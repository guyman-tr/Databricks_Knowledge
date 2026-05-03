## Review Summary: Dealing_dbo.Dealing_NumberofPositionsOpened_Agg

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 3/10**
Sampled 5 columns: DateID, InstrumentType, Region, NumberOfPositionsOpened, UpdateDate. The first three are GROUP BY passthroughs from `Dealing_DealingDashboard_Clients` (upstream wiki exists in bundle) — they should be Tier 1, not Tier 2. Only NumberOfPositionsOpened (SUM aggregation → Tier 2) and UpdateDate (GETDATE() → Tier 2) are correctly tagged. 3 mismatches out of 5.

**Dimension 2 — Upstream Fidelity: 3/10**
The wiki claims 0 Tier 1 columns. Four columns (DateID, Date, InstrumentType, Region) are verbatim passthroughs from `Dealing_DealingDashboard_Clients`, whose wiki is present in the bundle. All four are missed inheritances — the writer should have quoted the upstream descriptions verbatim and tagged Tier 1. This is the "wrong tier origin" failure mode.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count matches DDL (6/6). Every element row has 5 cells with tier tags. Property table complete. ASCII pipeline diagram present. Footer has tier breakdown. Section 1 has row count (178,742) and date range (2022-01-01 to 2026-04-26). Dictionary columns list inline values (6 instrument types, 21 regions). Review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (dealing desk trend analysis), row grain (daily × instrument type × region), upstream table with row count (1.83B), ETL SP and pattern (DELETE + INSERT), own row count and date range, and explains what dimensions are collapsed.

**Dimension 5 — Data Evidence: 7/10**
Row count (178,742), date range, and specific enum values are present and appear grounded. No explicit Phase Gate P2/P3 checkboxes visible, but data claims look plausible. Footer says 11/14 phases.

**Dimension 6 — Shape Fidelity: 8/10**
All structural elements present: numbered sections, tier legend (though only Tier 2 shown), real SQL samples in Section 7, footer with quality score and phases. Minor: tier legend is incomplete since it only shows Tier 2 row.

### T1 Fidelity Table

The wiki claims **zero** Tier 1 columns. However, four columns SHOULD be Tier 1 (passthroughs from an upstream with a wiki in the bundle). This table documents what the upstream says vs. what the wiki says for those missed columns:

| Column | Upstream Quote (Dealing_DealingDashboard_Clients) | Wiki Quote | Match | Loss |
|--------|--------------------------------------------------|------------|-------|------|
| DateID | "Date as YYYYMMDD integer. (Tier 2 — SP_DealingDashboard_Clients)" | "Snapshot date as YYYYMMDD integer. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. Range: 20220101 to present. Clustered index column. (Tier 2 — Dealing_DealingDashboard_Clients)" | NO | Tier should be 1; description paraphrased ("Snapshot date" vs "Date as YYYYMMDD integer") |
| Date | "Reporting date. (Tier 2 — SP_DealingDashboard_Clients)" | "Reporting calendar date. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. (Tier 2 — Dealing_DealingDashboard_Clients)" | NO | Tier should be 1; "Reporting date" → "Reporting calendar date" (paraphrase) |
| InstrumentType | "Asset class from Dim_Instrument. (Tier 2 — SP_DealingDashboard_Clients)" | "Asset class label: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Instrument.InstrumentType..." | NO | Tier should be 1; heavily expanded from upstream's terse description |
| Region | "Client's geographic region. From Fact_SnapshotCustomer. (Tier 2 — SP_DealingDashboard_Clients)" | "Marketing region label. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Country.Region..." | NO | Tier should be 1; "Client's geographic region" → "Marketing region label" (semantic change); dropped "From Fact_SnapshotCustomer" |

### Top 5 Issues

1. **Severity: HIGH — All passthrough columns mistagged as Tier 2 instead of Tier 1**
   Columns: DateID, Date, InstrumentType, Region. These are GROUP BY passthroughs from `Dealing_DealingDashboard_Clients` whose wiki is in the bundle. Per tier rules, passthrough + upstream wiki = Tier 1.

2. **Severity: HIGH — Upstream descriptions paraphrased instead of quoted verbatim**
   Column: Region. Upstream says "Client's geographic region. From Fact_SnapshotCustomer." Wiki says "Marketing region label." This changes the semantic meaning — "geographic region" ≠ "marketing region" (the Dim_Country wiki explicitly warns these differ).

3. **Severity: MEDIUM — Tier legend only shows Tier 2**
   The Section 4 legend omits Tier 1, misleading readers into thinking no upstream documentation exists. The footer confirms "0 T1" which is factually wrong.

4. **Severity: MEDIUM — Region description cites wrong origin chain**
   Wiki says Region "originates from Dim_Country.Region (loaded from Dictionary.MarketingRegion.Name)" but the SP code shows Region comes from `#SnapshotCustomer` which gets it from `Fact_SnapshotCustomer` (which itself gets it from Dim_Country). The wiki skips the Fact_SnapshotCustomer relay and claims a Dim_Country origin, but the actual SELECT in SP_DealingDashboard_Clients is `b.Region` from `#SnapshotCustomer`. The upstream wiki for Dealing_DealingDashboard_Clients correctly says "From Fact_SnapshotCustomer."

5. **Severity: LOW — InstrumentType description embeds CASE mapping that belongs in Section 2**
   The element description for InstrumentType includes the full CASE mapping (1=Currencies, 2=Commodities, etc.) which duplicates Section 2.2. Element descriptions should be concise; detailed mappings belong in business logic.

### Regeneration Feedback

1. Re-tag DateID, Date, InstrumentType, and Region as Tier 1 from `Dealing_DealingDashboard_Clients`, quoting the upstream wiki descriptions verbatim.
2. For Region, use the upstream description exactly: "Client's geographic region. From Fact_SnapshotCustomer." Do not replace "geographic region" with "marketing region."
3. Update the Section 4 tier legend to include Tier 1 row.
4. Update footer tier counts to reflect 4 T1, 2 T2.
5. Move the InstrumentType CASE mapping detail out of the element description and into Section 2.2 only; keep element description concise.

---

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_NumberofPositionsOpened_Agg",
  "weighted_score": 6.20,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "DateID",
      "upstream_quote": "Date as YYYYMMDD integer. (Tier 2 — SP_DealingDashboard_Clients)",
      "wiki_quote": "Snapshot date as YYYYMMDD integer. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. Range: 20220101 to present. Clustered index column. (Tier 2 — Dealing_DealingDashboard_Clients)",
      "match": "NO",
      "loss": "Should be Tier 1; description paraphrased ('Date as YYYYMMDD integer' → 'Snapshot date as YYYYMMDD integer')"
    },
    {
      "column": "Date",
      "upstream_quote": "Reporting date. (Tier 2 — SP_DealingDashboard_Clients)",
      "wiki_quote": "Reporting calendar date. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. (Tier 2 — Dealing_DealingDashboard_Clients)",
      "match": "NO",
      "loss": "Should be Tier 1; 'Reporting date' paraphrased to 'Reporting calendar date'"
    },
    {
      "column": "InstrumentType",
      "upstream_quote": "Asset class from Dim_Instrument. (Tier 2 — SP_DealingDashboard_Clients)",
      "wiki_quote": "Asset class label: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Instrument.InstrumentType (CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies). (Tier 2 — Dim_Instrument)",
      "match": "NO",
      "loss": "Should be Tier 1; heavily expanded from upstream's terse 'Asset class from Dim_Instrument'; tier source changed from SP_DealingDashboard_Clients to Dim_Instrument"
    },
    {
      "column": "Region",
      "upstream_quote": "Client's geographic region. From Fact_SnapshotCustomer. (Tier 2 — SP_DealingDashboard_Clients)",
      "wiki_quote": "Marketing region label. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Country.Region (loaded from Dictionary.MarketingRegion.Name). 21 distinct values including USA, UK, Spain, ROW, ROE, Africa, etc. (Tier 2 — Dim_Country)",
      "match": "NO",
      "loss": "Should be Tier 1; semantic change: 'Client's geographic region' → 'Marketing region label'; dropped 'From Fact_SnapshotCustomer'; tier source changed from SP_DealingDashboard_Clients to Dim_Country"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "DateID, Date, InstrumentType, Region",
      "problem": "All four passthrough columns tagged Tier 2 but should be Tier 1 — upstream wiki for Dealing_DealingDashboard_Clients exists in the bundle and these are GROUP BY passthroughs with no transform."
    },
    {
      "severity": "high",
      "column_or_section": "Region",
      "problem": "Upstream description is 'Client's geographic region. From Fact_SnapshotCustomer.' but wiki says 'Marketing region label' — semantic change. Dim_Country wiki explicitly warns geographic region ≠ marketing region."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 — Tier Legend",
      "problem": "Tier legend only shows Tier 2 row, omitting Tier 1. Footer states '0 T1' which is incorrect — 4 columns should be Tier 1."
    },
    {
      "severity": "medium",
      "column_or_section": "InstrumentType, Region",
      "problem": "Tier source attribution changed from the direct upstream (SP_DealingDashboard_Clients) to deeper ancestors (Dim_Instrument, Dim_Country), bypassing the immediate source Dealing_DealingDashboard_Clients."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentType",
      "problem": "Element description embeds full CASE mapping (1=Currencies, 2=Commodities, etc.) duplicating Section 2.2 business logic. Element descriptions should be concise."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag DateID, Date, InstrumentType, Region as Tier 1 from Dealing_DealingDashboard_Clients, quoting upstream wiki descriptions verbatim. (2) For Region, use upstream text exactly: 'Client's geographic region. From Fact_SnapshotCustomer.' — do not substitute 'marketing region label'. (3) Update Section 4 tier legend to include Tier 1 row. (4) Update footer tier counts to 4 T1, 2 T2. (5) Keep InstrumentType element description concise; move CASE mapping to Section 2.2 only.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
