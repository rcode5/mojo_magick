module ImageMagick
  class Fonts
    def self.all
      raw_fonts = MojoMagick::Commands.send(:execute, "identify", "-list", "font").return_value
      MojoMagick::Util::FontParser.new(raw_fonts).parse
    end
  end
end
