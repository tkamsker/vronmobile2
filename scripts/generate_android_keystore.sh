#!/bin/bash

# Interactive script to generate Android keystore for release builds
# See docs/ANDROID_KEYSTORE_SETUP.md for detailed instructions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Android Keystore Generation Script                ║${NC}"
echo -e "${BLUE}║     VRon Mobile                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if keystore already exists
KEYSTORE_PATH="android/app/upload-keystore.jks"
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}⚠️  WARNING: Keystore already exists at $KEYSTORE_PATH${NC}"
    echo ""
    read -p "Do you want to overwrite it? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}Aborted. Existing keystore preserved.${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Removing existing keystore...${NC}"
    rm -f "$KEYSTORE_PATH"
    rm -f "$KEYSTORE_PATH.base64"
fi

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}✗ Error: keytool not found${NC}"
    echo ""
    echo "keytool is part of the Java JDK. Please install it:"
    echo "  macOS:   brew install openjdk"
    echo "  Linux:   apt-get install default-jdk"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ keytool found${NC}"
echo ""

# Collect information
echo -e "${YELLOW}Enter keystore information:${NC}"
echo ""

read -p "Organization Name [VRon]: " ORG_NAME
ORG_NAME=${ORG_NAME:-VRon}

read -p "Organizational Unit [Mobile Development]: " ORG_UNIT
ORG_UNIT=${ORG_UNIT:-Mobile Development}

read -p "City/Locality: " CITY
CITY=${CITY:-Vienna}

read -p "State/Province: " STATE
STATE=${STATE:-Vienna}

read -p "Country Code (2 letters) [AT]: " COUNTRY
COUNTRY=${COUNTRY:-AT}

echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Organization:   $ORG_NAME"
echo "  Unit:           $ORG_UNIT"
echo "  City:           $CITY"
echo "  State:          $STATE"
echo "  Country:        $COUNTRY"
echo ""

read -p "Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Aborted.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Generating keystore...${NC}"
echo ""
echo -e "${YELLOW}You will be prompted for:${NC}"
echo "  1. Keystore password (CREATE A STRONG PASSWORD)"
echo "  2. Key password (press ENTER to use same as keystore)"
echo ""

# Generate keystore
keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=$ORG_NAME Mobile Team, OU=$ORG_UNIT, O=$ORG_NAME, L=$CITY, ST=$STATE, C=$COUNTRY"

echo ""
echo -e "${GREEN}✓ Keystore generated successfully${NC}"
echo ""

# Base64 encode
echo -e "${BLUE}Encoding keystore for CI/CD...${NC}"
base64 -i "$KEYSTORE_PATH" > "$KEYSTORE_PATH.base64"
echo -e "${GREEN}✓ Base64 encoded: $KEYSTORE_PATH.base64${NC}"
echo ""

# Verify
echo -e "${BLUE}Verifying keystore...${NC}"
keytool -list -v -keystore "$KEYSTORE_PATH" -alias upload | head -20
echo ""

# Display next steps
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✓ Keystore Generation Complete                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}CRITICAL: Store these securely in your password manager:${NC}"
echo "  • Keystore file:     $KEYSTORE_PATH"
echo "  • Keystore password: [THE PASSWORD YOU JUST ENTERED]"
echo "  • Key alias:         upload"
echo "  • Key password:      [SAME AS KEYSTORE OR YOUR CUSTOM PASSWORD]"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "1. ${BLUE}Create key.properties file:${NC}"
echo "   cp android/key.properties.example android/key.properties"
echo "   # Then edit android/key.properties with your passwords"
echo ""
echo -e "2. ${BLUE}For CI/CD, copy the base64 encoded keystore:${NC}"
echo "   cat $KEYSTORE_PATH.base64"
echo "   # Add this as ANDROID_KEYSTORE_BASE64 secret in your CI/CD"
echo ""
echo -e "3. ${BLUE}Test release build:${NC}"
echo "   flutter build apk --release"
echo ""
echo -e "4. ${BLUE}Backup keystore securely:${NC}"
echo "   # Upload to password manager or encrypted storage"
echo ""
echo -e "${RED}⚠️  WARNING: Loss of this keystore means you CANNOT update your app!${NC}"
echo ""
echo -e "For detailed instructions, see: ${BLUE}docs/ANDROID_KEYSTORE_SETUP.md${NC}"
echo ""
