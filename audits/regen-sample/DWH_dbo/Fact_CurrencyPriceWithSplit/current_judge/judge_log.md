## Judge Review: DWH_dbo.Fact_CurrencyPriceWithSplit

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (ProviderID, InstrumentID, AskSpreaded, UpdateDate, ConvertRateIsBuy_1). All are correctly tagged Tier 2 from SP code. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable" — every column flows from unresolved DWH_staging sources or is ETL-computed. Tier 2 is the correct ceiling. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10**
No Tier 1 columns exist, which is correct — no upstream wiki was available in the bundle. This is the neutral-score case per the rubric. The writer did not fabricate Tier 1 tags or fake upstream quotes.

**Dimension 3 — Completeness: 8/10**
9/10 checklist items pass. The single miss: ProviderID has 3 distinct values but the wiki does not enumerate them inline (`key=value` pairs). The `isvalid` column does describe its two values (0/1), but ProviderID is a dictionary column (≤15 values) left unenumerated. All 8 sections present, 14 elements match 14 DDL columns, tier tags on every element, ETL pipeline diagram uses real object names, footer has tier breakdown.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (daily price reference), row grain (one+ rows per instrument per calendar day), ETL SP name, refresh pattern (per-date delete+insert), row count (~17.2M), date range (2009-06-15 to present), and the split-adjustment logic. An analyst new to this table would know exactly when and how to query it.

**Dimension 5 — Data Evidence: 7/10**
Rich data evidence: row count (17.2M), date range, distinct instrument count (15,416), isvalid distribution (~54%/46%), NULL ConvertRate stats (~1.3M / 7.5%), 3 distinct ProviderIDs. No explicit Phase Gate Checklist section with P2/P3 checkboxes, but the footer shows "Phases: 9/14" and the data claims are specific and internally consistent. The ProviderID values are counted but not listed — a gap.

**Dimension 6 — Shape Fidelity: 9/10**
All structural elements present: numbered sections 1-8, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score (7.7/10), phase count (9/14), and tier breakdown. Minor: no explicit Phase Gate Checklist table (P1-P14 with checkboxes).

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle contained no resolvable wikis — all sources are DWH_staging Data Lake intermediates without documented wiki pages. Tier 2 is the correct and only appropriate tier for all passthrough columns.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **[Medium] ProviderID — missing dictionary enumeration.** The wiki states "3 distinct values in production" but does not list them. Dictionary columns with ≤15 values should enumerate key=value pairs inline.

2. **[Low] No explicit Phase Gate Checklist.** The footer says "Phases: 9/14" but there is no P1-P14 checklist table showing which phases were completed vs. skipped. This makes it harder to verify whether data-evidence phases (P2/P3) were actually executed.

3. **[Low] ConvertRateIsBuy_1 description minor inaccuracy.** The wiki says "Multiply by instrument price to convert to USD" but the actual SP logic is more nuanced — for BuyCurrencyID=1, it's `1/Bid`, not a multiplication of the instrument price. The description oversimplifies the usage guidance.

4. **[Low] Section 6.2 Referenced By is speculative.** `Fact_CustomerUnrealized_PnL` is marked "(probable)" — this should either be confirmed or omitted. Speculative lineage without verification is noise.

5. **[Low] isvalid percentage discrepancy.** Element #6 says "~54% of rows are valid" while Section 3.4 Gotchas says "isvalid = 0 rows (~46% of all rows)." These are consistent (54% valid + 46% invalid = 100%), but the same fact is stated from opposite directions, which could confuse a reader.

### Regeneration Feedback

1. Enumerate the 3 distinct ProviderID values with their meanings (query live data or ask a domain expert).
2. Add an explicit Phase Gate Checklist table showing P1-P14 status.
3. Refine ConvertRateIsBuy_1/0 usage guidance — instead of "multiply by instrument price," describe the actual output: "pre-computed rate that, when applied to the position value, yields the USD equivalent."
4. Either confirm or remove the speculative `Fact_CustomerUnrealized_PnL` entry in Section 6.2.
5. These are minor issues — the wiki is fundamentally sound and usable as-is.

### Weighted Score Calculation

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.90
         = 8.45
```

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Fact_CurrencyPriceWithSplit",
  "weighted_score": 8.45,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "ProviderID",
      "problem": "Dictionary column with 3 distinct values but key=value pairs not enumerated inline. Wiki says '3 distinct values in production' without listing them."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist table (P1-P14 with checkboxes). Footer says 'Phases: 9/14' but does not itemize which phases were completed vs skipped."
    },
    {
      "severity": "low",
      "column_or_section": "ConvertRateIsBuy_1",
      "problem": "Description says 'Multiply by instrument price to convert to USD' but the SP logic computes rates differently per case (1.00, 1/Bid, or cross-rate). The usage guidance oversimplifies."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Fact_CustomerUnrealized_PnL entry is speculative — marked '(probable)'. Unverified downstream lineage should be confirmed or removed."
    },
    {
      "severity": "low",
      "column_or_section": "isvalid",
      "problem": "Same statistic expressed from opposite directions in Element #6 (~54% valid) and Section 3.4 (~46% invalid). Consistent but potentially confusing — pick one canonical phrasing."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Enumerate the 3 distinct ProviderID values with their meanings. (2) Add an explicit Phase Gate Checklist table. (3) Refine ConvertRateIsBuy usage guidance to reflect the actual CASE logic rather than oversimplified 'multiply by price'. (4) Confirm or remove speculative Fact_CustomerUnrealized_PnL reference in Section 6.2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "ProviderID: '3 distinct values'",
      "InstrumentID: '15,416 distinct instruments'",
      "isvalid: '~54% of rows are valid'",
      "ConvertRateIsBuy_1: 'NULL for ~1.3M rows (7.5%)'",
      "Section 1: '~17.2M rows, 2009-06-15 to present'"
    ],
    "skipped_phases": ["Phase Gate Checklist not present as explicit section — footer indicates 9/14 phases completed"]
  }
}
</JUDGE_VERDICT>
