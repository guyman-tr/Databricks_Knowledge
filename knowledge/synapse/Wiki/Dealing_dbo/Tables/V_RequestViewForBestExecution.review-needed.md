# Review Notes — Dealing_dbo.V_RequestViewForBestExecution

**Status**: Active ✅ (view over live staging tables)

## Items Requiring Human Review

1. **Leg 1 24-hour limit**: The RequestExecutionLog JOIN condition `AND REL.RequestTime >= DATEADD(DAY,-1,GETDATE())` is placed on the LEFT JOIN, not the main WHERE clause. This means the time filter only applies to the join condition — it does NOT filter the RequestExecutionLog rows themselves. Verify whether all RequestExecutionLog rows appear (no date filter) or only 24h rows appear. The intent may be a WHERE clause bug.

2. **Historical best execution reporting**: With Leg 1 limited to 24h, this view cannot support historical best execution audits. Confirm whether there is a separate historical source for best execution regulatory reporting.

3. **HedgeExecutionModeID=3**: This mode is excluded from Leg 2 (EMS). Confirm what mode 3 represents and whether it should genuinely be excluded from best execution analysis.

4. **UNION dedup**: Using UNION (not UNION ALL) implies RequestIDs could overlap between the two legs. Confirm whether RequestExecutionLog and EMSOrders can share RequestIDs, and whether deduplication is correct if they do.

5. **Staging source freshness**: Both sources are staging tables (eToroLogs). Confirm their ingestion latency — if staging is delayed, the view may show stale execution data.
