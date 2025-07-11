#Connect-AzAccount -SubscriptionId "54586d14-94a9-4e93-8253-5da2f7f6afcf" -TenantId "6de69d54-d6b2-4e3b-abcc-3d8be186b46e"

# Replace these with your actual values
$subscriptionId = "54586d14-94a9-4e93-8253-5da2f7f6afcf"
$resourceGroupName = "rg-medcan-qa-canadacentral-001"
$appInsightsName = "medcan-integration-qa"
$kqlQuery = @"
exceptions
| where timestamp > ago(3d)  // Time filter
| where client_Type != "Browser"  // Exclude browser requests
| where operation_Name == "SalesforceInvoiceChanged_CreateOrUpdateInvoiceInWorkday"  // Specific operation
| where not(outerMessage has "Exception while executing function: SalesforceInvoiceChanged_CreateOrUpdateInvoiceInWorkday")
| project timestamp, cloud_RoleName,operation_Name, outerMessage    // Select relevant columns including exception details
| order by timestamp desc  // Order by timestamp
"@  # Your KQL query
$apiVersion = "2018-04-20"  # API version for querying Application Insights
$accessToken = (Get-AzAccessToken).Token  # Use your Azure credentials

# Construct the URL for querying Application Insights
$url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/microsoft.insights/components/$appInsightsName/query?api-version=$apiVersion"

# Define the body with the KQL query
$body = @{
    "query" = $kqlQuery
} | ConvertTo-Json

# Send the request to the REST API
$response = Invoke-RestMethod -Uri $url -Method Post -Body $body -Headers @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

# Check if the response contains results
if ($response.tables -and $response.tables.Count -gt 0) {
    # Get the primary result table
    $primaryResult = $response.tables[0]

    # Extract column names and rows
    $columns = $primaryResult.columns
    $rows = $primaryResult.rows

    # Display the results in a readable format
    $columnNames = $columns | ForEach-Object { $_.name }
    $formattedOutput = $rows | ForEach-Object { 
        $row = $_
        $rowObject = [PSCustomObject]@{}
        for ($i = 0; $i -lt $columnNames.Count; $i++) {
            $rowObject | Add-Member -MemberType NoteProperty -Name $columnNames[$i] -Value $row[$i]
        }
        $rowObject
    }
    # Define the path to the CSV file
    $csvFilePath = "C:\Output.csv"  # Change this to your desired output path

    # Export the results to a CSV file
    $formattedOutput | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8

}
else {
    Write-Host "No results found for the query."
}
