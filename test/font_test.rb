
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

class FontTest < MiniTest::Unit::TestCase

  def test_font
    f = MojoMagick::Font.new
    assert_equal f.name, nil
    assert_equal f.valid?, false

    f = MojoMagick::Font.new(:name => "Zapfino", :weight => 400)
    assert_equal f.name, 'Zapfino'
    assert_equal f.valid?, true
    assert_equal f.weight,  400

  end

end


