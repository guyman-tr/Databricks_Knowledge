# Dealing_dbo.Dealing_Rollover_Assurance

> Daily rollover (overnight) fee discrepancy audit table — stores one row per position where the model-calculated rollover fee differs from the actual fee charged by more than $1, with the discrepancy broken down into four mutually exclusive categories: Islamic exemption, late close, fee configuration update, and other.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Rev_Assurance (also writes Dealing_Commission_Assurance and Dealing_Commission_Assurance_By_Position) |
| **Refresh** | Daily via SB_Daily (Priority 0) |
| **Row Count** | ~46.4M (2022-01-01 to present) |
| **Temporal Coverage** | 2022-01-01 — present (active, updated to business day −1) |
| | |
| **Synapse Distribution** | HASH (CID, InstrumentID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_assurance` |

---

## 1. Business Meaning

This table is a **rollover fee quality-assurance audit trail**. Each day, SP_Rev_Assurance calculates what overnight fees *should have been* charged for every eligible open position (based on instrument fee config and day-of-week multipliers) and compares this against the fees *actually* recorded in the credit history. Only rows where the discrepancy exceeds $1 are retained.

**Coverage**: Commodities dominate (~70% of rows), followed by Crypto, FX, Stocks, and Indices. This reflects the relative overnight-fee volume by asset class.

**Exclusions applied by SP**:
- Positions that are long (IsBuy=1) and unleveraged (Leverage=1) on Stocks or ETFs — these have no overnight fee
- HedgeServerID=121 (special hedge server excluded from rollover tracking)
- PI/premium accounts (Dim_Customer.PlayerLevelID=4)

---

## 2. Business Logic

### 2.1 Rollover Fee Calculation

**What**: The model reconstructs the expected overnight fee using instrument-level fee configs and a day-of-week multiplier.

**Formula**: `[Calculated RO] = day_multiplier × Units × overnight_fee_rate`

**Day multipliers**:
- Saturday/Sunday → **0** (no fees on weekends for most instruments)
- Friday (Stocks/ETF/Crypto — InstrumentTypeID 4,5,6) → **×3** (triple fee)
- Wednesday (FX/Commodities/Indices) → **×3** (triple fee)
- All other days → **×1**

**Fee rate selection** from `etoro_Trade_InstrumentToFeeConfig`:
- Leveraged + buy → `LeveragedBuyOverNightFee`
- Leveraged + sell → `LeveragedSellOverNightFee`
- Unleveraged + buy → `NonLeveragedBuyOverNightFee`
- Unleveraged + sell → `NonLeveragedSellOverNightFee`

**Cutoff time**: 21:00 UTC from 2018-03-11 onward (previously 22:00 UTC). A position must be open at the cutoff to incur a fee.

### 2.2 Discrepancy Breakdown (Mutually Exclusive Categories)

The `[Total Diff]` = `[Calculated RO] - [Actual RO]` is partitioned into four exclusive buckets. A positive diff means the actual fee was lower than the model (underpayment):

| Column | Condition | Meaning |
|---|---|---|
| `[Islamic]` | WeekendFeePrecentage = 0 | Islamic (swap-free) accounts — no overnight fees expected; any diff is the Islamic exemption amount |
| `[Closed after cutoff]` | Non-Islamic AND position closed within 90 min of cutoff | Late closers: closed after the cutoff but within the 90-min grace window; fee still applies |
| `[Fee updated]` | Non-Islamic, not late-close, AND (InstrumentID=22 OR InstrumentTypeID IN (5,6)) | Fee config update discrepancy for Natural Gas (XNG/USD) and Crypto/ETF |
| `[Other]` | Non-Islamic, not late-close, not fee-config instruments | Unexplained discrepancies for all other instruments |

**Identity**: For every row: `[Total Diff] = [Islamic] + [Closed after cutoff] + [Fee updated] + [Other]`

### 2.3 Islamic Account Detection

`WeekendFeePrecentage = 0` identifies Islamic swap-free accounts. These customers are contracted to pay no overnight fees; any model-vs-actual diff for them is expected (the system correctly charged 0).

---

## 3. Columns

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Reporting date (the cutoff date for which rollover fees are evaluated) (Tier 2 — SP parameter) |
| PositionID | bigint | Unique position identifier (Tier 1 — DWH_dbo.Dim_Position) |
| CID | int | Customer identifier (Tier 1 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier (Tier 1 — DWH_dbo.Dim_Position) |
| InstrumentName | varchar(50) | Instrument display name (e.g., XAU/USD, BTC) (Tier 1 — DWH_dbo.Dim_Instrument) |
| InstrumentType | varchar(50) | Instrument class: Commodities, Crypto Currencies, Currencies, Stocks, Indices, ETF (Tier 2 — DWH_dbo.Dim_Instrument) |
| OpenOccurred | datetime | Timestamp when the position was opened (Tier 1 — DWH_dbo.Dim_Position) |
| CloseOccurred | datetime | Timestamp when the position was closed; GETDATE() for open positions at execution time (Tier 1 — DWH_dbo.Dim_Position) |
| Units | decimal(16,6) | Position size in instrument units (AmountInUnitsDecimal) (Tier 1 — DWH_dbo.Dim_Position) |
| Leverage | int | Leverage multiplier applied to the position (Tier 1 — DWH_dbo.Dim_Position) |
| IsBuy | bit | Direction: 1 = long (buy), 0 = short (sell) (Tier 1 — DWH_dbo.Dim_Position) |
| MirrorID | int | Copy-trading mirror ID; 0 = manual trade, >0 = copy position (Tier 1 — DWH_dbo.Dim_Position) |
| HedgeServerID | int | Hedge server routing identifier; HedgeServerID=225 = NOP server (unhedged) (Tier 1 — DWH_dbo.Dim_Position) |
| WeekendFeePrecentage | tinyint | Customer's weekend fee percentage; 0 = Islamic/swap-free account (no overnight fees) (Tier 4 — etoro_Customer_CustomerStatic) |
| [Calculated RO] | numeric(38,8) | Model-calculated rollover fee: day_multiplier × Units × overnight_fee_rate from InstrumentToFeeConfig (Tier 2 — computed) |
| [Actual RO] | money | Actual rollover fee charged, sourced from etoro_History_Credit CreditTypeID=14 (excludes dividend payments) (Tier 4 — Dealing_staging.etoro_History_Credit) |
| [Total Diff] | numeric(38,8) | Discrepancy: [Calculated RO] − [Actual RO]; positive = model expected more than was charged (Tier 2 — computed) |
| [Islamic] | numeric(38,8) | Portion of [Total Diff] attributable to Islamic/swap-free accounts (WeekendFeePrecentage=0) (Tier 2 — computed) |
| [Closed after cutoff] | numeric(38,8) | Portion of [Total Diff] where a non-Islamic position closed within 90 minutes of the cutoff time (Tier 2 — computed) |
| [Fee updated] | numeric(38,8) | Portion of [Total Diff] for non-Islamic positions on Natural Gas (InstrumentID=22) or Crypto/ETF (InstrumentTypeID 5,6) — typically reflects fee config change lag (Tier 2 — computed) |
| [Other] | numeric(38,8) | Remaining unexplained discrepancy not covered by the other three categories (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — GETDATE()) |

---

## 4. Usage Notes

- **Column names with spaces**: `[Calculated RO]`, `[Actual RO]`, `[Total Diff]`, `[Islamic]`, `[Closed after cutoff]`, `[Fee updated]`, `[Other]` must be quoted with brackets in SQL.
- **Threshold filter**: Only discrepancies >$1 are stored. Zero-diff positions (fee matched exactly) are excluded.
- **Typical distribution** (Mar 2026): ~914 rows per day; ~62% Islamic, ~5% late-close, ~21% fee-updated, ~11% other.
- **Average abs discrepancy** (2026-03-10): ~$47 per position — large variances are expected for commodity overnight positions.
- **Companion tables**: `Dealing_Commission_Assurance` (commission monthly summary) and `Dealing_Commission_Assurance_By_Position` (position-level commission audit) are written by the same SP.
- **Related**: `Dealing_overnight_fees` tracks overnight fee totals at the instrument level (separate SP).

---

## 5. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| FK source | DWH_dbo.Dim_Position | PositionID | Full position context |
| FK source | DWH_dbo.Dim_Instrument | InstrumentID | Instrument type/name |
| Same writer | Dealing_dbo.Dealing_Commission_Assurance | — | SP_Rev_Assurance |
| Same writer | Dealing_dbo.Dealing_Commission_Assurance_By_Position | — | SP_Rev_Assurance |
