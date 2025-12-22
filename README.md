# GitHub-Slack Sync

PR 머지 시 Slack List를 자동으로 업데이트하는 GitHub Actions 워크플로우

## 기능

- PR 머지 시 자동 트리거
- **PRD 기반 Checklist 문서 파싱** (v1.1 신규)
- PR 본문의 Checklist 파싱 (Fallback)
- 시각적 프로그레스 바 표시 (`████░░░░░░ 60%`)
- **PR 머지 시 해당 항목 자동 체크** (v1.1 신규)
- 진행중인 Checklist 항목 비고에 표시
- Slack List에 항목 없으면 자동 생성
- Checklist 미작성 시 "— Checklist 미작성" 표시 (N/A)

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

## 설정

### 1. Slack App 생성

1. [Slack API](https://api.slack.com/apps)에서 새 앱 생성
2. **OAuth & Permissions**에서 User Token Scopes 추가:
   - `lists:read`
   - `lists:write`
3. 워크스페이스에 앱 설치
4. **User OAuth Token** 복사 (`xoxp-...`)

> **Note**: Bot Token(`xoxb-`)은 Lists API 접근 불가. 반드시 User Token(`xoxp-`) 사용

### 2. Slack List 생성

1. Slack에서 List 생성
2. 필수 컬럼 추가:

| 컬럼 | 타입 | 용도 |
|------|------|------|
| `ID` | 텍스트 | Issue 번호 (`#123`) |
| `업무명` | 텍스트 | PR 제목 |
| `진행률` | **텍스트** | 프로그레스 바 (`████░░░░░░ 60%`) |
| `비고` | 텍스트 | 진행중인 Checklist 항목 |

3. List ID 확인 (URL에서 `F...` 형식)

> **Note**: 진행률 컬럼은 **텍스트 타입**으로 설정해야 프로그레스 바가 표시됩니다.

### 3. GitHub Secrets 설정

Repository Settings > Secrets and variables > Actions에서 추가:

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `SLACK_USER_TOKEN` | Slack User 토큰 | `xoxp-123-456-abc` |
| `SLACK_LIST_ID` | Slack List ID | `F1234ABCD` |

### 4. Column ID 확인

Slack List의 실제 Column ID를 확인하고 워크플로우 수정:

```bash
curl -X POST "https://slack.com/api/slackLists.items.list" \
  -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "list_id=YOUR_LIST_ID"
```

응답에서 `column_id` 값을 확인하고 `.github/workflows/slack-list-sync.yml` 수정.

## 사용법

### PR 본문에 Checklist 작성

```markdown
## Checklist

- [x] 기능 구현
- [x] 단위 테스트
- [ ] 문서 업데이트
- [x] 코드 리뷰
```

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

```
1. PR 머지
2. GitHub Actions 트리거
3. PR 본문 Checklist 파싱
   - 전체: 4개, 완료: 3개 → 75%
4. Slack List에서 #123 항목 검색
   - 없으면 자동 생성
5. 업데이트:
   - 진행률: ████████░░ 75% (3/4)
   - 비고: 🔄 진행중: • 문서 업데이트
```

## 예시

### PR Checklist

```markdown
- [x] API 구현
- [x] 테스트 작성
- [ ] 문서화
```

### Slack List 결과

| ID | 업무명 | 진행률 | 비고 |
|----|--------|--------|------|
| #123 | feat: add API | `██████░░░░ 66% (2/3)` | 🔄 진행중: • 문서화 |

## 문제 해결

### Issue 번호를 찾을 수 없음

- PR 제목에 `#123` 형식으로 Issue 번호 포함
- 또는 브랜치명에 숫자 포함

### Slack List 항목을 찾을 수 없음

- 항목이 없으면 자동 생성됩니다
- `SLACK_LIST_ID` Secret이 올바른지 확인

### 프로그레스 바가 표시되지 않음

- Slack List의 진행률 컬럼이 **텍스트 타입**인지 확인
- 숫자 타입이면 텍스트로 변경 필요

### 권한 오류

- Slack App에 `lists:read`, `lists:write` 권한 확인
- User Token(`xoxp-`)을 사용하는지 확인 (Bot Token 불가)
- Slack Pro 플랜 이상인지 확인 (Lists API 필수)

## 비용

| 항목 | 비용 |
|------|------|
| GitHub Actions | $0 (Free tier) |
| Slack Pro | $8.75/사용자/월 |

## 라이선스

MIT
