## Review: eMoney_Tribe.CardsSnapshots_Account-513255

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
Sampled 5 columns: @Id, AccountStatus, AccountLimitsGroupName, Created, etr_y. The bundle explicitly states "NO UPSTREAM WIKI was resolvable for any source." Yet the writer claims Tier 1 for @Id and Created. With no upstream wiki in the bundle, there is nothing to quote verbatim — these must be Tier 3. 2 mismatches out of 5.

**Dimension 2 — Upstream Fidelity: 5/10**
The writer claims 2 Tier 1 columns (@Id, Created) citing "Tribe.CardsSnapshots_Account-513255" as the upstream wiki source. But the bundle is unambiguous: no upstream wiki was resolved. The writer fabricated Tier 1 provenance. Since no upstream wiki existed, the neutral score would be 7, but deducting for 2 false Tier 1 claims (wrong tier origin) drops this to 5.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 25 elements match DDL exactly. Every element row has 5 cells with tier tags. Property table has all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (86.4M) and date range (2023-12-20 to 2026-04-26). Review-needed sidecar does not contain `## 4. Elements`. 10/10 checklist items pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (Tribe card provider), row grain (point-in-time account snapshot), hierarchical context (child of CardsSnapshots_Accounts-350640), ETL pattern (Generic Pipeline, Append, daily), downstream consumer (SP_eMoney_Reconciliation_ETLs), row count, and date range. An analyst can immediately understand when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (86.4M) and date range present. Specific enum values with percentages (AccountStatus: A ~94%, S ~4.4%; AccountCurrency: GBP ~83%, EUR ~17%; limits groups with distribution). Empty-string vs NULL behavior documented. Footer says "Phases: 13/14" but no explicit Phase Gate Checklist section is visible to confirm P2/P3 completion.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and phase count. Minor deviation: no explicit Phase Gate Checklist section; phase status is only in the footer line.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| @Id | *No upstream wiki exists in the bundle* | "PK. (Tier 1 — Tribe.CardsSnapshots_Account-513255)" | NO | False Tier 1 claim — no upstream wiki was available to quote from |
| Created | *No upstream wiki exists in the bundle* | "Source timestamp. (Tier 1 — Tribe.CardsSnapshots_Account-513255)" | NO | False Tier 1 claim — no upstream wiki was available to quote from |

### Top 5 Issues

1. **HIGH — @Id (Element #1)**: Tagged Tier 1 citing Tribe.CardsSnapshots_Account-513255, but the upstream bundle contains no wiki for this source. Must be Tier 3.

2. **HIGH — Created (Element #24)**: Tagged Tier 1 citing Tribe.CardsSnapshots_Account-513255, but no upstream wiki exists in the bundle. Must be Tier 3.

3. **MEDIUM — Columns 3–19 (AccountId through ReservedBalance)**: All are passthrough columns from the production source and tagged Tier 3, which is correct given no upstream wiki. However, the lineage file marks them as "Passthrough" — if an upstream wiki were to become available, these would need re-evaluation to Tier 1.

4. **LOW — @Id description**: The description says only "PK." which is extremely sparse. Even as Tier 3, it should describe the column's role as a unique snapshot record identifier (which Section 3.1 acknowledges).

5. **LOW — Footer tier counts**: Footer claims "2 T1" but should be "0 T1, 0 T2, 25 T3" since no upstream wiki exists.

### Weighted Total

```
weighted = 0.25×5 + 0.20×5 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 1.25 + 1.00 + 2.00 + 1.35 + 0.70 + 0.90
         = 7.20
```

### Regeneration Feedback

1. Re-tag @Id and Created as `(Tier 3 — no upstream wiki)` since the upstream bundle contains no resolvable wiki for FiatDwhDB.Tribe.CardsSnapshots_Account-513255.
2. Update the footer tier breakdown from "2 T1, 0 T2, 23 T3" to "0 T1, 0 T2, 25 T3".
3. Expand the @Id description beyond just "PK." — describe it as the unique snapshot record identifier used for distribution and clustering.
4. Update the lineage file to change @Id and Created from Tier 1 to Tier 3.
5. Add an explicit Phase Gate Checklist section or clarify P2/P3 status inline rather than only in the footer.

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "CardsSnapshots_Account-513255",
  "weighted_score": 7.2,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "@Id",
      "upstream_quote": "No upstream wiki exists in the bundle",
      "wiki_quote": "PK. (Tier 1 — Tribe.CardsSnapshots_Account-513255)",
      "match": "NO",
      "loss": "False Tier 1 claim — no upstream wiki was available in the bundle to quote from. Must be Tier 3."
    },
    {
      "column": "Created",
      "upstream_quote": "No upstream wiki exists in the bundle",
      "wiki_quote": "Source timestamp. (Tier 1 — Tribe.CardsSnapshots_Account-513255)",
      "match": "NO",
      "loss": "False Tier 1 claim — no upstream wiki was available in the bundle to quote from. Must be Tier 3."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "@Id",
      "problem": "Tagged Tier 1 citing Tribe.CardsSnapshots_Account-513255 as upstream wiki, but the upstream bundle explicitly states no wiki was resolvable for any source. Must be Tier 3."
    },
    {
      "severity": "high",
      "column_or_section": "Created",
      "problem": "Tagged Tier 1 citing Tribe.CardsSnapshots_Account-513255 as upstream wiki, but the upstream bundle contains no wiki for this source. Must be Tier 3."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '2 T1, 0 T2, 23 T3' but should be '0 T1, 0 T2, 25 T3' since no upstream wiki exists in the bundle."
    },
    {
      "severity": "low",
      "column_or_section": "@Id",
      "problem": "Description says only 'PK.' which is extremely sparse even for Tier 3. Should describe the column's role as the unique snapshot record identifier used for HASH distribution and clustered index."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 13/14' but P2/P3 completion status is not verifiable from the wiki content."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag @Id as Tier 3 — no upstream wiki exists in the bundle. (2) Re-tag Created as Tier 3 — no upstream wiki exists in the bundle. (3) Update footer tier counts to 0 T1, 0 T2, 25 T3. (4) Expand @Id description beyond 'PK.' to describe its role as unique snapshot record identifier, HASH distribution key, and clustered index column. (5) Update lineage file to mark @Id and Created as Tier 3 instead of Tier 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
