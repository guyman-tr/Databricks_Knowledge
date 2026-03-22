# Review: Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.8/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "ManipulationReport CID" or "SP_ManipulationReport_RealStocks" in Confluence for additional regulatory context |
| ⚠️ PII data classification | Table contains CID, UserName, Country, Manager — customer-level PII | Verify data access controls are in place; confirm this table is restricted to Dealing/Compliance team only |
| ⚠️ PercentOfAvg30Days definition | `AvgDailyOpen` uses `OpenVolume30Days / 30` — "30 working days" trailing. The exact method for counting working days (skip weekends? skip holidays?) was not verified | Confirm the 30-day average uses trading days only |
| ℹ️ No KPI column | Unlike the instrument-level parent table, this CID table has no KPI column — it uses its own flagging criteria (PercentOfTotalTrades > 0.5 OR PercentOfAvg30Days > 2) independent of the 8 instrument-level KPI types | Confirm whether compliance team uses both tables together or independently |
| ℹ️ IsPartialCloseChild filter | NumberOfTrades excludes `IsPartialCloseChild=1` rows (partial close children). Volume and Units do NOT have this filter — they include all position flow including partial closes | Verify this asymmetry is intentional for trade counting purposes |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
