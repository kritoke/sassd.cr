# Justfile for sassd.cr
# Installs Sass into ./bin/sass.
# 1) Try Dart Sass GitHub release for current OS/arch  
# 2) If that fails, fallback to npm "sass"

# Default Dart Sass version
export DART_VERSION := "1.98.0"

# Set working directory
set working-directory := "."

# Ensure bin directory exists
ensure-bin:
    @mkdir -p ./bin

# Install npm sass as fallback
npm-sass: ensure-bin
    @echo "Installing npm 'sass' globally (requires Node/npm) ..."
    @if ! command -v npm >/dev/null 2>&1; then \
        echo "Error: npm not found; cannot install npm sass. Please install Node.js/npm or provide Sass manually." >&2; \
        exit 1; \
    fi
    @npm i -g sass
    @BIN_PATH=$$(npm config get prefix)/bin/sass; \
    if [ ! -x "$$BIN_PATH" ]; then \
        echo "Could not locate global npm 'sass' binary at $$BIN_PATH" >&2; \
        exit 1; \
    fi
    @mkdir -p ./bin
    @ln -sf "$$BIN_PATH" ./bin/sass
    @echo "Linked npm sass to ./bin/sass"

# Main sass installation using shell script
sass: ensure-bin
    @./scripts/install-sass.sh

# Clean sass binaries  
clean-sass:
    @rm -f ./bin/sass ./bin/sass.bat
    @echo "Removed local Sass binaries"

# Run tests
test: sass
    @crystal spec

# Build project
build: sass
    @shards build

# Default recipe
@default:
    @echo "Available commands:"
    @echo "  just sass          # Install Sass binary"
    @echo "  just clean-sass    # Remove local Sass binaries"
    @echo "  just test          # Run tests"  
    @echo "  just build         # Build the project"
    @echo ""
    @just --list | tail -n +2