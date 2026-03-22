---
object: Dealing_Monitoring_ADV
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_Monitoring_ADV — Review Notes

## Auto-Generated Flags

- **ADV/MKTcap/SharesOutStanding source**: The SP header doesn't explicitly name the market data source for ADV, MKTcap, and SharesOutStanding. Reviewer: what is the source — Refinitiv, Bloomberg, or a static table?
- **Special-character columns**: 8 columns have `/` or `()` in names. This is intentional for Tableau compatibility but complicates SQL queries. Consider adding a view with sanitized names.
- **29M rows table**: Growing ~several hundred thousand rows per day. No partitioning/archiving strategy documented. Should older rows be compressed or archived?
- **CopyFromLake dependency (Dec 2024)**: The SP now calls SP_Copy_Temporary_Data to load etoro_Hedge_ExecutionLog. If the CopyFromLake job fails, TotalVolumeUnitsLP will be zero or stale.
- **InstrumentTypeID IN (5,6)**: Only Real Stocks + ETFs. CFD stocks and all other asset types are excluded. Is there a separate ADV monitoring for other asset classes?

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
