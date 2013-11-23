require File::join(File::dirname(__FILE__), 'test_helper')

class MojoMagickTest < Test::Unit::TestCase

  # we keep a fixtures path and a working path so that we can easily test image
  # manipulation routines without tainting the original images
  def setup
    @fixtures_path = File.expand_path(File::join(File.dirname(__FILE__), 'fixtures'))
    @working_path = File::join(@fixtures_path, 'tmp')
  end

  def reset_images
    FileUtils::rm_r(@working_path) if File::exists?(@working_path)
    FileUtils::mkdir(@working_path)
    Dir::glob(File::join(@fixtures_path, '*')).each do |file|
      FileUtils::cp(file, @working_path) if File::file?(file)
    end
    @test_image = File::join(@working_path, '5742.jpg')

  end

  def test_get_image_size
    reset_images
    orig_image_size = File::size(@test_image)
    retval = MojoMagick::get_image_size(@test_image)
    assert_equal orig_image_size, File::size(@test_image)
    assert_equal 500, retval[:height]
    assert_equal 333, retval[:width]
  end

  def test_image_resize
    # test basic resizing
    reset_images
    orig_image_size = File::size(@test_image)
    size_test_temp = Tempfile::new('mojo_test')
    size_test = size_test_temp.path
    retval = MojoMagick::resize(@test_image, size_test, {:width=>100, :height=>100})
    assert_equal size_test, retval
    assert_equal orig_image_size, File::size(@test_image)
    assert_equal retval, size_test
    new_dimensions = MojoMagick::get_image_size(size_test)
    assert_equal 100, new_dimensions[:height]
    assert_equal 67, new_dimensions[:width]

    # we should be able to resize image right over itself
    retval = MojoMagick::resize(@test_image, @test_image, {:width=>100, :height=>100})
    assert_equal @test_image, retval
    assert_not_equal orig_image_size, File::size(@test_image)
    new_dimensions = MojoMagick::get_image_size(@test_image)
    assert_equal 100, new_dimensions[:height]
    assert_equal 67, new_dimensions[:width]
  end

  def test_shrink_with_big_dimensions
    # image shouldn't resize if we specify very large dimensions and specify "shrink_only"
    reset_images
    size_test_temp = Tempfile::new('mojo_test')
    size_test = size_test_temp.path
    retval = MojoMagick::shrink(@test_image, size_test, {:width=>1000, :height=>1000})
    assert_equal size_test, retval
    new_dimensions = MojoMagick::get_image_size(@test_image)
    assert_equal 500, new_dimensions[:height]
    assert_equal 333, new_dimensions[:width]
  end

  def test_shrink
    reset_images
    # image should resize if we specify small dimensions and shrink_only
    retval = MojoMagick::shrink(@test_image, @test_image, {:width=>1000, :height=>100})
    assert_equal @test_image, retval
    new_dimensions = MojoMagick::get_image_size(@test_image)
    assert_equal 100, new_dimensions[:height]
    assert_equal 67, new_dimensions[:width]
  end

  def test_resize_with_shrink_only_options
    reset_images
    # image should resize if we specify small dimensions and shrink_only
    retval = MojoMagick::resize(@test_image, @test_image, {:shrink_only => true, :width=>400, :height=>400})
    assert_equal @test_image, retval
    new_dimensions = MojoMagick::get_image_size(@test_image)
    assert_equal 400, new_dimensions[:height]
    assert_equal 266, new_dimensions[:width]
  end

  def test_expand_with_small_dim
    # image shouldn't resize if we specify small dimensions and expand_only
    reset_images
    orig_image_size = File::size(@test_image)
    retval = MojoMagick::expand(@test_image, @test_image, {:width=>10, :height=>10})
    assert_equal @test_image, retval
    new_dimensions = MojoMagick::get_image_size(@test_image)
    assert_equal 500, new_dimensions[:height]
    assert_equal 333, new_dimensions[:width]
  end

  def test_expand
    reset_images
    # image should resize if we specify large dimensions and expand_only
    retval = MojoMagick::expand(@test_image, @test_image, {:width=>1000, :height=>1000})
    assert_equal @test_image, retval
    new_dimensions = MojoMagick::get_image_size(@test_image)
    assert_equal 1000, new_dimensions[:height]
    assert_equal 666, new_dimensions[:width]
  end

  def test_invalid_images
    # test bad images
    bad_image = File::join(@working_path, 'not_an_image.jpg')
    zero_image = File::join(@working_path, 'zero_byte_image.jpg')
    assert_raise(MojoMagick::MojoFailed) {MojoMagick::get_image_size(bad_image)}
    assert_raise(MojoMagick::MojoFailed) {MojoMagick::get_image_size(zero_image)}
    assert_raise(MojoMagick::MojoFailed) {MojoMagick::get_image_size('/file_does_not_exist_here_ok.jpg')}
  end

  def test_resize_with_fill
    reset_images
    @test_image = File::join(@working_path, '5742.jpg')
    MojoMagick::resize(@test_image, @test_image, {:fill => true, :width => 100, :height => 100})
    dim = MojoMagick::get_image_size(@test_image)
    assert_equal 100, dim[:width]
    assert_equal 150, dim[:height]
  end

  def test_resize_with_fill_and_crop
    reset_images
    @test_image = File::join(@working_path, '5742.jpg')
    MojoMagick::resize(@test_image, @test_image, {:fill => true, :crop => true, :width => 150, :height => 120})
    dim = MojoMagick::get_image_size(@test_image)
    assert_equal 150, dim[:width]
    assert_equal 120, dim[:height]
  end

  def test_tempfile
    # Create a tempfile and return the path
    filename = MojoMagick::tempfile('binary data')
    File.open(filename, 'rb') do |f|
      assert_equal f.read, 'binary data'
    end
  end

  def test_label
    reset_images
    out_image = File::join(@working_path, 'label_test.png')

    MojoMagick::convert do |c|
      c.label 'rock the house'
      c.file out_image
    end
  end

  def test_label_with_quote
    reset_images
    out_image = File::join(@working_path, 'label_test.png')

    MojoMagick::convert do |c|
      c.label 'rock "the house'
      c.file out_image
    end
  end

  def test_label_with_apostrophe
    reset_images
    out_image = File::join(@working_path, 'label_test.png')

    MojoMagick::convert do |c|
      c.label 'rock \'the house'
      c.file out_image
    end
  end

  def test_label_with_quotes
    reset_images
    out_image = File::join(@working_path, 'label_test.png')

    MojoMagick::convert do |c|
      c.label 'this is "it!"'
      c.file out_image
    end
  end

  def test_command_helpers
    reset_images
    test_image = File::join(@working_path, '5742.jpg')
    out_image = File::join(@working_path, 'out1.jpg')

    # Simple convert test
    MojoMagick::convert do |c|
      c.file test_image
      c.crop '92x64+0+0'
      c.repage!
      c.file out_image
    end
    retval = MojoMagick::get_image_size(out_image)
    assert_equal 92, retval[:width]
    assert_equal 64, retval[:height]

    # Simple mogrify test
    MojoMagick::mogrify do |m|
      m.crop '32x32+0+0'
      m.repage!
      m.file out_image
    end
    retval = MojoMagick::get_image_size(out_image)
    assert_equal 32, retval[:width]
    assert_equal 32, retval[:height]

    # Convert test, using file shortcuts
    MojoMagick::convert(test_image, out_image) do |c|
      c.crop '100x100+0+0'
      c.repage!
    end
    retval = MojoMagick::get_image_size(out_image)
    assert_equal 100, retval[:width]
    assert_equal 100, retval[:height]

    # Mogrify test, using file shortcut
    MojoMagick::mogrify(out_image) { |m| m.shave('25x25').repage! }
    retval = MojoMagick::get_image_size(out_image)
    assert_equal 50, retval[:width]
    assert_equal 50, retval[:height]

    # RGB8 test
    bdata = 'aaaaaabbbbbbccc'
    out = 'out.png'
    MojoMagick::convert do |c|
      c.blob bdata, :format => :rgb, :depth => 8, :size => '5x1'
      c.file out
    end
    r = MojoMagick::get_image_size(out)
    assert r[:height] == 1
    assert r[:width] == 5

    bdata = '1111222233334444'
    out = 'out.png'
    MojoMagick::convert do |c|
      c.blob bdata, :format => :rgba, :depth => 8, :size => '4x1'
      c.file out
    end
    r = MojoMagick::get_image_size(out)
    assert r[:height] == 1
    assert r[:width] == 4

  end
end
