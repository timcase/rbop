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

    assert_equal("secret123", item.password)
    assert_equal("user@example.com", item.username)
    assert_equal("What is your name?", item.security_question)
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
    assert_equal("field_password_value", item.field_password)
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
    assert_equal("some_class_value", item.field_class)
    assert_equal("some_id_value", item.field_object_id)
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

  def test_respond_to_missing_works_for_collision_field_methods
    hash = {
      "password" => "top_level_password",  # This will cause collision
      "fields" => [
        { "label" => "password", "value" => "field_password_value" }
      ]
    }
    item = Rbop::Item.new(hash)

    # Top-level password should be accessible
    assert item.respond_to?(:password)

    # Field with collision should be accessible with field_ prefix
    assert item.respond_to?(:field_password)
    assert item.respond_to?("field_password")
  end

  def test_comprehensive_item_functionality
    # Comprehensive fixture JSON covering all scenarios
    fixture_hash = {
      "id" => "item_abc123",
      "title" => "My Secure Login",
      "category" => "LOGIN",
      "vault" => {
        "id" => "vault_def456",
        "name" => "Personal"
      },
      "created_at" => "2023-12-01T10:30:00Z",
      "updated_at" => "2023-12-15T14:45:30.123Z",
      "last_modified_time" => "2023-12-20T09:15:45+05:00",
      "password" => "top_level_password_value",  # Will cause collision with field
      "class" => "top_level_class_value",       # Will cause collision with Ruby method
      "tags" => ["work", "important"],
      "fields" => [
        # Basic field methods
        { "label" => "username", "value" => "john.doe@example.com" },
        { "label" => "url", "value" => "https://example.com/login" },

        # Timestamp casting in fields
        { "label" => "lastLoginAt", "value" => "2023-12-25T12:00:00Z" },
        { "label" => "expiryDate", "value" => "2024-06-01T00:00:00Z" },
        { "label" => "normalField", "value" => "just a string" },

        # CamelCase to snake_case conversion
        { "label" => "firstName", "value" => "John" },
        { "label" => "lastName", "value" => "Doe" },
        { "label" => "phoneNumber", "value" => "555-1234" },

        # Space handling
        { "label" => "Security Question", "value" => "What is your favorite color?" },
        { "label" => "Recovery Email", "value" => "recovery@example.com" },

        # Collision scenarios
        { "label" => "password", "value" => "field_password_value" },  # Collides with top-level key
        { "label" => "class", "value" => "first_class_field" },        # Collides with Ruby method
        { "label" => "class", "value" => "second_class_field" },       # Numeric suffix needed
        { "label" => "class", "value" => "third_class_field" },        # _3 suffix needed

        # Invalid field entries (should be ignored)
        { "value" => "no_label_field" },  # Missing label
        "invalid_string_field",           # Not a hash
        nil,                              # Nil entry
        { "label" => "", "value" => "empty_label" }  # Empty label
      ]
    }

    item = Rbop::Item.new(fixture_hash)

    # Test key methods (top-level data access)
    assert_equal "item_abc123", item.id
    assert_equal "My Secure Login", item.title
    assert_equal "LOGIN", item.category
    assert_equal({ "id" => "vault_def456", "name" => "Personal" }, item.vault)
    assert_equal ["work", "important"], item.tags

    # Test timestamp casting for top-level keys
    assert_instance_of Time, item.created_at
    assert_instance_of Time, item.updated_at
    assert_instance_of Time, item.last_modified_time
    assert_equal "2023-12-01T10:30:00Z", item.created_at.iso8601

    # Test bracket access
    assert_equal "item_abc123", item["id"]
    assert_equal "item_abc123", item[:id]
    assert_instance_of Time, item["created_at"]
    assert_instance_of Time, item[:updated_at]

    # Test field methods (basic)
    assert_equal("john.doe@example.com", item.username)
    assert_equal("https://example.com/login", item.url)

    # Test field timestamp casting
    last_login_value = item.last_login_at
    assert_instance_of Time, last_login_value
    assert_equal "2023-12-25T12:00:00Z", last_login_value.iso8601

    expiry_value = item.expiry_date
    assert_instance_of Time, expiry_value

    normal_value = item.normal_field
    assert_equal "just a string", normal_value

    # Test CamelCase conversion
    assert_equal("John", item.first_name)
    assert_equal("Doe", item.last_name)
    assert_equal("555-1234", item.phone_number)

    # Test space handling
    assert_equal("What is your favorite color?", item.security_question)
    assert_equal("recovery@example.com", item.recovery_email)

    # Test collision handling
    assert_equal "top_level_password_value", item.password  # Top-level wins
    assert_equal("field_password_value", item.field_password)

    # Test Ruby method collision with numeric suffixes
    assert_equal "top_level_class_value", item["class"]  # Via bracket access
    assert_equal("first_class_field", item.field_class)
    assert_equal("second_class_field", item.field_class_2)
    assert_equal("third_class_field", item.field_class_3)

    # Test respond_to for all methods
    assert item.respond_to?(:id)
    assert item.respond_to?(:username)
    assert item.respond_to?(:first_name)
    assert item.respond_to?(:security_question)
    assert item.respond_to?(:field_password)
    assert item.respond_to?(:field_class)
    assert item.respond_to?(:field_class_2)
    assert item.respond_to?(:field_class_3)

    # Test to_h deep copy
    copy = item.to_h
    copy["title"] = "Modified Title"
    copy["vault"]["name"] = "Modified Vault"
    copy["tags"] << "modified"

    assert_equal "My Secure Login", item.title
    assert_equal "Personal", item.vault["name"]
    assert_equal 2, item.tags.length

    # Test as_json alias
    assert_equal item.to_h, item.as_json
    refute_same item.to_h, item.as_json

    # Test invalid field entries are ignored
    refute item.respond_to?(:no_label_field)
    refute item.respond_to?(:invalid_string_field)
    refute item.respond_to?(:empty_label)
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

    assert_equal("John", item.first_name)
    assert_equal("Doe", item.last_name)
    assert_equal("555-1234", item.phone_number)
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
    assert_equal("valid_value", item.valid_field)
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

  def test_timestamp_casting_for_keys_ending_with_at
    hash = {
      "created_at" => "2023-12-01T10:30:00Z",
      "updated_at" => "2023-12-02T15:45:30+05:00",
      "deleted_at" => "2023-12-03T20:15:45.123Z"
    }
    item = Rbop::Item.new(hash)

    assert_instance_of Time, item.created_at
    assert_instance_of Time, item.updated_at
    assert_instance_of Time, item.deleted_at

    assert_equal "2023-12-01T10:30:00Z", item.created_at.iso8601
    assert_equal "2023-12-02T15:45:30+05:00", item.updated_at.iso8601
  end

  def test_timestamp_casting_for_iso_8601_values
    hash = {
      "some_date" => "2023-12-01T10:30:00Z",
      "another_field" => "2023-12-02T15:45:30.456+02:00",
      "not_a_date" => "just a string"
    }
    item = Rbop::Item.new(hash)

    assert_instance_of Time, item.some_date
    assert_instance_of Time, item.another_field
    assert_equal "just a string", item.not_a_date
  end

  def test_timestamp_casting_with_bracket_access
    hash = {
      "created_at" => "2023-12-01T10:30:00Z",
      "some_date" => "2023-12-02T15:45:30Z",
      "normal_field" => "regular value"
    }
    item = Rbop::Item.new(hash)

    assert_instance_of Time, item["created_at"]
    assert_instance_of Time, item[:some_date]
    assert_equal "regular value", item["normal_field"]
  end

  def test_field_timestamp_casting
    hash = {
      "fields" => [
        { "label" => "lastEditedAt", "value" => "2023-12-01T10:30:00Z" },
        { "label" => "createdDate", "value" => "2023-12-02T15:45:30Z" },
        { "label" => "normalField", "value" => "regular value" }
      ]
    }
    item = Rbop::Item.new(hash)

    # Field methods should cast timestamp values
    last_edited_value = item.last_edited_at
    assert_instance_of Time, last_edited_value

    created_date_value = item.created_date
    assert_instance_of Time, created_date_value

    normal_value = item.normal_field
    assert_equal "regular value", normal_value
  end

  def test_timestamp_casting_memoization
    hash = { "created_at" => "2023-12-01T10:30:00Z" }
    item = Rbop::Item.new(hash)

    time1 = item.created_at
    time2 = item.created_at

    assert_instance_of Time, time1
    assert_same time1, time2  # Should be the same object due to memoization
  end

  def test_invalid_timestamp_returns_original_value
    hash = {
      "created_at" => "invalid-date-string",
      "some_field" => "2023-13-45T99:99:99Z"  # Invalid date
    }
    item = Rbop::Item.new(hash)

    # Should return original strings when parsing fails
    assert_equal "invalid-date-string", item.created_at
    assert_equal "2023-13-45T99:99:99Z", item.some_field
  end

  def test_non_string_values_not_cast
    hash = {
      "created_at" => 1234567890,  # Integer timestamp
      "updated_at" => nil,
      "deleted_at" => { "nested" => "object" }
    }
    item = Rbop::Item.new(hash)

    assert_equal 1234567890, item.created_at
    assert_nil item.updated_at
    assert_equal({ "nested" => "object" }, item.deleted_at)
  end

  def test_field_collision_enumeration_numbering
    hash = {
      "fields" => [
        { "label" => "code", "value" => "first_code_value" },
        { "label" => "code", "value" => "second_code_value" }
      ]
    }
    item = Rbop::Item.new(hash)

    # First field with "code" label should get the method
    assert_equal("first_code_value", item.code)

    # Second field with same "code" label should get field_ prefix
    assert_equal("second_code_value", item.field_code)

    # Verify respond_to works
    assert item.respond_to?(:code)
    assert item.respond_to?(:field_code)
  end

  def test_field_collision_enumeration_numbering_with_field_prefix
    hash = {
      "class" => "top_level_class",  # This will cause collision
      "fields" => [
        { "label" => "class", "value" => "first_class_field" },
        { "label" => "class", "value" => "second_class_field" },
        { "label" => "class", "value" => "third_class_field" }
      ]
    }
    item = Rbop::Item.new(hash)

    # Top-level key should be accessible via bracket access (can't override class method)
    assert_equal "top_level_class", item["class"]

    # First field labeled "class" should get field_ prefix due to collision
    assert_equal("first_class_field", item.field_class)

    # Second field should get _2 suffix
    assert_equal("second_class_field", item.field_class_2)

    # Third field should get _3 suffix
    assert_equal("third_class_field", item.field_class_3)

    # Verify respond_to works
    assert item.respond_to?(:field_class)
    assert item.respond_to?(:field_class_2)
    assert item.respond_to?(:field_class_3)
  end
end