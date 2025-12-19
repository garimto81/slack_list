# CLAUDE.md - GitHub-Slack Sync

프로젝트별 Claude Code 지침

## 프로젝트 개요

PR 머지 시 Slack List를 자동으로 업데이트하는 GitHub Actions 워크플로우

## 핵심 파일

| 파일 | 용도 |
|------|------|
| `.github/workflows/slack-list-sync.yml` | GitHub Actions 워크플로우 |
| `docs/PRD-0001-GITHUB-SLACK-SYNC.md` | PRD 문서 |
| `README.md` | 설정 가이드 |

## 아키텍처

```
PR Merge → GitHub Actions → Slack Lists API → List 업데이트
           (Issue 파싱)    (items.update)    (진행률 100%)
```

## 필수 Secrets

| Secret | 설명 |
|--------|------|
| `SLACK_BOT_TOKEN` | Slack Bot OAuth Token (`xoxb-...`) |
| `SLACK_LIST_ID` | 대상 Slack List ID (`F...`) |
| `SLACK_WEBHOOK_URL` | 실패 알림용 Webhook |

## PR 제목 규칙

Issue 번호를 PR 제목에 포함:

```
feat: add social login #123
fix: resolve session timeout #456
```

## 테스트

```bash
# Slack API 연결 테스트
curl -X POST "https://slack.com/api/auth.test" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"

# List 항목 조회
curl -X POST "https://slack.com/api/files.list?types=lists" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"
```

## 관련 문서

- [Slack Lists API 문서](https://docs.slack.dev/reference/methods/slackLists.items.update/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
