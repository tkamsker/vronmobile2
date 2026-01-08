#!/bin/bash
# Setup GitHub Secrets from local .env files
# Requires: GitHub CLI (gh) installed and authenticated
# Usage: ./scripts/setup-github-secrets.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔐 GitHub Secrets Setup Script"
echo "================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}"
    echo ""
    echo "Install instructions:"
    echo "  macOS:   brew install gh"
    echo "  Linux:   See https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo "  Windows: See https://github.com/cli/cli#windows"
    echo ""
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Error: Not authenticated with GitHub CLI${NC}"
    echo ""
    echo "Please authenticate first:"
    echo "  gh auth login"
    echo ""
    exit 1
fi

# Check if .env.stage exists
if [ ! -f ".env.stage" ]; then
    echo -e "${RED}❌ Error: .env.stage not found${NC}"
    echo ""
    echo "Please create .env.stage with your stage environment values:"
    echo "  cp .env.example .env.stage"
    echo "  # Edit .env.stage with actual values"
    echo ""
    exit 1
fi

# Check if .env.main exists
if [ ! -f ".env.main" ]; then
    echo -e "${RED}❌ Error: .env.main not found${NC}"
    echo ""
    echo "Please create .env.main with your production environment values:"
    echo "  cp .env.example .env.main"
    echo "  # Edit .env.main with actual values"
    echo ""
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo -e "${RED}❌ Error: Not in a GitHub repository or unable to detect repository${NC}"
    exit 1
fi

echo -e "Repository: ${GREEN}$REPO${NC}"
echo ""

# Function to extract value from .env file
get_env_value() {
    local file=$1
    local key=$2
    grep "^${key}=" "$file" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2

    if [ -z "$secret_value" ]; then
        echo -e "${YELLOW}⚠️  Skipping $secret_name (empty value)${NC}"
        return
    fi

    echo "Setting $secret_name..."
    echo "$secret_value" | gh secret set "$secret_name" --repo="$REPO"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $secret_name set successfully${NC}"
    else
        echo -e "${RED}✗ Failed to set $secret_name${NC}"
    fi
}

echo "📋 Reading values from .env.stage and .env.main..."
echo ""

# Extract values from .env files
VRON_API_URI_STAGE=$(get_env_value ".env.stage" "VRON_API_URI")
VRON_MERCHANTS_URL_STAGE=$(get_env_value ".env.stage" "VRON_MERCHANTS_URL")
BLENDER_API_BASE_URL_STAGE=$(get_env_value ".env.stage" "BLENDER_API_BASE_URL")
BLENDER_API_KEY_STAGE=$(get_env_value ".env.stage" "BLENDER_API_KEY")

VRON_API_URI_MAIN=$(get_env_value ".env.main" "VRON_API_URI")
VRON_MERCHANTS_URL_MAIN=$(get_env_value ".env.main" "VRON_MERCHANTS_URL")
BLENDER_API_BASE_URL_MAIN=$(get_env_value ".env.main" "BLENDER_API_BASE_URL")
BLENDER_API_KEY_MAIN=$(get_env_value ".env.main" "BLENDER_API_KEY")

APP_COOKIE_DOMAIN=$(get_env_value ".env.stage" "APP_COOKIE_DOMAIN")

# Display what will be set (masking sensitive values)
echo "Stage Secrets:"
echo "  VRON_API_URI_STAGE: $VRON_API_URI_STAGE"
echo "  VRON_MERCHANTS_URL_STAGE: $VRON_MERCHANTS_URL_STAGE"
echo "  BLENDER_API_BASE_URL_STAGE: $BLENDER_API_BASE_URL_STAGE"
echo "  BLENDER_API_KEY_STAGE: ${BLENDER_API_KEY_STAGE:0:8}***"
echo ""
echo "Main Secrets:"
echo "  VRON_API_URI_MAIN: $VRON_API_URI_MAIN"
echo "  VRON_MERCHANTS_URL_MAIN: $VRON_MERCHANTS_URL_MAIN"
echo "  BLENDER_API_BASE_URL_MAIN: $BLENDER_API_BASE_URL_MAIN"
echo "  BLENDER_API_KEY_MAIN: ${BLENDER_API_KEY_MAIN:0:8}***"
echo ""
echo "Shared Secrets:"
echo "  APP_COOKIE_DOMAIN: $APP_COOKIE_DOMAIN"
echo ""

# Confirmation
read -p "Do you want to set these secrets in $REPO? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🚀 Setting GitHub Secrets..."
echo ""

# Set Stage secrets
echo "📦 Stage Branch Secrets:"
set_secret "VRON_API_URI_STAGE" "$VRON_API_URI_STAGE"
set_secret "VRON_MERCHANTS_URL_STAGE" "$VRON_MERCHANTS_URL_STAGE"
set_secret "BLENDER_API_BASE_URL_STAGE" "$BLENDER_API_BASE_URL_STAGE"
set_secret "BLENDER_API_KEY_STAGE" "$BLENDER_API_KEY_STAGE"
echo ""

# Set Main secrets
echo "📦 Main Branch Secrets:"
set_secret "VRON_API_URI_MAIN" "$VRON_API_URI_MAIN"
set_secret "VRON_MERCHANTS_URL_MAIN" "$VRON_MERCHANTS_URL_MAIN"
set_secret "BLENDER_API_BASE_URL_MAIN" "$BLENDER_API_BASE_URL_MAIN"
set_secret "BLENDER_API_KEY_MAIN" "$BLENDER_API_KEY_MAIN"
echo ""

# Set Shared secrets
echo "📦 Shared Secrets:"
set_secret "APP_COOKIE_DOMAIN" "$APP_COOKIE_DOMAIN"
echo ""

echo -e "${GREEN}✅ GitHub Secrets setup complete!${NC}"
echo ""
echo "You can verify secrets were set correctly:"
echo "  gh secret list --repo=$REPO"
echo ""
echo "Or view in GitHub:"
echo "  https://github.com/$REPO/settings/secrets/actions"
