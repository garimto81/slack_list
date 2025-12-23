# Slack List Update with Unicode Block Characters
Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_USER_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

# Unicode escape sequences for JSON
$bar100 = "\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588 100%"
$bar90 = "\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2591 90%"

Write-Host "========================================"
Write-Host "Slack List Unicode Update"
Write-Host "========================================"

# Update items
$updates = @(
    @{ row_id = "Rec0A4QC0JML3"; progress = $bar100; note = "Done" },
    @{ row_id = "Rec0A4FAAK58F"; progress = $bar100; note = "Done" },
    @{ row_id = "Rec0A50BA1QH2"; progress = $bar100; note = "Done" },
    @{ row_id = "Rec0A4TALDS4V"; progress = $bar90; note = "In Progress" }
)

foreach ($item in $updates) {
    Write-Host "Updating: $($item.row_id)"

    $json = @"
{
  "list_id": "$listId",
  "cells": [
    {
      "row_id": "$($item.row_id)",
      "column_id": "Col0A55RYJHEV",
      "rich_text": [{"type": "rich_text", "elements": [{"type": "rich_text_section", "elements": [{"type": "text", "text": "$($item.progress)"}]}]}]
    },
    {
      "row_id": "$($item.row_id)",
      "column_id": "Col0A4WG5SFD2",
      "rich_text": [{"type": "rich_text", "elements": [{"type": "rich_text_section", "elements": [{"type": "text", "text": "$($item.note)"}]}]}]
    }
  ]
}
"@

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    try {
        $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' `
            -Method Post `
            -Headers @{ 'Authorization' = "Bearer $token" } `
            -ContentType 'application/json; charset=utf-8' `
            -Body $bytes

        if ($result.ok) {
            Write-Host "  [OK]" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $($result.error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done!"
