# frozen_string_literal: true

require "test_helper"

class TestShell < Minitest::Test
  def test_run_with_string_command_success
    stdout, status = Rbop::Shell.run("echo hi")

    assert_equal "hi\n", stdout
    assert_equal 0, status
  end

  def test_run_with_array_command_success
    stdout, status = Rbop::Shell.run([ "echo", "hi" ])

    assert_equal "hi\n", stdout
    assert_equal 0, status
  end

  def test_run_with_non_zero_exit_status
    exception = assert_raises(Rbop::Shell::CommandFailed) do
      Rbop::Shell.run("exit 1")
    end

    assert_equal "exit 1", exception.command
    assert_equal 1, exception.status
    assert_equal "Command failed with status 1: exit 1", exception.message
  end

  def test_run_with_environment_variables
    stdout, status = Rbop::Shell.run("echo $TEST_VAR", { "TEST_VAR" => "hello" })

    assert_equal "hello\n", stdout
    assert_equal 0, status
  end

  def test_shell_runner_module_attribute
    # Verify default shell runner
    assert_equal Rbop::Shell, Rbop.shell_runner

    # Create fake runner for testing
    fake_runner = Module.new do
      @commands = []

      class << self
        attr_reader :commands

        def run(cmd, env = {})
          @commands << { cmd: cmd, env: env }
          [ "fake output\n", 0 ]
        end
      end
    end

    # Replace shell runner
    original_runner = Rbop.shell_runner
    Rbop.shell_runner = fake_runner

    # Use the fake runner
    stdout, status = Rbop.shell_runner.run("echo test")

    assert_equal "fake output\n", stdout
    assert_equal 0, status
    assert_equal 1, fake_runner.commands.length
    assert_equal "echo test", fake_runner.commands.first[:cmd]

    # Restore original runner
    Rbop.shell_runner = original_runner
  end

  def test_fake_runner_with_command_failed
    # Create fake runner that mimics Shell behavior with non-zero status
    fake_runner = Module.new do
      class << self
        def run(cmd, env = {})
          cmd_string = cmd.is_a?(Array) ? cmd.join(" ") : cmd
          # Simulate non-zero exit status
          status = 42
          raise Rbop::Shell::CommandFailed.new(cmd_string, status)
        end
      end
    end

    # Replace shell runner
    original_runner = Rbop.shell_runner
    Rbop.shell_runner = fake_runner

    # Verify CommandFailed is raised with FakeRunner
    exception = assert_raises(Rbop::Shell::CommandFailed) do
      Rbop.shell_runner.run("some command")
    end

    assert_equal "some command", exception.command
    assert_equal 42, exception.status
    assert_equal "Command failed with status 42: some command", exception.message

    # Restore original runner
    Rbop.shell_runner = original_runner
  end
end
