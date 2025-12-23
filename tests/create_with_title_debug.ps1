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

Write-Host "=== Creating item with title ===" -ForegroundColor Yellow

$body = @{
    list_id = $listId
    item = @{
        fields = @{
            title = "garimto81/claude"
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "Request body:"
Write-Host $body
Write-Host ""

$result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.create' -Method Post -Headers $headers -Body $body

Write-Host "Response:"
$result | ConvertTo-Json -Depth 10
