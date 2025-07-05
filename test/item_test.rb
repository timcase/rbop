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

  def test_field_methods_provide_access_to_field_labels
    hash = {
      "title" => "My Login",
      "fields" => [
        { "label" => "password", "value" => "secret123" },
        { "label" => "username", "value" => "user@example.com" },
        { "label" => "Security Question", "value" => "What is your name?" }
      ]
    }
    item = Rbop::Item.new(hash)
    
    assert_equal({ "label" => "password", "value" => "secret123" }, item.password)
    assert_equal({ "label" => "username", "value" => "user@example.com" }, item.username)
    assert_equal({ "label" => "Security Question", "value" => "What is your name?" }, item.security_question)
  end

  def test_field_collision_with_data_key_uses_field_prefix
    hash = {
      "password" => "top_level_password",  # This will collide
      "fields" => [
        { "label" => "password", "value" => "field_password_value" }
      ]
    }
    item = Rbop::Item.new(hash)
    
    # Top-level key should be accessible normally
    assert_equal "top_level_password", item.password
    
    # Field should be accessible with field_ prefix
    assert_equal({ "label" => "password", "value" => "field_password_value" }, item.field_password)
  end

  def test_field_collision_with_ruby_method_uses_field_prefix
    hash = {
      "fields" => [
        { "label" => "class", "value" => "some_class_value" },
        { "label" => "object_id", "value" => "some_id_value" }
      ]
    }
    item = Rbop::Item.new(hash)
    
    # Ruby methods should not be overridden
    assert_instance_of Class, item.class
    assert_instance_of Integer, item.object_id
    
    # Fields should be accessible with field_ prefix
    assert_equal({ "label" => "class", "value" => "some_class_value" }, item.field_class)
    assert_equal({ "label" => "object_id", "value" => "some_id_value" }, item.field_object_id)
  end

  def test_respond_to_missing_works_for_field_methods
    hash = {
      "fields" => [
        { "label" => "password", "value" => "secret123" },
        { "label" => "username", "value" => "user@example.com" }
      ]
    }
    item = Rbop::Item.new(hash)
    
    assert item.respond_to?(:password)
    assert item.respond_to?(:username)
    assert item.respond_to?("password")
    assert item.respond_to?("username")
    refute item.respond_to?(:nonexistent_field)
  end

  def test_field_methods_handle_camel_case_labels
    hash = {
      "fields" => [
        { "label" => "firstName", "value" => "John" },
        { "label" => "lastName", "value" => "Doe" },
        { "label" => "phoneNumber", "value" => "555-1234" }
      ]
    }
    item = Rbop::Item.new(hash)
    
    assert_equal({ "label" => "firstName", "value" => "John" }, item.first_name)
    assert_equal({ "label" => "lastName", "value" => "Doe" }, item.last_name)
    assert_equal({ "label" => "phoneNumber", "value" => "555-1234" }, item.phone_number)
  end

  def test_field_methods_handle_missing_or_invalid_fields
    hash = {
      "fields" => [
        { "label" => "valid_field", "value" => "valid_value" },
        { "value" => "no_label" },  # Missing label
        "invalid_field",  # Not a hash
        nil  # Nil entry
      ]
    }
    item = Rbop::Item.new(hash)
    
    # Only valid field should be accessible
    assert_equal({ "label" => "valid_field", "value" => "valid_value" }, item.valid_field)
    assert item.respond_to?(:valid_field)
    
    # Invalid fields should not create methods
    refute item.respond_to?(:no_label)
  end

  def test_item_without_fields_array_works_normally
    hash = { "title" => "My Login", "id" => "abc123" }
    item = Rbop::Item.new(hash)
    
    assert_equal "My Login", item.title
    assert_equal "abc123", item.id
    assert item.respond_to?(:title)
    assert item.respond_to?(:id)
  end
end