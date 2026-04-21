# EXW_dbo.Staking_BI_Version_WalletUserRewards — Review Needed

**Generated**: 2026-04-20 | **Batch**: 8 | **Object**: #3 of 6

## Tier 4 Items (Require Business Owner Verification)

| # | Column | Question | Current Assumption |
|---|--------|----------|-------------------|
| RN-001 | ALL | ETL mechanism: no writer SP in SSDT. Is this populated by the same Databricks/ADF job that writes Staking_WalletUserRewards, or a separate pipeline? | Assumed: same external ETL as base table, but with BI-enrichment step (uniqueidentifier WalletID, numeric ClubRevShare, IsTestUser inclusion) |
| RN-002 | UpdateDate | Is UpdateDate the ETL write time or the reward distribution date? | Assumed: ETL write timestamp (same assumption as base table) |
| RN-003 | IsTestUser | What source does IsTestUser come from — CustomerWalletsView.IsTest or a separate eToro accounts allowlist? | Assumed: CustomerWalletsView IsTest flag (or equivalent) |
| RN-004 | ALL | Why does the BI version cover Jul 2021–May 2023 (23 months) while the base table covers Jun 2021–Jun 2023 (25 months)? Is the missing Jun 2021 a pilot exclusion or ETL timing difference? Is Jun 2023 excluded because it had no real staking rewards? | Assumed: different ETL run windows; Jun 2021 is a pilot period excluded from BI version; Jun 2023 is a trailing/cleanup period excluded from BI enrichment |
| RN-005 | EligibleRewards | EligibleRewards = MonthlyRewards for all 23,659 rows. Same pattern as base table. Intentional (all users fully eligible)? | Assumed: same as base table — all ETH staking users fully eligible throughout program |

## Tier 2 Columns Awaiting SP Confirmation

- GCID: derived via JOIN to CustomerWalletsView — confirm this is the source
- Club: same enrichment as GCID
- ClubRevShare / RevShare: hardcoded by club (numeric(2,2)) — confirm mapping
- StakingStartDate: confirm it's derived as first day of StakingMonthID month (date, not datetime2 as in base)
- EligibleTransactions: confirm it's COUNT of EXW_Staking.Staking rows per wallet/month
- IsTestUser: confirm source field name in CustomerWalletsView

## Cross-Object Consistency

- `StakingMonthID` format (YYYYMM) matches `Staking_WalletUserRewards.StakingMonthID` — verified consistent.
- `MonthlyYield` values in BI version match `Staking_WalletUserRewards.MonthlyYield` for overlapping months (202107–202305) — assumed consistent (no query run).
- `MonthlyYield` (decimal 18,16) should match `YieldInDecimal` in `Staking_ETH_Rewards_Parameters` for overlapping months — logical cross-check only.
- Row count: 23,659 (BI) vs 23,617 (base). Difference of 42 = IsTestUser rows. Verify the 42 test rows are not present in base table.
- WalletID type: uniqueidentifier here vs varchar(1024) in base — always CAST(base.WalletID AS uniqueidentifier) when joining.
- ClubRevShare type: numeric(2,2) here vs varchar in base — do not join or compare without explicit CAST.

## T1 Upstream Fidelity Check

| Column | Upstream Description (WalletDB.Staking.StakingRewards) | Wiki Description | MATCH? |
|--------|--------------------------------------------------------|------------------|--------|
| WalletID | "The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups in GetStakingRewardList." | "The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Stored as native uniqueidentifier — correctly typed vs varchar in base table Staking_WalletUserRewards." | YES — verbatim base; DWH-specific note added (correct type) |
| StakingMonthID | "The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data." | "The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202107 to 202305 in current data." | YES — verbatim base; range updated to reflect BI version actual data |
| MonthlyYield | "The overall staking pool yield percentage for this month (maps to WalletDB.StakingRewards.MonthlyYieldPercentage). Recent records show 0, suggesting yield tracking may have been externalized." | "The overall staking pool yield percentage for this month (maps to WalletDB.StakingRewards.MonthlyYieldPercentage). Range: 0.00112–0.00528 (0.11%–0.53% monthly). Stored as decimal(18,16) for higher precision." | YES — verbatim base; range data from DWH observation added |
| MonthlyRewards | "The amount of crypto earned as staking reward for this month, in the asset's native units (e.g., 0.01172 ETH)." | "The amount of ETH earned as staking reward for this month, in native ETH units (maps to WalletDB.StakingRewards.MonthlyReward). Stored as float in this BI version (vs decimal in base table). In all observed data, equals EligibleRewards." | YES — verbatim base; float type difference documented |
| UserYield | "The user's share of the pool yield, based on their eToro club tier (maps to WalletDB.StakingRewards.UserYieldPercentage)." | "The user's share of the pool yield, based on their eToro club tier (maps to WalletDB.StakingRewards.UserYieldPercentage). In all observed data, equals MonthlyYield exactly." | YES — verbatim base; DWH observation added |
