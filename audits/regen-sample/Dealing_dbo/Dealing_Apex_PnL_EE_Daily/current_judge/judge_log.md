# Judge Review — Dealing_dbo.Dealing_Apex_PnL_EE_Daily

## Dimension Scores

**Dimension 1 — Tier Accuracy: 7/10**
Sampled 5 columns: Date (Tier 2 ✓), Equity_Start (Tier 2 ✓), Transfers (Tier 2 ✓), UpdateDate (wiki says Tier 4 — WRONG, SP clearly shows `GETDATE()` → Tier 2), Dividends (Tier 2 ✓). 1 mismatch out of 5. UpdateDate is explicitly set as `GETDATE() AS UpdateDate` in the final INSERT at line ~430 of SP_Apex_PnL — there is nothing to "infer."

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns claimed, zero Tier 1 columns expected. All columns originate from unresolved staging tables (`LP_APEX_EXT981_3EU`, `LP_APEX_EXT869_3EU`) or are ETL-computed. No upstream wikis exist for these staging sources. The sibling `Dealing_Apex_PnL_EE` wiki also tags the same columns as Tier 2. Correct classification.

**Dimension 3 — Completeness: 8/10 (9 of 10 checks pass)**
Missing: Section 5 has no ETL pipeline ASCII diagram (5.2). All other checks pass — 8 sections present, 8/8 DDL columns documented, all element rows have 5 cells with tier tags, property table complete, footer has tier breakdown, Section 1 has row count and date range, review-needed sidecar does not list Section 4.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (Dealing/Middle Office/Apex LP), row grain (one row per business day per account), ETL SP (`SP_Apex_PnL`), refresh status (stale), row count (~2,491), history range (2022-07-06 → 2024-06-07), and the operational caveat about staleness. Clearly distinguishes from the WTD sibling.

**Dimension 5 — Data Evidence: 6/10**
Row count (~2,491) and date range are present, plus the specific last-ETL timestamp (2024-06-08 09:19). However, no Phase Gate Checklist is present in the wiki, no NULL-rate distribution data is cited, and no explicit P2/P3 completion markers exist. The data claims appear credible but unverifiable without phase markers.

**Dimension 6 — Shape Fidelity: 7/10**
Numbered sections 1–8 present, tier legend in Section 4, three real SQL queries in Section 7, footer has quality score and tier breakdown. Missing: no phases-completed list in footer, no 5.2 pipeline diagram.

---

## T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

No Tier 1 columns exist in this wiki. All 7 non-Tier-4 columns are correctly tagged Tier 2 (ETL-computed from staging or SP logic). The single Tier 4 column (UpdateDate) should actually be Tier 2.

---

## Top 5 Issues

1. **HIGH — UpdateDate mistagged as Tier 4**: The SP code at the final INSERT clearly shows `GETDATE() AS UpdateDate`. This is Tier 2 (SP code), not Tier 4 (inferred). The `[UNVERIFIED]` prefix is unjustified.

2. **MEDIUM — No ETL pipeline ASCII diagram in Section 5**: The rubric requires a Section 5.2 with a real-name pipeline diagram. The wiki only has a prose summary pointing to the lineage sidecar. The EE_Daily path (`#Equity_Daily` ← `#EquityStart_ApexFiles_Daily` ← `LP_APEX_EXT981_3EU`, `#Transfers_Daily` ← `LP_APEX_EXT869_3EU`, `#Dividends_PerAcc_Daily` ← `#Dividends_ApexFiles_Daily` ← `LP_APEX_EXT869_3EU`) should be diagrammed.

3. **MEDIUM — No Phase Gate Checklist**: Wiki has no explicit P2/P3 phase markers. Data claims (row count, dates) appear in the text but cannot be verified against a checklist.

4. **LOW — Footer missing phases-completed list**: The golden shape expects something like `Phases: P1 ✓ P2 ✓ P3 ✓` alongside the quality score. Only tier counts and sub-scores are present.

5. **LOW — Lineage sidecar is thin**: The lineage file is only 10 lines and defers entirely to the EE sibling's lineage. While the objects share a writer SP, the daily-specific temp table chain (`#Equity_Daily`, `#Transfers_Daily`, `#Dividends_PerAcc_Daily`) deserves its own column-level mapping.

---

## Regeneration Feedback

1. Re-tag **UpdateDate** as `(Tier 2 — SP_Apex_PnL)` — remove `[UNVERIFIED]` prefix; cite `GETDATE()` at insert.
2. Add a **Section 5.2 ETL pipeline ASCII diagram** showing the daily-specific temp table chain: `LP_APEX_EXT981_3EU` → `#EquityStart/End_ApexFiles_Daily` → `#Equity_Daily`; `LP_APEX_EXT869_3EU` → `#Transfers_Daily` + `#Dividends_PerAcc_Daily`; all merging via FULL OUTER JOIN into final INSERT.
3. Add a **Phase Gate Checklist** section with explicit P2/P3 markers (or mark them skipped if live queries were not run).
4. Add **phases-completed** to the footer line.
5. Expand the **lineage sidecar** with a column-level source mapping table specific to EE_Daily (even if it mirrors EE, the daily temp tables differ).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL_EE_Daily",
  "weighted_score": 7.40,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged as `[UNVERIFIED] (Tier 4 — inferred)` but SP_Apex_PnL explicitly sets `GETDATE() AS UpdateDate` in the EE_Daily INSERT. Should be `(Tier 2 — SP_Apex_PnL)`."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "No ETL pipeline ASCII diagram (Section 5.2). The daily-specific temp table chain (#Equity_Daily, #Transfers_Daily, #Dividends_PerAcc_Daily from LP_APEX_EXT981_3EU and LP_APEX_EXT869_3EU) is not visualized."
    },
    {
      "severity": "medium",
      "column_or_section": "Phase Gate Checklist",
      "problem": "No Phase Gate Checklist present. Data evidence claims (row count ~2,491, date range, last ETL timestamp) cannot be verified against explicit phase completion markers."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer is missing a phases-completed list (e.g., 'Phases: P1 ✓ P2 ✓ P3 ✓'). Only tier counts and sub-scores are present."
    },
    {
      "severity": "low",
      "column_or_section": "Lineage sidecar",
      "problem": "Lineage file is 10 lines and defers entirely to the EE sibling. The daily-specific temp table chain deserves its own column-level mapping table."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as `(Tier 2 — SP_Apex_PnL)` citing GETDATE() at insert — remove [UNVERIFIED]. (2) Add Section 5.2 ETL pipeline ASCII diagram showing LP_APEX_EXT981_3EU → #EquityStart/End_ApexFiles_Daily → #Equity_Daily and LP_APEX_EXT869_3EU → #Transfers_Daily + #Dividends_PerAcc_Daily → FULL OUTER JOIN → final INSERT. (3) Add Phase Gate Checklist section with explicit P2/P3 markers. (4) Add phases-completed to footer. (5) Expand lineage sidecar with column-level source mapping specific to the daily path.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
