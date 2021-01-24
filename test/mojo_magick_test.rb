require_relative "test_helper"

class MojoMagickTest < MiniTest::Test
  # we keep a fixtures path and a working path so that we can easily test image
  # manipulation routines without tainting the original images
  def setup
    @fixtures_path = File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))
    @working_path = File.join(@fixtures_path, "tmp")

    reset_images

    @test_image = File.join(@working_path, "5742.jpg")
    @out_image = File.join(@working_path, "out1.jpg")
  end

  def reset_images
    FileUtils.rm_r(@working_path) if File.exist?(@working_path)
    FileUtils.mkdir(@working_path)
    Dir.glob(File.join(@fixtures_path, "*")).each do |file|
      FileUtils.cp(file, @working_path) if File.file?(file)
    end
  end

  def test_get_image_size
    orig_image_size = File.size(@test_image)
    retval = MojoMagick.get_image_size(@test_image)
    assert_equal orig_image_size, File.size(@test_image)
    assert_equal 500, retval[:height]
    assert_equal 333, retval[:width]
  end

  def test_image_resize
    # test basic resizing
    orig_image_size = File.size(@test_image)
    size_test_temp = Tempfile.new("mojo_test")
    size_test = size_test_temp.path
    retval = MojoMagick.resize(@test_image, size_test, { width: 100, height: 100 })
    assert_equal size_test, retval
    assert_equal orig_image_size, File.size(@test_image)
    assert_equal retval, size_test
    new_dimensions = MojoMagick.get_image_size(size_test)
    assert_equal 100, new_dimensions[:height]
    assert_equal 67, new_dimensions[:width]

    # we should be able to resize image right over itself
    retval = MojoMagick.resize(@test_image, @test_image, { width: 150, height: 150 })
    assert_equal @test_image, retval
    refute_equal orig_image_size, File.size(@test_image)
    new_dimensions = MojoMagick.get_image_size(@test_image)
    assert_equal 150, new_dimensions[:height]
    assert_equal 100, new_dimensions[:width]
  end

  def test_image_resize_with_percentage
    original_size = MojoMagick.get_image_size(@test_image)
    retval = MojoMagick.resize(@test_image, @test_image, { percent: 50 })
    assert_equal @test_image, retval
    new_dimensions = MojoMagick.get_image_size(@test_image)
    %i[height width].each do |dim|
      assert_equal (original_size[dim] / 2.0).ceil, new_dimensions[dim]
    end
  end

  def test_shrink_with_big_dimensions
    # image shouldn't resize if we specify very large dimensions and specify "shrink_only"
    size_test_temp = Tempfile.new("mojo_test")
    size_test = size_test_temp.path
    retval = MojoMagick.shrink(@test_image, size_test, { width: 1000, height: 1000 })
    assert_equal size_test, retval
    new_dimensions = MojoMagick.get_image_size(@test_image)
    assert_equal 500, new_dimensions[:height]
    assert_equal 333, new_dimensions[:width]
  end

  def test_shrink
    # image should resize if we specify small dimensions and shrink_only
    retval = MojoMagick.shrink(@test_image, @test_image, { width: 1000, height: 100 })
    assert_equal @test_image, retval
    new_dimensions = MojoMagick.get_image_size(@test_image)
    assert_equal 100, new_dimensions[:height]
    assert_equal 67, new_dimensions[:width]
  end

  def test_resize_with_shrink_only_options
    # image should resize if we specify small dimensions and shrink_only
    retval = MojoMagick.resize(@test_image, @test_image, { shrink_only: true, width: 400, height: 400 })
    assert_equal @test_image, retval
    new_dimensions = MojoMagick.get_image_size(@test_image)
    assert_equal 400, new_dimensions[:height]
    assert_equal 266, new_dimensions[:width]
  end

  def test_expand_with_small_dim
    # image shouldn't resize if we specify small dimensions and expand_only
    _orig_image_size = File.size(@test_image)
    retval = MojoMagick.expand(@test_image, @test_image, { width: 10, height: 10 })
    assert_equal @test_image, retval
    new_dimensions = MojoMagick.get_image_size(@test_image)
    assert_equal 500, new_dimensions[:height]
    assert_equal 333, new_dimensions[:width]
  end

  def test_expand
    # image should resize if we specify large dimensions and expand_only
    retval = MojoMagick.expand(@test_image, @test_image, { width: 1000, height: 1000 })
    assert_equal @test_image, retval
    new_dimensions = MojoMagick.get_image_size(@test_image)
    assert_equal 1000, new_dimensions[:height]
    assert_equal 666, new_dimensions[:width]
  end

  def test_invalid_images
    # test bad images
    bad_image = File.join(@working_path, "not_an_image.jpg")
    zero_image = File.join(@working_path, "zero_byte_image.jpg")
    assert_raises(MojoMagick::MojoFailed) { MojoMagick.get_image_size(bad_image) }
    assert_raises(MojoMagick::MojoFailed) { MojoMagick.get_image_size(zero_image) }
    assert_raises(MojoMagick::MojoFailed) do
      MojoMagick.get_image_size("/file_does_not_exist_here_ok.jpg")
    end
  end

  def test_resize_with_fill
    @test_image = File.join(@working_path, "5742.jpg")
    MojoMagick.resize(@test_image, @test_image, { fill: true, width: 100, height: 100 })
    dim = MojoMagick.get_image_size(@test_image)
    assert_equal 100, dim[:width]
    assert_equal 150, dim[:height]
  end

  def test_resize_with_fill_and_crop
    @test_image = File.join(@working_path, "5742.jpg")
    MojoMagick.resize(@test_image, @test_image, { fill: true, crop: true, width: 150, height: 120 })
    dim = MojoMagick.get_image_size(@test_image)
    assert_equal 150, dim[:width]
    assert_equal 120, dim[:height]
  end

  def test_tempfile
    # Create a tempfile and return the path
    filename = MojoMagick.tempfile("binary data")
    File.open(filename, "rb") do |f|
      assert_equal f.read, "binary data"
    end
  end

  def test_label
    out_image = File.join(@working_path, "label_test.png")

    MojoMagick.convert do |c|
      c.label "rock the house"
      c.file out_image
    end
  end

  def test_label_with_quote
    out_image = File.join(@working_path, "label_test.png")

    MojoMagick.convert do |c|
      c.label 'rock "the house'
      c.file out_image
    end
  end

  def test_label_with_apostrophe
    out_image = File.join(@working_path, "label_test.png")

    MojoMagick.convert do |c|
      c.label "rock 'the house"
      c.file out_image
    end
  end

  def test_label_with_quotes
    out_image = File.join(@working_path, "label_test.png")

    MojoMagick.convert do |c|
      c.label 'this is "it!"'
      c.file out_image
    end
  end

  def test_bad_command
    MojoMagick.convert do |c|
      c.unknown_option "fail"
      c.file "boogabooga.whatever"
    end
  rescue MojoMagick::MojoFailed => e
    assert e.message.include?("unrecognized option"),
           "Unable to find ImageMagick commandline error in the message"
    assert e.message.include?("convert.c/ConvertImageCommand"),
           "Unable to find ImageMagick commandline error in the message"
  end

  def test_blob_rgb
    data = (Array.new(16) { [rand > 0.5 ? 0 : 255] * 3 }).flatten
    bdata = data.pack "C" * data.size
    out = "out.png"
    MojoMagick.convert(nil, "png:#{out}") do |c|
      c.blob bdata, format: :rgb, depth: 8, size: "4x4"
    end
    r = MojoMagick.get_image_size(out)
    assert r[:height] == 4
    assert r[:width] == 4
  end

  def test_convert
    MojoMagick.convert do |c|
      c.file @test_image
      c.crop "92x64+0+0"
      c.repage!
      c.file @out_image
    end
    retval = MojoMagick.get_image_size(@out_image)
    assert_equal 92, retval[:width]
    assert_equal 64, retval[:height]
  end

  def test_mogrify
    MojoMagick.convert do |c|
      c.file @test_image
      c.file @out_image
    end
    # Simple mogrify test
    MojoMagick.mogrify do |m|
      m.crop "32x32+0+0"
      m.repage!
      m.file @out_image
    end
    retval = MojoMagick.get_image_size(@out_image)
    assert_equal 32, retval[:width]
    assert_equal 32, retval[:height]
  end

  def test_convert_crop_and_repage
    MojoMagick.convert(@test_image, @out_image) do |c|
      c.crop "100x100+0+0"
      c.repage!
    end
    retval = MojoMagick.get_image_size(@out_image)
    assert_equal 100, retval[:width]
    assert_equal 100, retval[:height]
  end

  def test_mogrify_with_shave_and_repage
    MojoMagick.convert do |c|
      c.file @test_image
      c.crop "100x100+0+0"
      c.file @out_image
    end
    MojoMagick.mogrify(@out_image) { |m| m.shave("25x25").repage! }
    retval = MojoMagick.get_image_size(@out_image)
    assert_equal 50, retval[:width]
    assert_equal 50, retval[:height]
  end

  def test_convert_rgb
    bdata = "aaaaaabbbbbbccc"
    out = "out.png"
    MojoMagick.convert do |c|
      c.blob bdata, format: :rgb, depth: 8, size: "5x1"
      c.file out
    end
    r = MojoMagick.get_image_size(out)
    assert r[:height] == 1
    assert r[:width] == 5
  end

  def test_convert_rgba
    bdata = "1111222233334444"
    out = "out.png"
    MojoMagick.convert do |c|
      c.blob bdata, format: :rgba, depth: 8, size: "4x1"
      c.file out
    end
    r = MojoMagick.get_image_size(out)
    assert r[:height] == 1
    assert r[:width] == 4
  end

  def test_available_fonts
    fonts = MojoMagick.available_fonts
    assert fonts.is_a? Array
    assert fonts.length > 1
    assert fonts.first.name
    assert(fonts.first.name.is_a?(String))
  end
end
