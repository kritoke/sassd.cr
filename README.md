# sassd.cr

`sassd.cr` is a small, **libsass-style** Sass/SCSS compiler for Crystal that uses
the official Dart Sass implementation under the hood.

It aims to feel like [`sass.cr`](https://github.com/straight-shoota/sass.cr)
while targeting **current, spec-compliant Sass** via the `sass` command-line
tool.

- Simple API: `compile` and `compile_file` methods.
- Familiar options: include paths, output style, basic source map control.
- Implementation: shells out to the Dart Sass CLI instead of linking `libsass`.
  This avoids relying on the deprecated `libsass` C library.

## Status

**Experimental.** The API is intentionally close to `sass.cr`, but exact output
may differ in edge cases due to Dart Sass vs Libsass behavior differences. 

## Setup

This shard requires the Dart Sass executable. You can install it locally into your project's `bin/` folder using the provided Makefile:

```bash
make sass
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