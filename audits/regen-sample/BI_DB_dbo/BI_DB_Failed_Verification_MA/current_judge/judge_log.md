I need to verify the upstream wiki to confirm my analysis of the passthrough columns.
Now let me read the Elements section to get exact upstream descriptions for the passthrough columns.
Good. I now have all the verbatim upstream descriptions. Let me compile the full review.

---

## Adversarial Wiki Review: BI_DB_dbo.BI_DB_Failed_Verification_MA

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 1/10**
Sampled 5 columns: GCID, CountryName, CurrentRegulation, RejectionReasonPOA, EV_MatchStatus. All 5 are passthroughs from BI_DB_Operations_Onboarding_Flow_UserKPIs, whose wiki exists in the bundle. Per tier rules, all should be Tier 1 — but ALL are tagged Tier 2. 5/5 mismatches (base score 3), plus 5 paraphrasing failures on what should be Tier 1 columns (-10). Floor: 1.

**Dimension 2 — Upstream Fidelity: 1/10**
7 passthrough columns exist. Zero are tagged Tier 1. Zero use verbatim upstream descriptions. Every single one is paraphrased with semantic losses (NULL semantics changed, vendor names dropped, resolution paths removed). Additionally, 3 columns trace to root origins in the upstream wiki (GCID → Customer.CustomerStatic, CountryName → Dictionary.Country, CurrentRegulation → Dictionary.Regulation) but the writer attributed all to SP_Failed_Verification_MA — 3 missed inheritances (-6). Floor: 1.

**Dimension 3 — Completeness: 8/10**
9/10 checklist items pass. All 8 sections present, 10/10 elements match DDL, all rows have 5 cells, all have tier tags, property table complete, ETL diagram present, footer has tier breakdown, review-needed has no Section 4. Missing: no absolute date range in Section 1 (only "3-day window" described generically).

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent: names the domain (KYC/marketing automation), row grain (one GCID), ETL SP, refresh pattern, filter criteria, author, and row count. An analyst could immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 8/10**
Row count (~1,130), EV_MatchStatus distribution with percentages, ReasonNumber top values with percentages, filter condition constants documented. Footer claims 14/14 phases. Solid evidence of live data usage.

**Dimension 6 — Shape Fidelity: 8/10**
Correct numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: tier legend only lists Tier 2 and Tier 5 (no Tier 1/3/4), which is consistent with the (incorrect) tier assignments but deviates from the standard full legend.

---

### T1 Fidelity Table

The writer tagged **zero** columns as Tier 1. All 7 passthrough columns should be Tier 1. Below compares what the upstream wiki says vs. what the writer wrote:

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|---|---|---|---|---|
| GCID | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | "Global Customer ID — cross-platform identifier. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. FK to Dim_Customer." | NO | "Group" → "Global", "cross-product identity key" → "cross-platform identifier", NULL semantics dropped entirely, root origin (Customer.CustomerStatic) lost |
| CountryName | "Full country name in English. Unique per country." | "Customer's registered country name. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs." | NO | Complete rewrite; "Unique per country" dropped, root origin (Dictionary.Country) lost |
| CurrentRegulation | "Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration." | "Customer's current regulatory jurisdiction. Values: BVI, CySEC, FCA, ASIC, FSA Seychelles, eToroUS, FINRAONLY, etc. Passthrough from source." | NO | Resolution path dropped, DesignatedRegulation diff note dropped, root origin (Dictionary.Regulation) lost |
| RejectionReasonPOA | "Rejection reason text for the POA document. NULL if POA was approved or not submitted." | "Raw Proof of Address rejection reason text from source. NULL if only POI was rejected. Used as input to ReasonNumber/RejectReasonName mapping." | NO | NULL semantics changed ("approved or not submitted" → "only POI was rejected" — different meaning) |
| RejectionReasonPOI | "Rejection reason text for the POI document. NULL if POI was approved or not submitted." | "Raw Proof of Identity rejection reason text from source. NULL if only POA was rejected. Used as input to ReasonNumber/RejectReasonName mapping." | NO | NULL semantics changed ("approved or not submitted" → "only POA was rejected" — different meaning) |
| NonVerificationReason | "Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers." | "Reason for non-verification. Always 'Docs not Approved' in this table (filter condition)." | NO | All 6 CASE values dropped, "Only meaningful for VL2 customers" dropped |
| EV_MatchStatus | "Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus." | "Electronic verification match status. Never 'Verified' (filter condition). 4 values: blank (64%), NotVerified (27%), PartiallyVerified (9%), None (<1%)." | NO | Resolution source (Dim_EvMatchStatus) dropped, original value list replaced with filtered distribution |

---

### Top 5 Issues

1. **GCID** — Tagged `(Tier 2 — SP_Failed_Verification_MA)` but is a direct passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs where it is documented as `(Tier 1 — Customer.CustomerStatic)`. Description rewrites "Group" as "Global" and drops NULL semantics.

2. **CountryName** — Tagged Tier 2 but upstream documents it as `(Tier 1 — Dictionary.Country)`. Should inherit the root origin. Description is a complete rewrite losing "Unique per country".

3. **CurrentRegulation** — Tagged Tier 2 but upstream documents it as `(Tier 1 — Dictionary.Regulation)` with the resolution path `Dim_Customer.RegulationID -> Dim_Regulation.Name`. Wiki drops both the path and the important note that it may differ from DesignatedRegulation.

4. **RejectionReasonPOI / RejectionReasonPOA** — NULL semantics inverted. Upstream says NULL when "approved or not submitted"; wiki says NULL when "only POI/POA was rejected" — these are different conditions. A reader would misunderstand when NULLs appear.

5. **Tier Legend** — Section 4 legend only shows Tier 2 and Tier 5, reflecting the writer's (incorrect) belief that no Tier 1 columns exist. The footer reads "0 T1" which is factually wrong — 7 columns should be Tier 1.

---

### Regeneration Feedback

1. Re-tag all 7 passthrough columns (GCID, CountryName, CurrentRegulation, RejectionReasonPOA, RejectionReasonPOI, NonVerificationReason, EV_MatchStatus) as **Tier 1** with verbatim descriptions from the upstream BI_DB_Operations_Onboarding_Flow_UserKPIs wiki.
2. For GCID, CountryName, and CurrentRegulation, trace to the **root origin** declared in the upstream wiki: `Customer.CustomerStatic`, `Dictionary.Country`, `Dictionary.Regulation` respectively.
3. For RejectionReasonPOA/POI, fix the NULL semantics: upstream says "NULL if POA/POI was approved or not submitted", NOT "NULL if only POI/POA was rejected".
4. For NonVerificationReason, include the full CASE value list from the upstream wiki even though this table filters to only one value — the upstream description is the canonical reference.
5. Update the Tier Legend to include Tier 1 and update the footer tier counts (should be 7 T1, 2 T2, 1 T5).
6. Add a concrete date-range note in Section 1 (e.g., "data reflects the 3-day window ending on the most recent ETL run date").

---

**Weighted Score**: 0.25×1 + 0.20×1 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×8 = 0.25 + 0.20 + 1.60 + 1.35 + 0.80 + 0.80 = **5.00**

**Verdict: FAIL**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Failed_Verification_MA",
  "weighted_score": 5.0,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 1,
    "upstream_fidelity": 1,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "GCID",
      "upstream_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.",
      "wiki_quote": "Global Customer ID — cross-platform identifier. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. FK to Dim_Customer.",
      "match": "NO",
      "loss": "\"Group\" changed to \"Global\", \"cross-product identity key\" changed to \"cross-platform identifier\", NULL semantics dropped, root origin Customer.CustomerStatic lost"
    },
    {
      "column": "CountryName",
      "upstream_quote": "Full country name in English. Unique per country.",
      "wiki_quote": "Customer's registered country name. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs.",
      "match": "NO",
      "loss": "Complete rewrite; \"Unique per country\" dropped, root origin Dictionary.Country lost"
    },
    {
      "column": "CurrentRegulation",
      "upstream_quote": "Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration.",
      "wiki_quote": "Customer's current regulatory jurisdiction. Values: BVI, CySEC, FCA, ASIC, FSA Seychelles, eToroUS, FINRAONLY, etc. Passthrough from source.",
      "match": "NO",
      "loss": "Resolution path (Dim_Customer.RegulationID -> Dim_Regulation.Name) dropped, DesignatedRegulation diff note dropped, root origin Dictionary.Regulation lost"
    },
    {
      "column": "RejectionReasonPOA",
      "upstream_quote": "Rejection reason text for the POA document. NULL if POA was approved or not submitted.",
      "wiki_quote": "Raw Proof of Address rejection reason text from source. NULL if only POI was rejected. Used as input to ReasonNumber/RejectReasonName mapping.",
      "match": "NO",
      "loss": "NULL semantics inverted: upstream says NULL when 'approved or not submitted', wiki says NULL when 'only POI was rejected' — different conditions"
    },
    {
      "column": "RejectionReasonPOI",
      "upstream_quote": "Rejection reason text for the POI document. NULL if POI was approved or not submitted.",
      "wiki_quote": "Raw Proof of Identity rejection reason text from source. NULL if only POA was rejected. Used as input to ReasonNumber/RejectReasonName mapping.",
      "match": "NO",
      "loss": "NULL semantics inverted: upstream says NULL when 'approved or not submitted', wiki says NULL when 'only POA was rejected' — different conditions"
    },
    {
      "column": "NonVerificationReason",
      "upstream_quote": "Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers.",
      "wiki_quote": "Reason for non-verification. Always 'Docs not Approved' in this table (filter condition).",
      "match": "NO",
      "loss": "All 6 CASE values dropped, 'Only meaningful for VL2 customers' note dropped"
    },
    {
      "column": "EV_MatchStatus",
      "upstream_quote": "Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus.",
      "wiki_quote": "Electronic verification match status. Never 'Verified' (filter condition). 4 values: blank (64%), NotVerified (27%), PartiallyVerified (9%), None (<1%).",
      "match": "NO",
      "loss": "Resolution source (Dim_EvMatchStatus) dropped, canonical value list replaced with filtered distribution"
    }
  ],
  "issues": [
    {
      "severity": "critical",
      "column_or_section": "ALL passthrough columns (GCID, CountryName, CurrentRegulation, RejectionReasonPOA, RejectionReasonPOI, NonVerificationReason, EV_MatchStatus)",
      "problem": "All 7 passthrough columns tagged Tier 2 — SP_Failed_Verification_MA. Upstream wiki BI_DB_Operations_Onboarding_Flow_UserKPIs exists and was provided in the bundle. Per tier rules, all passthroughs with upstream wiki present must be Tier 1 with verbatim descriptions."
    },
    {
      "severity": "critical",
      "column_or_section": "GCID",
      "problem": "Tagged Tier 2 but upstream documents as Tier 1 — Customer.CustomerStatic. Description rewrites 'Group Customer ID' as 'Global Customer ID' and drops NULL semantics ('NULL for older accounts predating GCID introduction')."
    },
    {
      "severity": "critical",
      "column_or_section": "CountryName",
      "problem": "Tagged Tier 2 but upstream documents as Tier 1 — Dictionary.Country. Description is a complete rewrite: 'Full country name in English. Unique per country.' became 'Customer's registered country name.' Root origin Dictionary.Country lost."
    },
    {
      "severity": "critical",
      "column_or_section": "CurrentRegulation",
      "problem": "Tagged Tier 2 but upstream documents as Tier 1 — Dictionary.Regulation. Resolution path (Dim_Customer.RegulationID -> Dim_Regulation.Name) and the important note 'May differ from DesignatedRegulation if customer's regulation changed after registration' both dropped."
    },
    {
      "severity": "high",
      "column_or_section": "RejectionReasonPOI, RejectionReasonPOA",
      "problem": "NULL semantics inverted. Upstream: 'NULL if POI/POA was approved or not submitted'. Wiki: 'NULL if only POA/POI was rejected'. These describe different conditions — a reader would misunderstand when NULLs appear."
    },
    {
      "severity": "high",
      "column_or_section": "Section 4 — Tier Legend and Footer",
      "problem": "Tier legend only lists Tier 2 and Tier 5. Footer shows '0 T1' — should be 7 T1, 2 T2, 0 T3, 0 T4, 1 T5."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag all 7 passthrough columns (GCID, CountryName, CurrentRegulation, RejectionReasonPOA, RejectionReasonPOI, NonVerificationReason, EV_MatchStatus) as Tier 1 using VERBATIM descriptions from the upstream BI_DB_Operations_Onboarding_Flow_UserKPIs wiki. (2) For GCID use root origin Customer.CustomerStatic, for CountryName use Dictionary.Country, for CurrentRegulation use Dictionary.Regulation — these are the root origins declared in the upstream wiki. (3) Fix RejectionReasonPOA/POI NULL semantics: upstream says 'NULL if POA/POI was approved or not submitted', not 'NULL if only POI/POA was rejected'. (4) For NonVerificationReason, include the full CASE value list from upstream even though this table filters to one value. (5) Update Section 4 tier legend to include Tier 1 and fix footer tier counts to 7 T1, 2 T2, 0 T3, 0 T4, 1 T5. (6) Add concrete date context to Section 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "ReasonNumber: top values with percentages (11=31%, 10=21%, 8=13%)",
      "EV_MatchStatus: distribution with percentages (blank 64%, NotVerified 27%, PartiallyVerified 9%, None <1%)"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
