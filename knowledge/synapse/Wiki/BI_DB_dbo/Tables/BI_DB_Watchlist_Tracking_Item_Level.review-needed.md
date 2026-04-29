# BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Row count**: Placeholder — run `SELECT COUNT(*) FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level` to populate the property table.
2. **Partial close children exclusion**: Dim_Position filtering excludes MirrorID=0 partial close children. Confirm this is the correct filter for instrument trade extraction.
3. **ActionTypeID=17 scope**: Copy trades are identified via Fact_CustomerAction ActionTypeID=17 (register new mirror). Verify no other ActionTypeIDs (e.g., copy portfolio) should be included for the User item population.
4. **FunnelFromID vs First5Actions**: The funnel attribution logic uses both Dim_Customer.FunnelFromID and BI_DB_First5Actions. Clarify which takes precedence or how they interact.
5. **Paired cluster dependency**: This table must be written before BI_DB_Watchlist_Tracking_High_Level. Confirm the SP enforces this ordering (not reliant on parallel execution).
6. **Desk mapping**: Region-to-Desk mapping from Dim_Country — is this a static lookup or a separate mapping table? Confirm the mapping logic.
