# Column Lineage: DWH_dbo.Dim_PlayerLevel

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PlayerLevel` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` |
| **Primary Source** | `Dictionary.PlayerLevel` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.PlayerLevel  (13 columns, 7 rows)
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/PlayerLevel/
      |
      v (DWH staging import -- 8 cols loaded)
  DWH_staging.etoro_Dictionary_PlayerLevel
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  DWH_dbo.Dim_PlayerLevel  (12 cols, 8 rows incl. ID=0)
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PlayerLevelID | Dictionary.PlayerLevel | PlayerLevelID | passthrough | PK in both layers |
| Name | Dictionary.PlayerLevel | Name | passthrough | Same name |
| CashoutPendingHours | Dictionary.PlayerLevel | CashoutPendingHours | passthrough | Cashout wait time by tier |
| FromSumLotCount | Dictionary.PlayerLevel | FromSumLotCount | passthrough | Legacy threshold; -1 = disabled for upper tiers |
| ToSumLotCount | Dictionary.PlayerLevel | ToSumLotCount | passthrough | Legacy threshold; -1 = disabled |
| FromSumDeposit | Dictionary.PlayerLevel | FromSumDeposit | passthrough | Legacy threshold; -1 = disabled |
| ToSumDeposit | Dictionary.PlayerLevel | ToSumDeposit | passthrough | Legacy threshold; -1 = disabled |
| Sort | Dictionary.PlayerLevel | Sort | passthrough | Display rank order |
| DWHPlayerLevelID | -- | -- | ETL-computed | = PlayerLevelID (redundant surrogate); 0 for ID=0 sentinel |
| UpdateDate | -- | -- | ETL-computed | GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel |
| InsertDate | -- | -- | ETL-computed | GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 (active) for all rows |

## Dropped Production Columns (Schema Drift)

| Production Column | Type | Reason Not in DWH |
|------------------|------|-------------------|
| IsWalletRedeemAllowed | bit | Not loaded by ETL SP |
| RealizedEquityFrom | int | Not loaded -- primary equity qualification threshold (CRITICAL GAP) |
| RealizedEquityTo | int | Not loaded -- primary equity qualification threshold (CRITICAL GAP) |
| ThresholdPercentToCurrentLevel | int | Not loaded -- downgrade threshold percent |
| DaysInRiskBeforeDowngrade | int | Not loaded -- downgrade grace period |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 8 |
| **ETL-computed** | 4 |
| **Dropped from production** | 5 |
| **Total DWH columns** | 12 |
