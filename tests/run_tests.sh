#!/bin/bash
# Manual test runner for extract_issue logic
# bats 없이 직접 테스트 실행

source tests/helpers/extract_issue.sh

# Test counter
PASSED=0
FAILED=0

# Helper function
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    ((PASSED++))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    ((FAILED++))
  fi
}

echo "=========================================="
echo "Issue Number Extraction Tests"
echo "=========================================="

# Test Case 1: PR 제목에서 Issue 번호 추출
result=$(extract_issue_number "feat: add login #123" "")
assert_equals "123" "$result" "PR 제목 'feat: add login #123'에서 123 추출"

# Test Case 2: 브랜치명에서 Issue 번호 추출
result=$(extract_issue_number "fix: bug" "feat/456-login")
assert_equals "456" "$result" "브랜치명 'feat/456-login'에서 456 추출"

# Test Case 3: Issue 번호 없음
result=$(extract_issue_number "docs: update" "main")
assert_equals "" "$result" "PR 제목과 브랜치명에 Issue 번호 없을 때 빈 문자열"

# Test Case 4: 여러 Issue 번호 중 첫 번째만 추출
result=$(extract_issue_number "#12 #34 multiple" "")
assert_equals "12" "$result" "PR 제목 '#12 #34 multiple'에서 12만 추출"

# Edge Case 5: PR 제목 우선순위
result=$(extract_issue_number "feat: login #999" "feat/456-login")
assert_equals "999" "$result" "PR 제목과 브랜치명 모두 Issue 번호가 있을 때 PR 제목 우선"

# Edge Case 6: # 기호 없이 숫자만 있는 경우
result=$(extract_issue_number "" "feature/789-test")
assert_equals "789" "$result" "브랜치명 'feature/789-test'에서 789 추출"

# Edge Case 7: 브랜치명에 여러 숫자
result=$(extract_issue_number "" "feat/100-issue-200")
assert_equals "100" "$result" "브랜치명 'feat/100-issue-200'에서 100 추출 (첫 번째)"

echo "=========================================="
echo "Results: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi
