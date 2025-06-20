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

# Use a trusted, stable BusyBox version and directory
BUSYBOX_VERSION="1.36.1-defconfig-multiarch-musl"
BUSYBOX_BASE_URL="https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}"

ARCH_RAW="$(uname -m)"
echo "[chezmoi] Detected architecture: $ARCH_RAW"
case "$ARCH_RAW" in
    x86_64)
        BUSYBOX_ARCH="busybox-x86_64"
        ;;
    aarch64|arm64)
        BUSYBOX_ARCH="busybox-aarch64"
        ;;
    armv7l)
        BUSYBOX_ARCH="busybox-armv7l"
        ;;
    i386|i686)
        BUSYBOX_ARCH="busybox-i686"
        ;;
    *)
        echo "[chezmoi] Unsupported architecture: $ARCH_RAW"
        exit 1
        ;;
esac

BUSYBOX_URL="${BUSYBOX_BASE_URL}/${BUSYBOX_ARCH}"
BUSYBOX_BIN="$INSTALL_DIR/busybox-unzip"

echo "[chezmoi] Downloading busybox $BUSYBOX_VERSION as unzip to $UNZIP_BIN..."
echo "[chezmoi] Download URL: $BUSYBOX_URL"
curl -fL -o "$BUSYBOX_BIN" "$BUSYBOX_URL" || { echo "[chezmoi] Download failed!"; exit 1; }

# Check if the file is a valid ELF binary
echo "[chezmoi] Verifying downloaded file is a valid ELF binary..."
if ! file "$BUSYBOX_BIN" | grep -q 'ELF'; then
    echo "[chezmoi] Downloaded file is not a valid binary:"
    head "$BUSYBOX_BIN"
    exit 1
fi

chmod +x "$BUSYBOX_BIN"
ln -sf "$BUSYBOX_BIN" "$UNZIP_BIN"

echo "[chezmoi] unzip installed to $UNZIP_BIN (via busybox $BUSYBOX_VERSION)."