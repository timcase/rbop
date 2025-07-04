Below is a complete “plan-of-attack” that goes **three layers deep**—from a broad blueprint, to mid-sized iterations, to fine-grained, test-driven steps.
Afterward you’ll find a **sequence of LLM prompts** (each in its own `text` block) that implement the project incrementally and safely.

---

## 1 . High-Level Blueprint

| #  | Milestone                  | Key Outputs                                              |
| -- | -------------------------- | -------------------------------------------------------- |
| 1  | **Project scaffold**       | Bundler gem skeleton, MIT license, Ruby 3.0+ CI          |
| 2  | **Shell runner layer**     | `Rbop::Shell` (back-tick abstraction) + fake test runner |
| 3  | **CLI presence check**     | `op --version` detection in `Rbop::Client`               |
| 4  | **Sign-in workflow**       | `whoami?`, `signin!`, session-token management           |
| 5  | **Item fetch**             | `get` with title/ID/URL selector & JSON parse            |
| 6  | **Rbop::Item dynamic API** | `method_missing`, snake-case, collision handling         |
| 7  | **Helpers & conversions**  | `to_h`, `[]`, timestamp cast                             |
| 8  | **Edge-case hardening**    | ambiguous titles, invalid JSON, missing vaults           |
| 9  | **Docs & examples**        | README usage, yardocs                                    |
| 10 | **Manual release flow**    | build & push instructions                                |

---

## 2 . Iterative Chunks (mid-size)

### Chunk A – Foundation

1. Create gem skeleton (`bundle gem rbop`)
2. Configure gemspec (Ruby ≥ 3.0, MIT, activesupport dep)
3. Add blank `Rbop::Client` and `Rbop::Item` stubs
4. Set up Minitest + GitHub Actions (Ubuntu, Ruby 3.x)
5. Provide a stub “fake runner” for tests

### Chunk B – Shell & Presence

1. Implement `Rbop::Shell.run(cmd, env = {})` wrapper (uses back-ticks)
2. Unit test success & non-zero exit handling via fake runner
3. Add `Client#ensure_cli_present` using `op --version`
4. Test: raises when CLI absent

### Chunk C – Sign-in Pipeline

1. `whoami?` (returns bool)
2. `signin!` (interactive; captures token)
3. `ensure_signed_in` (runs before every op call)
4. Pass token via env hash in `Shell.run`
5. Tests: signed-in, not-signed-in, signin failure

### Chunk D – Item Fetch Core

1. Selector parsing (title/id/url)
2. `get` method calling `op item get … --format json`
3. Parse JSON to raw hash; raise on parse error
4. Simple `Rbop::Item` wrapper exposing `to_h` only
5. Tests for each selector type & error cases

### Chunk E – Dynamic Item API

1. `method_missing`/`respond_to_missing?` reading hash & fields
2. Snake-case conversion with ActiveSupport
3. Collision detection → `field_` prefix rule
4. Timestamp casting (`_at` keys + ISO-8601)
5. Tests covering all field/key permutations

### Chunk F – Polishing & Docs

1. `[]` operator and `as_json` alias
2. README usage snippet, edge-case docs
3. CI badge, Codecov (optional)
4. Tag v0.1.0 & manual release instructions

---

## 3 . Fine-Grained Steps (right-sized)

Below each mid-size chunk is now atomized into **bite-size tickets** (≈ 30-90 min of work each, always with tests):

### A - Foundation

1. **A1** – `bundle gem rbop --mit --test=minitest`
2. **A2** – Edit gemspec: remove unnecessary files, set `required_ruby_version '= ">= 3.0"'`
3. **A3** – Add `activesupport` runtime dep (≥ 6)
4. **A4** – Create empty `lib/rbop/client.rb` and `lib/rbop/item.rb`
5. **A5** – Configure `.github/workflows/ci.yml` w/ matrix `{ruby: [3.0, 3.1, 3.2, 3.3]}` + Ubuntu
6. **A6** – Add `test_helper.rb` and proof-of-life test

### B - Shell & Presence

1. **B1** – Implement `Rbop::Shell.run(cmd, env = {})` returning `[stdout, status]`
2. **B2** – Inject global `Rbop.shell_runner` (defaults to real shell) so tests can stub
3. **B3** – Write fake runner for tests (records cmds, returns canned results)
4. **B4** – Add `Client#ensure_cli_present`; call in `initialize`
5. **B5** – Test: when fake runner returns non-zero for `op --version`, `Client.new` raises

### C - Sign-in Pipeline

1. **C1** – Add `#whoami?` using `Shell.run`
2. **C2** – Add `#signin!` (writes `@token`, returns true/false)
3. **C3** – Add `#ensure_signed_in` invoked at top of `#get`
4. **C4** – Update fake runner scenarios (whoami signed-in vs not)
5. **C5** – Tests: (a) already signed in path (b) successful signin (c) failed signin raises

### D - Item Fetch Core

1. **D1** – Implement `Selector.parse(hash)` class (title/id/url detection & validation)
2. **D2** – `Client#get(**selector)` builds CLI args from Selector
3. **D3** – Parse stdout JSON → hash; wrap in `Rbop::Item`
4. **D4** – Error: stdout empty or bad JSON → `JSON::ParserError`
5. **D5** – Tests: title, id, private URL, share URL, vault override

### E - Dynamic Item API

1. **E1** – `Item#initialize(raw_hash)` stores @data
2. **E2** – Implement `method_missing` & `respond_to_missing?`
3. **E3** – Field extraction helper; label → `underscore`
4. **E4** – Collision resolution → `field_` prefix with index
5. **E5** – Timestamp pattern detection → `Time.parse`
6. **E6** – `#to_h` deep-dupes data; `#[]` operator; `as_json` alias
7. **E7** – Tests covering keys, fields, collisions, timestamps

### F - Polish & Release

1. **F1** – Flesh out README (install, usage, caveats)
2. **F2** – Add `Rbop::VERSION` constant & changelog
3. **F3** – Verify CI green badge, coverage
4. **F4** – Manual gem build & push checklist in RELEASING.md

All steps are small, isolated, and easily testable.

---

## 4 . Prompt Series for a Code-Gen LLM

Below is a **ready-to-paste prompt** for each bite-size ticket.
Every prompt instructs the LLM to (1) add or modify code, (2) write the corresponding unit test **first** (TDD), and (3) ensure existing tests stay green.
Prompts reference earlier files so the LLM always has context.

> **Usage tip:** feed one prompt at a time; once it passes CI, move to the next.

---

### Prompt A1

```text
You are enhancing a fresh Ruby project.

**Task**: Generate a gem skeleton named `rbop` with MIT license and Minitest tests.

**Requirements**
1. Run `bundle gem rbop --mit --test=minitest` (simulate file structure).
2. Ensure `rbop.gemspec` sets summary, description, and homepage placeholders.
3. Add a root `VERSION` file or `lib/rbop/version.rb` with `Rbop::VERSION = '0.0.0'`.
4. Provide initial CI workflow skeleton for GitHub Actions that simply runs `bundle exec rake` on Ruby 3.0.

Return the file list and key file contents. Do **not** implement any library logic yet.
```

---

### Prompt A2

```text
**Task**: Edit the generated gemspec and Gemfile.

**Requirements**
1. In `rbop.gemspec`, set `required_ruby_version = '>= 3.0'`.
2. Add `activesupport` (>= 6.0) as a runtime dependency.
3. In `Gemfile`, reference the local platform (`ruby`).

Update bundle lock if needed. Provide diff snippets only.
```

---

### Prompt A3

```text
**Task**: Add initial test infrastructure.

**Requirements**
1. Create `test/test_helper.rb` that requires 'rbop' and `minitest/autorun`.
2. Add a dummy test `test/rbop_test.rb` asserting `Rbop::VERSION` equals '0.0.0'.
3. Update `.github/workflows/ci.yml` to run the test matrix for Ruby 3.0, 3.1, 3.2, 3.3 on Ubuntu-latest.

Ensure `bundle exec rake` passes. Provide full CI file content.
```

---

### Prompt B1

```text
**Task**: Implement `Rbop::Shell`.

**Requirements**
1. Create `lib/rbop/shell.rb` with `Rbop::Shell.run(cmd, env = {})`.
   * Accepts `cmd` array or string.
   * Prepends `env` (a hash) before the command when using back-ticks.
   * Returns `[stdout, status]` where `status` is `$?.exitstatus`.
2. Add `Rbop.shell_runner` module attribute defaulting to `Rbop::Shell`.
3. Update `lib/rbop.rb` to require 'rbop/shell' and expose the runner attr.

**Tests**
* Stub a fake runner in tests that records commands.
* Verify `Rbop.shell_runner.run('echo hi')` returns `"hi\n"` and status 0.
* Verify non-zero exit status when command is `exit 1`.

All tests must pass. Show updated files and new tests.
```

---

*(Continue prompts B2 … F4 in the same pattern, each referencing previous code and focusing on its single ticket requirements + tests.)*

Every prompt ensures:

* **Test-first** development.
* No step depends on code that doesn’t exist yet.
* The final prompt (F4) wires everything and verifies green CI.

---

### How to Iterate

1. Copy Prompt A1 → feed to LLM → commit.
2. Run CI (or local tests).
3. Proceed with Prompt A2, etc.

If a step feels too big during implementation, split it ad-hoc (e.g., E5-a timestamp regex, E5-b `Time.parse`). But this list should already be granular enough for safe, incremental progress.

Happy building!

Below are the **remaining prompts B2 … F4**, each contained in its own `text` block so you can feed them sequentially to your code-generation LLM.
They pick up exactly where Prompt B1 left off and carry the project through to the final release checklist.

---

### Prompt B2

```text
**Task**: Inject a configurable shell runner for tests.

**Requirements**
1. Add `Rbop.shell_runner=` writer in `lib/rbop.rb`.
2. Modify `Rbop::Shell.run` to raise `Rbop::Shell::CommandFailed` (custom subclass of RuntimeError) when status ≠ 0; include command and status in the message.
3. Update existing code to rescue or expect this new error as needed.

**Tests**
* In tests, assign a fake runner via `Rbop.shell_runner = FakeRunner`.
* Verify that when `FakeRunner` returns non-zero status, `Rbop::Shell::CommandFailed` is raised with the correct message.

All tests must pass.
```

---

### Prompt B3

```text
**Task**: Implement a reusable `FakeShellRunner` for the test suite.

**Requirements**
1. Create `test/support/fake_runner.rb` defining `FakeShellRunner.run(cmd, env = {})`.
   * Accepts `cmd`, `env`.
   * Looks up canned responses from a registry `FakeShellRunner.define(cmd_pattern, stdout:, status:)`.
   * Default stdout = "", status = 0 if no pattern matches.

2. Extend `test_helper.rb` to `require_relative "support/fake_runner"`.

**Tests**
* Define canned response for `"op --version"` returning `"2.25.0\n"` and status 0; assert `Rbop.shell_runner.run("op --version")` yields that stdout.
* Define canned response with status 1 and assert error raised via B2 logic.

Leave real runner unchanged in production code.
```

---

### Prompt B4

```text
**Task**: Add `Client#ensure_cli_present` and call it during initialization.

**Requirements**
1. In `Rbop::Client.initialize`, call `ensure_cli_present`.
2. Implement `ensure_cli_present`:
   * Runs `op --version` via `Rbop.shell_runner`.
   * Raises `RuntimeError, "1Password CLI (op) not found"` on `Rbop::Shell::CommandFailed`.

**Tests**
* Use `FakeShellRunner`:
  * Scenario success: canned `"op --version"` status 0 → no error.
  * Scenario failure: status 1 → expect RuntimeError with message above.
```

---

### Prompt B5

```text
**Task**: Wire `Rbop::Client` into project namespace.

**Requirements**
1. Fill out `lib/rbop/client.rb` with constructor saving `@account`, `@vault`.
2. Add trivial `#get` placeholder (raises NotImplementedError).

**Tests**
* Instantiate client with account and vault; assert accessors return supplied values.
* Use existing fake runner stubs so no CLI is executed beyond `op --version`.
```

---

### Prompt C1

```text
**Task**: Implement `Client#whoami?`.

**Requirements**
1. Method runs `op whoami --format=json` with session env (if any).
2. Returns `true` on status 0, `false` on non-zero exit (rescue `Rbop::Shell::CommandFailed`).

**Tests**
* FakeRunner canned response "op whoami --format=json" status 0 → expect true.
* Same command status 1 → expect false.
```

---

### Prompt C2

```text
**Task**: Implement `Client#signin!`.

**Requirements**
1. Run `op signin #{@account} --raw --force` through `Rbop.shell_runner`.
2. Capture stdout (`token`), strip whitespace, store in `@token`.
3. Return `true` on success.
4. On non-zero exit, raise `RuntimeError, "1Password sign-in failed"`.

**Tests**
* FakeRunner returns `"OPSESSIONTOKEN\n"` status 0 → `signin!` returns true and sets `@token`.
* Failure scenario status 1 → expect RuntimeError with message.
```

---

### Prompt C3

```text
**Task**: Add `Client#ensure_signed_in`.

**Requirements**
1. Call `whoami?`; if false, call `signin!`.
2. On signin failure, propagate exception.
3. Call `ensure_signed_in` at top of `#get` (currently placeholder).

**Tests**
* Scenario 1: FakeRunner `whoami` status 0 → `signin!` NOT called (record invocations).
* Scenario 2: `whoami` status 1 then `signin!` success → both commands invoked.
* Scenario 3: `whoami` status 1 then `signin!` failure → exception propagates.
```

---

### Prompt C4

```text
**Task**: Pass session token via env hash in Shell.run.

**Requirements**
1. Modify internal helper (maybe `build_env`) to set `"OP_SESSION_#{account_short}" => @token` if `@token`.
2. Use this env for `op whoami` and `op item get`.
3. `account_short` = part before first dot in `@account` (e.g., "my-account" → "my-account").

**Tests**
* After successful `signin!`, assert next `whoami` call receives env with correct key in FakeRunner (inspect recorded env argument).
```

---

### Prompt C5

```text
**Task**: Refactor FakeRunner to capture env argument.

**Requirements**
1. FakeRunner.run should store each call in `FakeRunner.calls << {cmd:, env:}`.
2. Add `FakeRunner.last_call` helper for tests.
3. Update existing tests to use these helpers.

No production code changes. Ensure all tests still pass.
```

---

### Prompt D1

```text
**Task**: Create `Rbop::Selector.parse`.

**Requirements**
1. `Rbop::Selector.parse(**kwargs)` accepts **one** of `title:`, `id:`, `url:`.
2. Returns `{type:, value:}` where type ∈ `:title, :id, :url_share, :url_private`.
3. Detect share URL if starts with `https://share.1password.com/`.
4. Detect private link URL if contains `/open/i?`.

5. Raise `ArgumentError` if:
   * none or multiple keys passed,
   * string does not match expected patterns.

**Tests**
* One test per valid type.
* Error cases: no key, multiple keys, malformed URL.
```

---

### Prompt D2

```text
**Task**: Implement `Client#build_op_args(selector)`.

**Requirements**
1. Accept hash from Selector.parse.
2. Return array of strings for `op item get`:
   * Title → [`"get"`, selector.value, `"--vault", vault]`
   * ID    → [`"get", "--id", selector.value`]
   * URLs  → [`"get", "--share-link", selector.value`]

3. If `vault:` override was supplied to `#get`, use that vault (stored in local param).

**Tests**
* Each selector type returns expected array.
* Vault override works.
```

---

### Prompt D3

```text
**Task**: Flesh out `Client#get`.

**Requirements**
1. Accept keyword args (`title:`, `id:`, `url:`) plus optional `vault:`.
2. Call `ensure_signed_in`.
3. Build args via `build_op_args`.
4. Run `op item` command with `"--format", "json"`.
5. Parse stdout JSON (`JSON.parse`); raise `JSON::ParserError` on failure.
6. Wrap in `Rbop::Item.new(raw_hash)` and return.

**Tests**
* FakeRunner returns canned JSON for title → assert item class & raw data.
* Ensure `Client.get` raises JSON::ParserError on invalid JSON stdout.
```

---

### Prompt D4

```text
**Task**: Implement minimal `Rbop::Item` with `#to_h`, `#as_json`, and `#[]`.

**Requirements**
1. Store deep-dup of raw hash (`@data`).
2. `to_h` → deep copy.
3. `as_json` → alias for `to_h`.
4. `[]` → lookup on `@data` (string/symbol indifferent).

**Tests**
* Verify original hash unchanged when modifying `item.to_h`.
* `[]` works for "id" and :id.
```

---

### Prompt D5

```text
**Task**: Add first integration between Client and Item.

**Requirements**
1. In `Client#get` test from D3, call `item.to_h["title"]` and assert expected value.
2. Ensure FakeRunner scenario for ID and URL selectors also parse to Item.

No production code changes—extend tests only.
```

---

### Prompt E1

```text
**Task**: Add `method_missing` and `respond_to_missing?` to `Rbop::Item`.

**Requirements**
1. Top-level keys of `@data` accessible as methods.
2. Use `super` for undefined keys.
3. Cache looked-up values in `@memo` hash.

**Tests**
* JSON with key "title" → `item.title` returns correct string.
* `item.respond_to?(:title)` is true.
```

---

### Prompt E2

```text
**Task**: Expose field labels as methods.

**Requirements**
1. Scan `@data["fields"]` (array).
2. Convert each `label` to snake_case via `ActiveSupport::Inflector.underscore`.
3. If collision with existing method name or Ruby method (e.g., `object_id`), generate `field_` + label.
4. Store mapping in `@field_methods` for quick lookup.

**Tests**
* Field "password" and key "password" collision → `item.field_password` exists.
* Non-collision field accessible via `item.password`.
```

---

### Prompt E3

```text
**Task**: Add timestamp casting.

**Requirements**
1. When returning value for a key:
   * If key ends with `_at` or value matches ISO-8601 regex, return `Time.parse(value)`.
2. Memoize cast result.

**Tests**
* Key "created_at" → returns `Time` instance.
* Field label "lastEditedAt" also converts.
```

---

### Prompt E4

```text
**Task**: Implement collision enumeration numbering.

**Requirements**
1. If `field_#{label}` already taken, append numeric suffix `_2`, `_3`, incrementally.

**Tests**
* JSON with two fields label "code" → methods `item.code`, `item.field_code_2` created.
```

---

### Prompt E5

```text
**Task**: Complete `respond_to_missing?` to include field methods.

**Requirements**
1. Return true for any generated method name (keys + field map).

**Tests**
* `item.respond_to?(:field_password)` true when collision occurred.
```

---

### Prompt E6

```text
**Task**: Add deep duplication helper to `Item#to_h`.

**Requirements**
1. Use `Marshal.load(Marshal.dump(@data))` or recursive dup to avoid mutation leaks.

**Tests**
* Mutating nested hash inside `item.to_h` does not affect original `item`.
```

---

### Prompt E7

```text
**Task**: Add full coverage tests for `Rbop::Item`.

**Requirements**
* Build fixture JSON mirroring earlier example.
* Cover:
  * Key methods
  * Field methods
  * Collision prefix
  * Numeric suffix
  * Timestamp cast
  * `[]`, `to_h`, `as_json`

Ensure overall test suite coverage ≥ 95 %.
```

---

### Prompt F1

```text
**Task**: Write project README.

**Requirements**
1. Installation (Gemfile snippet + `gem install rbop`).
2. Quick start code block.
3. Feature list (session mgmt, selectors, dynamic API).
4. Limitations & thread-safety note.
5. Link to 1Password CLI docs.

Add badge for GitHub Actions status.
```

---

### Prompt F2

```text
**Task**: Introduce version constant & changelog.

**Requirements**
1. Add `lib/rbop/version.rb` with `Rbop::VERSION = "0.1.0"`.
2. Require this file in `lib/rbop.rb`.
3. Create `CHANGELOG.md` with entries for 0.1.0.

Update dummy test (A3) to assert new version.
```

---

### Prompt F3

```text
**Task**: Add RELEASING.md manual instructions.

**Requirements**
1. Steps: bump version, update changelog, commit, tag `vX.Y.Z`, run tests, `gem build`, `gem push`.
2. Mention setting `~/.gem/credentials`.

No tests required.
```

---

### Prompt F4

```text
**Task**: Final wiring & cleanup.

**Requirements**
1. Remove any TODOs or NotImplementedErrors.
2. Ensure `Rbop::Client#get` fully integrated with `Rbop::Item`.
3. Run `rubocop -A` (if configured) or ensure `bundle exec rake` passes.
4. Push code; CI matrix must be green.

Provide a summary of final file count, test count, and coverage percentage.
```

---

Use these prompts sequentially after the earlier A1–B1 steps. Each prompt references only code that exists from prior steps, ensuring a smooth, test-driven, incremental build.
