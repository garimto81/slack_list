Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_USER_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json; charset=utf-8'
}

# Old items to delete (without title)
$oldItems = @(
    "Rec0A4WE34P37",
    "Rec0A4ZSCRT8S",
    "Rec0A4JDL4JUX",
    "Rec0A4JDK7HUP"
)

Write-Host "=== Deleting old items ===" -ForegroundColor Yellow

foreach ($itemId in $oldItems) {
    Write-Host "Deleting: $itemId"

    # Try different API formats
    $body = @{
        list_id = $listId
        item_id = $itemId
    } | ConvertTo-Json

    $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.delete' -Method Post -Headers $headers -Body $body

    if ($result.ok) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  Error: $($result.error)" -ForegroundColor Red

        # Try bulk delete format
        $body2 = @{
            list_id = $listId
            items = @($itemId)
        } | ConvertTo-Json -Depth 5

        $result2 = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.delete' -Method Post -Headers $headers -Body $body2

        if ($result2.ok) {
            Write-Host "  Retry OK" -ForegroundColor Green
        } else {
            Write-Host "  Retry Error: $($result2.error)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=== Current Items ===" -ForegroundColor Cyan

$listBody = @{ list_id = $listId } | ConvertTo-Json
$listResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $listBody

foreach ($item in $listResult.items) {
    $title = ($item.fields | Where-Object { $_.key -eq "title" }).text
    $progress = ($item.fields | Where-Object { $_.column_id -eq "Col0A55RYJHEV" }).text
    Write-Host "ID: $($item.id) | Title: $title | Progress: $progress"
}
