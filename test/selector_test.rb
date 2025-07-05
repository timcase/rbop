# frozen_string_literal: true

require "test_helper"

class SelectorTest < Minitest::Test
  def test_parse_title
    result = Rbop::Selector.parse(title: "My Login")
    
    assert_equal :title, result[:type]
    assert_equal "My Login", result[:value]
  end

  def test_parse_id
    result = Rbop::Selector.parse(id: "abc123def456")
    
    assert_equal :id, result[:type]
    assert_equal "abc123def456", result[:value]
  end

  def test_parse_share_url
    url = "https://share.1password.com/s/abc123def456ghi789"
    result = Rbop::Selector.parse(url: url)
    
    assert_equal :url_share, result[:type]
    assert_equal url, result[:value]
  end

  def test_parse_private_link_url
    url = "https://my-team.1password.com/vaults/abc123/allitems/def456/open/i?ghi789"
    result = Rbop::Selector.parse(url: url)
    
    assert_equal :url_private, result[:type]
    assert_equal url, result[:value]
  end

  def test_error_no_arguments
    error = assert_raises(ArgumentError) do
      Rbop::Selector.parse
    end
    
    assert_equal "Must provide one of: title:, id:, or url:", error.message
  end

  def test_error_multiple_arguments
    error = assert_raises(ArgumentError) do
      Rbop::Selector.parse(title: "My Login", id: "abc123")
    end
    
    assert_equal "Must provide exactly one of: title:, id:, or url:", error.message
  end

  def test_error_invalid_argument
    error = assert_raises(ArgumentError) do
      Rbop::Selector.parse(name: "My Login")
    end
    
    assert_equal "Must provide one of: title:, id:, or url:", error.message
  end

  def test_error_malformed_url
    error = assert_raises(ArgumentError) do
      Rbop::Selector.parse(url: "https://example.com/not-a-1password-url")
    end
    
    assert_equal "URL must be a valid 1Password share URL or private link", error.message
  end
end