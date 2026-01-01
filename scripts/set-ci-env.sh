#!/usr/bin/env bash
# scripts/set-ci-env.sh
# Usage: source ./scripts/set-ci-env.sh

# --- iOS / App Store Connect ---
export APP_STORE_CONNECT_KEY_ID="XXXXXX"                  # e.g. from Apple Developer portal
export APP_STORE_CONNECT_ISSUER_ID="YYYYYY"               # Issuer ID
export APP_STORE_CONNECT_API_KEY_BASE64="ZZZZZZ"          # p8 file, base64-encoded

# --- fastlane match / signing ---
export MATCH_GIT_URL="git@github.com:your-org/ios-signing.git"
export MATCH_PASSWORD="your-match-password"
export MATCH_GIT_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa_match"

# --- Flutter / build metadata ---
export FLUTTER_VERSION="stable"
export BUILD_NUMBER_OVERRIDE="1"                          # optional override when running locally
export APP_ENV="stage"                                    # dev/stage/prod for dart-define

# --- Android signing (for local builds, in CI use GitHub Secrets) ---
export ANDROID_KEYSTORE_PATH="$HOME/keystores/android.jks"
export ANDROID_KEYSTORE_PASSWORD="keystore-password"
export ANDROID_KEY_ALIAS="upload"
export ANDROID_KEY_ALIAS_PASSWORD="alias-password"

echo "Environment variables for Flutter CI/CD and fastlane have been set in this shell."
