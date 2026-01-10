#!/bin/bash
# Delete all VRon-related GitHub Secrets
# Requires: GitHub CLI (gh) installed and authenticated
# Usage: ./scripts/delete-github-secrets.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🗑️  GitHub Secrets Cleanup Script"
echo "=================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Error: Not authenticated with GitHub CLI${NC}"
    echo "Authenticate with: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo -e "${RED}❌ Error: Not in a GitHub repository${NC}"
    exit 1
fi

echo -e "Repository: ${GREEN}$REPO${NC}"
echo ""

# List of secrets to delete
SECRETS=(
    "VRON_API_URI_STAGE"
    "VRON_MERCHANTS_URL_STAGE"
    "BLENDER_API_BASE_URL_STAGE"
    "BLENDER_API_KEY_STAGE"
    "VRON_API_URI_MAIN"
    "VRON_MERCHANTS_URL_MAIN"
    "BLENDER_API_BASE_URL_MAIN"
    "BLENDER_API_KEY_MAIN"
    "APP_COOKIE_DOMAIN"
)

echo "The following secrets will be deleted:"
for secret in "${SECRETS[@]}"; do
    echo "  - $secret"
done
echo ""

# Confirmation
read -p "Are you sure you want to delete these secrets from $REPO? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🗑️  Deleting secrets..."
echo ""

# Delete each secret
for secret in "${SECRETS[@]}"; do
    echo "Deleting $secret..."
    gh secret delete "$secret" --repo="$REPO" 2>/dev/null && \
        echo -e "${GREEN}✓ $secret deleted${NC}" || \
        echo -e "${YELLOW}⚠️  $secret not found or already deleted${NC}"
done

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
