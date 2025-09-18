Azure Metrics & Logs PowerShell Scripts

This repository contains a collection of PowerShell scripts for retrieving and analyzing metrics, logs, and insights from various Azure resources.
They are useful for monitoring, troubleshooting, and creating custom reports outside of the Azure Portal.

📂 Repository Contents
Script	Description
AllMetricsData.ps1	Collects all available Azure metrics data across resources.
AllMetricsDatasinglesub.ps1	Retrieves all metrics from a single Azure subscription.
Appinsightslogs.ps1	Queries logs from Azure Application Insights.
ApplicationInsightsMetrics.ps1	Fetches metrics from Application Insights.
FilteredApplicationInsightsMetrics.ps1	Retrieves filtered metrics from Application Insights (e.g., specific apps or time ranges).
LogicAppMetricsCount.ps1	Collects execution metrics for Logic Apps.
FilteredLogicAppMetricsCount.ps1	Retrieves filtered metrics for specific Logic Apps.
VMmetric.ps1	Pulls general VM performance metrics.
VMmetric CPU Max.ps1	Extracts maximum CPU usage metrics for VMs.
FilteredVmmetrics.ps1	Retrieves filtered VM metrics (e.g., specific VMs or ranges).
SQLDatabaseMetricsCount.ps1	Collects SQL Database performance metrics.
StorageMetricsCount.ps1	Retrieves general Azure Storage metrics.
FilteredStorageMetricsCount.ps1	Fetches filtered metrics for specific storage accounts.
StorageAccountTransactionsCount.ps1	Collects transaction count metrics for Azure Storage accounts.
LogAnalyticsIngestion.ps1	Sends custom logs into Azure Log Analytics.
Loganalyticsinsights.ps1	Queries insights from Azure Log Analytics.
🚀 Prerequisites

PowerShell 5.1 or later (PowerShell 7 recommended)

Azure PowerShell Module
 (Az module)

Permissions to read metrics and logs from target Azure resources

Install the Az module if not already installed:

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force


Login to your Azure account before running scripts:

Connect-AzAccount

🛠️ Usage

Run any script directly in PowerShell:

.\ApplicationInsightsMetrics.ps1


Some scripts accept parameters (e.g., resource group, subscription, resource name). Example:

.\FilteredVmmetrics.ps1 -ResourceGroup "MyResourceGroup" -VMName "MyVM01"

📊 Use Cases

Monitor VM performance (CPU, memory, etc.)

Track Logic App execution counts

Query Application Insights metrics and logs

Retrieve SQL Database utilization metrics

Analyze Azure Storage transactions

Push custom logs into Log Analytics

⚡ Contributing

Feel free to fork this repo, open issues, and submit pull requests to enhance the scripts or add new resource types.

📜 License

This repository is licensed under the MIT License.
