# frozen_string_literal: true

require "active_support/inflector"

module Rbop
  class Item
    attr_reader :raw

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
      @data[key.to_s]
    end

    def method_missing(method_name, *args, &block)
      if args.empty? && !block_given?
        # Check for field methods first
        if field_info = @field_methods[method_name.to_s]
          return @memo[method_name] ||= field_info[:field]
        end
        
        # Check for top-level data keys
        if @data.key?(method_name.to_s)
          return @memo[method_name] ||= @data[method_name.to_s]
        end
      end
      
      super
    end

    def respond_to_missing?(method_name, include_private = false)
      @field_methods.key?(method_name.to_s) || @data.key?(method_name.to_s) || super
    end

    private

    def build_field_methods
      fields = @data["fields"]
      return unless fields.is_a?(Array)

      fields.each do |field|
        next unless field.is_a?(Hash) && field["label"]
        
        label = field["label"]
        method_name = ActiveSupport::Inflector.underscore(label.gsub(/\s+/, '_'))
        
        # Check for collisions with existing methods or data keys
        if has_collision?(method_name)
          method_name = "field_#{method_name}"
        end
        
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