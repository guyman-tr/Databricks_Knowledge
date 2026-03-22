# Review Notes — Dealing_dbo.Dealing_PriceLocks

**Status**: Active ✅

## Items Requiring Human Review

1. **Column typo `TotalInFist15Min`**: The DDL has `TotalInFist15Min` (should be `TotalInFirst15Min`). This typo is preserved in the live table — any schema migration or documentation must use the exact misspelled name. Confirm whether a DDL rename is planned.

2. **Two OpsDB entries**: Both the original SP and the migrated SP appear in OpsDB Priority 0 / SB_Daily. Confirm only one is active and the other should be removed.

3. **Details field parsing**: `minVolatility_Pips`, `maxVolatility_Pips`, `SpreadLockThresholdPercentage`, `minTimeOut_MS`, `maxTimeOut_MS` are all parsed from a semi-structured `Details` text field. If the event log format changed, these columns may silently return NULL — verify parsing is still valid.

4. **Market schedule dependency**: `External_CalendarDB_Market_MergedDailySchedules` changed (SR-258289). Confirm the new schedule table produces correct DuringSession/time-window results for all instrument types including crypto.

5. **Duration units**: `TotalDuration` is in milliseconds — confirm all BI reports and dashboards consuming this column convert to seconds/minutes correctly.
