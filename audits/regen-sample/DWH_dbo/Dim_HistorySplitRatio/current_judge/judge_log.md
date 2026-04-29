## Judge Review: DWH_dbo.Dim_HistorySplitRatio

### Critical Finding: Upstream Wiki Completely Ignored

The upstream bundle includes a comprehensive wiki for `History.SplitRatio` (the production source), yet the writer tagged **zero** columns as Tier 1. All 8 passthrough columns from `PriceLog.History.SplitRatio` have upstream descriptions available, but the writer wrote original descriptions instead of quoting verbatim. This is the single most damaging failure mode for this wiki.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 3/10**
Sampled 5 columns: `ID`, `InstrumentID`, `PriceRatio`, `MinDate`, `AmountRatioUnAdjusted`. All 5 are passthroughs from `PriceLog.History.SplitRatio` with an upstream wiki present in the bundle → all 5 should be Tier 1. The wiki tags them as Tier 2 or Tier 3. That is 5/5 mismatches → base score 3.

**Dimension 2 — Upstream Fidelity: 2/10**
8 columns are passthroughs with an available upstream wiki. Zero are tagged Tier 1. Zero use verbatim upstream text. Every description is rewritten. This is 8 missed inheritances at −2 each, capped at the floor. Details in the fidelity table below.

**Dimension 3 — Completeness: 7/10**
8/9 applicable checklist items pass. Missing: Section 1 lacks an explicit data date-range statement (only row count). All 8 sections present, element count matches DDL (9=9), tier tags on every element, property table complete, ETL diagram present, footer has tier breakdown, review-needed sidecar is clean.

**Dimension 4 — Business Meaning: 8/10**
Section 1 is genuinely strong: names the domain (stock split adjustment factors), describes row grain (one row per instrument per date range), names the ETL SP, describes TRUNCATE+INSERT pattern, gives row count (15,899). Missing the data date-range, but otherwise specific and actionable.

**Dimension 5 — Data Evidence: 6/10**
Row count present (15,899). Sentinel values documented. Specific instrument example (4459 with 15 splits). UpdateDate timestamp cited. However, no explicit Phase Gate Checklist section, footer says "Phases: 9/14" without specifying which were skipped. Distribution analysis is absent.

**Dimension 6 — Shape Fidelity: 8/10**
All numbered sections present, tier legend in Section 4, real SQL in Section 7, footer has quality score and tier breakdown. Minor: no explicit Phase Gate Checklist subsection.

---

### T1 Fidelity Table

All 8 passthrough columns SHOULD be Tier 1 but are not tagged as such. Comparing what the upstream wiki says vs. what the writer wrote:

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| ID | "Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event." | "Sequential integer primary key for the split ratio record. Passed through from PriceLog.History.SplitRatio without transformation." | NO | Dropped IDENTITY, NOT FOR REPLICATION, "split event" specificity |
| InstrumentID | "The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto)." | "Instrument identifier (FK to DWH_dbo.Dim_Currency.CurrencyID and DWH_dbo.Dim_Instrument.InstrumentID). Groups all split ratio records for a single tradeable instrument." | NO | Dropped CHECK >1000 constraint, dropped stocks-only restriction, changed FK target from Trade.Instrument to Dim_Currency |
| MinDate | "Start of the period this split ratio is effective. Default '2000-01-01' means 'from the beginning of the instrument's history.' The split adjustment applies to transactions from this date forward until MaxDate." | "Start of the date range (inclusive) for which the ratio applies. `2000-01-01` is the beginning-of-history sentinel for the earliest period before any splits." | MINOR | Meaning preserved but reworded; dropped "applies to transactions from this date forward" detail |
| MaxDate | "End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means 'currently active - no end date set.' When a new split occurs, the current active row's MaxDate is set to the new split's MinDate." | "End of the date range (exclusive) for which the ratio applies. `2100-01-01` is the open-ended sentinel indicating the currently active ratio (no further splits yet)." | NO | Dropped update behavior ("current active row's MaxDate is set to the new split's MinDate") |
| PriceRatio | "Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment." | "Cumulative price adjustment multiplier for this period. Multiply a historical price by this value to get its split-adjusted equivalent. 1.0 means no adjustment. Example: PriceRatio=0.25 means a 4:1 stock split occurred..." | NO | Dropped UnitsBefore/UnitsAfter formula, CHECK >0 constraint, changed examples, added "cumulative" which upstream doesn't say |
| AmountRatio | "Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment." | "Cumulative amount/quantity adjustment multiplier for this period. Multiply a historical position size by this value to get the split-adjusted share count. Inverse of PriceRatio: AmountRatio=4.0 corresponds to PriceRatio=0.25 (4:1 split)." | NO | Dropped formula, CHECK constraint, changed examples, added "cumulative" |
| PriceRatioUnAdjusted | "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison." | "Incremental (non-cumulative) price ratio from the most recent split event only, before stacking with prior splits. Used to isolate the effect of a single split. 1.0 for the oldest period (before any splits)." | NO | Dropped "money type", fabricated "incremental" semantics not in upstream, added claims not backed by source |
| AmountRatioUnAdjusted | "Original unadjusted amount ratio stored as money type. Before cumulative adjustments." | "Incremental (non-cumulative) amount ratio from the most recent split event only. Inverse of PriceRatioUnAdjusted for the current split. 1.0 for the oldest period (before any splits)." | NO | Dropped "money type", fabricated semantics |

---

### Top 5 Issues

1. **[HIGH] All 8 passthrough columns mistagged** — ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted are all passthroughs from `PriceLog.History.SplitRatio` with an upstream wiki available. All should be `(Tier 1 — History.SplitRatio)` with verbatim descriptions. Instead tagged Tier 2/Tier 3 with rewritten text.

2. **[HIGH] InstrumentID drops stock-only CHECK constraint** — Upstream documents `CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto)`. Wiki replaces this with a generic FK reference to Dim_Currency, losing a critical business rule.

3. **[HIGH] PriceRatioUnAdjusted / AmountRatioUnAdjusted descriptions fabricated** — Upstream says "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison." Writer invented "incremental (non-cumulative) price ratio from the most recent split event only" which is not what the upstream states.

4. **[MEDIUM] PriceRatio/AmountRatio formulas dropped** — Upstream provides the computation formulas (`UnitsBefore/UnitsAfter` and `UnitsAfter/UnitsBefore`). The wiki drops these and adds the word "cumulative" which the upstream does not use — the DWH copy may carry cumulative semantics but the upstream description should be quoted verbatim.

5. **[MEDIUM] Footer claims 0 T1 columns** — Footer reads "Tiers: 0 T1, 3 T2, 6 T3, 0 T4" when 8 columns should be T1. This signals the writer never consulted the upstream bundle.

---

### Regeneration Feedback

1. Re-tag all 8 passthrough columns (ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted) as `(Tier 1 — History.SplitRatio)` and use **verbatim** descriptions from the upstream wiki at `DB_Schema\etoro\Wiki\History\Tables\History.SplitRatio.md`.
2. For `InstrumentID`, preserve the CHECK constraint (`InstrumentID > 1000 — stocks only`) and the FK to `Trade.Instrument` from the upstream wiki.
3. For `PriceRatioUnAdjusted` and `AmountRatioUnAdjusted`, use the upstream text ("Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison.") — do NOT fabricate "incremental" semantics.
4. For `PriceRatio` and `AmountRatio`, include the `UnitsBefore/UnitsAfter` formulas and CHECK constraint from upstream.
5. Add explicit data date-range to Section 1 (e.g., "MinDate spans from 2000-01-01 sentinel to recent split dates; MaxDate uses 2100-01-01 as active sentinel").
6. Update the footer tier counts to reflect the corrected tier assignments (8 T1, 0 T2 for passthrough columns, 1 T2 for UpdateDate).

---

### Weighted Score

```
weighted = 0.25×3 + 0.20×2 + 0.20×7 + 0.15×8 + 0.10×6 + 0.10×8
         = 0.75 + 0.40 + 1.40 + 1.20 + 0.60 + 0.80
         = 5.15
```

**Verdict: FAIL**

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_HistorySplitRatio",
  "weighted_score": 5.15,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 2,
    "completeness": 7,
    "business_meaning": 8,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "ID",
      "upstream_quote": "Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event.",
      "wiki_quote": "Sequential integer primary key for the split ratio record. Passed through from PriceLog.History.SplitRatio without transformation.",
      "match": "NO",
      "loss": "Dropped IDENTITY, NOT FOR REPLICATION detail, 'split event' specificity; completely reworded"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto).",
      "wiki_quote": "Instrument identifier (FK to DWH_dbo.Dim_Currency.CurrencyID and DWH_dbo.Dim_Instrument.InstrumentID). Groups all split ratio records for a single tradeable instrument.",
      "match": "NO",
      "loss": "Dropped CHECK >1000 constraint, stocks-only restriction, changed FK target from Trade.Instrument to Dim_Currency"
    },
    {
      "column": "MinDate",
      "upstream_quote": "Start of the period this split ratio is effective. Default '2000-01-01' means 'from the beginning of the instrument's history.' The split adjustment applies to transactions from this date forward until MaxDate.",
      "wiki_quote": "Start of the date range (inclusive) for which the ratio applies. `2000-01-01` is the beginning-of-history sentinel for the earliest period before any splits.",
      "match": "MINOR",
      "loss": "Reworded; dropped 'applies to transactions from this date forward until MaxDate'"
    },
    {
      "column": "MaxDate",
      "upstream_quote": "End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means 'currently active - no end date set.' When a new split occurs, the current active row's MaxDate is set to the new split's MinDate.",
      "wiki_quote": "End of the date range (exclusive) for which the ratio applies. `2100-01-01` is the open-ended sentinel indicating the currently active ratio (no further splits yet).",
      "match": "NO",
      "loss": "Dropped update behavior ('current active row's MaxDate is set to the new split's MinDate')"
    },
    {
      "column": "PriceRatio",
      "upstream_quote": "Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment.",
      "wiki_quote": "Cumulative price adjustment multiplier for this period. Multiply a historical price by this value to get its split-adjusted equivalent. 1.0 means no adjustment. Example: PriceRatio=0.25 means a 4:1 stock split occurred (1 old share = 4 new shares, price adjusted down to 25%).",
      "match": "NO",
      "loss": "Dropped UnitsBefore/UnitsAfter formula, CHECK >0 constraint, changed examples, added 'cumulative' not in upstream"
    },
    {
      "column": "AmountRatio",
      "upstream_quote": "Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment.",
      "wiki_quote": "Cumulative amount/quantity adjustment multiplier for this period. Multiply a historical position size by this value to get the split-adjusted share count. Inverse of PriceRatio: AmountRatio=4.0 corresponds to PriceRatio=0.25 (4:1 split).",
      "match": "NO",
      "loss": "Dropped formula (UnitsAfter/UnitsBefore), CHECK constraint, changed examples, added 'cumulative'"
    },
    {
      "column": "PriceRatioUnAdjusted",
      "upstream_quote": "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison.",
      "wiki_quote": "Incremental (non-cumulative) price ratio from the most recent split event only, before stacking with prior splits. Used to isolate the effect of a single split. 1.0 for the oldest period (before any splits).",
      "match": "NO",
      "loss": "Dropped 'money type', fabricated 'incremental/non-cumulative' semantics and 'most recent split event only' not stated in upstream"
    },
    {
      "column": "AmountRatioUnAdjusted",
      "upstream_quote": "Original unadjusted amount ratio stored as money type. Before cumulative adjustments.",
      "wiki_quote": "Incremental (non-cumulative) amount ratio from the most recent split event only. Inverse of PriceRatioUnAdjusted for the current split. 1.0 for the oldest period (before any splits).",
      "match": "NO",
      "loss": "Dropped 'money type', fabricated 'incremental' semantics not in upstream"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted",
      "problem": "All 8 passthrough columns from PriceLog.History.SplitRatio are mistagged as Tier 2 or Tier 3. Upstream wiki (History.SplitRatio.md) was available in the bundle. All should be Tier 1 with verbatim upstream descriptions."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentID",
      "problem": "Dropped CHECK constraint (InstrumentID > 1000 — stocks only, not forex or crypto) and changed FK target from Trade.Instrument to Dim_Currency. Critical business rule lost."
    },
    {
      "severity": "high",
      "column_or_section": "PriceRatioUnAdjusted, AmountRatioUnAdjusted",
      "problem": "Upstream says 'Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison.' Writer fabricated 'Incremental (non-cumulative) price ratio from the most recent split event only' — semantics not in upstream wiki."
    },
    {
      "severity": "medium",
      "column_or_section": "PriceRatio, AmountRatio",
      "problem": "Dropped computation formulas (UnitsBefore/UnitsAfter, UnitsAfter/UnitsBefore) and CHECK >0 constraints from upstream. Added 'cumulative' qualifier not present in upstream text."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '0 T1, 3 T2, 6 T3' when 8 columns should be T1 and only 1 (UpdateDate) should be T2. Signals upstream bundle was never consulted."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag all 8 passthrough columns (ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, PriceRatioUnAdjusted, AmountRatioUnAdjusted) as Tier 1 — History.SplitRatio and use VERBATIM descriptions from the upstream wiki at DB_Schema/etoro/Wiki/History/Tables/History.SplitRatio.md. (2) For InstrumentID, preserve the CHECK >1000 constraint and FK to Trade.Instrument from upstream. (3) For PriceRatioUnAdjusted and AmountRatioUnAdjusted, use upstream text verbatim — do NOT fabricate 'incremental' semantics. (4) For PriceRatio and AmountRatio, include UnitsBefore/UnitsAfter formulas and CHECK >0 constraint from upstream. (5) Add explicit data date-range to Section 1. (6) Update footer tier counts to 8 T1, 1 T2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phases 9/14 — specific skipped phases not enumerated in footer"]
  }
}
</JUDGE_VERDICT>
