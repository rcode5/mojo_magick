require File::join(File::dirname(__FILE__), 'test_helper')

IDENTIFY_FONT_RESPONSE =<<EOF

Font: Zapf-Dingbats
    family: Zapf Dingbats
    style: Normal
    stretch: Normal
    weight: 400
    glyphs: /System/Library/Fonts/ZapfDingbats.ttf

  Font: Zapfino
    family: Zapfino
    style: Italic
    stretch: Normal
    weight: 400
    glyphs: /Library/Fonts/Zapfino.ttf


EOF

class ParserTest < MiniTest::Unit::TestCase

  def test_parse_fonts
    parser = MojoMagick::Util::Parser.new
    parsed_fonts = parser.parse_fonts(IDENTIFY_FONT_RESPONSE)
    assert_equal parsed_fonts.length, 2
    assert_equal parsed_fonts[1].style, 'Italic'
  end
end
