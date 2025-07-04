# **rbop – Developer-Ready Specification**

---

## 1 . Purpose & Scope

`rbop` is a Ruby gem that wraps the 1Password CLI (`op`) so Ruby scripts can fetch secrets from any vault with a single call:

```ruby
client = Rbop::Client.new(account: 'my-account.1password.com', vault: 'Personal')
item   = client.get(title: 'Mobbin')          # or id:, url:
item.username  # ⇒ 'me@something.com'
item.password  # ⇒ 'super-secret-password'
```

The gem **does not** attempt to expose **write** operations, manage vaults, or handle documents/attachments. It is read-only and focused on **login-style items**.

---

## 2 . Compatibility, Dependencies & License

| Aspect             | Decision                                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------- |
| **Ruby versions**  | 3.0 minimum; CI matrix covers every stable 3.x (3.0, 3.1, 3.2, 3.3…).                                             |
| **Runtime gems**   | `activesupport` (≥ 6.0) for `String#underscore`.                                                                  |
| **External tools** | Presence of an `op` binary on `PATH`; *no minimum version enforced*.                                              |
| **License**        | MIT                                                                                                               |
| **Thread safety**  | A single `Rbop::Client` **is not thread-safe**. Callers create one client per thread or handle their own locking. |

---

## 3 . Public API

### 3.1 `Rbop::Client`

```ruby
Rbop::Client.new(
  account: 'my-account.1password.com',  # required
  vault:   'Personal'                   # required
)
```

| Method              | Signature                                                  | Behaviour                                                                                                                                                                                                            |
| ------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `get(...)`          | `get(title: '…')`  <br>`get(id: '…')`  <br>`get(url: '…')` | Fetches an item. Optional `vault:` keyword may override the client-level vault. `account:` **cannot** be overridden. Returns an `Rbop::Item`. If multiple matches for a title, the **first** CLI result is returned. |
| `account` / `vault` | readers                                                    | expose the defaults supplied at construction.                                                                                                                                                                        |

### 3.2 `Rbop::Item`

Dynamic, read-only view of the JSON payload.

* **Keys at depth 1** → methods (`item.title`, `item.created_at`, …).
* **Fields array** → for each element, create a method from `field.label.underscore`, e.g. `"notesPlain"` → `item.notes_plain`.

  * Name collision ➜ additional method with **`field_` prefix** (`field_password`, `field_password_2` …).
* **Type conversions**:

  * Keys ending in `_at` **or ISO-8601 strings** → `Time` objects.
  * Everything else stays as the JSON value.
* Enumerable helpers:

  * `to_h` / `as_json` → deep Ruby `Hash`.
  * `[]` operator for arbitrary key/field access.
* `inspect` / `to_s` → unchanged default (`#<Rbop::Item:0x000055…>`). No automatic redaction or dumping.

---

## 4 . Internal Architecture

```
Rbop
├── Client
│   ├── #initialize
│   ├── #get
│   └── (private)
│       ├── #ensure_cli_present
│       ├── #ensure_signed_in
│       ├── #signin!            # captures session token
│       ├── #whoami?            # returns bool
│       └── #run_op(...)        # low-level shell helper
└── Item
```

### 4.1 Command Execution (`#run_op`)

* **Implementation**: Ruby back-ticks throughout—`stdout = `op …\`\`.
* **Failure detection**: check `$?.exitstatus`.

  * Non-zero ➜ raise `RuntimeError` with `"op exited #{status}: #{cmd}"`.
  * *No additional logging.*
* **Session token injection**:

  ```ruby
  `OP_SESSION_#{@account_short}=#{@token} op item get #{args} --format json`
  ```

  Token lives only in memory.

### 4.2 Sign-in Flow

1. `whoami?` → `op whoami --format=json`

   * success → continue.
   * failure → `signin!`.
2. `signin!` → `op signin #{@account} --raw --force` (interactive).

   * Reads the token from `stdout`.
   * Stores token in `@token` for later use.
   * No environment variable is exported; each command passes the token explicitly.

A sign-in check runs **before every** `get` call (no caching).

---

## 5 . Error Handling

* Only **standard Ruby exceptions** are raised (`RuntimeError`, `ArgumentError`, `JSON::ParserError`, etc.).
* Each error message is descriptive but minimal; no logging side-effects.
* Typical failure cases:

  * CLI missing (`op --version` fails) – `RuntimeError, "1Password CLI (op) not found"`.
  * Sign-in fails – `RuntimeError, "1Password sign-in failed"`.
  * Item not found – `RuntimeError, "No item matching #{selector}"`.
  * Ambiguous selector (title finds 0 items) – same “not found”. > 1 item ➜ first match is returned (documented).

---

## 6 . Testing Plan

| Layer                                     | Strategy                                                                                                                                                                                          |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Unit tests** (Minitest)                 | All CLI interaction is **stubbed**. Inject a fake runner object that returns canned `stdout`, `stderr`, and exit status for each command scenario (success, failure, whoami not signed in, etc.). |
| **Coverage**                              | 100 % of public API paths; key private helpers; collision handling; time conversion.                                                                                                              |
| **Integration tests** (optional / future) | Guarded by `ENV["RBOP_INTEGRATION_TOKEN"]`, can run against a real vault; *not* required in CI.                                                                                                   |

---

## 7 . Continuous Integration (GitHub Actions)

```yaml
# .github/workflows/ci.yml (outline)
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    strategy:
      matrix:
        ruby: [ '3.0', '3.1', '3.2', '3.3' ]
        os:   [ ubuntu-latest ]   # expand to macos/windows later if desired
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
      - run: bundle install --jobs 4 --retry 3
      - run: bundle exec rake
```

*Future enhancement*: add `macos-latest` and `windows-latest` once stub runner proves fully portable.

---

## 8 . Release & Publishing

| Step                                             | Responsibility                                                                               |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| Version bump (`lib/rbop/version.rb`) & changelog | Maintainer                                                                                   |
| Commit & tag (`vX.Y.Z`) on `main`                | Maintainer                                                                                   |
| CI                                               | runs tests only. No automatic publishing.                                                    |
| Manual release                                   | `gem build rbop.gemspec && gem push rbop-X.Y.Z.gem` by maintainer with local RubyGems creds. |

---

## 9 . Open Items / Future Enhancements

* **Cross-account support** – current design requires a separate client per account.
* **Write operations** – add `put`, `edit` later if needed.
* **Pluggable logging / runner** – an injectable runner could simplify testing and power users.
* **Caching** – optional TTL cache for heavy scripts.
* **Thread safety** – mutexes or a pool of CLI processes.

---

## 10 . Implementation Checklist

1. **Gem skeleton** (`bundle gem rbop --mit --test=minitest`).
2. Add **Activesupport** dependency & require only `"active_support/core_ext/string/inflections"`.
3. Implement **Rbop::Client** per section 4.
4. Implement **Rbop::Item** with `method_missing`, collision handling, type conversion, and `to_h` / `[]`.
5. Write **unit tests** with stubbed runner. Aim for ≥ 95 % coverage.
6. Configure **GitHub Actions** workflow.
7. Update **README** with install instructions, example, and limitations.
8. Tag **v0.1.0** and publish manually.

With this specification a developer can start coding immediately, confident that behavior, dependencies, and non-functional requirements are fully defined.
