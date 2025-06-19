#!/bin/bash

set -euo pipefail

check_1password_installed() {
    if command -v op &>/dev/null; then
        echo "[chezmoi] 1Password CLI is already installed."
        exit 0
    else
        echo "[chezmoi] 1Password CLI is not installed. Proceeding with installation."
    fi
}

get_latest_version() {
    # Try to get version from GitHub API
    local version
    version=$(curl -s https://api.github.com/repos/1Password/op/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    # If empty, use a hardcoded fallback version
    if [[ -z "$version" ]]; then
        echo "[chezmoi] Warning: Could not determine latest version from GitHub API. Using fallback version."
        version="v2.22.0"  # Hardcoded fallback version
    fi
    
    echo "$version"
}

install_1password_linux() {
    VERSION="$(get_latest_version)"
    if [[ -z "$VERSION" ]]; then
        echo "[chezmoi] Error: Could not determine 1Password version."
        exit 1
    fi
    
    echo "[chezmoi] Installing 1Password CLI $VERSION for Linux..."
    ARCH_RAW="$(uname -m)"
    case "$ARCH_RAW" in
        x86_64) ARCH="amd64" ;;
        aarch64 | arm64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
        i386) ARCH="386" ;;
        *) echo "[chezmoi] Unsupported architecture: $ARCH_RAW" && exit 1 ;;
    esac

    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"

    ZIPFILE="op_linux_${ARCH}_${VERSION}.zip"
    URL="https://cache.agilebits.com/dist/1P/op2/pkg/${VERSION}/op_linux_${ARCH}_${VERSION}.zip"

    echo "[chezmoi] Downloading from $URL"
    curl -L -o "$ZIPFILE" "$URL" || { echo "[chezmoi] Download failed!"; exit 1; }
    
    if ! command -v unzip &>/dev/null; then
        echo "[chezmoi] unzip not found! Installing..."
        sudo apt-get update -qq && sudo apt-get install -y unzip -qq
    fi
    
    unzip -d op "$ZIPFILE" || { echo "[chezmoi] unzip failed!"; exit 1; }
    if [[ ! -f op/op ]]; then
        echo "[chezmoi] op binary not found after unzip!"
        ls -l op
        exit 1
    fi
    mv op/op "$INSTALL_DIR/op"
    rm -rf op "$ZIPFILE"

    chmod 755 "$INSTALL_DIR/op"
    echo "[chezmoi] 1Password CLI $VERSION installed to $INSTALL_DIR."
}

install_1password_macos() {
    if command -v brew &>/dev/null; then
        echo "[chezmoi] Installing 1Password CLI via Homebrew..."
        brew install 1password-cli
        ln -sf "$(brew --prefix)/bin/op" "$HOME/.local/bin/op"
    else
        VERSION="$(get_latest_version)"
        ARCH_RAW="$(uname -m)"
        case "$ARCH_RAW" in
            x86_64) ARCH="amd64" ;;
            arm64) ARCH="arm64" ;;
            *) echo "[chezmoi] Unsupported architecture: $ARCH_RAW" && exit 1 ;;
        esac

        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"

        ZIPFILE="op_darwin_${ARCH}_${VERSION}.zip"
        URL="https://cache.agilebits.com/dist/1P/op2/pkg/${VERSION}/op_darwin_${ARCH}_${VERSION}.zip"

        echo "[chezmoi] Downloading 1Password CLI $VERSION for macOS $ARCH..."
        curl -L -o "$ZIPFILE" "$URL"
        unzip -d op "$ZIPFILE"
        mv op/op "$INSTALL_DIR/op"
        rm -rf op "$ZIPFILE"

        chmod 755 "$INSTALL_DIR/op"
        echo "[chezmoi] 1Password CLI $VERSION installed to $INSTALL_DIR."
    fi
}

echo "[chezmoi] Checking if 1Password CLI is already installed..."
check_1password_installed

echo "[chezmoi] Checking OS Version"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
echo "[chezmoi] Detected OS: $OS"

if [[ "$OS" == "linux" ]]; then
    echo "[chezmoi] Starting Installation for Linux OS"
    install_1password_linux
elif [[ "$OS" == "darwin" ]]; then
    echo "[chezmoi] Starting Installation for macOS"
    install_1password_macos
else
    echo "[chezmoi] Unsupported OS: $OS"
    exit 1
fi

echo "[chezmoi] 1Password CLI installation completed successfully."