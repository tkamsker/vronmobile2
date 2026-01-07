#!/bin/bash
# Switch between .env.stage and .env.main for local development
# Usage: ./scripts/switch-env.sh [stage|main]

set -e

ENV="${1:-stage}"

if [ "$ENV" != "stage" ] && [ "$ENV" != "main" ]; then
  echo "Error: Invalid environment. Use 'stage' or 'main'"
  echo "Usage: ./scripts/switch-env.sh [stage|main]"
  exit 1
fi

SOURCE_FILE=".env.$ENV"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: $SOURCE_FILE not found"
  echo ""
  echo "Please create $SOURCE_FILE with the appropriate configuration."
  echo "You can use .env.example as a template:"
  echo "  cp .env.example $SOURCE_FILE"
  echo "  # Then edit $SOURCE_FILE with environment-specific values"
  exit 1
fi

# Backup existing .env if it exists
if [ -f .env ]; then
  echo "Backing up existing .env to .env.backup"
  cp .env .env.backup
fi

# Copy environment-specific file to .env
cp "$SOURCE_FILE" .env

echo "✓ Switched to $ENV environment"
echo "✓ .env now points to $SOURCE_FILE configuration"
echo ""
echo "Environment settings:"
grep "^VRON_API_URI=" .env
grep "^ENV=" .env
grep "^DEBUG=" .env
