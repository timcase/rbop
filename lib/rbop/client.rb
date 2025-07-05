# frozen_string_literal: true

require "json"

module Rbop
  class Client
    attr_reader :account, :vault

    def initialize(account:, vault:)
      @account = account
      @vault = vault
      ensure_cli_present
    end

    def get(title: nil, id: nil, url: nil, vault: nil)
      # Build kwargs hash with only non-nil values
      kwargs = {}
      kwargs[:title] = title if title
      kwargs[:id] = id if id
      kwargs[:url] = url if url

      selector = Rbop::Selector.parse(**kwargs)
      args = build_op_args(selector, vault)
      args += [ "--format", "json" ]
      args += [ "--account", @account ]

      cmd = [ "op" ] + args

      begin
        stdout, _status = Rbop.shell_runner.run(cmd)
      rescue Rbop::Shell::CommandFailed
        # If the command failed, assume it's an authentication error and try signing in
        puts "[DEBUG] Command failed, attempting signin..." if Rbop.debug
        signin!
        stdout, _status = Rbop.shell_runner.run(cmd)
      end

      raw_hash = JSON.parse(stdout)
      Rbop::Item.new(raw_hash)
    rescue JSON::ParserError
      raise JSON::ParserError, "Invalid JSON response from 1Password CLI"
    end

    def whoami?
      cmd = "op whoami --format=json"
      cmd += " --account #{@account}" if @account
      stdout, _status = Rbop.shell_runner.run(cmd)

      # Parse the response to ensure it's valid
      data = JSON.parse(stdout)
      !!(data["user_uuid"] && data["account_uuid"])
    rescue Rbop::Shell::CommandFailed, JSON::ParserError
      false
    end


    def signin!
      # Get the session token
      stdout, _status = Rbop.shell_runner.run("op signin --account #{@account} --raw")
      session_token = stdout.strip

      # Set the session token in the environment using the session token itself
      # The op whoami command with the session token will tell us the user UUID
      whoami_stdout, _ = Rbop.shell_runner.run("op whoami --format=json --account #{@account} --session #{session_token}")
      whoami_data = JSON.parse(whoami_stdout)
      user_uuid = whoami_data["user_uuid"]

      # Set the session token in the correct environment variable
      ENV["OP_SESSION_#{user_uuid}"] = session_token

      true
    rescue Rbop::Shell::CommandFailed, JSON::ParserError
      raise RuntimeError, "1Password sign-in failed"
    end

    private

    def ensure_signed_in
      return if whoami?
      signin!
    end

    def build_op_args(selector, vault_override = nil)
      args = [ "item", "get" ]

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

    def ensure_cli_present
      _stdout, _status = Rbop.shell_runner.run("op --version")
    rescue Rbop::Shell::CommandFailed
      raise RuntimeError, "1Password CLI (op) not found"
    end
  end
end
