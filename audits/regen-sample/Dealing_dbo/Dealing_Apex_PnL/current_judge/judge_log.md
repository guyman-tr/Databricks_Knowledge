I'll review this wiki systematically. Let me first verify the upstream Dim_Instrument wiki to confirm the descriptions for the columns that should be inherited.

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy: **7/10**

**Random 5 columns sampled:** `Date`, `AccountNumber`, `InstrumentID`, `PnL`, `Zero`

| Column | Lineage Source | Expected Tier | Wiki Tier | Match? |
|--------|---------------|--------------|-----------|--------|
| Date | SP parameter `@Date`, passthrough | Tier 2 (no upstream wiki) | Tier 2 — SP_Apex_PnL | YES |
| AccountNumber | LP_APEX_EXT982_3EU.AccountNumber, passthrough | Tier 2 (external staging, no wiki) | Tier 2 — SP_Apex_PnL | YES |
| InstrumentID | DWH_dbo.Dim_Instrument.InstrumentID via Symbol/CUSIP/ISIN join | **Tier 1 — Dim_Instrument** (dim-lookup passthrough) | Tier 2 — SP_Apex_PnL | **NO** |
| PnL | Computed: NOP_End - NOP_Start - Trades + Dividends + AdditionalFees | Tier 2 (ETL-computed) | Tier 2 — SP_Apex_PnL | YES |
| Zero | Dealing_DailyZeroPnL_Stocks.TotalZero, SUM over week | Tier 2 (ETL-computed aggregation) | Tier 2 — SP_Apex_PnL | YES |

1 mismatch → base score 7. `InstrumentDisplayName` is the same pattern (dim-lookup passthrough from Dim_Instrument, tagged Tier 2 instead of Tier 1) — systematic issue, not just a one-off.

### Dimension 2 — Upstream Fidelity: **3/10**

The wiki claims **0 Tier 1 columns**. The upstream bundle includes the full `DWH_dbo.Dim_Instrument` wiki with documented descriptions for both `InstrumentID` and `InstrumentDisplayName`. Both are dim-lookup passthroughs — the SP selects the value from Dim_Instrument with no transformation. Per the rubric, these must be Tier 1 with the dim's origin description quoted verbatim.

**Missed inheritances:** 2 (InstrumentID, InstrumentDisplayName) → "Wrong tier origin (relay instead of root)" = **3**.

### T1 Fidelity Table

Since the wiki declares 0 Tier 1 columns, there are no declared T1 entries to compare. However, these columns **should** be Tier 1:

| Column | Upstream (Dim_Instrument) Quote | Wiki Quote | Match | Loss |
|--------|--------------------------------|-----------|-------|------|
| InstrumentID | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- upstream wiki, Trade.Instrument)" | "**eToro instrument key** from **`DWH_dbo.Dim_Instrument`** when Apex identifiers match; **NULL** if no match. (Tier 2 — SP_Apex_PnL)" | NO | Dropped upstream origin (Trade.Instrument), dropped ID range, dropped FK references, paraphrased to generic "instrument key", wrong tier |
| InstrumentDisplayName | "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)" | "**eToro display name** for the instrument — may differ from Apex **`Symbol`**. (Tier 2 — SP_Apex_PnL)" | NO | Dropped source (Trade.InstrumentMetaData), dropped example values, dropped NULL semantics, paraphrased to generic description |

### Dimension 3 — Completeness: **6/10**

| Check | Status |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL column count (21 = 21) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Production Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 ETL pipeline ASCII diagram in wiki | **FAIL** — delegated to lineage file; no diagram in the wiki body |
| Footer has tier breakdown counts | PASS |
| Section 1 contains row count and date range | **FAIL** — row count (~3.0M) and full date range (2021-02-10 – 2024-06-07) appear in Section 3, not Section 1 |
| Dictionary columns ≤15 values list inline | N/A (no applicable columns) — counted as pass |
| `.review-needed.md` does NOT contain `## 4. Elements` | PASS |

8/10 → **6**.

### Dimension 4 — Business Meaning: **8/10**

Section 1 is well-written: names the domain (Apex Clearing LP, Middle Office reconciliation), specifies row grain (`Date, AccountNumber, Symbol`), identifies the ETL SP (`SP_Apex_PnL`), explains the weekly WTD refresh pattern, prominently flags stale data with specific dates, and explains the Apex-vs-DB price reconciliation intent. Missing: row count not in Section 1 (it's buried in Section 3).

### Dimension 5 — Data Evidence: **6/10**

Row count (~3.0M) and date range are present but in Section 3. Stale data flag is well-evidenced with specific dates (last row 2024-06-07, last load 2024-06-08 09:19). Section 1 mentions "Phase 2 sampling confirmed stale data" but there is no formal Phase Gate Checklist section with `[x]` marks for P2/P3. No NULL-rate distributions or enum value lists. Data claims appear grounded but the formal evidence framework is incomplete.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8 present. Tier legend in Section 4. Real SQL samples in Section 7 (three practical queries). Footer includes quality score and tier breakdown. Minor deviations: no explicit phases-completed list in footer (uses element/logic/relationship/sources breakdown instead), tier legend omits Tier 1 and Tier 3 rows entirely (should show all tiers even if count is 0).

---

## Weighted Score

```
weighted = 0.25×7 + 0.20×3 + 0.20×6 + 0.15×8 + 0.10×6 + 0.10×8
         = 1.75 + 0.60 + 1.20 + 1.20 + 0.60 + 0.80
         = 6.15
```

**Verdict: FAIL** (6.15 < 7.5)

---

## Top 5 Issues

1. **HIGH — InstrumentID (Tier misclassification):** Tagged `(Tier 2 — SP_Apex_PnL)` but is a dim-lookup passthrough from `DWH_dbo.Dim_Instrument`. Should be `(Tier 1 — Dim_Instrument, Trade.Instrument)` with verbatim upstream description.

2. **HIGH — InstrumentDisplayName (Tier misclassification):** Same pattern — dim-lookup passthrough tagged Tier 2. Should be `(Tier 1 — Dim_Instrument, Trade.InstrumentMetaData)` with verbatim upstream description including NULL semantics and example values.

3. **MEDIUM — Section 1 missing row count and date range:** The ~3.0M row count and 2021-02-10 start date appear only in Section 3 Query Advisory. Section 1 should include these for a self-contained business summary.

4. **MEDIUM — No ETL pipeline ASCII diagram in wiki body:** Section 5 delegates entirely to the lineage sidecar. The wiki should include a Section 5.2 diagram with real SP/table names inline.

5. **LOW — No Phase Gate Checklist section:** The wiki mentions P2 was done in passing but has no formal `[x]`/`[ ]` checklist for P1–P3, making evidence claims unverifiable.

---

## Regeneration Feedback

1. Re-tag `InstrumentID` as `(Tier 1 — Dim_Instrument, Trade.Instrument)` and use the verbatim description from the Dim_Instrument wiki: *"Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated..."* — adapted to note NULL when unmatched.
2. Re-tag `InstrumentDisplayName` as `(Tier 1 — Dim_Instrument, Trade.InstrumentMetaData)` and use verbatim: *"User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries."*
3. Move row count (~3.0M) and full date range (2021-02-10 – 2024-06-07) into Section 1.
4. Add a Section 5.2 ETL pipeline ASCII diagram in the wiki body (not just in the lineage sidecar).
5. Add a Phase Gate Checklist section with explicit `[x]`/`[ ]` marks for P1–P3.
6. Update the tier legend in Section 4 to include Tier 1 row (now applicable).
7. Update the footer tier breakdown to reflect the corrected T1 count (at least 2 T1, 19 T2).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL",
  "weighted_score": 6.15,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 3,
    "completeness": 6,
    "business_meaning": 8,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- upstream wiki, Trade.Instrument)",
      "wiki_quote": "**eToro instrument key** from **`DWH_dbo.Dim_Instrument`** when Apex identifiers match; **NULL** if no match. (Tier 2 — SP_Apex_PnL)",
      "match": "NO",
      "loss": "Wrong tier (Tier 2 instead of Tier 1). Dropped upstream origin (Trade.Instrument), dropped ID range (0 to ~21M), dropped FK references (Dim_Currency, Dim_HistorySplitRatio), paraphrased to generic 'instrument key'."
    },
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)",
      "wiki_quote": "**eToro display name** for the instrument — may differ from Apex **`Symbol`**. (Tier 2 — SP_Apex_PnL)",
      "match": "NO",
      "loss": "Wrong tier (should be Tier 1 from Dim_Instrument). Dropped source (Trade.InstrumentMetaData), dropped example values ('Apple Inc.' vs 'Apple'), dropped NULL semantics, paraphrased to generic description."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "InstrumentID",
      "problem": "Tagged Tier 2 (SP_Apex_PnL) but is a dim-lookup passthrough from DWH_dbo.Dim_Instrument. Dim_Instrument documents InstrumentID as Tier 1 from Trade.Instrument. Writer should have used Tier 1 with the dim's root origin description verbatim."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentDisplayName",
      "problem": "Tagged Tier 2 (SP_Apex_PnL) but is a dim-lookup passthrough from DWH_dbo.Dim_Instrument. Upstream description includes source (Trade.InstrumentMetaData), example values, and NULL semantics — all dropped."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "Row count (~3.0M) and full date range (2021-02-10 through 2024-06-07) appear only in Section 3 Query Advisory, not in Section 1 Business Meaning."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "No ETL pipeline ASCII diagram in the wiki body. Section 5 delegates entirely to the lineage sidecar file. The wiki should include an inline Section 5.2 diagram with real SP and table names."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No formal Phase Gate Checklist section with [x]/[ ] marks for P1-P3. Section 1 mentions Phase 2 sampling in passing but evidence framework is not structured."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag InstrumentID as Tier 1 from Dim_Instrument (root: Trade.Instrument) and quote the upstream description verbatim, noting NULL when Apex symbols are unmatched. (2) Re-tag InstrumentDisplayName as Tier 1 from Dim_Instrument (root: Trade.InstrumentMetaData) with verbatim description including example values and NULL semantics. (3) Move row count (~3.0M) and date range (2021-02-10 – 2024-06-07) into Section 1. (4) Add Section 5.2 ETL pipeline ASCII diagram inline in the wiki. (5) Add a Phase Gate Checklist section with explicit P1-P3 checkmarks. (6) Update tier legend and footer to reflect corrected Tier 1 count (≥2 T1).",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2/P3 not formally marked in a Phase Gate Checklist section"]
  }
}
</JUDGE_VERDICT>
