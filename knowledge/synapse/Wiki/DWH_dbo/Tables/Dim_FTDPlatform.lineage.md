# Column Lineage: DWH_dbo.Dim_FTDPlatform

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_FTDPlatform` |
| **UC Target** | `bi_db.bronze_moneybusdb_dictionary_accounttypes` (bronze layer; DWH target TBD) |
| **Primary Source** | `MoneyBusDB.Dictionary.AccountTypes` (`MoneyBusDB`) |
| **ETL SP** | None - static table, one-time manual load |
| **Secondary Sources** | BI_DB_dbo.External_MoneyBusDB_Dictionary_AccountTypes (intermediate read path) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
MoneyBusDB.Dictionary.AccountTypes  [moneybus production server]
  |
  | Generic Pipeline (daily Override, 1440 min)
  v
Bronze/MoneyBusDB/Dictionary/AccountTypes/  [Data Lake]
  |
  | External Table (Synapse reads parquet)
  v
BI_DB_dbo.External_MoneyBusDB_Dictionary_AccountTypes
  |
  | BI_DB_dbo.V_Dim_FTDPlatform (CASE expression renames FTDPlatformID->Name)
  |
  | [ONE-TIME MANUAL LOAD - no active ETL SP]
  v
DWH_dbo.Dim_FTDPlatform  [static, 4 rows]
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| FTDPlatformID | MoneyBusDB.Dictionary.AccountTypes | FTDPlatformID | passthrough | PK in both source and DWH. Same name. |
| FTDPlatformName | MoneyBusDB.Dictionary.AccountTypes | Name | rename | Source column is `Name` (nvarchar(4000)); DWH renames to `FTDPlatformName` varchar(50). Values: TradingPlatform/Options/eMoney/MoneyFarm. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **Total** | 2 |

## Lost / Added Columns

**Lost from production** (in source, not in DWH):
- None identified — source has 2 cols (FTDPlatformID, Name), DWH has 2 cols

**Added in DWH** (DWH-only):
- None — no ETL-derived columns added
