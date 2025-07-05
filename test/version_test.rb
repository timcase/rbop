# frozen_string_literal: true

require "test_helper"

class VersionTest < Minitest::Test
  def test_version_constant_exists
    # This ensures the version file is loaded and covered
    require_relative "../lib/rbop/version"

    assert_equal "0.1.0", Rbop::VERSION
    assert_kind_of String, Rbop::VERSION
  end
end
