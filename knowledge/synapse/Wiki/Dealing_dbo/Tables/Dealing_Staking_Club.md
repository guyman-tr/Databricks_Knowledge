# Dealing_dbo.Dealing_Staking_Club

> Per-month average daily holdings threshold required to earn at least $1 USD in staking compensation, broken down by cryptocurrency and eToro Club loyalty tier. Used by the Dealing/Staking team to understand the minimum stake size that makes staking economically meaningful at each tier level.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (analytical output) |
| **Production Source** | Derived — computed by SP_Staking from BI_DB_dbo.BI_DB_PositionPnL, DWH_dbo.Dim_PlayerLevel, Dealing_staging.Fivetran_google_sheets_platform_rewards |
| **Refresh** | Monthly — SP_Staking runs once per staking month (when Fivetran rewards sheet is ready and that month's results not yet loaded) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on StakingMonthID |
| **Row Count** | 744 (as of Mar 2026) |
| **Date Range** | Sep 2024 – Feb 2026 (StakingMonthID 202409 – 202602) |
| **Last Updated** | 2026-03-03 |

---

## 1. Business Meaning

This table answers the question: *"How many units of a given crypto does a client at a given loyalty tier need to hold on average per day, over a staking period, to receive at least $1 USD in staking compensation?"*

The threshold is the staking program's practical minimum — a client holding fewer units would receive less than $1 USD and may be eligible for a cash compensation top-up instead of an airdrop. It's a per-month, per-currency, per-tier metric used by Dealing analysts and the Tableau staking overview dashboard.

The 6 loyalty tiers (Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond) each have different revenue share percentages (45–90%), which means a Bronze-tier client must hold more units than a Diamond client to earn the same $1 USD minimum (since Bronze receives a smaller share of the distributed rewards).

**Supported cryptocurrencies as of Feb 2026**: ADA, ETH, SOL, TRX, POL, NEAR, ATOM, DOT, SUI (9 coins). ADA, ETH, SOL, TRX have been in the program since Sep 2024 (18 months); SUI added recently (2 months).

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking period identifier in YYYYMM format (e.g., 202602 = February 2026). Derived from `LEFT(StakingEndDate, 6)` of the prior month. (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards) |
| StakingMonth | varchar(100) | Full month name of the staking period (e.g., "February"). Derived from `DATENAME(MONTH, StakingEndDate)`. (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards) |
| StakingYear | int | Calendar year of the staking period. Derived from `YEAR(StakingEndDate)`. (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards) |
| InstrumentID | int | eToro instrument identifier for the staked cryptocurrency. FK to DWH_dbo.Dim_Instrument. Pairs with Currency to fully identify the crypto asset. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| Currency | varchar(100) | Ticker symbol of the staked cryptocurrency (e.g., "ADA", "ETH", "SOL", "DOT"). Sourced from the platform rewards Google Sheet via Fivetran. (Tier 3 — Dealing_staging.Fivetran_google_sheets_platform_rewards) |
| PlayerLevel | varchar(100) | eToro Club loyalty tier name. One of: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Higher tiers receive a larger revenue share fraction (Bronze 45% → Diamond 90%), so they reach the $1 USD threshold with fewer held units. FK to DWH_dbo.Dim_PlayerLevel.Name. (Tier 1 — DWH_dbo.Dim_PlayerLevel) |
| Avg_Daily_Holdings_Threshold | decimal(38,8) | The average daily holdings in native crypto units that a client must maintain over the staking period to earn at least $1 USD in compensation. Computed by SP_Staking as the interpolated midpoint of the boundary "under" and "over" CIDs straddling the $1 USD threshold: `((under_holdings + over_holdings) / 2) / TotalStakingDays`. Higher tiers (larger revenue share) have lower thresholds. (Tier 3 — computed from BI_DB_dbo.BI_DB_PositionPnL) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by SP_Staking. Set to GETDATE() at SP execution time. (Tier 4 — ETL metadata) |

---

## 3. Business Logic

### 3.1 Threshold Computation

The threshold is derived by finding pairs of clients that straddle the $1 USD staking compensation boundary:

1. **#Under_Over**: SP_Staking identifies the client just BELOW $1 USD (`Type = 'Under'`, computed from `#Final` where `USD_Compensation < 1`) and the client just ABOVE $1 USD (`Type = 'Over'`)  for each (InstrumentID, PlayerLevel, StakingMonthID) combination.

2. **Interpolation**: `Avg_Daily_Holdings_Threshold = ((under_holdings + over_holdings) / 2) / TotalStakingDays` where holdings are `[Units * Eligible_Days]` from the position data.

3. The threshold thus represents a client whose compensation sits right at the $1 boundary — the minimum economically meaningful stake.

### 3.2 Revenue Share by Tier

Revenue share fractions embedded in SP_Staking (from `#RevShareBrackets`):
- Bronze: 45% | Silver: 55% | Gold: 65% | Platinum: 75% | Platinum Plus: 85% | Diamond: 90%

Because Diamond clients get 90% of the pool's per-unit reward vs Bronze's 45%, a Diamond client needs roughly half the holdings of a Bronze client to earn the same $1 USD.

### 3.3 SP Execution Guard

SP_Staking only runs for a given StakingMonthID when:
1. `Dealing_staging.Fivetran_google_sheets_platform_rewards` contains an active row for that month (`is_active = 1`)
2. `Dealing_dbo.Dealing_Staking_Results` does NOT yet have results for that month

This prevents duplicate runs within the same month.

### 3.4 US Isolation

SP_Staking (non-US) excludes clients with `is_us = 1`. US staking is handled separately by `SP_Staking_US`, which writes to `Dealing_Staking_Club_US`. The non-US and US populations are fully separated.

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Parameters` | Configuration source — IntroDays, LiquidityBuffer, start dates per InstrumentID |
| `Dealing_dbo.Dealing_Staking_Club_US` | US-market equivalent — same structure, written by SP_Staking_US |
| `Dealing_dbo.Dealing_Staking_Results` | Main result table written by same SP_Staking run — per-client staking output |
| `Dealing_dbo.Dealing_Staking_Summary` | Monthly aggregate summary written by same SP_Staking run |
| `Dealing_dbo.Dealing_Staking_Position` | Per-position staking detail written by same SP_Staking run |
| `DWH_dbo.Dim_PlayerLevel` | Lookup for PlayerLevel tier names and IDs |
| `DWH_dbo.Dim_Instrument` | Lookup for InstrumentID → instrument name/type |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source of client position holdings used in threshold calculation |

---

## 5. Notes & Caveats

- **Granularity**: One row per (StakingMonthID, InstrumentID/Currency, PlayerLevel). Always exactly 6 rows per crypto per month (one per tier).
- **No client PII**: This table contains only aggregate/summary thresholds — no CID-level data.
- **Intro days excluded**: The `IntroDays` waiting period (7 for most coins, 60 for ETH) is applied before computing holdings. Positions held during the intro period don't contribute to the eligible staking days.
- **Coverage**: Only coins present in the `Fivetran_google_sheets_platform_rewards` sheet for a given month are included. New coins appear once eToro begins their staking program.
- **Historical depth**: Data starts Sep 2024 (program launch), with new currencies added progressively.
