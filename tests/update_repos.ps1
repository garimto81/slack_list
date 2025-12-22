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
$titleColumnId = "Col0A4WG2LPHA"
$progressColumnId = "Col0A55RYJHEV"

# Get current items
$listBody = @{ list_id = $listId } | ConvertTo-Json
$currentItems = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.list' -Method Post -Headers $headers -Body $listBody

# Repos with activity in last 5 days
$repos = @(
    "shorts-generator",
    "heritage_shop",
    "pokergo_crawling",
    "wsoptv_solution",
    "field-uploader",
    "slack_list",
    "mad_framework",
    "claude",
    "wsoptv_v2",
    "store_parser",
    "ggp_fasion_01",
    "archive_converter",
    "project_master"
)

Write-Host "=== Updating Slack List with Repos ===" -ForegroundColor Cyan
Write-Host "Current items: $($currentItems.items.Count)"
Write-Host "Repos to set: $($repos.Count)"
Write-Host ""

# Update existing items with repo names
$itemIds = $currentItems.items | ForEach-Object { $_.id }

for ($i = 0; $i -lt [Math]::Min($itemIds.Count, $repos.Count); $i++) {
    $itemId = $itemIds[$i]
    $repoName = $repos[$i]

    Write-Host "Updating $itemId -> $repoName"

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
                                        text = $repoName
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

# Create new items for remaining repos
if ($repos.Count -gt $itemIds.Count) {
    Write-Host ""
    Write-Host "=== Creating new items ===" -ForegroundColor Yellow

    for ($i = $itemIds.Count; $i -lt $repos.Count; $i++) {
        $repoName = $repos[$i]
        Write-Host "Creating: $repoName"

        # Create item
        $createBody = @{
            list_id = $listId
            item = @{
                fields = @{}
            }
        } | ConvertTo-Json -Depth 10

        $createResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.create' -Method Post -Headers $headers -Body $createBody

        if ($createResult.ok) {
            $newItemId = $createResult.item.id
            Write-Host "  Created: $newItemId" -ForegroundColor Green

            # Set title
            $updateBody = @{
                list_id = $listId
                cells = @(
                    @{
                        row_id = $newItemId
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
                                                text = $repoName
                                            }
                                        )
                                    }
                                )
                            }
                        )
                    },
                    @{
                        row_id = $newItemId
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
                    }
                )
            } | ConvertTo-Json -Depth 10

            $updateResult = Invoke-RestMethod -Uri 'https://slack.com/api/slackLists.items.update' -Method Post -Headers $headers -Body $updateBody

            if ($updateResult.ok) {
                Write-Host "  Title set: OK" -ForegroundColor Green
            } else {
                Write-Host "  Title set: FAILED - $($updateResult.error)" -ForegroundColor Red
            }
        } else {
            Write-Host "  FAILED: $($createResult.error)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Done!"
