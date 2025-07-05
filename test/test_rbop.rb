# frozen_string_literal: true

require "test_helper"
require "rbop/version"

class TestRbop < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rbop::VERSION
    assert_equal "0.1.0", ::Rbop::VERSION
  end

  def test_version_is_string
    assert_instance_of String, ::Rbop::VERSION
    assert_match(/\A\d+\.\d+\.\d+/, ::Rbop::VERSION)
  end

  def test_error_class_exists
    assert_kind_of Class, ::Rbop::Error
    assert ::Rbop::Error < StandardError
  end

  def test_shell_runner_attribute_accessor
    original_runner = Rbop.shell_runner

    # Test getter
    assert_equal Rbop::Shell, Rbop.shell_runner

    # Test setter
    fake_runner = Object.new
    Rbop.shell_runner = fake_runner
    assert_equal fake_runner, Rbop.shell_runner

    # Restore original
    Rbop.shell_runner = original_runner
  end

  def test_default_shell_runner_is_shell_module
    assert_equal Rbop::Shell, Rbop.shell_runner
  end

  def test_version_constant_loaded
    # This test ensures version.rb is loaded and the constant is accessible
    assert_equal "0.1.0", Rbop::VERSION
    assert_defined_constant Rbop, :VERSION
  end

  def test_debug_attribute_accessible
    # Test debug attribute getter and setter
    original_debug = Rbop.debug

    # Test default value
    assert_equal false, Rbop.debug

    # Test setter
    Rbop.debug = true
    assert_equal true, Rbop.debug

    # Restore original
    Rbop.debug = original_debug
  end

  private

  def assert_defined_constant(klass, constant_name)
    assert klass.const_defined?(constant_name), "#{klass}::#{constant_name} should be defined"
  end
end
