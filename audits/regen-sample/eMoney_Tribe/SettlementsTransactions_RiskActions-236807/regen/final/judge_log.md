## Adversarial Review: eMoney_Tribe.SettlementsTransactions_RiskActions-236807

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: `@Id` (Tier 3 — passthrough, no upstream wiki ✓), `MarkTransactionAsSuspicious` (Tier 3 — passthrough, no upstream wiki ✓), `etr_y` (Tier 2 — Generic Pipeline computed ✓), `Created` (Tier 3 — passthrough, no upstream wiki ✓), `partition_date` (Tier 2 — Generic Pipeline derived ✓). Zero mismatches. Tier assignments are defensible throughout: all source-system columns correctly marked Tier 3 given no upstream wiki, all framework columns correctly Tier 2.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No upstream wiki exists for `FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807`. The bundle confirms this explicitly. Zero Tier 1 columns claimed, zero Tier 1 columns possible. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (15) matches DDL column count (15) exactly. Every element row has 5 cells with tier tags. Property table includes Production Source, Refresh, Distribution, and UC Target. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (2.87M) and date range (2023-12-20 to 2026-04-25). Flag columns list their value domains inline ('0'/'1'/''). `.review-needed.md` does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (risk-action flags for card settlements), row grain (one record per transaction's risk responses), source system (FiatDwhDB.Tribe on prod-banking), ETL pattern (Generic Pipeline #539, Append, daily), downstream consumer (SP_eMoney_Reconciliation_ETLs), row count, and date range. A new analyst would know exactly when and why to query this table.

**Dimension 5 — Data Evidence: 8/10**
Rich data evidence: row count (2.87M), date range, specific trigger counts (1,179 suspicious, 230 card-risk), empty-string rate analysis (1.8% vs 34% for late-added columns), and the observation that 3 flags have zero '1' values. Footer says "Phases: 13/14". Evidence appears genuine and internally consistent.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviation: Section 8 titled "Atlassian Knowledge Sources" rather than a more standard heading, but structurally sound.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no wiki was resolvable for any source column.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Column: @Id, idx_236807_Id** — The wiki correctly identifies the duplicate NCI indexes on `@Id` but could more explicitly flag this as a DBA action item in Section 3 rather than just a gotcha note.

2. **Severity: low | Section 7, Query 7.3** — The JOIN syntax uses `ra.[@Id] = st.[@Id]` with brackets inside the alias-dot notation. While Synapse may parse this, the bracket placement is inconsistent with queries 7.1 and 7.2 which don't use brackets. Minor style inconsistency.

3. **Severity: low | Section 2.1** — The specific count "1,179 rows" for `MarkTransactionAsSuspicious` will become stale as the Append pipeline adds data daily. The description could note these are point-in-time observations. This is a minor concern for a living wiki.

4. **Severity: low | Section 6.1** — The relationship table says "1:1 on @Id" but the join is actually on the FK column `@SettlementsTransactions_SettlementTransaction@Id-637239`, not `@Id` directly. The wiki notes these contain identical values, but the semantic distinction matters — the FK column name IS the relationship declaration.

5. **Severity: info | Footer** — Writer self-assessed quality at 7.0/10, which is conservative. The wiki is well-constructed for a Tier 3 table with no upstream wiki available.

### Regeneration Feedback

No regeneration needed. Minor polish items if desired:
1. Clarify in Section 6.1 that the JOIN key is `@SettlementsTransactions_SettlementTransaction@Id-637239` (the FK column), noting that it happens to contain the same GUID as `@Id`.
2. Normalize bracket usage in Section 7 SQL samples for consistency.

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90
         = 8.95
```

**Verdict: PASS**

This is a strong wiki for a table with no upstream documentation. The writer correctly identified all columns as Tier 3 (no upstream wiki) or Tier 2 (framework-generated), provided rich data evidence including distribution analysis, and built a clear business narrative around the risk-action flagging domain. The review-needed sidecar appropriately calls out the right questions for domain experts.

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "SettlementsTransactions_RiskActions-236807",
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
      "column_or_section": "@Id / idx_236807_Id",
      "problem": "Duplicate NCI indexes on @Id noted as gotcha but not explicitly flagged as a DBA action item in Section 3."
    },
    {
      "severity": "low",
      "column_or_section": "Section 7, Query 7.3",
      "problem": "Bracket placement in JOIN syntax (ra.[@Id] = st.[@Id]) is inconsistent with bracket-free usage in queries 7.1 and 7.2."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1 / MarkTransactionAsSuspicious",
      "problem": "Specific count '1,179 rows' will become stale as Append pipeline adds data daily. Could note these are point-in-time observations."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.1",
      "problem": "Relationship described as '1:1 on @Id' but the actual FK column is @SettlementsTransactions_SettlementTransaction@Id-637239. They hold identical values but the semantic distinction matters."
    },
    {
      "severity": "info",
      "column_or_section": "Footer",
      "problem": "Writer self-assessed quality at 7.0/10 which is conservative for the quality of work produced."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 2.87M in Section 1",
      "MarkTransactionAsSuspicious trigger count 1,179 in Section 2.1",
      "ChangeCardStatusToRisk trigger count 230 in Section 2.1",
      "Empty-string rates 1.8% and 34% in Sections 2.1 and 3.4"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
