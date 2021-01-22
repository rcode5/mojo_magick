require_relative "test_helper"

IDENTIFY_FONT_RESPONSE = <<~EO_FONTS
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
EO_FONTS

class FontTest < MiniTest::Test
  def test_font
    f = MojoMagick::Font.new
    assert_nil f.name
    assert_equal f.valid?, false

    f = MojoMagick::Font.new(name: "Zapfino", weight: 400)
    assert_equal f.name, "Zapfino"
    assert_equal f.valid?, true
    assert_equal f.weight, 400
  end
end
