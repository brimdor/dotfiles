#!/bin/bash
set -euo pipefail

# Enable debug output for visibility
export PS4='[${BASH_SOURCE}:${LINENO}] '
set -x

INSTALL_DIR="$HOME/.local/bin"
UNZIP_BIN="$INSTALL_DIR/unzip"
BUSYBOX_BIN="$INSTALL_DIR/busybox-unzip"
BUSYBOX_VERSION="1.37.0"
BUSYBOX_TARBALL="busybox-${BUSYBOX_VERSION}.tar.bz2"
BUSYBOX_URL="https://busybox.net/downloads/${BUSYBOX_TARBALL}"
BUSYBOX_BZ2_HELPER="/tmp/busybox-bz2-helper"
BUSYBOX_BZ2_URL="https://busybox.net/downloads/binaries/1.36.1-defconfig-multiarch-musl/busybox-x86_64"

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

# Download BusyBox tarball

echo "[chezmoi] Downloading BusyBox $BUSYBOX_VERSION source..."
curl -fL -o "/tmp/$BUSYBOX_TARBALL" "$BUSYBOX_URL" || { echo "[chezmoi] Download failed!"; exit 1; }

# Extract BusyBox source, using bzip2 or busybox-bzip2 if needed
echo "[chezmoi] Extracting BusyBox source..."
cd /tmp
if command -v bzip2 &>/dev/null; then
    tar -xjf "$BUSYBOX_TARBALL"
else
    echo "[chezmoi] bzip2 not found, using busybox bzip2 applet."
    # Download a static busybox binary for bzip2
    curl -fL -o "$BUSYBOX_BZ2_HELPER" "$BUSYBOX_BZ2_URL"
    chmod +x "$BUSYBOX_BZ2_HELPER"
    "$BUSYBOX_BZ2_HELPER" bzip2 -d -c "$BUSYBOX_TARBALL" > "/tmp/busybox-${BUSYBOX_VERSION}.tar"
    tar -xf "/tmp/busybox-${BUSYBOX_VERSION}.tar"
    rm -f "$BUSYBOX_BZ2_HELPER" "/tmp/busybox-${BUSYBOX_VERSION}.tar"
fi
cd "busybox-$BUSYBOX_VERSION"

# Configure and build BusyBox with static linking and unzip enabled
echo "[chezmoi] Configuring BusyBox..."
make distclean
make defconfig
# Ensure unzip is enabled
grep -q CONFIG_UNZIP=y .config || sed -i 's/# CONFIG_UNZIP is not set/CONFIG_UNZIP=y/' .config
# Build static binary
echo "[chezmoi] Building BusyBox (static)..."
make -j$(nproc) busybox CONFIG_STATIC=y LDFLAGS="-static" || { echo "[chezmoi] Build failed!"; exit 1; }

# Install the binary
echo "[chezmoi] Installing BusyBox binary to $BUSYBOX_BIN..."
cp busybox "$BUSYBOX_BIN"
chmod +x "$BUSYBOX_BIN"
ln -sf "$BUSYBOX_BIN" "$UNZIP_BIN"

# Clean up
echo "[chezmoi] Cleaning up..."
cd ~
rm -rf "/tmp/busybox-$BUSYBOX_VERSION" "/tmp/$BUSYBOX_TARBALL"

echo "[chezmoi] unzip installed to $UNZIP_BIN (via busybox $BUSYBOX_VERSION built from source)."