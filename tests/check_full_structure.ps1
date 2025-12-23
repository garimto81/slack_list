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

Write-Host "=== All Fields for Each Item ===" -ForegroundColor Cyan
Write-Host ""

foreach ($item in $result.items) {
    Write-Host "Item ID: $($item.id)" -ForegroundColor Yellow
    foreach ($field in $item.fields) {
        Write-Host "  Key: $($field.key)" -ForegroundColor Gray
        Write-Host "    Column ID: $($field.column_id)"
        Write-Host "    Text: $($field.text)"
        Write-Host "    Value: $($field.value)"
    }
    Write-Host ""
}
