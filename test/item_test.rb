# frozen_string_literal: true

require "test_helper"

class ItemTest < Minitest::Test
  def test_to_h_returns_deep_copy_and_original_unchanged
    original_hash = {
      "id" => "abc123",
      "title" => "My Login",
      "vault" => { "id" => "vault123" },
      "fields" => [{ "id" => "field1", "value" => "secret" }]
    }
    
    item = Rbop::Item.new(original_hash)
    copy = item.to_h
    
    # Modify the copy
    copy["title"] = "Modified Title"
    copy["vault"]["id"] = "modified_vault"
    copy["fields"][0]["value"] = "modified_secret"
    
    # Original should be unchanged
    assert_equal "My Login", item.raw["title"]
    assert_equal "vault123", item.raw["vault"]["id"]
    assert_equal "secret", item.raw["fields"][0]["value"]
    
    # Item's internal data should also be unchanged
    assert_equal "My Login", item["title"]
    assert_equal "vault123", item["vault"]["id"]
  end

  def test_bracket_access_works_with_strings_and_symbols
    hash = { "id" => "abc123", "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    assert_equal "abc123", item["id"]
    assert_equal "abc123", item[:id]
    assert_equal "My Login", item["title"]
    assert_equal "My Login", item[:title]
  end

  def test_bracket_access_returns_nil_for_missing_keys
    hash = { "id" => "abc123" }
    item = Rbop::Item.new(hash)
    
    assert_nil item["missing"]
    assert_nil item[:missing]
  end

  def test_as_json_is_alias_for_to_h
    hash = { "id" => "abc123", "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    assert_equal item.to_h, item.as_json
    refute_same item.to_h, item.as_json  # Different objects
  end

  def test_deep_copy_handles_nested_structures
    hash = {
      "level1" => {
        "level2" => {
          "level3" => ["item1", "item2"]
        }
      }
    }
    
    item = Rbop::Item.new(hash)
    copy = item.to_h
    
    copy["level1"]["level2"]["level3"] << "item3"
    
    # Original should have only 2 items
    assert_equal 2, item.raw["level1"]["level2"]["level3"].length
    assert_equal 3, copy["level1"]["level2"]["level3"].length
  end

  def test_raw_attribute_preserves_original_hash
    original_hash = { "id" => "abc123", :title => "My Login" }
    item = Rbop::Item.new(original_hash)
    
    assert_same original_hash, item.raw
    assert_equal "abc123", item.raw["id"]
    assert_equal "My Login", item.raw[:title]
  end

  def test_method_missing_provides_dynamic_access_to_top_level_keys
    hash = { "title" => "My Login", "id" => "abc123", "category" => "LOGIN" }
    item = Rbop::Item.new(hash)
    
    assert_equal "My Login", item.title
    assert_equal "abc123", item.id
    assert_equal "LOGIN", item.category
  end

  def test_respond_to_missing_returns_true_for_existing_keys
    hash = { "title" => "My Login", "id" => "abc123" }
    item = Rbop::Item.new(hash)
    
    assert item.respond_to?(:title)
    assert item.respond_to?(:id)
    assert item.respond_to?("title")
    assert item.respond_to?("id")
  end

  def test_respond_to_missing_returns_false_for_non_existing_keys
    hash = { "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    refute item.respond_to?(:missing_key)
    refute item.respond_to?("missing_key")
  end

  def test_method_missing_raises_error_for_undefined_keys
    hash = { "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    error = assert_raises(NoMethodError) do
      item.missing_key
    end
    
    assert_match(/undefined method .*missing_key/, error.message)
  end

  def test_method_missing_raises_error_when_arguments_provided
    hash = { "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    error = assert_raises(NoMethodError) do
      item.title("extra", "args")
    end
    
    assert_match(/undefined method .*title/, error.message)
  end

  def test_method_missing_raises_error_when_block_provided
    hash = { "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    error = assert_raises(NoMethodError) do
      item.title { "block" }
    end
    
    assert_match(/undefined method .*title/, error.message)
  end

  def test_method_missing_caches_values_in_memo
    hash = { "title" => "My Login" }
    item = Rbop::Item.new(hash)
    
    # Access twice to test caching
    result1 = item.title
    result2 = item.title
    
    assert_equal "My Login", result1
    assert_equal "My Login", result2
    assert_same result1, result2  # Should be the same object due to caching
  end
end