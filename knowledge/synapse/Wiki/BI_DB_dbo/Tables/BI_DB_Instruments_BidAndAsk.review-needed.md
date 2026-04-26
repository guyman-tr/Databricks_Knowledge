# BI_DB_dbo.BI_DB_Instruments_BidAndAsk — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **Low stock count**: Only 2 stocks appear vs 370 crypto instruments. Is this because Dim_GetSpreadedPriceCandle60MinSplitted doesn't carry stock candles, or is the price feed filtered?

2. **ISINCode/CUSIP defaulting to '0'**: The SP uses ISNULL(ISINCode, 0) which coerces NULL to string '0'. This is unusual — downstream consumers need to check for '0' instead of NULL.

## Reviewer Corrections

None yet.
