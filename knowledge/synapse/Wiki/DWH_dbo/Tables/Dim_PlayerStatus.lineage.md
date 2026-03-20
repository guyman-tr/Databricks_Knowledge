# Column Lineage: DWH_dbo.Dim_PlayerStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PlayerStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` |
| **Primary Source** | `Dictionary.PlayerStatus` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.PlayerStatus  (15 columns, 15 rows)
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/PlayerStatus/
      |
      v (DWH staging import -- 13 cols loaded)
  DWH_staging.etoro_Dictionary_PlayerStatus
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  DWH_dbo.Dim_PlayerStatus  (15 cols, 16 rows incl. ID=0)
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|------------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PlayerStatusID | Dictionary.PlayerStatus | PlayerStatusID | passthrough | PK in both layers |
| Name | Dictionary.PlayerStatus | Name | passthrough | Status name string |
| IsBlocked | Dictionary.PlayerStatus | IsBlocked | passthrough | 1=account blocked |
| CanEditPosition | Dictionary.PlayerStatus | CanEditPosition | passthrough | Edit existing position permission |
| CanOpenPosition | Dictionary.PlayerStatus | CanOpenPosition | passthrough | Open new position permission |
| CanClosePosition | Dictionary.PlayerStatus | CanClosePosition | passthrough | Close position permission |
| CanDeposit | Dictionary.PlayerStatus | CanDeposit | passthrough | Deposit permission |
| CanRequestWithdraw | Dictionary.PlayerStatus | CanRequestWithdraw | passthrough | Withdrawal request permission |
| CanLogin | Dictionary.PlayerStatus | CanLogin | passthrough | Login permission |
| CanChatAndPost | Dictionary.PlayerStatus | CanChatAndPost | passthrough | Social/chat permission |
| CanBeCopied | Dictionary.PlayerStatus | CanBeCopied | passthrough | Allow others to copy this account |
| DWHPlayerStatusID | -- | -- | ETL-computed | = PlayerStatusID (redundant surrogate); 0 for ID=0 sentinel |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 (active) for all rows |
| UpdateDate | -- | -- | ETL-computed | GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel |
| InsertDate | -- | -- | ETL-computed | GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel |

## Dropped Production Columns (Schema Drift)

| Production Column | Type | Reason Not in DWH |
|------------------|------|-------------------|
| CanCopy | bit | Not loaded by ETL SP -- social trading copy permission dropped |
| GetsInterest | bit | Not loaded -- interest accrual eligibility dropped |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 11 |
| **ETL-computed** | 4 |
| **Dropped from production** | 2 |
| **Total DWH columns** | 15 |
