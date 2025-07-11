param(

$subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252",
$outputpath = ".\"
)

# connect and Set the subscription context

Connect-AzAccount -SubscriptionId $subscriptionId

Set-AzContext -SubscriptionId $subscriptionId

# Define time range
$timeFrame = (Get-Date).AddDays(-1)
$startDate = $timeFrame.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Initialize an empty array to store results
$resultsArray = @()

# Get current subscription name
$subscriptionName = (Get-AzContext).Subscription.Name

# Get SQL server details
$sqlServers = Get-AzSqlServer

# Get metrics data for each SQL server
foreach ($sqlServer in $sqlServers) {

    $sqlServerName = $sqlServer.ServerName
    $resourceGroupName = $sqlServer.ResourceGroupName

    # Get databases for the current SQL server
    $databases = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName

    foreach ($database in $databases) {

        $databaseName = $database.DatabaseName
        $databaseResourceId = $database.ResourceId

        # Define metrics parameters
        $metricNames = @("allocated_data_storage", "storage", "cpu_percent", "sql_instance_memory_percent","storage_percent")
        $metricNamespace = "Microsoft.Sql/servers/databases"

        # Initialize an object to store metrics data
        $metricsData = [PSCustomObject]@{
            'SubscriptionName'  = $subscriptionName
            'SqlServerName'     = $sqlServerName
            'DatabaseName'      = $databaseName
            'ResourceGroupName' = $resourceGroupName
        }

        # Get metrics data for each metric
        foreach ($metricName in $metricNames) {

            $sqlMetric = Get-AzMetric -ResourceId $databaseResourceId -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType Average -DetailedOutput -WarningAction SilentlyContinue
            $sqlMetrics = $sqlMetric.Data

            # Calculate the total count for the current metric
            $totalMetricCount = 0
            $dataPointCount = 0
            $nonZeroDataPointCount = 0

            foreach ($dataPoint in $sqlMetrics) {
                $value = $dataPoint.Average

                # Exclude null or zero values
                if ($null -ne $value) {
                    $totalMetricCount += $value
                    $dataPointCount++

                    if ($value -ne 0) {
                        # Additional check to exclude zero values from the count
                        $nonZeroDataPointCount++
                    }
                }
            }

            # Calculate the average if there are non-null, non-zero data points
            if ($dataPointCount -gt 0) {
              
                $averageValue = $totalMetricCount / $dataPointCount
               
                $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $averageValue -Force

                if ($metricName -eq "cpu_percent") {
                    $averageValue = $metricsData.cpu_percent
                    $averageValue = [math]::Round($averageValue, 3)
                }
                if ($metricName -eq "storage_percent") {
                    
                    $averageValue = $metricsData.storage_percent   
                    
                }
                if ($metricName -eq "sql_instance_memory_percent") {
                    
                    $averageValue = $metricsData.sql_instance_memory_percent
                    $averageValue = [math]::Round($averageValue, 2)  
                    
                }
                if ($metricName -eq "storage" -or $metricName -eq "allocated_data_storage") {
                    
                    $averageValue = ($averageValue / (1024 * 1024))
                    $averageValue = [math]::Round($averageValue, 3)
                }
                
                 
                else {
                    $metricsData | Add-Member -MemberType NoteProperty -Name $metricDisplayName -Value 0 -Force # Set the average to 0 if there are no non-null, non-zero data points
                }

                
            }

            # Add the total count for the current metric to the metricsData object
                
            $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $averageValue -Force
        }

        #Add metrics data to results array
        $resultsArray += $metricsData
    }
    
}

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$outputpath\SQLDatabaseMetricsCount.csv"
 

$resultsArray | Select-Object -Property SubscriptionName, SqlServerName, DatabaseName, ResourceGroupName, @{Name = "Data space allocated (MB)"; Expression = { $_.allocated_data_storage } }, @{Name = "Data space used (MB)"; Expression = { $_.storage } }, @{Name = "Percentage CPU"; Expression = { $_.cpu_percent } }, @{Name = "Storage percent"; Expression = { $_.sql_instance_memory_percent } }, @{Name = "SQL instance memory percent"; Expression = { $_.storage_percent } } | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath"