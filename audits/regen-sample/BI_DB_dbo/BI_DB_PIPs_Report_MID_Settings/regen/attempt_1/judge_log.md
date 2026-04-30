## Judge Summary — BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Tier Accuracy** | 10 | All 7 columns correctly tagged Tier 2 — every column is ETL-computed (SP parameter literals, CAST+concat, complex CASE logic, GETDATE()). No passthroughs exist. Verified Date, DateID, TransactionID, MIDName, MID. |
| **Upstream Fidelity** | 7 | No Tier 1 columns exist. Table is entirely synthesized by SP_PIPs_Report_MID_Settings with no direct passthroughs from upstream wikis. Neutral score per rubric. |
| **Completeness** | 8 | 9/10 checks pass. Missing: UC Target not listed in property table (though this table may genuinely lack one). All 8 sections present, 7/7 elements, tier tags on all descriptions, ETL pipeline diagram present, footer has tier breakdown. |
| **Business Meaning** | 10 | Exceptional. Section 1 names the domain (MID routing), row grain (per transaction per date), ETL SP, refresh pattern (daily), row count (15.8M), date range (2024-01-01 to present), downstream consumer (Tableau DepositWithdrawFee), and why it exists as a separate table. |
| **Data Evidence** | 8 | Row count (15.8M), date range, ~11% blank rate (28,785/260,322 in Sept 2025), specific entity values (eToroEU/UK/AU/ME/US, EMUK, PWMBUS). Phase completion states 11/14. |
| **Shape Fidelity** | 9 | Numbered sections, tier legend in §4, real SQL in §7, footer with quality score and phase count. Minor: property table uses "ETL Pattern" instead of standard "Load Pattern" label. |

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. All 7 columns are Tier 2 (ETL-computed). This is correct — the table is entirely synthesized by `SP_PIPs_Report_MID_Settings` through complex CASE logic, string concatenation, and SP parameter injection. No column values pass through unchanged from any upstream table.

| column | upstream_quote | wiki_quote | match | loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Property table** — UC Target row missing. If this table has no UC export, a row stating "UC Target: N/A" would satisfy the completeness check.

2. **Severity: low | Section 3.2** — Query pattern `WHERE DateID BETWEEN @start AND @end` uses `DateID` but the suggested column filter text says "DateID" while the actual clustered index is on `[Date]`, not `DateID`. Minor confusion — analysts should prefer `[Date]` for index-aligned filtering.

3. **Severity: low | Row count discrepancy potential** — Wiki claims 15.8M rows. Review-needed sidecar shows ~260K rows/day for a single Sept 2025 date. Over 618 days (2024-01-01 to 2025-09-10) that would imply ~160M, not 15.8M. If daily volumes were lower in early 2024 this could reconcile, but worth flagging.

4. **Severity: low | Section 6.2** — "Referenced By" cites "Tableau DepositWithdrawFee report" which is not a Synapse object. This is fine contextually but differs from standard format which lists DWH objects.

5. **Severity: low | Withdraw MerchantAccountID resolution** — The wiki §2.2 states MerchantAccountID is resolved from `History.WithdrawToFundingAction` but the SP actually uses both `External_Etoro_History_WithdrawToFundingAction` (Dealing_staging) and `DWH_staging.etoro_History_WithdrawToFundingAction` via a FULL OUTER JOIN pattern. The wiki simplifies this slightly.

### Regeneration Feedback

Not needed — wiki passes. Minor improvements if desired:
1. Add `UC Target: N/A` row to property table.
2. Clarify that clustered index is on `[Date]`, so date-range queries should prefer `[Date]` column over `DateID` for index utilization.
3. Verify 15.8M row count against live data — may be outdated if data started accumulating in early 2024 at lower daily volumes.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PIPs_Report_MID_Settings",
  "weighted_score": 8.63,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Property table",
      "problem": "UC Target row missing from property table. Should state 'N/A' if no UC export exists."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.2",
      "problem": "Query pattern suggests WHERE DateID BETWEEN but clustered index is on [Date] not DateID. Analysts should prefer [Date] for index-aligned filtering."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "15.8M row count may be inconsistent with review-needed data showing ~260K rows/day over 618 days (~160M expected). Verify against live data."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Referenced By cites Tableau report rather than a Synapse object. Acceptable contextually but non-standard format."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2",
      "problem": "Withdraw MerchantAccountID resolution simplifies the FULL OUTER JOIN between External_Etoro_History_WithdrawToFundingAction and #wtf into a single source reference."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["15.8M rows", "~11% blank MIDName/MID", "28785/260322 unresolved in Sept 2025"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
