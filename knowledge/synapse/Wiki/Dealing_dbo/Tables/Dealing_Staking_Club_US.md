# Dealing_dbo.Dealing_Staking_Club_US

> US-market equivalent of Dealing_Staking_Club — per-month average daily holdings threshold required to earn at least $1 USD in staking compensation for US-regulated clients, broken down by cryptocurrency and eToro Club loyalty tier. Covers only cryptos eligible under US regulations (ADA, SOL, ETH).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (analytical output) |
| **Production Source** | Derived — computed by SP_Staking_US from BI_DB_dbo.BI_DB_PositionPnL (US clients), DWH_dbo.Dim_PlayerLevel, Dealing_staging.Fivetran_google_sheets_platform_rewards (is_us=1) |
| **Refresh** | Monthly — SP_Staking_US runs daily at 11:00 AM, writes once per staking month when US rewards sheet is ready |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Row Count** | 81 (as of Mar 2026) |
| **Date Range** | Oct 2025 – Feb 2026 (StakingMonthID 202510 – 202602) |
| **Last Updated** | 2026-03-03 |

---

## 1. Business Meaning

The US staking program launched in October 2025 and operates under separate regulatory restrictions compared to the global program. This table mirrors the structure and computation of `Dealing_Staking_Club` (the non-US equivalent) but is populated exclusively from US-regulated client data (`DWH_dbo.Dim_Customer.RegulationID IN (6, 7, 8)`) and US-active reward configurations (`Fivetran_google_sheets_platform_rewards WHERE is_us = 1`).

**Key differences from the non-US Dealing_Staking_Club**:
- **Smaller currency scope**: Only ADA, SOL, ETH are offered to US clients (vs 9 currencies globally)
- **Later launch**: Program started Oct 2025 (non-US started Sep 2024)
- **Scheduled execution**: SP_Staking_US runs at a fixed 11:00 AM time (ProcessType 3 = SQL&TIME), while SP_Staking is event-driven
- **Index type**: CLUSTERED COLUMNSTORE INDEX (vs CLUSTERED INDEX on non-US version) — optimized for analytical queries

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking period identifier in YYYYMM format. US program started Oct 2025 (202510). (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards is_us=1) |
| StakingMonth | varchar(100) | Full month name of the staking period (e.g., "October"). Derived from `DATENAME(MONTH, StakingEndDate)`. (Tier 3 — computed) |
| StakingYear | int | Calendar year of the staking period. Derived from `YEAR(StakingEndDate)`. (Tier 3 — computed) |
| InstrumentID | int | eToro instrument identifier for the staked cryptocurrency. For US: SOL (100063), ADA, or ETH. FK to DWH_dbo.Dim_Instrument. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| Currency | varchar(100) | Ticker symbol of the staked cryptocurrency. US-eligible values: "ADA", "SOL", "ETH". (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards is_us=1) |
| PlayerLevel | varchar(100) | eToro Club loyalty tier name. One of: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Same tier structure as non-US; higher tiers have lower thresholds due to higher revenue share. FK to DWH_dbo.Dim_PlayerLevel.Name. (Tier 1 — DWH_dbo.Dim_PlayerLevel) |
| Avg_Daily_Holdings_Threshold | decimal(38,8) | Average daily holdings in native crypto units required to earn ≥$1 USD in staking compensation for a US client at this tier during this staking month. Computed identically to the non-US variant: `((under_holdings + over_holdings) / 2) / TotalStakingDays` from boundary CIDs in #Under_Over_US. (Tier 3 — computed from BI_DB_dbo.BI_DB_PositionPnL) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by SP_Staking_US. Set to GETDATE() at SP execution time. (Tier 4 — ETL metadata) |

---

## 3. Business Logic

Same threshold interpolation algorithm as `Dealing_Staking_Club` — see that table's documentation for the full methodology. Key distinctions for the US variant:

- **Client eligibility filter**: Only US-regulated clients (DWH_dbo.Dim_Customer.RegulationID IN (6, 7, 8))
- **Rewards filter**: Only rows with `is_us = 1` in the platform rewards Google Sheet
- **Execution guard**: SP_Staking_US runs if rewards sheet has `is_us=1` data for the target month AND Dealing_Staking_Results_US doesn't yet have that month

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Club` | Non-US equivalent — identical schema, wider currency coverage, different client population |
| `Dealing_dbo.Dealing_Staking_Results_US` | Main per-client result table for US staking written by SP_Staking_US |
| `Dealing_dbo.Dealing_Staking_Summary_US` | Monthly aggregate summary for US staking |
| `Dealing_dbo.Dealing_Staking_Position_US` | Per-position detail for US staking |
| `Dealing_dbo.Dealing_Staking_Parameters` | Shared configuration (IntroDays, etc.) — same parameters used for both US and non-US |
| `DWH_dbo.Dim_PlayerLevel` | Lookup for loyalty tier names |

---

## 5. Notes & Caveats

- **Program maturity**: US staking is newer (launched Oct 2025) with fewer currencies and fewer historical months. Data may be less stable/representative than the non-US program.
- **Columnar storage**: Unlike the non-US table (row-store CLUSTERED INDEX), this uses COLUMNSTORE for better analytical scan performance — may indicate heavier aggregation query patterns.
- **ProcessType 3 (SQL&TIME)**: The 11:00 AM scheduled execution ensures the US staking run happens after the non-US run (which is event-driven upon Fivetran update). This ordering prevents resource contention.
