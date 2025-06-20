#!/bin/bash
set -euo pipefail

# Enable debug output for visibility
export PS4='[${BASH_SOURCE}:${LINENO}] '
set -x

INSTALL_DIR="$HOME/.local/bin"
UNZIP_BIN="$INSTALL_DIR/unzip"

# Check if unzip is already installed in $HOME/.local/bin or system-wide
if command -v unzip &>/dev/null; then
    echo "[chezmoi] unzip is already installed."
    exit 0
fi

echo "[chezmoi] Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Get the latest busybox version from GitHub releases (e.g., 1_36_1)
echo "[chezmoi] Fetching latest busybox version from GitHub..."
BUSYBOX_VERSION=$(curl -s https://api.github.com/repos/landley/busybox/releases/latest | grep 'tag_name' | sed -E 's/.*\"([^"]+)\".*/\1/')
echo "[chezmoi] Latest busybox version: $BUSYBOX_VERSION"
if [[ -z "$BUSYBOX_VERSION" ]]; then
    echo "[chezmoi] Could not determine latest busybox version from GitHub." >&2
    exit 1
fi

ARCH_RAW="$(uname -m)"
echo "[chezmoi] Detected architecture: $ARCH_RAW"
case "$ARCH_RAW" in
    x86_64)
        BUSYBOX_URL="https://github.com/landley/busybox/releases/download/${BUSYBOX_VERSION}/busybox-x86_64"
        ;;
    aarch64 | arm64)
        BUSYBOX_URL="https://github.com/landley/busybox/releases/download/${BUSYBOX_VERSION}/busybox-arm64"
        ;;
    *)
        echo "[chezmoi] Unsupported architecture: $ARCH_RAW"
        exit 1
        ;;
esac

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