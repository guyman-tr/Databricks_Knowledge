## Judge Review: BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (CID, Regulation, Club, Manager, Desk). All tier assignments are correct. Dim-lookup columns correctly trace to root origins (Dictionary.Regulation, Dictionary.PlayerLevel, etc.) rather than stopping at the intermediate dim. Manager correctly tagged Tier 2 since BI_DB_CIDFirstDates computes it via concatenation. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10**
Most Tier 1 columns are verbatim or verbatim-plus-context. NegativeMarket was fully rewritten rather than quoting the upstream BlockReasonDesc description verbatim — however the rewrite adds filter specificity (BlockReasonID=12, Failed) that makes the description *more* accurate for this table. PlayerStatus dropped the trailing-spaces RTRIM note. Appropriateness_Status dropped upstream percentage distributions. No vendor names or FK targets were lost.

**Dimension 3 — Completeness: 8/10**
All 8 sections present. 52 elements match 52 DDL columns. All element rows have 5 cells with tier tags. Property table complete. ETL pipeline diagram with real names. Footer has tier breakdown. Section 1 notes 0 rows (table empty). Review-needed sidecar clean (no Section 4). One minor gap: not all enum-like columns enumerate their values (e.g. PlayerStatus values not listed inline).

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent — names the FCA CDIM programme, specifies row grain (one per qualifying customer), lists all 6 population filter criteria with exact IDs, groups the 51 columns into 5 logical categories, names the ETL SP, states TRUNCATE+INSERT pattern, identifies the consumer (complianceuk@etoro.com). Only missing a date range (justifiably, since table is empty).

**Dimension 5 — Data Evidence: 4/10**
Table returned 0 rows. P3 (distribution analysis) was skipped — legitimately, as there was no data. No row counts, date ranges, or distribution percentages from live data. Enum values for Appropriateness_Status come from the upstream wiki, not live sampling. The writer was transparent about the empty state.

**Dimension 6 — Shape Fidelity: 9/10**
All structural elements present: numbered sections, tier legend, real SQL in Section 7, property table, ASCII pipeline diagram, footer with quality score and phases-completed list. Minor: tier legend uses a 3-tier table instead of the 5-tier golden reference.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID." | YES | — |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Always 'FCA' in this table..." | YES | — |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Excludes Blocked (2) and Blocked Upon Request (4) in this table." | MINOR | Dropped trailing-spaces RTRIM note |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID." | YES | — |
| Desk | "Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join...Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region." | "Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region." | YES | — |
| MifidCategorisation | "Human-readable classification label. Used in compliance dashboards and regulatory reports." | "Human-readable MiFID II classification label. Used in compliance dashboards and regulatory reports." | MINOR | Added "MiFID II" qualifier (enhancement, not loss) |
| CountryOfResidence | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | YES | — |
| BirthDate | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification." | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification." | YES | — |
| Appropriateness_Status | "Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: 'Failed' 75% (13.4M), 'Passed' 24% (4.2M), blank 1%, 'Borderline Pass' <0.1%." | "Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: 'Failed', 'Passed', blank, 'Borderline Pass'." | MINOR | Dropped percentage breakdowns from upstream |
| IsTradedDemo | "Whether the user has traded on demo. 1 = traded, 0 = registered but never traded. Currently all rows are 1 (only traded users are present)." | "Whether the user has traded on demo. 1=traded, 0=registered but never traded. Passthrough from BI_DB_Demo_CID_Panel." | MINOR | Dropped note that all source rows currently have value=1 |
| NegativeMarket | "Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not blocked." | "Block reason description for customers blocked from CFD trading due to failing the appropriateness test. From BI_DB_Scored_Appropriateness_Negative_Market.BlockReasonDesc WHERE BlockReasonID=12 AND RestrictionStatusDesc='Failed'. NULL if not blocked for this specific reason." | NO | Rewrote description entirely; upstream generic text replaced with filter-specific text. More informative but not verbatim. |

### Top 5 Issues

1. **NegativeMarket (col #45) — Tier 1 description not verbatim.** The upstream BlockReasonDesc description was completely rewritten. While the wiki's version is more accurate for this filtered usage, the rubric requires verbatim inheritance for Tier 1.

2. **Empty table — no data evidence.** P3 skipped due to 0 rows. All distribution claims (Appropriateness_Status values, expected population sizes) are sourced from upstream wikis or estimates, not live data. When the table is populated, distributions should be verified.

3. **PlayerStatus trailing-spaces note dropped.** Dim_PlayerStatus wiki warns about trailing spaces requiring RTRIM(). This operational gotcha was not inherited into the CDIM wiki description.

4. **Appropriateness_Status percentage distributions dropped.** The upstream wiki provides concrete distribution data (75% Failed, 24% Passed, etc.) that was simplified to just listing the value names.

5. **Section 4 — KYC columns placed in "4.2 KYC Questionnaire Answers" subsection but Appropriateness_Status (#18), AVG_CFD_Leverage (#19), IsTradedDemo (#20), UsedDemoBeforeLivePlatform (#21) are mixed into that section.** These non-KYC columns are grouped under the KYC heading, which is a minor organizational issue.

### Regeneration Feedback

1. Quote NegativeMarket's upstream description verbatim from BI_DB_Scored_Appropriateness_Negative_Market.BlockReasonDesc, then append the filter context (BlockReasonID=12, Failed) as additional SP-level context.
2. Restore the trailing-spaces RTRIM() note from Dim_PlayerStatus upstream wiki into the PlayerStatus description.
3. Restore percentage distributions for Appropriateness_Status from the upstream wiki (75% Failed, 24% Passed, etc.) — note these are source-table-level percentages that may differ in this FCA-filtered table.
4. When the table is populated, re-run with P3 enabled to add live row count, date range, and distribution analysis to Section 1.
5. Move Appropriateness_Status, AVG_CFD_Leverage, IsTradedDemo, and UsedDemoBeforeLivePlatform out of the "KYC Questionnaire Answers" subsection into their own subsections.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_M_Compliance_CDIM_Report",
  "weighted_score": 8.15,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 4,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Always 'FCA' in this table (filtered to DWHRegulationID=2). Dim-lookup from Dim_Regulation.Name.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Excludes Blocked (2) and Blocked Upon Request (4) in this table. Dim-lookup from Dim_PlayerStatus.Name.",
      "match": "MINOR",
      "loss": "Dropped trailing-spaces RTRIM() operational note from upstream"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Desk",
      "upstream_quote": "Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region.",
      "wiki_quote": "Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region. Dim-lookup from Dim_Country.Desk via CountryID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "MifidCategorisation",
      "upstream_quote": "Human-readable classification label. Used in compliance dashboards and regulatory reports.",
      "wiki_quote": "Human-readable MiFID II classification label. Used in compliance dashboards and regulatory reports. Dim-lookup from Dim_MifidCategorization.Name via MifidCategorizationID.",
      "match": "MINOR",
      "loss": "Added 'MiFID II' qualifier not present in upstream (enhancement, not semantic loss)"
    },
    {
      "column": "CountryOfResidence",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup from Dim_Country.Name via CountryID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "BirthDate",
      "upstream_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.",
      "wiki_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Appropriateness_Status",
      "upstream_quote": "Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: 'Failed' 75% (13.4M), 'Passed' 24% (4.2M), blank 1%, 'Borderline Pass' <0.1%. Note: column name contains typo.",
      "wiki_quote": "Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: 'Failed', 'Passed', blank, 'Borderline Pass'. Passthrough from BI_DB_Scored_Appropriateness_Negative_Market.ApproprietnessScore_Status (renamed).",
      "match": "MINOR",
      "loss": "Dropped percentage breakdowns (75%/24%/1%/<0.1%) and typo note from upstream"
    },
    {
      "column": "IsTradedDemo",
      "upstream_quote": "Whether the user has traded on demo. 1 = traded, 0 = registered but never traded. Currently all rows are 1 (only traded users are present).",
      "wiki_quote": "Whether the user has traded on demo. 1=traded, 0=registered but never traded. Passthrough from BI_DB_Demo_CID_Panel.",
      "match": "MINOR",
      "loss": "Dropped note that all source rows currently have value=1"
    },
    {
      "column": "NegativeMarket",
      "upstream_quote": "Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not blocked.",
      "wiki_quote": "Block reason description for customers blocked from CFD trading due to failing the appropriateness test. From BI_DB_Scored_Appropriateness_Negative_Market.BlockReasonDesc WHERE BlockReasonID=12 AND RestrictionStatusDesc='Failed'. NULL if not blocked for this specific reason.",
      "match": "NO",
      "loss": "Completely rewritten — upstream generic description replaced with filter-specific description. More informative but not verbatim."
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "NegativeMarket",
      "problem": "Tier 1 description is fully rewritten rather than quoting upstream BlockReasonDesc verbatim. Upstream: 'Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not blocked.' Wiki: entirely new text. Verbatim quote should come first, filter context appended."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1 / Data Evidence",
      "problem": "Table returned 0 rows. P3 (distribution analysis) skipped. No live data evidence for any column distributions. When table is populated, Section 1 needs row count, date range, and distribution analysis re-run."
    },
    {
      "severity": "low",
      "column_or_section": "PlayerStatus",
      "problem": "Dropped upstream Dim_PlayerStatus note about trailing spaces requiring RTRIM() for string comparisons. This is a practical gotcha that analysts need."
    },
    {
      "severity": "low",
      "column_or_section": "Appropriateness_Status",
      "problem": "Dropped upstream percentage distributions (Failed 75%, Passed 24%, blank 1%, Borderline Pass <0.1%). These provide useful context even if they represent source-table-level rates."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4.2",
      "problem": "Non-KYC columns (Appropriateness_Status #18, AVG_CFD_Leverage #19, IsTradedDemo #20, UsedDemoBeforeLivePlatform #21) are placed under the 'KYC Questionnaire Answers' subsection heading, which is misleading."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Quote NegativeMarket upstream BlockReasonDesc description verbatim, then append BlockReasonID=12/Failed filter context. (2) Restore RTRIM trailing-spaces note in PlayerStatus description. (3) Restore percentage distributions for Appropriateness_Status from upstream. (4) When table is populated, re-run P3 for live row count, date range, and distributions. (5) Move Appropriateness_Status, AVG_CFD_Leverage, IsTradedDemo, UsedDemoBeforeLivePlatform out of the KYC subsection.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3 — empty table", "P7 — no views", "P10 — regen harness"]
  }
}
</JUDGE_VERDICT>
