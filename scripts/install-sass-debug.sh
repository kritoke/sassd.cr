#!/bin/bash
set -e

# Install Dart Sass script - DEBUG VERSION
# This script is called by the Justfile to install Dart Sass

DART_VERSION="${DART_VERSION:-1.97.3}"

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
    exit 1
fi

echo "Attempting Dart Sass install for ${DART_OS}/${DART_ARCH} version ${DART_VERSION}..."

# Create temporary directory
tmpdir=$(mktemp -d)
echo "Temporary directory: $tmpdir"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"
echo "Current working directory: $(pwd)"

# Compose URLs and artifact names
DART_BASE="dart-sass-${DART_VERSION}-${DART_OS}-${DART_ARCH}"
DART_TGZ="${DART_BASE}.tar.gz"
DART_URL="https://github.com/sass/dart-sass/releases/download/${DART_VERSION}/${DART_TGZ}"

echo "Downloading ${DART_URL}"
if curl -fL --retry 3 --retry-delay 2 -o "${DART_TGZ}" "${DART_URL}"; then
    echo "Download successful, file size: $(stat -c%s "${DART_TGZ}")"
    mkdir dart && tar -xzf "${DART_TGZ}" -C dart --strip-components=1
    echo "Extracted contents:"
    ls -la dart/
    mkdir -p ../bin
    cp -R dart/* ../bin/
    chmod +x ../bin/sass
    echo "Installed Dart Sass to ../bin/sass"
else
    echo "Dart download failed."
    exit 1
fi