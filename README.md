# GitHub-Slack Sync

PR 머지 시 Slack List를 자동으로 업데이트하는 GitHub Actions 워크플로우

## 기능

- PR 머지 시 자동 트리거
- PR 제목에서 Issue 번호(`#123`) 추출
- Slack List 항목의 진행률을 100%로 업데이트
- 비고 필드에 PR 제목 저장
- 매칭 실패 시 Slack 알림 발송

## 아키텍처

```
PR Merge → GitHub Actions → Slack Lists API → List 업데이트
           (Issue 파싱)    (items.update)    (진행률 100%)
```

## 설정

### 1. Slack App 생성

1. [Slack API](https://api.slack.com/apps)에서 새 앱 생성
2. **OAuth & Permissions**에서 Bot Token Scopes 추가:
   - `lists:read`
   - `lists:write`
3. 워크스페이스에 앱 설치
4. **Bot User OAuth Token** 복사 (`xoxb-...`)

### 2. Slack List 생성

1. Slack에서 List 생성
2. 필수 컬럼 추가:
   - `ID` (텍스트) - Issue 번호 (`#123`)
   - `업무명` (텍스트)
   - `진행률` (숫자) - 0-100%
   - `비고` (텍스트) - PR 제목 저장
3. List ID 확인 (URL에서 `F...` 형식)

### 3. GitHub Secrets 설정

Repository Settings > Secrets and variables > Actions에서 추가:

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `SLACK_BOT_TOKEN` | Slack Bot 토큰 | `xoxb-123-456-abc` |
| `SLACK_LIST_ID` | Slack List ID | `F1234ABCD` |
| `SLACK_WEBHOOK_URL` | 실패 알림용 Webhook | `https://hooks.slack.com/...` |

### 4. Column ID 확인

Slack List의 실제 Column ID를 확인하고 워크플로우 수정:

```bash
curl -X POST "https://slack.com/api/slackLists.items.list" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"list_id": "YOUR_LIST_ID"}'
```

응답에서 `column_id` 값을 확인하고 `.github/workflows/slack-list-sync.yml` 수정.

## 사용법

### PR 제목 형식

Issue 번호를 PR 제목에 포함:

```
feat: add social login #123
fix: resolve session timeout #456
```

또는 브랜치명에 포함:

```
feat/123-add-login
fix/456-session-bug
```

### 동작 흐름

1. PR 머지
2. GitHub Actions 트리거
3. Issue 번호 추출 (`#123`)
4. Slack List에서 해당 항목 검색
5. 진행률 100% + 비고 업데이트

## 문제 해결

### Issue 번호를 찾을 수 없음

- PR 제목에 `#123` 형식으로 Issue 번호 포함
- 또는 브랜치명에 숫자 포함

### Slack List 항목을 찾을 수 없음

- Slack List의 ID 필드에 `#123` 형식으로 입력되어 있는지 확인
- `SLACK_LIST_ID` Secret이 올바른지 확인

### 권한 오류

- Slack App에 `lists:read`, `lists:write` 권한 확인
- Bot Token이 올바른지 확인
- Slack Pro 플랜 이상인지 확인 (Lists API 필수)

## 비용

| 항목 | 비용 |
|------|------|
| GitHub Actions | $0 (Free tier) |
| Slack Pro | $8.75/사용자/월 |

## 라이선스

MIT
# 한글 테스트 Sun, Dec 21, 2025  5:20:40 PM
# 테스트 v2 Sun, Dec 21, 2025  5:23:12 PM
# 테스트 v3 Sun, Dec 21, 2025  5:24:53 PM
# 테스트 v4 Sun, Dec 21, 2025  5:27:47 PM
# debug test Sun, Dec 21, 2025  5:29:21 PM
# debug v2 Sun, Dec 21, 2025  5:30:27 PM
# curl fix $(date)
# form $(date)
# urlencode Sun, Dec 21, 2025  5:33:32 PM
# json v2 Sun, Dec 21, 2025  5:34:58 PM
