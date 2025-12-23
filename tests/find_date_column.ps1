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

$body = @{ list_id = $listId } | ConvertTo-Json

$result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $body

Write-Host "=== Looking for Date columns ===" -ForegroundColor Cyan

$result.items | ForEach-Object {
    $itemId = $_.id
    $_.fields | ForEach-Object {
        if ($_.date -ne $null) {
            Write-Host "Found Date Column!" -ForegroundColor Green
            Write-Host "  Item ID: $itemId"
            Write-Host "  Column ID: $($_.column_id)"
            Write-Host "  Key: $($_.key)"
            Write-Host "  Date: $($_.date)"
        }
    }
}

Write-Host ""
Write-Host "=== All Column IDs in first item ===" -ForegroundColor Cyan
$result.items[0].fields | ForEach-Object {
    Write-Host "  Column: $($_.column_id) | Key: $($_.key)"
}
