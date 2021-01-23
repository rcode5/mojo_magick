require "tempfile"
require "open3"
require_relative "./mojo_magick/util/font_parser"
require_relative "./mojo_magick/errors"
require_relative "./mojo_magick/command_status"
require_relative "./mojo_magick/commands"
require_relative "./image_magick/fonts"
require_relative "./mojo_magick/opt_builder"
require_relative "./mojo_magick/font"

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
#   MojoMagick::Commands.raw_command('convert', 'source.jpg -crop 250x250+0+0\
#         +repage -strip -set comment "my favorite file" dest.jpg')
#
# Example #mogrify usage:
#
#   MojoMagick::mogrify('image.jpg') {|i| i.shave '10x10'}
#
# Equivalent to:
#
#   MojoMagick::Commands.raw_command('mogrify', '-shave 10x10 image.jpg')
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

module MojoMagickDeprecations
  # rubocop:disable Naming/AccessorMethodName
  def get_fonts
    warn "DEPRECATION WARNING: #{__method__} is deprecated and will be removed with the next minor version release."\
         "  Please use `available_fonts` instead"
    MojoMagick.available_fonts
  end

  # rubocop:enable Naming/AccessorMethodName
  ### Moved to `Commands`
  def execute!(*args)
    warn "DEPRECATION WARNING: #{__method__} is deprecated and will be removed with the next minor version release."\
         "  Please use `MojoMagick::Commands.execute!` instead"
    MojoMagick::Commands.send(:execute!, *args)
  end

  def execute(*args)
    warn "DEPRECATION WARNING: #{__method__} is deprecated and will be removed with the next minor version release."\
         "  Please use `MojoMagick::Commands.execute!` instead"
    MojoMagick::Commands.send(:execute, *args)
  end

  def raw_command(*args)
    warn "DEPRECATION WARNING: #{__method__} is deprecated and will be removed with the next minor version release."\
         "  Please use `MojoMagick::Commands.execute!` instead"
    MojoMagick::Commands.raw_command(*args)
  end
end

module MojoMagick
  extend MojoMagickDeprecations
  def self.windows?
    !RUBY_PLATFORM.include(win32)
  end

  def self.shrink(source_file, dest_file, options)
    opts = options.dup
    opts.delete(:expand_only)
    MojoMagick.resize(source_file, dest_file, opts.merge(shrink_only: true))
  end

  def self.expand(source_file, dest_file, options)
    opts = options.dup
    opts.delete(:shrink_only)
    MojoMagick.resize(source_file, dest_file, opts.merge(expand_only: true))
  end

  # resizes an image and returns the filename written to
  # options:
  #   :width / :height => scale to these dimensions
  #   :scale => pass scale options such as ">" to force shrink scaling only or
  #             "!" to force absolute width/height scaling (do not preserve aspect ratio)
  #   :percent => scale image to this percentage (do not specify :width/:height in this case)
  def self.resize(source_file, dest_file, options)
    scale_options = extract_scale_options(options)
    geometry = extract_geometry_options(options)
    extras = []
    if !options[:fill].nil? && !options[:crop].nil?
      extras << "-gravity"
      extras << "Center"
      extras << "-extent"
      extras << geometry.to_s
    end
    Commands.raw_command("convert",
                         source_file,
                         "-resize", "#{geometry}#{scale_options}",
                         *extras, dest_file)
    dest_file
  end

  def self.convert(source = nil, dest = nil)
    opts = OptBuilder.new
    opts.file source if source
    yield opts
    opts.file dest if dest

    Commands.raw_command("convert", *opts.to_a)
  end

  def self.mogrify(dest = nil)
    opts = OptBuilder.new
    yield opts
    opts.file dest if dest
    Commands.raw_command("mogrify", *opts.to_a)
  end

  def self.available_fonts
    # returns width, height of image if available, nil if not
    Font.all
  end

  def self.get_format(source_file, format_string)
    Commands.raw_command("identify", "-format", format_string, source_file)
  end

  # returns an empty hash or a hash with :width and :height set (e.g. {:width => INT, :height => INT})
  # raises MojoFailed when results are indeterminate (width and height could not be determined)
  def self.get_image_size(source_file)
    # returns width, height of image if available, nil if not
    retval = get_format(source_file, "w:%w h:%h")
    return {} unless retval

    width = retval.match(/w:([0-9]+) /)
    width = width ? width[1].to_i : nil
    height = retval.match(/h:([0-9]+)/)
    height = height ? height[1].to_i : nil
    raise(MojoFailed, "Indeterminate results in get_image_size: #{source_file}") if !height || !width

    { width: width, height: height }
  end

  def self.tempfile(*opts)
    data = opts[0]
    rest = opts[1]
    ext = rest && rest[:format]
    file = Tempfile.new(["mojo", ext ? ".#{ext}" : ""])
    file.binmode
    file.write(data)
    file.path
  ensure
    file.close
  end

  class << self
    private

    def extract_geometry_options(options)
      if !options[:width].nil? && !options[:height].nil?
        "#{options[:width]}X#{options[:height]}"
      elsif !options[:percent].nil?
        "#{options[:percent]}%"
      else
        raise MojoMagickError, "Resize requires width and height or percentage: #{options.inspect}"
      end
    end

    def extract_scale_options(options)
      [].tap { |scale_options|
        scale_options << ">" unless options[:shrink_only].nil?
        scale_options << "<" unless options[:expand_only].nil?
        scale_options << "!" unless options[:absolute_aspect].nil?
        scale_options << "^" unless options[:fill].nil?
      }.join
    end
  end
end
