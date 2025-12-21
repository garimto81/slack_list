#!/usr/bin/env bash
# Mock Slack API helper for testing

# Mock curl command for Slack API calls
mock_curl() {
    local url="$1"
    local response_file=""

    # Parse URL to determine which fixture to return
    if [[ "$url" == *"slackLists.items.list"* ]]; then
        response_file="tests/fixtures/slack_responses/items_list.json"
    elif [[ "$url" == *"slackLists.items.update"* ]]; then
        response_file="tests/fixtures/slack_responses/items_update.json"
    elif [[ "$url" == *"error"* ]]; then
        response_file="tests/fixtures/slack_responses/api_error.json"
    else
        echo '{"ok": false, "error": "unknown_endpoint"}'
        return 1
    fi

    # Check if fixture file exists
    if [[ -f "$response_file" ]]; then
        cat "$response_file"
    else
        echo '{"ok": false, "error": "fixture_not_found"}'
        return 1
    fi
}

# Mock successful items.list response
mock_items_list_success() {
    cat "tests/fixtures/slack_responses/items_list.json"
}

# Mock successful items.update response
mock_items_update_success() {
    cat "tests/fixtures/slack_responses/items_update.json"
}

# Mock API error response
mock_api_error() {
    cat "tests/fixtures/slack_responses/api_error.json"
}

# Extract item ID from items.list response
extract_item_id() {
    local response="$1"
    local issue_num="$2"

    echo "$response" | jq -r ".items[] | select(.fields[] | select(.text[]?.text? | contains(\"#$issue_num\"))) | .id" | head -1
}

# Validate items.update request body
validate_update_request() {
    local request_body="$1"
    local expected_list_id="$2"
    local expected_item_id="$3"
    local expected_progress="$4"
    local expected_remarks="$5"

    # Parse JSON
    local list_id=$(echo "$request_body" | jq -r '.list_id')
    local item_id=$(echo "$request_body" | jq -r '.item_id')
    local progress=$(echo "$request_body" | jq -r '.fields[] | select(.column_id == "progress") | .number[0]')
    local remarks=$(echo "$request_body" | jq -r '.fields[] | select(.column_id == "remarks") | .rich_text[0].elements[0].elements[0].text')

    # Validate each field
    [[ "$list_id" == "$expected_list_id" ]] || return 1
    [[ "$item_id" == "$expected_item_id" ]] || return 1
    [[ "$progress" == "$expected_progress" ]] || return 1
    [[ "$remarks" == "$expected_remarks" ]] || return 1

    return 0
}

# Export functions for use in tests
export -f mock_curl
export -f mock_items_list_success
export -f mock_items_update_success
export -f mock_api_error
export -f extract_item_id
export -f validate_update_request
