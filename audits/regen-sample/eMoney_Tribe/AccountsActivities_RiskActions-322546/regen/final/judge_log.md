## Review: eMoney_Tribe.AccountsActivities_RiskActions-322546

### Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 15 columns tagged Tier 3. The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable for any source." Spot-checked `@Id`, `MarkTransactionAsSuspicious`, `etr_ym`, `Created`, `ChangeAccountStatusToReceiveOnly` — all correctly Tier 3 with appropriate sourcing citations. No mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available in the bundle. This is the correct outcome — the writer did not fabricate Tier 1 claims. Neutral score per rubric.

**Dimension 3 — Completeness: 9/10**
- [x] All 8 sections present
- [x] Element count matches DDL (15/15)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (29.8M) and date range (2023-12-20 to present)
- [x] Boolean flag columns enumerate their values (0/1) inline
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 checks → Score: 10. Being slightly generous — the boolean "key=value" listing is inline in descriptions rather than a formal table, but the domain values are fully enumerated.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eMoney/Modulr card management), row grain (risk action flags per account activity), consuming SP (`SP_eMoney_Reconciliation_ETLs`), refresh pattern (incremental data lake), row count (29.8M), date range, and even flag activation rates. A new analyst would know exactly when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Strong data evidence throughout: exact row count (29.8M), date range (2023-12-20 to 2026-04-26), flag distributions (0.08% suspicious = 6,006/7.2M in 2026, 2 `ChangeCardStatusToRisk` in 2026, zero `RejectTransaction`). NULL/empty-string behavior documented for late-added columns. Footer says "Phases: 13/14" but there is no formal Phase Gate Checklist section with explicit `[x]` marks for P2/P3. The data appears genuine based on specificity, but the missing checklist prevents a full score.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section; phase count is only in the footer line.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle contained no resolvable upstream wikis, making Tier 3 the correct assignment for all columns. The `t1_fidelity_table` is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Missing Phase Gate Checklist section** (`shape/evidence`): Footer claims "Phases: 13/14" but there is no explicit Phase Gate Checklist with `[x]`/`[ ]` marks. Analysts cannot verify which phase was skipped or whether P2/P3 data sampling was actually performed.

2. **Query 7.3 references unverified upstream columns** (`Section 7`): The JOIN query references `HolderId`, `AccountId`, `TransactionAmount`, `TransactionCurrencyAlpha`, `TransactionCode` from `AccountsActivities_AccountActivity-833937`. These column names are plausible but not verified against that table's DDL in the bundle.

3. **Section 8 is minimal** (`Section 8`): States "No Atlassian sources searched (regen harness mode)" and mentions a Freshservice link. This is honest but provides no knowledge base context. Acceptable for a raw ingestion table but noted.

4. **Duplicate index not flagged in wiki body** (`Section 3`): The duplicate NCI on `[@Id]` (`ClusteredIndex_AA_322546_Id` and `idx_322546_Id`) is mentioned in the property table and Section 3.1 but only as an observation, not as a warning. The review-needed sidecar correctly flags this.

5. **No explicit "NotifyCardholderBySendingTAIsNotification" activation rate** (`Element 4`): Unlike `MarkTransactionAsSuspicious` (0.08%) and `ChangeCardStatusToRisk` (2 rows), this column has no distribution stats. Minor inconsistency in evidence depth across similar columns.

### Regeneration Feedback

Not required — wiki passes. For polish in a future revision:
1. Add an explicit Phase Gate Checklist section listing P1–P3 with `[x]`/`[ ]` marks.
2. Add activation rate stats for `NotifyCardholderBySendingTAIsNotification` and `ChangeAccountStatusToSuspended` to match the depth given to other flag columns.
3. Verify column names in Query 7.3 against the `AccountsActivities_AccountActivity-833937` DDL.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
         = 8.85
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsActivities_RiskActions-322546",
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
      "severity": "medium",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] marks for P1–P3. Footer claims 'Phases: 13/14' but does not identify which phase was skipped or confirm P2/P3 data sampling was performed."
    },
    {
      "severity": "low",
      "column_or_section": "Section 7 (Query 7.3)",
      "problem": "JOIN query references columns HolderId, AccountId, TransactionAmount, TransactionCurrencyAlpha, TransactionCode from AccountsActivities_AccountActivity-833937 without verifying these column names against that table's DDL."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Section 8 is minimal — states 'No Atlassian sources searched (regen harness mode)' with only a Freshservice link. Acceptable for raw ingestion but provides no knowledge base context."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.1 / @Id indexes",
      "problem": "Duplicate NCI on [@Id] (ClusteredIndex_AA_322546_Id and idx_322546_Id) is mentioned as an observation but not flagged as a warning or anti-pattern in the query advisory."
    },
    {
      "severity": "low",
      "column_or_section": "Element 4 (NotifyCardholderBySendingTAIsNotification)",
      "problem": "No activation rate stats provided for NotifyCardholderBySendingTAIsNotification or ChangeAccountStatusToSuspended, unlike MarkTransactionAsSuspicious (0.08%) and ChangeCardStatusToRisk (2 rows). Inconsistent evidence depth across similar flag columns."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "MarkTransactionAsSuspicious: 0.08% activation rate (6,006/7.2M in 2026)",
      "ChangeCardStatusToRisk: 2 occurrences in 2026",
      "RejectTransaction: 0 activations in 2026",
      "Row count: 29.8M",
      "Date range: 2023-12-20 to 2026-04-26"
    ],
    "skipped_phases": [
      "Phase Gate Checklist section missing — cannot determine which phase was skipped"
    ]
  }
}
</JUDGE_VERDICT>
