# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 2.

## Questions for Reviewer

1. **Empty Instrument_Type in Q1 2024**: Early data shows rows with blank Instrument_Type values. Was this due to:
   - Missing Dim_Instrument join conditions?
   - New instrument types not yet classified?
   - A bug in the initial SP run that was later fixed?
   Confirm whether this data should be backfilled or flagged as known bad data.

2. **Market_Value formula**: Confirm that `AmountInUnitsDecimal * RateBid * USD_CR` is the correct market value calculation for all instrument types. Does RateBid represent the closing bid at quarter end, or an intraday snapshot?

3. **Instrument_Type classification completeness**: Are there InstrumentTypeIDs beyond 5, 6, and 10 that should have specific labels instead of falling into 'Other_CFDs' or 'Other'?

4. **Open position definition**: Confirm the exact filter used to identify "open positions" at quarter end — is it `CloseDateID = 0`, `CloseDateID >= End_DateID`, or another condition?

5. **Population scope**: This table aggregates across all FSA Seychelles customers matching the population filter (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3). Confirm this matches the customer set in the sibling `_end` table.

## Corrections Applied

- None required — column count matches DDL (5 columns).

## Tier Summary

- **Tier 2 (5 columns)**: Market_Value, Account_Type_Group, End_DateID, UpdateDate, Instrument_Type

## Reviewer Instructions

1. Investigate empty Instrument_Type rows in Q1 2024 — count and determine if they should be reclassified
2. Validate Market_Value calculation against manual spot checks of known positions
3. Confirm RateBid source timing (end of quarter day close vs snapshot)
