# sassd.cr

A modern, high-performance Crystal wrapper for the Dart Sass CLI. 

`sassd.cr` provides a familiar, `libsass`-style API while leveraging the power and spec-compliance of the official Dart Sass implementation. By shelling out to the native binary, it avoids the complexities of C bindings and the obsolescence of the deprecated LibSass library.

## Features

*   **Modern Sass Support**: Full support for the latest Sass features and syntax.
*   **API Compatibility**: Designed as a drop-in replacement for `sass.cr`.
*   **Zero-Config Installation**: Automatically downloads the correct Dart Sass binary for your OS and Architecture.
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

### Configuration

You can manually point the library to a specific Sass binary:

```crystal
Sass.bin_path = "/usr/local/bin/sass"
```

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

## Contributing

1. Fork it (<https://github.com/kritoke/sassd.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [kritoke](https://github.com/kritoke) - creator and maintainer
