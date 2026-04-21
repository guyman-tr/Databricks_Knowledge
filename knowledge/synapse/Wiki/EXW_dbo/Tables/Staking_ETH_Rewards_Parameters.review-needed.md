# EXW_dbo.Staking_ETH_Rewards_Parameters — Review Needed

**Generated**: 2026-04-20 | **Batch**: 8 | **Object**: #1 of 6

## Tier 4 Items (Require Business Owner Verification)

| # | Column | Question | Current Assumption |
|---|--------|----------|-------------------|
| RN-001 | ALL | ETL mechanism: no writer SP found in SSDT. Is this table manually maintained via SQL INSERT? Or was it populated by a decommissioned SP not in source control? | Assumed: manually maintained or historical pipeline |
| RN-002 | Rewards | Two June 2021 rows (ID=42, Rewards=32; ID=102, Rewards=0.064). Which is canonical? The large value (32 ETH) appears to be an early estimate that was corrected. | Assumed: ID=102 is the corrected/canonical June 2021 row |
| RN-003 | YieldInDecimal | NULL for IDs 42 and 102 (June 2021). Was this metric not tracked in the early program or was it filled in later for other months? | Assumed: metric added retroactively in July 2021 |
| RN-004 | StakingEndDate (2023-05-10) | Final row ends 2023-05-10, not month-end. Was the staking program hard-stopped on this specific date or is this a reporting cutoff? | Assumed: program terminated mid-month May 2023 |
| RN-005 | Rewards | Is this the total ETH distributed across ALL users for the period, or per-user average? | Assumed: aggregate pool total, not per-user |

## Cross-Object Consistency

- `StakingMonthID` in `Staking_WalletUserRewards` and `Staking_BI_Version_WalletUserRewards` uses YYYYMM integer format. `Staking_ETH_Rewards_Parameters` uses `StakingStartDate`/`StakingEndDate` date range. A bridge would be: `WHERE CAST(YEAR(sep.StakingStartDate)*100 + MONTH(sep.StakingStartDate) AS int) = swr.StakingMonthID`

## Known Issues / Flags

- ANOMALY: Two rows for June 2021 with vastly different Rewards values (32 vs 0.064). Potential data quality issue — one row may be erroneous.
- INFO: All IsActive values are 0. No active staking program exists in this table.
- INFO: IDs increment by 60 — Synapse IDENTITY distribution artifact, not missing rows.
