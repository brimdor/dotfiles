#!/bin/bash

set -euo pipefail

user_path="$HOME/.local/bin"

install_jq() {
    if [[ -x "$user_path/jq" ]]; then
        echo "[chezmoi] jq is already installed in $user_path."
        return
    fi

    echo "[chezmoi] Installing jq binary..."
    ARCH_RAW="$(uname -m)"
    case "$ARCH_RAW" in
        x86_64) JQ_ARCH="jq-linux64" ;;
        aarch64 | arm64) JQ_ARCH="jq-linuxarm64" ;;
        armv7l) JQ_ARCH="jq-linuxarm" ;;
        i386) JQ_ARCH="jq-linux32" ;;
        *) echo "[chezmoi] Unsupported architecture for jq: $ARCH_RAW" && exit 1 ;;
    esac

    mkdir -p "$user_path"
    JQ_URL="https://github.com/jqlang/jq/releases/latest/download/$JQ_ARCH"
    curl -L -o "$user_path/jq" "$JQ_URL" || { echo "[chezmoi] jq download failed!"; exit 1; }
    chmod +x "$user_path/jq"
    export PATH="$user_path:$PATH"
    echo "[chezmoi] jq installed to $user_path."
}

# Function to get the latest 7zip release version from GitHub
get_latest_7zip_asset() {
    ARCH_RAW="$(uname -m)"
    case "$ARCH_RAW" in
        x86_64) ARCH="linux-x64" ;;
        aarch64 | arm64) ARCH="linux-arm64" ;;
        armv7l) ARCH="linux-arm" ;;
        i386) ARCH="linux-x86" ;;
        *) echo "[chezmoi] Unsupported architecture: $ARCH_RAW" && exit 1 ;;
    esac

    # Get the asset info from GitHub API
    ASSET_INFO=$(curl -s "https://api.github.com/repos/ip7z/7zip/releases/latest" | \
        jq -r --arg ARCH "$ARCH" '.assets[] | select(.name | test($ARCH)) | "\(.name) \(.browser_download_url)"' | head -1)

    if [[ -z "$ASSET_INFO" ]]; then
        echo "[chezmoi] Could not find a 7zip release for $ARCH"
        exit 1
    fi

    ASSET_NAME=$(echo "$ASSET_INFO" | awk '{print $1}')
    ASSET_URL=$(echo "$ASSET_INFO" | awk '{print $2}')
    # Extract version from asset name, e.g., 7z2409-linux-x64.tar.xz -> 2409 -> 24.09
    VERSION_RAW=$(echo "$ASSET_NAME" | grep -oP '7z\K[0-9]+' | head -1)
    VERSION="${VERSION_RAW:0:2}.${VERSION_RAW:2:2}"

    echo "$ASSET_NAME|$ASSET_URL|$VERSION"
}

install_7zip() {
    command -v jq >/dev/null 2>&1 || { echo "[chezmoi] jq is required but not installed."; exit 1; }
    command -v xz >/dev/null 2>&1 || { echo "[chezmoi] xz is required but not installed."; exit 1; }

    echo "[chezmoi] Checking latest 7zip version..."
    ASSET_INFO=$(get_latest_7zip_asset)
    ASSET_NAME=$(echo "$ASSET_INFO" | cut -d'|' -f1)
    ASSET_URL=$(echo "$ASSET_INFO" | cut -d'|' -f2)
    LATEST_7ZIP_VERSION=$(echo "$ASSET_INFO" | cut -d'|' -f3)

    if [[ -z "$LATEST_7ZIP_VERSION" ]]; then
        echo "[chezmoi] Failed to fetch latest 7zip version."
        exit 1
    fi

    # Check if 7z is already installed and up-to-date
    if command -v 7zz &>/dev/null; then
        INSTALLED_VERSION="$(7zz | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        if [[ "$INSTALLED_VERSION" == "$LATEST_7ZIP_VERSION" ]]; then
            echo "[chezmoi] 7zip $INSTALLED_VERSION is already installed."
            return
        fi
    fi

    echo "[chezmoi] Downloading $ASSET_NAME..."
    curl -L -o "/tmp/$ASSET_NAME" "$ASSET_URL" || { echo "[chezmoi] Download failed!"; exit 1; }

    echo "[chezmoi] Extracting 7zip binary..."
    tar -xf "/tmp/$ASSET_NAME" -C "$user_path" 7zz || { echo "[chezmoi] Extraction failed!"; exit 1; }
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

install_jq
install_7zip

echo "[chezmoi] Checking if 1Password CLI is already installed..."
check_1password_installed

echo "[chezmoi] 1Password CLI not found! Proceeding with installation..."
echo "[chezmoi] This may take a few moments..."
install_1password

echo "[chezmoi] 1Password CLI installation completed successfully!"