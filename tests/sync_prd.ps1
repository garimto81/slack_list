# Sync PRD Checklist to Slack List

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
Write-Host "Sync PRD Checklist to Slack List"
Write-Host "==========================================="
Write-Host ""

# Step 1: Find Checklist document
Write-Host "Step 1: Finding Checklist document..." -ForegroundColor Cyan

$checklistPath = "docs/checklists/PRD-0001.md"

if (-not (Test-Path $checklistPath)) {
    Write-Host "  ERROR: Checklist not found: $checklistPath" -ForegroundColor Red
    exit 1
}

Write-Host "  Found: $checklistPath" -ForegroundColor Green
Write-Host ""

# Step 2: Parse Checklist
Write-Host "Step 2: Parsing Checklist..." -ForegroundColor Cyan

$content = Get-Content $checklistPath -Raw

# Count items
$totalMatches = [regex]::Matches($content, '^\s*-\s*\[[ xX]\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)
$doneMatches = [regex]::Matches($content, '^\s*-\s*\[[xX]\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)

$total = $totalMatches.Count
$done = $doneMatches.Count
$progress = if ($total -gt 0) { [math]::Floor($done * 100 / $total) } else { 100 }

Write-Host "  Total: $total, Done: $done, Progress: $progress%" -ForegroundColor Green
Write-Host ""

# Step 3: Build progress bar
$filledChar = [char]0x2588
$emptyChar = [char]0x2591
$bulletChar = [char]0x2022

$filled = [math]::Floor($progress / 10)
$empty = 10 - $filled
$bar = ($filledChar.ToString() * $filled) + ($emptyChar.ToString() * $empty)
$progressText = "$bar $progress% ($done/$total)"

# Get pending items
$pendingItems = @()
$lines = $content -split "`n"
foreach ($line in $lines) {
    if ($line -match '^\s*-\s*\[ \]\s*(.+)$') {
        $itemText = $matches[1].Trim()
        $pendingItems += "$bulletChar $itemText"
        if ($pendingItems.Count -ge 5) { break }
    }
}

$pendingCount = ($content | Select-String -Pattern '^\s*-\s*\[ \]' -AllMatches).Matches.Count

if ($pendingCount -eq 0) {
    $noteText = "All Done!"
}
else {
    $noteText = "In Progress:`n" + ($pendingItems -join "`n")
    if ($pendingCount -gt 5) {
        $noteText += "`n$bulletChar and $($pendingCount - 5) more"
    }
}

Write-Host "Step 3: Creating Slack List item..." -ForegroundColor Cyan
Write-Host "  Title: PRD-0001 GitHub-Slack List"
Write-Host "  Progress: $progressText"
Write-Host ""

# Step 4: Create item
$title = "PRD-0001 GitHub-Slack List"
$currentDate = (Get-Date).AddHours(9).ToString("yyyy-MM-dd")

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
        Write-Host "  OK Created: $newItemId" -ForegroundColor Green

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
            Write-Host "  OK Updated fields" -ForegroundColor Green
        }
        else {
            Write-Host "  WARN Failed to update: $($updateResult.error)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  FAIL $($createResult.error)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ERROR $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================="
Write-Host "Sync Complete!"
Write-Host "==========================================="
