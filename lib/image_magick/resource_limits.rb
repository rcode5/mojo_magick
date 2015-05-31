# This module provides some mix-in methods to permit resource limitation commands in MojoMagick
module ImageMagick
  module ResourceLimits
    @@resource_limits = {}

    # controls limits on memory and other resources for imagemagick.
    # possible values for type can include:
    #    Area, Disk, File, Map, or Memory
    # value is byte size for everything but Disk, where it's number of files
    # type can be string or symbol.
    # Just limiting Memory will not solve problems with imagemagick going out of
    # control with resource consumption on certain bad files. You have to set disk,
    # area and map limits too. Read up on imagemagick website for more.
    # Different options have different units
    #   DISK: N GB
    #   AREA, MAP, MEMORY: N MB
    #   FILE: N num file handles
    # Examples:
    #   # set disk to 5 gigabytes limit
    #   MiniMagick::Image::set_limit(:disk => 5)
    #   # set memory to 32mb, map to 64mb and disk to 0
    #   MiniMagick::Image::set_limit(:memory => 32, 'map' => 64, 'disk' => 0)
      def set_limits(options)
        mem_fix = 1
        options.each do |resource, value|
          @@resource_limits[resource.to_s.downcase.to_sym] = value.to_s
        end
      end

      # remove a limit
      def remove_limits(*options)
        mem_fix = 1
        @@resource_limits.delete_if do |resource, value|
          idx = options.index(resource)
          resource == options.values_at(idx)[0].to_s.downcase.to_sym if idx
        end
      end

      # remove limits from resources
      def unset_limits(options = {})
        mem_fix = 1
        @@resource_limits = {}
        if options[:unset_env]
          ENV["MAGICK_AREA_LIMIT"]=nil
          ENV["MAGICK_MAP_LIMIT"]=nil
          ENV["MAGICK_MEMORY_LIMIT"]=nil
          ENV["MAGICK_DISK_LIMIT"]=nil
        end
      end

      # returns the default limits that imagemagick is using, when run with no "-limit" parameters
    # options:
    #   :show_actual_values => true (default false) - will return integers instead of readable values
      def get_default_limits(options = {})
        mem_fix = 1
        parse_limits(options.merge(:get_current_limits => false))
      end

      # returns the limits that imagemagick is running based on any "set_limits" calls
      def get_current_limits(options = {})
        mem_fix = 1
        parse_limits(options.merge(:get_current_limits => true))
      end

      alias :get_limits :get_current_limits

      def parse_limits(options)
        show_actual_values = options[:show_actual_values]
        if options[:get_current_limits]
          status = self.execute('identify', '-list resource')
          raw_limits = status.return_value
        else
          # we run a raw shell command here to obtain
          # limits without applying command line limit params
          raw_limits = `identify -list resource`
        end
        actual_values, readable_values = parser.parse_limits(raw_limits)
        show_actual_values ? actual_values : readable_values
      end # parse_limits

      # returns a string suitable for passing as a set of imagemagick params
    # that contains all the limit constraints
    def get_limits_as_params
      retval = ''
      # we upcase the value here for newer versions of ImageMagick (>=6.8.x)
      @@resource_limits.each do |type, value|
        retval += " -limit #{type.to_s} #{value.upcase} "
      end
      retval
    end

    def parser
      @parser ||= MojoMagick::Util::Parser.new
    end
  end
end
