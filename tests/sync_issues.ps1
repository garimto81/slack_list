# Sync GitHub Issues to Slack List
# GitHub OPEN Issues를 Slack List 항목으로 생성합니다

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

# Column IDs
$COL_PROGRESS = "Col0A55RYJHEV"
$COL_NOTE = "Col0A4WG5SFD2"
$COL_LAST_UPDATE = "Col0A4ZL4THPU"

Write-Host "==========================================="
Write-Host "Sync GitHub Issues to Slack List"
Write-Host "==========================================="
Write-Host ""

# Step 1: Fetch OPEN issues from GitHub
Write-Host "[Step 1] Fetching OPEN issues from GitHub..." -ForegroundColor Cyan

# Change to repo directory
Push-Location "D:\AI\claude01"

try {
    $issuesJson = gh issue list --state open --json number,title,labels --limit 100
    $issues = $issuesJson | ConvertFrom-Json
} catch {
    Write-Host "  [ERROR] Failed to fetch issues: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

$issueCount = $issues.Count
Write-Host "  Found: $issueCount issues" -ForegroundColor Green
Write-Host ""

if ($issueCount -eq 0) {
    Write-Host "No OPEN issues to sync."
    exit 0
}

# Step 2: Create Slack List items
Write-Host "[Step 2] Creating Slack List items..." -ForegroundColor Cyan
$successCount = 0
$failCount = 0
$currentDate = (Get-Date).AddHours(9).ToString("yyyy-MM-dd")  # KST

foreach ($issue in $issues) {
    $issueNum = $issue.number
    $issueTitle = $issue.title
    $labels = ($issue.labels | ForEach-Object { $_.name }) -join ", "

    $title = "#$issueNum - $issueTitle"
    Write-Host "  Creating: $title"

    # Create item
    $createBody = @{
        list_id = $listId
        item = @{
            fields = @{
                title = $title
            }
        }
    } | ConvertTo-Json -Depth 5

    try {
        $createResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.create' `
            -Method Post `
            -Headers $headers `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($createBody))

        if ($createResult.ok) {
            $newItemId = $createResult.item.id
            Write-Host "    [OK] Created: $newItemId" -ForegroundColor Green

            # Update progress, note, and date
            $progressText = "-- 대기중"
            $noteText = if ($labels) { "Labels: $labels" } else { "No labels" }

            $updateBody = @{
                list_id = $listId
                cells = @(
                    @{
                        row_id = $newItemId
                        column_id = $COL_PROGRESS
                        rich_text = @(
                            @{
                                type = "rich_text"
                                elements = @(
                                    @{
                                        type = "rich_text_section"
                                        elements = @(
                                            @{ type = "text"; text = $progressText }
                                        )
                                    }
                                )
                            }
                        )
                    },
                    @{
                        row_id = $newItemId
                        column_id = $COL_NOTE
                        rich_text = @(
                            @{
                                type = "rich_text"
                                elements = @(
                                    @{
                                        type = "rich_text_section"
                                        elements = @(
                                            @{ type = "text"; text = $noteText }
                                        )
                                    }
                                )
                            }
                        )
                    },
                    @{
                        row_id = $newItemId
                        column_id = $COL_LAST_UPDATE
                        date = @($currentDate)
                    }
                )
            } | ConvertTo-Json -Depth 10

            $updateResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' `
                -Method Post `
                -Headers $headers `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($updateBody))

            if ($updateResult.ok) {
                Write-Host "    [OK] Updated fields" -ForegroundColor Green
            } else {
                Write-Host "    [WARN] Failed to update: $($updateResult.error)" -ForegroundColor Yellow
            }

            $successCount++
        } else {
            Write-Host "    [FAIL] $($createResult.error)" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "==========================================="
Write-Host "Sync Complete!"
Write-Host "  Created: $successCount / $issueCount"
if ($failCount -gt 0) {
    Write-Host "  Failed: $failCount" -ForegroundColor Red
}
Write-Host "==========================================="
