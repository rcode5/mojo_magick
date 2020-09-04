module MojoMagick
  module Util
    class Parser
      # handle parsing outputs from ImageMagick commands

      def parse_fonts(raw_fonts)
        fonts = {}
        enumerator = raw_fonts.split(/\n/).each
        name = nil
        while begin; line = enumerator.next; rescue StopIteration; line = nil; end
          line.chomp!
          line = enumerator.next if line.nil? || line.empty? || (/^\s+$/ =~ line)
          if m = /^\s*Font:\s+(.*)$/.match(line)
            name = m[1].strip
            fonts[name] = {name: name}
          else
            key_val = line.split(/:/).map(&:strip)
            k = key_val[0].downcase.to_sym
            v = key_val[1]
            fonts[name][k] = v if k && name
          end
        end
        fonts.values.map { |f| MojoMagick::Font.new f}
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
          scale = limits[i].match(/[a-z]+$/) || []
          value = limits[i].match(/^[0-9]+/)
          unscaled_value = value ? value[0].to_i : -1
          scaled_value = case scale[0]
                         when 'eb'
                           unscaled_value * (2**60)
                         when 'pb'
                           unscaled_value * (2**50)
                         when 'tb'
                           unscaled_value * (2**40)
                         when 'gb'
                           unscaled_value * (2**30)
                         when 'mb'
                           unscaled_value * (2**20)
                         when 'kb'
                           unscaled_value * (2**10)
                         when 'b'
                           unscaled_value
                         else
                           unscaled_value
                         end
          actual_values[resource] = scaled_value
          readable_values[resource] = limits[i]
        end
        [actual_values, readable_values]
      end
    end
  end
end
