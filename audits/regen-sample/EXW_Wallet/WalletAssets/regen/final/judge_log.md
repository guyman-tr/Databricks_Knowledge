## Review: EXW_Wallet.WalletAssets

This is a straightforward Bronze-layer table with **no upstream wiki available** — the bundle explicitly confirms this. The writer correctly tagged all 10 columns as Tier 3 and compensated with strong live-data evidence. Let me walk through each dimension.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Id, CryptoId, IsShown, SynapseUpdateDate, partition_date). All correctly tagged Tier 3. The upstream bundle confirms "NO UPSTREAM WIKI was resolvable," so Tier 3 is the correct ceiling for every column. SynapseUpdateDate is correctly marked as ETL-injected. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available. This is the correct outcome — the writer did not fabricate Tier 1 claims. Per the rubric, this scores 7 (neutral). No missed inheritance possible since the bundle is empty.

**Dimension 3 — Completeness: 10/10**
- [x] All 8 sections present (1–8)
- [x] Element count matches DDL (10 = 10)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (1,780,223) and date range (2019-06-11 to 2026-04-27)
- [x] IsShown (bit, 2 values) lists inline value distribution in Elements
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 checks pass → Score 10.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the platform (eToro Money/eToroX), defines row grain (one crypto asset per wallet), states ETL pattern (Generic Pipeline Append #651), refresh cadence (daily ~06:00 UTC), row count, and date range. An analyst would know exactly what this table is and when to use it.

**Dimension 5 — Data Evidence: 8/10**
Strong evidence throughout: exact row count (1,780,223), date range, CryptoId distribution (top 5 with counts), IsShown distribution (99.996% True), NULL patterns for SynapseUpdateDate and etr_* columns, daily volume estimate (1,000-3,000 rows). No explicit Phase Gate Checklist section with P2/P3 checkboxes, but the data claims are clearly grounded in live queries given the specificity.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend, real SQL in Section 7, footer with quality score and tier breakdown all present. Minor deviation: no formal Phase Gate Checklist section; phases are only noted in the footer line. Otherwise matches the golden shape well.

---

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained no resolvable wikis. This is correct and expected.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

---

### Top 5 Issues

1. **Low — Missing Phase Gate Checklist section**: The footer says "Phases: 11/14" but there is no explicit checklist section showing which phases were completed and which were skipped. This makes it impossible to verify P2/P3 completion independently.

2. **Low — CryptoId values not decoded**: The writer correctly notes no Synapse-side lookup exists, but the review-needed sidecar could have been more prescriptive about where to find the WalletDB dictionary (e.g., specific server/database name if known).

3. **Low — Section 8 placeholder**: "Atlassian search skipped" is honest but provides no value. Could note whether Confluence spaces for WalletDB/eToroX exist.

4. **Info — etr_* column Tier 3 sourcing**: The lineage file says "ETL partition column derived from Occurred year" for etr_y/etr_ym/etr_ymd, which is arguably a Tier 2 derivation (computed from Occurred). However, since these columns exist in the production source table and are passed through as-is by the Generic Pipeline, Tier 3 passthrough is defensible.

5. **Info — No downstream consumers documented beyond views**: Section 6.2 only lists two views. If other tables or reports consume WalletAssets, they're not captured — but this is a limitation of the available codebase, not a writer error.

---

### Regeneration Feedback

No regeneration needed — this wiki passes. Minor improvements for a future polish pass:

1. Add a formal Phase Gate Checklist section listing which phases were completed
2. If WalletDB server/instance name is known, add it to Section 6.1 for CryptoId FK resolution
3. Consider noting etr_* columns as Tier 2 (derived from Occurred) rather than Tier 3 passthrough, with a note that the derivation happens on the production side

---

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.80
         = 8.85
```

**Verdict: PASS (8.85)**

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "WalletAssets",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No formal Phase Gate Checklist section. Footer says 'Phases: 11/14' but does not enumerate which phases were completed or skipped, making independent P2/P3 verification impossible."
    },
    {
      "severity": "low",
      "column_or_section": "CryptoId",
      "problem": "CryptoId FK target is described as 'production crypto dictionary in WalletDB' but no specific server/database/table name is given for the lookup. The review-needed sidecar flags this but could be more prescriptive."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Atlassian Knowledge Sources section says 'search skipped' — provides no value. Could note whether relevant Confluence spaces for WalletDB/eToroX are known to exist."
    },
    {
      "severity": "info",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "These columns are derived from Occurred (year/month/day extraction) which is arguably a Tier 2 transformation. Marked Tier 3 passthrough because the derivation happens production-side and columns pass through as-is. Defensible but debatable."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.2",
      "problem": "Only two downstream consumers listed (EXW_CustomerWalletsView, EXW_TransactionsView). If other objects consume WalletAssets, they are not captured — likely a codebase limitation, not a writer error."
    }
  ],
  "regeneration_feedback": "No regeneration needed. For a future polish pass: (1) Add a formal Phase Gate Checklist section enumerating completed/skipped phases. (2) If WalletDB server/instance name is known, add it to Section 6.1 for CryptoId FK resolution. (3) Consider re-tagging etr_y/etr_ym/etr_ymd as Tier 2 (derived from Occurred on production side) with a note that the derivation is pre-Synapse.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
