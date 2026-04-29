## Human-Readable Summary

**Object**: `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH` (partition-switch shadow table, 169 DDL columns, always empty at rest)

---

### Per-Dimension Scores

| Dimension | Score | Justification |
|---|---|---|
| Tier Accuracy (25%) | 9 | All 169 columns correctly tagged Tier 1 (passthrough via metadata-only partition switch, upstream wiki present). Minor concern: relay attribution `(Tier 1 — BI_DB_CID_DailyPanel_FullData)` rather than root for columns whose root in the parent is a different upstream (e.g., `CID` → `DWH_dbo.Dim_Customer`). No outright misfires. |
| Upstream Fidelity (20%) | 8 | Strong verbatim matching for all columns verifiable from the 30 KB bundle excerpt. Descriptions in the SWITCH wiki are character-for-character from the parent wiki entries. Single minor deviation: `Revenue_Total` changes "See §2.6" → "See parent wiki §2.6". Full verification of columns beyond the bundle truncation limit is not possible, but the pattern is consistent throughout. |
| Completeness (20%) | 8 | All 8 sections present, 169 element rows match DDL exactly, all rows have 5 cells and end with tier notation, property table complete, ETL pipeline diagram present with real SP names, review-needed sidecar has no `## 4. Elements`. Deductions: footer quality score left as `pending/10`; tier legend in Section 4 only lists Tier 1 and Tier 3 (no Tier 2/4 listed even for completeness). |
| Business Meaning (15%) | 9 | Exceptional for an infrastructure table. Explains the partition-switch mechanism step-by-step, names both SPs, documents the SSDT vs runtime schema drift, gives the typical state (0 rows), and calls out "never query this table for analytics." Exactly what a new analyst needs. |
| Data Evidence (10%) | 6 | Correctly avoids fabricating statistics for a table that is always empty. "Normally 0 rows" is the correct and only honest row-count statement. However, the footer shows `Phases: 11/14` without specifying which 3 phases were skipped — if P2/P3 were skipped, this should be explicit. No data claims appear (correct). |
| Shape Fidelity (10%) | 7 | Numbered sections, SQL samples, tier legend, and lineage diagram all present. Footer is structurally incomplete (`Quality: pending/10`). Tier legend lists only 2 of 4 possible tiers. Section reference in `Revenue_Total` ("See parent wiki §2.6") slightly diverges from golden shape. |

**Weighted score**: `0.25×9 + 0.20×8 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×7 = 2.25 + 1.60 + 1.60 + 1.35 + 0.60 + 0.70 = **8.10**`

---

### T1 Fidelity Table

All 169 columns are tagged Tier 1 from `BI_DB_CID_DailyPanel_FullData`. Spot-checking 10 columns against the bundle's upstream wiki:

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| CID | "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID" | "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID" | YES | — |
| DateID | "Partition key: date in YYYYMMDD format. One row per CID per day" | "Partition key: date in YYYYMMDD format. One row per CID per day" | YES | — |
| Region | "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe')" | "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe')" | YES | — |
| Country | "Customer's country name at snapshot date" | "Customer's country name at snapshot date" | YES | — |
| Active | "1 if customer had any position open or closed on this date (any instrument, including partial close children excluded)" | "1 if customer had any position open or closed on this date (any instrument, including partial close children excluded)" | YES | — |
| Revenue_Copy | "Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy" | "Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy" | YES | — |
| EOD_Club | "Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'" | "Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'" | YES | — |
| Equity | "Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value" | "Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value" | YES | — |
| Daily_Classification | "Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration" | "Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration" | YES | — |
| Revenue_Total | "Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See §2.6" | "Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See parent wiki §2.6" | MINOR | Added "parent wiki" qualifier to section ref |

---

### Top 5 Issues

1. **[medium] Footer/Section 8 — Quality score left as `pending/10`**: The footer was never updated with a computed quality score. The output is structurally incomplete. Any consumer of this wiki expecting a self-reported score will see a sentinel rather than a value.

2. **[low] All 169 columns — Tier source is relay (BI_DB_CID_DailyPanel_FullData), not root**: Columns `CID`, `Region`, and `Country` have documented root origins in the parent wiki (`DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Country.Region`, `DWH_dbo.Dim_Country.Name` respectively). The SWITCH wiki correctly inherits verbatim descriptions but sources every column through the relay parent rather than the root. For a partition-switch shadow table this is defensible, but an analyst looking for the ultimate origin will need to chase one additional link. Should either cite the root or explicitly document the relay pattern.

3. **[low] Section 4 Tier Legend — Tier 2 and Tier 4 entries absent**: The legend lists Tier 1 and Tier 3 only. Even if T2 and T4 are not used in this table, the legend should include all four tiers (with a note that only T1 applies) to match the golden reference shape.

4. **[low] Footer — `Phases: 11/14` without specifying which 3 were skipped**: Three of fourteen phases are unaccounted for. If any of the skipped phases are P2 (row-count queries) or P3 (distribution queries), this must be documented explicitly. For a shadow table that is always empty, skipping P2/P3 is correct, but the rationale should appear in the footer or review-needed sidecar.

5. **[low] Runtime schema divergence (14 extra columns) not reflected in Elements table**: The SSDT DDL has 169 columns; the runtime table has 183 (the SP recreates via `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`). The wiki correctly documents this in §3.4 and the review-needed sidecar. However, the 14 extra runtime-only columns (`V3_CompleteDate`, `EOD_LSD`, `ActiveOpen_Manual`, `ActiveOpen_Mirror`, `ActiveOpen_AirDrop`, `ActiveOpen_IncludeCopy`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`, `Transactional_Revenue_Total`, `ACC_Transactional_Revenue_Total`, `CashoutsAdjusted`, `EOD_LSD`) are not documented in the Elements table. An analyst who queries the live table will encounter 14 undocumented columns.

---

### Regeneration Feedback

1. Replace `Quality: pending/10` in the footer with the computed weighted score.
2. For `CID`, `Region`, and `Country` (confirmed T1 roots in parent), add a note that the tier citation relays through `BI_DB_CID_DailyPanel_FullData` but traces ultimately to `DWH_dbo.Dim_Customer` / `DWH_dbo.Dim_Country.Region` / `DWH_dbo.Dim_Country.Name`. Alternatively, cite the root directly per the rubric's relay rule.
3. Expand the Section 4 Tier Legend to list all four tiers, with "N/A — not used in this table" for T2 and T4.
4. In the footer or review-needed sidecar, explicitly document which 3 phases were skipped and why (e.g., "P2/P3 skipped — table is always empty at rest; live data queries return 0 rows").
5. Add a note in Section 4 (or as a separate subsection of Section 3.4) listing the 14 runtime-only columns not present in the SSDT DDL, with a reference back to the parent wiki for their descriptions.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CID_DailyPanel_FullData_SWITCH",
  "weighted_score": 8.10,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 8,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID",
      "wiki_quote": "eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID",
      "match": "YES",
      "loss": null
    },
    {
      "column": "DateID",
      "upstream_quote": "Partition key: date in YYYYMMDD format. One row per CID per day",
      "wiki_quote": "Partition key: date in YYYYMMDD format. One row per CID per day",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Region",
      "upstream_quote": "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe')",
      "wiki_quote": "Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe')",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Customer's country name at snapshot date",
      "wiki_quote": "Customer's country name at snapshot date",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Active",
      "upstream_quote": "1 if customer had any position open or closed on this date (any instrument, including partial close children excluded)",
      "wiki_quote": "1 if customer had any position open or closed on this date (any instrument, including partial close children excluded)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Revenue_Copy",
      "upstream_quote": "Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy",
      "wiki_quote": "Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy",
      "match": "YES",
      "loss": null
    },
    {
      "column": "EOD_Club",
      "upstream_quote": "Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'",
      "wiki_quote": "Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Equity",
      "upstream_quote": "Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value",
      "wiki_quote": "Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Daily_Classification",
      "upstream_quote": "Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration",
      "wiki_quote": "Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Revenue_Total",
      "upstream_quote": "Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See §2.6",
      "wiki_quote": "Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See parent wiki §2.6",
      "match": "MINOR",
      "loss": "Added 'parent wiki' qualifier to section cross-reference; meaning preserved"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Quality score left as 'pending/10' — was never computed and filled in. The wiki is structurally incomplete at the footer level."
    },
    {
      "severity": "low",
      "column_or_section": "CID, Region, Country (and all 169 columns)",
      "problem": "Tier citations relay through BI_DB_CID_DailyPanel_FullData rather than citing the root origin. CID's root is DWH_dbo.Dim_Customer, Region's root is DWH_dbo.Dim_Country.Region, Country's root is DWH_dbo.Dim_Country.Name. For a partition-switch shadow this is defensible but violates the rubric's relay rule."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Legend only lists Tier 1 and Tier 3 ('not applicable'). Tier 2 and Tier 4 are absent. Golden reference shape requires all four tiers in the legend, with N/A annotation if unused."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Phases: 11/14 — three phases are unaccounted for without specifying which. If P2 or P3 are among the skipped, the rationale (table is always empty at rest) must be documented explicitly."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Elements",
      "problem": "14 runtime-only columns (V3_CompleteDate, EOD_LSD, ActiveOpen_Manual, ActiveOpen_Mirror, ActiveOpen_AirDrop, ActiveOpen_IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, Revenue_TicketFeeByPercent, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, CashoutsAdjusted, EOD_LSD) exist in the live runtime table (created via SELECT TOP 0 * FROM parent) but are not documented in the Elements table. Analysts querying the live table will find 14 undocumented columns."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace 'pending/10' in footer with the computed weighted quality score. (2) For CID, Region, Country — either cite the ultimate root origin (DWH_dbo.Dim_Customer, DWH_dbo.Dim_Country.Region, DWH_dbo.Dim_Country.Name) or add a legend note that SWITCH table citations relay through BI_DB_CID_DailyPanel_FullData by design. (3) Expand Section 4 Tier Legend to include all four tiers (T2 and T4 as 'N/A — not used'). (4) Document which 3 phases were skipped in footer or review-needed sidecar, with rationale (table always empty at rest, P2/P3 data collection not feasible). (5) Add a subsection in Section 3.4 or a note in Section 4 header listing the 14 runtime-only columns absent from the SSDT DDL, with pointer to parent wiki for their descriptions.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["3 of 14 phases unspecified — likely P2/P3 data collection phases skipped due to table being always empty at rest"]
  }
}
</JUDGE_VERDICT>
