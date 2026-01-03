# Migration Guide: sass.cr → sassd.cr

This guide explains how to migrate from `sass.cr` to `sassd.cr`.

## Overview

`sassd.cr` is designed as a drop-in replacement for `sass.cr`. The migration process is straightforward - in most cases, you only need to change one line of code.

## Quick Migration

### Step 1: Update Your Dependency

In your `shard.yml`, change:

```yaml
dependencies:
  sass:
    github: straight-shoota/sass.cr
```

To:

```yaml
dependencies:
  sassd:
    github: kritoke/sassd.cr
```

### Step 2: Update Your Requires

In your Crystal code, change:

```crystal
require "sass"
```

To:

```crystal
require "sassd"
```

That's it! Your code should work without any other changes.

## API Compatibility

All `sass.cr` methods are supported:

### Sass.compile

```crystal
# Both libraries support the same interface
css = Sass.compile(source)
css = Sass.compile(source, style: "compressed")
css = Sass.compile(source, load_paths: ["includes"])
css = Sass.compile(source, source_map: true)
```

### Sass.compile_file

```crystal
# File compilation works identically
css = Sass.compile_file("path/to/file.scss")
css = Sass.compile_file("path/to/file.scss", style: "compressed")
```

### Sass.compile_directory

```crystal
# Batch compilation is supported
Sass.compile_directory("input_dir", "output_dir", style: "compressed")
```

## Additional Features in sassd.cr

While maintaining full compatibility, `sassd.cr` adds some enhancements:

### Sass::Compiler Class

For better performance when compiling multiple files with the same options:

```crystal
# Create a reusable compiler instance
compiler = Sass::Compiler.new(
  style: "compressed",
  source_map: true,
  load_paths: ["vendor/stylesheets"]
)

# Use it for multiple compilations
css1 = compiler.compile_file("app.scss")
css2 = compiler.compile_file("admin.scss")
css3 = compiler.compile("@import 'common';")

# Modify options dynamically
compiler.style = "expanded"
```

## Platform Support

`sassd.cr` supports more platforms out of the box:

- ✅ Linux (arm64, amd64)
- ✅ macOS (arm64, amd64)
- ✅ FreeBSD (arm64, amd64)
- ✅ Windows (via npm fallback)

The library automatically downloads the correct Dart Sass binary for your platform.

## Differences to Note

### No Native LibSass

`sass.cr` uses native C bindings to LibSass (deprecated). `sassd.cr` uses Dart Sass through CLI:

- **Pros**: Always up-to-date with latest Sass features, no C compilation issues
- **Cons**: Slight performance overhead from process spawning (negligible for most use cases)

### Binary Installation

`sassd.cr` requires the Dart Sass binary. This is automatically handled by the Makefile:

```bash
make sass  # Downloads the correct binary for your platform
```

Or it will fallback to npm if precompiled binaries aren't available.

## Example: Complete Migration

### Before (sass.cr)

```crystal
require "sass"

# Compile a file
css = Sass.compile_file("styles/main.scss", style: "compressed")

# Compile a string
css = Sass.compile(".test { color: red; }")

# Use load paths
css = Sass.compile("@import 'mixin'; .a { @include test; }", load_paths: ["includes"])
```

### After (sassd.cr)

```crystal
require "sassd"

# Compile a file (same API)
css = Sass.compile_file("styles/main.scss", style: "compressed")

# Compile a string (same API)
css = Sass.compile(".test { color: red; }")

# Use load paths (same API)
css = Sass.compile("@import 'mixin'; .a { @include test; }", load_paths: ["includes"])

# Optional: Use Compiler class for better performance
compiler = Sass::Compiler.new(style: "compressed")
css1 = compiler.compile_file("main.scss")
css2 = compiler.compile_file("admin.scss")
```

## Troubleshooting

### Sass Binary Not Found

If you see an error about the Sass binary not being found:

```bash
make sass
```

This will download and install the correct Dart Sass binary for your platform.

### Version Mismatch

The library checks for a minimum Dart Sass version (1.97.1). If you have an older version:

```bash
make clean-sass
make sass
```

### Platform-Specific Issues

The Makefile automatically handles platform detection. If you encounter issues:

```bash
# Check detected platform
make sass

# If that fails, install via npm fallback
npm install -g sass
```

## Performance Considerations

The `Sass::Compiler` class is recommended for:
- Build processes compiling many files
- Development servers watching files
- Static site generators
- Any scenario with repeated compilations

For single-file compilations, the module-level methods (`Sass.compile`, `Sass.compile_file`) work perfectly fine.

## Need Help?

If you encounter any issues migrating:
1. Check that `make sass` ran successfully
2. Verify you changed `require "sass"` to `require "sassd"`
3. Check that your code doesn't use any deprecated LibSass features
4. Open an issue on GitHub: https://github.com/kritoke/sassd.cr/issues
