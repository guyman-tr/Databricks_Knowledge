# Lineage: BI_DB_dbo.LTV_Conversions_Multipliers_Table

## Source Objects

| # | Source Object | Schema | Type | Relationship |
|---|--------------|--------|------|-------------|
| 1 | Function_Revenue_Total | BI_DB_dbo | Function (TVF) | Revenue metrics (TotalFullCommission, RolloverFee, ConversionFee) for FTD cohort 2019–2021 |
| 2 | Dim_Customer | DWH_dbo | Table (Dimension) | FTD date, IsDepositor, VerificationLevelID, CountryID for customer filtering and joins |
| 3 | Dim_Country | DWH_dbo | Table (Dimension) | MarketingRegionManualName → Region column |
| 4 | BI_DB_CID_MonthlyPanel_FullData | BI_DB_dbo | Table | ClusterDetail + FirstAction at Seniority=1 → First_Cluster derivation |
| 5 | Fact_BillingDeposit | DWH_dbo | Table (Fact) | First-month deposit currency (CurrencyID) → Currency column (USD / Non_USD) |

## Column Lineage

| # | Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------|-----------------|-----------------|-----------|------|
| 1 | Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Passthrough (renamed: dc1.MarketingRegionManualName AS Region, via Dim_Customer.CountryID JOIN) | T1 |
| 2 | First_Cluster | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | ClusterDetail, FirstAction | CASE: ClusterDetail if not NULL; 'No Cluster - Active' if FirstAction not NULL and VerificationLevelID=3; else 'No Cluster - Inactive'. Evaluated at Seniority=1. Aggregated by group. | T2 |
| 3 | Currency | DWH_dbo.Fact_BillingDeposit | CurrencyID | CASE WHEN CurrencyID=1 THEN 'USD' ELSE 'Non_USD'. Most frequent deposit currency in first 30 days after FTD, by AmountUSD descending (ROW_NUMBER=1). NULL rows included as a third bucket. | T2 |
| 4 | TotalFullCommission | BI_DB_dbo.Function_Revenue_Total | Amount (Metric='FullCommission'→'TotalFullCommission') | SUM(Amount) WHERE Metric='TotalFullCommission', grouped by Region/First_Cluster/Currency. Date range 20190101–20241027, OnlyValidCustomers=1. | T2 |
| 5 | RolloverFee | BI_DB_dbo.Function_Revenue_Total | Amount (Metric='RolloverFee') | SUM(Amount) WHERE Metric='RolloverFee', grouped by Region/First_Cluster/Currency | T2 |
| 6 | ConversionFee | BI_DB_dbo.Function_Revenue_Total | Amount (Metric='ConversionFee') | SUM(Amount) WHERE Metric='ConversionFee', grouped by Region/First_Cluster/Currency | T2 |
| 7 | Revenue_LTV_WO_Conversions | BI_DB_dbo.Function_Revenue_Total | Amount | SUM(TotalFullCommission) + SUM(RolloverFee) per group | T2 |
| 8 | Revenue_LTV_Incl_Conversions | BI_DB_dbo.Function_Revenue_Total | Amount | SUM(TotalFullCommission) + SUM(RolloverFee) + SUM(ConversionFee) per group | T2 |
| 9 | Revenue_Change_Percentage | BI_DB_dbo.Function_Revenue_Total | Amount | Revenue_LTV_Incl_Conversions / Revenue_LTV_WO_Conversions − 1; 0 if denominator is 0 | T2 |
| 10 | Clients | DWH_dbo.Dim_Customer | RealCID | COUNT(*) of distinct depositors (FTD 2019–2021) per Region/First_Cluster/Currency group. ISNULL(...,0) for unmatched combinations. | T2 |
| 11 | Revenue_Change_Percentage_Fixed | Multiple | Revenue_Change_Percentage, Region, Clients, First_Cluster, Currency | CASE: cap at 0.1 if >0.1; 0 if USA; region-level fallback if Clients<100; region+currency or region+cluster fallback for NULL dimensions; region-only fallback for double-NULL; else raw Revenue_Change_Percentage | T2 |
| 12 | UpdateDate | — | — | GETDATE() at SP execution time | T2 |

---

*Generated: 2026-04-30*
