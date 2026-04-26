# BI_DB_dbo.BI_DB_DailyGain_History — Review Needed

## Tier 3 Items (All Columns)

All 17 columns are Tier 3 (data observation + schema inference). The source is the Rankings Bronze data lake layer — no upstream production wiki exists for the Rankings service's internal calculations.

**Reviewer action needed**:
1. Confirm the business meaning of `ID` — assumed to be Dim_Customer.ID (GUID) based on SP_PI_Gain's JOIN. Verify this is correct and not a separate Rankings-specific identifier.
2. Confirm the equity decomposition formula: Equity = Cash + Investment + PnL. This is inferred from column naming patterns and observed data, not from code.
3. Confirm the Gain column is a percentage (not decimal). SP_PI_Gain uses `1 + Gain/100` which supports this, but the Rankings calculation source is opaque.
4. The extreme gain range (-49,800 to 401,200) suggests outliers or edge cases. Verify whether these are valid or data quality issues.
5. HasTradingActivity NULL semantics are unclear — ~28% of rows are NULL. Is this "not evaluated" or "unknown"?

## Data Quality Observations

- PositiveCashFlows NULL for 92% of rows — most users have no deposits within a month
- NegativeCashFlows NULL for 99% of rows — withdrawals are rare
- StartInvestment/StartPnL NULL for 57% — users with cash-only accounts or no open positions
- AdjustedCash is never NULL (always 0.0000 when no adjustment needed)

## Open Questions

1. What is the Rankings service that produces MonthlyGainAnon? Is it the Social Trading / CopyTrader ranking engine?
2. Is the `DailyGain` staging table (ROUND_ROBIN HEAP) intentionally auto-created and dropped each run, or is this a legacy pattern?
3. Does the within-month overwrite pattern mean mid-month historical snapshots are permanently lost?
4. SP_Create_Rankings_History_MonthlyGainAnon_Range uses dynamic SQL with `AUTO_CREATE_TABLE = 'ON'` — is the schema guaranteed stable across lake partitions?

## Cross-Object Consistency

- ID → Dim_Customer.ID: confirmed by SP_PI_Gain JOIN pattern
- No other DWH wiki documents this same Rankings source, so no cross-object consistency conflicts
