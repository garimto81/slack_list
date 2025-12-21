#!/usr/bin/env bats
# Slack API Integration Tests (TDD)
# Tests for GitHub Actions workflow slack-list-sync.yml

# Setup and teardown
setup() {
    # Add jq to PATH if it exists in tests directory
    if [[ -f "$(dirname "$BATS_TEST_FILENAME")/jq.exe" ]]; then
        export PATH="$(dirname "$BATS_TEST_FILENAME"):$PATH"
    fi

    # Load test helpers
    source "$(dirname "$BATS_TEST_FILENAME")/helpers/mock_slack.sh"

    # Set test environment variables
    export SLACK_BOT_TOKEN="xoxb-test-token-12345"
    export SLACK_LIST_ID="F987654321"
    export TEST_ISSUE_NUM="101"
    export TEST_PR_TITLE="feat(auth): add social login"

    # Create temporary directory for test outputs
    export TEMP_DIR="$(mktemp -d)"
}

teardown() {
    # Clean up temporary files
    [[ -n "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

# Test Case 1: slackLists.items.list - Success Response Parsing
@test "TC-1: Parse successful items.list response" {
    # Arrange
    local response=$(mock_items_list_success)

    # Act
    local ok=$(echo "$response" | jq -r '.ok')
    local item_count=$(echo "$response" | jq -r '.items | length')
    local first_item_id=$(echo "$response" | jq -r '.items[0].id')

    # Assert
    [[ "$ok" == "true" ]]
    [[ "$item_count" == "2" ]]
    [[ "$first_item_id" == "I123456789" ]]
}

# Test Case 2: Item ID Extraction - jq Query Validation
@test "TC-2: Extract item ID by issue number using jq" {
    # Arrange
    local response=$(mock_items_list_success)
    local issue_num="101"

    # Act - Using the exact jq query from workflow
    local item_id=$(echo "$response" | jq -r ".items[] | select(.fields[] | select(.text[]?.text? | contains(\"#$issue_num\"))) | .id" | head -1)

    # Assert
    [[ "$item_id" == "I123456789" ]]
    [[ -n "$item_id" ]]
}

# Test Case 3: Item ID Extraction - No Match Found
@test "TC-3: Return empty when issue number not found" {
    # Arrange
    local response=$(mock_items_list_success)
    local issue_num="999"

    # Act
    local item_id=$(echo "$response" | jq -r ".items[] | select(.fields[] | select(.text[]?.text? | contains(\"#$issue_num\"))) | .id" | head -1)

    # Assert
    [[ -z "$item_id" ]]
}

# Test Case 4: Item ID Extraction - Multiple Matches (Edge Case)
@test "TC-4: Return first match when multiple items found" {
    # Arrange - Create response with duplicate issue numbers
    local response=$(cat <<'EOF'
{
  "ok": true,
  "items": [
    {
      "id": "I111111111",
      "fields": [{"column_id": "issue_number", "text": [{"text": "#101"}]}]
    },
    {
      "id": "I222222222",
      "fields": [{"column_id": "issue_number", "text": [{"text": "#101"}]}]
    }
  ]
}
EOF
)
    local issue_num="101"

    # Act
    local item_id=$(echo "$response" | jq -r ".items[] | select(.fields[] | select(.text[]?.text? | contains(\"#$issue_num\"))) | .id" | head -1)

    # Assert - Should return first match only
    [[ "$item_id" == "I111111111" ]]
}

# Test Case 5: slackLists.items.update - Request Body Validation
@test "TC-5: Validate items.update request body structure" {
    # Arrange
    local list_id="F987654321"
    local item_id="I123456789"
    local pr_title="feat(auth): add social login"

    # Act - Construct request body (matching workflow format)
    local request_body=$(cat <<EOF
{
  "list_id": "$list_id",
  "item_id": "$item_id",
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
            "text": "$pr_title"
          }]
        }]
      }]
    }
  ]
}
EOF
)

    # Assert - Validate JSON structure
    local parsed_list_id=$(echo "$request_body" | jq -r '.list_id')
    local parsed_item_id=$(echo "$request_body" | jq -r '.item_id')
    local parsed_progress=$(echo "$request_body" | jq -r '.fields[0].number[0]')
    local parsed_remarks=$(echo "$request_body" | jq -r '.fields[1].rich_text[0].elements[0].elements[0].text')

    [[ "$parsed_list_id" == "$list_id" ]]
    [[ "$parsed_item_id" == "$item_id" ]]
    [[ "$parsed_progress" == "100" ]]
    [[ "$parsed_remarks" == "$pr_title" ]]
}

# Test Case 6: slackLists.items.update - Progress Field Validation
@test "TC-6: Verify progress field is set to 100" {
    # Arrange
    local response=$(mock_items_update_success)

    # Act
    local progress=$(echo "$response" | jq -r '.item.fields[] | select(.column_id == "progress") | .number[0]')

    # Assert
    [[ "$progress" == "100" ]]
}

# Test Case 7: slackLists.items.update - Remarks Field Validation
@test "TC-7: Verify remarks field contains PR title" {
    # Arrange
    local response=$(mock_items_update_success)

    # Act
    local remarks=$(echo "$response" | jq -r '.item.fields[] | select(.column_id == "remarks") | .rich_text[0].elements[0].elements[0].text')

    # Assert
    [[ "$remarks" == "feat(auth): add social login" ]]
}

# Test Case 8: API Error Handling - Invalid Auth
@test "TC-8: Handle invalid_auth error gracefully" {
    # Arrange
    local response=$(mock_api_error)

    # Act
    local ok=$(echo "$response" | jq -r '.ok')
    local error=$(echo "$response" | jq -r '.error')

    # Assert
    [[ "$ok" == "false" ]]
    [[ "$error" == "invalid_auth" ]]
}

# Test Case 9: API Error Handling - Check Response Status
@test "TC-9: Verify error response contains ok=false" {
    # Arrange
    local response=$(mock_api_error)

    # Act
    local ok=$(echo "$response" | jq -r '.ok')

    # Assert
    [[ "$ok" == "false" ]]
    [[ "$ok" != "true" ]]
}

# Test Case 10: Special Characters in PR Title
@test "TC-10: Handle special characters in PR title" {
    # Arrange
    local pr_title='fix: resolve "checkout" error (critical)'
    local escaped_title=$(echo "$pr_title" | sed 's/"/\\"/g')

    # Act - Construct request body with escaped special characters
    local request_body=$(cat <<EOF
{
  "list_id": "F987654321",
  "item_id": "I123456789",
  "fields": [{
    "column_id": "remarks",
    "rich_text": [{
      "type": "rich_text",
      "elements": [{
        "type": "rich_text_section",
        "elements": [{
          "type": "text",
          "text": "$escaped_title"
        }]
      }]
    }]
  }]
}
EOF
)

    # Assert - Verify JSON is valid
    local is_valid=$(echo "$request_body" | jq -e '.' >/dev/null 2>&1 && echo "valid" || echo "invalid")
    [[ "$is_valid" == "valid" ]]
}

# Test Case 11: Empty Response Handling
@test "TC-11: Handle empty items array" {
    # Arrange
    local response='{"ok": true, "items": []}'
    local issue_num="101"

    # Act
    local item_id=$(echo "$response" | jq -r ".items[] | select(.fields[] | select(.text[]?.text? | contains(\"#$issue_num\"))) | .id" | head -1)

    # Assert
    [[ -z "$item_id" ]]
}

# Test Case 12: Issue Number Extraction from PR Title
@test "TC-12: Extract issue number from PR title using grep" {
    # Arrange
    local pr_title="feat: add social login #101"

    # Act - Using workflow's grep command
    local issue_num=$(echo "$pr_title" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

    # Assert
    [[ "$issue_num" == "101" ]]
}

# Test Case 13: Issue Number Extraction - Multiple Issues in Title
@test "TC-13: Extract first issue number when multiple exist" {
    # Arrange
    local pr_title="feat: fix #101 and close #102"

    # Act
    local issue_num=$(echo "$pr_title" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

    # Assert - Should return first match
    [[ "$issue_num" == "101" ]]
}

# Test Case 14: Issue Number Extraction - No Issue in Title
@test "TC-14: Return empty when no issue number in title" {
    # Arrange
    local pr_title="feat: add social login"

    # Act
    local issue_num=$(echo "$pr_title" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

    # Assert
    [[ -z "$issue_num" ]]
}

# Test Case 15: Integration Test - Full Workflow Simulation
@test "TC-15: Simulate full workflow end-to-end" {
    # Arrange
    local pr_title="feat: add social login #101"
    local list_id="F987654321"

    # Act - Step 1: Extract issue number
    local issue_num=$(echo "$pr_title" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

    # Act - Step 2: Get list items
    local list_response=$(mock_items_list_success)

    # Act - Step 3: Find item ID
    local item_id=$(echo "$list_response" | jq -r ".items[] | select(.fields[] | select(.text[]?.text? | contains(\"#$issue_num\"))) | .id" | head -1)

    # Act - Step 4: Construct update request
    local update_request=$(cat <<EOF
{
  "list_id": "$list_id",
  "item_id": "$item_id",
  "fields": [{
    "column_id": "progress",
    "number": [100]
  }]
}
EOF
)

    # Assert - Verify all steps succeeded
    [[ "$issue_num" == "101" ]]
    [[ "$item_id" == "I123456789" ]]
    [[ -n "$update_request" ]]

    # Assert - Verify update request is valid JSON
    local is_valid=$(echo "$update_request" | jq -e '.' >/dev/null 2>&1 && echo "valid" || echo "invalid")
    [[ "$is_valid" == "valid" ]]
}
