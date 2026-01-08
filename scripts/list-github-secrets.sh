#!/bin/bash
# List all GitHub Secrets for the repository
# Requires: GitHub CLI (gh) installed and authenticated
# Usage: ./scripts/list-github-secrets.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔐 GitHub Secrets List"
echo "======================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo ""
    echo "Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    echo ""
    echo "Authenticate with: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo "❌ Error: Not in a GitHub repository"
    exit 1
fi

echo -e "Repository: ${GREEN}$REPO${NC}"
echo ""

# List secrets
echo "Secrets configured in GitHub Actions:"
echo ""
gh secret list --repo="$REPO"

echo ""
echo -e "${YELLOW}Note: Secret values are not displayed for security reasons${NC}"
echo "To update a secret, use: ./scripts/setup-github-secrets.sh"
