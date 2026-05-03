## Review: eMoney_Tribe.Authorizes_SecurityChecks-30662

### Dimension 1 — Tier Accuracy: 10/10

Sampled 5 columns: `@Id`, `ThreeDomainSecure`, `etr_ymd`, `Created`, `partition_date`. All are tagged Tier 3 with source `FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662` or `Generic Pipeline`. The upstream bundle explicitly confirms **no upstream wiki was resolvable** for any source. Tier 3 is the correct assignment for every column. 0 mismatches out of 5.

### Dimension 2 — Upstream Fidelity: 7/10

No Tier 1 columns exist — all 19 are Tier 3. The bundle confirms no upstream wiki was available. Score is neutral per rubric ("No upstream wiki existed in the bundle → 7").

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: 10/10

| Check | Result |
|-------|--------|
| All 8 sections present | YES (1–8) |
| Element count = DDL column count | YES (19/19) |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (~3.76M, 2023-12-20 to 2026-04-26) |
| Dictionary columns ≤15 values list inline pairs | YES — boolean columns all list `0`/`1` meanings |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 checks pass → Score 10.

### Dimension 4 — Business Meaning: 9/10

Section 1 is excellent for a raw Tribe table. It names the specific domain (card authorization security checks for eToro Money), states the row grain (security verification methods per authorization attempt), identifies the parent table (`Authorizes_Authorize-312243`), the ETL SP (`SP_eMoney_Reconciliation_ETLs`), the pipeline (#544, daily append), row count, date range, and even notes the `etr_*` population gap. An analyst reading this would immediately understand what this table contains and when to use it.

### Dimension 5 — Data Evidence: 7/10

Evidence of live data usage is present: specific row count (3.76M), date range (2023-12-20 to 2026-04-26), the 99.9% CardExpirationDatePresent observation, the `etr_*` population gap between older and newer records, and AccountNames showing `0`/empty strings. However, the footer says "Phases: 13/14" without an explicit Phase Gate Checklist — it's not possible to verify P2/P3 completion. The data claims appear grounded but the audit trail is implicit rather than explicit.

### Dimension 6 — Shape Fidelity: 9/10

Numbered sections, tier legend in Section 4, real SQL in Section 7 (three practical queries), footer with quality score and phase count. Minor deviation: no explicit Phase Gate Checklist section visible in the output. Otherwise matches the golden shape well.

### Top 5 Issues

1. **No Phase Gate Checklist section** — Footer claims "Phases: 13/14" but no explicit checklist is present in the wiki body. Makes it impossible to verify which phases were completed and which was skipped.
2. **AccountNames column remains opaque** — Described honestly as "purpose unclear," which is correct, but the review-needed sidecar correctly flags this for SME follow-up. Not a wiki defect per se, but a knowledge gap.
3. **Redundant indexes noted but not actionable** — The wiki correctly identifies `ClusteredIndex_Authorizes_30662` and `idx_30662_Id` as duplicate NCIs on `@Id`. Good observation, properly surfaced in Section 3.4.
4. **Join condition in Query 7.3** — Uses `auth.[@Id] = aas.[@Id]` which is correct for the parent-child join, but the column naming could confuse analysts since `@Id` means different things in each table (parent PK vs child PK that happens to match). The wiki does explain this in Section 2.2, mitigating the risk.
5. **No explicit mention of index name mismatch** — `ClusteredIndex_Authorizes_30662` is a NCI, not a clustered index (the table is a HEAP). The misleading index name could confuse DBAs. Wiki mentions "HEAP with 4 NCIs" in the property table, which is correct, but doesn't call out the misleading name.

### Regeneration Feedback

This wiki passes and does not require regeneration. If further polish were desired:

1. Add an explicit Phase Gate Checklist section showing which phases were completed.
2. Note that `ClusteredIndex_Authorizes_30662` is misleadingly named — it is an NCI on a HEAP, not a clustered index.
3. Clarify in Query 7.3 that `@Id` in the parent table and `@Id` in this child table are distinct identifiers that happen to share the same value for 1:1 rows.

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "Authorizes_SecurityChecks-30662",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 'Phases: 13/14' but no explicit Phase Gate Checklist section is present in the wiki body. Cannot verify which phase was skipped or confirm P2/P3 completion."
    },
    {
      "severity": "low",
      "column_or_section": "AccountNames",
      "problem": "Column purpose remains unclear (observed values: '0' or empty string). Correctly flagged in review-needed sidecar for SME follow-up."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 / Indexes",
      "problem": "ClusteredIndex_Authorizes_30662 is misleadingly named — it is an NCI on a HEAP, not a clustered index. Wiki notes the redundancy but not the misleading name."
    },
    {
      "severity": "low",
      "column_or_section": "Section 7.3",
      "problem": "Join condition auth.[@Id] = aas.[@Id] could confuse analysts since @Id is semantically different in each table (parent PK vs child PK). Section 2.2 mitigates but the query comment could be clearer."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2",
      "problem": "States '@Id equals @Authorizes_Authorize@Id-312243 in many rows indicating 1:1 relationship' — this is an observed pattern but no percentage or count is given to quantify 'many'."
    }
  ],
  "regeneration_feedback": "Wiki passes. Optional improvements: (1) Add explicit Phase Gate Checklist section. (2) Note the misleading name of ClusteredIndex_Authorizes_30662 (NCI, not clustered). (3) Quantify the 1:1 @Id relationship claim in Section 2.2 with a percentage.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 14 (unknown — not documented)"]
  }
}
</JUDGE_VERDICT>
