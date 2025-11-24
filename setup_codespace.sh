#!/bin/bash
# BlackHole Development Environment Setup Script
# This script sets up a fresh Codespace for building the Android APK

set -e

echo "=========================================="
echo "BlackHole Codespace Setup"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
sudo apt-get update

# Install Python 3.11 (compatible with Chaquopy)
echo "Installing Python 3.11..."
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev

# Set Python 3.11 as the default python3
echo "Setting Python 3.11 as default..."
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2
sudo update-alternatives --set python3 /usr/bin/python3.11

# Install pip for Python 3.11
echo "Installing pip for Python 3.11..."
curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.11

# Verify Python version
echo "Python version:"
python3 --version
pip3 --version

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
