#!/bin/bash
#
# Test BlenderAPI Navmesh Generation and download result automatically
#
# This script:
#   1. Runs simple_navmesh_test.py to create session and generate navmesh
#   2. Extracts session ID from test output
#   3. Uses download_result.sh to download the generated navmesh GLB file
#   4. Optionally deletes the session
#
# Usage:
#   ./test_navmesh_and_download.sh [BASE_URL] [API_KEY] [TEST_FILE]
#
# Example:
#   ./test_navmesh_and_download.sh
#   ./test_navmesh_and_download.sh https://blenderapi.stage.motorenflug.at dev-test-key-1234567890 test_assets/test.glb

# Note: Not using 'set -e' to allow better error handling
# set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
DEFAULT_BASE_URL="http://localhost:8000"
DEFAULT_API_KEY="dev-test-key-1234567890"
DEFAULT_TEST_FILE="test_assets/test.glb"

# Use provided arguments or defaults
BASE_URL="${1:-$DEFAULT_BASE_URL}"
API_KEY="${2:-$DEFAULT_API_KEY}"
TEST_FILE="${3:-$DEFAULT_TEST_FILE}"

# Check if test file exists
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}Error: Test file not found: ${TEST_FILE}${NC}"
    exit 1
fi

# Check if download script exists
if [ ! -f "./download_result.sh" ]; then
    echo -e "${RED}Error: download_result.sh not found in current directory${NC}"
    exit 1
fi

# Check if Python test script exists
if [ ! -f "./simple_navmesh_test.py" ]; then
    echo -e "${RED}Error: simple_navmesh_test.py not found in current directory${NC}"
    exit 1
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}BlenderAPI Navmesh Test & Download${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Base URL: ${BASE_URL}"
echo -e "  API Key: ${API_KEY:0:8}..."
echo -e "  Test File: ${TEST_FILE}"
echo ""

# Create temporary file for test output
TEST_OUTPUT=$(mktemp)
trap "rm -f ${TEST_OUTPUT}" EXIT

echo -e "${BLUE}[1/3] Running navmesh generation test...${NC}"
echo ""

# Run Python test and capture output
if python simple_navmesh_test.py "${BASE_URL}" "${API_KEY}" "${TEST_FILE}" 2>&1 | tee "${TEST_OUTPUT}"; then
    TEST_SUCCESS=true
else
    TEST_SUCCESS=false
fi

echo ""

# Check if test succeeded
if [ "$TEST_SUCCESS" = false ]; then
    echo -e "${RED}✗ Python test failed${NC}"
    exit 1
fi

# Extract session ID from test output
# Looking for patterns like: "Session ID: sess_..." from the final output
SESSION_ID=$(grep -E "^Session ID: sess_" "${TEST_OUTPUT}" | tail -1 | awk '{print $3}')

if [ -z "$SESSION_ID" ]; then
    echo -e "${YELLOW}⚠ Could not find 'Session ID:' in output, trying alternative patterns...${NC}"

    # Try pattern: "✓ Session created: sess_..."
    SESSION_ID=$(grep -oE "Session created: (sess_[A-Za-z0-9_-]+)" "${TEST_OUTPUT}" | tail -1 | awk '{print $3}')

    if [ -z "$SESSION_ID" ]; then
        # Last resort: just find any session ID
        SESSION_ID=$(grep -oE "sess_[A-Za-z0-9_-]+" "${TEST_OUTPUT}" | tail -1)

        if [ -z "$SESSION_ID" ]; then
            echo -e "${RED}✗ Failed to extract session ID${NC}"
            echo ""
            echo "Test output excerpt:"
            grep -E "(Session|sess_|✓|FAIL)" "${TEST_OUTPUT}" | tail -30
            exit 1
        fi
    fi
fi

echo -e "${GREEN}✓${NC} Test completed successfully"
echo -e "${YELLOW}Extracted Session ID:${NC} ${SESSION_ID}"
echo ""

# Download the result
echo -e "${BLUE}[2/3] Downloading result...${NC}"
echo -e "${YELLOW}Waiting 2 seconds for session to stabilize...${NC}"
sleep 2
echo ""

# Call download script
DOWNLOAD_SUCCESS=false
DOWNLOAD_OUTPUT=$(mktemp)
if ./download_result.sh "${API_KEY}" "${SESSION_ID}" 2>&1 | tee "${DOWNLOAD_OUTPUT}"; then
    DOWNLOAD_SUCCESS=true
    echo ""

    # Show downloaded files
    DOWNLOADED_FILE=$(ls -t navmesh_*.glb 2>/dev/null | head -1)
    if [ -z "$DOWNLOADED_FILE" ]; then
        # Try any GLB file
        DOWNLOADED_FILE=$(ls -t *.glb 2>/dev/null | head -1)
    fi
    
    if [ -n "$DOWNLOADED_FILE" ]; then
        echo -e "${GREEN}✓${NC} Downloaded file: ${DOWNLOADED_FILE}"

        # Show file info
        FILE_SIZE=$(stat -f%z "${DOWNLOADED_FILE}" 2>/dev/null || stat -c%s "${DOWNLOADED_FILE}" 2>/dev/null)
        FILE_SIZE_KB=$(echo "scale=2; ${FILE_SIZE} / 1024" | bc)
        echo -e "  Size: ${FILE_SIZE_KB} KB"
        echo -e "  Path: $(pwd)/${DOWNLOADED_FILE}"
    fi
else
    echo ""
    echo -e "${RED}✗ Download failed${NC}"
    echo -e "${YELLOW}Download output saved to: ${DOWNLOAD_OUTPUT}${NC}"
    echo -e "${YELLOW}Last 20 lines of output:${NC}"
    tail -20 "${DOWNLOAD_OUTPUT}"
fi

# Cleanup temp file
rm -f "${DOWNLOAD_OUTPUT}"

# Optional: Delete session
echo ""
echo -e "${BLUE}[3/3] Cleaning up session...${NC}"

DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
    -H "X-API-Key: ${API_KEY}" \
    -H "X-Device-ID: 8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab" \
    -H "X-Platform: ios" \
    -H "X-OS-Version: 17.2" \
    -H "X-App-Version: 1.4.2" \
    -H "X-Device-Model: iPad13,8" \
    "${BASE_URL}/sessions/${SESSION_ID}")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -1)

if [ "$HTTP_CODE" = "202" ] || [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "404" ]; then
    if [ "$HTTP_CODE" = "202" ]; then
        echo -e "${GREEN}✓${NC} Session marked for deletion (cleanup within 5 minutes)"
    elif [ "$HTTP_CODE" = "204" ]; then
        echo -e "${GREEN}✓${NC} Session deleted"
    else
        echo -e "${YELLOW}⚠${NC} Session already expired/deleted"
    fi
else
    echo -e "${YELLOW}⚠${NC} Failed to delete session (HTTP ${HTTP_CODE})"
fi

# Final summary
echo ""
echo -e "${CYAN}========================================${NC}"
if [ "$DOWNLOAD_SUCCESS" = true ]; then
    echo -e "${GREEN}✓ All steps completed successfully${NC}"
else
    echo -e "${YELLOW}⚠ Completed with warnings${NC}"
fi
echo -e "${CYAN}========================================${NC}"
echo ""

