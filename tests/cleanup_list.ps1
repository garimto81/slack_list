# Slack List Cleanup - Delete All Items
# 모든 기존 항목을 삭제합니다

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

Write-Host "==========================================="
Write-Host "Slack List Cleanup - Delete All Items"
Write-Host "==========================================="
Write-Host ""

# Step 1: Fetch all items
Write-Host "[Step 1] Fetching all items..." -ForegroundColor Cyan
$listBody = @{ list_id = $listId } | ConvertTo-Json
$listResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $listBody

if (-not $listResult.ok) {
    Write-Host "  [ERROR] Failed to fetch items: $($listResult.error)" -ForegroundColor Red
    exit 1
}

$items = $listResult.items
$totalCount = $items.Count
Write-Host "  Found: $totalCount items" -ForegroundColor Green
Write-Host ""

if ($totalCount -eq 0) {
    Write-Host "No items to delete. List is already empty."
    exit 0
}

# Step 2: Delete each item
Write-Host "[Step 2] Deleting items..." -ForegroundColor Cyan
$successCount = 0
$failCount = 0

foreach ($item in $items) {
    $itemId = $item.id
    # Get item name from fields
    $nameField = $item.fields | Where-Object { $_.column_id -eq "Col0A4WG2LPHA" }
    $itemName = if ($nameField) { $nameField.text } else { "(no name)" }

    Write-Host "  Deleting: $itemId ($itemName)"

    $deleteBody = @{
        list_id = $listId
        id = $itemId
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.delete' `
            -Method Post `
            -Headers $headers `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($deleteBody))

        if ($result.ok) {
            Write-Host "    [OK] Deleted" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "    [FAIL] $($result.error)" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "==========================================="
Write-Host "Cleanup Complete!"
Write-Host "  Deleted: $successCount / $totalCount"
if ($failCount -gt 0) {
    Write-Host "  Failed: $failCount" -ForegroundColor Red
}
Write-Host "==========================================="
