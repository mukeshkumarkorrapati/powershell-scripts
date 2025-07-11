param(

    $subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252",
    $outputpath = ".\"
)

# connect and Set the subscription context

#Connect-AzAccount -SubscriptionId $subscriptionId

$resultsArray = @()
Write-Host "Getting Storage Metrics Insights for all Storage Accounts's in the Subscription '$subscriptionName'" -ForegroundColor Cyan

$storageAccounts = Get-AzStorageAccount

# Get storage account details
foreach ($storageAccount in $storageAccounts) {

    $storageAccountName = $storageAccount.StorageAccountName
    $resourceGroupName = $storageAccount.ResourceGroupName
    $resourceId = $storageAccount.Id

    # Define metrics parameters
    $metricNames = @("SuccessServerLatency", "SuccessE2ELatency", "Transactions")
    $metricNamespace = "Microsoft.Storage/storageAccounts"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'SubscriptionName'     = $Subscriptionname
        'StorageAccountName'   = $storageAccountName
        'ResourceGroupName'    = $resourceGroupName
        'SuccessServerLatency' = $null
        'SuccessE2ELatency'    = $null
        'Transactions'         = $null
    }

    # Get metrics data for each metric
    foreach ($metricName in $metricNames) {
        try {
            $aggregationType = if ($metricName -eq "SuccessServerLatency" -or $metricName -eq "SuccessE2ELatency" -or $metricName ) {
                #-eq "UsedCapacity"
                'Average'
            }
            else {
                'Total'
            }

            $storageMetric = Get-AzMetric -ResourceId "$resourceId" -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType $aggregationType -DetailedOutput -WarningAction SilentlyContinue
            $storageMetrics = $storageMetric.Data

            # Calculate the total count for the current metric
            $totalMetricCount = 0
            $dataPointCount = 0

            foreach ($dataPoint in $storageMetrics) {
                $value = if ($metricName -eq "SuccessServerLatency" -or $metricName -eq "SuccessE2ELatency" -or $metricName) {
                    # -eq "UsedCapacity"
                    $dataPoint.Average
                }
                else {
                    $dataPoint.Total
                }
                
                # Exclude null or zero values
                if ($null -ne $value -and $value -ne 0) {
                    $totalMetricCount += $value
                    $dataPointCount++
                }
            }

            # Calculate the average if there are non-null, non-zero data points
            if ($dataPointCount -gt 0) {
                if ($metricName -eq "Transactions") {
                    $averageValue = [math]::Round($totalMetricCount, 2)
                }
                else {
                    $averageValue = ($totalMetricCount / $dataPointCount)
                    # If the metric is SuccessServerLatency or SuccessE2ELatency, convert it to milliseconds
                    if ($metricName -eq "SuccessServerLatency" -or $metricName -eq "SuccessE2ELatency") {
                        $averageValue = [math]::Round($averageValue, 2)
                    } 
                }
            }
            else {
                $averageValue = $null  # Set the average to null if there are no non-null, non-zero data points
            }

            # Add the total count for the current metric to the metricsData object
            $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $averageValue -Force

        }
        catch {
            Write-Host "Error retrieving metric $metricName for storage account '$storageAccountName': $_"
        }
    }

    # Add metrics data to results array if SuccessServerLatency is greater than 20
    if ($metricsData.SuccessServerLatency -ge 20) {
        $resultsArray += $metricsData
    }
}

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$folderPath\StorageAccountMetrics.csv"
$resultsArray | Select-Object -Property SubscriptionName, StorageAccountName, ResourceGroupName, Transactions, @{Name = "SuccessServerLatency (ms)"; Expression = { $_.SuccessServerLatency } }, @{Name = "SuccessE2ELatency (ms)"; Expression = { $_.SuccessE2ELatency } } | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath for Storage Account Metrics" -ForegroundColor Yellow
