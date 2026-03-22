# Review: Dealing_dbo.Dealing_AbuseAPI

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.8/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "AbuseAPI" or "SP_AbuseAPI" in Confluence for business context on the $5,000 and 1-second thresholds |
| ⚠️ PII data | Table contains CID, Country, Region | Confirm access is restricted to the Dealing/Compliance team |
| ⚠️ Sentinel rows | Recent live data shows all-NULL rows except UpdateDate — this means no customers triggered the API abuse pattern | These NULL rows are expected (sentinel insert); do not interpret as table being empty or broken. Include `WHERE CID IS NOT NULL` in all queries |
| ⚠️ InstrumentType-level burst detection | The 3-position burst detection groups by InstrumentType (e.g., 'Stocks'), not InstrumentID — a customer opening 3 different stocks in 1 second is flagged | Confirm whether the business intent is instrument-type-level or instrument-level detection |
| ℹ️ $5,000 threshold | DailyNetProfit ≥ $5,000 filter is hardcoded. This was set in 2019 — may be outdated relative to current account sizes | Verify the threshold is still appropriate |
| ℹ️ 3 rows per burst | Each burst produces 3 output rows (one per position). There is no burst_id to group them — reconstructing which 3 positions form a burst requires comparing PositionID values or timestamp proximity | Consider whether a burst grouping ID would be useful for downstream analysis |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
