#!/bin/bash

# Investigate Session - Get all information about a session
# Usage: ./investigate_session.sh <session_id>

set -e

NAMESPACE="vron-stage"
API_URL="https://blenderapi.stage.motorenflug.at"
API_KEY="${BLENDERAPI_KEY:-dev-test-key-1234567890}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if session ID is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Session ID not provided${NC}"
    echo ""
    echo "Usage: ./investigate_session.sh <session_id>"
    echo ""
    echo "Example:"
    echo "  ./investigate_session.sh sess_SLuZEI3FpOk6R-a3u0DfBA"
    echo ""
    exit 1
fi

SESSION_ID=$1

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Session Investigation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Session ID: $SESSION_ID"
echo "Namespace: $NAMESPACE"
echo "API URL: $API_URL"
echo ""

# Step 1: Check API Status
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}1. Checking Session Status via API${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

STATUS_RESPONSE=$(curl -s -X GET "$API_URL/sessions/$SESSION_ID/status" \
    -H "X-API-Key: $API_KEY" \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$STATUS_RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
STATUS_BODY=$(echo "$STATUS_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Session found via API${NC}"
    echo ""
    echo "$STATUS_BODY" | python3 -m json.tool 2>/dev/null || echo "$STATUS_BODY"
else
    echo -e "${RED}✗ Session not found via API (HTTP $HTTP_CODE)${NC}"
    echo "Response: $STATUS_BODY"
fi
echo ""

# Step 2: Find Pod
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}2. Finding BlenderAPI Pod${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

POD=$(kubectl get pods -n $NAMESPACE -l app=blenderapi-stage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
    echo -e "${RED}✗ No blenderapi pod found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pod found: $POD${NC}"
echo ""

# Step 3: Check Session Directory
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}3. Checking Session Directory${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

SESSION_DIR="/data/sessions/$SESSION_ID"

# Check if directory exists
if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -d "$SESSION_DIR" 2>/dev/null; then
    echo -e "${GREEN}✓ Session directory exists: $SESSION_DIR${NC}"
    echo ""
    
    # List directory contents
    echo "Directory contents:"
    kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- ls -lah "$SESSION_DIR" 2>/dev/null || echo "Could not list directory"
    echo ""
    
    # Check subdirectories
    echo "Checking subdirectories:"
    for subdir in input output logs; do
        SUBDIR_PATH="$SESSION_DIR/$subdir"
        if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -d "$SUBDIR_PATH" 2>/dev/null; then
            echo -e "  ${GREEN}✓ $subdir/${NC}"
            FILE_COUNT=$(kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- \
                find "$SUBDIR_PATH" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "    Files: $FILE_COUNT"
            if [ "$FILE_COUNT" -gt 0 ]; then
                echo "    Contents:"
                kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- \
                    ls -lh "$SUBDIR_PATH" 2>/dev/null | tail -n +2 | awk '{print "      " $9 " (" $5 ")"}'
            fi
        else
            echo -e "  ${RED}✗ $subdir/ (not found)${NC}"
        fi
    done
else
    echo -e "${RED}✗ Session directory does not exist${NC}"
    echo "  Path: $SESSION_DIR"
    echo ""
    echo "This could mean:"
    echo "  - Session expired and was cleaned up"
    echo "  - Session was manually deleted"
    echo "  - Session never completed creation"
fi
echo ""

# Step 4: Check Session Files
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}4. Checking Session Files${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check status.json
STATUS_FILE="$SESSION_DIR/status.json"
if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -f "$STATUS_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ status.json exists${NC}"
    echo "Content:"
    kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- cat "$STATUS_FILE" 2>/dev/null | python3 -m json.tool 2>/dev/null || \
        kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- cat "$STATUS_FILE" 2>/dev/null
    echo ""
else
    echo -e "${RED}✗ status.json not found${NC}"
fi

# Check meta.json
META_FILE="$SESSION_DIR/output/meta.json"
if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -f "$META_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ meta.json exists${NC}"
    echo "Content:"
    kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- cat "$META_FILE" 2>/dev/null | python3 -m json.tool 2>/dev/null || \
        kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- cat "$META_FILE" 2>/dev/null
    echo ""
else
    echo -e "${YELLOW}○ meta.json not found (may not exist if processing failed)${NC}"
fi

# Check params.json
PARAMS_FILE="$SESSION_DIR/params.json"
if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -f "$PARAMS_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ params.json exists${NC}"
    echo "Content:"
    kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- cat "$PARAMS_FILE" 2>/dev/null | python3 -m json.tool 2>/dev/null || \
        kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- cat "$PARAMS_FILE" 2>/dev/null
    echo ""
else
    echo -e "${YELLOW}○ params.json not found${NC}"
fi
echo ""

# Step 5: Check Logs
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}5. Checking Session Logs${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

LOG_FILE="$SESSION_DIR/logs/blender.log"
if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -f "$LOG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ blender.log exists${NC}"
    echo ""
    echo "Last 20 lines:"
    kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- tail -20 "$LOG_FILE" 2>/dev/null || echo "Could not read log file"
    echo ""
    echo "Full log available at: $LOG_FILE"
else
    echo -e "${YELLOW}○ blender.log not found${NC}"
fi
echo ""

# Step 6: Check Pod Logs
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}6. Checking Pod Logs for Session${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Searching API container logs for session $SESSION_ID..."
kubectl logs -n $NAMESPACE $POD -c blenderapi-api --tail=100 2>/dev/null | \
    grep -i "$SESSION_ID" | tail -10 || echo "No logs found for this session"
echo ""

# Step 7: Check Session Manager State
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}7. Checking All Sessions in Workspace${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "All session directories:"
kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- \
    ls -ld /data/sessions/sess_* 2>/dev/null | awk '{print "  " $9}' | sed 's|/data/sessions/||' || \
    echo "  No sessions found or cannot access directory"
echo ""

# Check if our session is in the list
if kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -d "$SESSION_DIR" 2>/dev/null; then
    echo -e "${GREEN}✓ Session directory still exists in filesystem${NC}"
else
    echo -e "${RED}✗ Session directory not found in filesystem${NC}"
    echo ""
    echo "Possible reasons:"
    echo "  1. Session expired (TTL: 3600s = 1 hour)"
    echo "  2. Cleanup service removed expired session"
    echo "  3. Session was manually deleted"
    echo "  4. Session creation failed"
fi
echo ""

# Step 8: Check API Logs for Session Events
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}8. Session Events in API Logs${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Recent events for this session:"
kubectl logs -n $NAMESPACE $POD -c blenderapi-api --tail=500 2>/dev/null | \
    grep "$SESSION_ID" | tail -20 || echo "No events found"
echo ""

# Step 9: Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Determine session state
if [ "$HTTP_CODE" = "200" ]; then
    SESSION_STATUS=$(echo "$STATUS_BODY" | grep -o '"session_status":"[^"]*' | cut -d'"' -f4)
    echo "API Status: $SESSION_STATUS"
elif kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -d "$SESSION_DIR" 2>/dev/null; then
    echo "API Status: Not accessible (but directory exists)"
else
    echo "API Status: Not found"
    echo "Directory: Not found"
fi

echo ""
echo "Next steps:"
echo ""
if [ "$HTTP_CODE" != "200" ] && ! kubectl exec -n $NAMESPACE $POD -c blenderapi-api -- test -d "$SESSION_DIR" 2>/dev/null; then
    echo "  ⚠ Session appears to have been cleaned up"
    echo ""
    echo "  This is normal if:"
    echo "    - Session expired (1 hour TTL)"
    echo "    - Cleanup service ran"
    echo "    - Conversion completed and session was cleaned up"
    echo ""
    echo "  To investigate further:"
    echo "    - Check pod logs for session lifecycle events"
    echo "    - Check cleanup service logs"
    echo "    - Verify session TTL settings"
else
    echo "  ✓ Session is accessible"
    echo ""
    echo "  To download result:"
    echo "    curl -X GET \"$API_URL/sessions/$SESSION_ID/download/<filename>\" \\"
    echo "      -H \"X-API-Key: $API_KEY\" \\"
    echo "      --output result.glb"
fi
echo ""

