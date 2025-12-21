#!/bin/bash
# Slack API 실제 연동 테스트
# 사용법: bash tests/test_slack_api_live.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "Slack API 실제 연동 테스트"
echo "========================================"
echo ""

# 환경 변수 로드
if [ -f "$PROJECT_DIR/env.local" ]; then
    echo -e "${YELLOW}[INFO]${NC} env.local 파일 로드 중..."
    export $(grep -v '^#' "$PROJECT_DIR/env.local" | xargs)
else
    echo -e "${RED}[ERROR]${NC} env.local 파일이 없습니다."
    echo "  다음 명령으로 생성하세요:"
    echo "  cp env.local.example env.local"
    exit 1
fi

# 환경 변수 확인
if [ -z "$SLACK_BOT_TOKEN" ] || [ "$SLACK_BOT_TOKEN" = "xoxb-여기에입력" ]; then
    echo -e "${RED}[ERROR]${NC} SLACK_BOT_TOKEN이 설정되지 않았습니다."
    exit 1
fi

if [ -z "$SLACK_LIST_ID" ] || [ "$SLACK_LIST_ID" = "F여기에입력" ]; then
    echo -e "${RED}[ERROR]${NC} SLACK_LIST_ID가 설정되지 않았습니다."
    exit 1
fi

echo -e "${GREEN}[OK]${NC} 환경 변수 로드 완료"
echo "  SLACK_BOT_TOKEN: ${SLACK_BOT_TOKEN:0:15}..."
echo "  SLACK_LIST_ID: $SLACK_LIST_ID"
echo ""

# Step 1: 인증 테스트
echo "========================================"
echo "Step 1: 인증 테스트 (auth.test)"
echo "========================================"

AUTH_RESPONSE=$(curl -s -X POST "https://slack.com/api/auth.test" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json")

AUTH_OK=$(echo "$AUTH_RESPONSE" | jq -r '.ok')

if [ "$AUTH_OK" = "true" ]; then
    BOT_USER=$(echo "$AUTH_RESPONSE" | jq -r '.user')
    TEAM=$(echo "$AUTH_RESPONSE" | jq -r '.team')
    echo -e "${GREEN}[OK]${NC} 인증 성공"
    echo "  Bot: $BOT_USER"
    echo "  Team: $TEAM"
else
    ERROR=$(echo "$AUTH_RESPONSE" | jq -r '.error')
    echo -e "${RED}[FAIL]${NC} 인증 실패: $ERROR"
    exit 1
fi
echo ""

# Step 2: List 항목 조회
echo "========================================"
echo "Step 2: List 항목 조회 (slackLists.items.list)"
echo "========================================"

LIST_RESPONSE=$(curl -s -X POST "https://slack.com/api/slackLists.items.list" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"list_id\": \"$SLACK_LIST_ID\"}")

LIST_OK=$(echo "$LIST_RESPONSE" | jq -r '.ok')

if [ "$LIST_OK" = "true" ]; then
    ITEM_COUNT=$(echo "$LIST_RESPONSE" | jq -r '.items | length')
    echo -e "${GREEN}[OK]${NC} List 조회 성공"
    echo "  항목 수: $ITEM_COUNT"
    echo ""
    echo "  항목 목록:"
    echo "$LIST_RESPONSE" | jq -r '.items[] | "  - ID: \(.id) | Fields: \(.fields | length)개"'

    # 첫 번째 항목의 구조 확인
    if [ "$ITEM_COUNT" -gt 0 ]; then
        echo ""
        echo "  첫 번째 항목 상세:"
        echo "$LIST_RESPONSE" | jq '.items[0]'
    fi
else
    ERROR=$(echo "$LIST_RESPONSE" | jq -r '.error')
    echo -e "${RED}[FAIL]${NC} List 조회 실패: $ERROR"
    echo "  전체 응답: $LIST_RESPONSE"
    exit 1
fi
echo ""

# Step 3: 테스트 항목 업데이트 (첫 번째 항목)
echo "========================================"
echo "Step 3: 테스트 항목 업데이트 (slackLists.items.update)"
echo "========================================"

# 첫 번째 항목 ID 추출
FIRST_ITEM_ID=$(echo "$LIST_RESPONSE" | jq -r '.items[0].id')

if [ -z "$FIRST_ITEM_ID" ] || [ "$FIRST_ITEM_ID" = "null" ]; then
    echo -e "${YELLOW}[SKIP]${NC} 업데이트할 항목이 없습니다."
    exit 0
fi

echo "  업데이트 대상: $FIRST_ITEM_ID"
echo "  진행률: 100%"
echo "  비고: 테스트 업데이트 ($(date '+%Y-%m-%d %H:%M:%S'))"

# Column ID 확인 (첫 번째 항목에서 추출)
echo ""
echo "  현재 항목의 Column ID들:"
echo "$LIST_RESPONSE" | jq -r '.items[0].fields[] | "  - \(.column_id)"'

# 업데이트 요청
UPDATE_RESPONSE=$(curl -s -X POST "https://slack.com/api/slackLists.items.update" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"list_id\": \"$SLACK_LIST_ID\",
        \"item_id\": \"$FIRST_ITEM_ID\",
        \"fields\": [
            {
                \"column_id\": \"progress\",
                \"number\": [100]
            },
            {
                \"column_id\": \"remarks\",
                \"rich_text\": [{
                    \"type\": \"rich_text\",
                    \"elements\": [{
                        \"type\": \"rich_text_section\",
                        \"elements\": [{
                            \"type\": \"text\",
                            \"text\": \"테스트 업데이트 ($(date '+%Y-%m-%d %H:%M:%S'))\"
                        }]
                    }]
                }]
            }
        ]
    }")

UPDATE_OK=$(echo "$UPDATE_RESPONSE" | jq -r '.ok')

if [ "$UPDATE_OK" = "true" ]; then
    echo ""
    echo -e "${GREEN}[OK]${NC} 업데이트 성공!"
    echo "  Slack List에서 확인하세요."
else
    ERROR=$(echo "$UPDATE_RESPONSE" | jq -r '.error')
    echo ""
    echo -e "${RED}[FAIL]${NC} 업데이트 실패: $ERROR"
    echo "  전체 응답: $UPDATE_RESPONSE"
    echo ""
    echo -e "${YELLOW}[TIP]${NC} column_id가 맞는지 확인하세요."
    echo "  위에 출력된 Column ID를 확인하고 워크플로우를 수정하세요."
    exit 1
fi

echo ""
echo "========================================"
echo "테스트 완료"
echo "========================================"
