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

# Get List metadata
Write-Host "=== List Metadata ===" -ForegroundColor Cyan
$body = @{ list_id = $listId } | ConvertTo-Json
$result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.get' -Method Post -Headers $headers -Body $body

if ($result.ok) {
    Write-Host "List ID: $($result.list.id)"
    Write-Host "Name: $($result.list.name)"
    Write-Host ""
    Write-Host "=== Columns ===" -ForegroundColor Cyan
    foreach ($col in $result.list.schema.columns) {
        Write-Host "  ID: $($col.id)" -ForegroundColor Yellow
        Write-Host "    Name: $($col.name)"
        Write-Host "    Type: $($col.type)"
        Write-Host ""
    }
} else {
    Write-Host "Error: $($result.error)" -ForegroundColor Red
    $result | ConvertTo-Json -Depth 10
}
