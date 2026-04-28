## Adversarial Review: BI_DB_dbo.BI_DB_CIDFunnelFlow

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
Sampled 5 columns: RealCID (Tier 2 — defensible as GROUP BY key, MATCH), V3 (Tier 2 — ETL CASE expression, MATCH), Country (should be Tier 1 from Dictionary.Country via Dim_Country.Name passthrough, tagged Tier 2 — MISMATCH), DesignatedRegulation (should be Tier 1 from Dictionary.Regulation via Dim_Regulation.Name passthrough, tagged Tier 2 — MISMATCH), UpdateDate (Tier 2 GETDATE(), MATCH). 2 mismatches of 5.

**Dimension 2 — Upstream Fidelity: 2/10**
The wiki claims **zero Tier 1 columns**. This is flatly wrong. Six columns are dim-lookup passthroughs from upstream wikis that document the source column as Tier 1: Country (Dim_Country.Name → Dictionary.Country), Funnel (Dim_Funnel.Name → Dictionary.Funnel), FunnelFrom (same), DesignatedRegulation (Dim_Regulation.Name → Dictionary.Regulation), Regulation (same), Platform (Dim_Platform.Platform → Dictionary.Platform). All six have their upstream descriptions completely rewritten rather than quoted verbatim. This is "wrong tier origin" (score 3 baseline) with 6 missed inheritances.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 37 elements match 37 DDL columns. Every element has 5 cells with tier tags. Property table complete. ETL diagram in 5.2 uses real names. Footer has tier breakdown. Section 1 has row count and date range. PEP lists inline values. Review-needed sidecar has no `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (customer acquisition funnel), row grain (1 per customer), ETL SP (SP_CIDFunnelFlow), refresh pattern (daily TRUNCATE+INSERT), row count (3,970,310), ReportDateID semantics, population filter. An analyst reading this would immediately know what the table contains and when to use it.

**Dimension 5 — Data Evidence: 9/10**
Row count (3,970,310), date range (2025-04-12 to 2026-04-12), specific enum distributions (Regulation: BVI 84%, Channel: Direct 57%), milestone percentages (EmailVerification 59.5%, FTD 8.6%), NULL rates (PEP NULL 66.9%). Footer claims "Phases: 16/16" and "Data Evidence: live."

**Dimension 6 — Shape Fidelity: 9/10**
Correct numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: tier legend uses a simplified 4-tier format rather than the 5-star golden reference, but structure is recognizable and complete.

---

### T1 Fidelity Table

These columns **should** be Tier 1 but are tagged Tier 2 with paraphrased descriptions:

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." (Dim_Country → Dictionary.Country) | "Customer's registered country name (e.g., 'Germany', 'United States', 'Brazil'). Resolved from Dim_Country.Name via CountryID." | NO | Dropped uniqueness, usage context; added fabricated examples; wrong tier origin (Tier 2 via Dim_Country instead of Tier 1 via Dictionary.Country) |
| Funnel | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." (Dim_Funnel → Dictionary.Funnel) | "Customer acquisition funnel name from Dim_Funnel (e.g., 'eToro Web', 'eToro App'). Resolved in the main INSERT SELECT via LEFT JOIN on FunnelFromID. Identical to FunnelFrom." | NO | Dropped marketing/BackOffice usage context; added fabricated examples; wrong tier origin |
| FunnelFrom | Same as Funnel upstream | "Funnel name pre-resolved in the #POP staging table (e.Name from Dim_Funnel). Identical to Funnel in value. Represents the acquisition funnel pathway the customer entered through." | NO | Completely rewritten; wrong tier origin |
| DesignatedRegulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation → Dictionary.Regulation) | "The regulation jurisdiction first assigned to the customer after registration, sourced from Fact_SnapshotCustomer RANK=1..." | NO | Upstream description entirely replaced with ETL-level explanation; wrong tier origin (Tier 2 via Fact_SnapshotCustomer/Dim_Regulation instead of Tier 1 via Dictionary.Regulation) |
| Regulation | Same as DesignatedRegulation upstream | "The customer's current regulation jurisdiction name at ETL run time. Resolved from Dim_Regulation DR2 on DC.RegulationID = DR2.ID." | NO | Same problem — upstream replaced with ETL mechanics |
| Platform | "Platform name label: 'Undefined', 'Web', 'IOS', 'Android'. Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name." (Dim_Platform → Dictionary.Platform) | "Device or platform type through which the customer registered (e.g., 'Web', 'iOS', 'Android'). Resolved from Dim_Platform via Dim_Funnel.PlatformID in the #POP staging table." | NO | Dropped 'Undefined' value, changed 'IOS' to 'iOS', dropped reporting dashboard usage note; wrong tier origin |

---

### Top 5 Issues

1. **[HIGH] All dim-lookup passthroughs misclassified as Tier 2 (Country, Funnel, FunnelFrom, DesignatedRegulation, Regulation, Platform)**: The SP performs `SELECT dim.Name` from 4 dimension tables whose upstream wikis document those columns as Tier 1 from production dictionaries. The writer tagged all 37 columns as Tier 2, achieving "0 T1" — a systematic failure to trace through dimension lookups to the root production source. Per the tier rules, `SELECT Dim_Country.Name` with no transform should be `(Tier 1 — Dictionary.Country)` with the verbatim upstream description.

2. **[HIGH] Zero verbatim upstream quotes in the entire wiki**: Despite the upstream bundle containing 13 documented wikis with explicit Tier 1 column descriptions, not a single Element description quotes the upstream verbatim. Every dim-lookup column has a rewritten description mixing ETL mechanics with paraphrased business meaning.

3. **[MEDIUM] Region tagged Tier 2 citing Dim_Country, but source attribution is incomplete**: Region in Dim_Country is itself Tier 2 (computed from MarketingRegion join). The wiki correctly tags it Tier 2 but cites `(Tier 2 — Dim_Country)` without noting the marketing region origin. Should read `(Tier 2 — Dim_Country, from Dictionary.MarketingRegion)`.

4. **[MEDIUM] PEP tagged Tier 2 but upstream Dim_ScreeningStatus.Name is Tier 3**: The Dim_ScreeningStatus wiki documents its Name column as `(Tier 3 - live data)` since no production wiki exists for ScreeningService.Dictionary.ScreeningStatus. The CIDFunnelFlow wiki tags PEP as `(Tier 2 — Dim_ScreeningStatus)`, inflating confidence.

5. **[LOW] DesignatedRegulation and Regulation descriptions conflate the column value (a dim name passthrough) with the ETL resolution logic**: The Element descriptions for these columns spend most of their text explaining the RANK=1 logic and DR2.ID join — which belongs in Business Logic (Section 2), not the Element description. The Element should carry the upstream description of what Dim_Regulation.Name represents.

---

### Regeneration Feedback

1. Re-tag Country as `(Tier 1 — Dictionary.Country)` and use verbatim from Dim_Country wiki: "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports."
2. Re-tag Funnel and FunnelFrom as `(Tier 1 — Dictionary.Funnel)` and use verbatim from Dim_Funnel wiki: "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics."
3. Re-tag DesignatedRegulation and Regulation as `(Tier 1 — Dictionary.Regulation)` and use verbatim from Dim_Regulation wiki: "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name."
4. Re-tag Platform as `(Tier 1 — Dictionary.Platform)` and use verbatim from Dim_Platform wiki: "Platform name label: 'Undefined', 'Web', 'IOS', 'Android'. Used in reporting dashboards and per-platform analytics."
5. Move ETL resolution details (RANK=1 logic, DR2.ID join, #POP staging) from Element descriptions to Section 2 Business Logic or Section 5 Lineage — Element descriptions should describe what the value means, not how it was computed.
6. Re-tag PEP as `(Tier 3 — Dim_ScreeningStatus, no production wiki)` to match the upstream tier.
7. Update footer tier counts to reflect the corrected breakdown (at least 6 T1, ~30 T2, 1 T3).

---

### Weighted Score Calculation

```
weighted = 0.25×5 + 0.20×2 + 0.20×10 + 0.15×9 + 0.10×9 + 0.10×9
         = 1.25 + 0.40 + 2.00 + 1.35 + 0.90 + 0.90
         = 6.80
```

**Verdict: FAIL** (6.80, threshold 7.5)

The wiki is structurally excellent — complete, well-organized, rich in business logic and data evidence. The single critical failure mode is systematic misclassification of dim-lookup passthroughs as Tier 2 with no verbatim upstream inheritance. Fixing the 6 Tier 1 columns with verbatim quotes would likely push this above the pass threshold.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CIDFunnelFlow",
  "weighted_score": 6.80,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 2,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki)",
      "wiki_quote": "Customer's registered country name (e.g., 'Germany', 'United States', 'Brazil'). Resolved from Dim_Country.Name via CountryID. (Tier 2 — Dim_Country)",
      "match": "NO",
      "loss": "Completely paraphrased. Dropped uniqueness note, UI/compliance usage context. Added fabricated examples. Wrong tier: should be Tier 1 — Dictionary.Country, not Tier 2 — Dim_Country."
    },
    {
      "column": "Funnel",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. (Tier 1 — Dictionary.Funnel)",
      "wiki_quote": "Customer acquisition funnel name from Dim_Funnel (e.g., 'eToro Web', 'eToro App'). Resolved in the main INSERT SELECT via LEFT JOIN on FunnelFromID. Identical to FunnelFrom — see Business Logic §2.6. (Tier 2 — Dim_Funnel)",
      "match": "NO",
      "loss": "Dropped marketing/BackOffice usage context. Added fabricated examples and ETL mechanics. Wrong tier origin."
    },
    {
      "column": "FunnelFrom",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. (Tier 1 — Dictionary.Funnel)",
      "wiki_quote": "Funnel name pre-resolved in the #POP staging table (e.Name from Dim_Funnel). Identical to Funnel in value — see Business Logic §2.6. Represents the acquisition funnel pathway the customer entered through. (Tier 2 — Dim_Funnel via #POP)",
      "match": "NO",
      "loss": "Completely rewritten with ETL-level explanation. Wrong tier origin."
    },
    {
      "column": "DesignatedRegulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "The regulation jurisdiction first assigned to the customer after registration, sourced from Fact_SnapshotCustomer RANK=1 (earliest snapshot with non-null DesignatedRegulationID on or after registration date). Resolved to Dim_Regulation.Name. Unlike Regulation, this reflects the original designated jurisdiction and does not change if the customer later migrates. (Tier 2 — Fact_SnapshotCustomer/Dim_Regulation)",
      "match": "NO",
      "loss": "Upstream description entirely replaced with ETL resolution logic. Wrong tier: should be Tier 1 — Dictionary.Regulation."
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "The customer's current regulation jurisdiction name at ETL run time. Resolved from Dim_Regulation DR2 on DC.RegulationID = DR2.ID. Note: join uses DR2.ID (not DR2.DWHRegulationID). Distribution: BVI 84.0%, eToroUS 6.2%, CySEC 5.5%, FCA 1.7%. (Tier 2 — Dim_Regulation via RegulationID)",
      "match": "NO",
      "loss": "Upstream description replaced with ETL join mechanics and distribution stats. Wrong tier origin."
    },
    {
      "column": "Platform",
      "upstream_quote": "Platform name label: 'Undefined', 'Web', 'IOS', 'Android'. Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name. (Tier 1 - upstream wiki, Dictionary.Platform)",
      "wiki_quote": "Device or platform type through which the customer registered (e.g., 'Web', 'iOS', 'Android'). Resolved from Dim_Platform via Dim_Funnel.PlatformID in the #POP staging table. (Tier 2 — Dim_Platform via #POP)",
      "match": "NO",
      "loss": "Dropped 'Undefined' value, changed 'IOS' to 'iOS', dropped reporting dashboard usage note. Wrong tier origin."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Country, Funnel, FunnelFrom, DesignatedRegulation, Regulation, Platform",
      "problem": "All 6 dim-lookup passthrough columns are tagged Tier 2 instead of Tier 1. The SP performs SELECT dim.Name with no transform from Dim_Country, Dim_Funnel, Dim_Regulation, and Dim_Platform — all of which document their Name/Platform columns as Tier 1 from production dictionaries. Per tier rules, these should be Tier 1 with the dim's root origin (e.g., Dictionary.Country), not Tier 2 via the SP or dim table."
    },
    {
      "severity": "high",
      "column_or_section": "Section 4 (all 6 should-be-T1 columns)",
      "problem": "Zero verbatim upstream quotes in the entire wiki. Despite 13 upstream wikis in the bundle with explicit Tier 1 descriptions, every dim-lookup column has a completely rewritten description mixing ETL mechanics with paraphrased meaning. Not a single character-level match."
    },
    {
      "severity": "medium",
      "column_or_section": "PEP",
      "problem": "Tagged Tier 2 (Dim_ScreeningStatus) but the upstream Dim_ScreeningStatus wiki documents its Name column as Tier 3 (live data inference, no production wiki exists). Tier confidence is inflated."
    },
    {
      "severity": "medium",
      "column_or_section": "DesignatedRegulation, Regulation (Element descriptions)",
      "problem": "Element descriptions contain ETL resolution logic (RANK=1, DR2.ID join) that belongs in Section 2 Business Logic or Section 5 Lineage. Element descriptions should describe what the value means to an analyst, not how the SP computes it."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer claims '0 T1, 37 T2' — should be at least 6 T1 after corrections. The self-reported quality score of 9.68/10 is inflated given the systematic tier misclassification."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag Country as (Tier 1 — Dictionary.Country) using verbatim: 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.' (2) Re-tag Funnel and FunnelFrom as (Tier 1 — Dictionary.Funnel) using verbatim: 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics.' (3) Re-tag DesignatedRegulation and Regulation as (Tier 1 — Dictionary.Regulation) using verbatim: 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.' (4) Re-tag Platform as (Tier 1 — Dictionary.Platform) using verbatim: 'Platform name label: Undefined, Web, IOS, Android. Used in reporting dashboards and per-platform analytics.' (5) Move ETL resolution details from Element descriptions to Section 2/5. (6) Re-tag PEP as (Tier 3 — Dim_ScreeningStatus, no production wiki). (7) Update footer tier counts.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 3,970,310 in Section 1 header",
      "Regulation distribution (BVI 84.0%, eToroUS 6.2%, CySEC 5.5%, FCA 1.7%) in Element 10",
      "Channel distribution (Direct 57.0%, SEM 16.2%, etc.) in Element 6",
      "Milestone percentages across 15+ elements (EmailVerification 59.5%, V1 52.3%, FTD 8.6%, etc.)"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
