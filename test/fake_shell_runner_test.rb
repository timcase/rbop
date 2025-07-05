# frozen_string_literal: true

require "test_helper"

class FakeShellRunnerTest < Minitest::Test
  def setup
    FakeShellRunner.clear!
    @original_runner = Rbop.shell_runner
    Rbop.shell_runner = FakeShellRunner
  end

  def teardown
    Rbop.shell_runner = @original_runner
  end

  def test_defined_command_returns_expected_stdout
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    result = Rbop.shell_runner.run("op --version")
    
    assert_equal "2.25.0\n", result
  end

  def test_defined_command_with_non_zero_status_raises_error
    FakeShellRunner.define("op signin", stdout: "Authentication failed\n", status: 1)
    
    error = assert_raises(StandardError) do
      Rbop.shell_runner.run("op signin")
    end
    
    assert_equal "Command failed with status 1: op signin", error.message
    assert_equal "Authentication failed\n", error.stdout
    assert_equal 1, error.status
  end

  def test_undefined_command_returns_empty_string
    result = Rbop.shell_runner.run("undefined command")
    
    assert_equal "", result
  end

  def test_pattern_matching_with_regex
    FakeShellRunner.define(/^op item get/, stdout: '{"title": "Test Item"}', status: 0)
    
    result = Rbop.shell_runner.run("op item get 12345")
    
    assert_equal '{"title": "Test Item"}', result
  end

  def test_calls_and_last_call_helpers
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test"}', status: 0)
    
    Rbop.shell_runner.run("op --version")
    Rbop.shell_runner.run("op whoami --format=json", { "OP_SESSION_test" => "token123" })
    
    assert_equal 2, FakeShellRunner.calls.length
    
    last_call = FakeShellRunner.last_call
    assert_equal "op whoami --format=json", last_call[:cmd]
    assert_equal({ "OP_SESSION_test" => "token123" }, last_call[:env])
    
    first_call = FakeShellRunner.calls.first
    assert_equal "op --version", first_call[:cmd]
    assert_equal({}, first_call[:env])
  end
end