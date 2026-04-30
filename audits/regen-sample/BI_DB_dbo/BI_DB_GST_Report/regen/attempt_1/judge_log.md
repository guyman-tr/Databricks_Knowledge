## Judge Review: BI_DB_dbo.BI_DB_GST_Report

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 8/10**
Sampled 5 columns (RealCID, Regulation, Club, OvernightFee, Entity). All tier assignments are correct: RealCID/Regulation/Club correctly tagged Tier 1, OvernightFee/Entity correctly tagged Tier 2. Dim-lookup columns (Regulation, Club) correctly trace to the dim's origin (Dictionary.Regulation, Dictionary.PlayerLevel) rather than the intermediate dim table. Deduct 2 for paraphrasing on Club (dropped "Internal, N/A" values and upstream usage context).

**Dimension 2 — Upstream Fidelity: 5/10**
Only 3 Tier 1 columns exist. Club is clearly paraphrased — the upstream says "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." but the wiki rewrites it entirely. RealCID drops "Hash distribution key", "FK to Dim_Customer (if exists)", and "46.4M distinct values" from the upstream — though some of these are FSC-specific context, the verbatim standard is not met. Regulation is the closest to verbatim, with minor additions.

**Dimension 3 — Completeness: 8/10 (9 checks passed)**
All 8 sections present. 27 elements match 27 DDL columns. All element rows have 5 cells with tier tags. Property table complete. ETL pipeline diagram present with real names. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar does NOT contain Section 4. One miss: dictionary columns (Regulation, Club) list values but not in `key=value` format (e.g., `1=Bronze, 5=Silver`).

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent — names the domain (Singapore GST), row grain (per customer per day), ETL SP, refresh pattern (DELETE+INSERT), row count (~3.3M), date range (2023-01-01 to present), and population filters (CountryID=183). An analyst would immediately know when and why to query this table.

**Dimension 5 — Data Evidence: 8/10**
Strong data evidence: ~3.3M rows, 29,902 distinct customers, 8 regulations enumerated, 6 club tiers, 3 entity values with exact row counts (2,091,484 / 902,696 / 334,762). Date range explicit. Phase gate not formally marked as P2/P3 checkboxes but data claims appear grounded in live queries.

**Dimension 6 — Shape Fidelity: 9/10**
All structural elements present: numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: tier legend only includes T1 and T2 rows (no T3-T5), but that's because none are used.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values." (Fact_SnapshotCustomer) | "Real (funded) customer ID. The primary customer identifier in the DWH ecosystem." | MINOR | Dropped "Hash distribution key", "FK to Dim_Customer", "46.4M distinct values" — FSC-specific context, core meaning preserved |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation) | "Short code for the regulation. Values match production Dictionary.Regulation.Name. 8 values observed: FCA, ASIC & GAML, FSA Seychelles, ASIC, CySEC, MAS, FSRA, BVI." | MINOR | Dropped "Used in V_Dim_Customer and analytics dashboards"; added observed values (enrichment, not loss) |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." (Dim_PlayerLevel) | "Tier display name from eToro Club loyalty program. 6 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. IDs are NOT in rank order — use Dim_PlayerLevel.Sort for ordering." | NO | Dropped "Internal, N/A" from enumeration, dropped "Used in BackOffice reporting JOINs and customer-facing UI", rewrote opening phrase |

---

### Top 5 Issues

1. **HIGH — Club (column 3): Tier 1 description is paraphrased.** The upstream Dim_PlayerLevel.Name description is rewritten. "Internal" and "N/A" values are dropped from the enumeration. While these values won't appear in the GST table (filtered to Singapore depositors), the Tier 1 contract requires verbatim upstream text.

2. **MEDIUM — RealCID (column 1): Tier 1 description drops upstream metadata.** "Hash distribution key", "FK to Dim_Customer (if exists)", and "46.4M distinct values" are all present in the Fact_SnapshotCustomer upstream wiki but omitted. The first two are contextually appropriate to drop (GST_Report is ROUND_ROBIN, not HASH), but the verbatim standard is strict.

3. **LOW — Dictionary columns lack key=value format.** Regulation lists 8 values and Club lists 6, but neither provides the ID-to-name mapping inline (e.g., `1=CySEC, 2=FCA, 4=ASIC`). The SP source contains these mappings and they'd help analysts.

4. **LOW — Tier legend incomplete.** Section 4 tier legend only includes Tier 1 and Tier 2 rows. The standard 5-tier legend (T1 through T5) should appear for shape compliance even if some tiers are unused.

5. **LOW — TicketingFee sign convention not fully explained in element description.** While Section 3.4 Gotchas mentions the negation, the element description for TicketingFee (column 25) says "Negated SUM" without explaining WHY positive = company revenue. The Gotcha does clarify, but the element description should be self-contained.

---

### Regeneration Feedback

1. Replace Club description with verbatim text from Dim_PlayerLevel wiki: "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI."
2. Replace RealCID description with verbatim text from Fact_SnapshotCustomer wiki: "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values."
3. Add key=value pairs for Regulation and Club columns (e.g., `1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 9=FSA Seychelles, 10=ASIC&GAML, 13=MAS`).
4. Expand tier legend to include all 5 tiers for shape compliance.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_GST_Report",
  "weighted_score": 7.65,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 5,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values.",
      "wiki_quote": "Real (funded) customer ID. The primary customer identifier in the DWH ecosystem.",
      "match": "MINOR",
      "loss": "Dropped 'Hash distribution key', 'FK to Dim_Customer (if exists)', '46.4M distinct values' — FSC-specific context, core meaning preserved"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Values match production Dictionary.Regulation.Name. 8 values observed: FCA, ASIC & GAML, FSA Seychelles, ASIC, CySEC, MAS, FSRA, BVI.",
      "match": "MINOR",
      "loss": "Dropped 'Used in V_Dim_Customer and analytics dashboards'; added observed values (enrichment not loss)"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name from eToro Club loyalty program. 6 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. IDs are NOT in rank order — use Dim_PlayerLevel.Sort for ordering.",
      "match": "NO",
      "loss": "Dropped 'Internal, N/A' from value enumeration, dropped 'Used in BackOffice reporting JOINs and customer-facing UI', rewrote opening phrase"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Club",
      "problem": "Tier 1 description is paraphrased. Upstream Dim_PlayerLevel.Name says 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.' but wiki rewrites entirely and drops Internal/N/A values."
    },
    {
      "severity": "medium",
      "column_or_section": "RealCID",
      "problem": "Tier 1 description drops upstream metadata: 'Hash distribution key', 'FK to Dim_Customer (if exists)', '46.4M distinct values' from Fact_SnapshotCustomer wiki."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Elements",
      "problem": "Regulation and Club columns list values but not in key=value format (e.g., RegulationID 1=CySEC, 2=FCA). The SP source contains these mappings."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Tier legend only includes T1 and T2 rows. Standard shape requires all 5 tiers listed even if unused."
    },
    {
      "severity": "low",
      "column_or_section": "TicketingFee",
      "problem": "Element description says 'Negated SUM' without explaining why positive = company revenue. The Gotcha in 3.4 clarifies but element description should be self-contained."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace Club description with verbatim from Dim_PlayerLevel wiki: 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.' (2) Replace RealCID description with verbatim from Fact_SnapshotCustomer wiki including 'Hash distribution key' and 'FK to Dim_Customer'. (3) Add key=value pairs for Regulation and Club dictionary columns. (4) Expand tier legend to show all 5 tiers.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["~3.3M rows", "29,902 distinct customers", "2023-01-01 to 2026-04-26", "Entity distribution: eToro UK=2,091,484, eToro Capital Australia=902,696, NULL=334,762"],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
