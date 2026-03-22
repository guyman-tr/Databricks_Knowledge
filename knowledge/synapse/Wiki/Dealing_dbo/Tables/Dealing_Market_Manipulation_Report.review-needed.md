# Review: Dealing_dbo.Dealing_Market_Manipulation_Report

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.6/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "Market Manipulation Report" or "SP_Market_Manipulation_Report" in Confluence for business context on KPI thresholds and report usage |
| ⚠️ PII data | Table contains CID, UserName, Country, Manager, Club, Desk, Region | Confirm access controls restrict this table to the Dealing/Compliance team |
| ⚠️ PositionID always NULL | In current SP, PositionID is not populated in any KPI segment — it appears to be a legacy column from an older version | Confirm whether this column was intentionally deprecated; consider dropping or documenting as unused |
| ⚠️ V_Liabilities undocumented | Equity calculation uses `DWH_dbo.V_Liabilities` which is a view not in the current wiki | Document V_Liabilities (or note it computes Liabilities + ActualNWA per CID per DateID) |
| ⚠️ Equity ≥ $100 filter | Customer universe requires `Liabilities + ActualNWA >= 100` — this excludes very small accounts. Confirm this threshold is still correct | Verify $100 minimum is the current business intent |
| ℹ️ GURU source | Guru PnL uses `BI_DB_CopyDailyData` joined to `BI_DB_CIDFirstDates` — both BI_DB tables. `BI_DB_CIDFirstDates` is documented (see BI_DB_dbo wiki); `BI_DB_CopyDailyData` may not be | Verify BI_DB_CopyDailyData is documented in the BI_DB wiki |
| ℹ️ NOP stocks vs all instruments | #Nop_Stocks uses the same query as #Nop_Instruments without a stocks filter (both SELECT from #All_Positions without an InstrumentType filter) — the stock/non-stock distinction may be a naming artifact | Confirm whether YDay_NOP_Stocks is actually filtered to stocks only |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
