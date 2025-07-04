# frozen_string_literal: true

module Rbop
  class Client
    def initialize
      ensure_cli_present
    end

    private

    def ensure_cli_present
      Rbop.shell_runner.run("op --version")
    rescue Rbop::Shell::CommandFailed
      raise RuntimeError, "1Password CLI (op) not found"
    end
  end
end