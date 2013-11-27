# Option builder used in #convert and #mogrify helpers.
module MojoMagick
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

    def label(*args)
      @opts << "label:#{quoted_arg(args.join)}"
    end

    # annotate takes non-standard args
    def annotate(*args)
      @opts << '-annotate'
      arguments = args.join.split
      if arguments.length == 1
        arguments.unshift '0'
      end
      arguments.each do |arg|
        add_formatted arg
      end
    end

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

    def image_block(&block)
      @opts << '\('
      yield block
      @opts << '\)'
      self
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
      @opts << quoted_arg(arg)
    end

    def quoted_arg(arg)
      return arg unless arg =~ /[#'<>^|&();` ]/
      [ '"', arg.gsub('"', '\"').gsub("'", "\'"), '"'].join
    end
  end
end
