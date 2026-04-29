# Review Needed: BI_DB_dbo.External_Price_History_LastPriceBeforeClose_Range

## Tier 4 Items Requiring Human Verification

1. **PriceType values (Tier 3)**: Inferred PriceType=1 as forex/crypto and PriceType=2 as standard instruments based on SourceID NULL correlation and data distribution. Needs confirmation from Price team (MDT).
2. **SourceID values (Tier 3)**: SourceID 4, 6, 7 inferred as primary/secondary/tertiary price providers. Actual provider names unknown — confirm with Market Data team.
3. **All 17 business columns (Tier 4)**: No upstream wiki exists for Price.History.LastPriceBeforeClose. Column descriptions are inferred from column names, data patterns, and the pricing domain context. Descriptions should be validated against Price DB documentation if/when it becomes available.
4. **BidSpreaded vs Bid**: In sampled data, many rows show BidSpreaded = Bid (zero spread at close). Confirm whether this is expected behavior or indicates that spread is not applied at close.
5. **USDConversionRate = 1.0 pattern**: Observed for both USD instruments AND some non-USD instruments (SourceID=4). Verify whether all SourceID=4 instruments are truly USD-denominated or if conversion is handled elsewhere.

## Questions for Reviewer

- Is this table consumed by any downstream processes not visible in the SSDT repo (e.g., Databricks notebooks, PowerBI reports, external exports)?
- Why does this table use DROP + COPY INTO instead of an external table definition? Is there a plan to migrate to a proper external table?
- Should the `InsretDate` typo be corrected in the production DDL?

## Cross-Object Consistency

- InstrumentID: FK to DWH_dbo.Dim_Instrument — no description conflict (Dim_Instrument uses Tier 1 from Trade.Instrument, this table uses Tier 4 from Price.History.LastPriceBeforeClose).
