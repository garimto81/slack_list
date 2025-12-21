# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

PR 머지 시 Slack List를 자동으로 업데이트하는 GitHub Actions 워크플로우

## 아키텍처

```
PR Merge → GitHub Actions → Slack Lists API → List 업데이트
           (Issue 파싱)    (items.update)    (진행률 100%)
```

**워크플로우 단계**:
1. `pull_request.closed` + `merged == true` 트리거
2. PR 제목에서 `#123` 패턴으로 Issue 번호 추출 (없으면 브랜치명에서)
3. `slackLists.items.list`로 List 항목 검색
4. `slackLists.items.update`로 진행률 100% + 비고 업데이트
5. 매칭 실패 시 Webhook으로 알림 발송

## 핵심 파일

| 파일 | 용도 |
|------|------|
| `.github/workflows/slack-list-sync.yml` | 메인 워크플로우 |
| `tests/run_tests.sh` | 단위 테스트 실행 |
| `tests/helpers/extract_issue.sh` | Issue 번호 추출 로직 |

## 빌드/테스트 명령

```bash
# 단위 테스트 실행 (Git Bash 또는 WSL)
bash tests/run_tests.sh

# Slack List 조회 테스트
curl -X POST "https://slack.com/api/slackLists.items.list" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"list_id": "YOUR_LIST_ID"}'
```

## 필수 Secrets

| Secret | 설명 |
|--------|------|
| `SLACK_USER_TOKEN` | User 토큰 (`xoxp-...`) - Bot 토큰은 List 접근 불가 |
| `SLACK_LIST_ID` | List ID (`F...`) |
| `SLACK_WEBHOOK_URL` | 실패 알림용 Webhook |

## Column ID (하드코딩됨)

| Column | ID | 용도 |
|--------|-----|------|
| 진행률 | `Col0A55RYJHEV` | number 필드 (0-100) |
| 비고 | `Col0A4WG5SFD2` | rich_text 필드 |

⚠️ 새 List 사용 시 Column ID 변경 필요 (API 응답에서 확인)

## PR 제목 규칙

```
feat: add social login #123
```

Issue 번호는 PR 제목 또는 브랜치명(`feat/123-login`)에서 자동 추출

## 참조

| 문서 | 내용 |
|------|------|
| `README.md` | 설정 가이드, 문제 해결 |
| `docs/PRD-0001-GITHUB-SLACK-SYNC.md` | 상세 요구사항 |
