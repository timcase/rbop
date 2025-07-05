# Releasing Rbop

This document outlines the manual process for releasing a new version of the Rbop gem.

## Prerequisites

### RubyGems Credentials

Before you can push to RubyGems, you need to configure your credentials:

```bash
# Set up your RubyGems API key
gem push --key your-api-key-name
```

Or manually create `~/.gem/credentials`:

```yaml
---
:rubygems_api_key: your_api_key_here
```

Make sure the file has proper permissions:

```bash
chmod 0600 ~/.gem/credentials
```

You can obtain your API key from [RubyGems.org](https://rubygems.org/profile/edit) under "API Keys".

## Release Process

Follow these steps in order to release a new version:

### 1. Bump Version

Edit `lib/rbop/version.rb` and update the version number:

```ruby
module Rbop
  VERSION = "X.Y.Z"  # Update to new version
end
```

Follow [Semantic Versioning](https://semver.org/):
- **Patch** (X.Y.Z+1): Bug fixes, no breaking changes
- **Minor** (X.Y+1.0): New features, backward compatible
- **Major** (X+1.0.0): Breaking changes

### 2. Update Changelog

Edit `CHANGELOG.md`:

1. Move items from `[Unreleased]` to a new version section
2. Add release date
3. Create new empty `[Unreleased]` section
4. Add version link at the bottom

Example:

```markdown
## [Unreleased]

## [X.Y.Z] - 2025-MM-DD

### Added
- New feature descriptions

### Changed
- Changed feature descriptions

### Fixed
- Bug fix descriptions

[X.Y.Z]: https://github.com/timcase/rbop/releases/tag/vX.Y.Z
```

### 3. Commit Changes

```bash
git add lib/rbop/version.rb CHANGELOG.md
git commit -m "Bump version to X.Y.Z"
```

### 4. Create Git Tag

```bash
git tag vX.Y.Z
```

### 5. Run Tests

Ensure all tests pass before releasing:

```bash
bundle exec rake test
```

Fix any failing tests before proceeding.

### 6. Build Gem

```bash
gem build rbop.gemspec
```

This creates `rbop-X.Y.Z.gem` in the current directory.

### 7. Push to RubyGems

```bash
gem push rbop-X.Y.Z.gem
```

### 8. Push to GitHub

```bash
git push origin main
git push origin vX.Y.Z
```

### 9. Create GitHub Release

1. Go to [GitHub Releases](https://github.com/timcase/rbop/releases)
2. Click "Create a new release"
3. Choose tag `vX.Y.Z`
4. Set release title to `vX.Y.Z`
5. Copy changelog content for this version into the description
6. Publish release

## Verification

After release, verify:

1. **RubyGems**: Check [https://rubygems.org/gems/rbop](https://rubygems.org/gems/rbop) shows new version
2. **GitHub**: Verify tag and release appear correctly
3. **Installation**: Test `gem install rbop` installs new version

```bash
gem install rbop --version X.Y.Z
ruby -e "require 'rbop'; puts Rbop::VERSION"
```

## Rollback (if needed)

If there's an issue with the release:

1. **RubyGems**: You cannot delete a version once pushed, but you can yank it:
   ```bash
   gem yank rbop -v X.Y.Z
   ```

2. **GitHub**: Delete the release and tag:
   ```bash
   git tag -d vX.Y.Z
   git push origin :vX.Y.Z
   ```

3. **Fix and re-release**: Increment patch version and release again

## Notes

- Always test the release process in a separate environment first
- Consider using `gem build --verbose` for debugging build issues
- The `.gem` file can be inspected with `gem unpack rbop-X.Y.Z.gem`
- Keep release notes focused on user-facing changes
- Pre-release versions can use suffixes like `1.0.0.rc1` for release candidates