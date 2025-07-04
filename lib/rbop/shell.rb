# frozen_string_literal: true

module Rbop
  # Shell runner for executing system commands
  module Shell
    # Exception raised when a command fails
    class CommandFailed < RuntimeError
      attr_reader :command, :status

      def initialize(command, status)
        @command = command
        @status = status
        super("Command failed with status #{status}: #{command}")
      end
    end

    module_function

    # Run a command and return stdout and exit status
    #
    # @param cmd [String, Array] Command to execute
    # @param env [Hash] Environment variables to prepend
    # @return [Array<String, Integer>] stdout and exit status
    def run(cmd, env = {})
      cmd_string = cmd.is_a?(Array) ? cmd.join(" ") : cmd

      # Merge env into current ENV for the command
      if env.empty?
        stdout = `#{cmd_string}`
      else
        # Use bash -c to ensure variable expansion works properly
        env_string = env.map { |k, v| "#{k}='#{v}'" }.join(" ")
        stdout = `#{env_string} bash -c '#{cmd_string}'`
      end

      status = $?.exitstatus

      if status != 0
        raise CommandFailed.new(cmd_string, status)
      end

      [ stdout, status ]
    end
  end
end
