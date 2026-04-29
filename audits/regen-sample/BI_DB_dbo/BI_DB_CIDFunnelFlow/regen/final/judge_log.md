## Adversarial Review: BI_DB_dbo.BI_DB_CIDFunnelFlow

### Per-Dimension Scores

**Tier Accuracy: 8/10** — 5 random columns checked (Region, State, Country, PEP, FunnelFrom). Zero tier mismatches. Region correctly traced to Dictionary.MarketingRegion; Country to Dictionary.Country; FunnelFrom to Dictionary.Funnel. State tagged Tier 2 due to conditional CountryID=219 logic — defensible. PEP promoted from Dim_ScreeningStatus Tier 3 to Tier 1 by citing root source — borderline but acceptable. Deduct 2 for FunnelFrom paraphrasing (dropped "campaign/channel/product" specificity from upstream).

**Upstream Fidelity: 5/10** — FunnelFrom is clearly paraphrased with semantic loss: upstream says "Describes the campaign/channel/product that drove registration" but wiki says "Describes the funnel the customer came from." Five other Tier 1 columns have MINOR formatting differences (adding "Passthrough from Dim_X", dropping irrelevant-to-this-table context) — acceptable. PEP's upstream dim wiki is Tier 3 (no root source wiki exists), so the writer created a richer description than the source provides — not a failure per se but not verbatim either.

**Completeness: 8/10** — 9 of 10 checklist items pass. All 8 sections present; 37/37 elements match DDL; every row has 5 cells with tier tags; property table complete; ASCII pipeline diagram present; footer has tier counts; Section 1 has row count and date range; review-needed has no Section 4 dump. Miss: Regulation/DesignatedRegulation have ≤15 dictionary values but no inline key=value enumeration.

**Business Meaning: 9/10** — Section 1 is specific and actionable. Names the domain (registration-to-conversion funnel), row grain (one customer), ETL SP (SP_CIDFunnelFlow), refresh pattern (TRUNCATE+INSERT daily), row count (4.24M), date range (2025-04-26 to 2026-04-26), and key data flows. A new analyst could immediately understand when and how to query this table.

**Data Evidence: 7/10** — Row count (4.24M) and date range cited in Section 1. PEP values and Platform values enumerated inline. 22 distinct Region values mentioned. Phase gate checklist not explicitly shown as P2/P3 checkboxes, but specific data claims suggest live queries were run. No distribution percentages for funnel flags.

**Shape Fidelity: 9/10** — Matches golden reference shape: numbered sections 1-8, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score and phases-completed list. Minor: no explicit Phase Gate Checklist section with `[x]` marks.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | YES | — |
| Region | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'South & Central America'=40, 'Africa'=38, 'ROW'=38, 'French'=23, etc.). Used for marketing campaign grouping." | "Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Used for marketing campaign grouping. Passthrough from Dim_Country." | MINOR | Dropped example distribution values |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country." | YES | — |
| Funnel | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | "Unique human-readable label for the registration funnel. Describes the campaign/channel/product that drove registration. Passthrough from Dim_Funnel.Name via FunnelFromID." | MINOR | Dropped "Used in marketing reports, BackOffice customer views, and attribution analytics" |
| DesignatedRegulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the customer's first designated regulatory jurisdiction, resolved from the earliest Fact_SnapshotCustomer record after registration where DesignatedRegulationID is not null. Passthrough from Dim_Regulation.Name. NULL if never assigned." | MINOR | Dropped "Used in V_Dim_Customer and analytics dashboards", added resolution context |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the customer's current regulatory jurisdiction. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID." | MINOR | Dropped "Used in V_Dim_Customer" |
| AffiliateID | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer." | YES | — |
| FunnelFrom | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | "Unique human-readable label for the source funnel variant. Describes the funnel the customer came from. Passthrough from Dim_Funnel.Name via Dim_Customer.FunnelFromID." | NO | Dropped "campaign/channel/product that drove registration" — replaced with generic "the funnel the customer came from". Lost specificity about what a funnel name describes. |
| Platform | "Platform name label: 'Undefined', 'Web', 'IOS', 'Android'. Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name." | "Platform name label: 'Undefined', 'Web', 'IOS', 'Android'. Resolved via Dim_Customer.FunnelFromID → Dim_Funnel.PlatformID → Dim_Platform.Platform." | MINOR | Dropped "Used in reporting dashboards and per-platform analytics" |
| PEP | "Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management." (Dim_ScreeningStatus Tier 3) | "AML/compliance screening outcome name. Values: 'NoMatch' (clean), 'PendingInvestigation', 'PEP'... Empty string when ScreeningStatusID has no match. Passthrough from Dim_ScreeningStatus.Name." | NO | Rewrote "Internal code name for the screening outcome" as "AML/compliance screening outcome name". Added value enumeration not present in upstream. Upstream is only Tier 3 — no root wiki exists. |

### Top 5 Issues

1. **HIGH — FunnelFrom paraphrased**: FunnelFrom (#12) description drops the upstream's specific "campaign/channel/product that drove registration" phrasing and replaces it with the generic "the funnel the customer came from." This is the clearest Tier 1 verbatim violation.

2. **MEDIUM — Funnel and FunnelFrom are identical columns**: Both Funnel (#8) and FunnelFrom (#12) resolve to `Dim_Funnel.Name` via `FunnelFromID`. The SP joins Dim_Funnel on the same key for both columns. The wiki describes them as if they serve different purposes, but they will always contain the same value. This should be called out in Section 3.4 Gotchas.

3. **MEDIUM — PEP tier promotion without root source wiki**: PEP (#21) is tagged Tier 1 — ScreeningService.Dictionary.ScreeningStatus, but Dim_ScreeningStatus's own wiki says Name is Tier 3 (no upstream wiki exists for ScreeningService.Dictionary.ScreeningStatus). The writer created a description richer than the source, which is good, but the Tier 1 tag implies verbatim inheritance from a documented source that doesn't exist.

4. **LOW — Regulation values not enumerated inline**: Regulation (#10) and DesignatedRegulation (#9) have ≤15 possible values (15 per Dim_Regulation), but the wiki doesn't list them inline with key=value pairs. Dim_Regulation wiki documents: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. These should appear in the Elements descriptions.

5. **LOW — No explicit Phase Gate Checklist**: The footer mentions "Phases: 12/14" but there's no structured Phase Gate Checklist with `[x]` / `[ ]` marks showing which data validation phases were completed. This makes it harder to verify whether data claims were grounded in live queries.

### Regeneration Feedback

1. Replace FunnelFrom (#12) description with verbatim upstream: "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Passthrough from Dim_Funnel.Name via Dim_Customer.FunnelFromID."
2. Add a Gotcha noting Funnel and FunnelFrom are identical (both resolve to Dim_Funnel.Name via FunnelFromID).
3. Either downgrade PEP to Tier 2 (dim-lookup from Tier 3 upstream) or keep Tier 1 but note the root source has no documented wiki.
4. Add inline value enumeration for Regulation and DesignatedRegulation (0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, etc.).
5. Add explicit Phase Gate Checklist with P2/P3 completion markers.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CIDFunnelFlow",
  "weighted_score": 7.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 5,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Region",
      "upstream_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., \"South & Central America\"=40, \"Africa\"=38, \"ROW\"=38, \"French\"=23, etc.). Used for marketing campaign grouping.",
      "wiki_quote": "Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Used for marketing campaign grouping. Passthrough from Dim_Country.",
      "match": "MINOR",
      "loss": "Dropped example distribution values"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Funnel",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Unique human-readable label for the registration funnel. Describes the campaign/channel/product that drove registration. Passthrough from Dim_Funnel.Name via FunnelFromID.",
      "match": "MINOR",
      "loss": "Dropped 'Used in marketing reports, BackOffice customer views, and attribution analytics'"
    },
    {
      "column": "DesignatedRegulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the customer's first designated regulatory jurisdiction, resolved from the earliest Fact_SnapshotCustomer record after registration where DesignatedRegulationID is not null. Passthrough from Dim_Regulation.Name. NULL if never assigned.",
      "match": "MINOR",
      "loss": "Dropped 'Used in V_Dim_Customer and analytics dashboards'; added resolution context"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the customer's current regulatory jurisdiction. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID.",
      "match": "MINOR",
      "loss": "Dropped 'Used in V_Dim_Customer and analytics dashboards'"
    },
    {
      "column": "AffiliateID",
      "upstream_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.",
      "wiki_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FunnelFrom",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Unique human-readable label for the source funnel variant. Describes the funnel the customer came from. Passthrough from Dim_Funnel.Name via Dim_Customer.FunnelFromID.",
      "match": "NO",
      "loss": "Dropped 'campaign/channel/product that drove registration' — replaced with generic 'the funnel the customer came from'. Lost specificity about what a funnel name describes. Also dropped 'Used in marketing reports, BackOffice customer views, and attribution analytics'."
    },
    {
      "column": "Platform",
      "upstream_quote": "Platform name label: \"Undefined\", \"Web\", \"IOS\", \"Android\". Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name.",
      "wiki_quote": "Platform name label: \"Undefined\", \"Web\", \"IOS\", \"Android\". Resolved via Dim_Customer.FunnelFromID → Dim_Funnel.PlatformID → Dim_Platform.Platform.",
      "match": "MINOR",
      "loss": "Dropped 'Used in reporting dashboards and per-platform analytics'"
    },
    {
      "column": "PEP",
      "upstream_quote": "Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. (Tier 3 in Dim_ScreeningStatus)",
      "wiki_quote": "AML/compliance screening outcome name. Values: 'NoMatch' (clean), 'PendingInvestigation', 'PEP' (Politically Exposed Person), 'RiskMatch', 'SanctionsMatch', 'Unknown', 'Technical', 'MultipleMatch'. Empty string when ScreeningStatusID has no match. Passthrough from Dim_ScreeningStatus.Name.",
      "match": "NO",
      "loss": "Rewrote 'Internal code name for the screening outcome' as 'AML/compliance screening outcome name'. Added value enumeration not in upstream. Upstream is only Tier 3 — no root source wiki exists to quote verbatim."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "FunnelFrom (#12)",
      "problem": "Tier 1 paraphrase: upstream Dim_Funnel.Name says 'Describes the campaign/channel/product that drove registration' but wiki says 'Describes the funnel the customer came from'. Lost specificity about what a funnel name actually describes."
    },
    {
      "severity": "medium",
      "column_or_section": "Funnel (#8) and FunnelFrom (#12)",
      "problem": "Both columns resolve to Dim_Funnel.Name via FunnelFromID — they are identical in the SP. The wiki gives them different descriptions as if they serve different purposes, and does not flag this duplication in Gotchas."
    },
    {
      "severity": "medium",
      "column_or_section": "PEP (#21)",
      "problem": "Tagged Tier 1 — ScreeningService.Dictionary.ScreeningStatus, but Dim_ScreeningStatus's own wiki tags Name as Tier 3 (no upstream wiki exists for the root source). The Tier 1 tag implies verbatim inheritance from a documented source that does not exist."
    },
    {
      "severity": "low",
      "column_or_section": "Regulation (#10), DesignatedRegulation (#9)",
      "problem": "Dictionary columns with ≤15 values (15 regulations per Dim_Regulation) but no inline key=value enumeration. Should list: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, etc."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist with [x]/[ ] marks for P2 (row count) and P3 (distribution analysis). Footer says 'Phases: 12/14' but does not enumerate which phases were completed vs skipped."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace FunnelFrom description with verbatim upstream: 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.' (2) Add Gotcha: Funnel and FunnelFrom are identical — both resolve to Dim_Funnel.Name via FunnelFromID. (3) Downgrade PEP to Tier 2 or add explicit note that root source (ScreeningService.Dictionary.ScreeningStatus) has no documented wiki. (4) Add inline value enumeration for Regulation and DesignatedRegulation. (5) Add Phase Gate Checklist section with explicit P2/P3 completion markers.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 4.24M rows, date range 2025-04-26 to 2026-04-26",
      "Region: 22 distinct values",
      "PEP: 8 named values"
    ],
    "skipped_phases": [
      "P10 Atlassian skipped",
      "P16 deferred"
    ]
  }
}
</JUDGE_VERDICT>
