# BI_DB_DailyCopyRevenue — Review Needed

**Batch**: 20 | **Generated**: 2026-04-22 | **Reviewer**: Pending

## Tier 4 Items (Unverified — need confirmation)

None. All columns traced to confirmed SP code and upstream DWH sources.

## Questions for Domain Expert / Reviewer

1. **Revenue_Copy additivity across instrument types**: The SP formula `Revenue_Copy = FullCommission_Copy + RollOverFee + TicketFeeByPercent_Real_Crypto + TicketFeeByPercent_CFD_Crypto` is designed so that `Revenue_Copy = SUM(all Revenue_* columns)`. Confirmed in live data. However, if there are InstrumentTypeIDs not covered by any of the 7 named instrument columns (IDs 1, 2, 4, 5/6, 10), their commission would be in `Revenue_Copy` but NOT in any sub-column. Are there active instrument types in copy trading not classified into these 7 buckets? If so, the instrument breakdowns would not add to Revenue_Copy for those instruments.

2. **GuruStatusID=0 meaning**: In the 2026-04-12 sample, the highest-earning PI (CID 10155159, $857.02) has GuruStatusID=0. What does GuruStatusID=0 represent? Is it: non-PI customers who happen to have copiers, a legacy status from before the formal PI program, or a system default? Understanding this affects how to filter for "official" Popular Investors.

3. **Copier population filter applies to copier, not PI**: The IsDepositor=1, IsValidCustomer=1 filter (via #CIDs) applies to the COPIER's CID, not the ParentCID. This means a PI who only has non-depositor copiers would show zero revenue. Is this the intended business definition of copy revenue (only from valid depositor copiers)?

4. **TicketFeeByPercent historical completeness**: `Function_Revenue_TicketFeeByPercent` was added to this SP on 2025-10-26. Do historical Revenue_Real_Crypto and Revenue_CFD_Crypto values before that date need to be backfilled? If the function is date-range-capable, historical rebatching could add crypto ticket fees to pre-2025-10-26 rows.

5. **Missing instrument types in breakdown**: InstrumentTypeIDs like 3 (Currencies?), 7, 8, 9, 11+ are not broken out into named Revenue_* columns. Are there copy trading positions in these instrument types? If yes, their revenue silently accumulates in Revenue_Copy without any named breakdown column.

6. **AccountTypeID=9 meaning**: AccountTypeID=9 appears in the top PI sample. What does AccountTypeID=9 represent? (AccountTypeID=1 is likely Standard/Retail.)

## Potential Data Quality Issues

- **Instrument-type Revenue_ columns may not sum to Revenue_Copy if unusual InstrumentTypeIDs exist**: Filter to standard types (1, 2, 4, 5/6, 10) and verify `Revenue_Copy = Revenue_Real_Stocks + Revenue_CFD_Stocks + Revenue_Real_Crypto + Revenue_CFD_Crypto + Revenue_FX + Revenue_Comm + Revenue_Ind` per row before using breakdowns.
- **Pre-2025-10-26 crypto rows missing TicketFeeByPercent**: Crypto revenue before Oct 2025 does not include TicketFeeByPercent. Time-series comparisons of Revenue_Real_Crypto and Revenue_CFD_Crypto will show an artificial step-up from Oct 2025.
- **Weekend row counts are lower (~500–700)**: This is expected — fewer trades, fewer positions. Not a data quality issue but should not be compared directly to weekday counts without day-of-week normalization.
- **Raw ID columns (GuruStatusID, CountryID, AccountTypeID)**: These require joining to dimension tables. Do not filter on these columns without first verifying current dimension mappings — IDs can be reassigned.

## Correction Log

*(Empty — no corrections yet)*
