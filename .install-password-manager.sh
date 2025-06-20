#!/bin/bash

set -euo pipefail

user_path="$HOME/.local/bin"

check_1password_installed() {
    if command -v op &>/dev/null; then
        echo "[chezmoi] 1Password CLI is already installed."
        exit 0
    fi
}

install_1password() {
    if command -v brew &>/dev/null; then
        echo "[chezmoi] Installing 1Password CLI via Homebrew..."
        brew update
        brew install 1password-cli || true

    else
        echo "[chezmoi] No supported package manager found. Falling back to direct binary install..."
        VERSION="v2.30.3"
        ARCH_RAW="$(uname -m)"
        case "$ARCH_RAW" in
            x86_64) ARCH="amd64" ;;
            aarch64 | arm64) ARCH="arm64" ;;
            armv7l) ARCH="arm" ;;
            i386) ARCH="386" ;;
            *) echo "[chezmoi] Unsupported architecture: $ARCH_RAW" && exit 1 ;;
        esac

        1password_url="https://cache.agilebits.com/dist/1P/op2/pkg/${VERSION}"
        1password_binary="op_linux_${ARCH_RAW}_${VERSION}.zip"

        curl -LO $1password_url/$1password_binary || { echo "[chezmoi] Download failed!"; exit 1; }

        if ! command -v unzip &>/dev/null; then
            echo "[chezmoi] unzip not found, downloading busybox for extraction..."
            BB_URL="https://busybox.net/downloads/binaries/1.36.1-i686-uclibc/busybox"
            BB_BIN="/tmp/busybox"
            curl -Lo "$BB_BIN" "$BB_URL"
            chmod +x "$BB_BIN"
            "$BB_BIN" unzip "$1password_binary" -d "$user_path" || { echo "[chezmoi] BusyBox unzip failed!"; exit 1; }
            rm -f "$BB_BIN"
        else
            unzip -d "$user_path" "$1password_binary" || { echo "[chezmoi] Unzip failed!"; exit 1; }
        fi

        sudo groupadd -f onepassword-cli
        sudo chgrp onepassword-cli "$user_path/op"
        sudo chmod g+s "$user_path/op"
        echo "[chezmoi] 1Password CLI manual installation completed."
    fi
}


echo "[chezmoi] Prewarming sudo..."
sudo true

install_7zip

echo "[chezmoi] Checking if 1Password CLI is already installed..."
check_1password_installed

echo "[chezmoi] 1Password CLI not found! Proceeding with installation..."
echo "[chezmoi] This may take a few moments..."
install_1password

echo "[chezmoi] 1Password CLI installation completed successfully!"