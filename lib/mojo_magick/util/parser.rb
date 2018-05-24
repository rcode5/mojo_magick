# rubocop:disable Lint/AssignmentInCondition
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
          m = /^\s*Font:\s+(.*)$/.match(line)
          if m
            name = m[1].strip
            fonts[name] = { name: name }
          else
            key_val = line.split(/:/).map(&:strip)
            k = key_val[0].downcase.to_sym
            v = key_val[1]
            fonts[name][k] = v if k && name
          end
        end
        fonts.values.map { |f| MojoMagick::Font.new f }
      end
    end
  end
end
