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

# Item IDs and their titles
$items = @(
    @{ id = "Rec0A4WE34P37"; title = "garimto81/claude" }
    @{ id = "Rec0A4ZSCRT8S"; title = "garimto81/claude" }
    @{ id = "Rec0A4JDL4JUX"; title = "garimto81/claude" }
    @{ id = "Rec0A4JDK7HUP"; title = "garimto81/claude" }
)

foreach ($item in $items) {
    Write-Host "Setting title for: $($item.id)" -ForegroundColor Yellow

    $body = @{
        list_id = $listId
        item = @{
            id = $item.id
            fields = @{
                title = $item.title
            }
        }
    } | ConvertTo-Json -Depth 10

    $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $body

    if ($result.ok) {
        Write-Host "  OK - Title set to: $($item.title)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: $($result.error)" -ForegroundColor Red
        Write-Host "  Response: $($result | ConvertTo-Json -Depth 5)" -ForegroundColor Gray
    }
}

Write-Host "`nDone!"
