# Review Notes — Dealing_dbo.StocksOverrideRateLog

**Status**: Active ✅ (daily, Priority 0, SB_Daily)

## Items Requiring Human Review

1. **NULL represents Active**: `EndTime IS NULL` means the override is currently active (the original `9999-12-31 23:59:59.9999999` sentinel is converted to NULL in ETL). This is a non-obvious convention — confirm that all BI reports and downstream consumers correctly interpret NULL EndTime as "still active" rather than "unknown end date".

2. **Multiple rows per instrument per date**: An instrument with both an active override and a historical (expired) override will appear multiple times on the same Date. Confirm that all queries joining to this table correctly handle this fan-out (e.g., filter `WHERE Status = 'Active'` when wanting current rates only).

3. **Source from External staging tables**: Data is pulled from `Dealing_staging.External_Etoro_Dictionary_InterestRateOverride` and `External_Etoro_History_InterestRateOverride`, which are externally sourced (production eToro Dictionary DB). Confirm that the refresh timing of these External tables is guaranteed to be complete before `SP_StocksOverrideRateLog` runs in the daily SB schedule.

4. **`Total_Buy` / `Total_Sell` computation**: These are defined as `InterestRateBuy + MarkupBuy` and `InterestRateSell + MarkupSell`. Confirm that the sign conventions are correct (e.g., whether InterestRate can be negative for some instruments and whether that produces the expected Total).

5. **Coverage scope**: Table only covers instruments with override configurations — instruments using standard rates have no rows here. Confirm whether downstream consumers are aware that absence of a row implies the standard (non-override) rate applies.
