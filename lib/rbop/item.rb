# frozen_string_literal: true

module Rbop
  class Item
    attr_reader :raw

    def initialize(raw_hash)
      @raw = raw_hash
      @data = deep_dup(raw_hash)
      @memo = {}
    end

    def to_h
      deep_dup(@data)
    end

    alias_method :as_json, :to_h

    def [](key)
      @data[key.to_s]
    end

    def method_missing(method_name, *args, &block)
      if args.empty? && !block_given? && @data.key?(method_name.to_s)
        @memo[method_name] ||= @data[method_name.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @data.key?(method_name.to_s) || super
    end

    private

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