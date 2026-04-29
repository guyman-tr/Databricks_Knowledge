# BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB — Review Needed

## Questions for Reviewer

1. **"RoundeUnits" typo**: Column name missing 'd'. SP code says `RoundedUnits` but DDL says `RoundeUnits`. Should this be fixed?
2. **ClosePositionReasonID 10**: What exactly is reason ID 10? The SP includes 9 (Hierarchical Close) and 10 — confirm the second reason type.
3. **InstrumentTypeID filter**: Only (5, 6) = stocks and ETFs. Are there other instrument types settled through Apex that should be included?
4. **IsSettled filter**: `dp.IsSettled=1` — does this mean T+1/T+2 settlement completed, or something else?

## Cross-Object Consistency Notes

- This table pairs with BI_DB_US_Apex_Stocks_Activity_Apex for reconciliation.
- Both tables use the same "Recieved"/"Delivered" category values and same SP.
