## Human Summary

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 10 | Sampled HedgeServerID, Regulation, Country, MifID, IsValidCustomer — all correctly tagged. Dim-lookup passthroughs correctly traced to root Dictionary origins, not left at Dim_X relay. No mis-tiers. |
| Upstream Fidelity (20%) | 9 | All 9 Tier 1 columns reproduce upstream text verbatim, then append provenance notes ("Passthrough from Dim_Position.", "Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID."). These are additions, not rewording. No semantic loss. |
| Completeness (20%) | 10 | 10/10 checklist items pass. DDL 34 = wiki 34. All 8 sections present. Section 5.2 ASCII pipeline uses real object names. Footer has tier breakdown. Section 1 has row count + date range. Enum columns list values inline. review-needed has no Elements section. |
| Business Meaning (15%) | 9 | Section 1 is highly specific: names domain (invalid-customer zero P&L aggregate), row grain (daily DELETE+INSERT cycle), ETL SP, row count (6.18M), date range (2021–2025), year breakdown with exact counts, data gap (no 2024), and companion table. Only gap: no explicit mention of what GROUP BY dimensions drive grain uniqueness. |
| Data Evidence (10%) | 8 | Live data clearly used: year-level row counts, SettlementType distribution (Real=3.36M, CFD=2.82M, TRS=1.2K), 2025 sparsity noted. Footer says Phases 11/14; 3 phases skipped (Phase 10 = Atlassian explicitly noted; other 2 unidentified but data claims are internally consistent). |
| Shape Fidelity (10%) | 9 | Numbered sections, tier legend, real SQL samples, footer quality score and phases — all present. No Phase Gate Checklist section with [x]/[ ] boxes. Minor deviation. |

**Weighted: 0.25×10 + 0.20×9 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9 = 9.35 → PASS**

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| HedgeServerID | FK to Trade.HedgeServer. Hedge server managing this position. | FK to Trade.HedgeServer. Hedge server managing this position. Passthrough from Dim_Position. | MINOR | Addition only — no semantic loss |
| Leverage | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position. | MINOR | Addition only |
| Regulation | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID. | MINOR | Addition only |
| MifID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. Renamed from Fact_SnapshotCustomer.MifidCategorizationID. | MINOR | Addition only |
| Country | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID. | MINOR | Addition only |
| PlayerLevel | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID. | MINOR | Addition only |
| GuruStatus | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Dim-lookup passthrough via Fact_SnapshotCustomer.GuruStatusID. | MINOR | Addition only |
| IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. Approx 98% of current rows = 1 in Fact_SnapshotCustomer. Always 0 in this table (SP filters WHERE IsValidCustomer=0). | MINOR | "See §2.2" dropped (internal ref); table-specific note added — no semantic loss |
| IsCreditReportValidCB | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. Passthrough from Fact_SnapshotCustomer. | MINOR | "See §2.3" dropped (internal ref); provenance added — no semantic loss |

---

### Top 5 Issues

1. **[medium] Section 6.1 (References To) — severely incomplete.** Only `InstrumentID→Dim_Instrument` and `HedgeServerID→Dim_Position` are listed. Missing: `Regulation→Dim_Regulation`, `Country→Dim_Country`, `PlayerLevel→Dim_PlayerLevel`, `GuruStatus→Dim_GuruStatus`, `CID→Fact_SnapshotCustomer`, `PositionID→BI_DB_PositionPnL`. An analyst reading Section 6 would have a substantially incomplete join picture.

2. **[medium] IsCFD description inaccurate.** Element #21 claims "Dim_Position takes precedence for the inverse logic." The SP logic is: `CASE WHEN a.IsSettled=0 AND pnl.IsSettled=1 THEN 0 WHEN a.IsSettled=1 AND pnl.IsSettled=0 THEN 1 ELSE CASE WHEN a.IsSettled=0 THEN 1 ELSE 0 END`. When the two sources conflict, the output does NOT consistently follow Dim_Position — the first branch overrides CFD→Real, the second overrides Real→CFD, making PnL's signal the tiebreaker in both conflict cases. The description is misleading.

3. **[low] Section 3.3 (Common JOINs) incomplete.** Lists joins to `Dim_Instrument` and `Dim_Position` only. Missing joins to `Dim_Regulation`, `Dim_Country`, `Dim_PlayerLevel`, `Dim_GuruStatus` — all of which are in the SP and produce T1 columns analysts will want to navigate back to.

4. **[low] No explicit Phase Gate Checklist section.** The footer records `Phases: 11/14` but there is no `[x] P2`, `[x] P3` checkbox block. It is inferrable from data specificity that live queries ran, but the format is non-standard and a downstream reader cannot distinguish "P2 completed" from "P2 skipped with fabricated data."

5. **[low] Nop_Units column name inconsistency.** The DDL column is `[Nop_Units]` (capital N, lowercase op). The wiki element #17 labels it `Nop_Units` (correct match), but Section 5.1 lineage table uses `NOP_Units` (all-caps NOP). Minor but could cause copy-paste SQL errors.

---

### Regeneration Feedback

1. Expand Section 6.1 with all referenced objects: add rows for Dim_Regulation (Regulation), Dim_Country (Country), Dim_PlayerLevel (PlayerLevel), Dim_GuruStatus (GuruStatus), Fact_SnapshotCustomer (CID join), BI_DB_PositionPnL (PositionID join).
2. Correct IsCFD element #21 description: the SP's disagreement logic uses BI_DB_PositionPnL.IsSettled as the deciding signal in both conflict branches, not Dim_Position. Describe the three-case CASE logic explicitly.
3. Add missing dimension joins to Section 3.3 (Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus with their join conditions).
4. Add Phase Gate Checklist with explicit `[x] P2` / `[x] P3` markers or equivalent to make data-evidence phase completion auditable.
5. Normalize `NOP_Units` to `Nop_Units` in Section 5.1 lineage table to match DDL.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers",
  "weighted_score": 9.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing this position. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Addition only — provenance note appended, no semantic loss"
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Addition only"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID.",
      "match": "MINOR",
      "loss": "Addition only"
    },
    {
      "column": "MifID",
      "upstream_quote": "MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization.",
      "wiki_quote": "MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. Renamed from Fact_SnapshotCustomer.MifidCategorizationID.",
      "match": "MINOR",
      "loss": "Addition only — rename note appended"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID.",
      "match": "MINOR",
      "loss": "Addition only"
    },
    {
      "column": "PlayerLevel",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID.",
      "match": "MINOR",
      "loss": "Addition only"
    },
    {
      "column": "GuruStatus",
      "upstream_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration.",
      "wiki_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Dim-lookup passthrough via Fact_SnapshotCustomer.GuruStatusID.",
      "match": "MINOR",
      "loss": "Addition only"
    },
    {
      "column": "IsValidCustomer",
      "upstream_quote": "1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1.",
      "wiki_quote": "1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. Approx 98% of current rows = 1 in Fact_SnapshotCustomer. Always 0 in this table (SP filters WHERE IsValidCustomer=0).",
      "match": "MINOR",
      "loss": "Internal section reference 'See §2.2' dropped; table-specific note added — no semantic loss"
    },
    {
      "column": "IsCreditReportValidCB",
      "upstream_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3.",
      "wiki_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. Passthrough from Fact_SnapshotCustomer.",
      "match": "MINOR",
      "loss": "Internal section reference 'See §2.3' dropped; passthrough note added — no semantic loss"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 6.1 (References To)",
      "problem": "Only InstrumentID→Dim_Instrument and HedgeServerID→Dim_Position listed. Missing: Regulation→Dim_Regulation, Country→Dim_Country, PlayerLevel→Dim_PlayerLevel, GuruStatus→Dim_GuruStatus, CID join→Fact_SnapshotCustomer, PositionID join→BI_DB_PositionPnL. An analyst reading Section 6 has a substantially incomplete join picture."
    },
    {
      "severity": "medium",
      "column_or_section": "IsCFD",
      "problem": "Element #21 description claims 'Dim_Position takes precedence for the inverse logic.' The SP CASE branches show: when Dim_Position.IsSettled=0 (CFD) and PnL.IsSettled=1 (Real) → output 0 (Real wins); when Dim_Position.IsSettled=1 (Real) and PnL.IsSettled=0 (CFD) → output 1 (CFD wins). In both conflict cases the output follows BI_DB_PositionPnL's signal, not Dim_Position. The description is inaccurate and may mislead analysts debugging IsCFD discrepancies."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3 (Common JOINs)",
      "problem": "Missing common joins to Dim_Regulation (on Regulation), Dim_Country (on Country), Dim_PlayerLevel (on PlayerLevel), Dim_GuruStatus (on GuruStatus) — all of which are output columns analysts will want to cross-reference."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / footer",
      "problem": "Footer records 'Phases: 11/14' but no explicit Phase Gate Checklist with [x] P2 / [x] P3 checkboxes exists. Auditable evidence that live data queries ran cannot be confirmed from the document structure alone."
    },
    {
      "severity": "low",
      "column_or_section": "Nop_Units (Section 5.1)",
      "problem": "DDL column name is Nop_Units (capital N, lowercase op). Section 5.1 lineage table uses NOP_Units (all-caps NOP). Inconsistency could cause copy-paste SQL errors."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Expand Section 6.1 to include all referenced objects: Dim_Regulation (Regulation), Dim_Country (Country), Dim_PlayerLevel (PlayerLevel), Dim_GuruStatus (GuruStatus), Fact_SnapshotCustomer (CID join), BI_DB_PositionPnL (PositionID join). (2) Correct IsCFD element #21: the SP's conflict-resolution logic uses BI_DB_PositionPnL.IsSettled as the determining signal in both disagreement branches — not Dim_Position. Describe all three CASE branches explicitly. (3) Add Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus to Section 3.3 Common JOINs. (4) Add explicit Phase Gate Checklist with [x] P2 / [x] P3 or equivalent notation. (5) Normalize 'NOP_Units' to 'Nop_Units' in Section 5.1 lineage to match DDL column casing.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "SettlementType: Real=3.36M, CFD=2.82M, TRS=1.2K",
      "Year distribution: 2021=2.51M, 2022=2.88M, 2023=766K, 2025=20K",
      "Total rows: 6.18M"
    ],
    "skipped_phases": ["Phase 10 (Atlassian — explicitly noted in Section 8)", "2 additional phases unidentified (footer: 11/14)"]
  }
}
</JUDGE_VERDICT>
