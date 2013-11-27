module MojoMagick
  module Util
    class Parser
      # handle parsing outputs from ImageMagick commands

      def parse_fonts(raw_fonts)
        font = nil
        fonts = {}
        enumerator = raw_fonts.split(/\n/).each
        name = nil
        while (begin; line = enumerator.next; rescue StopIteration; line=nil; end) do
          line.chomp!
          line = enumerator.next if line.nil? || line.empty? || (/^\s+$/ =~ line)
          if m = /^\s*Font:\s+(.*)$/.match(line)
            name = m[1].strip
            fonts[name] = {:name => name}
          else
            key_val = line.split(/:/).map(&:strip)
            k = key_val[0].downcase.to_sym
            v = key_val[1]
            if k && name
              fonts[name][k] = key_val[1]
            end
          end
        end
        fonts.values.map{|f| MojoMagick::Font.new f}
      end

      def parse_limits(raw_limits)

        row_limits = raw_limits.split("\n")
        header = row_limits[0].chomp
        data = row_limits[2].chomp
        resources = header.strip.split
        limits = data.strip.split

        actual_values = {}
        readable_values = {}

        resources.each_index do |i|
          resource = resources[i].downcase.to_sym
          scale = limits[i].match(%r{[a-z]+$}) || []
          value = limits[i].match(%r{^[0-9]+})
          unscaled_value = value ? value[0].to_i : -1
          case scale[0]
          when 'eb'
            scaled_value = unscaled_value * (2 ** 60)
          when 'pb'
            scaled_value = unscaled_value * (2 ** 50)
          when 'tb'
            scaled_value = unscaled_value * (2 ** 40)
          when 'gb'
            scaled_value = unscaled_value * (2 ** 30)
          when 'mb'
            scaled_value = unscaled_value * (2 ** 20)
          when 'kb'
            scaled_value = unscaled_value * (2 ** 10)
          when 'b'
            scaled_value = unscaled_value
          else
            scaled_value = unscaled_value
          end
          actual_values[resource] = scaled_value
          readable_values[resource] = limits[i]
        end
        [actual_values, readable_values]
      end
    end
  end
end
