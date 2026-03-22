# Dealing_dbo.Dealing_Staking_DailyPool

> Daily aggregate of total crypto units held by all staking-eligible opted-in clients, plus the running average of that pool. One row per (date, instrument). Feeds the monthly SP_Staking calculation as the key measure of how large the staking pool was over a period.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (analytical — daily fact) |
| **Production Source** | Derived — computed by SP_Staking_DailyPool from BI_DB_dbo.BI_DB_PositionPnL (opted-in eligible positions) |
| **Refresh** | Daily — SP_Staking_DailyPool writes one row per instrument for the current date |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |
| **Row Count** | 4,919 (as of Mar 2026) |
| **Date Range** | 2023-09-01 – 2026-03-10 (daily, ~913 days × 13 instruments) |
| **Instruments** | 13 (ADA, ADAEUR, ETH, ETHEUR, TRX, SOL, SOLEUR, POL, DOT, NEAR, ATOM, AVAX, SUI) |
| **Last Updated** | 2026-03-11 |

---

## 1. Business Meaning

This table is the **daily building block of the staking reward calculation**. SP_Staking (the monthly distribution SP) uses `Avg_DailyTotalStakingPool` from this table to determine how much of the network's staking rewards belong to eToro vs clients: the bigger eToro's pool, the more rewards eToro earned and thus can distribute.

**DailyTotalStakingPool**: The total crypto units held across all eligible clients who are opted into staking for this instrument on this date. Excludes:
- Clients in intro period (IntroDays waiting period)
- Clients who opted out
- Clients in non-eligible regulations/countries
- Clients flagged as is_us=1 (handled by SP_Staking_DailyPool_US)

**Avg_DailyTotalStakingPool**: The simple average of DailyTotalStakingPool across ALL dates stored in the table for this instrument. This is a rolling average — it changes each day as a new row is added. SP_Staking reads this column to compute the client-pool-to-network ratio for reward distribution.

The table also drives `Dealing_Staking_OptedOut` and `Dealing_Staking_OptedOut_PerCID` which are written in the same SP_Staking_DailyPool run and provide the opted-out breakdowns used by the Staking PM team.

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| Date | date | The calendar date for this pool snapshot. One row per (date, instrument). CLUSTERED INDEX key. (Tier 3 — SP_Staking_DailyPool @Date parameter) |
| InstrumentID | int | eToro instrument identifier for the staked cryptocurrency. FK to DWH_dbo.Dim_Instrument. Includes both base and EUR pairs (e.g., SOL=100063, SOLEUR=100456). (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| Currency | varchar(100) | Ticker symbol of the staked crypto (e.g., "ADA", "ADAEUR", "ETH", "SOL"). EUR pairs represent the EUR-denominated equivalent instruments. (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards) |
| DailyTotalStakingPool | decimal(30,2) | Total crypto units held by all opted-in eligible clients for this instrument on this date. Sum of `AmountInUnitsDecimal` from BI_DB_dbo.BI_DB_PositionPnL, filtered to the eligible, opted-in staking population. Units in native crypto denomination (e.g., TRX pool shows ~393M TRX). (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| Avg_DailyTotalStakingPool | decimal(30,2) | Simple average of DailyTotalStakingPool across ALL dates in the table for this instrument. Recomputed each day. Used by SP_Staking as the primary measure of eToro's average staked pool during the distribution period. (Tier 3 — computed from DailyTotalStakingPool history) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was written by SP_Staking_DailyPool. Set to GETDATE(). (Tier 4 — ETL metadata) |

---

## 3. Business Logic

### 3.1 Pool Eligibility

SP_Staking_DailyPool applies the same eligibility filters as SP_Staking:
1. **Regulation eligibility**: Client must be in an eligible regulation for the specific crypto
2. **Opt-in status**: Client must have opted into staking (waiver-based system)
3. **Intro period**: Position must be past the IntroDays waiting period (7 days for most, 60 for ETH)
4. **US exclusion**: US-regulated clients (is_us=1) are excluded — they're handled by SP_Staking_DailyPool_US

### 3.2 Liquidity Buffer

The SP also computes `Units_AvailableForStaking` using LiquidityBuffer from Dealing_Staking_Parameters, but this is stored in `Dealing_Staking_OptedOut` — not in this table. DailyTotalStakingPool represents the gross eligible pool, not the liquidity-buffered portion.

### 3.3 Average Computation

`Avg_DailyTotalStakingPool` is a simple AVG across all rows in `#DailyPool` (which contains the current month's daily snapshots loaded in the same SP run). This means it's the average over the month-to-date data loaded in memory — not the historical average of the full table. As a result, the value of `Avg_DailyTotalStakingPool` for older rows may differ from the value that was stored when those rows were written (the average grows as more data is added).

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_DailyPool_US` | US-market equivalent — same structure, same SP logic, US clients only |
| `Dealing_dbo.Dealing_Staking_OptedOut` | Co-written by same SP_Staking_DailyPool run — opted-out breakdown by instrument/regulation |
| `Dealing_dbo.Dealing_Staking_OptedOut_PerCID` | Co-written by same SP_Staking_DailyPool run — per-client opted-out detail |
| `Dealing_dbo.Dealing_Staking_Parameters` | Configuration source — LiquidityBuffer, IntroDays per instrument |
| `Dealing_dbo.Dealing_Staking_Results` | Consumer — SP_Staking reads Avg_DailyTotalStakingPool to compute monthly rewards |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source of AmountInUnitsDecimal (client position holdings) |

---

## 5. Notes & Caveats

- **Historical avg drift**: `Avg_DailyTotalStakingPool` for a given date reflects the average at the time SP_Staking_DailyPool ran, over the dates loaded in memory. If the SP re-runs for a historical date, the stored average will change.
- **13 instruments including EUR pairs**: SOL and ADA each have EUR variants (SOLEUR, ADAEUR) for European clients who hold these in EUR-denominated positions. ETH also has ETHEUR.
- **Large unit values**: Some instruments show very large pool values (TRX ~393M, ADA ~552M) because these are low-value-per-unit coins with many fractional units.
- **US separation**: This table covers non-US only. Add Dealing_Staking_DailyPool_US for the full picture.
