# Review: Dealing_dbo.Dealing_ApexRecon_Hedging

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.4/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "ApexRecon" or "SP_Apex_Recon" in Confluence for threshold documentation ($50K Over, $5K/-$100K Under) |
| ⚠️ Threshold hardcoding | Over threshold: $50,000; Under threshold: $5,000 individual / $100,000 portfolio — all hardcoded in SP | Confirm thresholds are reviewed periodically; these were set in 2021 and may need updating |
| ⚠️ Dealing_Duco_EODRecon undocumented | Source table `Dealing_Duco_EODRecon` not yet in wiki | Document Dealing_Duco_EODRecon in a future batch before this table's accuracy can be fully confirmed |
| ℹ️ Live data shows NULL Over_Under | Recent rows have NULL Over_Under — this is expected (no discrepancies) | Not an issue; filter `WHERE Over_Under IS NOT NULL` for action items |
| ℹ️ HedgingDiff semantics | 'Yes' means gap UNCHANGED (no correction); 'No' means gap changed | This is counterintuitive naming — "HedgingDiff=Yes" actually means the problem persists. Consider adding a note to downstream dashboards |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. Format:
[RESOLVED] YYYY-MM-DD: <what was corrected>
Or just add corrections as bullet points.
-->
