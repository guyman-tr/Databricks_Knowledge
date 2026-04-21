# EXW_dbo.Staking_WalletUserRewards — Column Lineage

**Generated**: 2026-04-20  
**Object Type**: Table  
**Schema**: EXW_dbo  
**ETL Mechanism**: Unknown — no writer SP found in SSDT repo. Likely populated via Databricks/ADF external ETL pipeline using EXW_Staking External Tables (Bronze layer of WalletDB.Staking) as source. 23,617 rows covering Jun 2021–Jun 2023.

## ETL Pipeline Summary

```
WalletDB.Staking.StakingRewards (production — WalletDB)
WalletDB.Wallet.CustomerWalletsView (GCID/Club enrichment source)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Staking.StakingRewards (External Table, Bronze layer)
EXW_Staking.Staking (External Table, Bronze layer)
  |-- Unknown ETL (Databricks/ADF not in SSDT) --|
  v
EXW_dbo.Staking_WalletUserRewards (23,617 rows, frozen Jun 2023)
  |-- No Generic Pipeline Gold target --|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | ID | None (IDENTITY) | — | Auto-generated surrogate key; sequential (1,2,3...) | Tier 4 |
| 2 | WalletID | WalletDB.Staking.StakingRewards (via EXW_Staking.StakingRewards) | WalletId | Passthrough (varchar 1024 in DWH vs uniqueidentifier in source; CAST to string) | Tier 1 |
| 3 | GCID | WalletDB.Wallet.CustomerWalletsView | Gcid | Lookup enrichment — not in source StakingRewards; resolved via WalletId JOIN | Tier 2 |
| 4 | Club | WalletDB.Wallet.CustomerWalletsView (or EXW_DimUser) | Club | Enrichment — Club tier at time of reward (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond/Internal) | Tier 2 |
| 5 | ClubRevShare | Derived/hardcoded by Club | — | Revenue share percentage by Club (varchar); same as RevShare but as string | Tier 2 |
| 6 | RevShare | Derived/hardcoded by Club | — | Revenue share as decimal (0.75–0.90 by Club tier) | Tier 2 |
| 7 | StakingStartDate | Derived from StakingMonthID | — | First day of the staking month (datetime2 format) | Tier 2 |
| 8 | StakingMonthID | WalletDB.Staking.StakingRewards (via EXW_Staking.StakingRewards) | StakingMonthId | Passthrough YYYYMM integer | Tier 1 |
| 9 | StakingMonth | Derived from StakingMonthID | — | Human-readable month label (e.g., "Aug-2021") | Tier 2 |
| 10 | MonthlyYield | WalletDB.Staking.StakingRewards (via EXW_Staking.StakingRewards) | MonthlyYieldPercentage | Passthrough (renamed; decimal 32,18) | Tier 1 |
| 11 | MonthlyRewards | WalletDB.Staking.StakingRewards (via EXW_Staking.StakingRewards) | MonthlyReward | Passthrough (renamed; decimal 32,18) | Tier 1 |
| 12 | UserYield | WalletDB.Staking.StakingRewards (via EXW_Staking.StakingRewards) | UserYieldPercentage | Passthrough (renamed; decimal 32,18) | Tier 1 |
| 13 | EligibleRewards | Derived — equals MonthlyRewards in all observed data | MonthlyReward | Likely same as MonthlyRewards; may represent the portion that actually qualified (all eligible in ETH program) | Tier 2 |
| 14 | EligibleTransactions | EXW_Staking.Staking | COUNT of staking records | Count of staking transactions that contributed to this month's reward | Tier 2 |
| 15 | UpdateDate | Unknown ETL | — | Timestamp when this row was written | Tier 4 |

## Upstream Wiki Sources

- **WalletDB.Staking.StakingRewards**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Staking\Tables\Staking.StakingRewards.md`
  - Applies to: WalletID, StakingMonthID, MonthlyYield (← MonthlyYieldPercentage), MonthlyRewards (← MonthlyReward), UserYield (← UserYieldPercentage)

## UC Target

`_Not_Migrated` — No Gold layer UC target in generic pipeline mapping.
