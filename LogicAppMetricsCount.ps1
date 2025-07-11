<#
This PowerShell script is used to retrieve metrics data for Azure Logic Apps. It takes in two parameters: $subscriptionId and $outputpath. 
The script connects to the specified subscription and sets the subscription context. It then defines a time range and retrieves the details of all Logic Apps. 
For each Logic App, it defines metrics parameters and retrieves metrics data for each metric. 
Finally, it calculates the total count for each metric and adds the total count for each metric to the metricsData object. 
The metrics data is then added to the results array. The script is useful for monitoring the performance of Azure Logic Apps.



#>



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

$LogicApps = Get-AzLogicApp

# Get Logic App details
foreach ($LogicApp in $LogicApps) {
    $logicAppName = $LogicApp.Name
    $resourceGroupName = (Get-AzResource -Name $logicAppName).ResourceGroupName
    $resourceId = $LogicApp.Id

    # Define metrics parameters
    $metricNames = @("TotalBillableExecutions", "RunsCompleted")
    $metricNamespace = "Microsoft.Logic/workflows"
    $aggregationType = "Total"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'subscriptionname'  = $subscriptionName
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

    # Add metrics data to results array
    $resultsArray += $metricsData
}

# Saving results to CSV file (append if the file exists)

$csvFilePath = "$outputpath\LogicappmetricsCount.csv" 
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Host "Results saved to $csvFilePath"