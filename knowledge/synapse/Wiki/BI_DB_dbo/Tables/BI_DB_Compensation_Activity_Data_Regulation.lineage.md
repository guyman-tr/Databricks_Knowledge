# BI_DB_dbo.BI_DB_Compensation_Activity_Data_Regulation — Column Lineage

> Generated: 2026-04-23 | Batch 71

## Object Metadata

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Writer SP | SP_Compensation_Activity_Data |
| Load Pattern | TRUNCATE + INSERT (previous-month full refresh) |
| Population | 7 regulation rows (excludes 'Other'); one row per regulation entity |

## ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionType CategoryID IN 17,18 = PositionOpen/PositionClose)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID: 5,6=Real Stocks/ETF, 10=Real Crypto)
  + DWH_dbo.Dim_Customer (RegulationID + IsValidCustomer)
  + DWH_dbo.Dim_Country (Region = 'eToro' for Internal)
  + DWH_dbo.Dim_ActionType (CategoryID filter)
    → #Positions (RealStocksETFTransactions, CFDTransactions per regulation)
    → #ActiveTraders (COUNT DISTINCT RealCID per regulation)
    → #RealCryptoPositions (COUNT DISTINCT PositionID per regulation)
    → #final (LEFT JOIN, Regulation <> 'Other' filter)
    |-- SP_Compensation_Activity_Data (previous month window) TRUNCATE+INSERT ---|
    v
BI_DB_dbo.BI_DB_Compensation_Activity_Data_Regulation (7 rows, March 2026)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | Regulation | DWH_dbo.Dim_Customer + Dim_Country | RegulationID + Region | CASE expression mapping RegulationID/Region to label; RegulationID IN (10,4) merged as 'ASIC and ASIC&GAML'; Region='eToro'+IsValidCustomer=0 → 'Internal'; 'Other' excluded | Tier 2 — SP_Compensation_Activity_Data |
| 2 | RealStocksETFTransactions | DWH_dbo.Fact_CustomerAction + Dim_Instrument | PositionID | COUNT(*) where InstrumentTypeID IN (5,6) AND IsSettled=1 AND CategoryID IN (17,18) | Tier 2 — SP_Compensation_Activity_Data |
| 3 | CFDTransactions | DWH_dbo.Fact_CustomerAction | PositionID | COUNT(*) where IsSettled=0 AND CategoryID IN (17,18) | Tier 2 — SP_Compensation_Activity_Data |
| 4 | ActiveTraderCount | DWH_dbo.Fact_CustomerAction | RealCID | COUNT DISTINCT RealCID where CategoryID IN (17,18) | Tier 2 — SP_Compensation_Activity_Data |
| 5 | RealCryptoPositionCount | DWH_dbo.Fact_CustomerAction + Dim_Instrument | PositionID | COUNT DISTINCT PositionID where InstrumentTypeID=10 AND IsSettled=1 AND CategoryID IN (17,18) | Tier 2 — SP_Compensation_Activity_Data |
| 6 | UpdateDate | ETL | GETDATE() | Runtime timestamp | Propagation |
