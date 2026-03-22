# Review: Dealing_dbo.Dealing_Market_Manipulation_Report_FCA

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.2/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Data staleness | Max date in live sample is 2025-07-12 (8+ months behind main table at 2026-03-10) | Confirm whether this table is still actively refreshed or has been replaced/deprecated. Check if SP is still scheduled in OpsDB or batch orchestration |
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "Market Manipulation FCA" or "SP_Market_Manipulation_Report_FCA" in Confluence for regulatory context |
| ⚠️ PII data | Table contains CID, UserName, Country, Manager, Club, Desk, Region | Confirm access is restricted to Dealing/Compliance team |
| ⚠️ No GURU KPIs | GURU_YDay_Profit and GURU_WTD_Profit segments absent vs main table | Confirm this is intentional — does FCA not require Popular Investor surveillance, or was this omitted? |
| ℹ️ Regulation always 'FCA' | All rows have RegulationID=2 = FCA. The Regulation column is constant in this table | Consider whether the column is needed or just structural redundancy with the main table |
| ℹ️ PositionID always NULL | Same as main table — this column is never populated in the SP | Legacy column; no action required unless the column is to be dropped |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
