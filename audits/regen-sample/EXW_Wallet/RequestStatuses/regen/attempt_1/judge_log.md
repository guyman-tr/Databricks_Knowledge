## Review: EXW_Wallet.RequestStatuses

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `Id`, `RequestId`, `RequestStatusId`, `etr_y`, `partition_date`.

The upstream bundle explicitly states **"NO UPSTREAM WIKI was resolvable for any source."** Therefore:
- Business columns from WalletDB → Tier 3 is correct (no upstream wiki to inherit from)
- ETL columns from Generic Pipeline → Tier 2 is correct (pipeline-generated)

All 5 sampled columns have correct tier assignments. 0 mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are **zero Tier 1 columns** in this wiki, which is correct — no upstream wiki existed in the bundle. The writer properly tagged all WalletDB-sourced columns as Tier 3 and all pipeline columns as Tier 2. No missed inheritance is possible when no upstream documentation exists.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **9/10** → Score **8**

| Check | Pass? |
|-------|-------|
| All 8 sections present | Yes |
| Element count = DDL count (10=10) | Yes |
| Every element row has 5 cells | Yes |
| Every description ends with (Tier N — source) | Yes |
| Property table has Production Source, Refresh, Distribution, UC Target | Yes |
| Section 5.2 has ETL pipeline ASCII diagram with real names | Yes |
| Footer has tier breakdown counts | Yes |
| Section 1 has row count and date range | Yes (48.4M, 2018-07-11 to present) |
| Dictionary columns ≤15 values list key=value pairs | N/A (RequestStatusId has 29 values, no other dicts) |
| .review-needed.md does NOT contain `## 4. Elements` | Yes |

9/10 applicable checks pass. The dictionary-values check is borderline — `RequestStatusId` has 29 values (exceeding the ≤15 threshold), but the writer did list many of them inline in the element description anyway, which is good practice.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names:
- The domain: eToro crypto wallet status transitions
- Row grain: single status transition event per row
- Row count: 48.4M
- Date range: 2018-07-11 to present
- ETL pattern: Generic Pipeline, Append, daily
- Consuming SPs: `SP_EXW_C2F_E2E`, `SP_EXW_FactRedeemTransactions`
- State machine pattern with specific status codes

A new analyst would immediately know what this table is and when to use it.

### Dimension 5 — Data Evidence: **7/10**

Strong evidence of live data usage:
- Row count (48.4M) and date range stated
- Status distribution with specific counts (ReadByExecuter 24.1M/49.8%, Start 5M, etc.)
- DetailsJson NULL rate (~85%, 41.3M of 48.4M)
- 23 of 29 dictionary values with rows; 6 with zero rows named specifically

Footer says "Phases: 12/14" but no explicit Phase Gate Checklist with `[x]` markers is shown. The data claims appear grounded but the missing checklist prevents full confidence.

### Dimension 6 — Shape Fidelity: **7/10**

- Numbered sections 1-8: present
- Tier legend in Section 4: present
- SQL samples in Section 7: present but Section 7.1 has **syntactically invalid SQL** — `ROW_NUMBER()` used directly in a `WHERE` clause, which SQL Server does not allow. The writer acknowledged this with a note, but the sample query is still broken as written.
- Footer format: present with quality score and phases

Deduction for the invalid SQL sample.

### Top 5 Issues

1. **Section 7.1 — Invalid SQL**: `ROW_NUMBER()` cannot appear in a `WHERE` clause. The writer added a disclaimer note but should have written valid SQL using a CTE.
2. **No Phase Gate Checklist**: Footer claims 12/14 phases but no explicit checklist with `[x]`/`[ ]` markers to verify which phases were completed.
3. **RequestStatusId inline values incomplete**: The element description lists some status codes but not all 29. Since there are 29 (>15), this isn't required, but the partial listing could mislead — consider listing all or referencing the dictionary table exclusively.
4. **etr_* columns described as "Tier 2 — Generic Pipeline"**: This is defensible but the description claims specific format patterns (e.g., 'YYYY-MM') without citing where that format is documented — these are effectively Tier 3 inferences labeled as Tier 2.
5. **DetailsJson JSON schema undocumented**: The review-needed sidecar flags this correctly, but the wiki could mention that the JSON schema is unstructured/variable rather than leaving it as "additional context."

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×7
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.70
         = 8.25
```

### Regeneration Feedback

Not required (PASS), but recommended improvements:
1. Fix Section 7.1 SQL to use a proper CTE wrapping the `ROW_NUMBER()` instead of placing it in the `WHERE` clause.
2. Add an explicit Phase Gate Checklist with `[x]`/`[ ]` markers for all 14 phases.
3. Consider whether `etr_y`, `etr_ym`, `etr_ymd` are truly Tier 2 (documented pipeline behavior) or Tier 3 (inferred from data patterns). If the format is inferred from sample data, tag as Tier 3.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "RequestStatuses",
  "weighted_score": 8.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 7.1",
      "problem": "ROW_NUMBER() used directly in WHERE clause — syntactically invalid in SQL Server. Writer added a disclaimer note but should have written valid SQL using a CTE/subquery."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 'Phases: 12/14' but no explicit Phase Gate Checklist with [x]/[ ] markers is present in the wiki to verify which phases were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "Tagged as 'Tier 2 — Generic Pipeline' but the specific format patterns (YYYY-MM, YYYY-MM-DD) appear inferred from data samples rather than documented pipeline behavior. Could be argued as Tier 3."
    },
    {
      "severity": "low",
      "column_or_section": "RequestStatusId",
      "problem": "Element description lists a partial subset of the 29 known status values. Since >15 values, inline listing is not required, but the partial list could mislead. Consider referencing the dictionary table as the authoritative source."
    },
    {
      "severity": "low",
      "column_or_section": "DetailsJson",
      "problem": "JSON schema is flagged as unknown in review-needed sidecar. Wiki describes it as 'additional context' without noting that the structure is variable/undocumented."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "48.4M rows total",
      "ReadByExecuter 24.1M rows (49.8%)",
      "Start 5M rows",
      "ExecuterEnqueued 3.9M rows",
      "Done 3.8M rows",
      "DetailsJson ~85% NULL (41.3M of 48.4M)",
      "23 of 29 dictionary values present"
    ],
    "skipped_phases": ["Phases 12/14 claimed but no explicit checklist shown"]
  }
}
</JUDGE_VERDICT>
