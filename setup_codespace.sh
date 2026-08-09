#!/bin/bash
# Universe Development Environment Setup Script
# This script sets up a fresh Codespace for building the Android APK

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_BASHRC="$TARGET_HOME/.bashrc"

echo "=========================================="
echo "Universe Codespace Setup"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get install -y git wget unzip zip curl software-properties-common

# Install Python 3.11 (Chaquopy build host requirement)
echo "Installing Python 3.11 for Chaquopy..."
if ! command -v python3.11 >/dev/null 2>&1; then
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
fi
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev

# Prepare a dedicated build Python for Chaquopy
echo "Preparing Chaquopy build Python environment..."
CHAQUOPY_HOST_PYTHON="$(command -v python3.11)"
sudo rm -rf /opt/chaquopy-python
sudo "$CHAQUOPY_HOST_PYTHON" -m venv /opt/chaquopy-python
sudo /opt/chaquopy-python/bin/python3 -m pip install --upgrade "pip==23.2.1" setuptools wheel
sudo chown -R "$TARGET_USER":"$TARGET_USER" /opt/chaquopy-python

# Install Java 17.0.17 (Microsoft build via SDKMAN)
echo "Installing Java 17 (Microsoft build)..."
if ! command -v java >/dev/null 2>&1; then
    sudo apt-get install -y zip unzip curl
fi

SDKMAN_DIR="${SDKMAN_DIR:-}"
if [ -z "$SDKMAN_DIR" ]; then
    if [ -d "/usr/local/sdkman" ]; then
        SDKMAN_DIR="/usr/local/sdkman"
    else
        SDKMAN_DIR="$HOME/.sdkman"
    fi
fi

if [ ! -d "$SDKMAN_DIR" ]; then
    curl -s "https://get.sdkman.io" | bash
fi

source "$SDKMAN_DIR/bin/sdkman-init.sh"
if ! sdk list java | grep -q "17.0.17-ms"; then
    yes | sdk install java 17.0.17-ms
else
    sdk install java 17.0.17-ms >/dev/null 2>&1 || true
fi
sdk default java 17.0.17-ms

# Set JAVA_HOME from installed java binary
JAVA_BIN=$(readlink -f "$(which java)")
export JAVA_HOME=$(dirname "$(dirname "$JAVA_BIN")")
echo "export JAVA_HOME=$JAVA_HOME" >> "$TARGET_BASHRC"
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$TARGET_BASHRC"

# Verify Java version
echo "Java version:"
java -version

# Install Android SDK command line tools
echo "Installing Android SDK..."
ANDROID_HOME=/opt/android-sdk
sudo mkdir -p $ANDROID_HOME/cmdline-tools
cd /tmp
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O commandlinetools-linux-latest.zip
sudo unzip -oq commandlinetools-linux-latest.zip -d $ANDROID_HOME/cmdline-tools
sudo mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest 2>/dev/null || true
sudo chown -R "$TARGET_USER":"$TARGET_USER" $ANDROID_HOME

# Set Android environment variables
export ANDROID_HOME=$ANDROID_HOME
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
echo "export ANDROID_HOME=$ANDROID_HOME" >> "$TARGET_BASHRC"
echo "export ANDROID_SDK_ROOT=$ANDROID_HOME" >> "$TARGET_BASHRC"
echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >> "$TARGET_BASHRC"

# Accept Android SDK licenses
echo "Accepting Android SDK licenses..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true

# Install required Android SDK components for AGP 8.8+ & Flutter
echo "Installing Android SDK components..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "platforms;android-35" \
    "build-tools;34.0.0" \
    "build-tools;35.0.0" \
    "cmake;3.22.1" \
    "ndk;25.1.8937393"

# Install stable Flutter SDK
if [ ! -d "/opt/flutter" ] || [ ! -d "/opt/flutter/.git" ]; then
    echo "Installing Flutter (stable branch)..."
    sudo rm -rf /opt/flutter
    cd /opt
    sudo git clone https://github.com/flutter/flutter.git -b stable --depth 1
    sudo chown -R "$TARGET_USER":"$TARGET_USER" /opt/flutter
else
    echo "Ensuring Flutter is on stable branch..."
    cd /opt/flutter
    git fetch origin stable
    git checkout stable
    git pull origin stable
fi

sudo git config --system --add safe.directory /opt/flutter 2>/dev/null || true
sudo chown -R "$TARGET_USER":"$TARGET_USER" /opt/flutter

# Set Flutter environment variables
export PATH=$PATH:/opt/flutter/bin
sudo ln -sf /opt/flutter/bin/flutter /usr/local/bin/flutter
echo "export PATH=\$PATH:/opt/flutter/bin" >> "$TARGET_BASHRC"

# Verify Flutter version
echo "Flutter version:"
flutter --version

# Run Flutter doctor
echo "Running Flutter doctor..."
flutter doctor -v

# Configure Flutter for Android SDK path
sudo -u "$TARGET_USER" HOME="$TARGET_HOME" /usr/local/bin/flutter config --android-sdk "$ANDROID_HOME"

# Install Flutter dependencies for project
echo "Installing Flutter dependencies..."
cd "$SCRIPT_DIR"
flutter pub get

# Clean any previous builds
echo "Cleaning previous builds..."
flutter clean

sudo chown -R $USER:$USER /opt/flutter

# 1. Export ANDROID_HOME for current session
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# 2. Tell Flutter explicitly where the SDK is located
flutter config --android-sdk /opt/android-sdk

# 3. Accept Android SDK licenses
yes | flutter doctor --android-licenses


echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Important: Reload your shell to apply environment variables:"
echo "  source ~/.bashrc"
echo ""
echo "Then build your release APK with:"
echo "  cd /workspaces/Universe"
echo "  flutter build apk --release"
echo ""