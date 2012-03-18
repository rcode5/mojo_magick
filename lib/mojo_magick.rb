require File::expand_path(File::join(File::dirname(__FILE__), 'image_resources'))
require 'tempfile'

# MojoMagick is a stateless set of module methods which present a convient interface
# for accessing common tasks for ImageMagick command line library.
#
# MojoMagick is specifically designed to be efficient and simple and most importantly
# to not leak any memory. For complex image operations, you will find MojoMagick limited.
# You might consider the venerable MiniMagick or RMagick for your purposes if you care more
# about ease of use rather than speed and memory management.

# all commands raise "MojoMagick::MojoFailed" if command fails (ImageMagick determines command success status)

# Two command-line builders, #convert and #mogrify, have been added to simplify
# complex commands. Examples included below.
#
# Example #convert usage:
#
#   MojoMagick::convert('source.jpg', 'dest.jpg') do |c|
#     c.crop '250x250+0+0'
#     c.repage!
#     c.strip
#     c.set 'comment', 'my favorite file'
#   end
# 
# Equivalent to:
#
#   MojoMagick::raw_command('convert', 'source.jpg -crop 250x250+0+0 +repage -strip -set comment "my favorite file" dest.jpg')
#
# Example #mogrify usage:
#
#   MojoMagick::mogrify('image.jpg') {|i| i.shave '10x10'}
#
# Equivalent to:
# 
#   MojoMagick::raw_command('mogrify', '-shave 10x10 image.jpg')
#
# Example showing some additional options:
#
#   MojoMagick::convert do |c|
#     c.file 'source.jpg'
#     c.blob my_binary_data
#     c.append
#     c.crop '256x256+0+0'
#     c.repage!
#     c.file 'output.jpg'
#   end
#
# Use .file to specify file names, .blob to create and include a tempfile. The
# bang (!) can be appended to command names to use the '+' versions
# instead of '-' versions.
#
module MojoMagick

  class MojoMagickException < StandardError; end
  class MojoError < MojoMagickException; end
  class MojoFailed < MojoMagickException; end

  # enable resource limiting functionality
  extend ImageMagickResources::ResourceLimits

  def MojoMagick::windows?
    mem_fix = 1
    !(RUBY_PLATFORM =~ /win32/).nil?
  end

  def MojoMagick::raw_command(command, args, options = {})
    # this suppress error messages to the console
    err_pipe = windows? ? "2>nul" : "2>/dev/null"
    begin
      execute = "#{command} #{get_limits_as_params} #{args} #{err_pipe}"
      puts execute
      retval = `#{execute}`
    # guarantee that only MojoError exceptions are raised here
    rescue Exception => e
      raise MojoError, "#{e.class}: #{e.message}"
    end
    if $? && !$?.success?
      err_msg = options[:err_msg] || "MojoMagick command failed: #{command}."
      raise(MojoFailed, "#{err_msg} (Exit status: #{$?.exitstatus})\n  Command: #{execute}")
    end
    retval
  end

  def MojoMagick::shrink(source_file, dest_file, options)
    opts = options.dup
    opts.delete(:expand_only)
    MojoMagick::resize(source_file, dest_file, opts.merge(:shrink_only => true))
  end

  def MojoMagick::expand(source_file, dest_file, options)
    opts = options.dup
    opts.delete(:shrink_only)
    MojoMagick::resize(source_file, dest_file, opts.merge(:expand_only => true))
  end

  # resizes an image and returns the filename written to
  # options:
  #   :width / :height => scale to these dimensions
  #   :scale => pass scale options such as ">" to force shrink scaling only or "!" to force absolute width/height scaling (do not preserve aspect ratio)
  #   :percent => scale image to this percentage (do not specify :width/:height in this case)
  def MojoMagick::resize(source_file, dest_file, options)
    retval = nil
    scale_options = []
    scale_options << '">"' unless options[:shrink_only].nil?
    scale_options << '"<"' unless options[:expand_only].nil?
    scale_options << '"!"' unless options[:absolute_aspect].nil?
    scale_options << '"^"' unless options[:fill].nil?
    scale_options = scale_options.join(' ')
    
    extras = []
    if !options[:width].nil? && !options[:height].nil?
      geometry = "#{options[:width]}X#{options[:height]}"
    elsif !options[:percent].nil?
      geometry = "#{options[:percent]}%"
    else
      raise MojoMagickError, "Unknown options for method resize: #{options.inspect}"
    end
    if !options[:fill].nil? && !options[:crop].nil?
      extras << "-gravity Center"
      extras << "-extent #{geometry}"
    end
    retval = raw_command("convert", "\"#{source_file}\" -resize #{geometry}#{scale_options} #{extras.join(' ')} \"#{dest_file}\"")
    dest_file
  end

  # returns an empty hash or a hash with :width and :height set (e.g. {:width => INT, :height => INT})
  # raises MojoFailed when results are indeterminate (width and height could not be determined)
  def MojoMagick::get_image_size(source_file)
    # returns width, height of image if available, nil if not
    retval = raw_command("identify", "-format \"w:%w h:%h\" \"#{source_file}\"")
    return {} if !retval
    width = retval.match(%r{w:([0-9]+) })
    width = width ? width[1].to_i : nil
    height = retval.match(%r{h:([0-9]+)})
    height = height ? height[1].to_i : nil
    raise(MojoFailed, "Indeterminate results in get_image_size: #{source_file}") if !height || !width
    {:width=>width, :height=>height}
  end

  def MojoMagick::convert(source = nil, dest = nil)
    opts = OptBuilder.new
    opts.file source if source
    yield opts
    opts.file dest if dest
    raw_command('convert', opts.to_s)
  end

  def MojoMagick::mogrify(dest = nil)
    opts = OptBuilder.new
    yield opts
    opts.file dest if dest
    raw_command('mogrify', opts.to_s)
  end

  
  def MojoMagick::tempfile(*opts)
    begin
      data = opts[0]
      rest = opts[1]
      ext = rest && rest[:format]
      file = Tempfile.new(["mojo", ext ? '.' + ext.to_s : ''])
      file.binmode
      file.write(data)
      file.path
    rescue Exception => ex
      raise
    end
  ensure
    file.close
  end

  # Option builder used in #convert and #mogrify helpers.
  class OptBuilder
    def initialize
      @opts = []
    end

    # Add command-line options with no processing
    def <<(arg)
      if arg.is_a?(Array)
        @opts += arg
      else
        @opts << arg
      end
      self
    end

    # Add files to command line, formatted if necessary
    def file(*args)
      args.each do |arg|
        add_formatted arg
      end
      self
    end
    alias files file

    # Create a temporary file for the given image and add to command line
    def format(*args)
      @opts << '-format' 
      args.each do |arg|
        add_formatted arg
      end
    end
      
    def blob(*args)
      data = args[0]
      opts = args[1] || {}
      opts.each do |k,v|
        send(k.to_s,v.to_s)
      end
      tmpfile = MojoMagick::tempfile(data, opts)
      file tmpfile
    end

    # Generic commands. Arguments will be formatted if necessary
    def method_missing(command, *args)
      if command.to_s[-1, 1] == '!'
        @opts << "+#{command.to_s.chop}"
      else
        @opts << "-#{command}"
      end
      args.each do |arg|
        add_formatted arg
      end 
      self
    end

    def to_s
      @opts.join ' '
    end

    protected
    def add_formatted(arg)
      # Quote anything that would cause problems on *nix or windows
      if arg =~ /[<>^|&();` ]/
        @opts << "\"#{arg.gsub('"', '\"')}\""
      else
        @opts << arg
      end
    end
  end
    
end # MojoMagick


