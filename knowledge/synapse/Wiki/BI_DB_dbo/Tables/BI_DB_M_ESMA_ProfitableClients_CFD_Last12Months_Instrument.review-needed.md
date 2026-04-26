# Review Needed: BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument

## Tier 4 Items (Needs Verification)

- None. All columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **Customer overcounting**: A customer trading Stocks and Currencies appears in both rows. Is this the intended ESMA reporting granularity, or should there be a "primary instrument" classification?
2. **Same questions as parent table**: Count columns as decimal, retail-only population, IsSettled=0 semantics. See parent review-needed file.

## Cross-Object Consistency

- Shared columns (StartDate through RollOver) have identical descriptions to parent table
- InstrumentTypeID/InstrumentType: values match DWH_dbo.Dim_Instrument convention

## Corrections Applied

- None.
