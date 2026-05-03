## Review Summary — EXW_Wallet.SentTransactionOutputs

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Id, SentTransactionId, Amount, IsEtoroFee, etr_y). All tier assignments are correct. Production-origin columns with no upstream wiki are correctly Tier 3; ETL-added columns are correctly Tier 2. No mismatches, no paraphrasing failures (impossible since no Tier 1 columns exist).

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable for any source." Tier 3 assignment for all production columns is the correct response. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (16) matches DDL column count (16). Every element row has 5 cells with proper tier tags. Property table includes Production Source, Refresh, Distribution, and UC Target. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (2,212,095) and date range (2018-04-23 to 2026-04-27). SourceIdType and IsEtoroFee list inline value distributions. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (blockchain send transaction outputs, UTXO model), row grain (one destination address + amount per output), production source (WalletDB), ETL pattern (Generic Pipeline, Append, daily), row count, date range, and downstream consumers with concrete usage descriptions. An analyst could immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (2,212,095), date range, enum distributions (SourceIdType, IsEtoroFee), NULL-rate observations (BlockchainFees, SourceId ~49%) are all present and specific. Footer shows "Phases: 11/14" — no explicit Phase Gate Checklist section exists in the wiki body, but the data claims are internally consistent and appear grounded. Minor deduction for missing explicit phase gate documentation.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phase count all present. Minor deviation: no explicit Phase Gate Checklist section; phase completion is only in the footer line.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained no resolvable wiki. This is correctly reflected in the wiki (0 T1 in footer).

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **(Low) Missing Phase Gate Checklist section** — The wiki has no explicit Phase Gate Checklist (e.g., `[x] P1 DDL reviewed`, `[x] P2 Live data sampled`). Phase completion is only noted in the footer ("Phases: 11/14"). This makes it harder to audit which specific phases were skipped.

2. **(Low) SynapseUpdateDate description hedges** — Element 15 says "NULL in sampled data suggests this column may not be populated for all rows." The hedging ("suggests", "may not be") is honest but could be more definitive. The review-needed sidecar correctly flags this for human follow-up.

3. **(Low) SourceIdType = 2 undocumented** — The wiki correctly notes that SourceIdType = 2 is "alternate source type (~0.06%)" but acknowledges this is unknown. This is properly flagged in review-needed. Not a wiki defect per se, but a data knowledge gap.

4. **(Low) No Section 8 content** — Section 8 (Atlassian Knowledge Sources) is empty. This is correct if no Confluence/Jira sources exist, but the section adds no value in its current form.

5. **(Low) Footer quality self-score** — The writer self-scored 7.5/10. For a Generic Pipeline table with no upstream wiki and solid data evidence, this is a reasonable self-assessment.

### Regeneration Feedback

No regeneration needed. The wiki is well-constructed for a Generic Pipeline Bronze landing table with no upstream documentation. If improvements were desired:

1. Add an explicit Phase Gate Checklist section listing which phases were completed and which 3 were skipped.
2. Make the SynapseUpdateDate description more definitive — either "always NULL in current data" or confirm with the pipeline team.
3. When/if an upstream WalletDB wiki becomes available, re-run to upgrade Tier 3 columns to Tier 1.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS (8.75)**

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "SentTransactionOutputs",
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
      "column_or_section": "Section (missing)",
      "problem": "No explicit Phase Gate Checklist section. Phase completion is only noted in the footer line ('Phases: 11/14') with no detail on which 3 phases were skipped."
    },
    {
      "severity": "low",
      "column_or_section": "SynapseUpdateDate",
      "problem": "Description hedges with 'suggests this column may not be populated for all rows' instead of stating definitively that the column is NULL in all sampled data."
    },
    {
      "severity": "low",
      "column_or_section": "SourceIdType",
      "problem": "Value 2 is described as 'alternate source type' without concrete meaning. Correctly flagged in review-needed but the element description could note this is unconfirmed."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Empty Atlassian Knowledge Sources section adds no value. Minor structural concern only."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Writer self-scored 7.5/10 quality. Reasonable but no breakdown of what drove the deductions."
    }
  ],
  "regeneration_feedback": "No regeneration required. Minor improvements: (1) Add explicit Phase Gate Checklist section detailing which 3 of 14 phases were skipped. (2) Make SynapseUpdateDate description definitive rather than hedging. (3) Re-run if upstream WalletDB wiki becomes available to upgrade Tier 3 to Tier 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["3 of 14 phases skipped per footer but not individually identified"]
  }
}
</JUDGE_VERDICT>
