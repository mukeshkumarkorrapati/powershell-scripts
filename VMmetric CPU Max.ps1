param(

$subscriptionId = "",
$outputpath = ".\"
)

# connect and Set the subscription context

Connect-AzAccount -SubscriptionId $subscriptionId

Set-AzContext -SubscriptionId $subscriptionId

# Define time range for the last 30 days
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
    $resourceId = $vm.Id
    $vmName = $vm.Name
    $resourceGroupName = $vm.ResourceGroupName
    $status = (Get-AzVM -Name $vmName -Status)
    $vmstatus = $status.PowerState
    $vmsku = $vm.HardwareProfile.VmSize

    # Define metrics parameters
    $metricNames = @("Percentage CPU")
    $metricNamespace = "Microsoft.Compute/virtualMachines"

    # Initialize an object to store metrics data
    $metricsData = [PSCustomObject]@{
        'subscriptionname'  = $subscriptionname
        'VMName'            = $vmName
        'ResourceGroupName' = $resourceGroupName
        'PowerState'        = $vmstatus
        'VMSize'            = $vmsku
    }

    # Get metrics data for each metric
    foreach ($metricName in $metricNames) {

        try {
            $vmMetric = Get-AzMetric -ResourceId $resourceId -StartTime $startDate -EndTime $endDate -MetricNamespace $metricNamespace -MetricName $metricName -AggregationType Maximum -DetailedOutput -WarningAction SilentlyContinue
            $vmMetrics = $vmMetric.Data

            # Calculate the total count for the current metric
            
            $maxCpu = ($vmMetrics | Measure-Object Maximum -Maximum).Maximum

            # Convert "Available Memory Bytes" to GiB
            if ($metricName -eq "Percentage CPU") {
                # Calculate average percentage CPU
                $metricsData | Add-Member -MemberType NoteProperty -Name $metricName -Value ([math]::Round($maxCpu, 2)) -Force
            }
           
        } catch [Microsoft.Azure.Management.Monitor.Models.ErrorResponseException] {
            # Handle error
        } catch {
            # Handle unexpected error
        }
    }

    # Add metrics data to results array
    $resultsArray += $metricsData
}

# Save results to CSV file (overwrite if the file exists)
$csvFilePath = "$outputpath\VMmetricXPUMax.csv"
$resultsArray | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Results saved to $csvFilePath"