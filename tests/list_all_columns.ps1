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

# Get list metadata with schema
$body = @{ list_id = $listId } | ConvertTo-Json

# Try lists.info
Write-Host "=== Trying lists.info ===" -ForegroundColor Cyan
$result1 = Invoke-RestMethod -Uri 'https://slack.com/api/lists.info' -Method Post -Headers $headers -Body $body
$result1 | ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "=== Trying slackLists.metadata ===" -ForegroundColor Cyan
$result2 = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.metadata' -Method Post -Headers $headers -Body $body
$result2 | ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "=== Unique Column IDs from items ===" -ForegroundColor Cyan
$listBody = @{ list_id = $listId } | ConvertTo-Json
$items = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $listBody

$columns = @{}
foreach ($item in $items.items) {
    foreach ($field in $item.fields) {
        $colId = $field.column_id
        $key = $field.key
        if (-not $columns.ContainsKey($colId)) {
            $columns[$colId] = $key
        }
    }
}

foreach ($col in $columns.GetEnumerator()) {
    Write-Host "Column ID: $($col.Key) | Key: $($col.Value)"
}
