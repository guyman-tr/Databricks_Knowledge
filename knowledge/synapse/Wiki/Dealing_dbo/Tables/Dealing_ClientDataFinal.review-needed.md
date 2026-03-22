---
object: Dealing_ClientDataFinal
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientDataFinal — Review Notes

## Auto-Generated Flags

- **÷5 for daily averages**: AvgDailyTrades and AvgUniqueCIDsPerDay are divided by 5 (business days). If a week has a bank holiday, averages will be overstated for the instrument on that day. Is this intentional?
- **InstrumentTypeID filter (4,2,1)**: Stocks, Indices, Commodities only. FX (type 5/6?), Crypto, ETFs are excluded. Confirm this is intentional scope for the Dealing dashboard.
- **percentage_of_total**: Reviewer to confirm denominator — is it total volume for the country across all instruments in InstrumentTypeID (4,2,1) only, or all instruments?
- **CopyFromLake dependency**: SP calls SP_Copy_Temporary_Data for etoro_History_PositionChangeLog. If this copy fails, percentageOfChanged/avgStopRateChange/avgLimitRateChange will be NULL or stale.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
