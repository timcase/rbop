# frozen_string_literal: true

require_relative "rbop/version"
require_relative "rbop/shell"
require_relative "rbop/client"
require_relative "rbop/selector"
require_relative "rbop/item"

module Rbop
  class Error < StandardError; end

  # Module attributes
  class << self
    attr_accessor :shell_runner
    attr_accessor :debug
  end

  # Set defaults
  self.shell_runner = Shell
  self.debug = false
end
