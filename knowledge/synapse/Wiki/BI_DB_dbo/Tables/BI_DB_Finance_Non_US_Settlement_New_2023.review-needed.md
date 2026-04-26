# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 — Review Needed

## Tier 4 Items (None)

No Tier 4 items — all columns traced to SP code or upstream wikis.

## Questions for Reviewer

1. **Table name "Non_US" is misleading**: The table contains ALL stocks/ETFs including US instruments (59% of rows by ISIN country). The name appears to be a legacy artifact from when the report was originally designed. Should the wiki note this more prominently?

2. **Provider mapping completeness**: The hardcoded #hedgeServers temp table has 24 entries, but ~18.7% of daily rows have blank Provider. Should the SP be updated to cover missing HedgeServerIDs (35, 500, etc.)?

3. **SettleCloseTime sentinel**: Values of 9999-12-31 23:59:59.997 appear on all sampled rows for SettleCloseTime and SettleCloseTimeUTC. Is this expected for all exchanges, or is the exchange calendar data incomplete?

4. **IsSettled column**: Marked Tier 5 (from Dim_Position wiki). Confirm interpretation: 1 = real asset ownership, 0 = CFD (contract for difference).

5. **Column count discrepancy**: Batch assignment listed 30 columns, but DDL shows 29 columns. Verified against SSDT DDL — 29 is correct.

## Corrections Applied

- None required.

## Cross-Object Consistency

- InstrumentID description matches Dim_Instrument wiki verbatim.
- HedgeServerID description matches Dim_Position wiki verbatim.
- IsDiscounted description matches Dim_Position wiki verbatim.
- IsSettled description matches Dim_Position wiki (Tier 5).
- IsCreditReportValidCB description matches Fact_SnapshotCustomer wiki verbatim.

*Generated: 2026-04-26*
