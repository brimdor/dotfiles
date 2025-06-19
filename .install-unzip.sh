#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
UNZIP_BIN="$INSTALL_DIR/unzip"

# Check if unzip is already installed in $HOME/.local/bin or system-wide
if command -v unzip &>/dev/null; then
    echo "[chezmoi] unzip is already installed."
    exit 0
fi

mkdir -p "$INSTALL_DIR"

ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64 | arm64)
        ARCH="arm64"
        ;;
    *)
        echo "[chezmoi] Unsupported architecture: $ARCH_RAW"
        exit 1
        ;;
esac

# Download prebuilt unzip binary (using busybox as a portable alternative)
UNZIP_URL="https://busybox.net/downloads/binaries/1.36.1-i686-uclibc/busybox"
UNZIP_TMP="$INSTALL_DIR/busybox-unzip"

echo "[chezmoi] Downloading busybox as unzip to $UNZIP_BIN..."
curl -L -o "$UNZIP_TMP" "$UNZIP_URL"
chmod +x "$UNZIP_TMP"
ln -sf "$UNZIP_TMP" "$UNZIP_BIN"

echo "[chezmoi] unzip installed to $UNZIP_BIN (via busybox)."