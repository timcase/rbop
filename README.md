# Rbop

[![Ruby](https://github.com/timcase/rbop/actions/workflows/ruby.yml/badge.svg)](https://github.com/timcase/rbop/actions/workflows/ruby.yml)

A Ruby gem for seamless integration with the 1Password CLI (`op`). Rbop provides an intuitive, object-oriented interface for retrieving and working with 1Password items, complete with dynamic method access and intelligent type casting.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbop'
```

And then execute:

```bash
bundle install
```

Or install it directly:

```bash
gem install rbop
```

## Quick Start

```ruby
require 'rbop'

# Initialize client with your 1Password account and vault
client = Rbop::Client.new(
  account: "my-team.1password.com", 
  vault: "Personal"
)

# Retrieve an item by title
item = client.get(title: "GitHub Login")

# Access top-level properties
puts item.title          # => "GitHub Login"
puts item.category       # => "LOGIN"
puts item.created_at     # => 2023-12-01 10:30:00 UTC (automatically parsed)

# Access field values dynamically
puts item.username       # => { "label" => "username", "value" => "john.doe" }
puts item.password       # => { "label" => "password", "value" => "secret123" }

# CamelCase fields are automatically converted to snake_case
puts item.two_factor_auth # => { "label" => "twoFactorAuth", "value" => "TOTP" }

# Collision handling with field_ prefix when needed
puts item.url            # => "https://github.com" (top-level field)
puts item.field_url      # => { "label" => "url", "value" => "backup-url" }

# Get raw hash data
puts item.to_h           # => Deep copy of all item data
puts item.as_json        # => Alias for to_h
```

## Features

### 🔐 Session Management
- Automatic authentication with 1Password CLI
- Session token management and environment variable handling
- Intelligent sign-in detection and retry logic

### 🎯 Flexible Item Selectors
- **By title**: `client.get(title: "My Login")`
- **By ID**: `client.get(id: "abc123def456")`
- **By share URL**: `client.get(url: "https://share.1password.com/s/...")`
- **By private URL**: `client.get(url: "https://my-team.1password.com/vaults/...")`

### 🚀 Dynamic API Access
- **Method access**: Access any field as a method (`item.username`, `item.password`)
- **Bracket access**: String/symbol indifferent (`item["username"]`, `item[:username]`)
- **Collision handling**: Automatic `field_` prefix when field names conflict with Ruby methods
- **Enumeration**: Multiple fields with same name get numeric suffixes (`field_class_2`, `field_class_3`)
- **Case conversion**: CamelCase field labels become snake_case methods (`firstName` → `first_name`)

### ⚡ Intelligent Type Casting
- **Timestamp parsing**: Automatic conversion of ISO-8601 strings to `Time` objects
- **Field-level casting**: Timestamps in field values are also converted
- **Graceful fallback**: Invalid timestamps return original string values

### 🛡️ Data Safety
- **Deep copying**: `item.to_h` returns a deep copy to prevent mutation
- **Immutable access**: Original data remains unchanged regardless of modifications to copies
- **Type preservation**: Non-string values maintain their original types

## Limitations

- **1Password CLI dependency**: Requires the official 1Password CLI (`op`) to be installed and available in PATH
- **Shell execution**: All operations execute shell commands under the hood
- **Thread safety**: ⚠️ **Not thread-safe** - session tokens are managed at the class level. Use separate client instances per thread or implement your own synchronization
- **Error handling**: Shell command failures bubble up as `Rbop::Shell::CommandFailed` exceptions
- **Authentication scope**: Supports only account-based authentication, not service account tokens

## Requirements

- Ruby 3.1+
- [1Password CLI (op)](https://developer.1password.com/docs/cli/get-started/) v2.20.0+
- Valid 1Password account with CLI access

## 1Password CLI Documentation

For more information about the underlying 1Password CLI:
- [Getting Started Guide](https://developer.1password.com/docs/cli/get-started/)
- [CLI Reference](https://developer.1password.com/docs/cli/reference/)
- [Authentication Methods](https://developer.1password.com/docs/cli/authentication/)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/timcase/rbop.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).