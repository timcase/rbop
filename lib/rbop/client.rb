# frozen_string_literal: true

module Rbop
  class Client
    attr_reader :account, :vault

    def initialize(account:, vault:)
      @account = account
      @vault = vault
      ensure_cli_present
    end

    def get(item)
      raise NotImplementedError, "get method not yet implemented"
    end

    def whoami?
      Rbop.shell_runner.run("op whoami --format=json")
      true
    rescue Rbop::Shell::CommandFailed
      false
    end

    private

    def ensure_cli_present
      Rbop.shell_runner.run("op --version")
    rescue Rbop::Shell::CommandFailed
      raise RuntimeError, "1Password CLI (op) not found"
    end
  end
end