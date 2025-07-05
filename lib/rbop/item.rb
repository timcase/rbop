# frozen_string_literal: true

module Rbop
  class Item
    attr_reader :raw

    def initialize(raw_hash)
      @raw = raw_hash
    end
  end
end