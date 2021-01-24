require_relative "test_helper"

class MojoMagickOptBuilderTest < MiniTest::Test
  # These tests make the assumption that if we call #raw_command with the
  # correct strings, ImageMagick itself will operate correctly. We're only
  # verifying that the option builder produces the correct strings

  def setup
    @builder = MojoMagick::OptBuilder.new
  end

  def test_annotate
    @builder.annotate "blah"
    assert_equal %w[-annotate 0 blah], @builder.to_a
  end

  def test_annotate_with_escapeable_string
    @builder.annotate "it's"
    assert_equal %w[-annotate 0 it's], @builder.to_a
  end

  def test_annotate_with_multiple_args
    @builder.annotate "5 it's"
    assert_equal ["-annotate", "0", "5 it's"], @builder.to_a
  end

  def test_annotate_with_geometry_args
    @builder.annotate "this thing", geometry: 3
    assert_equal ["-annotate", "3", "this thing"], @builder.to_a
  end

  def test_annotate_with_full_array_args
    @builder.annotate "this", "thing", geometry: 3
    assert_equal ["-annotate", "3", "thisthing"], @builder.to_a
  end

  def test_option_builder_with_blocks
    # Passing in basic commands produces a string
    @builder.image_block do
      @builder.background "red"
    end
    @builder.image_block do
      @builder.background "blue"
    end
    assert_equal ['\(', "-background", "red", '\)', '\(', "-background", "blue", '\)'], @builder.to_a
  end

  def test_option_builder_with_hex_colors
    @builder.background "#000000"
    assert_equal %w[-background #000000], @builder.to_a
  end

  def test_option_builder
    @builder.strip
    @builder.repage
    assert_equal %w[-strip -repage], @builder.to_a
  end

  def test_opt_builder_chaining_commands
    assert_equal %w[-strip -repage], @builder.strip.repage.to_a
  end

  def test_opt_builder_interpreting_bang_suffix
    # Bang (!) indicates the plus version of commands

    @builder.repage
    @builder.repage!
    assert_equal %w[-repage +repage], @builder.to_a
  end

  def test_opt_builder_pushing_raw_data
    # Treats an array of raw data as different arguments

    @builder << ["leave this data", "alone"]
    assert_equal ["leave this data", "alone"], @builder.to_a
  end

  def test_opt_builder_complex_command_arg
    @builder.extent "256x256+0+0"
    @builder.crop "64x64"
    assert_equal %w[-extent 256x256+0+0 -crop 64x64], @builder.to_a
  end

  def test_opt_builder_multi_arg_command_quoting
    # Multi-argument commands should not be quoted together

    @builder.set "comment", 'the "best" comment'
    assert_equal ["-set", "comment", "the \"best\" comment"], @builder.to_a
  end

  def test_opt_builder_with_custom_commands_and_raw_data
    # Accepts raw data as-is

    @builder.opt1
    @builder << "a ! b !"
    @builder.opt2
    assert_equal ["-opt1", "a ! b !", "-opt2"], @builder.to_a
  end

  def test_opt_builder_file_and_files
    # File and files are helper methods

    @builder.files "source.jpg", "source2.jpg"
    @builder.append
    @builder.crop "64x64"
    @builder.file "dest%d.jpg"
    assert_equal %w[source.jpg source2.jpg -append -crop 64x64 dest%d.jpg], @builder.to_a
  end

  def test_opt_builder_file_preserves_whitespace
    @builder.file "probably on windows.jpg"
    assert_equal ["probably on windows.jpg"], @builder.to_a
  end

  def test_opt_builder_comment
    @builder.comment "white space"
    @builder.comment "w&b"
    @builder.crop "6x6^"
    assert_equal ["-comment", "white space", "-comment", "w&b", "-crop", "6x6^"], @builder.to_a
  end

  def test_opt_builder_comment_with_quoted_elements
    @builder.comment 'Fred "Woot" Rook'
    assert_equal ["-comment", "Fred \"Woot\" Rook"], @builder.to_a
  end

  def test_opt_builder_blob_writes_data_to_temp_file
    @builder.blob "binary data"

    filename = @builder.to_a.first
    File.open(filename, "rb") do |f|
      assert_equal "binary data", f.read
    end
  end

  def test_opt_builder_label
    # label for text should use 'label:"the string"' if specified
    [%w[mylabel mylabel],
     ['my " label', '"my \" label"'],
     ["Rock it, cuz i said so!", '"Rock it, cuz i said so!"'],
     ["it's like this", '"it\'s like this"'],
     ["\#$%^&*", '"#$%^&*"']].each do |labels|
      b = MojoMagick::OptBuilder.new
      b.label labels[0]
      assert_equal ["label:#{labels[1]}"], b.to_a
    end
  end
end
