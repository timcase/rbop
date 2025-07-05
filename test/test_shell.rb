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

  def test_run_with_empty_environment
    stdout, status = Rbop::Shell.run("echo test", {})

    assert_equal "test\n", stdout
    assert_equal 0, status
  end

  def test_run_with_multiple_environment_variables
    stdout, status = Rbop::Shell.run("echo $VAR1-$VAR2", { "VAR1" => "hello", "VAR2" => "world" })

    assert_equal "hello-world\n", stdout
    assert_equal 0, status
  end

  def test_command_failed_exception_attributes
    exception = Rbop::Shell::CommandFailed.new("test command", 42)

    assert_equal "test command", exception.command
    assert_equal 42, exception.status
    assert_equal "Command failed with status 42: test command", exception.message
    assert_instance_of Rbop::Shell::CommandFailed, exception
    assert_kind_of RuntimeError, exception
  end

  def test_array_command_joins_correctly
    stdout, status = Rbop::Shell.run(["echo", "hello", "world"])

    assert_equal "hello world\n", stdout
    assert_equal 0, status
  end

  def test_debug_mode_logs_commands
    # Save original debug state
    original_debug = Rbop.debug

    # Capture stderr output
    captured_output = StringIO.new
    original_stderr = $stderr
    $stderr = captured_output

    begin
      # Enable debug mode
      Rbop.debug = true

      # Run a simple command
      stdout, status = Rbop::Shell.run("echo test")

      # Check command execution worked
      assert_equal "test\n", stdout
      assert_equal 0, status

      # Check debug output
      debug_output = captured_output.string
      assert_match(/\[RBOP DEBUG\] Executing: echo test/, debug_output)
      assert_match(/\[RBOP DEBUG\] Exit status: 0/, debug_output)
      assert_match(/\[RBOP DEBUG\] Output: test\n/, debug_output)
    ensure
      # Restore original state
      Rbop.debug = original_debug
      $stderr = original_stderr
    end
  end

  def test_debug_mode_logs_environment_variables
    # Save original debug state
    original_debug = Rbop.debug

    # Capture stderr output
    captured_output = StringIO.new
    original_stderr = $stderr
    $stderr = captured_output

    begin
      # Enable debug mode
      Rbop.debug = true

      # Run command with environment variables
      stdout, status = Rbop::Shell.run("echo $TEST_VAR", { "TEST_VAR" => "hello" })

      # Check command execution worked
      assert_equal "hello\n", stdout
      assert_equal 0, status

      # Check debug output
      debug_output = captured_output.string
      assert_match(/\[RBOP DEBUG\] Executing: echo \$TEST_VAR/, debug_output)
      assert_match(/\[RBOP DEBUG\] Environment: \{"TEST_VAR" => "hello"\}/, debug_output)
      assert_match(/\[RBOP DEBUG\] Full command: TEST_VAR='hello' bash -c 'echo \$TEST_VAR'/, debug_output)
      assert_match(/\[RBOP DEBUG\] Exit status: 0/, debug_output)
      assert_match(/\[RBOP DEBUG\] Output: hello\n/, debug_output)
    ensure
      # Restore original state
      Rbop.debug = original_debug
      $stderr = original_stderr
    end
  end

  def test_debug_mode_truncates_long_output
    # Save original debug state
    original_debug = Rbop.debug

    # Capture stderr output
    captured_output = StringIO.new
    original_stderr = $stderr
    $stderr = captured_output

    begin
      # Enable debug mode
      Rbop.debug = true

      # Run command that produces long output
      long_string = "a" * 300
      stdout, status = Rbop::Shell.run("echo #{long_string}")

      # Check command execution worked
      assert_equal "#{long_string}\n", stdout
      assert_equal 0, status

      # Check debug output is truncated
      debug_output = captured_output.string
      assert_match(/\[RBOP DEBUG\] Output \(truncated\):/, debug_output)
      assert_match(/\.\.\./, debug_output)
    ensure
      # Restore original state
      Rbop.debug = original_debug
      $stderr = original_stderr
    end
  end

  def test_debug_mode_disabled_by_default
    # Debug mode should be disabled by default
    assert_equal false, Rbop.debug

    # Capture stderr output
    captured_output = StringIO.new
    original_stderr = $stderr
    $stderr = captured_output

    begin
      # Run command with debug disabled
      stdout, status = Rbop::Shell.run("echo test")

      # Check command execution worked
      assert_equal "test\n", stdout
      assert_equal 0, status

      # Check no debug output
      debug_output = captured_output.string
      assert_equal "", debug_output
    ensure
      $stderr = original_stderr
    end
  end
end
