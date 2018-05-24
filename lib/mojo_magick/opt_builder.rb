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
      @opts << args
      self
    end
    alias files file

    def label(*args)
      @opts << "label:#{quoted_arg(args.join)}"
    end

    # annotate takes non-standard args
    def annotate(*args)
      @opts << "-annotate"
      arguments = args.join.split
      arguments.unshift "0" if arguments.length == 1
      @opts << arguments
    end

    # Create a temporary file for the given image and add to command line
    def format(*args)
      @opts << "-format"
      @opts << args
    end

    def blob(*args)
      data = args[0]
      opts = args[1] || {}
      opts.each do |k, v|
        send(k.to_s, v.to_s)
      end
      tmpfile = MojoMagick.tempfile(data, opts)
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
      @opts << if command.to_s[-1, 1] == "!"
                 "+#{command.to_s.chop}"
               else
                 "-#{command}"
               end
      @opts << args
      self
    end

    def to_s
      to_a.join " "
    end

    def to_a
      @opts.flatten
    end

    protected

    def quoted_arg(arg)
      return arg unless /[#'<>^|&();` ]/.match?(arg)

      ['"', arg.gsub('"', '\"').tr("'", "\'"), '"'].join
    end
  end
end
