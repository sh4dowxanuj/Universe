#!/bin/bash
# Universe Development Environment Setup Script
# Optimized, fully idempotent setup for GitHub Codespaces building Android/Flutter APKs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_BASHRC="$TARGET_HOME/.bashrc"
export DEBIAN_FRONTEND=noninteractive

# Helper function to append lines to bashrc without duplicates
add_to_bashrc() {
    local line="$1"
    if ! grep -Fq "$line" "$TARGET_BASHRC" 2>/dev/null; then
        echo "$line" >> "$TARGET_BASHRC"
    fi
}

echo "=========================================="
echo "Universe Codespace Setup"
echo "=========================================="

# 1. System Packages
echo "Checking system dependencies..."
REQUIRED_PKGS=(git wget unzip zip curl software-properties-common)
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "Installing missing packages: ${MISSING_PKGS[*]}..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${MISSING_PKGS[@]}"
else
    echo "✔ System packages are up to date."
fi

# 2. Python 3.11 (Chaquopy host requirement)
echo "Checking Python 3.11..."
if ! command -v python3.11 >/dev/null 2>&1; then
    echo "Installing Python 3.11..."
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3.11 python3.11-venv python3.11-dev
    echo "✔ Python 3.11 installed."
else
    echo "✔ Python 3.11 is already installed ($(python3.11 --version))."
fi

# Set Python 3.11 as the active CLI python for TARGET_USER
echo "Setting up Python 3.11 CLI symlinks..."
sudo mkdir -p /opt/python311-bin
sudo ln -sf "$(command -v python3.11)" /opt/python311-bin/python
sudo ln -sf "$(command -v python3.11)" /opt/python311-bin/python3

add_to_bashrc 'export PATH=/opt/python311-bin:$PATH'
export PATH=/opt/python311-bin:$PATH

# 3. Dedicated Chaquopy Python Environment
echo "Checking Chaquopy build environment..."
CHAQUOPY_HOST_PYTHON="$(command -v python3.11)"
if [ ! -f "/opt/chaquopy-python/bin/python3" ]; then
    echo "Creating Chaquopy venv at /opt/chaquopy-python..."
    sudo rm -rf /opt/chaquopy-python
    sudo "$CHAQUOPY_HOST_PYTHON" -m venv /opt/chaquopy-python
    sudo /opt/chaquopy-python/bin/python3 -m pip install --quiet --upgrade "pip==23.2.1" setuptools wheel
    sudo chown -R "$TARGET_USER":"$TARGET_USER" /opt/chaquopy-python
    echo "✔ Chaquopy environment prepared."
else
    echo "✔ Chaquopy Python venv exists at /opt/chaquopy-python."
fi

# 4. Java 17.0.17 (Microsoft build via SDKMAN)
echo "Checking Java 17..."
SDKMAN_DIR="${SDKMAN_DIR:-}"
if [ -z "$SDKMAN_DIR" ]; then
    if [ -d "/usr/local/sdkman" ]; then
        SDKMAN_DIR="/usr/local/sdkman"
    else
        SDKMAN_DIR="$TARGET_HOME/.sdkman"
    fi
fi

if [ ! -d "$SDKMAN_DIR" ]; then
    echo "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
fi

if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
    set +u
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    set -u
fi

if ! sdk list java 2>/dev/null | grep -q "17.0.17-ms" || ! command -v java >/dev/null 2>&1; then
    echo "Installing Java 17.0.17-ms..."
    set +u
    yes | sdk install java 17.0.17-ms || true
    sdk default java 17.0.17-ms >/dev/null 2>&1 || true
    set -u
    echo "✔ Java 17 installed."
else
    echo "✔ Java 17 (Microsoft build) is ready."
fi

JAVA_BIN=$(readlink -f "$(which java)" 2>/dev/null || echo "")
if [ -n "$JAVA_BIN" ]; then
    JAVA_HOME=$(dirname "$(dirname "$JAVA_BIN")")
    export JAVA_HOME
    add_to_bashrc "export JAVA_HOME=$JAVA_HOME"
    add_to_bashrc 'export PATH=$JAVA_HOME/bin:$PATH'
fi

# 5. Android SDK & CLI Tools
echo "Checking Android SDK..."
ANDROID_HOME=/opt/android-sdk

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    echo "Downloading Android SDK Command Line Tools..."
    sudo mkdir -p "$ANDROID_HOME/cmdline-tools"
    TMP_DIR=$(mktemp -d)
    trap 'sudo rm -rf "$TMP_DIR"' EXIT
    
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip -O "$TMP_DIR/cmdline.zip"
    sudo unzip -oq "$TMP_DIR/cmdline.zip" -d "$ANDROID_HOME/cmdline-tools"
    sudo mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" 2>/dev/null || true
    sudo chown -R "$TARGET_USER":"$TARGET_USER" "$ANDROID_HOME"
    echo "✔ Android Command Line Tools installed."
else
    echo "✔ Android Command Line Tools present."
fi

export ANDROID_HOME=$ANDROID_HOME
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

add_to_bashrc "export ANDROID_HOME=$ANDROID_HOME"
add_to_bashrc "export ANDROID_SDK_ROOT=$ANDROID_HOME"
add_to_bashrc 'export PATH=$PATH:'"$ANDROID_HOME"'/cmdline-tools/latest/bin:'"$ANDROID_HOME"'/platform-tools'

# Accept SDK Licenses & Install Components conditionally
echo "Verifying Android SDK licenses and components..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null 2>&1 || true

if [ ! -d "$ANDROID_HOME/platforms/android-35" ] || [ ! -d "$ANDROID_HOME/build-tools/35.0.0" ]; then
    echo "Installing missing Android SDK components..."
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;30.0.3" \
        "build-tools;35.0.0" \
        "cmake;3.22.1" \
        "ndk;27.0.12077973"
        
    echo "✔ Android SDK components installed."
else
    echo "✔ Android SDK components ready."
fi

# 6. Flutter 3.22.3
echo "Checking Flutter installation..."
if [ ! -d "/opt/flutter" ] || [ ! -d "/opt/flutter/.git" ]; then
    echo "Installing Flutter 3.22.3..."
    sudo rm -rf /opt/flutter
    sudo git clone https://github.com/flutter/flutter.git -b 3.22.3 --depth 1 /opt/flutter
    sudo chown -R "$TARGET_USER":"$TARGET_USER" /opt/flutter
    echo "✔ Flutter cloned."
else
    CURRENT_TAG=$(git -C /opt/flutter describe --tags 2>/dev/null || echo "")
    if [ "$CURRENT_TAG" != "3.22.3" ]; then
        echo "Switching Flutter to 3.22.3..."
        git -C /opt/flutter fetch --tags --depth 1 origin tag 3.22.3
        git -C /opt/flutter checkout 3.22.3
        git -C /opt/flutter reset --hard
    else
        echo "✔ Flutter 3.22.3 configured."
    fi
fi

sudo git config --system --add safe.directory /opt/flutter 2>/dev/null || true
sudo chown -R "$TARGET_USER":"$TARGET_USER" /opt/flutter

export PATH=$PATH:/opt/flutter/bin
sudo ln -sf /opt/flutter/bin/flutter /usr/local/bin/flutter
add_to_bashrc 'export PATH=$PATH:/opt/flutter/bin'

# 7. Flutter Configuration & Pub Dependencies
echo "Configuring Flutter environment..."
sudo -u "$TARGET_USER" HOME="$TARGET_HOME" /usr/local/bin/flutter config --android-sdk "$ANDROID_HOME" >/dev/null 2>&1

if [ -f "$SCRIPT_DIR/pubspec.yaml" ]; then
    echo "Fetching Flutter dependencies..."
    cd "$SCRIPT_DIR"
    flutter pub get
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Reload shell to apply environment variables:"
echo "  source ~/.bashrc"
echo ""
echo "Build project via:"
echo "  flutter build apk --debug"
echo ""