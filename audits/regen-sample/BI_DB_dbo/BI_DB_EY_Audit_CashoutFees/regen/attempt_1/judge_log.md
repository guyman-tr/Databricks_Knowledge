## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_CashoutFees

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (RealCID, Regulation, Category, Commission, Country). All tiers are correct. Dim-lookup passthroughs (Regulation, Club, Country, AccountType, PopularInvestors) are correctly traced to their Dictionary root origins, not mis-tagged as Tier 2 via the SP. ETL-computed columns (DateID, Category, Commission, UpdateDate) are correctly Tier 2. No mismatches.

**Dimension 2 — Upstream Fidelity: 9/10**
All 7 Tier 1 columns preserve the core upstream text. Additions (passthrough notes, value counts) do not constitute semantic loss. One column (Occurred) selectively trims inapplicable context (position open/login timestamps) — defensible given this table only has cashout events, but technically not verbatim. No vendor names dropped, no NULL semantics lost, no FK targets removed.

**Dimension 3 — Completeness: 10/10**
All 10 checklist items pass: 8 sections present, 12 elements match 12 DDL columns, all rows have 5 cells, all descriptions have tier tags, property table complete, ETL pipeline diagram with real names, footer has tier breakdown, Section 1 has row count + date range, review-needed sidecar has no Elements section.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (EY audit), row grain (one withdrawal per date), ETL SP with author, refresh pattern (DELETE+INSERT per DateID), source filters (ActionTypeID=30, IsCreditReportValidCB=1, IsRedeem=0), row count (6.1M), date range (2023-01-01 to 2025-10-27). An analyst could immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 8/10**
Row count (6.1M), date range (1,028 distinct dates), enum values (11 regulations, 8 club tiers, 9 PI statuses, 147 countries) all present. Commission distribution noted (predominantly 0.0). Footer says "Phases: 11/14" suggesting data phases were run. No explicit Phase Gate Checklist section in the wiki body, but data claims appear grounded.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score and phase count. Minor deviation: tier legend only shows Tier 1 and Tier 2 (appropriate since no other tiers exist).

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID." | "Real-account Customer ID. HASH distribution key in source. References `Dim_Customer.RealCID`. Each customer has one real CID." | MINOR | Added "in source" qualifier — contextually accurate (BI_DB is ROUND_ROBIN) |
| WithdrawID | "Withdrawal request ID for cashout events. 0 for non-cashout events." | "Withdrawal request ID for cashout events. 0 for non-cashout events. Part of the clustered index." | MINOR | Added local index context |
| Occurred | "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded." | "UTC timestamp when the action occurred. For credits: when the credit was recorded." | MINOR | Trimmed inapplicable context (position/login) — defensible for cashout-only table |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. 11 distinct values in 2025: ..." | YES | Core text verbatim; additions only |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel." | YES | Core text verbatim; passthrough note added |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row in Dim_Country. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. 147 distinct values in 2025 data." | MINOR | "Unique per row" → "Unique per row in Dim_Country" |
| AccountType | "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification." | "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Passthrough from Dim_AccountType." | YES | Verbatim with passthrough note |
| PopularInvestors | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration." | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus." | YES | Verbatim with passthrough note |

### Top 5 Issues

1. **Low severity — Occurred selective trimming**: Dropped "For position opens: when position was opened. For logins: login time." from the upstream Fact_CustomerAction description. Defensible (this table only has cashouts) but deviates from strict verbatim inheritance.

2. **Low severity — No explicit Phase Gate Checklist**: The wiki body doesn't contain a visible P1/P2/P3 checklist. The footer mentions "Phases: 11/14" but doesn't detail which were skipped. Minor shape gap.

3. **Low severity — WithdrawID type discrepancy with upstream**: Upstream Fact_CustomerAction declares WithdrawID as `int`, but the DDL and wiki show `bigint`. The wiki correctly reflects the DDL (the target table widened the type), but doesn't note the type difference from the source.

4. **Low severity — Commission gotcha could note the actual range**: The gotcha says "Predominantly 0.0" but doesn't give a percentage or count of non-zero rows, which would be more useful for an auditor.

5. **Low severity — Section 6.2 Referenced By is minimal**: Only lists the writer SP. Other BI_DB objects or reports that consume this audit table are not mentioned (if any exist).

### Regeneration Feedback

Not applicable — wiki passes. Minor suggestions for a future polish pass:
1. Consider preserving the full upstream Occurred description with a note that only the "credits" context applies here.
2. Add an explicit Phase Gate Checklist to Section 1 or as a subsection.
3. Note the WithdrawID type widening (int → bigint) from source.

### Weighted Score Calculation

```
weighted = 0.25*10 + 0.20*9 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 1.80 + 2.00 + 1.35 + 0.80 + 0.90
         = 9.35
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_CashoutFees",
  "weighted_score": 9.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID.",
      "wiki_quote": "Real-account Customer ID. HASH distribution key in source. References `Dim_Customer.RealCID`. Each customer has one real CID.",
      "match": "MINOR",
      "loss": "Added 'in source' qualifier — contextually accurate since BI_DB table is ROUND_ROBIN not HASH"
    },
    {
      "column": "WithdrawID",
      "upstream_quote": "Withdrawal request ID for cashout events. 0 for non-cashout events.",
      "wiki_quote": "Withdrawal request ID for cashout events. 0 for non-cashout events. Part of the clustered index.",
      "match": "MINOR",
      "loss": "Added local index context not present in upstream"
    },
    {
      "column": "Occurred",
      "upstream_quote": "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded.",
      "wiki_quote": "UTC timestamp when the action occurred. For credits: when the credit was recorded.",
      "match": "MINOR",
      "loss": "Trimmed position-open and login context (inapplicable to cashout-only table)"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. 11 distinct values in 2025: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, eToroUS, MAS, FinCEN.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row in Dim_Country. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. 147 distinct values in 2025 data.",
      "match": "MINOR",
      "loss": "Changed 'Unique per row' to 'Unique per row in Dim_Country'"
    },
    {
      "column": "AccountType",
      "upstream_quote": "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification.",
      "wiki_quote": "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Passthrough from Dim_AccountType.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PopularInvestors",
      "upstream_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration.",
      "wiki_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Occurred",
      "problem": "Upstream Fact_CustomerAction description trimmed: dropped 'For position opens: when position was opened. For logins: login time.' — defensible for a cashout-only table but deviates from strict verbatim Tier 1 inheritance."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Footer",
      "problem": "No explicit Phase Gate Checklist in wiki body. Footer says 'Phases: 11/14' but does not detail which phases were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "WithdrawID",
      "problem": "Upstream Fact_CustomerAction declares WithdrawID as int (NO NULL), but DDL and wiki show bigint (NULL). Type widening is correctly reflected but not called out."
    },
    {
      "severity": "low",
      "column_or_section": "Commission",
      "problem": "Gotcha says 'predominantly 0.0' but provides no percentage or count of non-zero rows — an auditor would benefit from specifics."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Referenced By only lists SP_EY_Audit_CashoutFees. Any downstream consumers (reports, views) are not mentioned."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["6.1M rows", "1,028 distinct dates", "147 distinct countries", "11 distinct regulations"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
