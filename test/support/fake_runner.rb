# frozen_string_literal: true

class FakeShellRunner
  class << self
    def run(cmd, env = {})
      calls << { cmd: cmd, env: env }
      # Convert array command to string like the real Shell.run does
      cmd_string = cmd.is_a?(Array) ? cmd.join(" ") : cmd
      response = registry.find { |pattern, _| cmd_string.match?(pattern) }
      if response
        stdout = response[1][:stdout]
        status = response[1][:status]

        if status != 0
          error = Rbop::Shell::CommandFailed.new(cmd_string, status)
          error.define_singleton_method(:stdout) { stdout }
          raise error
        end

        [ stdout, status ]
      else
        [ "", 0 ]
      end
    end

    def define(cmd_pattern, stdout:, status: 0)
      registry << [ cmd_pattern, { stdout: stdout, status: status } ]
    end

    def clear!
      @registry = []
      @calls = []
    end

    def calls
      @calls ||= []
    end

    def last_call
      calls.last
    end

    def find_call(cmd_pattern)
      calls.find do |call|
        cmd_string = call[:cmd].is_a?(Array) ? call[:cmd].join(" ") : call[:cmd]
        cmd_string.match?(cmd_pattern)
      end
    end

    # Legacy methods for backward compatibility
    def invocations
      calls
    end

    def find_invocation(cmd_pattern)
      find_call(cmd_pattern)
    end

    private

    def registry
      @registry ||= []
    end
  end
end
