# Review Needed — DWH_dbo.Fact_CurrencyPriceWithSplit

## Tier 3 Columns Requiring Upstream Wiki Resolution

All 11 passthrough columns from `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` are Tier 3 because:

1. **No upstream wiki exists** for the staging view or its production source. The `_no_upstream_found.txt` marker confirms this.
2. **The staging view DDL is not available** in the SSDT repo (DWH_staging objects are not in the DataPlatform SSDT project), so the ultimate production source database and table cannot be traced.
3. **Column descriptions are grounded in DDL types, SP code behavior, and live data sampling** — not inferred from names alone (Tier 4 is not used).

### Action Items for Human Reviewer

- [ ] **Identify the production source** for `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView`. This likely originates from a PriceLog service database. Once identified, the 11 Tier 3 columns can be upgraded to Tier 1.
- [ ] **Clarify `isvalid` semantics**: The flag has roughly 50/50 distribution (0 vs 1). Is `isvalid = 0` truly "invalid" pricing, or does it indicate a different business state (e.g., market closed, stale quote, pre-market)?
- [ ] **Clarify `ProviderID` values**: Currently only ProviderID=1 is observed. Is this expected for all time, or are there historical periods with other providers?
- [ ] **RateLastEx vs Bid**: In sample data, RateLastEx often equals Bid. Clarify whether RateLastEx is always the last executed rate or the last bid price.
- [ ] **ConvertRateIsBuy NULLs**: 594 NULL conversion rates in April 2026. Determine if these are expected (instruments with no USD path) or indicate a data quality issue.

## SP Version Note

Two versions of the writer SP exist in the SSDT repo:
- `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse` — current version (with ConvertRateIsBuy logic, split history carry-forward)
- `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER` — legacy version (no ConvertRateIsBuy columns in split path, commented-out column references)

The OLD_VER SP appears to be retained for reference but is not the active writer.

## Monitoring SP

`SP_CurrencyPriceExists_For_CHECK` sends email alerts when instruments have open positions but no price data for the previous day. The email-sending code is currently commented out but the detection logic remains active.
