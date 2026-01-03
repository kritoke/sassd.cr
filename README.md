# sassd.cr

[![Crystal CI](https://github.com/kritoke/sassd.cr/actions/workflows/crystal.yml/badge.svg)](https://github.com/kritoke/sassd.cr/actions/workflows/crystal.yml)
[![Crystal shard](https://img.shields.io/badge/crystal-v0.1.0_--_latest-blue.svg)](https://github.com/kritoke/sassd.cr)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/kritoke/sassd.cr/blob/main/LICENSE)

A modern, high-performance Crystal wrapper for the Dart Sass CLI.

`sassd.cr` provides a familiar, `libsass`-style API while leveraging the power and spec-compliance of the official Dart Sass implementation. By shelling out to the native binary, it avoids the complexities of C bindings and the obsolescence of the deprecated LibSass library.

## Features

*   **Modern Sass Support**: Full support for the latest Sass features and syntax.
*   **Full API Compatibility**: Drop-in replacement for `sass.cr` - just change the require from `"sass"` to `"sassd"`.
*   **Reusable Compiler Instance**: Create a `Sass::Compiler` instance for efficient repeated compilations with consistent options.
*   **Zero-Config Installation**: Automatically downloads the correct Dart Sass binary for your OS and Architecture.
*   **Cross-Platform Support**: Works on Linux (arm64/amd64), macOS, and FreeBSD using precompiled Dart Sass binaries.
*   **Batch Compilation**: Efficiently compile entire directories in a single process—perfect for static site generators.
*   **Flexible Output**: Control output styles (`expanded`, `compressed`) and source map generation.
*   **CLI Tool**: Includes a standalone `sassd` executable for quick compilations.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     sassd:
       github: kritoke/sassd.cr
   ```

2. Run `shards install`.

## Setup

This shard requires the Dart Sass executable. By default, `shards install` will automatically download the standalone binary to your project's `bin/` folder.

If you need to trigger the installation manually:
```bash
make sass
```

To build the included CLI tool:
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
```

### Compiling Files

```crystal
css = Sass.compile_file("src/assets/main.scss", style: "compressed")
```

### Batch Directory Compilation

Ideal for build pipelines and static site generators:

```crystal
Sass.compile_directory(
  input_dir: "src/assets/sass",
  output_dir: "public/css",
  style: "compressed",
  source_map: true
)
```

### Using a Reusable Compiler

For API compatibility with `sass.cr`, you can create a reusable `Sass::Compiler` instance:

```crystal
compiler = Sass::Compiler.new(
  style: "compressed",
  source_map: true,
  load_paths: ["vendor/stylesheets"],
  include_path: "includes"
)

# Compile multiple files with the same options
css_application = compiler.compile_file("application.scss")
css_layout = compiler.compile("@import 'layout';")

# Modify options dynamically
compiler.style = "expanded"
compiler.load_paths << "additional/styles"
```

### Configuration

You can manually point the library to a specific Sass binary:

```crystal
Sass.bin_path = "/usr/local/bin/sass"
```

### API Compatibility with sass.cr

This library is designed as a drop-in replacement for `sass.cr`. To migrate:

1. Change `require "sass"` to `require "sassd"` in your code
2. No other code changes needed - all methods and parameters are compatible
3. Optionally use the `Sass::Compiler` class for reusable compiler instances

For detailed migration instructions, see [MIGRATION.md](MIGRATION.md).

## CLI Tool

After running `shards build`, you can use the `sassd` utility:

```bash
./bin/sassd src/style.scss > public/style.css
```

This will attempt to download the standalone Dart Sass binary for your platform. If it cannot find a matching binary, it will fallback to an `npm` global installation.

## Cleaning

To remove the locally installed Sass binary and associated files from the `bin/` directory, run:

```bash
make clean-sass
```

## Installation

Add this shard to your `shard.yml`:

```yaml
dependencies:
  sassd:
    github: kritoke/sassd.cr
```

## Testing & Platform Notes

**Note**: This library has been primarily tested on macOS (arm64). While it includes support for Linux (arm64/amd64) and FreeBSD (arm64/amd64) through the Makefile's platform detection and precompiled Dart Sass binary downloads, extensive testing on those platforms has not yet been performed. If you encounter any issues on these platforms, please open an issue.

## Acknowledgments

This library is heavily inspired by and designed to be API-compatible with [sass.cr](https://github.com/straight-shoota/sass.cr) by [Johannes Müller](https://github.com/straight-shoota). The original sass.cr library provided an excellent API design for Sass compilation in Crystal, and this implementation aims to preserve that experience while leveraging the modern Dart Sass implementation.

## Contributing

1. Fork it (<https://github.com/kritoke/sassd.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [kritoke](https://github.com/kritoke) - creator and maintainer
