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

# Items to recreate with proper titles
$oldItems = @(
    "Rec0A4WE34P37",
    "Rec0A4ZSCRT8S",
    "Rec0A4JDL4JUX",
    "Rec0A4JDK7HUP"
)

# Step 1: Delete old items
Write-Host "=== Deleting old items ===" -ForegroundColor Yellow
foreach ($itemId in $oldItems) {
    Write-Host "Deleting: $itemId"

    $body = @{
        list_id = $listId
        item_ids = @($itemId)
    } | ConvertTo-Json -Depth 5

    $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.delete' -Method Post -Headers $headers -Body $body

    if ($result.ok) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: $($result.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Creating new item with title ===" -ForegroundColor Yellow

# Step 2: Create new item with title
$body = @{
    list_id = $listId
    item = @{
        fields = @{
            title = "garimto81/claude"
        }
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.create' -Method Post -Headers $headers -Body $body

if ($result.ok) {
    $newItemId = $result.item.id
    Write-Host "  Created: $newItemId" -ForegroundColor Green

    # Step 3: Update with progress bar
    Write-Host ""
    Write-Host "=== Setting progress ===" -ForegroundColor Yellow

    $updateBody = @{
        list_id = $listId
        cells = @(
            @{
                row_id = $newItemId
                column_id = "Col0A55RYJHEV"
                rich_text = @(
                    @{
                        type = "rich_text"
                        elements = @(
                            @{
                                type = "rich_text_section"
                                elements = @(
                                    @{
                                        type = "text"
                                        text = "N/A"
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
        Write-Host "  Progress set: OK" -ForegroundColor Green
    } else {
        Write-Host "  Progress set: FAILED - $($updateResult.error)" -ForegroundColor Red
    }
} else {
    Write-Host "  FAILED: $($result.error)" -ForegroundColor Red
    $result | ConvertTo-Json -Depth 5
}

Write-Host ""
Write-Host "Done!"
