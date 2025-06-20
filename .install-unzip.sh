#!/bin/bash
set -euo pipefail

# Enable debug output for visibility
export PS4='[${BASH_SOURCE}:${LINENO}] '
set -x

INSTALL_DIR="$HOME/.local/bin"
UNZIP_BIN="$INSTALL_DIR/unzip"

# Only run on Linux
echo "[chezmoi] Checking OS..."
OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [[ "$OS_NAME" != "linux" ]]; then
    echo "[chezmoi] Not a Linux system. Skipping unzip install."
    exit 0
fi

# Check if unzip is already installed in $HOME/.local/bin or system-wide
if command -v unzip &>/dev/null; then
    echo "[chezmoi] unzip is already installed."
    exit 0
fi

echo "[chezmoi] Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Use the latest available busybox_UNZIP for x86_64
BUSYBOX_VERSION="1.35.0-x86_64-linux-musl"
BUSYBOX_BIN_URL="https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}/busybox_UNZIP"
BUSYBOX_BIN="$INSTALL_DIR/busybox-unzip"

# Only x86_64 is supported for this binary
ARCH_RAW="$(uname -m)"
echo "[chezmoi] Detected architecture: $ARCH_RAW"
if [[ "$ARCH_RAW" != "x86_64" ]]; then
    echo "[chezmoi] Only x86_64 is supported for busybox_UNZIP at this time."
    exit 1
fi

echo "[chezmoi] Downloading busybox_UNZIP $BUSYBOX_VERSION as unzip to $UNZIP_BIN..."
echo "[chezmoi] Download URL: $BUSYBOX_BIN_URL"
curl -fL -o "$BUSYBOX_BIN" "$BUSYBOX_BIN_URL" || { echo "[chezmoi] Download failed!"; exit 1; }

# Check if the file is a valid ELF binary
echo "[chezmoi] Verifying downloaded file is a valid ELF binary..."
if ! file "$BUSYBOX_BIN" | grep -q 'ELF'; then
    echo "[chezmoi] Downloaded file is not a valid binary:"
    head "$BUSYBOX_BIN"
    exit 1
fi

chmod +x "$BUSYBOX_BIN"
ln -sf "$BUSYBOX_BIN" "$UNZIP_BIN"

echo "[chezmoi] unzip installed to $UNZIP_BIN (via busybox_UNZIP $BUSYBOX_VERSION)."