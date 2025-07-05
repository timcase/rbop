# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-07-04

### Added
- Initial release of Rbop gem
- Core `Rbop::Client` for 1Password CLI integration
- Session management with automatic authentication
- Item retrieval with flexible selectors:
  - By title: `client.get(title: "My Login")`
  - By ID: `client.get(id: "abc123def456")`
  - By share URL: `client.get(url: "https://share.1password.com/s/...")`
  - By private URL: `client.get(url: "https://my-team.1password.com/vaults/...")`
- Dynamic `Rbop::Item` API with method access to fields
- Intelligent collision handling with `field_` prefix
- Enumeration numbering for duplicate field names (`field_class_2`, `field_class_3`)
- CamelCase to snake_case field name conversion
- Automatic timestamp parsing for ISO-8601 strings
- String/symbol indifferent hash access
- Deep copy protection for `item.to_h` and `item.as_json`
- Comprehensive test suite with high coverage
- Shell command execution with `Rbop::Shell` module
- Error handling with `Rbop::Shell::CommandFailed` exceptions
- Session token management via environment variables
- CLI presence validation during client initialization

### Dependencies
- Ruby 3.1+ required
- 1Password CLI (`op`) v2.20.0+ required
- ActiveSupport for string inflection

### Documentation
- Complete README with installation, usage, and examples
- Inline code documentation
- Comprehensive test examples

[0.1.0]: https://github.com/timcase/rbop/releases/tag/v0.1.0
