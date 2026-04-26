# Review Needed: BI_DB_dbo.BI_DB_ABook_Exposure

**Generated**: 2026-04-23
**Quality Score**: 7.0/10
**Status**: NEEDS REVIEW — empty table, no writer SP, source system unknown

---

## Tier 4 Items

None — all 17 columns are Tier 3. The ABook hedging domain provides sufficient context for column semantics via column names and related table schemas. No all-NULL or completely opaque columns.

## Open Questions

1. **What populated this table?** No writer SP in SSDT BI_DB_dbo; not in OpsDB. Was this fed by:
   - An on-premises SQL Server job or SSIS package from the ABook hedging system?
   - A now-deleted Synapse SP?
   - A real-time feed from the hedging engine via Linked Server or Azure Service Bus?

2. **Relationship to BI_DB_ABook_Exposure_History**: The History table has the same schema (same columns, same types) but is clustered on DATE instead of HedgeServerID. Is `BI_DB_ABook_Exposure` the current-state snapshot and `BI_DB_ABook_Exposure_History` the rolling daily archive? Or are they separate feeds?

3. **Why superseded by BI_DB_ABook_Exposure_NOPHedged?** The NOPHedged table adds `LiquidityAccountID`, `LiquidityAccountName`, `InstrumentIDToHedge`, `InstrumentID_Final` and removes the `_unhedged` columns. What business change drove this schema evolution?

4. **NOPHedged semantics**: Is `NOPHedged` strictly `NOP_unhedged − NOP`, or does it include only successfully executed hedge orders? Are there cases where `NOPHedged > NOP_unhedged` (over-hedging)?

5. **Should this table be decommissioned?** Given `BI_DB_ABook_Exposure_NOPHedged` is the active operational successor, should `BI_DB_ABook_Exposure` and `BI_DB_ABook_Exposure_History` be dropped or retained for historical context?

## Corrections

- If the source system is identified, upgrade column tiers to Tier 2
- If NOPHedged relationship to NOP_unhedged and NOP is confirmed (NOP = NOP_unhedged − NOPHedged), note this as a verified business rule in Section 2

## Reviewer Instructions

1. Check with the Market Risk / ABook team (or whoever owns the hedging exposure reporting) for the original feed mechanism
2. Verify the NOP = NOP_unhedged − NOPHedged identity with a risk analyst
3. Confirm whether `BI_DB_ABook_Exposure_History` is the historical companion and what the loading cadence was
4. Determine decommission status given the active BI_DB_ABook_Exposure_NOPHedged successor
