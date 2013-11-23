require File::join(File::dirname(__FILE__), 'test_helper')

class ResourceLimitsTest < Test::Unit::TestCase

  def test_resource_limits
    orig_limits = MojoMagick::get_default_limits
    assert_equal 7, orig_limits.size
    orig_limits_test = orig_limits.dup
    orig_limits_test.delete_if do |resource, value|
      assert [:area, :map, :disk, :memory, :file, :thread, :time].include?(resource), "Found unexpected resource #{resource}"
      true
    end
    assert_equal 0, orig_limits_test.size

    # set area to 32mb limit
    MojoMagick::set_limits(:area => '32mb')
    new_limits = MojoMagick::get_current_limits
    assert_equal '32mb', new_limits[:area].downcase

    # remove limits on area
    MojoMagick::remove_limits(:area)
    new_limits = MojoMagick::get_current_limits
    assert_equal orig_limits[:area], new_limits[:area]

    # set memory to 64 mb, disk to 0 and
    MojoMagick::set_limits(:memory => '64mb', :disk => '0b')
    new_limits = MojoMagick::get_current_limits(:show_actual_values => true)
    assert_equal 61, new_limits[:memory]
    assert_equal 0, new_limits[:disk]

    # return to original/default limit values
    MojoMagick::unset_limits
    new_limits = MojoMagick::get_current_limits
    assert_equal orig_limits, new_limits
  end

end
