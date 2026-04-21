# EXW_dbo.Staking_ETH_Rewards_Parameters — Column Lineage

**Generated**: 2026-04-20  
**Object Type**: Table  
**Schema**: EXW_dbo  
**ETL Mechanism**: Unknown — no writer SP found in SSDT repo. Table appears manually maintained or populated via a decommissioned historical pipeline. All rows are frozen since 2023-06-05 (staking program ended May 2023).

## ETL Pipeline Summary

```
WalletDB.Staking (source — mechanism unknown)
  |-- Unknown ETL / Manual insert --|
  v
EXW_dbo.Staking_ETH_Rewards_Parameters (26 rows, frozen 2023-05-10)
  |-- No Generic Pipeline (not in mapping) --|
  v
UC Target: _Not_Migrated (parameter/reference table, no Gold layer target)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | ID | None (IDENTITY) | — | IDENTITY(1,1) auto-generated in Synapse (gaps due to parallel insert — IDs: 42, 102, 162...) | Tier 4 |
| 2 | Rewards | Unknown | — | Total ETH rewards distributed per staking period month (in ETH, not USD) | Tier 4 |
| 3 | StakingStartDate | Unknown | — | First day of the ETH staking period covered by this parameter row | Tier 4 |
| 4 | StakingEndDate | Unknown | — | Last day of the ETH staking period (note: May 2023 row ends 2023-05-10, not month-end — program ended) | Tier 4 |
| 5 | MinimumDays | Unknown | — | Minimum staking days required (always 0 in all 26 rows) | Tier 4 |
| 6 | IsActive | Unknown | — | Active flag: all rows = 0 (all periods closed; program ended May 2023) | Tier 4 |
| 7 | UpdateDate | Unknown | — | Timestamp when this parameter row was last written | Tier 4 |
| 8 | YieldInDecimal | Unknown | — | Monthly ETH staking yield as decimal fraction (NULL for 2 earliest rows Jun 2021; range 0.0011–0.0053) | Tier 4 |

## Upstream Wiki Search Result

No upstream wiki found. EXW_dbo.Staking_ETH_Rewards_Parameters is a DWH-specific historical parameter table with no direct equivalent in WalletDB wiki (WalletDB.Staking.StakingRewards tracks per-user monthly rewards, not aggregate pool parameters).

## UC Target

`_Not_Migrated` — This is a historical/frozen reference table. No Gold layer UC target identified in generic pipeline mapping.
