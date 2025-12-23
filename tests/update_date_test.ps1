# Date Column Update Test Script
# Tests the date update functionality for Slack List

Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_USER_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

# Column IDs
$COL_PROGRESS = "Col0A55RYJHEV"
$COL_NOTE = "Col0A4WG5SFD2"
$COL_LAST_UPDATE = "Col0A4ZL4THPU"

$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json; charset=utf-8'
}

# Get test item ID
Write-Host "=== Step 1: Getting List Items ===" -ForegroundColor Cyan
$listBody = @{ list_id = $listId } | ConvertTo-Json
$listResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $listBody

if (-not $listResult.ok) {
    Write-Host "Error: $($listResult.error)" -ForegroundColor Red
    exit 1
}

$testItemId = $listResult.items[0].id
Write-Host "Test Item ID: $testItemId" -ForegroundColor Green

# Get current date (KST)
$currentDate = (Get-Date).AddHours(9).ToString("yyyy-MM-dd")  # UTC + 9 = KST
Write-Host "Current Date (KST): $currentDate" -ForegroundColor Green

# Update date
Write-Host ""
Write-Host "=== Step 2: Updating Date Column ===" -ForegroundColor Cyan

$updateBody = @{
    list_id = $listId
    cells = @(
        @{
            row_id = $testItemId
            column_id = $COL_LAST_UPDATE
            date = @($currentDate)
        }
    )
} | ConvertTo-Json -Depth 10

Write-Host "Request Body:" -ForegroundColor Yellow
Write-Host $updateBody

$updateResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $updateBody

Write-Host ""
Write-Host "=== Step 3: Result ===" -ForegroundColor Cyan

if ($updateResult.ok) {
    Write-Host "SUCCESS: Date column updated to $currentDate" -ForegroundColor Green
} else {
    Write-Host "FAILED: $($updateResult.error)" -ForegroundColor Red
    Write-Host "Response:" -ForegroundColor Yellow
    $updateResult | ConvertTo-Json -Depth 5
}

# Verify the update
Write-Host ""
Write-Host "=== Step 4: Verification ===" -ForegroundColor Cyan
$verifyResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $listBody

$updatedItem = $verifyResult.items | Where-Object { $_.id -eq $testItemId }
$dateField = $updatedItem.fields | Where-Object { $_.column_id -eq $COL_LAST_UPDATE }

if ($dateField) {
    Write-Host "Verified Date: $($dateField.date)" -ForegroundColor Green
} else {
    Write-Host "Date field not found in response" -ForegroundColor Yellow
}
