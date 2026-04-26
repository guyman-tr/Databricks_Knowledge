# BI_DB_dbo.Dealing_Unrealized_CryptoRebate

## 1. Overview

Monthly unrealized crypto rebate report for Diamond and Platinum Plus club members. Captures the accrued (not-yet-paid) rebate entitlement for positions that are still open at month-end, valued at end-of-month market prices. Complements `Dealing_CryptoRebate` which covers realized (closed) positions.

**Business context:** At month-end, the SP estimates what the rebate would be if all currently-open eligible crypto positions were hypothetically closed at EOM market prices (`DWH_dbo.Fact_CurrencyPriceWithSplit.BidSpreaded`). This gives the finance team visibility into the accrued liability before positions are actually closed.

**Key distinction from Dealing_CryptoRebate:** 
- `Dealing_CryptoRebate` = **realized** rebates on positions **closed** during the month
- `Dealing_Unrealized_CryptoRebate` = **unrealized** accrual for positions **still open** at month-end (hypothetical close at EOM prices)

**Additional columns vs realized:** This table adds `IsCreditReportValidCB` and `IsGermanBaFin` — carried through in the unrealized pipeline but absent from the realized table.

**Writer:** `BI_DB_dbo.SP_M_CryptoRebateDiamond` (second INSERT block; same SP run as `Dealing_CryptoRebate`)
**Grain:** One row per {MonthEndDate × CID × Regulation × Club × IsCreditReportValidCB × IsGermanBaFin}

---

## 2. Table Metadata

| Property | Value |
|----------|-------|
| Schema | `BI_DB_dbo` |
| Table | `Dealing_Unrealized_CryptoRebate` |
| Distribution | `ROUND_ROBIN` |
| Index | `CLUSTERED INDEX (MonthEndDate ASC)` |
| Columns | 22 |
| Total rows | 786,027 |
| Date range | 2022-03-31 → 2026-03-31 (44 months) |
| Distinct CIDs | 48,589 |
| OpsDB priority | 20 |
| Frequency | Monthly |
| ProcessType | 1 (SQL) |

---

## 3. Column Reference

### 3.1 Date & ETL Metadata

| Column | Type | Description |
|--------|------|-------------|
| `MonthEndDate` | date | Last calendar day of the reporting month. ETL partition key (Tier 2 — SP_M_CryptoRebateDiamond) |
| `UPdatedate` | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline (Tier 1 — ETL metadata) |

### 3.2 Client Identity & Segmentation

| Column | Type | Description |
|--------|------|-------------|
| `CID` | int | Client identifier. Same eligibility criteria as realized table: Diamond/Platinum Plus, IsValidCustomer=1, GuruStatusID NOT IN (2,3,4,5,6), country exclusion list (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `Club` | varchar(100) | CopyTrader tier at month-end. Values: `1 Diamond` (PlayerLevelID=7), `1 Platinum Plus` (PlayerLevelID=6) (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `IsCreditReportValidCB` | int | 1 = client has a valid credit balance report at month-end, 0 otherwise. Additional column vs realized table. Sourced from `DWH_dbo.Fact_SnapshotCustomer.IsCreditReportValidCB` (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `IsGermanBaFin` | int | 1 = client is subject to German BaFin regulatory requirements on this month-end date, 0 otherwise. Additional column vs realized table. Sourced from `BI_DB_dbo.V_GermanBaFin` (Tier 2 — BI_DB_dbo.V_GermanBaFin) |
| `GuruStatus_ID` | int | Popular Investor / guru program status ID (same as realized table) (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `Country` | varchar(100) | Client's registered country at month-end (Tier 2 — DWH_dbo.Dim_Country) |
| `Region` | varchar(100) | Marketing region (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `Regulation` | varchar(100) | Regulatory jurisdiction at month-end (Tier 2 — DWH_dbo.Dim_Regulation) |

### 3.3 Volume Metrics (Unrealized / Mark-to-Market)

Eligible positions: crypto spot positions still open at month-end (`BI_DB_PositionPnL.DateID = @MonthEndDateID`), InstrumentTypeID=10, IsSettled=1, IsDiscounted=0, IsBuy=1, MirrorID=0, Leverage=1, OpenDateID≥2022-03-08.

| Column | Type | Description |
|--------|------|-------------|
| `OpenedVolume` | float | USD notional at open for positions still open at month-end: `SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1))`. Open-date forex rates from Dim_Position. Source: BI_DB_PositionPnL for position list (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Position) |
| `ClosedVolume` | float | Hypothetical close value at EOM market prices: `SUM(AmountInUnitsDecimal × ISNULL(Fact_CurrencyPriceWithSplit.BidSpreaded,1) × ISNULL(ConvertRateIsBuy_1,1))`. Uses `DWH_dbo.Fact_CurrencyPriceWithSplit` at OccurredDateID = @MonthEndDateID. This is NOT an actual close — it is a mark-to-market estimate (Tier 2 — DWH_dbo.Fact_CurrencyPriceWithSplit) |
| `TotalVolume` | float | `OpenedVolume + ClosedVolume` — combined notional (same formula as realized table). Basis for rebate calculation (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Markup` | float | `TotalVolume × 0.01` — estimated 1% spread on the unrealized notional (Tier 2 — SP_M_CryptoRebateDiamond) |

### 3.4 Bracket Volume Allocation

Same tier structure as realized table:

| Column | Type | Description |
|--------|------|-------------|
| `Bracket1_Volume` | float | Volume in $50,001–$1,000,000 tier (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket2_Volume` | float | Volume in $1,000,001–$5,000,000 tier (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket3_Volume` | float | Volume above $5,000,000 (Tier 2 — SP_M_CryptoRebateDiamond) |

### 3.5 Rebate Calculations

Same rates as realized table:

| Column | Type | Description |
|--------|------|-------------|
| `Bracket1_Rebate` | float | `Bracket1_Volume × 0.15%` (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket2_Rebate` | float | `Bracket2_Volume × 0.25%` (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket3_Rebate` | float | `Bracket3_Volume × 0.50%` (Tier 2 — SP_M_CryptoRebateDiamond) |
| `TotalRebate` | float | `CASE WHEN sum < 5 THEN 0 ELSE sum END`. Unrealized rebate accrual. Same $5 minimum threshold as realized table (Tier 2 — SP_M_CryptoRebateDiamond) |

---

## 4. Business Rules

### 4.1 Eligibility
Same as `Dealing_CryptoRebate` — Diamond/Platinum Plus only, same country exclusions, same GuruStatus exclusions, same position criteria (InstrumentTypeID=10, IsSettled=1, etc.). Positions must still be **open** at @MonthEndDateID (vs closed during the month for realized).

### 4.2 Mark-to-Market Pricing
The unrealized `ClosedVolume` uses `DWH_dbo.Fact_CurrencyPriceWithSplit.BidSpreaded × ConvertRateIsBuy_1` at EOM. This is the hypothetical sale price at the bid spread — the same pricing convention as real position closes.

### 4.3 Rebate Tier Schedule
Identical to realized table: ≤$50K = no rebate, $50K–$1M = 0.15%, $1M–$5M = 0.25%, >$5M = 0.50%. Minimum $5 threshold applies.

### 4.4 Scale Difference vs Realized
This table has ~3.7× more rows (786K vs 210K) because it captures ALL positions open at EOM — the number of open positions at any month-end is much larger than positions closed within a single month. Diamond members show higher unrealized volumes ($202K avg) than realized ($90K avg), consistent with Diamond tier clients holding larger long-term positions.

---

## 5. Data Profile

| Metric | Value |
|--------|-------|
| Total rows | 786,027 (44 months, 2022-03-31 to 2026-03-31) |
| Distinct CIDs across all months | 48,589 |
| Rows per month (2026-03-31) | ~37,866 (3,953 Diamond + 33,913 Platinum Plus) |
| Diamond rows with TotalRebate > 0 (2026-03-31) | 2,032 / 3,953 (51%) |
| Platinum Plus rows with TotalRebate > 0 (2026-03-31) | 9,216 / 33,913 (27%) |
| Diamond avg TotalVolume (2026-03-31) | ~$202,218 |
| Platinum Plus avg TotalVolume (2026-03-31) | ~$41,073 |

---

## 6. Lineage & Upstream Sources

See [`BI_DB_Dealing_Unrealized_CryptoRebate.lineage.md`](BI_DB_Dealing_Unrealized_CryptoRebate.lineage.md) for full column-level lineage.

**Primary upstream sources (unique to unrealized path):**
- `BI_DB_dbo.BI_DB_PositionPnL` — Open positions at month-end (vs Dim_Position for realized path)
- `DWH_dbo.Fact_CurrencyPriceWithSplit` — EOM market prices for unrealized close valuation
- `BI_DB_dbo.V_GermanBaFin` — German BaFin flag (present in this table, absent in realized)

---

## 7. Downstream Consumers

No downstream SP or view consumers identified in the BI_DB_dbo SSDT repo. Terminal reporting table consumed directly by BI tools / finance reporting.

---

## 8. Notes & Review Flags

- This table has 5 fewer months than the realized table (44 vs 49 months). The first 5 months of the realized table (2022-03-31 to 2022-07-31 approximately) may predate the unrealized calculation being added to the SP. Confirm the gap.
- The `IsCreditReportValidCB` and `IsGermanBaFin` columns are present here but absent from the realized table. This asymmetry appears intentional (they were added to the unrealized path for audit/reporting purposes) but was not reflected back to the realized path. Confirm whether this was deliberate.
- The month-end population is ~6.5× larger per month than the realized population (37,866 vs 5,853 rows for 2026-03-31), consistent with the large number of buy-and-hold crypto investors in the Diamond/Platinum Plus tiers.
