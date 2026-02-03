#!/bin/bash
# Universe Development Environment Setup Script
# This script sets up a fresh Codespace for building the Android APK

set -e

echo "=========================================="
echo "Universe Codespace Setup"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get install -y git wget unzip zip curl

# Install Python 3.11 (compatible with Chaquopy)
echo "Installing Python 3.11 (3.11.14)..."
# Python 3.11 is available from ppa.launchpadcontent.net (already configured in this environment)
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Install pip for Python 3.11 (without changing default python)
echo "Installing pip for Python 3.11..."
sudo python3.11 -m ensurepip --upgrade 2>/dev/null || true

# Verify Python 3.11 is available
echo "Python 3.11 version:"
python3.11 --version
python3.11 -m pip --version 2>/dev/null || echo "pip installation via ensurepip may have been skipped"

# Install Java 17.0.17 (Microsoft build via SDKMAN)
echo "Installing Java 17.0.17 (Microsoft build)..."
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

# Set JAVA_HOME from the installed java binary
JAVA_BIN=$(readlink -f "$(which java)")
export JAVA_HOME=$(dirname "$(dirname "$JAVA_BIN")")
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

# Verify Java version
echo "Java version:"
java -version

# Install Android SDK command line tools (cmdline-tools 20.0)
echo "Installing Android SDK..."
ANDROID_HOME=/opt/android-sdk
sudo mkdir -p $ANDROID_HOME/cmdline-tools
cd /tmp
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O commandlinetools-linux-latest.zip
sudo unzip -q commandlinetools-linux-latest.zip -d $ANDROID_HOME/cmdline-tools
sudo mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest 2>/dev/null || true
sudo chown -R $(whoami) $ANDROID_HOME

# Set Android environment variables
export ANDROID_HOME=$ANDROID_HOME
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
echo "export ANDROID_HOME=$ANDROID_HOME" >> ~/.bashrc
echo "export ANDROID_SDK_ROOT=$ANDROID_HOME" >> ~/.bashrc
echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >> ~/.bashrc

# Accept Android SDK licenses
echo "Accepting Android SDK licenses..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true

# Install required Android SDK components (match current codespace)
echo "Installing Android SDK components..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-28" \
    "platforms;android-30" \
    "platforms;android-31" \
    "platforms;android-33" \
    "platforms;android-34" \
    "platforms;android-35" \
    "platforms;android-36" \
    "build-tools;30.0.3" \
    "build-tools;35.0.0" \
    "cmake;3.18.1" \
    "ndk;21.4.7075529"

# Install Flutter 3.16.9 (stable)
if [ ! -d "/opt/flutter" ] || [ ! -d "/opt/flutter/.git" ]; then
    echo "Installing Flutter 3.16.9..."
    sudo rm -rf /opt/flutter
    cd /opt
    sudo git clone https://github.com/flutter/flutter.git -b 3.16.9 --depth 1
    sudo chown -R $(whoami) /opt/flutter
else
    echo "Ensuring Flutter is on 3.16.9..."
    cd /opt/flutter
    git fetch --tags
    git checkout 3.16.9
    git reset --hard
fi

# Set Flutter environment variables
export PATH=$PATH:/opt/flutter/bin
echo "export PATH=\$PATH:/opt/flutter/bin" >> ~/.bashrc

# Verify Flutter version
echo "Flutter version:"
flutter --version

# Run Flutter doctor
echo "Running Flutter doctor..."
flutter doctor -v

# Configure Flutter for Android
flutter config --android-sdk $ANDROID_HOME

# Install Flutter dependencies for the project
echo "Installing Flutter dependencies..."
cd /workspaces/BlackHole
flutter pub get

# Clean any previous builds
echo "Cleaning previous builds..."
flutter clean

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Important: Reload your shell to apply environment variables:"
echo "  source ~/.bashrc"
echo ""
echo "Then you can build the APK with:"
echo "  cd /workspaces/BlackHole"
echo "  flutter build apk --debug"
echo ""
echo "Verify setup with:"
echo "  flutter doctor -v"
echo "  python3 --version  # Should show 3.11.x"
echo "  java -version      # Should show OpenJDK 17"
echo ""
