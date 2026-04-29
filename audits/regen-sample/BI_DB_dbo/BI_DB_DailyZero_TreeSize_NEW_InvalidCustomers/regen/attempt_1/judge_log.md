## Adversarial Review — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

---

### Dimension 1 — Tier Accuracy: **5 / 10**

Five sampled columns and tier checks:

| Column | Wiki Tier | Correct Tier | Result |
|--------|-----------|-------------|--------|
| Country | Tier 1 — Dictionary.Country | Tier 1 — Dictionary.Country | ✓ |
| MifID | Tier 2 — SP_Fact_SnapshotCustomer | Tier 1 — DWH_dbo.Fact_SnapshotCustomer | ✗ |
| IsValidCustomer | Tier 2 — SP_Fact_SnapshotCustomer | Tier 1 — DWH_dbo.Fact_SnapshotCustomer | ✗ |
| Regulation | Tier 1 — Dictionary.Regulation | Tier 1 — Dictionary.Regulation | ✓ |
| GuruStatus | Tier 1 — Dictionary.GuruStatus | Tier 1 — Dictionary.GuruStatus | ✓ |

2 mismatches → **Score 5**. Both `MifID` (`b.MifidCategorizationID AS MifID`) and `IsValidCustomer` (`b.IsValidCustomer`) are direct passthrough/renames from `Fact_SnapshotCustomer`, whose wiki is fully present in the bundle. Per tier rules: passthrough with upstream wiki available → must be Tier 1. `IsCreditReportValidCB` has the same problem (also Tier 2 when it should be Tier 1 from FSC). No additional deduction for paraphrasing on the 6 declared T1 columns.

---

### Dimension 2 — Upstream Fidelity: **4 / 10**

T1 fidelity table (all 6 declared T1 columns):

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| HedgeServerID | "FK to Trade.HedgeServer. Hedge server managing this position." | "FK to Trade.HedgeServer. Hedge server managing the positions in this aggregation bucket." | MINOR | "this position" → "the positions in this aggregation bucket" |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | YES | None |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | Same + "ISNULL defaults to 'Unknown'." | MINOR | SP-level default note appended (accurate) |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | Same + "Passthrough from Dim_Country via Fact_SnapshotCustomer.CountryID." | MINOR | Routing note appended |
| PlayerLevel | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | Same + "Passthrough from Dim_PlayerLevel via Fact_SnapshotCustomer.PlayerLevelID." | MINOR | Routing note appended |
| GuruStatus | "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration." | Same + "Passthrough from Dim_GuruStatus via Fact_SnapshotCustomer.GuruStatusID." | MINOR | Routing note appended |

Base for declared T1 columns: **8** (all MINOR, no semantic loss). Three missed inheritances penalise this:
- `MifID`: Fact_SnapshotCustomer upstream available, tagged Tier 2. Upstream: "MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization." Wiki drops `DEFAULT 0` and FK target. **−2**
- `IsValidCustomer`: FSC upstream available, tagged Tier 2. Upstream "Approx 98% of current rows = 1" dropped. **−2**

8 − 4 = **4**

---

### Dimension 3 — Completeness: **8 / 10**

9/10 checklist items pass. Missing: **UC Target absent from the property table**. All other checks pass: 8 sections present, 34 elements = 34 DDL columns, all rows have 5 cells and `(Tier N — source)` tags, ETL ASCII diagram with real names, footer tier counts, row count + date range in Section 1, dictionary enum values listed inline where appropriate, review-needed sidecar does not contain `## 4. Elements`. Score: 9/10 = **8**.

---

### Dimension 4 — Business Meaning: **9 / 10**

Section 1 is specific and actionable: names the filter criterion (`IsValidCustomer=0`), row grain (multi-dimensional aggregation), row count (~6.18M), date range (2021-01-01 to 2025-06-29), ETL SP (`SP_DailyZero_TreeSize_NEW_InvalidCustomers`), and the DELETE+INSERT pattern. Could note the data anomaly (sparse 2025 data) but this is a minor omission.

---

### Dimension 5 — Data Evidence: **8 / 10**

Row count (~6.18M), date range, and last ETL run date all present. Enum values for Copy, GuruStatus, PlayerLevel, SettlementType, InstrumentType are listed. Review-needed sidecar contains live distribution data (SettlementType split, 2025 data sparsity). Phases: 11/14 but data claims are consistent with actual sampling. No fabricated statistics detected.

---

### Dimension 6 — Shape Fidelity: **9 / 10**

Golden reference shape followed throughout: numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed. Property table present. Section 5 has both a lineage table and ETL ASCII diagram. Only issue is the missing UC Target in the property table.

---

### Weighted Score

```
0.25×5 + 0.20×4 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×9
= 1.25 + 0.80 + 1.60 + 1.35 + 0.80 + 0.90
= 6.70
```

**Verdict: FAIL** (6.0–7.4 band)

---

### Top 5 Issues

1. **MifID (col 23)** — Tagged `(Tier 2 — SP_Fact_SnapshotCustomer)` but `b.MifidCategorizationID AS MifID` is a direct rename from `Fact_SnapshotCustomer`, whose wiki is in the bundle. Must be `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)`. Description drops "DEFAULT 0" and "FK to Dim_MifidCategorization".
2. **IsValidCustomer (col 33)** — Tagged Tier 2 but is a passthrough from `Fact_SnapshotCustomer.IsValidCustomer`. Should be Tier 1 from FSC. Upstream note "Approx 98% of current rows = 1" dropped from description.
3. **IsCreditReportValidCB (col 34)** — Tagged Tier 2 but is a passthrough from `Fact_SnapshotCustomer.IsCreditReportValidCB` (upstream wiki available in bundle). Should be Tier 1.
4. **UC Target absent from property table** — Property table omits the `UC Target` row, which fails the Completeness checklist. The sibling table `BI_DB_DailyZero_TreeSize_NEW` likely has a corresponding UC target that should be referenced here.
5. **Sparse 2025 data unmentioned in Section 1** — The review-needed sidecar documents a significant anomaly (~20K rows in 2025 vs ~6.15M in 2021–2024). This anomaly is not surfaced in Section 1 or Section 3.4 gotchas, leaving analysts blind to a likely ETL gap or table deprecation.

---

### Regeneration Feedback

1. **Re-tag MifID** as `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)`. Quote verbatim from FSC wiki: "MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization." Append SP transform note: "Renamed as `MifID` in SP."
2. **Re-tag IsValidCustomer** as `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)`. Use verbatim FSC description and retain the table-specific note that values are always 0 here due to `WHERE IsValidCustomer=0`.
3. **Re-tag IsCreditReportValidCB** as `(Tier 1 — DWH_dbo.Fact_SnapshotCustomer)` using verbatim FSC description.
4. **Add UC Target** to the property table — check sister table `BI_DB_DailyZero_TreeSize_NEW` for the pattern and confirm the mapping in `_generic_pipeline_mapping.json`.
5. **Add sparse-2025-data gotcha** to Section 3.4 (or Section 1): "Only ~20K rows exist for 2025 vs ~6.15M for 2021–2024 — possible ETL gap or table deprecation. Verify SP is still running daily before using this table for 2025 analysis."

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers",
  "weighted_score": 6.70,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 4,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing the positions in this aggregation bucket.",
      "match": "MINOR",
      "loss": "'this position' reworded to 'the positions in this aggregation bucket' — minor contextual adjustment"
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. ISNULL defaults to 'Unknown'.",
      "match": "MINOR",
      "loss": "SP-level ISNULL default appended — accurate addition, no semantic loss"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country via Fact_SnapshotCustomer.CountryID.",
      "match": "MINOR",
      "loss": "Routing note appended — no semantic loss"
    },
    {
      "column": "PlayerLevel",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel via Fact_SnapshotCustomer.PlayerLevelID.",
      "match": "MINOR",
      "loss": "Routing note appended — no semantic loss"
    },
    {
      "column": "GuruStatus",
      "upstream_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration.",
      "wiki_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus via Fact_SnapshotCustomer.GuruStatusID.",
      "match": "MINOR",
      "loss": "Routing note appended — no semantic loss"
    },
    {
      "column": "MifID",
      "upstream_quote": "MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization.",
      "wiki_quote": "MiFID II client categorization (Retail/Professional/Eligible Counterparty) from Fact_SnapshotCustomer.MifidCategorizationID. Renamed in SP.",
      "match": "NO",
      "loss": "Missed inheritance: should be Tier 1 from Fact_SnapshotCustomer. 'DEFAULT 0' and 'FK to Dim_MifidCategorization' dropped. Tagged Tier 2 instead of Tier 1."
    },
    {
      "column": "IsValidCustomer",
      "upstream_quote": "1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1.",
      "wiki_quote": "Always 0 in this table (SP filters WHERE IsValidCustomer=0). 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID.",
      "match": "NO",
      "loss": "Missed inheritance: should be Tier 1 from Fact_SnapshotCustomer. 'Approx 98% of current rows = 1' dropped. Tagged Tier 2 instead of Tier 1."
    },
    {
      "column": "IsCreditReportValidCB",
      "upstream_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3.",
      "wiki_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. Passthrough from Fact_SnapshotCustomer.",
      "match": "NO",
      "loss": "Missed inheritance: should be Tier 1 from Fact_SnapshotCustomer. Tagged Tier 2 instead of Tier 1. §2.3 detail reference dropped."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "MifID",
      "problem": "Tagged (Tier 2 — SP_Fact_SnapshotCustomer) but b.MifidCategorizationID AS MifID is a direct rename from Fact_SnapshotCustomer whose wiki is in the bundle. Must be Tier 1 from Fact_SnapshotCustomer. Description drops 'DEFAULT 0' and 'FK to Dim_MifidCategorization'."
    },
    {
      "severity": "high",
      "column_or_section": "IsValidCustomer",
      "problem": "Tagged (Tier 2 — SP_Fact_SnapshotCustomer) but b.IsValidCustomer is a direct passthrough from Fact_SnapshotCustomer (upstream wiki available). Should be Tier 1 from Fact_SnapshotCustomer. 'Approx 98% of current rows = 1' distribution stat dropped."
    },
    {
      "severity": "high",
      "column_or_section": "IsCreditReportValidCB",
      "problem": "Tagged (Tier 2 — SP_Fact_SnapshotCustomer) but b.IsCreditReportValidCB is a direct passthrough from Fact_SnapshotCustomer (upstream wiki available). Should be Tier 1 from Fact_SnapshotCustomer."
    },
    {
      "severity": "medium",
      "column_or_section": "## 2. Properties table",
      "problem": "UC Target row is absent from the property table. The Completeness checklist requires Production Source, Refresh, Distribution, and UC Target. Only the first three are present."
    },
    {
      "severity": "medium",
      "column_or_section": "## 1. Business Meaning / ## 3.4 Gotchas",
      "problem": "Sparse 2025 data (~20K rows vs ~6.15M in 2021-2024) is documented in the review-needed sidecar but not surfaced in Section 1 or Section 3.4. Analysts using this table for 2025 analysis will encounter unexpected empty results with no warning."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag MifID as (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) and quote verbatim: 'MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization.' Add SP rename note. (2) Re-tag IsValidCustomer as (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) using verbatim FSC description; retain the always-0 table-specific note. (3) Re-tag IsCreditReportValidCB as (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) using verbatim FSC description. (4) Add UC Target to the property table — check sister table BI_DB_DailyZero_TreeSize_NEW for the target path pattern. (5) Add gotcha in Section 3.4: 'Sparse 2025 data — only ~20K rows exist for 2025 vs ~6.15M for 2021–2024. Possible ETL gap or table deprecation. Verify SP is still running before using for 2025 analysis.'",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["3 phases of 14 unaccounted for (footer reports 11/14); data claims appear grounded in live sampling so P2/P3 likely not skipped"]
  }
}
</JUDGE_VERDICT>
