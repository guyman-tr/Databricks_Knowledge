# BI_DB_dbo.BI_DB_Mirror_Assets_Allocation — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **Historical retention**: The table is TRUNCATE + INSERT daily, so only yesterday's snapshot exists. Is there a need to keep historical snapshots? BI_DB_rsk_DailyRiskAgg retains the daily time series for risk metrics — does asset allocation also need history?
2. **CopyFund exclusion**: The SP filters to AccountTypeID<>9 (non-CopyFund). Is there a separate table or dashboard for CopyFund asset allocation?
3. **Shared SP**: SP_rsk_AgregatedRisk writes to BOTH BI_DB_rsk_DailyRiskAgg and BI_DB_Mirror_Assets_Allocation. The Mirror_Assets_Allocation portion is at the end of the SP.

## Cross-Object Consistency Notes

- InstrumentType values match DWH_dbo.Dim_Instrument.InstrumentType (6 asset classes).
- BI_DB_PositionPnL is the source for position-level P&L data (referenced but not yet documented).
