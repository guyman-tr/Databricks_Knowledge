# Review Sidecar — BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 10 columns in DDL, 10 in wiki |
| All columns have tier suffix | ✅ | 9 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | ✅ | SP_Finance_Non_US_Settlement_Report matches OpsDB |
| Sample data reviewed | ✅ | 5 rows — InstrumentName format, regulation values, price calculations consistent |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | BI_DB_PositionPnL dependency | High | This table reads from BI_DB_PositionPnL (another P99 table). SQL-level dependency not in OpsDB. SP also calls UPDATE STATISTICS on PositionPnL before running. |
| 2 | EffectiveEODPrice | Medium | Calculated as Total_Open_$ / Units. When Units = 0, this will produce a division error. Confirm if the SP has safeguards (no evidence of NULLIF/CASE found). |
| 3 | LP reconciliation removed | High | As of April 2022, all LP-side logic was removed. Confirm this table is still actively used for client-side settlement only. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 9 | All business columns |
| Tier 3 | 1 | UpdateDate |
