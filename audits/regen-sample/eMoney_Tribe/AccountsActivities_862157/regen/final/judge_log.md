## Review: eMoney_Tribe.AccountsActivities_862157

This is a well-executed wiki for a dormant upstream table (Treezor XML exports) with zero available upstream wikis. The writer correctly identified all 9 columns as Tier 3 and grounded descriptions in DDL structure, SP code analysis, and live data sampling. Let me walk through each dimension.

---

### Dimension Scores

**Tier Accuracy: 10/10** — Sampled 5 columns (@Created, @Id, etr_y, SynapseUpdateDate, partition_date). All correctly tagged Tier 3. The upstream bundle confirms "NO UPSTREAM WIKI was resolvable," making Tier 3 the only valid assignment. No mismatches.

**Upstream Fidelity: 7/10 (neutral)** — Zero Tier 1 columns exist because no upstream wiki was available in the bundle. This is the correct neutral score per the rubric. Nothing to verify, nothing to fault.

**Completeness: 9/10 → 8** — Checklist:
- [x] All 8 sections present (1–8)
- [x] Element count matches DDL (9 = 9)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (29.8M) and date range (2021-09-05 to 2026-04-26)
- [x] No dictionary columns applicable (no low-cardinality enums in this table)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 checks → Score: **10**

**Business Meaning: 9/10** — Section 1 is specific and actionable: names the domain (Treezor banking-as-a-service XML envelopes), row grain (one XML file per row), ETL SP (`SP_eMoney_Reconciliation_ETLs`), refresh pattern (incremental via `MAX(Created)` delete-insert), row count (29.8M), and date range. A new analyst would immediately understand this is an envelope/container table not to be queried alone.

**Data Evidence: 7/10** — Strong specific data claims present: 29.8M rows, date range 2021-09-05 to 2026-04-26, etr_* ~99.8% NULL (~73K populated), Created ~41.6% NULL, @Created 0% NULL. Footer says "Phases: 11/14" but no explicit Phase Gate Checklist section showing P2/P3 checkboxes. The specificity of claims suggests live queries were run, but the absence of an explicit checklist is a minor gap.

**Shape Fidelity: 9/10** — Numbered sections, tier legend in Section 4, real SQL in Section 7 (three practical queries), footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section (some templates include this as a dedicated subsection). Otherwise matches the golden shape well.

---

### T1 Fidelity Table

No Tier 1 columns exist — no upstream wiki was available in the bundle. This is correct and expected for a raw external-vendor ingestion table.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Top 5 Issues

1. **Low — Footer/Phases**: Footer states "Phases: 11/14" but there is no explicit Phase Gate Checklist section showing which phases were completed vs. skipped. This makes it hard to verify whether P2 (data sampling) and P3 (distribution analysis) were formally executed.

2. **Low — `ClusteredIndex_AA_862157_Id` naming**: The index name `ClusteredIndex_AA_862157_Id` is misleading — the DDL shows it's a `NONCLUSTERED INDEX`. The wiki correctly states "three nonclustered indexes" in Section 3.1 but element #2 references this index by its misleading name without clarifying it's actually nonclustered. Minor confusion risk.

3. **Low — Section 8 sparse**: Only one Atlassian reference (Freshservice CR #20353). This is acceptable given the external-vendor origin, but the section could note whether Treezor API documentation exists externally.

4. **Negligible — `partition_date` derivation**: Element #8 says "Corresponds to the date component of `@Created`" but this is labeled as an inference, not confirmed. The review-needed sidecar correctly flags this for verification.

5. **Negligible — Missing explicit grain statement**: Section 1 says "Each row represents one XML file ingested" which is good, but a formal "**Grain**: one row per Treezor XML document" callout in the property table or Section 1 would strengthen clarity.

---

### Regeneration Feedback

Not needed — this wiki passes. For future polish:
1. Add an explicit Phase Gate Checklist subsection showing P1–P3 completion status with checkboxes.
2. Clarify in element #2 that `ClusteredIndex_AA_862157_Id` is actually a nonclustered index despite its name.
3. Consider adding a note in Section 8 about external Treezor API documentation if available.

---

### Weighted Calculation

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

**Verdict: PASS (8.85)**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsActivities_862157",
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
      "column_or_section": "Footer",
      "problem": "Footer states 'Phases: 11/14' but no explicit Phase Gate Checklist section showing which phases (P1–P3) were completed vs skipped. Cannot formally verify P2/P3 execution."
    },
    {
      "severity": "low",
      "column_or_section": "@Id (Element #2)",
      "problem": "References index 'ClusteredIndex_AA_862157_Id' by name without clarifying it is actually a NONCLUSTERED index despite the misleading name. Section 3.1 correctly states nonclustered but the element description could confuse readers."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Only one Atlassian reference (Freshservice CR #20353). No mention of external Treezor API documentation or eMoney team confluence pages that may provide additional context."
    },
    {
      "severity": "negligible",
      "column_or_section": "partition_date (Element #8)",
      "problem": "States 'Corresponds to the date component of @Created' as fact but this is inferred, not confirmed. The review-needed sidecar correctly flags this for verification."
    },
    {
      "severity": "negligible",
      "column_or_section": "Section 1 / Property Table",
      "problem": "Missing a formal grain statement (e.g., 'Grain: one row per Treezor XML document') in the property table. The narrative describes the grain but a structured callout would improve scannability."
    }
  ],
  "regeneration_feedback": "No regeneration needed — wiki passes at 8.85. For future polish: (1) Add an explicit Phase Gate Checklist subsection with P1–P3 checkboxes. (2) Clarify in element #2 that ClusteredIndex_AA_862157_Id is a nonclustered index despite its name. (3) Add external Treezor API documentation references to Section 8 if available.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["29.8M rows", "2021-09-05 to 2026-04-26", "etr_* ~99.8% NULL", "Created ~41.6% NULL"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
