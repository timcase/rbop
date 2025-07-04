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
