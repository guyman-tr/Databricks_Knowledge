# Review Needed: BI_DB_dbo.BI_DB_QSR_Balance_New

## Items for Human Review

1. **StockMargin column**: Added 2025-10-23 by Markos Ch. Confirm which quarters have populated data vs NULL. The SP code shows `CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END` but StockMargin appears in both the balance and volume inserts — verify whether the balance table actually uses it or if it's always NULL here (the #balance temp table sources from #pnlCIDFinal which sources from #RealizedPnLCIDLevel which carries StockMargin from #realized).

2. **RealizedCFDWithBugPre2021Q2**: The SP code shows the bug formula `ISNULL(re.QuarterRealizedPnLRealStocks, 0) - ISNULL(re.QuarterRealizedPnLRealCrypto, 0) - ISNULL(re.QuarterRealizedPnLRealStocks, 0)` — confirm whether this column is still used in any downstream report or if it can be deprecated.

3. **Data freshness**: The table contains data only through Q4-2023 (202304). Confirm whether SP_Q_QSR_New has been run for more recent quarters or if the reporting pipeline has moved elsewhere.

4. **BI_DB_ECB_RateExtractFromAPI**: This upstream table has no wiki. Consider documenting it if ECB rate sourcing is critical for audit purposes.

5. **Sustainability ratio precision**: SP author notes this is approximate (V_Liabilities equity × ratio rather than position-level PnL). Confirm whether finance has accepted this approximation for ongoing regulatory submissions.
