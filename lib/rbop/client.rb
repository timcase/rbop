# frozen_string_literal: true

module Rbop
  class Client
    attr_reader :account, :vault, :token

    def initialize(account:, vault:)
      @account = account
      @vault = vault
      ensure_cli_present
    end

    def get(item)
      ensure_signed_in
      raise NotImplementedError, "get method not yet implemented"
    end

    def whoami?
      Rbop.shell_runner.run("op whoami --format=json", build_env)
      true
    rescue Rbop::Shell::CommandFailed
      false
    end

    def signin!
      stdout = Rbop.shell_runner.run("op signin #{@account} --raw --force")
      @token = stdout.strip
      true
    rescue Rbop::Shell::CommandFailed
      raise RuntimeError, "1Password sign-in failed"
    end

    private

    def ensure_signed_in
      signin! unless whoami?
    end

    def build_env
      return {} unless @token
      
      account_short = @account.split('.').first
      { "OP_SESSION_#{account_short}" => @token }
    end

    def ensure_cli_present
      Rbop.shell_runner.run("op --version")
    rescue Rbop::Shell::CommandFailed
      raise RuntimeError, "1Password CLI (op) not found"
    end
  end
end