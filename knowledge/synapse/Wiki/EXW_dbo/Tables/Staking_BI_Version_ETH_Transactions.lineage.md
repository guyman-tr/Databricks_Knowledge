# EXW_dbo.Staking_BI_Version_ETH_Transactions — Column Lineage

**Generated**: 2026-04-20  
**Object Type**: Table  
**Schema**: EXW_dbo  
**ETL Mechanism**: Unknown — no writer SP found in SSDT repo. BI-enriched transaction-level staking table combining WalletDB.Staking.Staking (core staking operation) and WalletDB.Staking.StakingTransactions (fees) with BI enrichment (GCID, Club, RevShare, IsTestUser, eligibility columns, reward allocation). 26 columns, HASH(GCID), HEAP.

## ETL Pipeline Summary

```
WalletDB.Staking.Staking (production — WalletDB)
WalletDB.Staking.StakingTransactions (fees: EtoroFee, BlockchainEstFee)
WalletDB.Staking.StakingStatuses (latest status per staking operation)
WalletDB.Wallet.CustomerWalletsView (GCID/Club/IsTestUser enrichment)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Staking.Staking (External Table, Bronze)
EXW_Staking.StakingRewards (External Table, Bronze)
  |-- Unknown external ETL (Databricks/ADF — not in SSDT) --|
  |-- Enrichment: GCID, Club, RevShare, IsTestUser, IsStakingEligible --|
  |-- BI computation: EligibleStakingDaysCount, AverageDailyPositionPerTransaction --|
  |-- BI computation: ClientMonthlyStakingReward (reward share per transaction) --|
  |-- StakingMonthID derived from reward month (not necessarily transaction month) --|
  v
EXW_dbo.Staking_BI_Version_ETH_Transactions (frozen, ETH staking program ended May 2023)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | StakingMonth | Derived from StakingMonthID | — | "Mmm-YYYY" label (e.g., "Jul-2021") derived from reward month | Tier 2 |
| 2 | StakingMonthID | Derived from staking period | — | YYYYMM integer identifying the reward month this transaction contributes to | Tier 2 |
| 3 | Id | WalletDB.Staking.Staking | Id | Passthrough — IDENTITY PK from Staking.Staking; bigint | Tier 1 |
| 4 | WalletID | WalletDB.Staking.Staking | WalletId | Passthrough uniqueidentifier (correctly typed) | Tier 1 |
| 5 | GCID | WalletDB.Wallet.CustomerWalletsView | Gcid | Lookup enrichment via WalletId | Tier 2 |
| 6 | Club | WalletDB.Wallet.CustomerWalletsView | Club | Enrichment — Club tier at time of staking | Tier 2 |
| 7 | RevShare | Derived/hardcoded by Club | — | Revenue share as numeric(2,2); 0.75=Internal, 0.85=Bronze–Platinum, 0.90=Platinum Plus | Tier 2 |
| 8 | Amount | WalletDB.Staking.Staking | Amount | Passthrough — quantity of ETH staked; decimal(36,18) | Tier 1 |
| 9 | CorrelationID | WalletDB.Staking.Staking | CorrelationId | Passthrough — uniqueidentifier idempotency key | Tier 1 |
| 10 | CryptoID | WalletDB.Staking.Staking | CryptoId | Passthrough — 2=ETH for all records in this dataset | Tier 1 |
| 11 | Staking_DateTime | WalletDB.Staking.Staking | Occurred | Passthrough rename — staking initiation timestamp; datetime2(7) | Tier 1 |
| 12 | Staking_Date | Derived from Staking_DateTime | — | Date portion only (date type) | Tier 2 |
| 13 | Staking_DateID | Derived from Staking_DateTime | — | YYYYMMDD integer date key | Tier 2 |
| 14 | EtoroFee | WalletDB.Staking.StakingTransactions | EtoroFee | Passthrough — eToro service fee; decimal(36,18); currently 0 across all records | Tier 1 |
| 15 | BlockchainEstFee | WalletDB.Staking.StakingTransactions | BlockchainEstFee | Passthrough — estimated blockchain gas fee; decimal(36,18); currently 0 across all records | Tier 1 |
| 16 | StatusID | WalletDB.Staking.StakingStatuses | StakingStatusId | Latest status per staking operation (Pending=1, Failed=2, Completed=3) | Tier 2 |
| 17 | Status_Name | Derived from StatusID | — | Human-readable status label (Pending/Failed/Completed) | Tier 2 |
| 18 | Status_DateTime | WalletDB.Staking.StakingStatuses | Occurred | Timestamp of latest status transition; datetime2(7) | Tier 2 |
| 19 | Status_Date | Derived from Status_DateTime | — | Date portion of Status_DateTime (date type) | Tier 2 |
| 20 | IsStakingEligible | BI enrichment / ETL computation | — | 1=this transaction position was eligible to contribute to staking rewards; 0=not eligible | Tier 3 |
| 21 | EffectiveStakingStartDate | BI enrichment / ETL computation | — | Date from which this position started accumulating staking eligibility for the reward month | Tier 3 |
| 22 | EligibleStakingDaysCount | BI enrichment / ETL computation | — | Number of days in the reward month during which this position was staking-eligible | Tier 3 |
| 23 | AverageDailyPositionPerTransaction | BI enrichment / ETL computation | — | Average ETH amount across eligible staking days (Amount × EligibleStakingDaysCount / total month days) | Tier 3 |
| 24 | ClientMonthlyStakingReward | BI enrichment / ETL computation | — | The ETH reward attributable to this specific staking transaction for the reward month | Tier 3 |
| 25 | IsTestUser | WalletDB.Wallet.CustomerWalletsView | IsTest | 1=test eToro account; 0=real production user | Tier 2 |
| 26 | UpdateDate | Unknown ETL | — | Timestamp when this row was written to the DWH by the external ETL | Tier 4 |

## Upstream Wikis

- **WalletDB.Staking.Staking**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Staking\Tables\Staking.Staking.md`
  - Applies to: Id, WalletID, Amount, CorrelationID, CryptoID, Staking_DateTime
- **WalletDB.Staking.StakingTransactions**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Staking\Tables\Staking.StakingTransactions.md`
  - Applies to: EtoroFee, BlockchainEstFee

## UC Target

`_Not_Migrated` — No Gold layer UC target in generic pipeline mapping.
