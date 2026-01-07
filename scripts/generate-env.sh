#!/bin/bash
# Generate .env file for CI/CD from environment variables or GitHub Secrets
# This script creates the .env file needed by flutter build

set -e

echo "Generating .env file for build..."

# Determine environment based on branch or ENV var
BRANCH="${GITHUB_REF_NAME:-stage}"
if [ "$BRANCH" = "main" ]; then
  ENV_TYPE="production"
else
  ENV_TYPE="staging"
fi

# Create .env file with environment-specific values
cat > .env <<EOF
# VRon Backend API (base URL without /graphql)
VRON_API_URI=${VRON_API_URI}

# VRon Merchants Web App
VRON_MERCHANTS_URL=${VRON_MERCHANTS_URL}

# Cookie domain for web-based authentication
APP_COOKIE_DOMAIN=${APP_COOKIE_DOMAIN}

# Environment Configuration
ENV=${ENV:-$ENV_TYPE}

# Debug mode flag (enables verbose logging)
DEBUG=${DEBUG:-false}

# BlenderAPI Configuration (for USDZ to GLB conversion and NavMesh generation)
BLENDER_API_BASE_URL=${BLENDER_API_BASE_URL}
BLENDER_API_KEY=${BLENDER_API_KEY}
BLENDER_API_TIMEOUT_SECONDS=${BLENDER_API_TIMEOUT_SECONDS:-900}
BLENDER_API_POLL_INTERVAL_SECONDS=${BLENDER_API_POLL_INTERVAL_SECONDS:-2}

# Room Stitching Canvas Configuration
ROOM_ROTATION_DEGREES=${ROOM_ROTATION_DEGREES:-45}
DOOR_CONNECTION_THRESHOLD=${DOOR_CONNECTION_THRESHOLD:-50}
CANVAS_GRID_SIZE=${CANVAS_GRID_SIZE:-20}
EOF

echo ".env file generated successfully for $ENV_TYPE environment"
echo "Environment variables used:"
echo "  VRON_API_URI: ${VRON_API_URI}"
echo "  VRON_MERCHANTS_URL: ${VRON_MERCHANTS_URL}"
echo "  BLENDER_API_BASE_URL: ${BLENDER_API_BASE_URL}"
