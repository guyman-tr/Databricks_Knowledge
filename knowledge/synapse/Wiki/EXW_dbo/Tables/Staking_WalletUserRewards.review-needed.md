# EXW_dbo.Staking_WalletUserRewards — Review Needed

**Generated**: 2026-04-20 | **Batch**: 8 | **Object**: #2 of 6

## Tier 4 Items (Require Business Owner Verification)

| # | Column | Question | Current Assumption |
|---|--------|----------|-------------------|
| RN-001 | ALL | ETL mechanism: no writer SP in SSDT. Is this written by a Databricks job? Or an ADF pipeline? | Assumed: external ETL (Databricks/ADF) not captured in SSDT repo |
| RN-002 | EligibleRewards | EligibleRewards = MonthlyRewards for all 23,617 rows. Is this intentional (all users fully eligible)? Or is EligibleRewards a legacy field never used differently? | Assumed: all users were fully eligible throughout the ETH staking program |
| RN-003 | UpdateDate | Is UpdateDate the ETL write time or the reward distribution date? | Assumed: ETL write timestamp |
| RN-004 | RevShare | Diamond club not explicitly confirmed — assumed same 0.85 as Platinum. Is Diamond = 0.90 (same as Platinum Plus) or 0.85? | Needs confirmation |

## Tier 2 Columns Awaiting SP Confirmation

- GCID: derived via JOIN to CustomerWalletsView — confirm this is the source
- Club: same enrichment as GCID
- RevShare/ClubRevShare: hardcoded by club — confirm mapping table or hardcoded logic
- StakingStartDate: confirm it's DATEADD(MONTH, StakingMonthID-based offset, ...) or similar
- EligibleTransactions: confirm it's COUNT of EXW_Staking.Staking rows per wallet/month

## Cross-Object Consistency

- `MonthlyYield` in this table matches `YieldInDecimal` in `Staking_ETH_Rewards_Parameters` for all months where both exist — verified consistent.
- `StakingMonthID` format (YYYYMM) must match `Staking_BI_Version_WalletUserRewards.StakingMonthID` — assumed consistent.
- WalletID in this table (varchar) must be compared with WalletDB GUID using CAST(WalletID AS uniqueidentifier).

## T1 Upstream Fidelity Check

| Column | Upstream Description (WalletDB.Staking.StakingRewards) | Wiki Description | MATCH? |
|--------|--------------------------------------------------------|------------------|--------|
| WalletID | "The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups in GetStakingRewardList." | "The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups. Stored as varchar in DWH (cast from uniqueidentifier source)." | YES — verbatim with DWH note added |
| StakingMonthID | "The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data." | "The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data." | YES — exact |
| MonthlyYield | "The overall staking pool yield percentage for this month (maps to WalletDB.StakingRewards.MonthlyYieldPercentage). Recent records show 0, suggesting yield tracking may have been externalized." | "The overall staking pool yield percentage for this month (maps to WalletDB.StakingRewards.MonthlyYieldPercentage). Range: 0.00112–0.00528 (0.11%–0.53% monthly). NULL for 14 June 2023 trailing rows." | YES — verbatim base, updated with DWH range data |
| MonthlyRewards | "The amount of crypto earned as staking reward for this month, in the asset's native units (e.g., 0.01172 ETH). Summed by Staking.GetStakingTotals for total rewards per wallet. Must exceed ~$1 USD equivalent to be distributed." | "The amount of ETH earned as staking reward for this month, in native ETH units (maps to WalletDB.StakingRewards.MonthlyReward). This is the actual crypto reward received. In all observed data, equals EligibleRewards." | YES — verbatim base, SP-specific detail replaced with DWH context |
| UserYield | "The user's share of the pool yield, based on their eToro club tier (maps to WalletDB.StakingRewards.UserYieldPercentage). Recent records show 0, suggesting calculation moved upstream. Per Confluence, yield varies by club level." | "The user's share of the pool yield, based on their eToro club tier (maps to WalletDB.StakingRewards.UserYieldPercentage). In all observed data, equals MonthlyYield (users receive the full pool yield rate)." | YES — verbatim base; "recent records show 0" updated with actual DWH observation |
