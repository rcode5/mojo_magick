require File::join(File::dirname(__FILE__), 'test_helper')

class MojoMagickOptBuilderTest < MiniTest::Unit::TestCase

  # These tests make the assumption that if we call #raw_command with the
  # correct strings, ImageMagick itself will operate correctly. We're only
  # verifying that the option builder produces the correct strings

  def setup
    @builder = MojoMagick::OptBuilder.new
  end

  def test_annotate
    @builder.annotate 'blah'
    assert_equal  '-annotate 0 blah', @builder.to_s
  end

  def test_annotate_with_escapeable_string
    @builder.annotate 'it\'s'
    assert_equal '-annotate 0 "it\'s"', @builder.to_s
  end

  def test_annotate_with_full_args
    @builder.annotate '5 it\'s'
    assert_equal '-annotate 5 "it\'s"', @builder.to_s
  end

  def test_option_builder_with_blocks
    # Passing in basic commands produces a string
    b = MojoMagick::OptBuilder.new
    b.image_block do
      b.background 'red'
    end
    b.image_block do
      b.background 'blue'
    end
    assert_equal '\( -background red \) \( -background blue \)', b.to_s
  end

  def test_option_builder_with_hex_colors 
    b = MojoMagick::OptBuilder.new
    b.background '#000000'
    assert_equal '-background "#000000"', b.to_s
  end

  def test_option_builder
    # Passing in basic commands produces a string
    b = MojoMagick::OptBuilder.new
    b.strip
    b.repage
    assert_equal '-strip -repage', b.to_s

    # Chaining commands works
    b = MojoMagick::OptBuilder.new.strip.repage
    assert_equal '-strip -repage', b.to_s

    # Bang (!) indicates the plus version of commands
    b = MojoMagick::OptBuilder.new
    b.repage
    b.repage!
    assert_equal '-repage +repage', b.to_s

    # Accepts raw data as-is
    b = MojoMagick::OptBuilder.new
    b.opt1
    b << 'a ! b !'
    b.opt2
    assert_equal '-opt1 a ! b ! -opt2', b.to_s

    # Treats an array of raw data as different arguments
    b = MojoMagick::OptBuilder.new
    b << ['leave this data','alone']
    assert_equal 'leave this data alone', b.to_s

    # String includes command arguments
    b = MojoMagick::OptBuilder.new
    b.extent '256x256+0+0'
    b.crop '64x64'
    assert_equal '-extent 256x256+0+0 -crop 64x64', b.to_s

    # Arguments are quoted (doublequote) if appropriate
    b = MojoMagick::OptBuilder.new
    b.comment 'white space'
    b.comment 'w&b'
    b.crop '6x6^'
    assert_equal '-comment "white space" -comment "w&b" -crop "6x6^"', b.to_s

    # Existing doublequotes are escaped
    b = MojoMagick::OptBuilder.new
    b.comment 'Fred "Woot" Rook'
    assert_equal '-comment "Fred \"Woot\" Rook"', b.to_s

    # Multi-argument commands should not be quoted together
    b = MojoMagick::OptBuilder.new
    b.set 'comment', 'the "best" comment'
    assert_equal '-set comment "the \"best\" comment"', b.to_s

    # File and files are helper methods
    b = MojoMagick::OptBuilder.new
    b.files 'source.jpg', 'source2.jpg'
    b.append
    b.crop '64x64'
    b.file 'dest%d.jpg'
    assert_equal 'source.jpg source2.jpg -append -crop 64x64 dest%d.jpg', b.to_s

    # Files are quoted (doublequote) if appropriate
    b = MojoMagick::OptBuilder.new
    b.file 'probably on windows.jpg'
    assert_equal '"probably on windows.jpg"', b.to_s

    # Blob is a shortcut for the #tempfile helper method
    b = MojoMagick::OptBuilder.new
    b.blob 'binary data'
    filename = b.to_s
    File.open(filename, 'rb') do |f|
      assert_equal 'binary data', f.read
    end

    #label for text should use 'label:"the string"' if specified
    [[ 'mylabel', 'mylabel' ],
     [ 'my " label', '"my \" label"' ],
     [ 'Rock it, cuz i said so!', '"Rock it, cuz i said so!"'],
     [ "it's like this", '"it\'s like this"'],
     [ '#$%^&*', '"#$%^&*"']].each do |labels|

      b = MojoMagick::OptBuilder.new
      b.label labels[0]
      assert_equal "label:#{labels[1]}", b.to_s
    end

  end
end
