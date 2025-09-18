Azure Metrics & Logs PowerShell Scripts


Collection of PowerShell scripts for retrieving and analyzing metrics, logs, and insights from Azure resources. Useful for monitoring, troubleshooting, and reporting outside of the Azure Portal.

Azure PowerShell Docs

Az PowerShell Module

Usage

Install Azure PowerShell

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force


Authenticate to Azure

Connect-AzAccount


Run scripts from this repository.

Scripts
<details> <summary>🔹 Application Insights</summary>
Script	Purpose
Appinsightslogs.ps1	Queries logs from Application Insights
ApplicationInsightsMetrics.ps1	Fetches Application Insights metrics
FilteredApplicationInsightsMetrics.ps1	Retrieves filtered Application Insights metrics
</details> <details> <summary>🔹 Virtual Machines (VMs)</summary>
Script	Purpose
VMmetric.ps1	Pulls general VM performance metrics
VMmetric CPU Max.ps1	Extracts maximum CPU usage metrics for VMs
FilteredVmmetrics.ps1	Retrieves filtered VM metrics
</details> <details> <summary>🔹 Logic Apps</summary>
Script	Purpose
LogicAppMetricsCount.ps1	Collects execution metrics for Logic Apps
FilteredLogicAppMetricsCount.ps1	Retrieves filtered Logic App metrics
</details> <details> <summary>🔹 SQL Databases</summary>
Script	Purpose
SQLDatabaseMetricsCount.ps1	Collects SQL Database performance metrics
</details> <details> <summary>🔹 Storage Accounts</summary>
Script	Purpose
StorageMetricsCount.ps1	Retrieves general Azure Storage metrics
FilteredStorageMetricsCount.ps1	Fetches filtered metrics for Storage Accounts
StorageAccountTransactionsCount.ps1	Collects transaction counts for Storage Accounts
</details> <details> <summary>🔹 Log Analytics</summary>
Script	Purpose
LogAnalyticsIngestion.ps1	Sends custom logs into Log Analytics
Loganalyticsinsights.ps1	Queries insights from Log Analytics
</details> <details> <summary>🔹 General / All Metrics</summary>
Script	Purpose
AllMetricsData.ps1	Collects all available Azure metrics across resources
AllMetricsDatasinglesub.ps1	Retrieves all metrics from a single subscription
</details>
Examples
Run a script directly
.\ApplicationInsightsMetrics.ps1

Filter VM metrics
.\FilteredVmmetrics.ps1 -ResourceGroup "MyResourceGroup" -VMName "MyVM01"

Query SQL Database metrics
.\SQLDatabaseMetricsCount.ps1 -Database "MyDB01" -ResourceGroup "MyResourceGroup"

Check Logic App executions
.\LogicAppMetricsCount.ps1 -LogicAppName "MyLogicApp01" -ResourceGroup "MyResourceGroup"

Sample Outputs
Application Insights Logs
Timestamp            Message                                Severity
-------------------  -------------------------------------  --------
2025-09-17T12:40:00  GET /api/orders returned 200 in 110ms  Information
2025-09-17T12:41:05  POST /api/orders failed (500)          Error

VM Metrics (CPU)
TimeStamp            Average CPU (%)   Max CPU (%)
-------------------  ----------------  -----------
2025-09-17T12:00:00  22.4              40.1
2025-09-17T12:05:00  35.9              68.2

SQL Database Metrics
TimeStamp            DTU %   CPU %   Data IO %   Log IO %
-------------------  ------  ------  ----------  --------
2025-09-17T12:00:00  35      20      10          5
2025-09-17T12:05:00  60      40      30          10

Contributing

Pull requests are welcome!
Fork the repo, add new scripts, or improve existing ones.

License

Licensed under the MIT License
