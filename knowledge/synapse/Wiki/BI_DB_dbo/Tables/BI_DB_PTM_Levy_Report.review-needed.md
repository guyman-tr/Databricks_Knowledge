# Review Needed: BI_DB_dbo.BI_DB_PTM_Levy_Report

## Tier 4 Items

- **PTM Levy threshold**: The GBP 10,000 threshold is hardcoded in the SP. This appears to match the current HMRC/PTM Levy rules but should be verified against the latest regulations.
- **Fact_CurrencyPriceWithSplit InstrumentID=2**: Assumed to be the GBP/USD exchange rate instrument. No upstream wiki exists for this fact table.

## Questions for Reviewer

1. Is InstrumentID=2 in Fact_CurrencyPriceWithSplit definitively the GBP/USD rate? Should be confirmed.
2. The SP description header says "PTM Report for Tax" but the date field says the author date, not the SP description. Who is the business owner of this report?
3. Close positions do NOT have the IsPartialCloseChild=0 filter (unlike opens). Is this intentional?
4. The GBP 10,000 threshold -- is this per the Takeover Panel's current threshold, or is it configurable?

## Confidence Notes

- PositionID, CID, Units are Tier 1 (passthrough from Dim_Position, origin Trade.PositionTbl)
- ISINCode, Instrument Name, Symbol are Tier 2/3 from Dim_Instrument (etoro_Trade_InstrumentMetaData)
- IsSettled is Tier 5 (Expert Review from Dim_Position wiki)
- GBP conversion logic is fully traced from SP code
