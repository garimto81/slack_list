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

Write-Host "=== Slack List Items ===" -ForegroundColor Cyan
Write-Host ""

foreach ($item in $result.items) {
    $id = $item.id
    $title = ($item.fields | Where-Object { $_.column_id -eq "Col0A4WG2LPHA" }).text
    $progress = ($item.fields | Where-Object { $_.column_id -eq "Col0A55RYJHEV" }).text

    Write-Host "ID: $id" -ForegroundColor Yellow
    Write-Host "  Title: $title"
    Write-Host "  Progress: $progress"
    Write-Host ""
}
