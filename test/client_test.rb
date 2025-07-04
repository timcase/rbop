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

  def test_whoami_returns_true_when_authenticated
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    assert_equal true, client.whoami?
  end

  def test_whoami_returns_false_when_not_authenticated
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: "", status: 1)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    assert_equal false, client.whoami?
  end

  def test_signin_success_returns_true_and_sets_token
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op signin test-account --raw --force", stdout: "OPSESSIONTOKEN\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    result = client.signin!
    
    assert_equal true, result
    assert_equal "OPSESSIONTOKEN", client.token
  end

  def test_signin_failure_raises_runtime_error
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op signin test-account --raw --force", stdout: "", status: 1)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    error = assert_raises(RuntimeError) do
      client.signin!
    end
    
    assert_equal "1Password sign-in failed", error.message
    assert_nil client.token
  end
end