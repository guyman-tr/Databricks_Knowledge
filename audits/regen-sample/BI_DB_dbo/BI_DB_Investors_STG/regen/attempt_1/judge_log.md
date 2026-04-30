## Judge Review: BI_DB_dbo.BI_DB_Investors_STG

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 7/10**
Sampled columns #1 (SourceTable), #4 (CID), #7 (RegulationID), #10 (InstrumentType), #13 (UpdateDate). One mismatch: RegulationID is a direct passthrough from `Fact_SnapshotCustomer.RegulationID` (just `fsc.RegulationID` in all three INSERT streams with no transform). FSC has a wiki in the bundle, so this should be Tier 1. The same issue affects AccountManagerID and CountryID — all three are `SELECT fsc.X` with zero transformation, yet all tagged Tier 2. Three total mismatches across the full table, one caught in sample.

**Dimension 2 — Upstream Fidelity: 3/10**
The wiki declares **zero** Tier 1 columns. However, AccountManagerID, CountryID, and RegulationID are all straight passthroughs from `Fact_SnapshotCustomer` — whose wiki is present in the bundle. The writer should have quoted FSC descriptions verbatim and tagged them Tier 1. This is a "wrong tier origin" failure: the writer attributed these to "SP_InvestorReport" (the relay) instead of the root upstream (FSC). Three missed inheritances at −2 each compounds the base score of 3.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count = DDL count (13/13). Every element row has 5 cells with `(Tier N — source)` tags. Property table has all required fields. Section 5.2 has a real ETL pipeline diagram. Footer has tier breakdown. Section 1 has row count (~9.5M) and date (2026-04-25). SourceTable, ActionType, AssetType, InstrumentType all enumerate their discrete values inline. Review-needed sidecar has no `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is concrete and actionable: names the domain (investor activity reporting), row grain (CID × ActionType × InstrumentType × AssetType per date), ETL SP (SP_InvestorReport), refresh pattern (daily truncate-and-reload), downstream consumers (SP_InvestorReport_Cluster → BI_DB_Investors), row count (~9.5M), and stream breakdown percentages. An analyst can immediately understand what this table is for and when to use it.

**Dimension 5 — Data Evidence: 7/10**
Row count (9.5M) and date (2026-04-25) present. Stream distribution with exact counts (Balance: 5,875,751). NULL observation for AUA (161 rows). Footer says "Phases: 12/14" but no explicit Phase Gate Checklist section identifying which phases were completed. Data claims appear genuine based on specificity.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor deviations: tier legend only lists Tier 2 (should list all tiers present or at least acknowledge the absence of Tier 1). Footer format is close to golden reference but not identical.

### T1 Fidelity Table

The wiki claims **zero** Tier 1 columns, so no fidelity comparisons can be made. However, three columns SHOULD be Tier 1:

| Column | Upstream Wiki (FSC) Description | Wiki Description | Match | Loss |
|--------|------|------|-------|------|
| AccountManagerID | "Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer)" | "Assigned account manager (sales/retention). Sourced from Fact_SnapshotCustomer.AccountManagerID in all streams. FK to DWH_dbo.Dim_Manager. (Tier 2 — Fact_SnapshotCustomer)" | NO | Dropped "DEFAULT 0", dropped BO source chain, wrong tier tag. Should be Tier 1 — Fact_SnapshotCustomer with verbatim FSC text. |
| CountryID | "Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer)" | "Customer's registered country. Sourced from Fact_SnapshotCustomer.CountryID in all streams. FK to DWH_dbo.Dim_Country. (Tier 2 — Fact_SnapshotCustomer)" | NO | Dropped "DEFAULT 0", dropped CC source, dropped CountryID=250 exclusion note. |
| RegulationID | "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer)" | "Regulatory entity ID. Sourced from Fact_SnapshotCustomer.RegulationID in all streams. FK to DWH_dbo.Dim_Regulation. (Tier 2 — Fact_SnapshotCustomer)" | NO | Dropped "DEFAULT 0", dropped end-of-day rule, dropped RegulationChangeLog source, genericized to "Regulatory entity ID". |

### Top 5 Issues

1. **HIGH — AccountManagerID, CountryID, RegulationID wrongly tagged Tier 2.** All three are direct passthroughs from `Fact_SnapshotCustomer` via `fsc.AccountManagerID`, `fsc.CountryID`, `fsc.RegulationID` with zero transformation. FSC wiki is in the bundle. These must be Tier 1 — Fact_SnapshotCustomer with verbatim descriptions.

2. **HIGH — Tier legend omits Tier 1.** The Confidence Tier Legend in Section 4 only lists Tier 2. With three columns that should be Tier 1, the legend is incomplete and misleading — it signals that the writer didn't consider inheritance at all.

3. **MEDIUM — AccountManagerID description drops DEFAULT 0 and BO source chain.** The FSC wiki explicitly notes `DEFAULT 0` and `Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO)`. The STG wiki replaces this with generic "Sourced from Fact_SnapshotCustomer.AccountManagerID in all streams." Semantic loss.

4. **MEDIUM — RegulationID description drops the end-of-day rule.** FSC wiki explicitly calls out the end-of-day change from RegulationChangeLog (§2.4 in FSC). The STG wiki genericizes this to "Regulatory entity ID" — an analyst reading this wiki would not know about the end-of-day rule.

5. **LOW — CountryID description drops the CountryID=250 exclusion note.** FSC wiki notes "Key filter for valid customer segmentation (CountryID=250 excluded)". The STG wiki drops this business-critical detail.

### Regeneration Feedback

1. Re-tag `AccountManagerID`, `CountryID`, and `RegulationID` as `(Tier 1 — Fact_SnapshotCustomer)` and use the verbatim descriptions from the Fact_SnapshotCustomer wiki (including DEFAULT 0, source chains, and business rules like end-of-day regulation and CountryID=250 exclusion).
2. Update the Confidence Tier Legend in Section 4 to include both Tier 1 (passthrough from upstream wiki) and Tier 2 (ETL-computed).
3. Update the footer tier breakdown from "0 T1, 13 T2" to "3 T1, 10 T2".
4. In the lineage file Column Lineage table, mark AccountManagerID/CountryID/RegulationID transforms as "Passthrough" (they already say this) and ensure the wiki reflects the same.

### Weighted Score

```
weighted = 0.25×7 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 1.75 + 0.60 + 2.00 + 1.35 + 0.70 + 0.80
         = 7.20
```

**Verdict: FAIL** (7.20 < 7.5)

The wiki is excellent on completeness, business meaning, and data evidence. The failure is concentrated in tier classification: three passthrough columns from Fact_SnapshotCustomer should be Tier 1 with verbatim descriptions but are tagged Tier 2 with paraphrased text. This is a fixable issue — the core content is strong.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Investors_STG",
  "weighted_score": 7.20,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "AccountManagerID, CountryID, RegulationID",
      "problem": "All three columns are direct passthroughs from Fact_SnapshotCustomer (fsc.AccountManagerID, fsc.CountryID, fsc.RegulationID) with no transformation. FSC wiki is in the bundle. These must be Tier 1 — Fact_SnapshotCustomer with verbatim descriptions, not Tier 2 — SP_InvestorReport."
    },
    {
      "severity": "high",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Confidence Tier Legend only lists Tier 2. With three columns that should be Tier 1, the legend is incomplete and misleading, signaling the writer did not consider upstream inheritance."
    },
    {
      "severity": "medium",
      "column_or_section": "AccountManagerID",
      "problem": "Description drops 'DEFAULT 0' and 'Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO)' from FSC wiki. Replaced with generic 'Sourced from Fact_SnapshotCustomer.AccountManagerID in all streams.'"
    },
    {
      "severity": "medium",
      "column_or_section": "RegulationID",
      "problem": "Description drops the end-of-day rule from FSC wiki (Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change). Genericized to 'Regulatory entity ID' — analyst would not know about the end-of-day regulation change semantics."
    },
    {
      "severity": "low",
      "column_or_section": "CountryID",
      "problem": "Description drops 'Key filter for valid customer segmentation (CountryID=250 excluded)' from FSC wiki — a business-critical detail for understanding validity filtering."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag AccountManagerID, CountryID, RegulationID as (Tier 1 — Fact_SnapshotCustomer) using verbatim descriptions from the FSC wiki, including DEFAULT 0, source chains (BO/CC), end-of-day regulation rule, and CountryID=250 exclusion. (2) Update Section 4 Confidence Tier Legend to include Tier 1 (passthrough from upstream wiki) alongside Tier 2. (3) Update footer tier breakdown from '0 T1, 13 T2' to '3 T1, 10 T2'. (4) In lineage file, ensure passthrough columns are consistent with Tier 1 designation.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
