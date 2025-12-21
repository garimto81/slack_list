# Slack List에 #21 항목 추가
$token = $env:SLACK_USER_TOKEN
$listId = $env:SLACK_LIST_ID

Write-Host "Token: $($token.Substring(0,15))..."
Write-Host "List ID: $listId"

# 항목 추가 API 호출
$body = @{
    list_id = $listId
    item = @{
        fields = @(
            @{ column_id = "title"; text = "#21" }
        )
    }
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri "https://slack.com/api/slackLists.items.create" `
    -Method POST `
    -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
    -Body $body

$response | ConvertTo-Json -Depth 5
