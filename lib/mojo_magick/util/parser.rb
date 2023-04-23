require_relative "./font_parser"
module MojoMagick
  module Util
    class Parser
      attr_reader :raw_fonts

      def initialize
        warn "DEPRECATION WARNING: This class has been deprecated and will be removed with " \
             "the next minor version release.  " \
             "Please use `MojoMagick::Util::FontParser` instead"
      end

      def parse_fonts(fonts)
        warn "DEPRECATION WARNING: #{__method__} has been deprecated and will be removed with " \
             "the next minor version release.  " \
             "Please use `MojoMagick::Util::FontParser#parse` instead"
        FontParser.new(fonts).parse
      end
    end
  end
end
