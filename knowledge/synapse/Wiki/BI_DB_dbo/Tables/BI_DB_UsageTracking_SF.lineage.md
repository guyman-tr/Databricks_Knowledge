# Column Lineage: BI_DB_dbo.BI_DB_UsageTracking_SF

## Column Mapping

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|-------------|---------------|-----------|-------|
| ID | -- | -- | IDENTITY | Auto-generated surrogate key (not in INSERT) |
| AccountHistoryID | Gold/CRM/UsageTracking (parquet) | AccountHistoryID | passthrough | Salesforce Account History ID (18-char SF ID) |
| AccountID | Gold/CRM/UsageTracking (parquet) | AccountID | passthrough | Salesforce Account ID |
| ActionName | Gold/CRM/UsageTracking (parquet) | ActionName | passthrough | Truncated to varchar(50) from varchar(200) source |
| CreatedByID | Gold/CRM/UsageTracking (parquet) | CreatedByID | passthrough | Salesforce user who created the record |
| CreatedDate_SF | Gold/CRM/UsageTracking (parquet) | CreatedDate_SF | passthrough | Salesforce created timestamp |
| OwnerID | Gold/CRM/UsageTracking (parquet) | OwnerID | passthrough | Salesforce account owner |
| ManagerID | Gold/CRM/UsageTracking (parquet) | ManagerID | passthrough | Internal manager ID |
| CID | Gold/CRM/UsageTracking (parquet) | CID | passthrough | Customer ID mapped from SF Account |
| CreatedDate | Gold/CRM/UsageTracking (parquet) | CreatedDate | function-computed | MIN(CreatedDate) grouped by all other columns (dedup) |
| CreatedByManagerID | Gold/CRM/UsageTracking (parquet) | ManagerID | rename | Duplicated from ManagerID column |
| UpdateDate | -- | -- | ETL-computed | GETDATE() |

## ETL Pipeline

```
Salesforce CRM
  → DLT-CRM pipeline (originally SSIS)
    → ADLS Gold/CRM/UsageTracking/*.parquet
      │
      └─ SP_UsageTracking_SF (no params)
          ├─ COPY INTO #UsageTracking FROM ADLS parquet
          ├─ TRUNCATE TABLE BI_DB_UsageTracking_SF
          └─ INSERT (GROUP BY dedup, MIN(CreatedDate), GETDATE())
```

## Consumers

| Consumer SP | Usage |
|-------------|-------|
| SP_CIDFirstDates | First activity dates per CID |
| SP_AM_Contacted | Account manager contact tracking |
| SP_AM_Portfolio_Summary | Account manager portfolio summary |
| SP_CID_DailyPanel_Club | CID daily panel |
| SP_CIDFunnelFlow | CID funnel flow analysis |
| SP_CopyDailyData | Daily copy aggregation |
| SP_Crypto_Top_1000_List | Top 1000 crypto users |
| SP_Daily_HighCashoutEmailsForManagement | High cashout email alerts |
| SP_HighCOsAndRedeemsWithSF | High cashout/redeem with SF data |
| SP_HighRedeemsApprovalForManagement | High redeem approval reports |
| SP_InvestorReportDetails | Investor report details |
| SP_NewBonusReport | Bonus reporting |
| SP_NewContactActivityPerRep | Per-rep contact activity |
| SP_ReverseCO_Report | Reverse cashout reporting |
| SP_StocksETFs_SignificantAllocation | Stocks/ETFs allocation analysis |
| SP_Copyfunds_SignificantAllocation | Copy funds allocation analysis |
| SP_BI_DB_High_Cashout_Emails_For_Management_Analysis | Management cashout analysis |
