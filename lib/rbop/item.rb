# frozen_string_literal: true

require "active_support/inflector"
require "time"
require "set"

module Rbop
  class Item
    attr_reader :raw

    # ISO-8601 datetime pattern
    ISO_8601_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/

    def initialize(raw_hash)
      @raw = raw_hash
      @data = deep_dup(raw_hash)
      @memo = {}
      @field_methods = {}
      build_field_methods
    end

    def to_h
      deep_dup(@data)
    end

    alias_method :as_json, :to_h

    def [](key)
      key_str = key.to_s
      return @memo[:"[#{key_str}]"] if @memo.key?(:"[#{key_str}]")

      value = @data[key_str]
      @memo[:"[#{key_str}]"] = cast_value(key_str, value)
    end

    def method_missing(method_name, *args, &block)
      if args.empty? && !block_given?
        method_str = method_name.to_s

        # Check for field methods first
        if field_info = @field_methods[method_str]
          field = field_info[:field]
          # For field methods, we want to return just the value, not the entire field structure
          if field.is_a?(Hash) && field.key?("value")
            value = field["value"]
            return @memo[method_name] ||= cast_value(field_info[:label], value)
          else
            return @memo[method_name] ||= field
          end
        end

        # Check for top-level data keys
        if @data.key?(method_str)
          value = @data[method_str]
          return @memo[method_name] ||= cast_value(method_str, value)
        end
      end

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      @field_methods.key?(method_name.to_s) || @data.key?(method_name.to_s) || super
    end

    private

    def cast_value(key, value)
      return value unless value.is_a?(String)

      # Cast if key ends with _at or value matches ISO-8601 pattern
      if key.to_s.end_with?("_at") || value.match?(ISO_8601_REGEX)
        begin
          Time.parse(value)
        rescue ArgumentError
          value  # Return original value if parsing fails
        end
      else
        value
      end
    end

    def build_field_methods
      fields = @data["fields"]
      return unless fields.is_a?(Array)

      used_method_names = Set.new

      fields.each do |field|
        next unless field.is_a?(Hash) && field["label"]

        label = field["label"]
        base_method_name = ActiveSupport::Inflector.underscore(label.gsub(/\s+/, "_"))
        method_name = base_method_name

        # Check if method name is already used or has collision
        if used_method_names.include?(method_name) || has_collision?(method_name)
          method_name = "field_#{base_method_name}"

          # Handle collision enumeration for field_ prefixed names
          counter = 2
          while used_method_names.include?(method_name)
            method_name = "field_#{base_method_name}_#{counter}"
            counter += 1
          end
        end

        used_method_names.add(method_name)
        @field_methods[method_name] = { field: field, label: label }
      end
    end

    def has_collision?(method_name)
      # Check if method exists in Ruby object hierarchy
      respond_to?(method_name, true) ||
      # Check if it collides with top-level data keys
      @data.key?(method_name) ||
      # Check if it's a dangerous Ruby method
      %w[object_id class send].include?(method_name)
    end

    def deep_dup(obj)
      case obj
      when Hash
        obj.transform_keys(&:to_s).transform_values { |v| deep_dup(v) }
      when Array
        obj.map { |v| deep_dup(v) }
      else
        obj.dup rescue obj
      end
    end
  end
end
