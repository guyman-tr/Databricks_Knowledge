# Review Notes — Dealing_dbo.Dealing_FactSet_NewPIs_History

**Status**: ⚠️ STALE — FactSet feed stopped June 2024

## Items Requiring Human Review

1. **Feed discontinuation confirmed?** DailyLastSentDate and UpdateDate both show 2024-06-04/2024-06-05 for all active PIs. Was this a planned decommission or an unexpected stoppage? Is there a replacement feed?

2. **TRUNCATE pattern risk**: The SP truncates and replaces the entire table on each run — if the feed were ever restarted, a failed run would leave the table empty. Confirm this is acceptable.

3. **HistorySendFlag logic**: `HistorySendFlag=1` means "history hasn't been sent yet." After a successful send, this flag should be cleared. Verify the flag management process is still maintained even with the feed stopped.

4. **Gold parquet source**: `Gold/Dealing/FactSet_stg/FactSet_PositionPnL_stg/*.parquet` — confirm this lake path still exists and was part of the same decommission as the FactSet feed.

5. **V_Liabilities risk score ladder**: The 10-tier risk score breakpoints (e.g., <0.0011=1, ≥0.0475=10) are hardcoded in the SP — if V_Liabilities StandardDeviation semantics changed, the tiers may be mis-calibrated.
