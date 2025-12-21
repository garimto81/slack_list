#!/bin/bash
# Issue 번호 추출 함수
# PR 제목 또는 브랜치명에서 #123 형식의 Issue 번호 추출

extract_issue_number() {
  local PR_TITLE="$1"
  local BRANCH_NAME="$2"

  # PR 제목에서 먼저 시도
  ISSUE_NUM=$(echo "$PR_TITLE" | grep -oE '#[0-9]+' | head -1 | tr -d '#')

  # 없으면 브랜치명에서 시도
  if [ -z "$ISSUE_NUM" ]; then
    ISSUE_NUM=$(echo "$BRANCH_NAME" | grep -oE '[0-9]+' | head -1)
  fi

  echo "$ISSUE_NUM"
}
