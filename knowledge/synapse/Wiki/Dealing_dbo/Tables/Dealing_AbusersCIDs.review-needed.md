# Review: Dealing_dbo.Dealing_AbusersCIDs

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 8.2/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "AbusersCIDs" or "SP_AbusersCIDs" in Confluence for business context on the $100 profit threshold and 80% success rate definition |
| ⚠️ PII data | Table contains CID | Confirm access is restricted to the Dealing/Compliance team |
| ⚠️ No customer enrichment | Unlike AbuseAPI, this table stores only CID — no UserName, Country, Manager | Users querying this table must join to Dim_Customer or Dim_Country for customer context. Consider if this is intentional design |
| ℹ️ Sentinel rows | Table uses same LEFT JOIN Dim_Date sentinel pattern as Dealing_AbuseAPI | Filter `WHERE CID IS NOT NULL` to exclude empty sentinel rows |
| ℹ️ Stocks only | Hard filter: InstrumentTypeID=5 (Stocks). Other asset types (Crypto, ETFs, etc.) are excluded from this detection | Confirm whether ETFs (TypeID=6) should also be included given ESMA/FCA short-duration trading regulations |
| ℹ️ ClosePositionReasonID=0 | Only manual closes are included. Platform-forced closes (stop loss, take profit) are excluded | Confirm this exclusion is correct for the intended abuse pattern |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
