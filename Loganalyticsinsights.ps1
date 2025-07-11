param(

$subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252",
$outputpath = ".\"
)

# connect and Set the subscription context

Connect-AzAccount -SubscriptionId $subscriptionId

Set-AzContext -SubscriptionId $subscriptionId

$workspaces = Get-AzOperationalInsightsWorkspace

# Initialize an empty array to store results
$resultsArray = @()

# Get current subscription name
$subscriptionName = (Get-AzContext).Subscription.Name

# Iterate through each Log Analytics workspace
foreach ($workspace in $workspaces) {
    $workspaceId = $workspace.CustomerId

    $query = @" 
    Usage
| where TimeGenerated >= ago(24h)  // Adjust the time span as needed
| summarize IngestionVolumeMB = sum(Quantity)
| project IngestionVolumeGB = round(IngestionVolumeMB, 3) / 1024
| order by IngestionVolumeGB desc
"@

    Write-Host "Executing query for $($workspace.Name)"

    # Execute the query
    $queryResult = 
    Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $query -Verbose

    # Display the result
    if ($queryResult.Results) {
        foreach ($resultRow in $queryResult.Results) {
            $roundedVolumeGB = [math]::Round($resultRow.IngestionVolumeGB, 3)
            $result = [PSCustomObject]@{
                'subscriptionname' = $subscriptionName
                'WorkspaceName'    = $workspace.Name
                'TotalVolumeGB'    = $roundedVolumeGB
            }
            $results += $result
        }
    }
    else {
        Write-Host "No results found."
    }
}

# Save results to CSV
# Save results to CSV file (append if the file exists)
$csvFilePath = "$outputpath\LogAnalyticsIngestion.csv" 
$results | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Results saved to LogAnalyticsIngestion.csv"