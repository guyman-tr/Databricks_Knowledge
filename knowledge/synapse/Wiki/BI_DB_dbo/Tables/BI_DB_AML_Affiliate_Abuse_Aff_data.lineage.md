# Lineage: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data

## Object
- **Schema**: BI_DB_dbo
- **Object**: BI_DB_AML_Affiliate_Abuse_Aff_data
- **Type**: Table
- **Writer SP**: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)
- **UC Target**: Not_Migrated

## ETL Pipeline
```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData (bdmmrd)
  |-- filter: AccountActivated=1, YearMonthID>=202301 ---|
  v
JOIN DWH_dbo.Dim_Affiliate ON AffiliateID
  |-- filter: SubChannelID IN (20,31,39,40,41,42,44) ---|
  v
GROUP BY AffiliateID, Channel, SubChannel, YearMonthID, ContractType, ContractName, Contact
  |-- SUM(SameDayFTD, TotalDeposit, FTDs, Registration, TotalCost, NetRevenues) ---|
  v
#Aff_data (Profitability = NetRevenues - TotalCost, UpdateDate = GETDATE())
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data (37,933 rows, YearMonthID 202301-202412, frozen 2024-12-31)
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| AffiliateID | BI_DB_MarketingMonthlyRawData | AffiliateID | passthrough |
| Channel | BI_DB_MarketingMonthlyRawData | Channel | passthrough |
| SubChannel | BI_DB_MarketingMonthlyRawData | SubChannel | passthrough |
| YearMonthID | BI_DB_MarketingMonthlyRawData | YearMonthID | passthrough (int YYYYMM) |
| ContractType | BI_DB_MarketingMonthlyRawData | ContractType | passthrough |
| ContractName | BI_DB_MarketingMonthlyRawData | ContractName | passthrough |
| SameDayFTD | BI_DB_MarketingMonthlyRawData | SameDayFTD | SUM (ISNULL→0) |
| TotalDeposit | BI_DB_MarketingMonthlyRawData | TotalDeposit | SUM (ISNULL→0) |
| FTDs | BI_DB_MarketingMonthlyRawData | FTD | SUM (ISNULL→0); renamed FTD→FTDs |
| Registration | BI_DB_MarketingMonthlyRawData | Registration | SUM (ISNULL→0) |
| TotalCost | BI_DB_MarketingMonthlyRawData | TotalCost | SUM (ISNULL→0) |
| NetRevenues | BI_DB_MarketingMonthlyRawData | NetRevenues | SUM (ISNULL→0) |
| Profitability | SP computation | NetRevenues, TotalCost | NetRevenues - TotalCost (ISNULL→0) |
| Contact | BI_DB_MarketingMonthlyRawData | Contact | passthrough |
| UpdateDate | ETL metadata | — | GETDATE() |

## Source Objects
- `BI_DB_dbo.BI_DB_MarketingMonthlyRawData` — monthly affiliate performance metrics (primary source)
- `DWH_dbo.Dim_Affiliate` — SubChannelID filter only (not a data source)
