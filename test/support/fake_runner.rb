# frozen_string_literal: true

class FakeShellRunner
  class << self
    def run(cmd, env = {})
      calls << { cmd: cmd, env: env }
      response = registry.find { |pattern, _| cmd.match?(pattern) }
      if response
        stdout = response[1][:stdout]
        status = response[1][:status]
        
        if status != 0
          error = Rbop::Shell::CommandFailed.new(cmd, status)
          error.define_singleton_method(:stdout) { stdout }
          raise error
        end
        
        stdout
      else
        ""
      end
    end

    def define(cmd_pattern, stdout:, status: 0)
      registry << [cmd_pattern, { stdout: stdout, status: status }]
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
      calls.find { |call| call[:cmd].match?(cmd_pattern) }
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