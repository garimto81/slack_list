# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

PR 머지 시 Slack List를 자동으로 업데이트하는 GitHub Actions 워크플로우

## 아키텍처

```
PR Merge → GitHub Actions → Slack Lists API → List 업데이트
           (Checklist 파싱)  (items.create/update)
                ↓
         ┌─────────────────────────────────────┐
         │ 진행률: ████░░░░░░ 60% (3/5)        │
         │ 비고: 🔄 진행중: • 문서 업데이트     │
         └─────────────────────────────────────┘
```

**워크플로우 단계**:
1. `pull_request.closed` + `merged == true` 트리거
2. PR 제목/브랜치명에서 Issue 번호 추출 (`#123` 또는 `feat/123-...`)
3. PR 본문 Checklist 파싱 → 진행률 계산
4. `slackLists.items.list`로 항목 검색 → 없으면 `items.create`로 생성
5. `slackLists.items.update`로 프로그레스 바 + 진행중 항목 업데이트

## 핵심 파일

| 파일 | 용도 |
|------|------|
| `.github/workflows/slack-list-sync.yml` | 메인 워크플로우 (Checklist 파싱, API 호출) |
| `tests/helpers/extract_issue.sh` | Issue 번호 추출 로직 (재사용 가능) |
| `tests/run_tests.sh` | 단위 테스트 (Git Bash/WSL) |
| `tests/run_api_test.ps1` | Slack API 통합 테스트 (PowerShell) |

## 빌드/테스트 명령

```bash
# 단위 테스트 실행 (Git Bash 또는 WSL)
bash tests/run_tests.sh

# Slack API 통합 테스트 (PowerShell, .env.local 필요)
powershell tests/run_api_test.ps1

# List 구조 확인
powershell tests/check_list_structure.ps1
```

## 필수 Secrets

| Secret | 설명 |
|--------|------|
| `SLACK_USER_TOKEN` | User 토큰 (`xoxp-...`) - Bot 토큰은 Lists API 접근 불가 |
| `SLACK_LIST_ID` | List ID (`F...`) |

## Column ID (하드코딩됨)

| Column | ID | 용도 |
|--------|-----|------|
| 진행률 | `Col0A55RYJHEV` | rich_text (프로그레스 바: `████░░░░░░ 60%`) |
| 비고 | `Col0A4WG5SFD2` | rich_text (진행중 항목 목록) |

⚠️ 새 List 사용 시 `tests/check_list_structure.ps1`로 Column ID 확인 후 워크플로우 수정 필요

## PR 본문 Checklist 형식

```markdown
## Checklist
- [x] 기능 구현
- [x] 테스트 작성
- [ ] 문서화
```

→ 진행률: `██████░░░░ 66% (2/3)`, 비고: `🔄 진행중: • 문서화`

## 로컬 테스트 설정

`.env.local` 파일 생성:
```
SLACK_USER_TOKEN=xoxp-...
SLACK_LIST_ID=F...
```

## 참조

| 문서 | 내용 |
|------|------|
| `README.md` | 설정 가이드, 문제 해결 |
| `docs/PRD-0001-GITHUB-SLACK-SYNC.md` | 상세 요구사항 |
