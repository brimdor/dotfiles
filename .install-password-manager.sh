#!/bin/bash

set -euo pipefail

user_path="$HOME/.local/bin"

# Function to get the latest 7zip release version from GitHub
get_latest_7zip_version() {
    curl -s "https://api.github.com/repos/ip7z/7zip/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to install 7zip binary for the current architecture
install_7zip() {
    echo "[chezmoi] Checking latest 7zip version..."
    LATEST_7ZIP_VERSION="$(get_latest_7zip_version)"
    if [[ -z "$LATEST_7ZIP_VERSION" ]]; then
        echo "[chezmoi] Failed to fetch latest 7zip version."
        exit 1
    fi

    # Check if 7z is already installed and up-to-date
    if command -v 7zz &>/dev/null; then
        INSTALLED_VERSION="$(7zz | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        if [[ "$INSTALLED_VERSION" == "${LATEST_7ZIP_VERSION#v}" ]]; then
            echo "[chezmoi] 7zip $INSTALLED_VERSION is already installed."
            return
        fi
    fi

    ARCH_RAW="$(uname -m)"
    case "$ARCH_RAW" in
        x86_64) ARCH="x64" ;;
        aarch64 | arm64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
        i386) ARCH="x86" ;;
        *) echo "[chezmoi] Unsupported architecture: $ARCH_RAW" && exit 1 ;;
    esac

    # Compose download URL for the latest release
    ZIP_NAME="7zz_${ARCH}.tar.xz"
    DOWNLOAD_URL="https://github.com/ip7z/7zip/releases/download/${LATEST_7ZIP_VERSION}/${ZIP_NAME}"

    echo "[chezmoi] Downloading 7zip $LATEST_7ZIP_VERSION for $ARCH..."
    curl -L -o "/tmp/$ZIP_NAME" "$DOWNLOAD_URL" || { echo "[chezmoi] Download failed!"; exit 1; }

    echo "[chezmoi] Extracting 7zip binary..."
    tar -xf "/tmp/$ZIP_NAME" -C "$user_path" 7zz || { echo "[chezmoi] Extraction failed!"; exit 1; }
    chmod +x "$user_path/7zz"

    echo "[chezmoi] 7zip $LATEST_7ZIP_VERSION installation completed."
}

# Pre-flight check function for 1Password CLI - Exit if already installed
check_1password_installed() {
    if command -v op &>/dev/null; then
        echo "[chezmoi] 1Password CLI is already installed."
        exit 0
    fi
}

# Function to install 1Password CLI based on the detected package manager
install_1password() {
    if command -v brew &>/dev/null; then
        # macOS using Homebrew
        echo "[chezmoi] Installing 1Password CLI via Homebrew..."
        brew update
        brew install 1password-cli || true

    else
        # Fallback: manual binary install
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

        unzip -d $user_path $1password_binary || { echo "[chezmoi] Unzip failed!"; exit 1; }

        sudo groupadd -f onepassword-cli
        sudo chgrp onepassword-cli 
        sudo chmod g+s $user_path/op
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