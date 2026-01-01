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

## Installation

Add this shard to your `shard.yml`:

```yaml
dependencies:
  sassd:
    github: kritoke/sassd.cr
