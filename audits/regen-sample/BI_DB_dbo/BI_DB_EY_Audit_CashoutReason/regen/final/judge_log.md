## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_CashoutReason

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: WithdrawID (T1 Billing.Withdraw — correct via FBW passthrough), Country (T1 Dictionary.Country — correct dim-lookup traced to root), CashoutReason (T1 Dictionary.CashoutReason — correct), ModificationDate_WithdrawToFunding_DateID (T2 — correct, ETL-computed), ExternalID (T1 Customer.CustomerStatic — correct via Dim_Customer). All 5 match. All dim-lookup columns correctly trace to the dictionary root origin rather than tagging as Tier 2 via SP.

### Dimension 2 — Upstream Fidelity: **10/10**

All 11 Tier 1 columns carry verbatim upstream descriptions with passthrough context appended. No paraphrasing, no dropped vendor names, no lost NULL semantics.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| WithdrawID | "Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column." (FBW) | "Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. Passthrough from Fact_BillingWithdraw." | YES | — |
| CID | "Customer ID. FK to Customer.CustomerStatic." (FBW) | "Customer ID. FK to Customer.CustomerStatic. Passthrough from Fact_BillingWithdraw." | YES | — |
| WithdrawPaymentID | "Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID." (FBW) | "Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. Passthrough from Fact_BillingWithdraw." | YES | — |
| CashoutReasonID | "Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason." (FBW) | "Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. Passthrough from Fact_BillingWithdraw." | YES | — |
| CashoutReason | "Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history." (Dim_CashoutReason) | "Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. Dim-lookup passthrough from Dim_CashoutReason.Name." | YES | — |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." (Dim_Country) | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID at point-in-time." | YES | — |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." (Dim_PlayerLevel) | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough from Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID at point-in-time." | YES | — |
| GuruStatusName | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration." (Dim_GuruStatus) | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Dim-lookup passthrough from Dim_GuruStatus.GuruStatusName via Fact_SnapshotCustomer.GuruStatusID at point-in-time." | YES | — |
| AccountType | "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification." (Dim_AccountType) | "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Dim-lookup passthrough from Dim_AccountType.Name via Fact_SnapshotCustomer.AccountTypeID at point-in-time." | YES | — |
| ExternalID | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." (Dim_Customer) | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.ExternalID (joined via Fact_SnapshotCustomer.RealCID). Stored as varchar(200) in this table." | YES | — |
| FundingType | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay)." (Dim_FundingType) | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Dim-lookup passthrough from Dim_FundingType.Name via Fact_BillingWithdraw.FundingTypeID_Funding." | YES | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks)

- [x] All 8 sections present
- [x] Element count matches DDL (13/13)
- [x] Every element row has 5 cells
- [x] Every element description ends with (Tier N — source)
- [ ] Property table has UC Target — **missing** (no UC Target row)
- [x] Section 5.2 has ETL pipeline ASCII diagram
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count and date range
- [x] Dictionary columns ≤15 values list values (Club: 8 values listed; GuruStatusName: 9 values listed)
- [x] .review-needed.md does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: **10/10**

Excellent. Section 1 names the domain (EY external audit), row grain (single withdrawal payment execution), ETL SP name, refresh pattern (DELETE+INSERT with auto-backfill), row count (7.6M), date range (2023-01-01 to 2025-10-27), and the critical point-in-time join semantics. A new analyst would immediately know when and why to query this table.

### Dimension 5 — Data Evidence: **8/10**

Row count (7.6M) and date range present. Specific distribution values cited ("Requested by User ~95%", "Private ~99.7%"). P2+P3 marked as completed in the phases list. Minor gap: no explicit NULL-rate claims for GuruStatusName or FundingType (the LEFT JOIN columns).

### Dimension 6 — Shape Fidelity: **9/10**

All structural elements present: numbered sections, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score (9.0/10) and phases. Minor: no `| UC Target |` row in property table.

### Weighted Total

```
weighted = 0.25*10 + 0.20*10 + 0.20*8 + 0.15*10 + 0.10*8 + 0.10*9
         = 2.50 + 2.00 + 1.60 + 1.50 + 0.80 + 0.90
         = 9.30
```

**Verdict: PASS**

### Top 5 Issues

1. **(low)** Property table missing UC Target row — should state "N/A" or equivalent if this table has no UC export.
2. **(low)** WithdrawID description inherits "HASH distribution key and clustered index column" from FBW, which could mislead readers into thinking these properties apply to the BI_DB table (which is ROUND_ROBIN / HEAP). Consider prefixing with "In FBW:" or removing FBW-specific physical properties.
3. **(low)** No explicit NULL-rate documentation for GuruStatusName and FundingType (the two LEFT JOIN columns). Section 3.4 mentions they "may be NULL" but doesn't quantify.
4. **(low)** WithdrawPaymentID type is bigint in DDL but the FBW wiki documents it as int. The wiki correctly uses bigint from the DDL, but the inherited description doesn't note the type widening.
5. **(low)** Section 1 data claims are dated "As of 2025-10-27" — stale by ~6 months. Not a structural error but worth refreshing.

### Regeneration Feedback

No regeneration needed — wiki passes. If iterating for polish:
1. Add a `| UC Target | N/A |` row to the property table.
2. Qualify FBW-specific physical properties in the WithdrawID description (e.g., "In Fact_BillingWithdraw: PK, HASH distribution key, clustered index column").
3. Add NULL-rate estimates for GuruStatusName and FundingType.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_CashoutReason",
  "weighted_score": 9.3,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 8,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "WithdrawID",
      "upstream_quote": "Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column.",
      "wiki_quote": "Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. Passthrough from Fact_BillingWithdraw.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID. FK to Customer.CustomerStatic.",
      "wiki_quote": "Customer ID. FK to Customer.CustomerStatic. Passthrough from Fact_BillingWithdraw.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "WithdrawPaymentID",
      "upstream_quote": "Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID.",
      "wiki_quote": "Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. Passthrough from Fact_BillingWithdraw.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CashoutReasonID",
      "upstream_quote": "Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason.",
      "wiki_quote": "Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. Passthrough from Fact_BillingWithdraw.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CashoutReason",
      "upstream_quote": "Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history.",
      "wiki_quote": "Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. Dim-lookup passthrough from Dim_CashoutReason.Name.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID at point-in-time.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough from Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID at point-in-time.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "GuruStatusName",
      "upstream_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration.",
      "wiki_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Dim-lookup passthrough from Dim_GuruStatus.GuruStatusName via Fact_SnapshotCustomer.GuruStatusID at point-in-time.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "AccountType",
      "upstream_quote": "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification.",
      "wiki_quote": "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Dim-lookup passthrough from Dim_AccountType.Name via Fact_SnapshotCustomer.AccountTypeID at point-in-time.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ExternalID",
      "upstream_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.",
      "wiki_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.ExternalID (joined via Fact_SnapshotCustomer.RealCID). Stored as varchar(200) in this table.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FundingType",
      "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Dim-lookup passthrough from Dim_FundingType.Name via Fact_BillingWithdraw.FundingTypeID_Funding.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Property Table",
      "problem": "Missing UC Target row. Should state N/A if no UC export exists for this table."
    },
    {
      "severity": "low",
      "column_or_section": "WithdrawID",
      "problem": "Inherited description includes FBW-specific physical properties (HASH distribution key, clustered index) that do not apply to the BI_DB table (ROUND_ROBIN / HEAP). Could mislead readers."
    },
    {
      "severity": "low",
      "column_or_section": "GuruStatusName, FundingType",
      "problem": "No explicit NULL-rate documentation for the two LEFT JOIN columns. Section 3.4 mentions they may be NULL but doesn't quantify."
    },
    {
      "severity": "low",
      "column_or_section": "WithdrawPaymentID",
      "problem": "Type is bigint in BI_DB DDL but int in FBW wiki. Inherited description does not note the type widening."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Data claims dated 2025-10-27 are ~6 months stale. Not structural but worth refreshing."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["7.6M rows", "2023-01-01 to 2025-10-27", "~95% Requested by User", "~99.7% Private"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
