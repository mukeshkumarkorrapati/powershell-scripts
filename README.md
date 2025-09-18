# ⚡ Azure Metrics & Logs PowerShell Scripts

Collection of PowerShell scripts for retrieving and analyzing metrics, logs, and insights from Azure resources. Useful for monitoring, troubleshooting, and reporting outside of the Azure Portal.

---

## 📦 Prerequisites

Install the Az PowerShell module and authenticate to Azure:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
Connect-AzAccount

```

---

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [💡 Usage](#-usage)
- [📦 Scripts Overview](#-scripts-overview)
- [📝 Examples & Output Previews](#-examples--output-previews)
- [🛠️ Requirements](#️-requirements)
- [📬 Feedback & Contributions](#-feedback--contributions)

---

## 🚀 Quick Start

[![Quickstart](https://img.shields.io/badge/Quickstart-Run%20Any%20Script-blue?style=for-the-badge)](#-usage)

Clone or download this repo and run any script directly from your terminal with PowerShell.

> ✅ Ensure you’re logged into Azure via `Connect-AzAccount` before running scripts.

---

## 💡 Usage

Run scripts directly from the repository. All scripts support common parameters like `-ResourceGroup` and `-Verbose`.

```powershell
.\ApplicationInsightsMetrics.ps1
```

### Filter VM Metrics
```powershell
.\FilteredVmmetrics.ps1 -ResourceGroup "MyResourceGroup" -VMName "MyVM01"
```

### Query SQL Database Metrics
```powershell
.\SQLDatabaseMetricsCount.ps1 -Database "MyDB01" -ResourceGroup "MyResourceGroup"
```

### Check Logic App Executions
```powershell
.\LogicAppMetricsCount.ps1 -LogicAppName "MyLogicApp01" -ResourceGroup "MyResourceGroup"
```

### Retrieve All Metrics (Single Subscription)
```powershell
.\AllMetricsDatasinglesub.ps1
```

### Send Custom Logs to Log Analytics
```powershell
.\LogAnalyticsIngestion.ps1 -WorkspaceId "xxxx" -SharedKey "yyyy" -LogType "CustomLog"
```

### Collect Storage Account Transaction Counts
```powershell
.\StorageAccountTransactionsCount.ps1 -StorageAccountName "mystorage01" -ResourceGroup "MyResourceGroup"
```

---

## 📦 Scripts Overview

| Script | Purpose |
|--------|---------|
| `ApplicationInsightsMetrics.ps1` | Fetch metrics from Application Insights resources |
| `FilteredVmmetrics.ps1` | Retrieve filtered performance metrics for a specific VM |
| `SQLDatabaseMetricsCount.ps1` | Query DTU/CPU/Storage metrics for SQL DB |
| `LogicAppMetricsCount.ps1` | Count successful/failed runs for a Logic App |
| `AllMetricsDatasinglesub.ps1` | Export all available metrics across all resources in subscription |
| `LogAnalyticsIngestion.ps1` | Ingest custom logs into Azure Log Analytics workspace |
| `StorageAccountTransactionsCount.ps1` | Count transactions (read/write) for a storage account |

---

## 📝 Examples & Output Previews

<details>
<summary>▶️ Example: Filtered VM Metrics Output</summary>

```json
{
  "Time": "2024-06-05T10:00:00Z",
  "Metric": "Percentage CPU",
  "Value": 42.3,
  "Unit": "Percent"
}
```

</details>

<details>
<summary>▶️ Example: SQL Database Metrics Output</summary>

```plaintext
Database: MyDB01
DTU Usage: 78%
Storage Used: 12.4 GB / 250 GB
Longest Query: 2.4s
```

</details>

<details>
<summary>▶️ Example: Logic App Run Count</summary>

```plaintext
Logic App: MyLogicApp01
Runs (Last 24h): 142
Success: 138
Failed: 4
Avg Duration: 872ms
```

</details>

---

## 🛠️ Requirements

- PowerShell 5.1 or later (or PowerShell 7+)
- Azure PowerShell module (`Az`)
- Permissions to read metrics from target Azure resources
- For Log Analytics ingestion: Workspace ID + Primary/Secondary Key

> 💡 Already covered in [Prerequisites](#-prerequisites) — no need to reinstall if done earlier.

---

## 📬 Feedback & Contributions

Found a bug? Want a new feature? Open an [Issue](../../issues) or submit a [Pull Request](../../pulls)!

---
