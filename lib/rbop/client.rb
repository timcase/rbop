# frozen_string_literal: true

require "json"

module Rbop
  class Client
    attr_reader :account, :vault, :token

    def initialize(account:, vault:)
      @account = account
      @vault = vault
      ensure_cli_present
    end

    def get(title: nil, id: nil, url: nil, vault: nil)
      ensure_signed_in
      
      # Build kwargs hash with only non-nil values
      kwargs = {}
      kwargs[:title] = title if title
      kwargs[:id] = id if id
      kwargs[:url] = url if url
      
      selector = Rbop::Selector.parse(**kwargs)
      args = build_op_args(selector, vault)
      args += ["--format", "json"]
      
      cmd = (["op"] + args).join(" ")
      stdout = Rbop.shell_runner.run(cmd, build_env)
      raw_hash = JSON.parse(stdout)
      
      Rbop::Item.new(raw_hash)
    rescue JSON::ParserError
      raise JSON::ParserError, "Invalid JSON response from 1Password CLI"
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

    def build_op_args(selector, vault_override = nil)
      args = ["item", "get"]
      
      case selector[:type]
      when :title
        args << selector[:value]
        args << "--vault"
        args << (vault_override || @vault)
      when :id
        args << "--id"
        args << selector[:value]
      when :url_share, :url_private
        args << "--share-link"
        args << selector[:value]
      end
      
      args
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