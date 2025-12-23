Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_USER_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

Write-Host "Deleting items without names..."

$deleteIds = @("Rec0A4UURHTN2", "Rec0A59RX85S5")

foreach ($itemId in $deleteIds) {
    Write-Host "  Deleting: $itemId"

    # Use 'id' field as per error message
    $body = @{
        list_id = $listId
        id = $itemId
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.delete' `
            -Method Post `
            -Headers @{ 'Authorization' = "Bearer $token"; 'Content-Type' = 'application/json; charset=utf-8' } `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        if ($result.ok) {
            Write-Host "    [OK] Deleted" -ForegroundColor Green
        } else {
            Write-Host "    [FAIL] $($result.error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done!"
