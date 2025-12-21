Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_BOT_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json; charset=utf-8'
}

$body = @{ list_id = $listId } | ConvertTo-Json

$result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $body

Write-Host "Full API Response:"
$result | ConvertTo-Json -Depth 10
