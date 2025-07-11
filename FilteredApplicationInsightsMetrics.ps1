param(

    $subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252",
    $outputpath = ".\"
)

# connect and Set the subscription context

Connect-AzAccount -SubscriptionId $subscriptionId

Set-AzContext -SubscriptionId $subscriptionId

# Initialize an empty array to store results
$resultsArray = @()

# Get current subscription name
$subscriptionName = (Get-AzContext).Subscription.Name

# Define time range
$timeFrame = (Get-Date).AddDays(-1)
$startDate = $timeFrame.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Initialize an empty array to store results
$resultsArray = @()
$subscriptionname = (Get-AzContext).Subscription.Name
$applicationInsightsResources = Get-AzResource -ResourceType "microsoft.insights/components"

# Get storage account details
foreach ($applicationInsightsResource in $applicationInsightsResources) {

    $applicationInsightsname = $applicationInsightsResource.Name
    $resourceGroupName = $applicationInsightsResource.ResourceGroupName
    $resourceId = $applicationInsightsResource.ResourceId

    # Define metrics parameters
    $metricNames = @("requests/failed", "availabilityResults/availabilityPercentage")
    $metricNamespace = "microsoft.insights/components"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'SubscriptionName'                           = $Subscriptionname
        'AppInsightsname'                            = $applicationInsightsname
        'ResourceGroupName'                          = $resourceGroupName
        'availabilityResults/availabilityPercentage' = $null
        'requests/failed'                            = $null
    }

    # Get metrics data for each metric
    foreach ($metricName in $metricNames) {
        try {
            $aggregationType = if ($metricName -eq "availabilityResults/availabilityPercentage") {
                'Average'
            }
            else {
                'Count'
            }

            $applicationInsightsMetric = Get-AzMetric -ResourceId $resourceId -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType $aggregationType -DetailedOutput -WarningAction SilentlyContinue
            $applicationInsightsMetrics = $applicationInsightsMetric.Data

            # Calculate the total count for the current metric
            $totalMetricCount = 0
            $dataPointCount = 0

            foreach ($dataPoint in $applicationInsightsMetrics) {
                $value = if ($metricName -eq "availabilityResults/availabilityPercentage") {
                    $dataPoint.Average
                }
                else {
                    $dataPoint.Count
                }
                
                # Exclude null or zero values
                if ($null -ne $value -and $value -ne 0) {
                    $totalMetricCount += $value
                    $dataPointCount++
                }
            }
            # Calculate the average if there are non-null, non-zero data points
            if ($dataPointCount -gt 0) {
                if ($metricName -eq "availabilityResults/availabilityPercentage") {
                    $averageValue = $totalMetricCount / $dataPointCount
                }
                else {
                    $averageValue = $totalMetricCount
                }

                    
            }
            else {
                $averageValue = 0  # Set the average to 0 if there are no non-null, non-zero data points
            }

            # Add the total count for the current metric to the metricsData object
            $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $averageValue -Force

        }
        catch {
            Write-Host "Error retrieving metric $metricName for storage account $storageAccountName"
        }
    }

    # Add metrics data to results array only if there are failed runs
    if ($metricsData.'requests/failed' -gt 0) {
        $resultsArray += $metricsData
    }
}

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$outputpath\ApplicationInsightsMetrics.csv"
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath"