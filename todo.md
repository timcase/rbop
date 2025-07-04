# ✅ rbop TODO Checklist

## 📦 Project Setup

- [ ] Set Ruby version in `.ruby-version` (e.g., `3.3.0`)
- [ ] Create gemspec (`rbop.gemspec`) with metadata and dependencies
- [ ] Create `lib/rbop.rb` and `lib/rbop/version.rb`
- [ ] Create core classes: `Rbop::Client`, `Rbop::Item`, etc.
- [ ] Add `.env` and `.env.example` for config
- [ ] Initialize Git repo and commit base scaffold

## 🔧 Tooling & Dev Experience

- [ ] Add `bin/setup` to bootstrap project
- [ ] Install and configure `dotenv`
- [ ] Add `rubocop` and `rubocop-rails-omakase`
- [ ] Configure `.rubocop.yml`
- [ ] Add `rake` tasks for:
  - [ ] `test`
  - [ ] `lint`
  - [ ] `install`
  - [ ] `release`

## 🧪 Testing

- [ ] Configure `test/test_helper.rb`
- [ ] Set up `minitest`, `mocha`, `factory_bot`
- [ ] Add tests for:
  - [ ] `Rbop::Client` CLI interaction
  - [ ] `Rbop::Item` parsing and representation
  - [ ] Authentication and vault selection (if applicable)

## 🔐 CLI Integration (op)

- [ ] Confirm `op` CLI is installed and on `$PATH`
- [ ] Add method to check `op --version`
- [ ] Implement wrapper for `op item get`
- [ ] Handle session/token management
- [ ] Parse JSON output safely (e.g., `JSON.parse`)
- [ ] Raise Ruby errors on CLI errors

## 🛡️ Error Handling

- [ ] Define `Rbop::Error`
- [ ] Create subclasses (e.g., `OpCommandError`, `AuthenticationError`)
- [ ] Ensure all external calls are wrapped with error guards

## 📚 Documentation

- [ ] Write `README.md` with:
  - [ ] What it is
  - [ ] Installation
  - [ ] Usage examples
  - [ ] Contributing instructions
- [ ] Add YARD doc comments to all public classes/methods
- [ ] Add license (`MIT` or preferred)

## 🚀 Releasing

- [ ] Set up RubyGems account + API key
- [ ] Add `.gem/credentials` to `.gitignore`
- [ ] Use `rake release` to publish
- [ ] Tag releases in Git (`v0.1.0`, etc.)

## 🔁 Optional: CI/CD

- [ ] Add GitHub Actions workflow:
  - [ ] Run tests
  - [ ] Run RuboCop
  - [ ] Lint `.gemspec`
- [ ] Add CodeClimate or SimpleCov if needed
- [ ] Auto-release tagged commits (optional)

## 🧪 Bonus Ideas

- [ ] Support multiple `op` CLI versions
- [ ] Add dry-run or verbose mode for debug
- [ ] Add logging support (with `logger`)
- [ ] Expose objects like `Rbop::Vault`, `Rbop::Session`, `Rbop::Document`
- [ ] Create example usage scripts

---

Let's build it right, step by step. 🧱💎
