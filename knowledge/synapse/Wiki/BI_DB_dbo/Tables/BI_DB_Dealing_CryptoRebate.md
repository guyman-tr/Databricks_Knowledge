# BI_DB_dbo.Dealing_CryptoRebate

## 1. Overview

Monthly realized crypto rebate report for Diamond and Platinum Plus club members. Calculates the cash rebate owed to eligible clients based on their total notional volume of spot crypto positions closed during the month, applying a tiered rebate rate schedule.

**Business context:** eToro offers Diamond and Platinum Plus club members a crypto rebate program where a portion of the estimated spread (Markup) is returned based on monthly trading volume. The rebate rate increases with volume tier (0.15% → 0.25% → 0.50%). A minimum threshold of $5 applies — rebates below $5 are zeroed out.

**Key distinction from Dealing_Unrealized_CryptoRebate:** This table contains **realized** rebates only — positions that were actually closed within the month. The companion table `Dealing_Unrealized_CryptoRebate` covers positions still open at month-end, valued at EOM market prices.

**Writer:** `BI_DB_dbo.SP_M_CryptoRebateDiamond` (Tom Boksenbojm original; migrated to BI_DB 2025-09-30 by Ofir Chloe Gal)
**Grain:** One row per {MonthEndDate × CID × Regulation × Club}. Monthly snapshot — full month overwrite.

---

## 2. Table Metadata

| Property | Value |
|----------|-------|
| Schema | `BI_DB_dbo` |
| Table | `Dealing_CryptoRebate` |
| Distribution | `ROUND_ROBIN` |
| Index | `CLUSTERED INDEX (MonthEndDate ASC)` |
| Columns | 21 |
| Total rows | 210,026 |
| Date range | 2022-03-31 → 2026-03-31 (49 months) |
| Distinct CIDs | 41,463 |
| OpsDB priority | 20 |
| Frequency | Monthly |
| ProcessType | 1 (SQL) |

---

## 3. Column Reference

### 3.1 Date & ETL Metadata

| Column | Type | Description |
|--------|------|-------------|
| `MonthEndDate` | date | Last calendar day of the reporting month. Computed as `EOMONTH` of the input month from the SP @Date parameter. ETL partition key (Tier 2 — SP_M_CryptoRebateDiamond) |
| `UPdatedate` | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline (Tier 1 — ETL metadata) |

### 3.2 Client Identity & Segmentation

| Column | Type | Description |
|--------|------|-------------|
| `CID` | int | Client identifier. Only Diamond (PlayerLevelID=7) and Platinum Plus (PlayerLevelID=6) members who are valid customers, not in excluded guru statuses, and not in excluded countries are included (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `Club` | varchar(100) | CopyTrader tier at month-end snapshot. Values: `1 Diamond` (PlayerLevelID=7), `1 Platinum Plus` (PlayerLevelID=6). The numeric prefix '1' represents the tier ranking in the SP implementation (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `GuruStatus_ID` | int | Popular Investor / guru program status ID from `Fact_SnapshotCustomer.GuruStatusID`. CIDs with GuruStatusID IN (2,3,4,5,6) are excluded from the rebate program (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `Country` | varchar(100) | Client's registered country at month-end from `DWH_dbo.Dim_Country`. Clients from Austria, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, United Kingdom are excluded from the rebate program (Tier 2 — DWH_dbo.Dim_Country) |
| `Region` | varchar(100) | Marketing region from `DWH_dbo.Fact_SnapshotCustomer.Region` (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| `Regulation` | varchar(100) | Regulatory jurisdiction at month-end from `DWH_dbo.Dim_Regulation.Name` (Tier 2 — DWH_dbo.Dim_Regulation) |

### 3.3 Volume Metrics

All volume figures are in USD, computed from crypto spot positions closed within the month. Eligible positions: InstrumentTypeID=10 (crypto), IsSettled=1, IsDiscounted=0, IsBuy=1, MirrorID=0, Leverage=1, OpenDateID≥2022-03-08.

| Column | Type | Description |
|--------|------|-------------|
| `OpenedVolume` | float | Total USD notional at open for eligible closed positions: `SUM(AmountInUnitsDecimal × InitForexRate × InitForex_USDConversionRate)`. Uses open-date forex rates. ISNULL(rate,1) applied for missing rates (Tier 2 — DWH_dbo.Dim_Position) |
| `ClosedVolume` | float | Total USD notional at close for eligible closed positions: `SUM(AmountInUnitsDecimal × EndForexRate × LastOpConversionRate)`. Uses close-date forex rates (Tier 2 — DWH_dbo.Dim_Position) |
| `TotalVolume` | float | `OpenedVolume + ClosedVolume`. Total notional volume (sum of open and close values). This double-counts the notional but is the defined basis for the rebate calculation (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Markup` | float | Estimated spread revenue: `TotalVolume × 0.01`. Approximates 1% of total notional as eToro's crypto spread income from these positions (Tier 2 — SP_M_CryptoRebateDiamond) |

### 3.4 Bracket Volume Allocation

The rebate tier structure applies to TotalVolume with a $50,000 minimum threshold before any rebate-eligible volume accrues:

| Column | Type | Description |
|--------|------|-------------|
| `Bracket1_Volume` | float | Volume in the $50,001–$1,000,000 tier: `CASE WHEN TotalVolume>50000 AND TotalVolume<=1000000 THEN TotalVolume-50000 WHEN TotalVolume>1000000 THEN 950000 ELSE 0 END`. Maximum $950,000 (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket2_Volume` | float | Volume in the $1,000,001–$5,000,000 tier: `CASE WHEN TotalVolume>1000000 AND TotalVolume<=5000000 THEN TotalVolume-1000000 WHEN TotalVolume>5000000 THEN 4000000 ELSE 0 END`. Maximum $4,000,000 (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket3_Volume` | float | Volume above $5,000,000: `CASE WHEN TotalVolume>5000000 THEN TotalVolume-5000000 ELSE 0 END`. Uncapped (Tier 2 — SP_M_CryptoRebateDiamond) |

### 3.5 Rebate Calculations

| Column | Type | Description |
|--------|------|-------------|
| `Bracket1_Rebate` | float | `Bracket1_Volume × 0.15%`. Rebate at 0.15% rate for volume in the $50K–$1M tier (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket2_Rebate` | float | `Bracket2_Volume × 0.25%`. Rebate at 0.25% rate for volume in the $1M–$5M tier (Tier 2 — SP_M_CryptoRebateDiamond) |
| `Bracket3_Rebate` | float | `Bracket3_Volume × 0.50%`. Rebate at 0.50% rate for volume above $5M (Tier 2 — SP_M_CryptoRebateDiamond) |
| `TotalRebate` | float | `CASE WHEN (Bracket1_Rebate+Bracket2_Rebate+Bracket3_Rebate) < 5 THEN 0 ELSE sum END`. Minimum rebate threshold: rebates below $5 are zeroed out. Final USD rebate amount owed to the client for the month (Tier 2 — SP_M_CryptoRebateDiamond) |

---

## 4. Business Rules

### 4.1 Rebate Eligibility
Only clients meeting ALL conditions are included:
- Club tier: Diamond (PlayerLevelID=7) or Platinum Plus (PlayerLevelID=6)
- IsValidCustomer = 1
- GuruStatusID NOT IN (2,3,4,5,6)
- Country NOT IN: Austria, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, United Kingdom

### 4.2 Eligible Position Criteria
Positions must meet ALL:
- InstrumentTypeID = 10 (Crypto Currencies only)
- IsSettled = 1 (spot crypto under custody, not CFD)
- IsDiscounted = 0
- IsBuy = 1 (long only)
- MirrorID = 0 (not CopyTrader mirrors)
- Leverage = 1 (unlevered)
- CloseDateID in the reporting month
- OpenDateID ≥ 2022-03-08 (rebate plan start date, hardcoded)

### 4.3 Rebate Tier Schedule

| Tier | Volume Range | Rate |
|------|-------------|------|
| Below minimum | ≤ $50,000 | No rebate |
| Bracket 1 | $50,001 – $1,000,000 | 0.15% |
| Bracket 2 | $1,000,001 – $5,000,000 | 0.25% |
| Bracket 3 | > $5,000,000 | 0.50% |

### 4.4 Minimum Rebate Threshold
If total rebate (all brackets combined) < $5, TotalRebate is set to $0. This prevents micro-payments to clients with very low trading volumes.

### 4.5 Volume Double-Counting
TotalVolume = OpenedVolume + ClosedVolume intentionally sums both the open-date and close-date notional values of each position. This is the defined business metric for the rebate calculation, not a data error.

---

## 5. Data Profile

| Metric | Value |
|--------|-------|
| Total rows | 210,026 (49 months, 2022-03-31 to 2026-03-31) |
| Distinct CIDs across all months | 41,463 |
| Rows per month (2026-03-31) | ~5,853 (802 Diamond + 5,051 Platinum Plus) |
| Diamond rows with TotalRebate > 0 (2026-03-31) | 214 / 802 (27%) |
| Platinum Plus rows with TotalRebate > 0 (2026-03-31) | 450 / 5,051 (9%) |
| Diamond avg TotalVolume (2026-03-31) | ~$90,073 |
| Platinum Plus avg TotalVolume (2026-03-31) | ~$19,029 |
| Diamond avg TotalRebate (2026-03-31) | ~$111 |
| Platinum Plus avg TotalRebate (2026-03-31) | ~$11 |

---

## 6. Lineage & Upstream Sources

See [`BI_DB_Dealing_CryptoRebate.lineage.md`](BI_DB_Dealing_CryptoRebate.lineage.md) for full column-level lineage.

**Primary upstream sources:**
- `DWH_dbo.Fact_SnapshotCustomer` — Club eligibility and client segmentation at month-end
- `DWH_dbo.Dim_Position` — Closed crypto position volumes (open/close forex rates, units)
- `DWH_dbo.Dim_Instrument` — InstrumentTypeID=10 filter

---

## 7. Downstream Consumers

No downstream SP or view consumers identified in the BI_DB_dbo SSDT repo. This is a terminal reporting table consumed directly by BI tools / finance reporting.

---

## 8. Notes & Review Flags

- The `Club` column uses a numeric prefix ('1 Diamond', '1 Platinum Plus') from the SP implementation. The '1' prefix is a sorting artifact from the CASE statement — there is no '2' equivalent.
- Country exclusion list is hardcoded in the SP. It excludes EU countries where eToro cannot operate the rebate program. France was added on 2025-10-20 per change log — but the France exclusion is not yet reflected in the WHERE clause (the change log says "Adding France country" but the code shows no France exclusion). This may be applied in a different version or may have been reverted.
- OpenDateID >= 20220308 is a hardcoded rebate plan start date — positions opened before this date do not count toward rebates even if closed after.
- The companion table `Dealing_Unrealized_CryptoRebate` is written by the same SP in the same run, covering still-open positions at month-end.
