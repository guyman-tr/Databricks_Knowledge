I'll review this wiki systematically against the rubric.

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy (7/10)

**5 columns sampled**: CID, AccountId, TotalAmountInvest, CIDViewed, UserPI

| Column | Wiki Claim | Actual | Correct? |
|--------|-----------|--------|----------|
| CID | Tier 1 — Customer.CustomerStatic | Passthrough from Fact_UserPageViews.RealCID; Fact_UserPageViews has no wiki, but root origin Customer.CustomerStatic is well-established across DWH | YES (acceptable root attribution) |
| AccountId | Tier 1 — BackOffice.Customer | Dim-lookup passthrough from Dim_Customer.SalesForceAccountID; Dim_Customer wiki confirms root = BackOffice.Customer | YES |
| TotalAmountInvest | Tier 2 — Dim_Mirror | SUM(dm.RealizedEquity) across mirrors, aggregation = Tier 2 | YES |
| CIDViewed | Tier 1 — Fact_UserPageViews | Passthrough from Fact_UserPageViews, but **Fact_UserPageViews has NO wiki**. Cannot be Tier 1. Should be Tier 3. | **NO** |
| UserPI | Tier 1 — Customer.CustomerStatic | Dim-lookup passthrough from Dim_Customer.UserName; Dim_Customer wiki confirms root = Customer.CustomerStatic | YES |

1 mismatch out of 5 → base score 7. No paraphrasing deductions on mismatched columns.

### Dimension 2 — Upstream Fidelity (6/10)

**T1 Fidelity Table**:

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|-----------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer.RealCID) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_UserPageViews.RealCID (renamed)." | YES | None — core text verbatim, lineage context appended |
| AccountId | "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced." (Dim_Customer.SalesForceAccountID) | "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID." | YES | None — core text verbatim, lineage context appended |
| CIDViewed | No upstream wiki exists (Fact_UserPageViews is unresolved) | "Customer ID of the Popular Investor whose profile was viewed. FK to Dim_Customer.RealCID. Passthrough from Fact_UserPageViews.CIDViewed." | NO | **Wrongly tagged Tier 1 — no upstream wiki exists.** Description is writer-authored, not inherited. |
| UserPI | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." (Dim_Customer.UserName) | "Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer.UserName via JOIN on CIDViewed=RealCID. Represents the Popular Investor's display name." | MINOR | Dropped "enforced via UserName_LOWER computed column index"; added context about PI display name |

CIDViewed is wrongly tagged Tier 1 with no upstream wiki (counts as wrong tier origin). UserPI has minor paraphrasing (dropped index enforcement detail). Score: 6.

### Dimension 3 — Completeness (8/10)

- [x] All 8 sections present
- [x] Element count matches DDL (13/13)
- [x] Every element row has 5 cells
- [x] Every element description ends with (Tier N — source)
- [ ] Property table has UC Target — **MISSING**
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (156,092) and date range (20240502-20240531)
- [x] No dictionary columns requiring inline pairs (N/A)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

9/10 checks → score 8.

### Dimension 4 — Business Meaning (9/10)

Section 1 is excellent: names the domain (Marketing Cloud SFTP export for PI copy-trading behavior), row grain (unique CID/CIDViewed pair), ETL SP with author attribution, refresh pattern (daily rolling 1-month), row count (156,092), date range, distinct customer/PI counts, and explicit differentiation from the Instrument sibling table. An analyst could immediately understand when and why to query this table.

### Dimension 5 — Data Evidence (7/10)

Row count (156,092), date range (20240502-20240531), distinct customer count (75,347), distinct PI count (5,575) all present in Section 1. NULL behavior for AccountId documented. No explicit Phase Gate Checklist with P2/P3 checkboxes, but data claims appear grounded in real queries. Footer says "Phases: 11/14".

### Dimension 6 — Shape Fidelity (8/10)

Numbered sections 1-8 present. Tier legend in Section 4. Real SQL samples in Section 7 (3 queries). Footer has quality score and phases completed. Property table missing UC Target. Otherwise matches golden reference shape well.

---

## Weighted Score

```
weighted = 0.25*7 + 0.20*6 + 0.20*8 + 0.15*9 + 0.10*7 + 0.10*8
         = 1.75 + 1.20 + 1.60 + 1.35 + 0.70 + 0.80
         = 7.40
```

**7.40 < 7.5 → FAIL**

---

## Top 5 Issues

1. **HIGH — CIDViewed wrongly tagged Tier 1**: `CIDViewed` is attributed as `(Tier 1 — Fact_UserPageViews)` but `DWH_pagetracking.Fact_UserPageViews` has no wiki in the bundle. Tier 1 requires a documented upstream wiki to copy from verbatim. This should be Tier 3 (source identified, no upstream wiki).

2. **MEDIUM — UserPI paraphrases Dim_Customer.UserName**: The upstream wiki says "Unique (case-insensitive, enforced via UserName_LOWER computed column index)" but the wiki drops "enforced via UserName_LOWER computed column index". Tier 1 columns must be verbatim.

3. **MEDIUM — DateID tier inconsistency**: The lineage file says DateID is "Passthrough (filtered to @DateID)" from Fact_UserPageViews, yet the Elements table tags it Tier 2 — SP_MarketingCloudUserBehavior. Since Fact_UserPageViews has no wiki, Tier 3 would be more accurate than Tier 2 if it's a passthrough, or the lineage should clarify it as SP-derived from the @date parameter.

4. **LOW — Missing UC Target in property table**: The property table omits UC Target, which is part of the completeness checklist.

5. **LOW — Footer claims "4 T1" but CIDViewed's Tier 1 is invalid**: If CIDViewed is corrected to Tier 3, the count becomes 3 T1, 9 T2, 1 T3.

---

## Regeneration Feedback

1. Re-tag `CIDViewed` as `(Tier 3 — Fact_UserPageViews, no upstream wiki)` and update the description to be writer-authored without claiming verbatim inheritance.
2. Fix `UserPI` description to quote Dim_Customer.UserName verbatim: "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." — then append lineage context.
3. Resolve `DateID` tier: either tag as Tier 3 (passthrough from undocumented Fact_UserPageViews) or clarify in lineage that it's SP-derived from `CONVERT(VARCHAR(8), @date, 112)` for Tier 2.
4. Add UC Target row to the property table (or note "None / not exported to UC" if applicable).
5. Update footer tier breakdown to reflect corrected tier assignments.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_MarketingCloudUserBehaviorPI",
  "weighted_score": 7.40,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 6,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_UserPageViews.RealCID (renamed).",
      "match": "YES",
      "loss": "None — core text verbatim, lineage context appended"
    },
    {
      "column": "AccountId",
      "upstream_quote": "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced.",
      "wiki_quote": "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID.",
      "match": "YES",
      "loss": "None — core text verbatim, lineage context appended"
    },
    {
      "column": "CIDViewed",
      "upstream_quote": "No upstream wiki exists (Fact_UserPageViews is unresolved)",
      "wiki_quote": "Customer ID of the Popular Investor whose profile was viewed. FK to Dim_Customer.RealCID. Passthrough from Fact_UserPageViews.CIDViewed.",
      "match": "NO",
      "loss": "Wrongly tagged Tier 1 — Fact_UserPageViews has no wiki. Description is writer-authored, not inherited from any upstream wiki."
    },
    {
      "column": "UserPI",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer.UserName via JOIN on CIDViewed=RealCID. Represents the Popular Investor's display name.",
      "match": "MINOR",
      "loss": "Dropped 'enforced via UserName_LOWER computed column index' detail; added PI display name context not in upstream."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CIDViewed",
      "problem": "Tagged Tier 1 — Fact_UserPageViews but Fact_UserPageViews has no wiki in the bundle. Tier 1 requires verbatim copy from a documented upstream wiki. Should be Tier 3 (source identified, no upstream wiki available)."
    },
    {
      "severity": "medium",
      "column_or_section": "UserPI",
      "problem": "Paraphrases Dim_Customer.UserName description — drops 'enforced via UserName_LOWER computed column index' and adds 'Represents the Popular Investor's display name' which is not in the upstream wiki. Tier 1 columns must be verbatim."
    },
    {
      "severity": "medium",
      "column_or_section": "DateID",
      "problem": "Lineage file says 'Passthrough (filtered to @DateID)' from Fact_UserPageViews but Elements table tags it Tier 2 — SP_MarketingCloudUserBehavior. Inconsistent: if passthrough from undocumented source, should be Tier 3; if SP-derived from @date parameter, lineage should say so."
    },
    {
      "severity": "low",
      "column_or_section": "Property Table",
      "problem": "Missing UC Target row. Completeness checklist requires Production Source, Refresh, Distribution, and UC Target in the property table."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer claims '4 T1' but CIDViewed's Tier 1 attribution is invalid (no upstream wiki). Corrected count would be 3 T1, 9 T2, 1 T3."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag CIDViewed as Tier 3 (Fact_UserPageViews has no wiki — cannot be Tier 1). (2) Fix UserPI to quote Dim_Customer.UserName verbatim: include 'enforced via UserName_LOWER computed column index'. (3) Resolve DateID tier inconsistency between lineage (passthrough) and elements (Tier 2). (4) Add UC Target to property table. (5) Update footer tier breakdown to reflect corrected assignments.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
