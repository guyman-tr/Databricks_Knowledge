# BI_DB_dbo.BI_DB_AccountClosure — Column Lineage

**Generated**: 2026-04-21 | **Schema**: BI_DB_dbo | **Writer SP**: SP_AccountClosure  
**Load pattern**: TRUNCATE + INSERT daily | **Row count**: 965,173 (as of 2026-04-11)  
**UC Target**: _Not_Migrated

---

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| DWH_dbo.Fact_SnapshotCustomer | Table | Primary source — daily snapshot of all customers with pending closure status (PendingClosureStatusID ≠ 1, IsValidCustomer=1) |
| DWH_dbo.Dim_PendingClosureStatus | Table | Status name and ID lookup (PendingClosureStatusID) |
| DWH_dbo.Dim_PlayerLevel | Table | Loyalty tier name (PlayerLevelID) |
| DWH_dbo.Dim_Regulation | Table | Regulation name (RegulationID → dr.ID) |
| DWH_dbo.Dim_Country | Table | Country name (CountryID) |
| DWH_dbo.Dim_Date | Table | Full date from DateKey (for PendingClosureChangeDate) |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Table | Financial aggregates per CID at @ddINT (TotalDeposits, TotalCashouts, PnL_Total, Equity, TotalCoFee, Revenue_Total) |

---

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer
  [Filter: PendingClosureStatusID != 1 (not Normal), IsValidCustomer=1, DateRangeID covers @dd]
  + History of closure status changes (first occurrence per status per CID)
  → #pendingClosure: most recent non-Normal closure status per CID (ROW_NUMBER DESC by DateID)
  +
DWH_dbo.Dim_PlayerLevel, Dim_Regulation, Dim_Country, Dim_PendingClosureStatus, Dim_Date
  +
BI_DB_dbo.BI_DB_CID_DailyPanel_FullData (financial snapshot at @ddINT)
  |-- SP_AccountClosure @dd (TRUNCATE+INSERT daily, SB_Daily, Priority 20) --|
  v
BI_DB_dbo.BI_DB_AccountClosure (965,173 rows, ROUND_ROBIN CLUSTERED(Date))
  |-- _Not_Migrated (no UC target) --|
```

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (RealCID = Customer.CustomerStatic.CID) | Tier 1 |
| 2 | Date | Parameter | @dd | Run date parameter directly inserted | Tier 2 |
| 3 | DateID | Parameter | @dd | CAST(CONVERT(VARCHAR(8), @dd, 112) AS INT) — YYYYMMDD int | Tier 2 |
| 4 | Tier | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID from Fact_SnapshotCustomer | Tier 2 |
| 5 | PendingClosureStatusName | DWH_dbo.Dim_PendingClosureStatus | PendingClosureStatusName | Most recent non-Normal closure status (ROW_NUMBER DESC by DateID) | Tier 2 |
| 6 | PendingClosureChangeDateID | DWH_dbo.Fact_SnapshotCustomer | DateRangeID | DateID (YYYYMMDD int) of first occurrence of current closure status | Tier 2 |
| 7 | PendingClosureChangeDate | DWH_dbo.Dim_Date | FullDate | JOIN on DateKey=PendingClosureChangeDateID | Tier 2 |
| 8 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on dr.ID = RegulationID from Fact_SnapshotCustomer | Tier 2 |
| 9 | Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID from Fact_SnapshotCustomer | Tier 2 |
| 10 | TotalDeposits | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | TotalDeposits | Passthrough JOIN (CID + DateID = @ddINT) | Tier 2 |
| 11 | TotalCashouts | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | TotalCashouts | Passthrough JOIN | Tier 2 |
| 12 | PnL_Total | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | PnL_Total | Passthrough JOIN | Tier 2 |
| 13 | Equity | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Equity | Passthrough JOIN | Tier 2 |
| 14 | TotalCoFee | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | TotalCoFee | Passthrough JOIN | Tier 2 |
| 15 | Revenue_Total | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Revenue_Total | Passthrough JOIN | Tier 2 |
| 16 | UpdateDate | Hardcoded | — | GETDATE() at SP execution time | Tier 2 |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 1 | CID |
| Tier 2 | 15 | Date, DateID, Tier, PendingClosureStatusName, PendingClosureChangeDateID, PendingClosureChangeDate, Regulation, Country, TotalDeposits, TotalCashouts, PnL_Total, Equity, TotalCoFee, Revenue_Total, UpdateDate |
| **Total** | **16** | |
