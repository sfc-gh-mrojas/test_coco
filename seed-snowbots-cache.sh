#!/bin/sh
set -e

# Pre-seeds the SnowBots cache so it doesn't need to download the runtime.
# Place this script alongside the .tar.gz files and run it.

VERSION="1.1.87+175514.04f5c9114e11"
CACHE_DIR="$HOME/Library/Caches/SnowBots/coco"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ARM64_FILE="coco-1.1.87-darwin-arm64.tar.gz"
ARM64_CHECKSUM="30c477268c1a3da3295acca80e7cc3c12e8c65c787b15f565e717b14d0c9b666"
ARM64_CACHE_NAME="${ARM64_CHECKSUM}-coco-${VERSION}-darwin-arm64.tar.gz"

AMD64_FILE="coco-1.1.87-darwin-amd64.tar.gz"
AMD64_CHECKSUM="adc079cc3423de6b8296a4c202c7b7122c3a5954af0208a14a4990388b68b242"
AMD64_CACHE_NAME="${AMD64_CHECKSUM}-coco-${VERSION}-darwin-amd64.tar.gz"

print_success() { echo "✓ $1"; }
print_error()   { echo "Error: $1" >&2; }

arch=$(uname -m | tr '[:upper:]' '[:lower:]')
case "$arch" in
    x86_64|amd64) arch="amd64"; SRC_FILE="$AMD64_FILE"; CHECKSUM="$AMD64_CHECKSUM"; CACHE_NAME="$AMD64_CACHE_NAME" ;;
    aarch64|arm64) arch="arm64"; SRC_FILE="$ARM64_FILE"; CHECKSUM="$ARM64_CHECKSUM"; CACHE_NAME="$ARM64_CACHE_NAME" ;;
    *) print_error "Unsupported architecture: $arch"; exit 1 ;;
esac

echo "Pre-seeding SnowBots cache for darwin-${arch}..."

TARBALL="$SCRIPT_DIR/$SRC_FILE"
if [ ! -f "$TARBALL" ]; then
    print_error "Tarball not found: $TARBALL"
    print_error "Make sure the .tar.gz files are in the same directory as this script."
    exit 1
fi

# Verify checksum
echo "Verifying checksum..."
if command -v shasum > /dev/null 2>&1; then
    actual=$(shasum -a 256 "$TARBALL" | awk '{print $1}')
elif command -v sha256sum > /dev/null 2>&1; then
    actual=$(sha256sum "$TARBALL" | awk '{print $1}')
else
    print_error "Neither shasum nor sha256sum found"; exit 1
fi

if [ "$actual" != "$CHECKSUM" ]; then
    print_error "Checksum mismatch: expected $CHECKSUM, got $actual"
    exit 1
fi
print_success "Checksum verified"

# Copy to SnowBots cache
mkdir -p "$CACHE_DIR"
cp "$TARBALL" "$CACHE_DIR/$CACHE_NAME"
print_success "Cached as $CACHE_DIR/$CACHE_NAME"

# Also seed the version and manifest so SnowBots doesn't need to fetch them
VERSIONS_DIR="$CACHE_DIR/versions"
mkdir -p "$VERSIONS_DIR"
echo "$VERSION" > "$VERSIONS_DIR/stable_version.txt"
print_success "Wrote stable_version.txt"

echo ""
print_success "SnowBots cache pre-seeded!"
echo "SnowBots will find the runtime locally and skip the download."
echo ""
echo "If SnowBots is not yet installed, open the .dmg file first:"
echo "  open \"$SCRIPT_DIR/Cortex-Code-darwin-arm64 (2).dmg\""
