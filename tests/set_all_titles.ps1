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

# Title column ID
$titleColumnId = "Col0A4WG2LPHA"

# All item IDs
$items = @(
    "Rec0A4JG0BCRM",
    "Rec0A4WG57FNH",
    "Rec0A4WE34P37",
    "Rec0A4ZSCRT8S",
    "Rec0A4JDL4JUX",
    "Rec0A4JDK7HUP"
)

Write-Host "=== Setting title to 'garimto81/claude' ===" -ForegroundColor Yellow
Write-Host ""

foreach ($itemId in $items) {
    Write-Host "Updating: $itemId"

    $body = @{
        list_id = $listId
        cells = @(
            @{
                row_id = $itemId
                column_id = $titleColumnId
                rich_text = @(
                    @{
                        type = "rich_text"
                        elements = @(
                            @{
                                type = "rich_text_section"
                                elements = @(
                                    @{
                                        type = "text"
                                        text = "garimto81/claude"
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
