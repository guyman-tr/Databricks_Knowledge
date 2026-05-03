## Adversarial Review: eMoney_Tribe.Authorizes-837045

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (`@Created`, `@Id`, `etr_y`, `partition_date`, `SynapseUpdateDate`). All are correctly tagged Tier 3. The upstream bundle confirms `_no_upstream_found.txt` — no wiki exists for any source. Tier 3 is the only defensible assignment. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available in the bundle. Per rubric, this is neutral (score 7). The writer correctly did not fabricate Tier 1 attributions.

**Dimension 3 — Completeness: 10/10**
- [x] All 8 sections present
- [x] Element count matches DDL (9/9)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ASCII pipeline diagram with real object names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (3,772,924) and date range (2021-09-05 to 2026-04-26)
- [x] No dictionary columns applicable
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToro Money card authorizations), row grain (XML ingestion header record), ETL SP (`SP_eMoney_Reconciliation_ETLs`), refresh pattern (daily via Generic Pipeline), row count, date range, and the parent-child relationship with three sibling tables. An analyst landing here would immediately understand this is a header table and needs JOINs for actual business data.

**Dimension 5 — Data Evidence: 7/10**
Strong specifics: row count (3,772,924), date range, NULL rates for `etr_*` columns (99.8%), NULL rate for `Created` (~11%, 364,581 of 3,174,513), latest `SynapseUpdateDate` (2026-04-26 06:33:40). Footer says "Phases: 12/14" but there is no explicit Phase Gate Checklist section — the reader cannot verify which phases were completed or skipped. Data claims appear grounded but the audit trail is implicit.

**Dimension 6 — Shape Fidelity: 8/10**
All numbered sections present, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviations: no explicit Phase Gate Checklist section, and the property table's "HEAP + NCI on `@Id`, `partition_date`, `@Created`" could be misread as a single composite index rather than three separate NCIs.

### T1 Fidelity Table

No Tier 1 columns exist — no upstream wiki was available.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Medium — Property table index description ambiguous**: "HEAP + NCI on `@Id`, `partition_date`, `@Created`" reads like one composite NCI. The DDL defines three separate NCIs (`ClusteredIndex_Authorizes_837045` on `@Id`, `XI_partition_date` on `partition_date`, `idx_837045_created` on `@Created`). Should list them individually.

2. **Low — Misleading index name not flagged**: The index `ClusteredIndex_Authorizes_837045` is actually a NONCLUSTERED INDEX per DDL. The wiki element for `@Id` says "Indexed (ClusteredIndex_Authorizes_837045)" without noting the naming contradiction. An analyst might assume clustered ordering exists.

3. **Low — No Phase Gate Checklist section**: Footer claims "Phases: 12/14" but no checklist section exists for the reader to verify which 2 phases were skipped and whether data claims are affected.

4. **Low — `Created` vs `@Created` semantics remain speculative**: Element #9 says "may represent a business-level event timestamp" — this is hedged speculation. The review-needed sidecar correctly flags this, but the wiki element description should avoid "may represent" language and simply state what is known.

5. **Low — Section 5.1 source column names unverifiable**: The lineage table claims source columns like "Created attribute" and "Id attribute" from "Tribe XML" but these names are inferred from the `@` prefix convention, not from actual XML schema documentation. This is appropriately Tier 3 but the source column names look more authoritative than they are.

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS**

### Regeneration Feedback

No regeneration required. Minor improvements if the writer revisits:
1. Expand property table index line to list three separate NCIs by name
2. Add a note that `ClusteredIndex_Authorizes_837045` is misleadingly named (it's NCI, not clustered)
3. Add an explicit Phase Gate Checklist section showing which phases were completed
4. Replace "may represent" in `Created` description with "purpose unconfirmed by upstream documentation"

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "Authorizes-837045",
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
      "severity": "medium",
      "column_or_section": "Property table (Synapse Index)",
      "problem": "Index description 'HEAP + NCI on @Id, partition_date, @Created' reads as one composite NCI. DDL defines three separate NCIs: ClusteredIndex_Authorizes_837045 on @Id, XI_partition_date on partition_date, idx_837045_created on @Created. Should list individually."
    },
    {
      "severity": "low",
      "column_or_section": "@Id (Element #2)",
      "problem": "References index 'ClusteredIndex_Authorizes_837045' without noting it is actually a NONCLUSTERED INDEX despite the misleading name. Analyst may assume clustered ordering exists."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / missing section",
      "problem": "Footer claims 'Phases: 12/14' but no Phase Gate Checklist section exists. Reader cannot verify which 2 phases were skipped or whether data claims are affected."
    },
    {
      "severity": "low",
      "column_or_section": "Created (Element #9)",
      "problem": "Description uses speculative 'may represent a business-level event timestamp'. Should state 'purpose unconfirmed by upstream documentation' to avoid implying partial knowledge."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.1 (Source Columns)",
      "problem": "Source column names ('Created attribute', 'Id attribute') are inferred from @ prefix convention, not from actual XML schema documentation. Looks more authoritative than warranted."
    }
  ],
  "regeneration_feedback": "No regeneration required (PASS). Minor improvements: (1) Expand property table index line to list three separate NCIs by name. (2) Note that ClusteredIndex_Authorizes_837045 is misleadingly named — it is NCI, not clustered. (3) Add explicit Phase Gate Checklist section. (4) Replace speculative 'may represent' in Created description with factual 'purpose unconfirmed'.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 3,772,924 in Section 1",
      "Date range 2021-09-05 to 2026-04-26 in Section 1",
      "etr_* 99.8% NULL in Elements 4-6",
      "Created ~11% NULL (364,581 of 3,174,513) in Element 9",
      "SynapseUpdateDate latest 2026-04-26 06:33:40 in Element 7"
    ],
    "skipped_phases": ["Phase Gate Checklist section absent; footer claims 12/14 but does not identify which 2 were skipped"]
  }
}
</JUDGE_VERDICT>
