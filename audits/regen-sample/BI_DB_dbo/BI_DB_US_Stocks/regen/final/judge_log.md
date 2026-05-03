## Judge Review — BI_DB_dbo.BI_DB_US_Stocks

This is a 3-column dormant reference table with no writer SP, no upstream wikis, and all Tier 3 columns. The writer had very little to work with, and the result is surprisingly thorough.

### Per-Dimension Scores

**Tier Accuracy: 10/10** — All 3 columns correctly tagged Tier 3. The upstream bundle confirms "NO UPSTREAM WIKI was resolvable." No writer SP exists. Zero mismatches.

**Upstream Fidelity: 7/10 (neutral)** — Zero Tier 1 columns exist because no upstream wiki was available in the bundle. This is the correct outcome, not a writer failure.

**Completeness: 10/10** — All 8 sections present. Element count (3) matches DDL (3). Every element row has 5 cells with tier annotations. Property table has all required fields. Section 5.2 has an ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count and date range. No dictionary columns apply. Review-needed sidecar does not contain `## 4. Elements`.

**Business Meaning: 9/10** — Section 1 is excellent: names row grain (one row per US-traded instrument), row count (1,025), date range (2019-03-24 to 2019-11-24), downstream consumer (SP_Daily_Dividends → Is_US_Stock flag), platform context (eToro), and dormancy status. An analyst would immediately understand this table's purpose and limitations.

**Data Evidence: 8/10** — Strong live-data evidence throughout: exact row count (1,025), date range, distinct counts (1,021 InstrumentIDs, 1,018 Names), specific duplicate IDs (5945-5948), specific duplicate names (SPHD/USD, SDY/USD, DVY/USD, VIG/USD, SPXU/USD), NULL observations. Footer says "Phases: 12/14" but no explicit P2/P3 checkboxes shown — minor gap.

**Shape Fidelity: 9/10** — Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: footer format is slightly non-standard (no explicit phase gate checklist block), but all key information is present.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle contained no resolvable upstream wikis. This is correct.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top Issues

1. **(low) Footer** — No explicit Phase Gate Checklist block with `[x]` checkboxes for P1-P5. Footer uses a summary format (`Phases: 12/14`) instead.
2. **(low) Section 5.2** — Pipeline diagram is minimal, but this is justified given the table has no writer SP or known ETL.
3. **(info) Dormancy** — The writer appropriately flagged this table as dormant since 2019 and called out the risk of stale Is_US_Stock classification. Good defensive documentation.

### Regeneration Feedback

No regeneration needed. If the wiki were to be improved:
1. Add an explicit Phase Gate Checklist section with P1-P5 checkboxes.
2. Consider adding a note about whether `Dim_Instrument.InstrumentID` covers all 1,021 distinct IDs in this table (orphan check).

---

**Weighted Total:**
```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9
= 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90
= 8.95
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_US_Stocks",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist block with [x] checkboxes for P1-P5. Footer uses summary format (Phases: 12/14) instead of individual phase status."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.2",
      "problem": "Pipeline diagram is minimal — justified given no writer SP exists, but could note the unknown original load mechanism more explicitly."
    },
    {
      "severity": "info",
      "column_or_section": "Section 1",
      "problem": "Writer correctly identified dormancy and downstream risk (stale Is_US_Stock flag). No action needed — this is good defensive documentation."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 1,025 in Section 1",
      "Date range 2019-03-24 to 2019-11-24 in Section 1",
      "1,021 distinct InstrumentIDs in InstrumentID description",
      "1,018 distinct Names in Name description",
      "Duplicate IDs 5945-5948 in Section 3.4 and InstrumentID description"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
