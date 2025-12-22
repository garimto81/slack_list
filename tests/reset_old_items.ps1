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
$progressColumnId = "Col0A55RYJHEV"
$noteColumnId = "Col0A4WG5SFD2"

# Old items that have stale data
$oldItems = @(
    "Rec0A4JG0BCRM",   # shorts-generator
    "Rec0A4WG57FNH",   # heritage_shop
    "Rec0A4WE34P37",   # pokergo_crawling (has 72%)
    "Rec0A4ZSCRT8S",   # wsoptv_solution
    "Rec0A4JDL4JUX",   # field-uploader
    "Rec0A4JDK7HUP"    # slack_list
)

Write-Host "=== Resetting old items ===" -ForegroundColor Yellow

foreach ($itemId in $oldItems) {
    Write-Host "Resetting: $itemId"

    $body = @{
        list_id = $listId
        cells = @(
            @{
                row_id = $itemId
                column_id = $progressColumnId
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
            },
            @{
                row_id = $itemId
                column_id = $noteColumnId
                rich_text = @(
                    @{
                        type = "rich_text"
                        elements = @(
                            @{
                                type = "rich_text_section"
                                elements = @(
                                    @{
                                        type = "text"
                                        text = "-"
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $body

    if ($result.ok) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: $($result.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done!"
