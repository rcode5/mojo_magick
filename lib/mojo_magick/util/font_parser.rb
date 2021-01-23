# rubocop:disable Lint/AssignmentInCondition
module MojoMagick
  module Util
    class FontParser
      attr_reader :raw_fonts

      def initialize(raw_fonts)
        @raw_fonts = raw_fonts
      end

      def parse
        fonts = {}
        enumerator = raw_fonts.split(/\n/).each
        name = nil
        while begin; line = enumerator.next; rescue StopIteration; line = nil; end
          line.chomp!
          line = enumerator.next if line_is_empty(line)
          m = /^\s*Font:\s+(.*)$/.match(line)
          if m
            name = m[1].strip
            fonts[name] = { name: name }
          else
            k, v = extract_key_value(line)
            fonts[name][k] = v if k && name
          end
        end
        fonts.values.map { |f| MojoMagick::Font.new f }
      end

      private

      def extract_key_value(line)
        key_val = line.split(/:/).map(&:strip)
        [key_val[0].downcase.to_sym, key_val[1]]
      end

      def line_is_empty(line)
        line.nil? || line.empty? || (/^\s+$/ =~ line)
      end
    end
  end
end
# rubocop:enable Lint/AssignmentInCondition
