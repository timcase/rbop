# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    FakeShellRunner.clear!
    @original_runner = Rbop.shell_runner
    Rbop.shell_runner = FakeShellRunner
  end

  def teardown
    Rbop.shell_runner = @original_runner
  end

  def test_initialize_with_cli_present_succeeds
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    assert_instance_of Rbop::Client, client
    assert_equal "test-account", client.account
    assert_equal "test-vault", client.vault
  end

  def test_initialize_without_cli_raises_runtime_error
    FakeShellRunner.define("op --version", stdout: "", status: 1)
    
    error = assert_raises(RuntimeError) do
      Rbop::Client.new(account: "test-account", vault: "test-vault")
    end
    
    assert_equal "1Password CLI (op) not found", error.message
  end

  def test_get_raises_not_implemented_error
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    error = assert_raises(NotImplementedError) do
      client.get("some-item")
    end
    
    assert_equal "get method not yet implemented", error.message
  end
end