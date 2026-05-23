# sassd.cr

[![Crystal CI](https://github.com/kritoke/sassd.cr/actions/workflows/crystal.yml/badge.svg)](https://github.com/kritoke/sassd.cr/actions/workflows/crystal.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/kritoke/sassd.cr/blob/main/LICENSE)

A modern, high-performance Crystal wrapper for the Dart Sass CLI.

`sassd.cr` provides a familiar, `libsass`-style API while leveraging the power and spec-compliance of the official Dart Sass implementation. By shelling out to the native binary, it avoids the complexities of C bindings and the obsolescence of the deprecated LibSass library.

## Features

* **Modern Sass Support**: Full support for the latest Sass features and syntax.
* **Full API Compatibility**: Drop-in replacement for `sass.cr` - just change the require from `"sass"` to `"sassd"`.
* **Reusable Compiler Instance**: Create a `Sass::Compiler` instance for efficient repeated compilations with consistent options.
* **Zero-Config Installation**: Automatically downloads the correct Dart Sass binary for your OS and Architecture.
* **Cross-Platform Support**: Works on Linux (arm64/amd64), macOS, and FreeBSD using precompiled Dart Sass binaries.
* **Batch Compilation**: Efficiently compile entire directories in a single process—perfect for static site generators.
* **Flexible Output**: Control output styles (`expanded`, `compressed`) and source map generation.
* **Advanced Source Map Control**: Customize source map behavior with options like `source_map_urls` (relative/absolute) and `embed_sources`.
* **Charset Control**: Control whether to emit `@charset` or BOM for CSS with non-ASCII characters.
* **Error Handling**: Option to emit error stylesheets when compilation fails instead of raising exceptions.
* **Warning Control**: Fine-grained control over warning behavior with `quiet`, `quiet_deps`, and `verbose` options.
* **Deprecation Control**: Control how deprecation warnings are handled with `fatal_deprecation`, `silence_deprecation`, and `future_deprecation`.
* **Timeout Handling**: Prevent hung compilations with configurable timeouts.
* **CLI Tool**: Includes a standalone `sassd` executable for quick compilations.

## Requirements

- Crystal 1.18.2 or later
- Dart Sass 1.100.0 or later (automatically installed)

## Installation

### 1. Add the dependency

```yaml
# shard.yml
dependencies:
  sassd:
    github: kritoke/sassd.cr
```

### 2. Run shards install

```bash
shards install
```

This will automatically download the Dart Sass binary for your platform.

### 3. Build the CLI (optional)

```bash
shards build
```

## Usage

### Basic Compilation

```crystal
require "sassd"

scss = <<-SCSS
.container {
  .content { color: #333; }
}
SCSS

css = Sass.compile(scss)
puts css
```

### Compiling Files

```crystal
# Simple file compilation
css = Sass.compile_file("styles.scss")

# With options
css = Sass.compile_file("styles.scss", style: "compressed", source_map: true)
```

### Using Config Objects

For cleaner code with multiple options, use the Config API:

```crystal
config = Sass::Config.new(
  style: "compressed",
  source_map: true,
  source_map_embed: true,
  load_paths: ["./lib", "./vendor"]
)

css = Sass.compile(source, config)
```

### Using a Reusable Compiler

```crystal
compiler = Sass::Compiler.new(
  style: "compressed",
  source_map: true,
  load_paths: ["vendor/stylesheets"]
)

# Compile multiple times with the same options
css1 = compiler.compile_file("app.scss")
css2 = compiler.compile_file("lib.scss")
```

### Stdin Compilation

```bash
# Pipe SCSS to stdin
echo '.test { color: red; }' | sassd --stdin

# With options
cat styles.scss | sassd --stdin --style=compressed
```

### Batch Directory Compilation

```crystal
Sass.compile_directory(
  "src/sass",
  "public/css",
  style: "compressed",
  source_map: true
)
```

## API Reference

### Module Methods

| Method | Description |
|--------|-------------|
| `Sass.compile(source, config?)` | Compile SCSS/Sass string to CSS |
| `Sass.compile_file(path, config?)` | Compile a file to CSS |
| `Sass.compile_directory(input, output, config?)` | Compile directory |
| `Sass::Compiler.new(**options)` | Create reusable compiler instance |

### Config Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style` | String | `"expanded"` | Output style: `"expanded"` or `"compressed"` |
| `source_map` | Bool | `false` | Generate source map |
| `source_map_embed` | Bool | `false` | Embed source map in CSS |
| `source_map_urls` | String | `"relative"` | Source map URL type: `"relative"` or `"absolute"` |
| `embed_sources` | Bool | `false` | Embed original sources in source map |
| `charset` | Bool | `true` | Include @charset declaration |
| `error_css` | Bool | `true` | Generate error CSS on failure |
| `quiet` | Bool | `false` | Suppress all warnings |
| `quiet_deps` | Bool | `false` | Suppress dependency warnings |
| `verbose` | Bool | `false` | Show all deprecation warnings |
| `load_paths` | Array(String) | `[]` | Paths for @import resolution |
| `include_path` | String/Array(String) | `nil` | Legacy load paths |
| `is_indented_syntax_src` | Bool | `false` | Treat as Sass (indented) syntax |
| `fatal_deprecation` | String? | `nil` | Treat deprecations up to version as errors |
| `silence_deprecation` | Array(String)? | `nil` | Deprecation names to suppress |
| `future_deprecation` | String? | `nil` | Opt-in to future deprecations |
| `timeout` | Int64? | `nil` | Compilation timeout in seconds |
| `min_version` | String? | `"1.100.0"` | Minimum required Dart Sass version |
| `bin_path` | String? | `nil` | Custom path to sass binary |

### Error Types

```crystal
Sass::CompilationError      # General compilation error
Sass::BinaryNotFoundError  # Sass binary not found
Sass::VersionMismatchError  # Dart Sass version too old
Sass::InvalidSourceError   # Invalid SCSS/Sass source
Sass::FileReadError        # File not found or unreadable
Sass::TimeoutError         # Compilation timed out
```

### CLI Options

```bash
sassd [options] <input_file> [-o <output_file>]
sassd --stdin [-o <output_file>]

Options:
  --help, -h              Show help
  --version, -v           Show version
  --stdin                  Read from stdin
  --style <style>          expanded|compressed [default: expanded]
  --source-map            Generate source map
  --embed-source-map      Embed source map in CSS
  --source-map-urls       relative|absolute [default: relative]
  --embed-sources         Embed source files in source map
  --no-charset            Don't include @charset
  --no-error-css          Don't generate error CSS
  --quiet                 Suppress warnings
  --quiet-deps            Suppress dependency warnings
  --verbose               Show all deprecation warnings
  --load-path <path>      Add import path
  --output, -o <file>     Output file
  --force, -f             Overwrite output file
  --fatal-deprecation <v> Treat deprecations as errors
  --silence-deprecation <n> Suppress deprecation warning
  --future-deprecation <v> Opt-in to future deprecations
  --timeout <seconds>     Compilation timeout
```

## Examples

### With Source Maps

```crystal
config = Sass::Config.new(
  source_map: true,
  source_map_embed: true,
  embed_sources: true
)
css = Sass.compile_file("input.scss", config)
```

### With Deprecation Control

```crystal
# Treat all deprecations up to 1.100.0 as errors
config = Sass::Config.new(fatal_deprecation: "1.100.0")
css = Sass.compile(source, config)

# Silence specific deprecations
config = Sass::Config.new(silence_deprecation: ["import"])
css = Sass.compile(source, config)
```

### With Timeout

```crystal
# Fail after 30 seconds
config = Sass::Config.new(timeout: 30)
begin
  css = Sass.compile(source, config)
rescue Sass::TimeoutError
  puts "Compilation timed out!"
end
```

## Development

```bash
# Install dependencies
shards install

# Run tests
crystal spec

# Build CLI
shards build

# Install Sass binary
./scripts/install-sass.sh
```

## API Compatibility

This library is designed as a drop-in replacement for `sass.cr`. To migrate:

```crystal
# Before (sass.cr)
require "sass"
css = Sass.compile(".test { color: red; }", style: "compressed")

# After (sassd.cr)
require "sassd"
css = Sass.compile(".test { color: red; }", style: "compressed")
```

No other code changes needed!

## License

MIT License - see [LICENSE](LICENSE)

## Contributing

1. Fork it
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Acknowledgments

Inspired by and API-compatible with [sass.cr](https://github.com/straight-shoota/sass.cr) by Johannes Müller.