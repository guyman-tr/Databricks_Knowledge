I'll review the wiki, DDL, lineage, upstream bundle, and sidecar. Let me verify the DDL column count and check if any upstream wikis actually exist that the writer claims to have read.
The upstream wikis DO exist on disk, but the bundle says "NO UPSTREAM WIKI was resolvable." This is a key finding — the writer's search log claims it found and read these, yet the bundle (authoritative source) didn't include them. Let me check what descriptions these upstream wikis have for the relevant columns to see if Tier 1 inheritance was possible.
Now I have everything needed for the review. The upstream wikis exist on disk (Dim_Affiliate.md, Dim_Customer.md) with documented columns, but the bundle explicitly says "NO UPSTREAM WIKI was resolvable." The writer found them via Read but correctly assigned Tier 3b since no writer SP confirms the column mappings.

---

## Review Summary — BI_DB_dbo.BI_DB_AffData

### Dimension 1 — Tier Accuracy: **9/10**

Sampled 5 columns: RealCID, ContractName, Channel, Aff_eLanguage, UpdateDate. All tagged Tier 3b (DDL structure). With no writer SP in the SSDT repo, column-level lineage cannot be traced from code — naming correlations with Dim_Affiliate are plausible but unconfirmed. Tier 3b is the correct assignment. The writer resisted the temptation to claim Tier 1 based on naming alone. Minor deduction: some descriptions present inferred correlations with moderate confidence ("correlates with Dim_Affiliate.DateCreated") that could mislead readers into treating them as confirmed.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist. The upstream bundle explicitly states no upstream wiki was resolvable. The writer's upstream search log claims to have found and read Dim_Affiliate.md and Dim_Customer.md on disk, which is a process inconsistency with the bundle, but the tier assignments are unaffected — the writer correctly refrained from claiming Tier 1 inheritance. Score is neutral per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns — all 11 columns are Tier 3b |

### Dimension 3 — Completeness: **9/10**

All 8 sections present. DDL has 11 columns; Elements table has 11 rows — match. Every element row has 5 cells with tier tags. Property table has Production Source, Refresh, Distribution (UC fields are pending). Section 5.2 has ASCII pipeline diagram. Footer has tier breakdown (correctly counts 11 T3b). Section 1 has row count (0); no date range is possible for an empty table. ContractType domain values are discussed in the element description. review-needed.md does not contain `## 4. Elements`. Deduction: footer says "Phases: 7/14" but lists 6 skipped phases (14-6=8, not 7) — arithmetic error. Also, tier legend in Section 4 only shows Tier 3b; a complete legend aids analyst comprehension.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable. It clearly names the domain (affiliate-customer mapping), the row grain (one customer-affiliate pair), the current state (0 rows, dormant), the likely replacement pattern (Dim_Customer JOIN Dim_Affiliate), and the PII concern (Aff_Email masking). An analyst would immediately know not to query this table and where to go instead. Missing: explicit ETL pattern (N/A is appropriate for a dormant table, but should be stated more prominently).

### Dimension 5 — Data Evidence: **5/10**

The wiki claims 0 rows but provides no evidence of a live query (no `SELECT COUNT(*)` result, no timestamp for the check). P2 and P3 are not listed among skipped phases, implying they were completed, but no query output or distribution analysis is cited. For a dormant table this is partially justifiable — there's nothing to analyze — but the writer should have included explicit evidence of the dormancy check (e.g., a query timestamp). The self-score of 3.5/10 and "Phases: 7/14" suggest the writer was at least honest about limitations.

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1–8 present. Tier legend in Section 4 (truncated to one tier but structurally correct). Real SQL samples in Section 7 with practical alternatives. Footer format includes quality score and phases-completed. Minor: Section 7 queries are primarily "use something else" redirects rather than queries on this table itself, though that's appropriate for a dormant table.

### Weighted Score

```
weighted = 0.25×9 + 0.20×7 + 0.20×9 + 0.15×9 + 0.10×5 + 0.10×9
         = 2.25 + 1.40 + 1.80 + 1.35 + 0.50 + 0.90
         = 8.20
```

### Top 5 Issues

1. **Medium — Footer phase count arithmetic**: Footer says "Phases: 7/14" but lists 6 skipped phases (P4,P5,P7,P9,P9B,P10), which yields 14-6=8, not 7.
2. **Low — No live data evidence**: 0-row claim is not backed by a cited query result or timestamp. Reader cannot verify when dormancy was last confirmed.
3. **Low — Upstream search log inconsistency**: The wiki's upstream search log (Section 5.2) claims Dim_Affiliate.md and Dim_Customer.md were found and read, but the authoritative bundle states "NO UPSTREAM WIKI was resolvable." Process gap — not a content error since tiers are still correct.
4. **Low — Tier legend is minimal**: Section 4 legend only shows Tier 3b. Including the full tier scale (even if unused) helps analysts unfamiliar with the tier system.
5. **Low — ContractType domain ambiguity**: Element #7 discusses Dim_Affiliate's tinyint codes but doesn't resolve what varchar(20) values this column was designed to store. The review-needed sidecar correctly flags this.

### Regeneration Feedback

1. Add explicit evidence of the dormancy check — include the query and timestamp that confirmed 0 rows.
2. Fix footer phase count: 14 - 6 skipped = 8 completed, not 7.
3. Remove or reconcile the upstream search log: either acknowledge the bundle had no upstream wikis, or explain that wikis were found outside the bundle.
4. Expand the tier legend to show the full tier scale with a note that only Tier 3b applies to this table.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AffData",
  "weighted_score": 8.20,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 7,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer says 'Phases: 7/14' but lists 6 skipped phases (P4,P5,P7,P9,P9B,P10), yielding 14-6=8 completed, not 7. Arithmetic error."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Data Evidence",
      "problem": "0-row claim is not backed by a cited live query result or timestamp. Reader cannot verify when dormancy was last confirmed."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.2 (Upstream Search Log)",
      "problem": "Search log claims Dim_Affiliate.md and Dim_Customer.md were found and read, but the authoritative upstream bundle states 'NO UPSTREAM WIKI was resolvable'. Process inconsistency — content is unaffected since Tier 3b was correctly assigned."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (Tier Legend)",
      "problem": "Tier legend only shows Tier 3b. Full tier scale (T1-T5) would help analysts unfamiliar with the system understand the confidence spectrum."
    },
    {
      "severity": "low",
      "column_or_section": "ContractType",
      "problem": "Element #7 discusses Dim_Affiliate's tinyint codes (0=N/A, 2=CPA, etc.) but does not resolve whether this varchar(20) column stores text labels or stringified numeric codes. Correctly flagged in review-needed sidecar."
    }
  ],
  "regeneration_feedback": "Minor fixes only (PASS): (1) Add explicit dormancy-check evidence — include the SELECT COUNT(*) result and timestamp. (2) Fix footer phase arithmetic: 14-6=8, not 7. (3) Reconcile upstream search log with the bundle's 'no upstream wiki resolvable' statement. (4) Expand Section 4 tier legend to show the full T1–T5 scale.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P4", "P5", "P7", "P9", "P9B", "P10"]
  }
}
</JUDGE_VERDICT>
