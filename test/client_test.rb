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

  def test_get_with_title_returns_item_object
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    FakeShellRunner.define(/^op item get/, stdout: '{"id":"abc123","title":"My Login","vault":{"id":"vault123"}}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    item = client.get(title: "My Login")
    
    assert_instance_of Rbop::Item, item
    assert_equal "abc123", item.raw["id"]
    assert_equal "My Login", item.raw["title"]
    
    # Verify Item integration works correctly
    assert_equal "My Login", item.to_h["title"]
    assert_equal "abc123", item["id"]
    assert_equal "vault123", item["vault"]["id"]
  end

  def test_get_raises_json_parser_error_on_invalid_json
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    FakeShellRunner.define(/^op item get/, stdout: "invalid json response", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    error = assert_raises(JSON::ParserError) do
      client.get(title: "My Login")
    end
    
    assert_equal "Invalid JSON response from 1Password CLI", error.message
  end

  def test_get_calls_correct_op_command
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    FakeShellRunner.define(/^op item get/, stdout: '{"id":"abc123","title":"My Login"}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    client.get(title: "My Login")
    
    get_call = FakeShellRunner.find_call(/^op item get/)
    refute_nil get_call
    assert_equal "op item get My Login --vault test-vault --format json", get_call[:cmd]
  end

  def test_get_with_id_selector_returns_item_object
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    FakeShellRunner.define(/^op item get/, stdout: '{"id":"abc123","title":"Bank Account","category":"LOGIN"}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    item = client.get(id: "abc123")
    
    assert_instance_of Rbop::Item, item
    assert_equal "abc123", item["id"]
    assert_equal "Bank Account", item.to_h["title"]
    assert_equal "LOGIN", item["category"]
  end

  def test_get_with_url_selector_returns_item_object
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    FakeShellRunner.define(/^op item get/, stdout: '{"id":"def456","title":"Shared Item","urls":[{"href":"https://example.com"}]}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    item = client.get(url: "https://share.1password.com/s/abc123def456")
    
    assert_instance_of Rbop::Item, item
    assert_equal "def456", item["id"]
    assert_equal "Shared Item", item.to_h["title"]
    assert_equal "https://example.com", item["urls"][0]["href"]
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

  def test_ensure_signed_in_when_already_authenticated
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    error = assert_raises(ArgumentError) do
      client.get
    end
    
    assert_equal "Must provide one of: title:, id:, or url:", error.message
    commands = FakeShellRunner.calls.map { |call| call[:cmd] }
    assert_includes commands, "op --version"
    assert_includes commands, "op whoami --format=json"
    refute_includes commands, "op signin test-account --raw --force"
  end

  def test_ensure_signed_in_when_not_authenticated_but_signin_succeeds
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: "", status: 1)
    FakeShellRunner.define("op signin test-account --raw --force", stdout: "OPSESSIONTOKEN\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    error = assert_raises(ArgumentError) do
      client.get
    end
    
    assert_equal "Must provide one of: title:, id:, or url:", error.message
    commands = FakeShellRunner.calls.map { |call| call[:cmd] }
    assert_includes commands, "op --version"
    assert_includes commands, "op whoami --format=json"
    assert_includes commands, "op signin test-account --raw --force"
  end

  def test_ensure_signed_in_when_not_authenticated_and_signin_fails
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: "", status: 1)
    FakeShellRunner.define("op signin test-account --raw --force", stdout: "", status: 1)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    
    error = assert_raises(RuntimeError) do
      client.get(title: "some-item")
    end
    
    assert_equal "1Password sign-in failed", error.message
    commands = FakeShellRunner.calls.map { |call| call[:cmd] }
    assert_includes commands, "op --version"
    assert_includes commands, "op whoami --format=json"
    assert_includes commands, "op signin test-account --raw --force"
  end

  def test_session_token_passed_to_whoami_after_signin
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op signin test-account --raw --force", stdout: "OPSESSIONTOKEN\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"test-account"}', status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    client.signin!
    client.whoami?
    
    whoami_call = FakeShellRunner.find_call("op whoami --format=json")
    refute_nil whoami_call
    assert_equal({ "OP_SESSION_test-account" => "OPSESSIONTOKEN" }, whoami_call[:env])
  end

  def test_account_short_handles_dots_correctly
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op signin my-team.1password.com --raw --force", stdout: "OPSESSIONTOKEN\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: '{"account":"my-team.1password.com"}', status: 0)
    
    client = Rbop::Client.new(account: "my-team.1password.com", vault: "test-vault")
    client.signin!
    client.whoami?
    
    whoami_call = FakeShellRunner.find_call("op whoami --format=json")
    refute_nil whoami_call
    assert_equal({ "OP_SESSION_my-team" => "OPSESSIONTOKEN" }, whoami_call[:env])
  end

  def test_empty_env_when_no_token
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    FakeShellRunner.define("op whoami --format=json", stdout: "", status: 1)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    client.whoami?
    
    whoami_call = FakeShellRunner.find_call("op whoami --format=json")
    refute_nil whoami_call
    assert_equal({}, whoami_call[:env])
  end

  def test_build_op_args_with_title_selector
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    selector = { type: :title, value: "My Login" }
    
    args = client.send(:build_op_args, selector)
    
    assert_equal ["item", "get", "My Login", "--vault", "test-vault"], args
  end

  def test_build_op_args_with_id_selector
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    selector = { type: :id, value: "abc123def456" }
    
    args = client.send(:build_op_args, selector)
    
    assert_equal ["item", "get", "--id", "abc123def456"], args
  end

  def test_build_op_args_with_share_url_selector
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    selector = { type: :url_share, value: "https://share.1password.com/s/abc123" }
    
    args = client.send(:build_op_args, selector)
    
    assert_equal ["item", "get", "--share-link", "https://share.1password.com/s/abc123"], args
  end

  def test_build_op_args_with_private_url_selector
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "test-vault")
    selector = { type: :url_private, value: "https://my-team.1password.com/vaults/abc/allitems/def/open/i?ghi" }
    
    args = client.send(:build_op_args, selector)
    
    assert_equal ["item", "get", "--share-link", "https://my-team.1password.com/vaults/abc/allitems/def/open/i?ghi"], args
  end

  def test_build_op_args_with_vault_override
    FakeShellRunner.define("op --version", stdout: "2.25.0\n", status: 0)
    
    client = Rbop::Client.new(account: "test-account", vault: "default-vault")
    selector = { type: :title, value: "My Login" }
    
    args = client.send(:build_op_args, selector, "override-vault")
    
    assert_equal ["item", "get", "My Login", "--vault", "override-vault"], args
  end
end