param(

    $subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252",
    $outputpath = ".\"
)

# connect and Set the subscription context

#Connect-AzAccount -SubscriptionId $subscriptionId

Set-AzContext -SubscriptionId $subscriptionId

# Define time range for the last 24 hours
$startDate = (Get-Date).AddDays(-30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Initialize an empty array to store results
$resultsArray = @()

# Get current subscription name
$subscriptionName = (Get-AzContext).Subscription.Name

# Get all virtual machines in the subscription
$virtualMachines = Get-AzVM

# Get metrics data for each virtual machine
foreach ($vm in $virtualMachines) {
    $resourceId        = $vm.Id
    $vmName            = $vm.Name
    $resourceGroupName = $vm.ResourceGroupName
    $status            = (Get-AzVM -Name $vmName -Status)
    $vmstatus          = $status.PowerState
    $sku               = ($vm.HardwareProfile).VmSize

    # Define metrics parameters
    $metricNames = @("Percentage CPU", "Available Memory Bytes", "Disk Write Operations/Sec")
    $metricNamespace = "Microsoft.Compute/virtualMachines"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'subscriptionname'  = $subscriptionname
        'VMName'            = $vmName
        'ResourceGroupName' = $resourceGroupName
        'PowerState'        = $vmstatus
        'VM SKU'            = $sku
    }

    # Get metrics data for each metric
    foreach ($metricName in $metricNames) {
        $metricAggregationType = "Average"

        try {
            $vmMetric = Get-AzMetric -ResourceId $resourceId -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType $metricAggregationType -DetailedOutput -WarningAction SilentlyContinue
            $vmMetrics = $vmMetric.Data

            # Calculate the total count for the current metric
            $totalMetricCount = 0
            foreach ($dataPoint in $vmMetrics) {
                $totalMetricCount += $dataPoint.Average
            }

            # Convert "Available Memory Bytes" to GiB
            if ($metricName -eq "Available Memory Bytes") {
                $averagememorybytes = ($totalMetricCount / $numberOfDataPoints)
                $convertedValue = [math]::Round(($averagememorybytes / (1024 * 1024 * 1024)), 2)
                $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $convertedValue -Force
            }
            elseif ($metricName -eq "Percentage CPU") {
                # Calculate average percentage CPU
                $numberOfDataPoints = $vmMetrics.Count
                $averageCpuPercentage = ($totalMetricCount / $numberOfDataPoints)
                $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value ([math]::Round($averageCpuPercentage, 2)) -Force
                
                # Filter based on CPU percentage
                if ($averageCpuPercentage -lt 20 -or $averageCpuPercentage -gt 80) {
                    # Add metrics data to results array
                    $resultsArray += $metricsData
                }
            }
            elseif ($metricName -eq "Disk Write Operations/Sec") {
                # Calculate the average availability percentage directly
                $averagediskoperations = $totalMetricCount / $numberOfDataPoints

                $convertedValue = [math]::Round($averagediskoperations , 2)
                $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $convertedValue -Force
            }
        }
        catch [Microsoft.Azure.Management.Monitor.Models.ErrorResponseException] {
            # Handle error
        }
        catch {
            # Handle unexpected error
        }

    }
}

$filename = "$subscriptionName-Vmmetrics.csv"

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$outputpath\$filename"
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Results saved to $csvFilePath"