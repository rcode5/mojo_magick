require_relative "test_helper"

IDENTIFY_FONT_RESPONSE = <<~EOFONT

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


EOFONT

class FontParserTest < MiniTest::Test
  def test_parse_fonts
    parser = MojoMagick::Util::FontParser.new(IDENTIFY_FONT_RESPONSE)
    parsed_fonts = parser.parse
    assert_equal parsed_fonts.length, 2
    assert_equal parsed_fonts[1].style, "Italic"
  end
end
