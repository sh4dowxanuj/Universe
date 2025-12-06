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

# Install Python 3.11 (compatible with Chaquopy)
echo "Installing Python 3.11..."
# Python 3.11 is available from ppa.launchpadcontent.net (already configured in this environment)
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Install pip for Python 3.11 (without changing default python)
echo "Installing pip for Python 3.11..."
sudo python3.11 -m ensurepip --upgrade 2>/dev/null || true

# Verify Python 3.11 is available
echo "Python 3.11 version:"
python3.11 --version
python3.11 -m pip --version 2>/dev/null || echo "pip installation via ensurepip may have been skipped"

# Install Java 17 (required for Flutter/Gradle)
echo "Installing Java 17..."
sudo apt-get install -y openjdk-17-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

# Verify Java version
echo "Java version:"
java -version

# Install Android SDK command line tools
echo "Installing Android SDK..."
ANDROID_HOME=/opt/android-sdk
sudo mkdir -p $ANDROID_HOME
cd /tmp
wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
sudo unzip -q commandlinetools-linux-9477386_latest.zip -d $ANDROID_HOME
sudo mkdir -p $ANDROID_HOME/cmdline-tools/latest
sudo mv $ANDROID_HOME/cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest/ 2>/dev/null || true

# Set Android environment variables
export ANDROID_HOME=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
echo "export ANDROID_HOME=$ANDROID_HOME" >> ~/.bashrc
echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >> ~/.bashrc

# Accept Android SDK licenses
echo "Accepting Android SDK licenses..."
yes | sudo $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true

# Install required Android SDK components
echo "Installing Android SDK components..."
sudo $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;21.4.7075529"

# Install Flutter (if not already installed)
if [ ! -d "/opt/flutter" ]; then
    echo "Installing Flutter..."
    cd /opt
    sudo git clone https://github.com/flutter/flutter.git -b stable --depth 1
    sudo chown -R $(whoami) /opt/flutter
fi

# Set Flutter environment variables
export PATH=$PATH:/opt/flutter/bin
echo "export PATH=\$PATH:/opt/flutter/bin" >> ~/.bashrc

# Update Flutter
echo "Updating Flutter..."
flutter upgrade

# Run Flutter doctor
echo "Running Flutter doctor..."
flutter doctor -v

# Configure Flutter for Android
flutter config --android-sdk $ANDROID_HOME

# Install Flutter dependencies for the project
echo "Installing Flutter dependencies..."
cd /workspaces/Universe
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
echo "  cd /workspaces/Universe"
echo "  flutter build apk --debug"
echo ""
echo "Verify setup with:"
echo "  flutter doctor -v"
echo "  python3 --version  # Should show 3.11.x"
echo "  java -version      # Should show OpenJDK 17"
echo ""
