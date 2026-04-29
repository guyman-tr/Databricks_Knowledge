# Review Needed: Dealing_dbo.Dealing_IGReconEODHolding

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No pure passthroughs from Tier 1 production sources exist. Upstream `Dealing_Duco_EODRecon` is itself all Tier 2 (SP_DataForDuco). IG side is from LP parquet files (no wiki). |
| Tier 2 | 27 | All columns are ETL-computed via SP_IGRecon (aggregations, ISNULL coalesce, oil multiplier, GBX normalization, diff calculations) |
| Tier 3 | 1 | UpdateDate (GETDATE()) |
| Tier 4 | 0 | -- |

## Items for Human Review

### 1. #MarketNameToID Hardcoded Mapping Maintenance
The SP contains a hardcoded `#MarketNameToID` temp table mapping IG market names to eToro InstrumentIDs. This mapping covers ~40 instruments (indices, commodities, forex, specific equities). If IG adds new instruments or changes market names, this mapping may become stale. Consider whether this should be externalized to a configuration table.

### 2. IG-Only Rows with NULL InstrumentID
~997 rows (13%) have NULL `HedgeServerID` and NULL `InstrumentID`, meaning the IG position could not be matched to an eToro instrument. These may represent instruments traded on IG but not tracked in eToro's Dim_Instrument (or not resolvable via ISIN/MarketName mapping). Verify whether these are expected or represent data quality issues.

### 3. Exchange Column Default Value
For IG-only rows, `Exchange` defaults to `'0'` (from `ISNULL(tse.Exchange, 0)` where 0 is cast to varchar). This is not a meaningful exchange name. Consider whether this should be NULL instead.

### 4. Oil Multiplier Scope
The Oil ×100 multiplier only applies to `'Oil - US Crude ($1)'`. If other oil-related instruments are added to IG in the future, the multiplier logic may need updating.

### 5. Dash Character Fix (SR-338909)
Adar's 2025-10-23 fix loads `LP_IG_PS_EODPositions_daily` from parquet and re-inserts into the main table with CASE expressions to handle dash characters (`"-"`) in numeric columns. This suggests IG files occasionally contain dashes instead of numeric values. Monitor for data quality issues in IG_Rate, IG_LocalAmount, and related columns.

### 6. No Downstream Consumers Documented
The bundle does not show any tables that read FROM Dealing_IGReconEODHolding. It may be a reporting endpoint. Confirm whether any dashboards or downstream processes consume this table.
