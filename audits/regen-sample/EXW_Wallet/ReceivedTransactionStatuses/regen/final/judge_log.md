## Review: EXW_Wallet.ReceivedTransactionStatuses

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Id, StatusId, etr_y, SynapseUpdateDate, DetailsJson). All tiers are correct. The 5 production columns from WalletDB have no upstream wiki (confirmed by bundle: "NO UPSTREAM WIKI was resolvable") → Tier 3 is correct. The 5 pipeline columns (etr_y/ym/ymd, SynapseUpdateDate, partition_date) are ETL-added → Tier 2 is correct. No mismatches.

**Dimension 2 — Upstream Fidelity: 7/10**
No Tier 1 columns exist because no upstream wiki was available in the bundle. This is the neutral case per rubric. The writer correctly avoided fabricating Tier 1 claims. T1 fidelity table is empty.

**Dimension 3 — Completeness: 10/10**
All 10 checks pass: 8 sections present; 10 elements match 10 DDL columns; all element rows have 5 cells; all descriptions end with `(Tier N — source)`; property table has Production Source, Refresh, Distribution, UC Target; Section 5.2 has pipeline diagram with real names; footer has tier breakdown; Section 1 has row count (5.6M) and date range (Sep 2018–Apr 2026); StatusId lists all 7 key=value pairs inline; review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eToroX crypto transaction status tracking), defines row grain (single status change event), describes the ETL pattern (CopyFromLake, Append, daily, no writer SP), gives row count and date range, explains the "latest status wins" downstream pattern, and lists all 7 status values with percentages. An analyst new to this table would immediately understand when and how to query it.

**Dimension 5 — Data Evidence: 7/10**
Row count (5,609,610), date range, status distribution percentages (47%/47%/6%/<1%), NULL rate for SynapseUpdateDate (~54%, 3.0M of 5.6M), and specific SynapseUpdateDate sample value (2026-04-27 06:01:12) all indicate live data was used. Footer says "Phases: 11/14" but no explicit Phase Gate Checklist section with `[x]` marks is present, so I cannot confirm P2/P3 were formally checked off. The specificity of the numbers suggests real queries, but the missing checklist costs a point.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7 (3 queries with proper CROSS APPLY and JOIN patterns), footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section as a numbered subsection. Otherwise matches the golden shape.

### T1 Fidelity Table

No Tier 1 columns exist — no upstream wikis were available in the bundle.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Low — Missing Phase Gate Checklist section.** The footer claims "Phases: 11/14" but there is no explicit `## Phase Gate Checklist` section with `[x]`/`[ ]` marks to let a reader verify which phases were completed and which were skipped.

2. **Low — Section 8 placeholder.** `No Atlassian sources searched (regen-harness mode)` is understandable given the regen context but provides no value to an analyst. Could note whether Confluence/Jira pages exist for the eToroX Wallet service.

3. **Informational — StatusId dictionary lookup not cross-referenced to wiki.** The writer correctly looked up EXW_Dictionary.TransactionStatus live to enumerate status values, but didn't note whether that dictionary table has its own wiki. If it does, the status name descriptions could be elevated to Tier 1 inheritance in the future.

4. **Informational — `partition_date` derivation.** The wiki says it's "derived from the source record" and "matches the date portion of Occurred," which is consistent. However, since this is a Generic Pipeline column, the exact derivation logic (CAST of which source column?) could be more explicit.

5. **Informational — `DetailsJson` string "null" values.** The wiki correctly flags that some rows contain the string `"null"` (as text), which is a valuable gotcha. No issue here, just noting it as a positive.

### Regeneration Feedback

No regeneration needed — the wiki passes. Minor improvements for a future polish pass:

1. Add an explicit Phase Gate Checklist section listing which phases were completed and which were skipped, so the "11/14" claim is verifiable.
2. In Section 8, note whether any Atlassian documentation exists for the eToroX Wallet service or WalletDB, even if not searched in regen mode.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "ReceivedTransactionStatuses",
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
      "column_or_section": "Section (missing)",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] marks. Footer claims 'Phases: 11/14' but the claim is not verifiable from the wiki content."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Placeholder text 'No Atlassian sources searched (regen-harness mode)' provides no value. Should note whether Confluence/Jira pages exist for eToroX Wallet / WalletDB."
    },
    {
      "severity": "informational",
      "column_or_section": "StatusId",
      "problem": "EXW_Dictionary.TransactionStatus was queried live for status values but no cross-reference to its wiki (if one exists) for potential Tier 1 inheritance of status name descriptions."
    },
    {
      "severity": "informational",
      "column_or_section": "partition_date",
      "problem": "Description says 'derived from the source record' but does not specify the exact Generic Pipeline derivation logic (e.g., CAST(Occurred AS date) or similar)."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 5,609,610 in Section 1",
      "StatusId distribution percentages (47%/47%/6%/<1%) in Section 1 and Element 3",
      "SynapseUpdateDate NULL rate ~54% (3.0M of 5.6M) in Element 9 and Section 3.4",
      "Date range Sep 2018 to Apr 2026 in Section 1"
    ],
    "skipped_phases": ["Phase Gate Checklist section not present — cannot determine which 3 of 14 phases were skipped"]
  }
}
</JUDGE_VERDICT>
