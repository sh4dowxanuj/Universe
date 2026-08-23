#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_BASHRC="$TARGET_HOME/.bashrc"

# ==================================================
# Versions / paths
# ==================================================

FLUTTER_VERSION="3.47.1"
FLUTTER_DIR="/opt/flutter"

ANDROID_HOME="/opt/android-sdk"
ANDROID_CMDLINE_TOOLS="$ANDROID_HOME/cmdline-tools/latest"

SDKMAN_DIR="/usr/local/sdkman"
JAVA_VERSION="17.0.20-ms"
JAVA_INSTALL_DIR="$SDKMAN_DIR/candidates/java/$JAVA_VERSION"

CHAQUOPY_DIR="/opt/chaquopy-python"
CHAQUOPY_PIP_VERSION="23.2.1"

NDK_VERSION="28.2.13676358"

SDKMANAGER="$ANDROID_CMDLINE_TOOLS/bin/sdkmanager"

export DEBIAN_FRONTEND=noninteractive

# ==================================================
# Output
# ==================================================

echo "=========================================="
echo "Universe Codespace Setup"
echo "=========================================="
echo "User:        $TARGET_USER"
echo "Home:        $TARGET_HOME"
echo "Flutter:     $FLUTTER_VERSION"
echo "Java:        $JAVA_VERSION"
echo "Python:      3.11"
echo "Android SDK: $ANDROID_HOME"
echo "NDK:         $NDK_VERSION"
echo "=========================================="

# ==================================================
# Helpers
# ==================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null |
        grep -q "install ok installed"
}

add_to_bashrc() {
    local line="$1"

    touch "$TARGET_BASHRC"

    if ! grep -qxF "$line" "$TARGET_BASHRC" 2>/dev/null; then
        echo "$line" >> "$TARGET_BASHRC"
    fi
}

# ==================================================
# Basic packages
# ==================================================

echo ""
echo "==> Checking basic packages..."

BASIC_PACKAGES=(
    git
    wget
    unzip
    zip
    curl
    software-properties-common
)

MISSING_PACKAGES=()

for package in "${BASIC_PACKAGES[@]}"; do
    if package_installed "$package"; then
        echo "  [✓] $package"
    else
        echo "  [ ] $package"
        MISSING_PACKAGES+=("$package")
    fi
done

if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
    echo ""
    echo "Installing missing packages..."

    sudo apt-get update
    sudo apt-get install -y "${MISSING_PACKAGES[@]}"
else
    echo "Basic packages already installed."
fi

# ==================================================
# Python 3.11
# ==================================================

echo ""
echo "==> Checking Python 3.11..."

if command_exists python3.11; then
    echo "Python 3.11 already installed:"
else
    echo "Python 3.11 not found."

    if ! grep -Rqs \
        "ppa.launchpadcontent.net/deadsnakes/ppa" \
        /etc/apt/sources.list \
        /etc/apt/sources.list.d 2>/dev/null; then

        echo "Adding deadsnakes PPA..."

        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt-get update
    fi

    sudo apt-get install -y \
        python3.11 \
        python3.11-venv \
        python3.11-dev
fi

python3.11 --version

# ==================================================
# Chaquopy Python
# ==================================================

echo ""
echo "==> Checking Chaquopy Python environment..."

CHAQUOPY_VALID=false

if [ -x "$CHAQUOPY_DIR/bin/python" ]; then
    if "$CHAQUOPY_DIR/bin/python" -c \
        'import sys; raise SystemExit(0 if sys.version_info[:2] == (3,11) else 1)' \
        >/dev/null 2>&1; then

        CHAQUOPY_VALID=true

        echo "Chaquopy Python already configured:"
        "$CHAQUOPY_DIR/bin/python" --version
    fi
fi

if [ "$CHAQUOPY_VALID" = false ]; then

    echo "Chaquopy Python environment is missing or invalid."

    if [ -d "$CHAQUOPY_DIR" ]; then
        echo "Removing invalid environment..."
        sudo rm -rf "$CHAQUOPY_DIR"
    fi

    echo "Creating Chaquopy Python environment..."

    sudo python3.11 -m venv "$CHAQUOPY_DIR"

    sudo "$CHAQUOPY_DIR/bin/python" \
        -m pip install \
        --upgrade \
        "pip==$CHAQUOPY_PIP_VERSION" \
        setuptools \
        wheel

    sudo chown -R \
        "$TARGET_USER:$TARGET_USER" \
        "$CHAQUOPY_DIR"
fi

echo "Chaquopy Python:"
"$CHAQUOPY_DIR/bin/python" --version

# ==================================================
# Python resolution
# ==================================================

echo ""
echo "Python resolution:"
echo "  Chaquopy -> $CHAQUOPY_DIR/bin/python"

if "$CHAQUOPY_DIR/bin/python" -c \
    'import sys; raise SystemExit(0 if sys.version_info[:2] == (3,11) else 1)' \
    >/dev/null 2>&1; then

    echo "[✓] Chaquopy uses Python 3.11."

else

    echo "[!] Chaquopy Python version is incorrect."
    exit 1

fi

# ==================================================
# Java 17
# ==================================================

echo ""
echo "==> Checking Java 17..."

JAVA_READY=false

if [ -x "$JAVA_INSTALL_DIR/bin/java" ]; then

    INSTALLED_JAVA_VERSION="$(
        "$JAVA_INSTALL_DIR/bin/java" -version 2>&1 |
        sed -n 's/.*version "\([0-9][0-9.]*\).*/\1/p' |
        head -1
    )"

    if [ "$INSTALLED_JAVA_VERSION" = "17.0.20" ]; then
        JAVA_READY=true
        echo "Java $JAVA_VERSION already installed."
    else
        echo "Java installation exists but version is:"
        echo "  ${INSTALLED_JAVA_VERSION:-unknown}"
    fi
fi

if [ "$JAVA_READY" = false ]; then

    echo "Required Java $JAVA_VERSION was not found."

    if [ ! -f "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then

        echo "SDKMAN not found."
        echo "Installing SDKMAN..."

        set +u
        curl -s "https://get.sdkman.io" | bash
        set -u
    fi

    if [ ! -f "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
        echo ""
        echo "ERROR: SDKMAN installation was not found:"
        echo "  $SDKMAN_DIR"
        exit 1
    fi

    echo ""
    echo "Installing Java through SDKMAN..."

    # Use a separate shell so SDKMAN never affects this
    # script's set -u environment.
    bash -c '
        set +u

        SDKMAN_DIR="$1"
        JAVA_VERSION="$2"
        JAVA_INSTALL_DIR="$3"

        export SDKMAN_DIR

        source "$SDKMAN_DIR/bin/sdkman-init.sh"

        if ! sdk list java | grep -q "$JAVA_VERSION"; then
            echo "ERROR: Java $JAVA_VERSION is unavailable through SDKMAN."
            exit 1
        fi

        if [ ! -x "$JAVA_INSTALL_DIR/bin/java" ]; then
            yes | sdk install java "$JAVA_VERSION"
        fi

        sdk default java "$JAVA_VERSION"
    ' bash "$SDKMAN_DIR" "$JAVA_VERSION" "$JAVA_INSTALL_DIR"

    if [ ! -x "$JAVA_INSTALL_DIR/bin/java" ]; then
        echo ""
        echo "ERROR: Java installation failed."
        exit 1
    fi

    echo "Java $JAVA_VERSION installed."
fi

# ==================================================
# Java environment
# ==================================================

export JAVA_HOME="$JAVA_INSTALL_DIR"
export PATH="$JAVA_HOME/bin:$PATH"

add_to_bashrc \
    'export JAVA_HOME="/usr/local/sdkman/candidates/java/17.0.20-ms"'

add_to_bashrc \
    'export PATH="$JAVA_HOME/bin:$PATH"'

echo ""
echo "Java:"
java -version

# ==================================================
# Android SDK command-line tools
# ==================================================

echo ""
echo "==> Checking Android SDK command-line tools..."

if [ -x "$SDKMANAGER" ]; then

    echo "Android command-line tools already installed."

else

    echo "Android command-line tools not found."

    sudo mkdir -p "$ANDROID_HOME/cmdline-tools"

    TMP_DIR="$(mktemp -d)"
    SDK_ZIP="$TMP_DIR/android-cmdline-tools.zip"

    echo "Downloading Android command-line tools..."

    wget -q \
        "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
        -O "$SDK_ZIP"

    echo "Extracting Android command-line tools..."

    unzip -q "$SDK_ZIP" -d "$TMP_DIR"

    sudo rm -rf "$ANDROID_CMDLINE_TOOLS"

    sudo mkdir -p "$ANDROID_CMDLINE_TOOLS"

    sudo cp -a \
        "$TMP_DIR/cmdline-tools/." \
        "$ANDROID_CMDLINE_TOOLS/"

    sudo chown -R \
        "$TARGET_USER:$TARGET_USER" \
        "$ANDROID_HOME"

    rm -rf "$TMP_DIR"

    echo "Android command-line tools installed."
fi

export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

export PATH="$ANDROID_CMDLINE_TOOLS/bin:$ANDROID_HOME/platform-tools:$PATH"

add_to_bashrc \
    'export ANDROID_HOME="/opt/android-sdk"'

add_to_bashrc \
    'export ANDROID_SDK_ROOT="/opt/android-sdk"'

add_to_bashrc \
    'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"'

if [ ! -x "$SDKMANAGER" ]; then
    echo ""
    echo "ERROR: sdkmanager was not installed correctly."
    exit 1
fi

echo ""
echo "sdkmanager:"
"$SDKMANAGER" --version

# ==================================================
# Android licenses
# ==================================================

echo ""
echo "==> Checking Android licenses..."

if yes | "$SDKMANAGER" --licenses >/dev/null 2>&1; then
    echo "Android licenses accepted."
else
    echo "Android licenses already present or no new licenses required."
fi

# ==================================================
# Android SDK components
# ==================================================

echo ""
echo "==> Checking Android SDK components..."

ANDROID_COMPONENTS=(
    "platform-tools"
    "platforms;android-35"
    "platforms;android-36"
    "build-tools;35.0.0"
    "build-tools;36.0.0"
    "ndk;$NDK_VERSION"
)

MISSING_COMPONENTS=()

for component in "${ANDROID_COMPONENTS[@]}"; do

    case "$component" in
        platform-tools)
            CHECK_PATH="$ANDROID_HOME/platform-tools"
            ;;

        platforms\;*)
            VERSION="${component#platforms;}"
            CHECK_PATH="$ANDROID_HOME/platforms/$VERSION"
            ;;

        build-tools\;*)
            VERSION="${component#build-tools;}"
            CHECK_PATH="$ANDROID_HOME/build-tools/$VERSION"
            ;;

        ndk\;*)
            VERSION="${component#ndk;}"
            CHECK_PATH="$ANDROID_HOME/ndk/$VERSION"
            ;;

        *)
            CHECK_PATH=""
            ;;
    esac

    if [ -n "$CHECK_PATH" ] && [ -d "$CHECK_PATH" ]; then
        echo "  [✓] $component"
    else
        echo "  [ ] $component"
        MISSING_COMPONENTS+=("$component")
    fi
done

if [ "${#MISSING_COMPONENTS[@]}" -gt 0 ]; then

    echo ""
    echo "Installing missing Android components..."

    printf '  %s\n' "${MISSING_COMPONENTS[@]}"

    "$SDKMANAGER" "${MISSING_COMPONENTS[@]}"

else

    echo ""
    echo "All required Android components are already installed."

fi

# ==================================================
# Flutter
# ==================================================

echo ""
echo "==> Checking Flutter $FLUTTER_VERSION..."

FLUTTER_VERSION_OK=false

if [ -x "$FLUTTER_DIR/bin/flutter" ]; then

    INSTALLED_FLUTTER_VERSION="$(
        "$FLUTTER_DIR/bin/flutter" --version 2>/dev/null |
        sed -n 's/^Flutter \([0-9][0-9.]*\).*/\1/p' |
        head -1
    )"

    if [ "$INSTALLED_FLUTTER_VERSION" = "$FLUTTER_VERSION" ]; then

        FLUTTER_VERSION_OK=true

        echo "Flutter $FLUTTER_VERSION already installed."

    else

        echo "Flutter version mismatch."
        echo "Installed: ${INSTALLED_FLUTTER_VERSION:-unknown}"
        echo "Required:  $FLUTTER_VERSION"

    fi
fi

if [ "$FLUTTER_VERSION_OK" = false ]; then

    if [ -d "$FLUTTER_DIR" ]; then
        echo "Removing incorrect Flutter installation..."
        sudo rm -rf "$FLUTTER_DIR"
    fi

    echo "Installing Flutter $FLUTTER_VERSION..."

    sudo git clone \
        https://github.com/flutter/flutter.git \
        -b "$FLUTTER_VERSION" \
        --depth 1 \
        "$FLUTTER_DIR"

    sudo chown -R \
        "$TARGET_USER:$TARGET_USER" \
        "$FLUTTER_DIR"

    sudo git config --system \
        --add safe.directory "$FLUTTER_DIR" \
        2>/dev/null || true

else

    CURRENT_OWNER="$(
        stat -c '%U:%G' "$FLUTTER_DIR" 2>/dev/null || true
    )"

    EXPECTED_OWNER="$TARGET_USER:$TARGET_USER"

    if [ "$CURRENT_OWNER" != "$EXPECTED_OWNER" ]; then

        echo "Fixing Flutter ownership..."

        sudo chown -R \
            "$TARGET_USER:$TARGET_USER" \
            "$FLUTTER_DIR"
    fi
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

sudo ln -sf \
    "$FLUTTER_DIR/bin/flutter" \
    /usr/local/bin/flutter

add_to_bashrc \
    'export PATH="/opt/flutter/bin:$PATH"'

# ==================================================
# Flutter configuration
# ==================================================

echo ""
echo "==> Configuring Flutter..."

flutter config \
    --android-sdk "$ANDROID_HOME"

flutter config \
    --jdk-dir "$JAVA_HOME"

flutter config \
    --no-analytics

# ==================================================
# Flutter verification
# ==================================================

echo ""
echo "==> Flutter version..."

flutter --version

echo ""
echo "==> Flutter doctor..."

flutter doctor -v || true

# ==================================================
# Project dependencies
# ==================================================

cd "$SCRIPT_DIR"

echo ""
echo "==> Checking project dependencies..."

if [ -f "pubspec.yaml" ]; then
    flutter pub get
else
    echo "No pubspec.yaml found; skipping flutter pub get."
fi

# ==================================================
# Final verification
# ==================================================

echo ""
echo "=========================================="
echo "Universe Codespace Setup Complete"
echo "=========================================="

echo ""
echo "Versions:"
echo "------------------------------------------"

python3.11 --version

echo ""
java -version

echo ""
flutter --version

echo "------------------------------------------"

echo ""
echo "Configuration:"
echo "  JAVA_HOME:       $JAVA_HOME"
echo "  ANDROID_HOME:    $ANDROID_HOME"
echo "  Flutter:         $FLUTTER_DIR"
echo "  Chaquopy:        $CHAQUOPY_DIR"
echo "  Chaquopy Python: $CHAQUOPY_DIR/bin/python"
echo "  NDK:             $NDK_VERSION"

# ==================================================
# Android-only verification
# ==================================================

echo ""
echo "Android toolchain:"
echo "------------------------------------------"

DOCTOR_OUTPUT="$(flutter doctor -v 2>&1 || true)"

if printf '%s\n' "$DOCTOR_OUTPUT" |
    grep -qE '^\[✓\] Android toolchain'; then

    echo "[✓] Android toolchain ready"

else

    echo "[!] Android toolchain needs attention"
    echo ""
    echo "Run:"
    echo "  flutter doctor -v"

fi

echo ""
echo "=========================================="
echo "Setup finished."
echo "=========================================="

echo ""
echo "You can now run:"
echo "  flutter analyze"
echo "  flutter build apk --debug"
echo "  flutter build apk --release"
echo ""