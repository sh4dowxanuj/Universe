#!/usr/bin/env bash
set -euo pipefail
PW=$(tr -dc "A-Za-z0-9" </dev/urandom | head -c 20)
ALIAS=release_key
KS_PATH="$(pwd)/release-keystore.jks"

keytool -genkeypair -v -noprompt \
  -keystore "$KS_PATH" \
  -storetype JKS \
  -storepass "$PW" \
  -keypass "$PW" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Release, OU=Dev, O=Company, L=City, S=State, C=US"

cat > key.properties <<EOF
storePassword=$PW
keyPassword=$PW
keyAlias=$ALIAS
storeFile=$KS_PATH
EOF

ls -l "$KS_PATH" key.properties

echo
echo "Keystore created at: $KS_PATH"
echo "Generated keystore password: $PW"
