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
    'Content-Type' = 'application/json'
}

$body = @{ list_id = $listId } | ConvertTo-Json
$result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $body

Write-Host "==========================================="
Write-Host "Slack List Items (Total: $($result.items.Count))"
Write-Host "==========================================="
Write-Host ""

$index = 1
foreach ($item in $result.items) {
    $name = ''
    $progress = ''
    $note = ''

    foreach ($field in $item.fields) {
        if ($field.column_id -eq 'Col0A4WG2LPHA') { $name = $field.text }
        if ($field.column_id -eq 'Col0A55RYJHEV') { $progress = $field.text }
        if ($field.column_id -eq 'Col0A4WG5SFD2') { $note = $field.text }
    }

    Write-Host "[$index] $($item.id)"
    Write-Host "    Name: $name"
    Write-Host "    Progress: $progress"
    Write-Host "    Note: $note"
    Write-Host ""
    $index++
}
