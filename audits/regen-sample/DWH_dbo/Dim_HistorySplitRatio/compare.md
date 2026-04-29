# Compare — `DWH_dbo.Dim_HistorySplitRatio`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +4.35; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 5.15 | 9.5 | 4.35 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 9 | 9 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 8 | +8 |
| T2 count | 3 | 1 | -2 |
| T3 count | 6 | 0 | -6 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 10 |
| completeness | 7 | 10 |
| data_evidence | 6 | 8 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 2 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `5` | 0.13 | 3 | 1 | Cumulative price adjustment multiplier for this period. Multiply a historical price by this value to get its split-adjusted equivalent. 1.0 means no adjustment. Example: PriceRatio=0.25 means a 4:1 st | Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constrai |
| `7` | 0.135 | 3 | 1 | Incremental (non-cumulative) price ratio from the most recent split event only, before stacking with prior splits. Used to isolate the effect of a single split. 1.0 for the oldest period (before any s | Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. DWH note: stored as decimal(19,4) in Synapse (money in production) |
| `6` | 0.18 | 3 | 1 | Cumulative amount/quantity adjustment multiplier for this period. Multiply a historical position size by this value to get the split-adjusted share count. Inverse of PriceRatio: AmountRatio=4.0 corres | Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK co |
| `4` | 0.221 | 3 | 1 | End of the date range (exclusive) for which the ratio applies. `2100-01-01` is the open-ended sentinel indicating the currently active ratio (no further splits yet). (Tier 3 -- live data, PriceLog.His | End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means "currently active — no end date set." When a new split occurs, the current active row's MaxDate is set to |
| `1` | 0.328 | 2 | 1 | Sequential integer primary key for the split ratio record. Passed through from PriceLog.History.SplitRatio without transformation. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) | Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event. (Tier 1 — History.SplitRatio) |
| `3` | 0.335 | 3 | 1 | Start of the date range (inclusive) for which the ratio applies. `2000-01-01` is the beginning-of-history sentinel for the earliest period before any splits. (Tier 3 -- live data, PriceLog.History.Spl | Start of the period this split ratio is effective. Default '2000-01-01' means "from the beginning of the instrument's history." The split adjustment applies to transactions from this date forward unti |
| `8` | 0.351 | 3 | 1 | Incremental (non-cumulative) amount ratio from the most recent split event only. Inverse of PriceRatioUnAdjusted for the current split. 1.0 for the oldest period (before any splits). (Tier 3 -- live d | Original unadjusted amount ratio stored as money type. Before cumulative adjustments. DWH note: stored as decimal(19,4) in Synapse (money in production). (Tier 1 — History.SplitRatio) |
| `2` | 0.454 | 2 | 1 | Instrument identifier (FK to DWH_dbo.Dim_Currency.CurrencyID and DWH_dbo.Dim_Instrument.InstrumentID). Groups all split ratio records for a single tradeable instrument. (Tier 2 -- SP_Dim_HistorySplitR | The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 — only stock instruments (not forex or crypto). (Tier 1 — History.SplitRatio) |
| `9` | 0.465 | 2 | 2 | ETL load timestamp -- set to GETDATE() by SP_Dim_HistorySplitRatio_DL_To_Synapse at each reload. Not from the production source. Reflects when DWH was last refreshed, not when the split data changed.  | ETL load timestamp — set to GETDATE() on each truncate/reload by SP_Dim_HistorySplitRatio_DL_To_Synapse. All rows share the same value after each daily refresh. (Tier 2 — SP_Dim_HistorySplitRatio_DL_T |

## Top issues — regen wiki (per judge)

- [low] `InstrumentID, MaxDate` — Hyphen-to-em-dash substitution in Tier 1 descriptions. Trivial but not byte-identical to upstream.
- [low] `Footer` — [UNVERIFIED] tag in tier counts is unnecessary — all columns are verified against the bundle.
- [low] `Shape` — No explicit Phase Gate Checklist section. Footer claims Phases: 11/11 but the checklist is not rendered.
