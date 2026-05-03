## Review: eMoney_Tribe.CardsSnapshots-890718

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 9 columns are tagged Tier 3. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable for any source." Tier 3 is the correct assignment for every column. Sampled 5 columns (`@Created`, `@Id`, `etr_y`, `SynapseUpdateDate`, `partition_date`) — all correct.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available. The bundle confirms this. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 numbered sections present. Element count (9) matches DDL column count (9). Every element row has 5 cells. Every description ends with `(Tier N — source)`. Property table includes Production Source, Refresh, Distribution, UC Target. Section 5.2 has ASCII pipeline diagram with real object names. Footer has tier breakdown. Section 1 has row count (86.4M) and date range (2021-09-05 to 2026-04-26). Review-needed sidecar does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToro Money card snapshots), row grain (one XML sub-file per row), the JOIN hub role, the consuming SP (`SP_eMoney_Reconciliation_ETLs`), refresh pattern (incremental on `MAX(Created)`), row count, and date range. A new analyst would immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (86.4M) and date range present. ETR column emptiness quantified (~99.5%). `@Created` vs `Created` relationship characterized (sub-second difference). Footer says "Phases: 11/14" — 3 phases skipped but not enumerated. Data claims appear grounded in actual sampling rather than fabricated.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phase count all present. Minor deviation: no explicit Phase Gate Checklist section listing which phases were completed/skipped.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle confirmed no upstream wikis were resolvable. T1 fidelity table is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — all columns are Tier 3)* | | | | |

### Top 5 Issues

1. **Low severity — Lineage Source Objects section is misleading** (`Section 5 / lineage file`): The lineage file lists `CardsSnapshots_CardSnapshot-140457` etc. as "Source Objects" but these are peer tables co-joined in the downstream SP, not upstream sources that feed data INTO this table. The column lineage correctly shows "Data Lake XML" as the source, creating an internal contradiction.

2. **Low severity — No Phase Gate Checklist section**: Footer references "Phases: 11/14" but no section enumerates which phases were completed vs. skipped. This makes it impossible to verify whether data claims are grounded.

3. **Low severity — `@FileName` example pattern speculative**: Element #3 includes an example filename pattern (`cards-snapshots-11-15967860899208-10079563-YYYYMMDD-SubFile-NNNNN.xml`). If this came from data sampling it's fine, but if fabricated it's misleading.

4. **Low severity — `Created` description is vague on derivation**: Element #8 says "Synapse-side copy of the ingestion timestamp" but the mechanism (is it a computed column? a pipeline artifact?) is unclear. This is acceptable for Tier 3 but could be sharper.

5. **Low severity — Missing Section 8 depth**: Section 8 (Atlassian Knowledge Sources) references only one Freshservice ticket. This is adequate given the limited external documentation available.

### Regeneration Feedback

This wiki is well-constructed for a table with no upstream documentation. If regenerating:

1. Fix the lineage file's Source Objects section to distinguish between "peer tables joined via SP" and "actual upstream data sources" (Data Lake XML pipeline).
2. Add an explicit Phase Gate Checklist section listing which phases were completed and which were skipped, so readers can assess data claim reliability.
3. Verify the `@FileName` example pattern against actual data rather than inferring it.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "CardsSnapshots-890718",
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
      "column_or_section": "Lineage file — Source Objects",
      "problem": "Lineage file lists CardsSnapshots_CardSnapshot-140457, CardsSnapshots_Accounts-350640, etc. as 'Source Objects' but these are peer tables co-joined in the downstream SP, not upstream sources that feed data INTO this table. Column lineage correctly shows 'Data Lake XML' as the source, creating an internal contradiction."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer references 'Phases: 11/14' but no section enumerates which phases were completed vs. skipped, making it impossible to verify whether data claims are grounded in actual sampling."
    },
    {
      "severity": "low",
      "column_or_section": "@FileName (Element #3)",
      "problem": "Example filename pattern (cards-snapshots-11-15967860899208-10079563-YYYYMMDD-SubFile-NNNNN.xml) may be speculative if not directly sampled from data."
    },
    {
      "severity": "low",
      "column_or_section": "Created (Element #8)",
      "problem": "Description says 'Synapse-side copy of the ingestion timestamp' but does not explain the derivation mechanism (computed column, pipeline artifact, etc.)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Only one Freshservice ticket referenced. Adequate given limited external docs but shallow compared to typical Section 8 content."
    }
  ],
  "regeneration_feedback": "Wiki passes. Minor improvements if regenerating: (1) Fix lineage Source Objects to distinguish peer tables (joined via SP) from actual upstream data sources (Data Lake XML). (2) Add explicit Phase Gate Checklist section enumerating completed/skipped phases. (3) Verify @FileName example pattern against actual data sample.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phases 12-14 appear skipped per footer (11/14) but not enumerated"]
  }
}
</JUDGE_VERDICT>
