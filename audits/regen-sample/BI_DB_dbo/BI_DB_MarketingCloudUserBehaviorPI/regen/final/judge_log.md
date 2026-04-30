## Judge Review: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (CID, AccountId, UserPI, TotalAmountInvest, OpenActiveInstruments). All tiers verified correct against SP code and upstream wikis. CID/AccountId/UserPI correctly trace through dim-lookup passthroughs to root origins (Customer.CustomerStatic, BackOffice.Customer). TotalAmountInvest and OpenActiveInstruments are ETL-computed aggregations, correctly tagged Tier 2. CIDViewed correctly tagged Tier 3 (Fact_UserPageViews has no wiki). Zero mismatches.

**Dimension 2 — Upstream Fidelity: 10/10**
All 3 Tier 1 columns carry verbatim descriptions from the Dim_Customer wiki, with appropriate passthrough/ETL context appended. No paraphrasing, no dropped semantics.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 13 elements match 13 DDL columns. Every element row has 5 cells with tier tags. Property table has all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar has no Section 4 leak.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (Marketing Cloud PI profile views + copy-trading), row grain, ETL SP + author, refresh pattern, row count (156,092), date range (20240502–20240531), companion table, and staleness warning. An analyst reading this would know exactly when and why to query it.

**Dimension 5 — Data Evidence: 8/10**
Strong data evidence: 156,092 rows, 75,347 distinct customers, 5,575 viewed PIs, 118 NULL AccountId rows. Date range cited. Footer says "Phases: 11/14". No explicit P2/P3 checkboxes in the wiki body, but the specificity of counts indicates live data was used.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed. Minor: no explicit Phase Gate Checklist section.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer.RealCID) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_UserPageViews.RealCID (renamed)." | YES | None — verbatim core with passthrough note appended |
| AccountId | "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced." (Dim_Customer.SalesForceAccountID) | "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID." | YES | None — verbatim core with ETL context appended |
| UserPI | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." (Dim_Customer.UserName) | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.UserName via JOIN on CIDViewed=RealCID (renamed to UserPI)." | YES | None — verbatim core with passthrough note appended |

### Top 5 Issues

1. **Severity: low | Section 1** — The phrase "for a given DateID" in "Each row represents a unique (CID, CIDViewed) pair for a given DateID" is slightly misleading. The UPSERT key is (CID, CIDViewed) without DateID; DateID is overwritten on update. Section 2.1 correctly states the grain as (CID, CIDViewed). Minor inconsistency.

2. **Severity: low | Section 4, OpenActiveInstruments** — Description says "Aggregated across all mirrors per (CID, ParentCID)" which is correct after the `#dpAssetPI` re-aggregation. The SP first computes per (CID, ParentCID, RealizedEquity) then sums. The description is not wrong but elides the intermediate grouping step.

3. **Severity: low | TotalAmountInvest** — The SP code groups by `dm.RealizedEquity` in `#dp_AmountInvestPI` then SUMs in `#dpAssetPI`. The wiki's description "Sum of Dim_Mirror.RealizedEquity across all mirrors" is functionally accurate but masks the two-step aggregation. Minor nuance loss.

4. **Severity: informational | Section 8** — Atlassian sources skipped. Expected in regen harness mode.

5. **Severity: informational | UC Target** — Listed as `_Not_Migrated`. Correctly documents current state.

### Regeneration Feedback

No regeneration needed. Minor polish opportunities:
1. Clarify Section 1 grain statement to say "(CID, CIDViewed)" without the "for a given DateID" qualifier, consistent with Section 2.1.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_MarketingCloudUserBehaviorPI",
  "weighted_score": 9.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_UserPageViews.RealCID (renamed).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "AccountId",
      "upstream_quote": "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced.",
      "wiki_quote": "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "UserPI",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.UserName via JOIN on CIDViewed=RealCID (renamed to UserPI).",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Grain statement says 'unique (CID, CIDViewed) pair for a given DateID' but the UPSERT key is (CID, CIDViewed) without DateID. DateID is overwritten on update. Section 2.1 correctly states the grain as (CID, CIDViewed)."
    },
    {
      "severity": "low",
      "column_or_section": "OpenActiveInstruments",
      "problem": "Description elides the two-step aggregation: first per (CID, ParentCID, RealizedEquity) in #dp_AmountInvestPI, then SUM in #dpAssetPI. Functionally correct but masks intermediate grouping."
    },
    {
      "severity": "low",
      "column_or_section": "TotalAmountInvest",
      "problem": "Wiki says 'Sum of Dim_Mirror.RealizedEquity across all mirrors' which is functionally accurate but the SP actually passes RealizedEquity through as a GROUP BY column first, then SUMs across the intermediate result."
    },
    {
      "severity": "informational",
      "column_or_section": "Section 8",
      "problem": "Atlassian sources skipped (expected in regen harness mode)."
    },
    {
      "severity": "informational",
      "column_or_section": "UC Target",
      "problem": "Listed as _Not_Migrated. Correctly documents current migration state."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
