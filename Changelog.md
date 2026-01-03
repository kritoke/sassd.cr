# Changelog

## [0.2.0] - 2026-01-03

### Added
- Added Crystal CI workflow configuration via GitHub Actions
- Added dependencies step to CI workflow for proper setup

### Changed
- Improved sass.cr API compatibility with additional compatibility features

## [0.1.0] - 2026-01-03

### Added
- Initial release of sassd.cr
    - Modern, high-performance Crystal wrapper for the Dart Sass CLI
- Full API compatibility with sass.cr (drop-in replacement)
    - `Sass.compile()` - Compile SCSS strings to CSS
    - `Sass.compile_file()` - Compile SCSS files to CSS
    - `Sass.compile_directory()` - Batch compile entire directories
    - `Sass::Compiler` class - Reusable compiler instances for efficient repeated compilations
- Automatic binary download for Dart Sass with zero-config installation
- Cross-platform support:
  - Linux (arm64/amd64)
  - macOS (arm64/amd64)
  - FreeBSD (arm64/amd64)
- Flexible output styles: `expanded`, `compressed`
- Source map generation support
- CLI tool (`sassd`) for quick command-line compilations
- Front matter stripping from SCSS files (for static site generators)
- Configuration options:
  - `style` - Control output CSS style
  - `source_map` - Enable/disable source map generation
  - `load_paths` - Additional import paths
  - `include_path` - Include directory path
- Comprehensive test suite
- Migration guide (MIGRATION.md) for migrating from sass.cr to sassd.cr
- Makefile with targets for:
  - `make sass` - Download Dart Sass binary
  - `make test` - Run tests
  - `make clean-sass` - Remove downloaded binaries