#!/bin/sh
set -e

VERSION="1.1.87+175514.04f5c9114e11"
BINARY_NAME="cortex"
INSTALL_DIR="$HOME/.local/share/cortex/$VERSION"
BIN_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Checksums
ARM64_CHECKSUM="30c477268c1a3da3295acca80e7cc3c12e8c65c787b15f565e717b14d0c9b666"
AMD64_CHECKSUM="adc079cc3423de6b8296a4c202c7b7122c3a5954af0208a14a4990388b68b242"

print_success() { echo "✓ $1"; }
print_error()   { echo "Error: $1" >&2; }

arch=$(uname -m | tr '[:upper:]' '[:lower:]')
case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) print_error "Unsupported architecture: $arch"; exit 1 ;;
esac

TARBALL="$SCRIPT_DIR/coco-1.1.87-darwin-${arch}.tar.gz"
if [ "$arch" = "arm64" ]; then
    EXPECTED_CHECKSUM="$ARM64_CHECKSUM"
else
    EXPECTED_CHECKSUM="$AMD64_CHECKSUM"
fi

echo "Installing Cortex Code v$VERSION for darwin-${arch}..."

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

if [ "$actual" != "$EXPECTED_CHECKSUM" ]; then
    print_error "Checksum mismatch: expected $EXPECTED_CHECKSUM, got $actual"
    exit 1
fi
print_success "Checksum verified"

# Extract
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Extracting..."
tar -xzf "$TARBALL" -C "$TEMP_DIR"

EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d ! -name "$(basename "$TEMP_DIR")" | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    print_error "No directory found in archive"
    exit 1
fi

if [ ! -f "$EXTRACTED_DIR/$BINARY_NAME" ]; then
    print_error "Binary '$BINARY_NAME' not found in extracted archive"
    exit 1
fi
print_success "Extracted"

# Install
echo "Installing to $INSTALL_DIR..."
mkdir -p "$BIN_DIR"
rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$EXTRACTED_DIR" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/$BINARY_NAME"
rm -f "$BIN_DIR/$BINARY_NAME"
ln -sf "$INSTALL_DIR/$BINARY_NAME" "$BIN_DIR/$BINARY_NAME"
print_success "Installed to $INSTALL_DIR"
print_success "Symlinked $BIN_DIR/$BINARY_NAME"

# PATH check
case ":$PATH:" in
    *":$BIN_DIR:"*)
        ;;
    *)
        echo ""
        echo "Add this to your shell profile (~/.zshrc):"
        echo ""
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        echo ""
        echo "Then run: source ~/.zshrc"
        ;;
esac

echo ""
print_success "Cortex Code v$VERSION installed successfully!"
echo "Run 'cortex --help' to get started."
