# Authenticate to Azure
<#$subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252"
Write-Host "Authenticating to Azure subscription... " -ForegroundColor Cyan
Connect-AzAccount -SubscriptionId $subscriptionId

Set-AzContext -SubscriptionId $subscriptionId
#>

# Define time range
$timeFrame = (Get-Date).AddDays(-1)
$startDate = $timeFrame.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Initialize an empty array to store results
$resultsArray = @()

$storageAccounts = Get-AzStorageAccount

# Get storage account details
foreach ($storageAccount in $storageAccounts) {
    $accountName = $storageAccount.StorageAccountName
    $resourceGroupName = $storageAccount.ResourceGroupName
    $resourceId = $storageAccount.Id

    # Define metrics parameters
    $Transactions = "Transactions"
    $metricNamespace = "Microsoft.Storage/storageAccounts"
    $aggregationType = "Total"

    # Get storage metrics
    $TransactionMetric = Get-AzMetric -ResourceId "$resourceId" -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType Count -DetailedOutput -WarningAction SilentlyContinue
    $storageTransactionMetrics = $TransactionMetric.Data

    # Calculate the total count
    $totalCount = 0
    foreach ($dataPoint in $storageTransactionMetrics) {
        # Extract timestamp and count from data point
        $timestamp = $dataPoint.TimeStamp
        $count = $dataPoint.Count

        # Add count to the total count
        $totalCount += $count
    }

    # Add data to results array
    $result = [PSCustomObject]@{
        'StorageAccountName' = $accountName
        'TotalValue' = $totalCount
    }
    $resultsArray += $result
}

# Save results to CSV file (append if the file exists)
$csvFilePath = "C:\scripts\StorageTransactionTotal.csv"
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation -Append

Write-Host "Results saved to $csvFilePath"