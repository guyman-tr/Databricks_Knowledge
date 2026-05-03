## Review: eMoney_Tribe.SettlementsTransactions-333243

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 9/10**
All 9 columns tagged Tier 3. Sampled 5: `@Created`, `@FileName`, `partition_date`, `SynapseUpdateDate`, `Created`. The upstream bundle confirms "NO UPSTREAM WIKI was resolvable" — Tier 3 is the correct assignment for every column. Minor quibble: `partition_date` (date extraction from `@Created`) and `Created` (copy of `@Created`) are ETL-computed transforms that could arguably be Tier 2, but since the Generic Pipeline code is not available as SP source, Tier 3 is defensible. No mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The bundle explicitly states no upstream wiki was resolvable. This is an external API ingestion table — neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 9 elements match 9 DDL columns exactly. Every element row has 5 cells with `(Tier N — source)` tags. Property table includes Production Source, Refresh, Distribution, UC Target. Section 5.2 has ASCII pipeline diagram with real object names. Footer has tier breakdown. Section 1 has row count (2,946,011) and date range (2021-09-05 to 2026-04-25). No dictionary columns applicable. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (Tribe Payments settlement XML metadata), defines row grain (one XML sub-file), names the ETL SP (`SP_eMoney_Reconciliation_ETLs`), describes refresh pattern (incremental via `@Created` watermark), explains parent-child structure with three named child tables, and calls out the legacy NULL columns. A new analyst would immediately know what this table is and when to query it.

**Dimension 5 — Data Evidence: 7/10**
Row count (2,946,011), date range, NULL rates (etr_* 99.8%, Created 26%), and a specific bulk-load timestamp (`2023-12-24 16:13:17.613` for SynapseUpdateDate) all present. These are suspiciously specific in a good way — suggests real data. Footer says "Phases: 11/14" but no explicit P2/P3 phase gate checkboxes are shown, creating ambiguity about whether live queries were actually run.

**Dimension 6 — Shape Fidelity: 9/10**
All structural elements present: numbered sections, tier legend in Section 4, three real SQL samples in Section 7 with correct bracket-quoting for `@`-prefixed and hyphenated names, footer with quality score and tier breakdown. Minor: footer format differs slightly from golden reference (uses prose-style rather than checklist for phases).

### T1 Fidelity Table

No Tier 1 columns exist — all 9 columns are Tier 3 (external API source with no upstream wiki).

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Medium — `partition_date` tier classification**: `partition_date` is described as "Date-only partition key derived from @Created" — this is an ETL transform (date extraction). Could be argued as Tier 2 rather than Tier 3, since the transform logic is known even without SP source code.

2. **Medium — `Created` tier classification**: Similarly, `Created` is described as "Copy of @Created populated only for records loaded since ~January 2024" — a known ETL derivation that could be Tier 2.

3. **Low — Phase Gate ambiguity**: Footer says "Phases: 11/14" but doesn't include an explicit Phase Gate Checklist with P2/P3 checkboxes. While the data specificity strongly suggests live queries, the phase completion evidence is implicit rather than explicit.

4. **Low — Missing explicit NULL-rate for `@Id`**: The wiki describes `@FileName` as "Always populated (0% NULL)" and `SynapseUpdateDate` similarly, but doesn't state the NULL rate for `@Id` despite it being the critical join key.

5. **Low — `ClusteredIndex_ST_333243` naming**: The index is named `ClusteredIndex_ST_333243` but is actually a non-clustered index (per DDL: `CREATE NONCLUSTERED INDEX`). The wiki correctly identifies it as an NCI in the property table, but the misleading index name is not called out as a gotcha for analysts who might see it in query plans.

### Regeneration Feedback

1. Consider re-tagging `partition_date` and `Created` as Tier 2 (ETL-derived from `@Created`) since the transform logic is known, even without the Generic Pipeline source code.
2. Add explicit NULL-rate for `@Id` — if it's always populated, state "0% NULL"; if nullable, state the rate.
3. Add a Phase Gate Checklist with explicit P2/P3 checkboxes to confirm live data validation.
4. Call out the misleading `ClusteredIndex_ST_333243` index name (it's actually non-clustered) in Section 3.4 Gotchas.

---

**Weighted Score Calculation:**
```
0.25×9 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
= 2.25 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90 = 8.60
```

**Verdict: PASS** — This is a well-crafted wiki for an external API ingestion table with no upstream documentation. The writer correctly identified all columns as Tier 3, provided rich business context, and included specific data evidence. The issues are minor and relate to tier edge cases and missing explicit phase gate confirmation.

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "SettlementsTransactions-333243",
  "weighted_score": 8.60,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "partition_date",
      "problem": "Tagged Tier 3 but is a known ETL derivation (date extraction from @Created). Transform logic is documented, making this a candidate for Tier 2 rather than Tier 3."
    },
    {
      "severity": "medium",
      "column_or_section": "Created",
      "problem": "Tagged Tier 3 but is a known copy of @Created populated only for newer records. Transform logic is documented, making this a candidate for Tier 2 rather than Tier 3."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer says 'Phases: 11/14' but no explicit Phase Gate Checklist with P2/P3 checkboxes is included. Data evidence appears genuine but phase completion is not formally verified."
    },
    {
      "severity": "low",
      "column_or_section": "@Id",
      "problem": "No explicit NULL-rate stated for @Id despite it being the critical join key to all child tables. Other metadata columns (@FileName, SynapseUpdateDate) have explicit NULL-rate callouts."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 Gotchas",
      "problem": "Index ClusteredIndex_ST_333243 is misleadingly named — it is actually a NONCLUSTERED INDEX per DDL. This naming discrepancy is not called out as a gotcha for analysts reviewing query plans."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Consider re-tagging partition_date and Created as Tier 2 since their ETL derivation from @Created is documented. (2) Add explicit NULL-rate for @Id. (3) Add a Phase Gate Checklist section with P2/P3 checkboxes. (4) Note the misleading ClusteredIndex_ST_333243 name (actually non-clustered) in Gotchas.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 2,946,011 in Section 1",
      "Date range 2021-09-05 to 2026-04-25 in Section 1",
      "etr_* NULL rate 99.8% (2,939,946 of 2,946,011) in Elements",
      "Created NULL rate 26% (770,930 of 2,946,011) in Elements",
      "SynapseUpdateDate bulk value 2023-12-24 16:13:17.613 in Elements"
    ],
    "skipped_phases": ["Phase gate checklist not explicitly present — 11/14 phases claimed in footer"]
  }
}
</JUDGE_VERDICT>
