# Review Needed: BI_DB_dbo.Dealing_Unrealized_CryptoRebate

## Items Requiring Human Verification

### HIGH Priority

1. **5-month history gap vs realized table** — `Dealing_CryptoRebate` spans 49 months (2022-03-31) but this table spans only 44 months. Confirm: when was the unrealized calculation added to `SP_M_CryptoRebateDiamond`? The gap suggests it was added after the realized path, but the exact date is not in the SP change log. Check git history for the SP.

2. **IsCreditReportValidCB and IsGermanBaFin asymmetry** — These two columns are in the unrealized table but NOT in the realized table. Confirm whether this was intentional (finance/audit needed these flags for unrealized reporting specifically) or an oversight that should be backfilled to the realized table.

3. **France exclusion (same as realized table)** — The SP change log says "Adding France country" (2025-10-20) but France is not in the WHERE clause exclusion list. Same issue as in Dealing_CryptoRebate.

### MEDIUM Priority

4. **IsCreditReportValidCB semantics in unrealized context** — In the realized table this flag is not present. In the unrealized table it's sourced from `Fact_SnapshotCustomer.IsCreditReportValidCB` at month-end. Confirm whether this flag is used to filter the unrealized rebate calculation downstream (e.g., only paying unrealized rebates to clients with valid credit reports) or is purely informational.

5. **IsGermanBaFin logic** — Uses `V_GermanBaFin` view joined on `CID = vbf.CID AND vbf.DateID = @MonthEndDateID`. Confirm: does this view capture the BaFin status on the month-end date, or is it a point-in-time snapshot? And what is the business impact of IsGermanBaFin=1 for the rebate program?

6. **ClosedVolume mark-to-market pricing** — The unrealized ClosedVolume uses `Fact_CurrencyPriceWithSplit.BidSpreaded × ConvertRateIsBuy_1`. Confirm this is the correct pricing convention for the hypothetical close valuation (bid price vs. mid price vs. ask price).

### LOW Priority

7. **float type precision** — Same concern as realized table: all volume/rebate columns use `float`. Confirm whether floating-point arithmetic is acceptable for accrual reporting.

8. **TotalRebate in unrealized context** — Is the unrealized TotalRebate used for actual payment decisions (i.e., if a client closes mid-month, is the unrealized rebate carried over to the realized calculation)? Or is it purely an accrual estimate for financial reporting?

## Data Quality Observations

- Diamond members have significantly higher rebate rates in the unrealized table (51% of rows with TotalRebate>0) vs realized (27%). This makes sense: long-term holders accumulate larger unrealized positions over time.
- Average unrealized volumes are ~2x the realized volumes for both tiers, consistent with clients holding positions longer than a single month.
- 37,866 rows for 2026-03-31 vs 5,853 for the realized table — the ~6.5x ratio reflects the proportion of total positions that are still open at month-end.
