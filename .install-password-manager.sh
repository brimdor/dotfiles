#!/bin/bash

set -euo pipefail

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
    elif command -v apt-get &>/dev/null; then
        # Debian/Ubuntu using apt-get
        export DEBIAN_FRONTEND=noninteractive
        export DEBCONF_NOWARNINGS=yes
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq > /dev/null || true
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https ca-certificates curl gnupg > /dev/null || true
        ARCH=$(dpkg --print-architecture)
        echo "[chezmoi] Installing 1Password CLI for Debian/Ubuntu..."
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${ARCH} stable main" | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmour --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y 1password-cli -qq >/dev/null|| true
    elif command -v dnf &>/dev/null; then
        # Fedora using dnf
        echo "[chezmoi] Installing 1Password CLI for Fedora..."
        sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
        sudo sh -c 'echo -e "[1password]\nname=1Password Repository\nbaseurl=https://downloads.1password.com/linux/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=0" > /etc/yum.repos.d/1password.repo'
        sudo dnf check-update -y 1password-cli
        sudo dnf install 1password-cli -y || true
    elif command -v pacman &>/dev/null; then
        # Arch Linux using pacman
        echo "[chezmoi] Installing 1Password CLI for Arch Linux..."
        sudo pacman -S --noconfirm --needed 1password-cli || true
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
        curl -LO "https://cache.agilebits.com/dist/1P/op2/pkg/${VERSION}/op_linux_${ARCH_RAW}_${VERSION}.zip"
        unzip -d op "op_linux_${ARCH_RAW}_${VERSION}.zip"
        sudo mv op/op $HOME/.local/bin/op
        rm -rf op* || true

        sudo groupadd -f onepassword-cli
        sudo chgrp onepassword-cli $HOME/.local/bin/op
        sudo chmod g+s $HOME/.local/bin/op
        echo "[chezmoi] 1Password CLI manual installation completed."
    fi
}


echo "[chezmoi] Prewarming sudo..."
sudo true

echo "[chezmoi] Checking if 1Password CLI is already installed..."
check_1password_installed

echo "[chezmoi] 1Password CLI not found! Proceeding with installation..."
echo "[chezmoi] This may take a few moments..."
install_1password

echo "[chezmoi] 1Password CLI installation completed successfully!"