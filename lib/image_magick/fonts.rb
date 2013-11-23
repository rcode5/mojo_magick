module ImageMagick
  module Fonts
    def get_fonts
      @parser ||= MojoMagick::Util::Parser.new
      fonts = self.raw_command('identify', '-list font')
      @parser.parse_fonts(fonts)
    end
  end
end
