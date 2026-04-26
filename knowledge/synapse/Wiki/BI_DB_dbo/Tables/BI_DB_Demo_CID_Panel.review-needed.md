# BI_DB_dbo.BI_DB_Demo_CID_Panel — Review Needed

## Open Questions

1. **FirstAction CASE logic uses InstrumentID IN (5,6) for Real Stocks/ETFs check, but InstrumentTypeID for other categories.** InstrumentID 5 and 6 are NOT InstrumentTypeIDs — they are specific instruments. Is this intentional (checking for specific instruments like BTC/ETH which had IDs 5/6 historically) or a bug where InstrumentTypeID was intended?
2. The max Reg_YearMonth is 2025-01 — has the External_Marketing_Acquisition_Demo source stopped being populated?
3. IsTradedDemo = 1 for ALL rows. The INSERT only adds CIDs from External_Marketing_Acquisition_Demo which presumably only contains demo traders. Is IsTradedDemo=0 ever expected?
4. Some CIDs have NULL Reg_YearMonth. These appear to be users who traded demo before their registration date was recorded.

## Cross-Object Consistency

- CID description matches DWH_dbo.Dim_Customer wiki for RealCID (Tier 1) ✓
