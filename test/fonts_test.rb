require File::join(File::dirname(__FILE__), 'test_helper')

class FontsTest < MiniTest::Unit::TestCase

  def test_get_fonts
    fonts = MojoMagick::get_fonts
    assert fonts.is_a? Array
    assert fonts.length > 1
    assert fonts.first.name
    assert (fonts.first.name.is_a? String)
  end
end
