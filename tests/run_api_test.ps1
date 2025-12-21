Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_USER_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

Write-Host "========================================"
Write-Host "Slack API Live Test"
Write-Host "========================================"
Write-Host ""

# Step 1: Auth Test
Write-Host "Step 1: Auth Test (auth.test)"
Write-Host "========================================"

$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json; charset=utf-8'
}

$authResult = Invoke-RestMethod -Uri 'https://slack.com/api/auth.test' -Method Post -Headers $headers

if ($authResult.ok) {
    Write-Host "[OK] Auth Success" -ForegroundColor Green
    Write-Host "  Bot: $($authResult.user)"
    Write-Host "  Team: $($authResult.team)"
} else {
    Write-Host "[FAIL] Auth Failed: $($authResult.error)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: List Items
Write-Host "========================================"
Write-Host "Step 2: List Items (slackLists.items.list)"
Write-Host "========================================"

$body = @{ list_id = $listId } | ConvertTo-Json

$listResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $body

if ($listResult.ok) {
    $itemCount = $listResult.items.Count
    Write-Host "[OK] List Query Success" -ForegroundColor Green
    Write-Host "  Item Count: $itemCount"

    if ($itemCount -gt 0) {
        Write-Host ""
        Write-Host "  Items:"
        foreach ($item in $listResult.items) {
            Write-Host "  - ID: $($item.id)"
        }

        # Save first item for update test
        $script:firstItemId = $listResult.items[0].id

        Write-Host ""
        Write-Host "  First Item Columns:"
        foreach ($field in $listResult.items[0].fields) {
            Write-Host "  - $($field.column_id)"
        }
    }
} else {
    Write-Host "[FAIL] List Query Failed: $($listResult.error)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Update Test
Write-Host "========================================"
Write-Host "Step 3: Update Test (slackLists.items.update)"
Write-Host "========================================"

if (-not $firstItemId) {
    Write-Host "[SKIP] No items to update" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Target Item: $firstItemId"

# Use the third item which has actual data
$targetItemId = "Rec0A4BF3PZT9"
Write-Host "  Using item with data: $targetItemId"

$updateBody = @{
    list_id = $listId
    cells = @(
        @{
            row_id = $targetItemId
            column_id = "Col0A55RYJHEV"  # Progress column
            number = @(100)
        },
        @{
            row_id = $targetItemId
            column_id = "Col0A4WG5SFD2"  # Description column
            rich_text = @(
                @{
                    type = "rich_text"
                    elements = @(
                        @{
                            type = "rich_text_section"
                            elements = @(
                                @{
                                    type = "text"
                                    text = "API Test $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                                }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

$updateResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $updateBody

if ($updateResult.ok) {
    Write-Host "[OK] Update Success!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Update Failed: $($updateResult.error)" -ForegroundColor Red
    Write-Host "  Response: $($updateResult | ConvertTo-Json)"
    exit 1
}

Write-Host ""
Write-Host "========================================"
Write-Host "All Tests Passed!"
Write-Host "========================================"
