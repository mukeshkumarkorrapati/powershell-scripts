<#
.SYNOPSIS
    This PowerShell script is used to retrieve metrics data for Azure Resources Storage Accounts, Log Anlaytics, LogicApp, Resource Count, Virtual Machine, Activity Logs, SQL Databses,
    Application Insights.

    This Scripts run locally on our local machine PowerShell/PowerShell ISE.

.DESCRIPTION

Usage : .\AllMetrics.ps1

Example 
         If for all subscriptions
         .\AllMetrics.ps1

Example
         If for single Subcription
         .\AllMetrics.ps1 -$subscriptionId "subscriptionId"

         where we need to comment out lines ($subscriptions = Get-AzSubscription) and (foreach ($subscription in $subscriptions) {) and } at line 716
        
.NOTES
     Organisation  -   Optimus Information Inc
     Year          -   2024
     Author        -   Mukesh Kumar Korrapati
     Owner         -   MSP
#>


param(
    $subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252"
    
)

#$subscriptionId = "3066bdd3-7f7c-4ebb-b9c2-062e937fb252" 

#Connect-AzAccount

Write-Host "Authenticating to Azure subscription... " -ForegroundColor Cyan

#Get all subscriptions

Set-AzContext -SubscriptionId $subscriptionId

# Get current subscription name
$subscriptionname = (Get-AzContext).Subscription.Name
$tenantname = "Optimus Information"

Write-Host "Exporting all metrics for the subscription '$subscriptionName'" -ForegroundColor Cyan

Write-Host "........Take a small break as it takes around 15 minutes to complete for each subscription......." -ForegroundColor Magenta


# Create a folder for the subscription if it doesn't exist
[string]$subscriptionName = $subscriptionname -replace '[^a-zA-Z0-9.-]', '_'
$folderPath = "$tenantname"
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath
}

$Path = Get-Location

# Define time range for the last 24 hours
$timeFrame = (Get-Date).AddDays(-1)
$startDate = (Get-Date).AddDays(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

#................. 1. Resource Type Counts .....................

Write-Host "Getting All resources count by ResourceType" -ForegroundColor Cyan
$resources = Get-AzResource
$resources | ForEach-Object {
    $_.ResourceType = $_.ResourceType -replace '.*/', ''
    return $_
} | Group-Object ResourceType | ForEach-Object {
    [PSCustomObject]@{
        'subscriptionname' = $subscriptionname
        'ResourceType'     = $_.Name
        'Count'            = $_.Count
    }
} | Export-Csv -Path "$folderPath\AzureResourcesCount.csv" -NoTypeInformation
Write-Host "Resource count by Resource type saved to '$folderPath\AzureResourcesCount.csv'"  -ForegroundColor Yellow

# ..................2. Log Analytics Ingestion ..................

Write-Host "Getting Log Analytics Ingestion data for Log Analytics Workspaces..." -ForegroundColor Cyan
$workspaces = Get-AzOperationalInsightsWorkspace
$results = @()

foreach ($workspace in $workspaces) {
    $workspaceId = $workspace.CustomerId
    $resourceGroupName = $workspace.ResourceGroupName
    $query = @"
    Usage
    | where TimeGenerated >= ago(24h)
    | summarize IngestionVolumeMB = sum(Quantity)
    | project IngestionVolumeGB = round(IngestionVolumeMB, 3)
    | order by IngestionVolumeGB desc
"@

    $queryResult = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $query -Verbose

    if ($queryResult.Results) {
        foreach ($resultRow in $queryResult.Results) {
            $roundedVolumeGB = [math]::Round($resultRow.IngestionVolumeGB, 3)
            $result = [PSCustomObject]@{
                'Subscriptionname'      = $subscriptionname
                'WorkspaceName'         = $workspace.Name
                'ResourceGroupName'     = $resourceGroupName
                'Ingestion Volume (MB)' = $roundedVolumeGB
            }
            $results += $result
        }
    }
    else {
        Write-Host "No results found for $($workspace.Name)."
    }
}

# Save results to CSV
$csvFilePath = "$folderPath\LogAnalyticsworkspaceIngestion.csv" 
$results | Export-Csv -Path $csvFilePath -NoTypeInformation
Write-Host "Results saved to $csvFilePath for LogAnalytics Ingestion" -ForegroundColor Yellow

# .................3. VM Metrics Insights ...................

# Initialize an empty array to store results
$resultsArray = @()

Write-Host "Getting Virtual machines Metrics for all Virtual machines's in the Subscription '$subscriptionName'" -ForegroundColor Cyan

# Get current subscription name
$subscriptionName = (Get-AzContext).Subscription.Name

# Get all virtual machines in the subscription
$virtualMachines = Get-AzVM

# Get metrics data for each virtual machine
foreach ($vm in $virtualMachines) {
    $resourceId = $vm.Id
    $vmName = $vm.Name
    $resourceGroupName = $vm.ResourceGroupName
    $status = (Get-AzVM -Name $vmName -Status)
    $vmstatus = $status.PowerState

    # Define metrics parameters
    $metricNames = @("Percentage CPU", "Available Memory Bytes", "Disk Write Operations/Sec")
    $metricNamespace = "Microsoft.Compute/virtualMachines"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'subscriptionname'  = $subscriptionname
        'VMName'            = $vmName
        'ResourceGroupName' = $resourceGroupName
        'PowerState'        = $vmstatus
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

                $convertedValue = [math]::Round($averagediskoperations, 2)
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

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$folderPath\VMMetric.csv"
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Results saved to $csvFilePath for VMMetric" -ForegroundColor Yellow


Write-Host "........Still 10 more minutes to complete for the subscription $subscriptionName ......." -ForegroundColor Red

# ....................4. Storage Metrics....................

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

Write-Host "........Still 5 more minutes to complete ......." -ForegroundColor Red


#...................5. AppInsights Metrics.........................

# Initialize an empty array to store results
$resultsArray = @()
Write-Host "Getting AppInsights Metrics for all App services's in the Subscription '$subscriptionName'" -ForegroundColor Cyan

$applicationInsightsResources = Get-AzResource -ResourceType "microsoft.insights/components"

# Get Appinsights details
foreach ($applicationInsightsResource in $applicationInsightsResources) {

    $applicationInsightsname = $applicationInsightsResource.Name
    $resourceGroupName = $applicationInsightsResource.ResourceGroupName
    $resourceId = $applicationInsightsResource.ResourceId

    # Define metrics parameters
    $metricNames = @("requests/failed", "availabilityResults/availabilityPercentage")
    $metricNamespace = "microsoft.insights/components"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'SubscriptionName'  = $Subscriptionname
        'AppInsightsname'   = $applicationInsightsname
        'ResourceGroupName' = $resourceGroupName
        'requests/failed'   = $null
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
            #Write-Host "Error retrieving metric $metricName for storage account $storageAccountName"
        }
    }

    # Add metrics data to results array only if there are failed runs
    if ($metricsData.'requests/failed' -gt 0) {
        $resultsArray += $metricsData
    }
}

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$folderPath\ApplicationInsightsMetrics.csv"
$resultsArray | Select-Object -Property  SubscriptionName, AppInsightsname, ResourceGroupName, requests/failed | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath for all Application insights in the subscription" -ForegroundColor Yellow

#....................6.SQL Database's metrics....................

# Initialize an empty array to store results
$resultsArray = @()

$subscriptionName = (Get-AzContext).Subscription.Name
Write-Host "Getting SQL Database Metrics for all SQL Database server's in the Subscription '$subscriptionName'" -ForegroundColor Cyan

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
        $metricNames = @("allocated_data_storage", "storage", "cpu_percent", "sql_instance_memory_percent", "storage_percent")
        $metricNamespace = "Microsoft.Sql/servers/databases"

        # Initialize an object to store metrics data
        $metricsData = [PSCustomObject]@{
            'SubscriptionName'  = $subscriptionname
            'SqlServerName'     = $sqlServerName
            'DatabaseName'      = $databaseName
            'ResourceGroupName' = $resourceGroupName
        }

        # Get metrics data for each metric
        foreach ($metricName in $metricNames) {

            $sqlMetric = Get-AzMetric -ResourceId $databaseResourceId -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType Average -DetailedOutput -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
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
                    $averageValue = [math]::Round($averageValue, 2)
                }
                if ($metricName -eq "storage_percent") {
                    
                    $averageValue = $metricsData.storage_percent   
                    
                }

            }
                 
            else {
                $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value 0 -Force # Set the average to 0 if there are no non-null, non-zero data points
            }

            # Add the total count for the current metric to the metricsData object
                
            $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $averageValue -Force
        }
        # Add metrics data to results array only if there are failed runs
        if ($metricsData.storage -eq 0 -or $metricsData.storage_percent -gt "50") {
            $resultsArray += $metricsData
        }
    }
    
}

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$folderPath\SQLDatabaseMetrics.csv"
$resultsArray | Select-Object -Property SubscriptionName, SqlServerName, DatabaseName, ResourceGroupName, @{Name = "Data space allocated (MB)"; Expression = { $_.allocated_data_storage } }, @{Name = "Data space used (MB)"; Expression = { $_.storage } }, @{Name = "Percentage CPU"; Expression = { $_.cpu_percent } }, @{Name = "SQL instance memory percent"; Expression = { $_.sql_instance_memory_percent } }, @{Name = "Data Space Used percent"; Expression = { $_.storage_percent } } | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath for SQL Database Metrics" -ForegroundColor Yellow

#...............7. Logic App Metrics................

# Initialize an empty array to store results
$resultsArray = @()

Write-Host "Getting LogicApp Metrics for all LogicApp's in the Subscription '$subscriptionName'" -ForegroundColor Cyan

$LogicApps = Get-AzLogicApp

# Get Logic App details
foreach ($LogicApp in $LogicApps) {
    $logicAppName = $LogicApp.Name
    $resourceGroupName = (Get-AzResource -Name $logicAppName).ResourceGroupName
    $resourceId = $LogicApp.Id

    # Define metrics parameters
    $metricNames = @("TotalBillableExecutions", "RunsCompleted", "RunsFailed")
    $metricNamespace = "Microsoft.Logic/workflows"
    $aggregationType = "Total"

    # Create a new metricsData object for each Logic App
    $metricsData = [PSCustomObject]@{
        'SubscriptionName'  = $subscriptionname
        'LogicAppName'      = $logicAppName
        'ResourceGroupName' = $resourceGroupName
    }

    # Get metrics data for each metric
    foreach ($metricName in $metricNames) {
        # Get Logic App metrics
        $logicAppMetric = Get-AzMetric -ResourceId "$resourceId" -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType $aggregationType -DetailedOutput -WarningAction SilentlyContinue
        $logicAppMetrics = $logicAppMetric.Data

        # Calculate the total count for the current metric
        $totalMetricCount = 0
        foreach ($dataPoint in $logicAppMetrics) {
            $totalMetricCount += $dataPoint.Total
        }

        # Add the total count for the current metric to the metricsData object
        $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value $totalMetricCount -Force
    }

    # Add metrics data to results array only if there are failed runs
    if ($metricsData.RunsFailed -gt 0) {
        $resultsArray += $metricsData
    }
}

# Saving results to CSV file (append if the file exists)

$csvFilePath = "$folderPath\LogicappmetricsCount.csv" 
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath for all Logic App Metrics" -ForegroundColor Yellow


#...............8. Activity Logs which has Deletion operation ....................

# Initialize an empty array to store results
$resultsArray = @()

Write-Host "Getting all Activity Logs which has deletion operation in the Subscription '$subscriptionname'" -ForegroundColor Cyan

# Filter log entries for the "delete" operation in the last one day
$activitylogs = Get-AzActivityLog -StartTime $StartDate -EndTime $EndDate -Status "Succeeded" -WarningAction SilentlyContinue | Where-Object Category -EQ "Administrative"

foreach ($activityLog in $activitylogs) {

    if ($activityLog.OperationName -match "Delete") {

        $subscriptionId = $activityLog.Properties[0].Value
        $resourceGroupName = $activityLog.ResourceGroupName
        $resourceName = $activityLog.ResourceId -split '/' | Select-Object -Last 1

        # Get the UPN ID of the owner based on caller
        $caller = $activityLog.Caller
        $ResourceType = $activityLog.ResourceId -split '/providers/', 3 | Select-Object -Last 1
        $ResourceTypevalue = $ResourceType -split '/' | Select-Object -Last 2
        $ResourceTypename = $ResourceTypevalue -split '/' | Select-Object -First 1
        $timestamp = $activityLog.EventTimestamp
        $operationname = $activityLog.OperationName
        $Eventdescription = "Deletion"

        # Add entry to results array
        $resultsArray += [PSCustomObject]@{
            SubscriptionName  = $subscriptionname
            ResourceName      = $resourceName
            ResourceGroupName = $resourceGroupName
            ResourceType      = $ResourceTypeName
            Eventdescription  = $Eventdescription
            Timestamp         = $timestamp
            EventInitiatedBy  = $caller

        }

    }


}

# Check if $resultsArray is empty
if ($resultsArray.Count -eq 0) {

    $csvFileName = "$folderPath\Deletionactivitylogs.csv"
    $resultsArray | Export-Csv -Path $csvFileName -NoTypeInformation

    Write-Host "No data found for Activity logs with deletion operation. CSV file not generated." -ForegroundColor Yellow
}
else {
    # Export filtered entries to a CSV file
    $csvFileName = "$folderPath\Deletionactivitylogs.csv"
    $resultsArray | Export-Csv -Path $csvFileName -NoTypeInformation
    Write-Host "Results saved to $csvFileName for Activity logs with deletion operation" -ForegroundColor Yellow
}


<#................9. Azure Advisories...................................

Write-Host "Pulling Azure Advisories to the subscription $subscriptionname" -ForegroundColor Cyan


Get-AzAdvisorRecommendation | Select-Object Category, Id, Impact, ImpactedField, ImpactedValue, ResourceGroupName, ShortDescriptionProblem, ShortDescriptionSolution | Export-Csv -Path "$folderPath\AzureAdvisories.csv" -NoTypeInformation

Write-Host "Results saved to $csvFilePath for Azure Advisories" -ForegroundColor Yellow #>


#...............10. To merge all files in one file .....................

[string]$date = $(get-date -f dd-MM-yyyy)

Write-Host "Merging all metrics in one CSV file" -ForegroundColor Green
Write-Host "last few seconds" -ForegroundColor Green

# Set the path to the folder containing CSV files
$csvfolderPath = "$Path\$folderPath"

# Get all CSV files in the folder
$csvFiles = Get-ChildItem -Path $csvfolderPath -Filter *.csv

# Create a new Excel COM object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false  # Set to $true if you want to see Excel in action

$filename = "$subscriptionName-HealthReport-$date.xlsx"

# Set the full output file path
$outputFilePath = Join-Path $csvfolderPath $filename

# Check if the output Excel file already exists, and delete it if it does
if (Test-Path $outputFilePath) {
    Remove-Item $outputFilePath -Force
}

# Create a new Excel workbook
$workbook = $excel.Workbooks.Add()

# Loop through each CSV file
foreach ($csvFile in $csvFiles) {
    # Get CSV data with headers
    $csvData = Import-Csv -Path $csvFile.FullName

    # Check if the sheet already exists, if not, add a new sheet
    $worksheet = $workbook.Sheets | Where-Object { $_.Name -eq $csvFile.BaseName }

    if (-not $worksheet) {
        $worksheet = $workbook.Worksheets.Add()
        $worksheet.Name = $csvFile.BaseName
    }

    # Check if there's any data to add
    if ($csvData) {
        # Find the last used row in the sheet
        $lastRow = $worksheet.UsedRange.Rows.Count + 1
        if ($lastRow -eq 1) {
            $lastRow = 2  # Skip header row if it already exists
        }

        # Populate the sheet with CSV data, including headers
        foreach ($entry in $csvData) {
            $col = 1
            foreach ($property in $entry.PSObject.Properties) {
                # Write headers in the first row only if it's a new sheet
                if ($lastRow -eq 2) {
                    $worksheet.Cells.Item($lastRow - 1, $col).Value2 = $property.Name
                }

                # Write values in subsequent rows
                $worksheet.Cells.Item($lastRow, $col).Value2 = $property.Value
                $col++
            }
            $lastRow++
        }
    }
    else {
        # If the CSV file has no data, create a worksheet with the file name and a message indicating that no data is available
        $worksheet.Cells.Item(1, 1).Value2 = "No data available"
    }
}

# Remove the last sheet (Sheet1) if it's empty
$lastSheet = $workbook.Sheets | Where-Object { $_.Name -eq "Sheet1" }
if ($lastSheet -ne $null -and $lastSheet.UsedRange.Rows.Count -eq 1) {
    $workbook.Sheets.Item($lastSheet.Name).Delete()
}

# Save the workbook
$workbook.SaveAs($outputFilePath, 51) # 51 is for Excel.xlOpenXMLWorkbook, which corresponds to the XLSX format
$excel.Visible = $true  # Set to $false if you don't want to see Excel in action

# Close Excel
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)

# Remove original CSV files
foreach ($csvFile in $csvFiles) {
    Remove-Item $csvFile.FullName -Force
}

Write-Host "Combined CSV file saved to: $outputFilePath" -ForegroundColor Yellow

Write-Host "........     Finally     ......." -ForegroundColor Red
Write-Host "........      It's       ......." -ForegroundColor White
Write-Host "........    Completed    ......." -ForegroundColor Green