# Compare — `DWH_dbo.V_Liabilities`

**Bucket**: `good`

**Verdict**: **BETTER**  (score delta +3.45; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 5.3 | 8.75 | 3.45 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 0 | 75 | +75 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 63 | +63 |
| T2 count | 0 | 12 | +12 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 4 | 8 |
| data_evidence | 2 | 8 |
| shape_fidelity | 5 | 9 |
| tier_accuracy | 8 | 10 |
| upstream_fidelity | 3 | 8 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.0 | None | 1 |  | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 1 — Fact_SnapshotEquity) |
| `2` | 0.0 | None | 1 |  | Individual calendar date key in YYYYMMDD integer format. Falls within the range defined by Dim_Range.FromDateID and Dim_Range.ToDateID (inclusive). Renamed from DateKey. (Tier 1 — V_M2M_Date_DateRange |
| `3` | 0.0 | None | 1 |  | Calendar date corresponding to DateKey in native DATE format. Provides the human-readable date for the YYYYMMDD integer key. (Tier 1 — V_M2M_Date_DateRange) |
| `4` | 0.0 | None | 1 |  | Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: "Unrealized  |
| `5` | 0.0 | None | 1 |  | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day |
| `6` | 0.0 | None | 1 |  | Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approa |
| `7` | 0.0 | None | 1 |  | Sum of pending withdrawal amounts for this CID that have not yet been finalized (statuses other than 3=Processed, 4=Cancelled, 5,6). Includes partially processed amounts for split-payment withdrawals  |
| `8` | 0.0 | None | 1 |  | Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only, excluding the parent/guru's own positions). Represents the CID's total investment in copy relationshi |
| `9` | 0.0 | None | 1 |  | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 — Fact_SnapshotEquity) |
| `10` | 0.0 | None | 1 |  | Legacy column, hardcoded to 0. Removed 2019-03-03 (Boris Slutski) — no data in PROD since 2015. Kept for schema compatibility. (Tier 1 — Fact_SnapshotEquity) |

## Top issues — regen wiki (per judge)

- [low] `Property table` — Missing explicit 'Distribution' row in the property table. HASH(CID) info is documented in Section 3.1 but not in the structured property table that tooling may parse.
- [low] `TotalCryptoPositionAmount` — Dropped upstream Confluence relationship note: 'TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount (approximately, excluding other types)'. This is a useful analyst hint about column relationships.
- [low] `Section 4 (28 columns from Fact_CustomerUnrealized_PnL)` — 28 columns from Fact_CustomerUnrealized_PnL tagged Tier 1 but no upstream wiki exists in the bundle. Descriptions are well-written from DDL/SP logic but cannot be 'verbatim copies' since there is nothing to copy from. A Tier Legend footnote would clarify this.
- [info] `Shape — Phase Gate` — No explicit Phase Gate Checklist section in the wiki body; completed phases only listed in the footer line.
- [info] `TotalStockMarginLoanValue` — Dropped 'Formula updated 2025-12-10 to use InitConversionRate' — minor changelog metadata but could be useful for analysts debugging historical formula changes.
