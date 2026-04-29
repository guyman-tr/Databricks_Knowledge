## Judge Review: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: FundingID (T1), IsBlocked (T3), Total_Users (T2), Group_Type (T2), Last_Withdraw_Date (T2). All correct. FundingID is a passthrough from Fact_BillingWithdraw — Tier 1 is appropriate. IsBlocked comes from External_etoro_Billing_Funding with no upstream wiki — Tier 3 correct. The three ETL-computed columns are correctly Tier 2. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 9/10**
Only 1 Tier 1 column (FundingID). The core upstream text "FK to Billing.Funding — the payment instrument to which the withdrawal is paid" is preserved verbatim. The upstream's "NULL if no specific instrument selected" was dropped — contextually justified since this table only contains FundingIDs with 2+ users and ID > 7, making NULLs impossible. One trivial contextual omission.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (8) matches DDL (8). Every element has 5 cells. Every description ends with tier tag. Property table complete. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (20,282). Group_Type values listed inline. Review-needed sidecar has no `## 4. Elements`. 10/10 checklist.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent: names the domain (AML Multiple Accounts Dashboard), row grain (one per shared FundingID), ETL SP and pattern (TRUNCATE + INSERT), companion tables, and documents a critical production column-swap bug with live data evidence. Highly specific and actionable. Deducted 1 point for an incorrect claim in Section 2.1: the wiki states rows with 2-4 users would get NULL Group_Type, but the SP CASE expression `WHEN COUNT(DISTINCT CID) <= 20 THEN '5-20'` covers all values from 2 upward.

**Dimension 5 — Data Evidence: 9/10**
Row count (20,282), date ranges (Last_Withdraw_Date 2013-12-18 to 2025-03-12), specific enum values (Group_Type distribution: 99.7% '5-20'), live data confirmation of the column swap (IsBlocked has values 2-151, Total_Users has values 0-1), UpdateDate staleness (2025-03-13). Phases 1-6,8,9,9B,10A,10B,11 listed.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend, real SQL samples in Section 7, footer with quality score and phases. Minor: no explicit Phase Gate Checklist section with `[x]` checkboxes, but phases are listed in footer.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| FundingID | "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected." (Fact_BillingWithdraw #12) | "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. Used here as the grouping key for multi-account detection. Only FundingIDs shared by 2+ customers and with ID > 7 are included." | MINOR | Dropped "NULL if no specific instrument selected" — contextually irrelevant since table only has FundingIDs with 2+ users |

### Top 5 Issues

1. **Medium — Section 2.1, Group_Type logic**: Wiki claims "the CASE has no explicit 2-4 bucket — those rows get NULL Group_Type". This is incorrect. The SP code uses `WHEN COUNT(DISTINCT CID) <= 20 THEN '5-20'`, which covers all values from 2 (the HAVING minimum) to 20. Rows with 2-4 users would get '5-20', not NULL.

2. **Low — FundingID, upstream NULL semantics**: Dropped "NULL if no specific instrument selected" from Fact_BillingWithdraw upstream description. Contextually justified but technically a deviation from verbatim Tier 1 inheritance.

3. **Low — Group_Type, trailing space in SP**: The SP code defines the '500+' bucket as `'500+ '` (with trailing space). The wiki lists it as `'500+'` without the space. Minor data fidelity issue for exact-match queries.

4. **Low — Section 2.2**: States `Total_Approved_Withdraw` source is `Amount_WithdrawToFunding` with "(payout amount in processing currency)". The upstream wiki for Fact_BillingWithdraw describes this as "The actual payout amount in the processing currency" — close but not a verbatim quote, and this is a Tier 2 column so verbatim inheritance isn't required.

5. **Info — Section 6.2**: "AML Multiple Accounts Dashboard" listed as a downstream consumer with "Power BI / reporting dashboard" — this is speculative without Atlassian confirmation (Phase 10 was skipped).

### Regeneration Feedback

1. Fix Section 2.1: Change "those rows get NULL Group_Type" to "rows with 2-4 users also receive '5-20' since the CASE uses `<= 20`, not `BETWEEN 5 AND 20`."
2. Note the trailing space in the '500+' bucket label from the SP source code.
3. Consider adding the minor note about dropped NULL semantics on FundingID for full transparency.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AML_Multiple_Accounts_Withdraw",
  "weighted_score": 9.45,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "FundingID",
      "upstream_quote": "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected.",
      "wiki_quote": "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. Used here as the grouping key for multi-account detection. Only FundingIDs shared by 2+ customers and with ID > 7 are included.",
      "match": "MINOR",
      "loss": "Dropped 'NULL if no specific instrument selected' — contextually irrelevant since table only includes FundingIDs with 2+ users and ID > 7"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 2.1 — Group_Type",
      "problem": "Wiki claims rows with 2-4 users get NULL Group_Type. Incorrect: the SP CASE uses `WHEN COUNT(DISTINCT CID) <= 20 THEN '5-20'`, which covers all values from 2 (HAVING minimum) to 20. Rows with 2-4 users get '5-20', not NULL."
    },
    {
      "severity": "low",
      "column_or_section": "FundingID",
      "problem": "Dropped 'NULL if no specific instrument selected' from Fact_BillingWithdraw upstream description. Contextually justified but deviates from verbatim Tier 1 inheritance."
    },
    {
      "severity": "low",
      "column_or_section": "Group_Type",
      "problem": "SP code defines '500+' bucket as '500+ ' (trailing space). Wiki lists it as '500+' without trailing space. May cause exact-match query issues."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Lists 'AML Multiple Accounts Dashboard' as a downstream consumer with 'Power BI / reporting dashboard' — speculative without Atlassian confirmation (Phase 10 skipped)."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Fix Section 2.1 Group_Type logic — rows with 2-4 users get '5-20' not NULL, since the CASE uses <= 20. (2) Note trailing space in '500+ ' bucket label from SP source. (3) Optionally add transparency note about dropped NULL semantics on FundingID Tier 1 description.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["Row count 20,282", "IsBlocked values 2-151", "Total_Users values 0-1", "Group_Type 99.7% '5-20'", "Last_Withdraw_Date range 2013-12-18 to 2025-03-12", "UpdateDate 2025-03-13"],
    "skipped_phases": ["7", "10"]
  }
}
</JUDGE_VERDICT>
