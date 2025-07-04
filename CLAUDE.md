# claude.md

## 💎 Project Environment

- **Language**: Ruby 3.4
- **Ruby Version Manager**: rbenv (`.ruby-version` tracked in Git)
- **Project Type**: Ruby gem
- **Source Control**: Git (hosted on GitHub)
- **Gemspec**: Uses `.gemspec` file with `Gem::Specification`
- **Packaging**: Bundler + `rake release`
- **Secrets**: Managed with dotenv for development/testing

## 🧪 Testing & Quality

- **Test Framework**: Minitest (no RSpec)
- **Factories**: FactoryBot
- **Mocking**: Mocha
- **Linting**: RuboCop (`rubocop-performance`, `rubocop-packaging`)

## 📦 Gem Conventions

- `lib/your_gem.rb` loads the gem
- Core logic lives in `lib/your_gem/...`
- `lib/your_gem/version.rb` defines `VERSION`
- Use semantic versioning (SemVer)
- Avoid monkey-patching core classes

## 🔧 Tooling & Workflow

- Use `rbenv install 3.3.0 && rbenv local 3.3.0` to set Ruby version
- Use `bundle install` to install dependencies
- Use `rake install` to install gem locally
- Use `rake release` to push to RubyGems
- Use `bin/setup` to bootstrap dev env
- Git used for all source tracking; `main` is the default branch

## ✅ Goals for Claude

1. Write idiomatic Ruby gem code
2. Help scaffold a fully testable and releasable gem
3. Suggest RuboCop rules
4. Explain `rake`, gem lifecycle, and CI strategies
5. Offer Git best practices for open source gems

## 🧪 Test Setup

```sh
bundle exec rake test
