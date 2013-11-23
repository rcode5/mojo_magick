module ImageMagick
  module Fonts
    def get_fonts
      @parser ||= MojoMagick::Util::Parser.new
      raw_fonts = begin
                    self.raw_command('identify', '-list font')
                  rescue Exception => ex
                    puts ex
                    puts "Failed to execute font list with raw_command - trying straight up execute"
                    `convert -list font`
                  end
      @parser.parse_fonts(raw_fonts)
    end
  end
end
