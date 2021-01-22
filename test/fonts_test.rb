require_relative "test_helper"

class FontsTest < MiniTest::Test
  def test_get_fonts
    fonts = MojoMagick.get_fonts
    assert fonts.is_a? Array
    assert fonts.length > 1
    assert fonts.first.name
    assert(fonts.first.name.is_a?(String))
  end
end
