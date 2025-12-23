# UTF-8 with BOM
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

# 업데이트할 항목 정의
$updates = @(
    @{ row_id = "Rec0A4QC0JML3"; progress = "========== 100%"; note = "Done" },
    @{ row_id = "Rec0A4FAAK58F"; progress = "========== 100%"; note = "Done" },
    @{ row_id = "Rec0A50BA1QH2"; progress = "========== 100%"; note = "Done" },
    @{ row_id = "Rec0A4TALDS4V"; progress = "=========- 90%"; note = "In Progress: Issue fix" }
)

Write-Host "========================================"
Write-Host "Slack List Batch Update"
Write-Host "========================================"
Write-Host ""

foreach ($item in $updates) {
    Write-Host "Updating: $($item.row_id)"

    $updateBody = @{
        list_id = $listId
        cells = @(
            @{
                row_id = $item.row_id
                column_id = "Col0A55RYJHEV"
                rich_text = @(
                    @{
                        type = "rich_text"
                        elements = @(
                            @{
                                type = "rich_text_section"
                                elements = @(
                                    @{ type = "text"; text = $item.progress }
                                )
                            }
                        )
                    }
                )
            },
            @{
                row_id = $item.row_id
                column_id = "Col0A4WG5SFD2"
                rich_text = @(
                    @{
                        type = "rich_text"
                        elements = @(
                            @{
                                type = "rich_text_section"
                                elements = @(
                                    @{ type = "text"; text = $item.note }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $updateBody

    if ($result.ok) {
        Write-Host "  [OK] $($item.progress) | $($item.note)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($result.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Update Complete!"
Write-Host "========================================"
