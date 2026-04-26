# Review Needed: BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints

Generated: 2026-04-22 | Batch 25 #2

## Tier 4 Items (Needs SME Verification)

None — all column descriptions are Tier 1 or Tier 2.

## Questions for Business SME

1. **IsSettled for overnight fees**: The SP pulls `IsSettled` from `DWH_dbo.Fact_CustomerAction` for overnight fee rows (ActionTypeID=35). In practice, is IsSettled meaningful for overnight fees (e.g., distinguishing overnight fees on stock positions vs. overnight fees on CFD positions), or is it always 0 for overnights?

2. **BI_DB_DDR_Daily_Aggregated dependency**: TotalCashoutFee, TotalDormantFee, and TransferCoinFee are sourced from `BI_DB_DDR_Daily_Aggregated` — a table on the blacklist (deferred from UC migration). What is the UC migration plan for this table, and does it block migration of `BI_DB_Finance_Audit_Auxillary_Datapoints`?

3. **StockMarginOvernightFee start date**: The SP has `AND x.DateID >= 20260216` — this hardcoded date means StockMarginOvernightFee only appears from Feb 2026. Is this a permanent cutoff (data truly only exists from this date) or a soft cutoff that may be extended backward as history is backfilled?

4. **Ticket fee sign convention**: TicketFee and TicketFeeByPercent are stored as negative amounts (`-SUM()`). Is this the finance team's expected convention, or are these values expected to be positive in downstream reporting (requiring re-negation by consumers)?

5. **No downstream SP consumers**: No OpsDB dependency records found for this table. Is it consumed directly by Power BI / finance dashboards, or are there intermediate SPs not captured in OpsDB?

## Data Quality Observations

- **IsSettled = 0 ambiguity**: Both "CFD commission" rows and "non-commission fee" rows have IsSettled = 0. The SP uses `'' AS IsSettled` for fee metrics, which converts to 0 in the int column — identical to CFD commission rows. Callers must filter on `Metric` to distinguish.
- **YearMonth is varchar(10)**: Despite being a 6-character YYYYMM string, the DDL declares it as `varchar(10)`. This is safe but allows out-of-format values. Data observed follows YYYYMM consistently.
- **DDL typo preserved**: The double-l in "Auxillary" appears in both the table name and the SP name and has been present since the original creation (2021). Renaming would require all downstream references to be updated.

## Reviewer Sign-Off

- [ ] IsSettled semantics confirmed for overnight fee rows
- [ ] DDR_Daily_Aggregated UC migration dependency resolved
- [ ] StockMarginOvernightFee historical cutoff confirmed
- [ ] Ticket fee sign convention confirmed with finance team
- [ ] Downstream consumers confirmed
