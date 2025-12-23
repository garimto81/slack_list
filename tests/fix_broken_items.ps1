Set-Location $PSScriptRoot\..

# Load env
Get-Content .env.local | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$token = [Environment]::GetEnvironmentVariable('SLACK_USER_TOKEN')
$listId = [Environment]::GetEnvironmentVariable('SLACK_LIST_ID')

# Broken item IDs
$brokenItems = @(
    "Rec0A4ZSCRT8S",
    "Rec0A4JDL4JUX",
    "Rec0A4JDK7HUP"
)

foreach ($itemId in $brokenItems) {
    Write-Host "Fixing item: $itemId"

    $body = @{
        list_id = $listId
        cells = @(
            @{
                row_id = $itemId
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

    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json; charset=utf-8'
    }

    $result = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $body

    if ($result.ok) {
        Write-Host "  OK - Updated to N/A" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: $($result.error)" -ForegroundColor Red
    }
}

Write-Host "`nDone!"
