## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Date, Metric_a_Value, Metric_b_Value, IsPriceFound, Diff_Percentage). All are ETL-computed by SP_EY_Audit_Auditor_Unrealized_Calculations — hardcoded literals, ABS(SUM(...)) aggregations, arithmetic derivations, or GETDATE(). All correctly tagged Tier 2. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
This table has zero Tier 1 columns. Every column is ETL-computed: hardcoded labels, aggregated sums, arithmetic differences, NULL placeholders, or timestamps. No upstream wiki descriptions should be inherited. The writer correctly identified this and the review-needed sidecar confirms. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count matches DDL exactly (10/10). Every element row has 5 cells with tier tags. Property table has all required fields. Section 5.2 has an ASCII pipeline diagram with real SP and table names. Footer has tier breakdown. Section 1 has row count (1,347) and date range (2023-07-01 to 2025-04-14). Metric_a (3 values), Metric_b (3 values), and Stored_Proc (1 value) all list their distinct values inline. Review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (EY audit reconciliation), row grain (3 metric pairs per date = commission, full commission, PnL), the ETL SP, refresh pattern (daily DELETE+INSERT per Date), row count, date range, and companion table. Key observations from live data add value. An analyst reading this would immediately know when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (1,347) and date range in Section 1. Specific enum values listed for Metric_a, Metric_b, Stored_Proc. IsPriceFound always-NULL noted. Diff_Percentage typical range stated (<1% to ~33%). No explicit Phase Gate Checklist with P2/P3 checkboxes, but the data claims are specific enough to be credible. Footer says "Phases: 11/14".

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1-8, tier legend in Section 4, real SQL samples in Section 7 (3 queries), footer with quality score, phases completed, and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section.

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. All 10 columns are Tier 2 (ETL-computed). This is correct — the table is entirely derived from SP computations, hardcoded literals, and aggregations.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Section 1** — The "Key observations from live data" bullet about Diff_Percentage ("ranges from <1% to ~33%") lacks specificity on how many dates exceed 5% vs the stated "most days under 5%". Minor — not a blocking issue.

2. **Severity: low | Section 4, IsPriceFound** — Description says "Placeholder column" but also says "(Tier 2 -- SP_EY_Audit_Auditor_Unrealized_Calculations)". While technically the NULL is hardcoded in the SP INSERT, calling a hardcoded-NULL placeholder "Tier 2" is debatable — it could equally be Tier 3 (inferred from data pattern). The SP code confirms `NULL AS IsPriceFound`, so Tier 2 is defensible.

3. **Severity: low | Footer** — No explicit Phase Gate Checklist section. The footer claims "Phases: 11/14" but the reader cannot verify which phases were completed or skipped.

4. **Severity: info | Section 2.2** — The PnL calculation description is high-level ("branches on PnLVersion, IsBuy, SellCurrencyID, BuyCurrencyID"). Given the SP code's complexity (12 CASE branches), this is an acceptable summary, but an analyst debugging a divergence would need to read the SP directly.

5. **Severity: info | Section 8** — Atlassian sources skipped. Expected for regen harness context.

### Regeneration Feedback

No regeneration needed. If polish were desired:
1. Add an explicit Phase Gate Checklist section listing which phases were completed.
2. Consider adding a note about the `Diff$` and `Diff%` column aliases used in the SP INSERT vs the DDL column names (`Diff`, `Diff_Percentage`) — the SP uses aliases with `$` and `%` characters that map to the DDL names.

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Diff_Percentage range claim ('ranges from <1% to ~33%, most days under 5%') lacks precise distribution data — how many dates exceed 5%?"
    },
    {
      "severity": "low",
      "column_or_section": "IsPriceFound",
      "problem": "Hardcoded NULL placeholder tagged Tier 2. Defensible since SP code confirms it, but Tier 3 (live data pattern) would also be valid."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist section. Footer claims 'Phases: 11/14' but reader cannot verify which phases were completed."
    },
    {
      "severity": "info",
      "column_or_section": "Section 2.2",
      "problem": "PnL calculation description is high-level summary of 12 CASE branches. Acceptable for wiki, but analyst debugging divergence needs SP code directly."
    },
    {
      "severity": "info",
      "column_or_section": "Section 8",
      "problem": "Atlassian sources skipped — expected for regen harness context."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 1,347 rows, 2023-07-01 to 2025-04-14",
      "Section 1: Diff_Percentage <1% to ~33%, most under 5%",
      "Section 1: Stored_Proc always single value",
      "Section 1: IsPriceFound always NULL"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
