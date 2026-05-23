#!/bin/bash
set -e

# Install Dart Sass script
# This script is called by the Justfile to install Dart Sass

DART_VERSION="${DART_VERSION:-1.100.0}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Detecting platform..."
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map OS to dart-sass naming
case "${OS}" in
    Darwin)
        DART_OS="macos"
        ;;
    Linux|FreeBSD)
        DART_OS="linux"
        ;;
    Windows_NT|MINGW*|MSYS*)
        DART_OS="windows"
        ;;
    *)
        DART_OS="unknown"
        ;;
esac

# Normalize ARCH names to dart-sass naming
case "${ARCH}" in
    x86_64|amd64)
        DART_ARCH="x64"
        ;;
    arm64|aarch64)
        DART_ARCH="arm64"
        ;;
    *)
        DART_ARCH="unknown"
        ;;
esac

if [ "${DART_OS}" = "unknown" ] || [ "${DART_ARCH}" = "unknown" ]; then
    echo "Unknown platform ${OS}/${ARCH}. Falling back to npm sass."
    exec just npm-sass
fi

echo "Attempting Dart Sass install for ${DART_OS}/${DART_ARCH} version ${DART_VERSION}..."

# Create temporary directory
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

# Compose URLs and artifact names
DART_BASE="dart-sass-${DART_VERSION}-${DART_OS}-${DART_ARCH}"
DART_TGZ="${DART_BASE}.tar.gz"
DART_ZIP="${DART_BASE}.zip"
DART_URL="https://github.com/sass/dart-sass/releases/download/${DART_VERSION}/${DART_TGZ}"
DART_URL_WIN="https://github.com/sass/dart-sass/releases/download/${DART_VERSION}/${DART_ZIP}"

# Handle different OS types
if [ "${OS}" = "Darwin" ] || [ "${OS}" = "Linux" ] || [ "${OS}" = "FreeBSD" ]; then
    echo "Downloading ${DART_URL}"
    if curl -fL --retry 3 --retry-delay 2 -o "${DART_TGZ}" "${DART_URL}"; then
        mkdir dart && tar -xzf "${DART_TGZ}" -C dart --strip-components=1
        mkdir -p "${PROJECT_DIR}/bin"
        cp -R dart/* "${PROJECT_DIR}/bin/"
        chmod +x "${PROJECT_DIR}/bin/sass"
        echo "Installed Dart Sass to ${PROJECT_DIR}/bin/sass"
    else
        echo "Dart download failed. Falling back to npm sass..."
        exec just npm-sass
    fi
elif [ "${OS}" = "Windows_NT" ] || [[ "${OS}" == MINGW* ]] || [[ "${OS}" == MSYS* ]]; then
    echo "Downloading ${DART_URL_WIN}"
    if curl -fL --retry 3 --retry-delay 2 -o "${DART_ZIP}" "${DART_URL_WIN}"; then
        if ! command -v unzip >/dev/null 2>&1; then
            echo "unzip not found. Falling back to npm sass..."
            exec just npm-sass
        else
            mkdir dart && unzip -q "${DART_ZIP}" -d dart
            mkdir -p "${PROJECT_DIR}/bin"
            if [ -f dart/dart-sass/sass.bat ]; then
                cp dart/dart-sass/sass.bat "${PROJECT_DIR}/bin/sass.bat"
                echo "Installed Dart Sass (Windows) to ${PROJECT_DIR}/bin/sass.bat"
            elif [ -f dart/sass.bat ]; then
                cp dart/sass.bat "${PROJECT_DIR}/bin/sass.bat"
                echo "Installed Dart Sass (Windows) to ${PROJECT_DIR}/bin/sass.bat"
            else
                echo "Could not locate sass.bat in archive. Falling back to npm sass..."
                exec just npm-sass
            fi
        fi
    else
        echo "Dart download failed. Falling back to npm sass..."
        exec just npm-sass
    fi
else
    echo "Unsupported OS ${OS}. Falling back to npm sass..."
    exec just npm-sass
fi