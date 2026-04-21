# EXW_dbo.Staking_BI_Version_WalletUserRewards — Column Lineage

**Generated**: 2026-04-20  
**Object Type**: Table  
**Schema**: EXW_dbo  
**ETL Mechanism**: Unknown — no writer SP found in SSDT repo. BI-enriched version of Staking_WalletUserRewards. Likely populated via same external ETL (Databricks/ADF) but with test-user inclusion and corrected WalletID type (uniqueidentifier vs varchar). 23,659 rows covering Jul 2021–May 2023.

## ETL Pipeline Summary

```
WalletDB.Staking.StakingRewards (production — WalletDB)
WalletDB.Wallet.CustomerWalletsView (GCID/Club/IsTestUser enrichment)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Staking.StakingRewards (External Table, Bronze)
EXW_Staking.Staking (External Table, Bronze)
  |-- Unknown external ETL (Databricks/ADF — not in SSDT) --|
  |-- Enrichment: GCID, Club, IsTestUser from CustomerWalletsView --|
  |-- WalletID preserved as uniqueidentifier (unlike base table) --|
  v
EXW_dbo.Staking_BI_Version_WalletUserRewards (23,659 rows, frozen May 2023)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | StakingMonth | Derived from StakingMonthID | — | "Mmm-YYYY" label (e.g., "Jul-2021") | Tier 2 |
| 2 | StakingMonthID | WalletDB.Staking.StakingRewards | StakingMonthId | Passthrough YYYYMM integer | Tier 1 |
| 3 | WalletID | WalletDB.Staking.StakingRewards | WalletId | Passthrough uniqueidentifier (correctly typed; base table casts to varchar) | Tier 1 |
| 4 | GCID | WalletDB.Wallet.CustomerWalletsView | Gcid | Lookup enrichment via WalletID | Tier 2 |
| 5 | Club | WalletDB.Wallet.CustomerWalletsView | Club | Enrichment — 7 values: Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond/Internal | Tier 2 |
| 6 | ClubRevShare | Derived/hardcoded by Club | — | Revenue share as numeric(2,2); 0.75=Internal, 0.85=Bronze–Platinum, 0.90=Platinum Plus | Tier 2 |
| 7 | RevShare | Derived/hardcoded by Club | — | Same as ClubRevShare (numeric(2,2)) | Tier 2 |
| 8 | StakingStartDate | Derived from StakingMonthID | — | First day of the staking month (date, not datetime2) | Tier 2 |
| 9 | MonthlyYield | WalletDB.Staking.StakingRewards | MonthlyYieldPercentage | Passthrough rename; decimal(18,16) | Tier 1 |
| 10 | MonthlyRewards | WalletDB.Staking.StakingRewards | MonthlyReward | Passthrough rename; float (vs decimal in base table) | Tier 1 |
| 11 | UserYield | WalletDB.Staking.StakingRewards | UserYieldPercentage | Passthrough rename; decimal(18,16) | Tier 1 |
| 12 | EligibleRewards | Derived — same as MonthlyRewards in all observed data | — | Float; mirrors base table pattern | Tier 2 |
| 13 | EligibleTransactions | EXW_Staking.Staking | COUNT of staking records | Count of staking transactions contributing to monthly reward | Tier 2 |
| 14 | IsTestUser | WalletDB.Wallet.CustomerWalletsView | IsTest (or similar) | 1=test account; 0=real user. 42 test-user rows present | Tier 2 |
| 15 | UpdateDate | Unknown ETL | — | Timestamp when row was written | Tier 4 |

## Upstream Wiki

- **WalletDB.Staking.StakingRewards**: Applies to StakingMonthID, WalletID, MonthlyYield, MonthlyRewards, UserYield

## UC Target

`_Not_Migrated` — No Gold layer target in generic pipeline mapping.
