# frozen_string_literal: true

require_relative "rbop/version"
require_relative "rbop/shell"
require_relative "rbop/client"
require_relative "rbop/selector"
require_relative "rbop/item"

module Rbop
  class Error < StandardError; end

  # Module attribute for shell runner
  class << self
    attr_accessor :shell_runner
  end

  # Set default shell runner
  self.shell_runner = Shell
end
