require File::join(File::dirname(__FILE__), 'test_helper')

class ResourceLimitsTest < MiniTest::Unit::TestCase

  def setup
    @orig_limits = MojoMagick::get_default_limits
  end

  def test_set_limits
    # set area to 32mb limit
    MojoMagick::set_limits(:area => '32mb')
    new_limits = MojoMagick::get_current_limits
    assert_equal '32mb', new_limits[:area].downcase
  end

  def test_get_limits
    assert(@orig_limits.size >= 7)
  end

  def test_resource_limits
    orig_limits_test = @orig_limits.dup
    orig_limits_test.delete_if do |resource, value|
      assert [:throttle, :area, :map, :disk, :memory, :file, :thread, :time].include?(resource), "Found unexpected resource #{resource}"
      true
    end
    assert_equal 0, orig_limits_test.size
  end

  def test_get_current_limits
    # remove limits on area
    MojoMagick::remove_limits(:area)
    new_limits = MojoMagick::get_current_limits
    assert_equal @orig_limits[:area], new_limits[:area]
  end

  def test_set_limits
    # set memory to 64 mb, disk to 0 and
    MojoMagick::set_limits(:memory => '64mb', :disk => '0b')
    new_limits = MojoMagick::get_current_limits(:show_actual_values => true)
    assert_equal 61, new_limits[:memory]
    assert_equal 0, new_limits[:disk]
  end

  def test_unset_limits
    # return to original/default limit values
    MojoMagick::unset_limits
    new_limits = MojoMagick::get_current_limits
    assert_equal @orig_limits, new_limits
  end

end
