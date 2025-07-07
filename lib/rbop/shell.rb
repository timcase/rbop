# frozen_string_literal: true

require "shellwords"

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
      cmd_string = cmd.is_a?(Array) ? shell_escape_array(cmd) : cmd

      # Log command execution if debug mode is enabled
      if Rbop.debug
        $stderr.puts "[RBOP DEBUG] Executing: #{cmd_string}"
        $stderr.puts "[RBOP DEBUG] Environment: #{env.inspect}" unless env.empty?
      end

      # Merge env into current ENV for the command
      if env.empty?
        stdout = `#{cmd_string}`
      else
        # Use bash -c to ensure variable expansion works properly
        env_string = env.map { |k, v| "#{k}='#{v}'" }.join(" ")
        full_cmd = "#{env_string} bash -c '#{cmd_string}'"
        $stderr.puts "[RBOP DEBUG] Full command: #{full_cmd}" if Rbop.debug
        stdout = `#{full_cmd}`
      end

      status = $?.exitstatus

      # Log results if debug mode is enabled
      if Rbop.debug
        $stderr.puts "[RBOP DEBUG] Exit status: #{status}"
        if stdout.length > 200
          $stderr.puts "[RBOP DEBUG] Output (truncated): #{stdout[0..200]}..."
        else
          $stderr.puts "[RBOP DEBUG] Output: #{stdout}"
        end
      end

      if status != 0
        # For authentication errors, include stderr/stdout in the exception
        error_output = stdout.empty? ? "" : ": #{stdout}"
        raise CommandFailed.new("#{cmd_string}#{error_output}", status)
      end

      [ stdout, status ]
    end

    def shell_escape_array(cmd_array)
      Shellwords.join(cmd_array)
    end

    module_function :shell_escape_array
  end
end
