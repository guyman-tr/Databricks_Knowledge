# Review Notes — Dealing_dbo.Dealing_Regime_Flags

**Status**: STALE ⚠️ (~14 months stale; last run 2025-01-19; not in OpsDB)

## Items Requiring Human Review

1. **Not in OpsDB/SB_Daily**: `SP_Regime_Flags()` has no OpsDB entry and is not scheduled in Service Broker. This means the table only updates when manually executed. Confirm whether this is intentional (on-demand only) or an oversight. If it should be scheduled, add to OpsDB with appropriate frequency.

2. **Full history rebuild cost**: Every execution deletes all ~17.9M rows and rebuilds from 2019-01-01. This is a very expensive operation. Confirm whether the full-rebuild pattern is still appropriate or whether an incremental approach (appending recent dates) could be implemented to reduce runtime.

3. **`DailyMeasure1` column purpose**: This column is not clearly labeled in the DDL — appears to store raw NOP or price values for the NOP Change / Price Change Rate measure types. Confirm its exact semantic and whether it should be renamed for clarity.

4. **Weekend handling for non-Crypto**: Weekends are excluded from rolling window calculations for non-Crypto instruments (DATEPART(dw) filter). Confirm this is still the correct treatment for newly added instrument types (e.g., indices, commodities).

5. **Hardcoded Z→percentile table**: The `#Z` lookup table (0.0–3.0 in 0.1 steps, hardcoded in the SP) approximates the normal distribution CDF. This means any Z-score not in the lookup is rounded to the nearest 0.1. Confirm this precision is sufficient for the intended use cases.

6. **Staleness remediation**: Data is ~14 months stale as of March 2026. Confirm whether a re-run is planned and whether Dealing_DealingDashboard_Clients (the primary source) is current enough to produce valid results.
