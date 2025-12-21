#!/usr/bin/env bats
# TDD: Issue 번호 추출 로직 테스트

# 테스트 대상 함수 로드
load helpers/extract_issue

# Test Case 1: PR 제목에서 Issue 번호 추출
@test "PR 제목 'feat: add login #123'에서 123 추출" {
  result=$(extract_issue_number "feat: add login #123" "")
  [ "$result" = "123" ]
}

# Test Case 2: 브랜치명에서 Issue 번호 추출
@test "브랜치명 'feat/456-login'에서 456 추출" {
  result=$(extract_issue_number "fix: bug" "feat/456-login")
  [ "$result" = "456" ]
}

# Test Case 3: Issue 번호 없음
@test "PR 제목과 브랜치명에 Issue 번호 없을 때 빈 문자열" {
  result=$(extract_issue_number "docs: update" "main")
  [ "$result" = "" ]
}

# Test Case 4: 여러 Issue 번호 중 첫 번째만 추출
@test "PR 제목 '#12 #34 multiple'에서 12만 추출" {
  result=$(extract_issue_number "#12 #34 multiple" "")
  [ "$result" = "12" ]
}

# Edge Case 5: PR 제목 우선순위
@test "PR 제목과 브랜치명 모두 Issue 번호가 있을 때 PR 제목 우선" {
  result=$(extract_issue_number "feat: login #999" "feat/456-login")
  [ "$result" = "999" ]
}

# Edge Case 6: # 기호 없이 숫자만 있는 경우
@test "브랜치명 'feature/789-test'에서 789 추출" {
  result=$(extract_issue_number "" "feature/789-test")
  [ "$result" = "789" ]
}

# Edge Case 7: 브랜치명에 여러 숫자
@test "브랜치명 'feat/100-issue-200'에서 100 추출 (첫 번째)" {
  result=$(extract_issue_number "" "feat/100-issue-200")
  [ "$result" = "100" ]
}
