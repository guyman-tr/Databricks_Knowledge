Let me start by reading the SP source code and verifying the upstream wiki descriptions.
Now I have all the information needed. Let me verify the SP source against the wiki's claims, then produce the full review.

**SP verification confirms:**
- Lines 33-54: Exactly 22 hardcoded rejection reason codes — matches wiki
- Lines 63-65: COALESCE logic for ReasonNumber and RejectReasonName — matches wiki
- Lines 66-72: Passthrough columns (CountryName, CurrentRegulation, RejectionReasonPOA, RejectionReasonPOI, NonVerificationReason, EV_MatchStatus) + GETDATE() for UpdateDate — matches wiki
- Lines 76-82: WHERE filters — matches wiki Section 2.2
- Line 5: `@Date [date]` parameter declared but never used — matches wiki gotcha
- Line 59: TRUNCATE before INSERT — matches wiki

---

## Adversarial Judge Review: BI_DB_dbo.BI_DB_Failed_Verification_MA

### Dimension 1 — Tier Accuracy: **10/10**

Five sampled columns:

| Column | Claimed Tier | SP Evidence | Verdict |
|--------|-------------|-------------|---------|
| GCID | Tier 1 — Customer.CustomerStatic | Passthrough (line 63), upstream wiki element #2 confirms origin | Correct |
| CountryName | Tier 1 — Dictionary.Country | Passthrough (line 66), upstream wiki element #6 confirms root origin | Correct |
| ReasonNumber | Tier 2 — SP_Failed_Verification_MA | COALESCE(trr.ReasonNumber, trr1.ReasonNumber, 0) — computed in SP | Correct |
| NonVerificationReason | Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs | Passthrough (line 70), upstream wiki present with description | Correct |
| EV_MatchStatus | Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs | Passthrough (line 71), upstream wiki present with description | Correct |

0 mismatches. No paraphrasing failures detected on sampled Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **9/10**

All 7 Tier 1 columns carry verbatim upstream text with additive DWH notes. No semantic loss, no dropped vendor names, no paraphrased NULL semantics. Minor formatting additions ("Passthrough from...", "DWH note: in this table...") are enrichments, not losses.

One gap: GCID inherits "NULL for older accounts predating GCID introduction" verbatim from upstream, but the DDL defines GCID as NOT NULL. The writer added DWH notes for NonVerificationReason and EV_MatchStatus but omitted one for GCID. This inconsistency doesn't constitute semantic loss (the upstream text IS verbatim) but is a missed opportunity.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| GCID | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | MINOR | Added passthrough note; missing DWH note about DDL NOT NULL constraint |
| CountryName | "Full country name in English. Unique per country." | "Full country name in English. Unique per country. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | MINOR | Added passthrough note only |
| CurrentRegulation | "Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration." | "Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | MINOR | Added passthrough note only |
| RejectionReasonPOA | "Rejection reason text for the POA document. NULL if POA was approved or not submitted." | "Rejection reason text for the POA document. NULL if POA was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | YES | — |
| RejectionReasonPOI | "Rejection reason text for the POI document. NULL if POI was approved or not submitted." | "Rejection reason text for the POI document. NULL if POI was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | YES | — |
| NonVerificationReason | "Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers." | "Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers. DWH note: in this table, always 'Docs not Approved' due to WHERE filter. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | MINOR | Added DWH note (enrichment, no loss) |
| EV_MatchStatus | "Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus." | "Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus. DWH note: in this table, 'Verified' is excluded by the WHERE filter; observed values are empty/NULL, NotVerified, PartiallyVerified. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | MINOR | Added DWH note (enrichment, no loss) |

### Dimension 3 — Completeness: **8/10**

Checklist:
- [x] All 8 sections present
- [x] Element count matches DDL (10/10)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [ ] Section 1 contains date range — row count present (1,039), but no explicit date range (the 3-day rolling window is described conceptually, not with actual dates)
- [x] Dictionary columns with ≤15 values listed inline
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

9/10 checks → score 8.

### Dimension 4 — Business Meaning: **10/10**

Section 1 is outstanding. It names the domain (marketing automation for document verification failures), specifies the row grain (one customer per GCID with noted near-uniqueness), names the ETL SP, states the refresh pattern (daily TRUNCATE+INSERT, 3-day lookback), provides a row count (1,039), and includes regulation distribution. A new analyst would immediately understand when and why to query this table.

### Dimension 5 — Data Evidence: **8/10**

Strong data evidence throughout:
- Row count: 1,039 rows, 1,034 distinct GCIDs
- Regulation distribution with exact counts (BVI 881, FSA Seychelles 56, etc.)
- EV_MatchStatus distribution with percentages (NULL 71%, NotVerified 20%, PartiallyVerified 9%)
- ReasonNumber=0 count: 96 rows (9.2%)

No explicit Phase Gate Checklist section with `[x]` marks. Footer says "Phases: 11/14" but doesn't enumerate P2/P3 status. Data claims appear genuine based on specificity.

### Dimension 6 — Shape Fidelity: **9/10**

Follows the golden shape closely: numbered sections, tier legend in Section 4, real SQL samples in Section 7 (three queries, all plausible), footer with tier breakdown and phases count. Minor deviation: no explicit Phase Gate Checklist section, and "Quality: pending judge" placeholder rather than a self-assessed score.

### Weighted Total

```
weighted = 0.25*10 + 0.20*9 + 0.20*8 + 0.15*10 + 0.10*8 + 0.10*9
         = 2.50 + 1.80 + 1.60 + 1.50 + 0.80 + 0.90
         = 9.10
```

### Top 5 Issues

1. **GCID NOT NULL vs upstream "NULL for older accounts"** (medium): GCID element description inherits "NULL for older accounts predating GCID introduction" verbatim from upstream, but DDL declares GCID as NOT NULL. Writer added DWH notes for NonVerificationReason and EV_MatchStatus but missed this contradiction. Should add a DWH note.

2. **No explicit date range in Section 1** (low): The 3-day rolling window is described conceptually but no concrete date range is stated (e.g., "covering April 24-27, 2026"). Minor given the table's nature.

3. **No Phase Gate Checklist section** (low): Footer says "Phases: 11/14" but there's no explicit checklist with `[x]` marks for P2/P3. Data claims appear genuine but the audit trail is missing.

4. **Section 8 empty** (low): "No Jira or Confluence sources searched (regen harness mode)" — honest but means no external knowledge was consulted for business context validation.

5. **@Date parameter gotcha could be stronger** (low): The gotcha correctly notes the unused parameter, but doesn't flag the implication: if an orchestrator passes a date expecting historical replay, the SP silently ignores it and always uses GETDATE().

### Regeneration Feedback

This wiki does not require regeneration (PASS). If polishing:
1. Add a DWH note to GCID: "DWH note: DDL defines GCID as NOT NULL; the upstream NULL scenario may not apply in this table due to the VL2/3-day-recency filters."
2. Add a concrete date range note in Section 1 (e.g., "data covers the 3-day window ending at the last SP execution date").
3. Strengthen the @Date parameter gotcha to explicitly note silent-ignore risk for batch orchestrators.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Failed_Verification_MA",
  "weighted_score": 9.10,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "GCID",
      "upstream_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.",
      "wiki_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "MINOR",
      "loss": "Added passthrough note; missing DWH note about DDL NOT NULL constraint contradicting upstream NULL semantics"
    },
    {
      "column": "CountryName",
      "upstream_quote": "Full country name in English. Unique per country.",
      "wiki_quote": "Full country name in English. Unique per country. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "MINOR",
      "loss": "Added passthrough note only"
    },
    {
      "column": "CurrentRegulation",
      "upstream_quote": "Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration.",
      "wiki_quote": "Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "MINOR",
      "loss": "Added passthrough note only"
    },
    {
      "column": "RejectionReasonPOA",
      "upstream_quote": "Rejection reason text for the POA document. NULL if POA was approved or not submitted.",
      "wiki_quote": "Rejection reason text for the POA document. NULL if POA was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RejectionReasonPOI",
      "upstream_quote": "Rejection reason text for the POI document. NULL if POI was approved or not submitted.",
      "wiki_quote": "Rejection reason text for the POI document. NULL if POI was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "NonVerificationReason",
      "upstream_quote": "Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers.",
      "wiki_quote": "Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers. DWH note: in this table, always 'Docs not Approved' due to WHERE filter. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "MINOR",
      "loss": "Added DWH note (enrichment, no semantic loss)"
    },
    {
      "column": "EV_MatchStatus",
      "upstream_quote": "Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus.",
      "wiki_quote": "Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus. DWH note: in this table, 'Verified' is excluded by the WHERE filter; observed values are empty/NULL, NotVerified, PartiallyVerified. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "MINOR",
      "loss": "Added DWH note (enrichment, no semantic loss)"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "GCID",
      "problem": "DDL defines GCID as NOT NULL but the inherited upstream description states 'NULL for older accounts predating GCID introduction'. Writer added DWH notes for NonVerificationReason and EV_MatchStatus but omitted one for this DDL/description contradiction. Should add a DWH note explaining the NOT NULL constraint."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "No explicit date range stated. The 3-day rolling window is described conceptually but no concrete date bounds are given (e.g., 'covering the 3-day window ending at last SP execution')."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section with [x] marks for P2/P3. Footer says 'Phases: 11/14' but doesn't enumerate which phases were completed. Data evidence appears genuine but the audit trail is incomplete."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "No Jira or Confluence sources searched due to regen harness mode. Business context validation relies entirely on SP code and upstream wiki."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 (@Date parameter)",
      "problem": "Gotcha correctly notes the unused @Date parameter but doesn't flag the implication: if an orchestrator passes a date expecting historical replay, the SP silently ignores it and always uses GETDATE()."
    }
  ],
  "regeneration_feedback": "No regeneration required (PASS at 9.10). Optional polish: (1) Add DWH note to GCID element about DDL NOT NULL constraint. (2) Add concrete date range note in Section 1. (3) Strengthen @Date parameter gotcha to note silent-ignore risk for orchestrators.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
