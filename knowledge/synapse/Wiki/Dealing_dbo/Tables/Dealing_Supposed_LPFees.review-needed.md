# Review Notes — Dealing_dbo.Dealing_Supposed_LPFees

**Status**: STALE ⚠️ (~30 months stale; last data 2023-09-11)

## Items Requiring Human Review

1. **No writer SP in SSDT**: No stored procedure exists in the Dealing_dbo SSDT repository that writes to this table. The ETL pipeline has been lost or removed. Confirm whether this table was manually populated, sourced from a non-SSDT system, or is permanently abandoned.

2. **Fee calculation methodology unknown**: Without the writer SP, the formula for computing `Fee`, `FeeUSD`, and `TotalCommission` cannot be verified. If historical data needs to be validated or reproduced, the original calculation logic must be located elsewhere.

3. **`TotalCommission` data quality**: Observed samples show `TotalCommission` is mostly NULL or zero. Confirm whether this column was ever populated meaningfully or was always sparse.

4. **REPLICATE distribution at 603K rows**: Table uses REPLICATE distribution (replicates full table to all compute nodes). At 603K rows this is larger than typical REPLICATE targets and may consume significant memory. Assess whether redistribution to HASH or ROUND_ROBIN is warranted if the table is ever revived.

5. **LP naming convention**: `LP` column contains short codes (e.g., 'IB', 'SAXO', 'JP') with no FK to a reference table. Confirm the full mapping and whether 'JP' means JPMorgan, 'IB' means Interactive Brokers, etc. for documentation accuracy.

6. **Decommission decision**: Table has been stale ~30 months with no active ETL. Confirm whether this table should be formally decommissioned/dropped or retained as a historical archive.
