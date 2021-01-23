module ImageMagick
  class Fonts
    def self.all
      raw_fonts = MojoMagick::Commands.raw_command("identify", "-list", "font")
      MojoMagick::Util::FontParser.new(raw_fonts).parse
    end
  end
end
