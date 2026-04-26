# BI_DB_dbo.BI_DB_ICF_Report — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **FCA exclusion logic**: The SP excludes cash and real assets from FCA's Total - USD calculation. Is this the current CySEC ICF regulatory requirement, or has it changed since the SP was last updated? The CASE logic only checks for CySEC/BVI/NFA/None to include full assets; FCA gets EquityCFD only.

2. **Column count mismatch**: The DDL has 19 columns, but the orchestrator listed 14. The 5 additional columns (EquityRealFutures, RealFuturesProviderMargin, FuturesLockedCash, EquityStocksMargin, TotalStockMarginLoanValue) were added in 2025. Verify the OpsDB column count is updated.

3. **ECB rate source**: BI_DB_ECB_RateExtractFromAPI — this table is used for the EUR/USD conversion. Confirm this is still the correct/authoritative ECB rate source (vs. Dim_CurrencyPriceDaily or other rate tables).

4. **Monthly-only execution**: The SP has `IF @Date=eomonth(@Date)` guard. This means the SB_Daily trigger fires daily but produces no output for 29-30 days per month. Consider whether this creates OpsDB monitoring noise.

## Reviewer Corrections

None yet.
