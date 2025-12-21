#!/bin/bash
# E2E Workflow Test for GitHub-Slack Sync
# TDD Test Suite using act

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
WORKFLOW_FILE=".github/workflows/slack-list-sync.yml"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Mock Slack API responses
setup_mock_server() {
    # Create a simple mock server for Slack API
    # This would be replaced with a real mock server in production
    export MOCK_SLACK_API=true
    export SLACK_BOT_TOKEN="xoxb-test-token"
    export SLACK_LIST_ID="F123456789"
    export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/test"
}

cleanup_mock_server() {
    unset MOCK_SLACK_API
    unset SLACK_BOT_TOKEN
    unset SLACK_LIST_ID
    unset SLACK_WEBHOOK_URL
}

# Test 1: Verify workflow file exists
test_workflow_exists() {
    print_test "Test 1: Workflow file exists"

    if [ -f "$WORKFLOW_FILE" ]; then
        print_pass "Workflow file found: $WORKFLOW_FILE"
        return 0
    else
        print_fail "Workflow file not found: $WORKFLOW_FILE"
        return 1
    fi
}

# Test 2: Extract issue number from PR title
test_extract_issue_number() {
    print_test "Test 2: Extract issue number from PR title"

    # Simulate the extraction logic
    PR_TITLE="feat: add social login #123"
    ISSUE_NUM=$(echo "$PR_TITLE" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

    if [ "$ISSUE_NUM" = "123" ]; then
        print_pass "Issue number extracted correctly: #$ISSUE_NUM"
        return 0
    else
        print_fail "Failed to extract issue number. Got: $ISSUE_NUM"
        return 1
    fi
}

# Test 3: Extract issue number from branch name
test_extract_from_branch() {
    print_test "Test 3: Extract issue number from branch name"

    # Test with PR title without issue number
    PR_TITLE="feat: add social login"
    BRANCH_NAME="feature/social-login-123"

    # PR 제목에서 먼저 시도
    ISSUE_NUM=$(echo "$PR_TITLE" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

    # 없으면 브랜치명에서 시도
    if [ -z "$ISSUE_NUM" ]; then
        ISSUE_NUM=$(echo "$BRANCH_NAME" | grep -oE '[0-9]+' | head -1)
    fi

    if [ "$ISSUE_NUM" = "123" ]; then
        print_pass "Issue number extracted from branch: #$ISSUE_NUM"
        return 0
    else
        print_fail "Failed to extract from branch. Got: $ISSUE_NUM"
        return 1
    fi
}

# Test 4: Verify Slack API payload structure
test_slack_api_payload() {
    print_test "Test 4: Verify Slack API update payload structure"

    # Simulate payload creation
    ITEM_ID="I123456"
    PR_TITLE="feat: add social login #123"

    PAYLOAD=$(cat <<'EOF'
{
  "list_id": "SLACK_LIST_ID_PLACEHOLDER",
  "item_id": "ITEM_ID_PLACEHOLDER",
  "fields": [
    {
      "column_id": "progress",
      "number": [100]
    },
    {
      "column_id": "remarks",
      "rich_text": [{
        "type": "rich_text",
        "elements": [{
          "type": "rich_text_section",
          "elements": [{
            "type": "text",
            "text": "PR_TITLE_PLACEHOLDER"
          }]
        }]
      }]
    }
  ]
}
EOF
)

    # Replace placeholders
    PAYLOAD="${PAYLOAD//SLACK_LIST_ID_PLACEHOLDER/$SLACK_LIST_ID}"
    PAYLOAD="${PAYLOAD//ITEM_ID_PLACEHOLDER/$ITEM_ID}"
    PAYLOAD="${PAYLOAD//PR_TITLE_PLACEHOLDER/$PR_TITLE}"

    # Validate JSON structure (check if it's valid JSON)
    if python -c "import json, sys; json.loads(sys.stdin.read())" <<< "$PAYLOAD" 2>/dev/null; then
        print_pass "Slack API payload is valid JSON"
        return 0
    else
        print_fail "Slack API payload is invalid JSON"
        return 1
    fi
}

# Test 5: Verify webhook payload for failure notification
test_failure_webhook_payload() {
    print_test "Test 5: Verify failure webhook payload structure"

    PR_TITLE="feat: add social login"
    PR_URL="https://github.com/test/repo/pull/456"
    MESSAGE="PR 제목에서 Issue 번호(#123)를 찾을 수 없습니다"

    PAYLOAD=$(cat <<'EOF'
{
  "text": "GitHub-Slack Sync 실패",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*GitHub-Slack Sync 실패*\nMESSAGE_PLACEHOLDER\n\n*PR:* <PR_URL_PLACEHOLDER|PR_TITLE_PLACEHOLDER>"
      }
    }
  ]
}
EOF
)

    # Replace placeholders
    PAYLOAD="${PAYLOAD//MESSAGE_PLACEHOLDER/$MESSAGE}"
    PAYLOAD="${PAYLOAD//PR_URL_PLACEHOLDER/$PR_URL}"
    PAYLOAD="${PAYLOAD//PR_TITLE_PLACEHOLDER/$PR_TITLE}"

    # Validate JSON structure (check if it's valid JSON)
    if python -c "import json, sys; json.loads(sys.stdin.read())" <<< "$PAYLOAD" 2>/dev/null; then
        print_pass "Webhook payload is valid JSON"
        return 0
    else
        print_fail "Webhook payload is invalid JSON"
        return 1
    fi
}

# Test 6: Verify workflow triggers on PR merge only
test_workflow_trigger() {
    print_test "Test 6: Verify workflow triggers on PR merge only"

    # Check if workflow has correct trigger
    if grep -q "types: \[closed\]" "$WORKFLOW_FILE" && \
       grep -q "github.event.pull_request.merged == true" "$WORKFLOW_FILE"; then
        print_pass "Workflow correctly filters for merged PRs"
        return 0
    else
        print_fail "Workflow trigger configuration incorrect"
        return 1
    fi
}

# Test 7: Verify required secrets are referenced
test_required_secrets() {
    print_test "Test 7: Verify required secrets are referenced"

    REQUIRED_SECRETS=("SLACK_BOT_TOKEN" "SLACK_LIST_ID" "SLACK_WEBHOOK_URL")
    ALL_FOUND=true

    for secret in "${REQUIRED_SECRETS[@]}"; do
        if ! grep -q "$secret" "$WORKFLOW_FILE"; then
            print_fail "Required secret not found: $secret"
            ALL_FOUND=false
        fi
    done

    if [ "$ALL_FOUND" = true ]; then
        print_pass "All required secrets are referenced"
        return 0
    else
        return 1
    fi
}

# Test 8: Verify conditional step execution
test_conditional_steps() {
    print_test "Test 8: Verify conditional step execution"

    # Check if steps have proper conditions
    if grep -q "if: steps.extract.outputs.issue_number != ''" "$WORKFLOW_FILE" && \
       grep -q "if: steps.get_item.outputs.item_id != ''" "$WORKFLOW_FILE"; then
        print_pass "Steps have proper conditional execution"
        return 0
    else
        print_fail "Missing or incorrect conditional execution"
        return 1
    fi
}

# Main test execution
main() {
    echo "================================="
    echo "GitHub-Slack Sync E2E Test Suite"
    echo "================================="
    echo ""

    setup_mock_server

    # Run all tests
    test_workflow_exists || true
    test_extract_issue_number || true
    test_extract_from_branch || true
    test_slack_api_payload || true
    test_failure_webhook_payload || true
    test_workflow_trigger || true
    test_required_secrets || true
    test_conditional_steps || true

    cleanup_mock_server

    # Print summary
    echo ""
    echo "================================="
    echo "Test Summary"
    echo "================================="
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main
