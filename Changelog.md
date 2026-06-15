# Changelog

## [0.3.2] - 2026-06-15

### Added

- stdin support in the CLI (compile from standard input)
- Timeout handling for compilations with a new `Sass::TimeoutError` exception type
- Deprecation control options: `fatal_deprecation`, `silence_deprecation`, `future_deprecation`
- New `timeout` field on `Sass::Config`
- Input size limits and empty load-path filtering for safer compilation
- Validation of `--style` and `--source-map-urls` CLI arguments
- Path validation specs (`spec/path_validation_spec.cr`)
- Additional stdin/timeout test coverage

### Changed

- Updated Dart Sass dependency from 1.98.0 to 1.100.0
- Extracted `ArgsBuilder` and `Validator` modules out of `compiler.cr` and `cli.cr`
- Consolidated constants and simplified internal modules
- Improved Crystal 1.18.2 compatibility and overall code quality
- Hardened the README with expanded usage documentation

### Fixed

- Command injection and path traversal vulnerabilities in CLI argument handling
- Addressed code review security findings
- CLI parsing bug in `validate_and_execute`
- Indentation in `cli.cr` `validate_and_execute`

### Security

- Resolved CommandInjection and PathTraversal attack vectors
- Added input size limits and filtered empty load paths
- Validated `--style` and `--source-map-urls` arguments before passing to the binary

## [0.3.1] - 2026-03-19

### Changed

- Updated Dart Sass dependency from 1.97.1 to 1.98.0 for latest features and fixes
- Includes CLI improvements for dependency loop handling in watch mode (1.98.0)
- Includes JavaScript API fixes and improvements (1.98.0)
- Migrated from Makefile to Justfile for improved long-term maintainability
- Removed Makefile dependency, now using Just exclusively
- Updated shard.yml to use Just for postinstall script
- Made ameba a proper development dependency (removed branch specification)
- Added comprehensive test coverage for new Config-based API
- Improved error handling with specific exception types

## [0.3.0] - 2026-01-18

### Added

- Enhanced compiler with new features from Dart Sass 1.97.1
- Added `source_map_urls` property (supports "relative" or "absolute" URLs)
- Added `embed_sources` property to embed sources in source maps
- Added `charset` property to control @charset output
- Added `error_css` property to control error stylesheet generation
- Added `quiet`, `quiet_deps`, and `verbose` properties for warning control
- Added support for all new options at module level (Sass.compile, Sass.compile_file, etc.)
- Added comprehensive specs for new API features

### Fixed

- Critical bug in `compile_file` method when processing files with YAML front matter
- Ameba Lint/SpecEqWithBoolOrNilLiteral warnings in specs

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
  - `just sass` - Download Dart Sass binary
  - `just test` - Run tests
  - `just clean-sass` - Remove downloaded binaries
