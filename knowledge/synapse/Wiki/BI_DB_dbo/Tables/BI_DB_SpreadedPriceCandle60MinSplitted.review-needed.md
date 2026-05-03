# BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted --- Review Needed

## Summary

All 21 columns are Tier 3 (no upstream wiki, no writer SP). The table is dormant since 2024-06-02 and loaded via an external migration pipeline from the production Candle Builder service.

## Items for Human Review

### 1. Production Source Confirmation

- **Issue**: The production source is inferred from Confluence documentation (Candle Builder service, Price:12 / Candles DB on AO-CANDLES-LSN) and the migration staging table (BI_DB_Migration schema). No Synapse writer SP exists.
- **Action**: Confirm with the Market Data team (MDT) whether this table is still actively maintained or has been permanently retired. Last data is from 2024-06-02.

### 2. ProviderID Mapping

- **Issue**: Two ProviderID values exist (0 and 1) but no dictionary or documentation maps these to provider names.
- **Action**: Confirm what ProviderID=0 and ProviderID=1 represent. ProviderID=0 has only 4,349 rows and may be test/fallback data.

### 3. Table Dormancy / Deprecation Status

- **Issue**: No new data since 2024-06-02. The migration scripts in NoDbObjectsScripts (dated 2024-09-16 and 2024-09-22) suggest the table was migrated and potentially archived. A JUNK_ prefix migration table also exists.
- **Action**: Determine whether this table has been superseded by a different price candle source or if the migration pipeline was simply paused. Four downstream SPs still reference it.

### 4. Downstream SP Impact

- **Issue**: Four SPs actively read from this table (SP_DailyNOP_ByInstrument, SP_M_EOMExposures, SP_NOP_LPandClients, SP_Max_NOP). If the table is dormant, these SPs may be returning stale prices.
- **Action**: Verify whether these SPs have been updated to use alternative price sources for dates after 2024-06-02.

### 5. "Spreaded" Naming Convention

- **Issue**: The "Spreaded" prefix in the table name indicates spread-adjusted prices (Ask/Bid split). Confirm whether a non-spreaded equivalent (e.g., T_PriceCandle60Min from Candles DB) exists and whether the spread adjustment is applied at the source or during migration.
- **Action**: Document the relationship between this table and the raw candle tables in the Candles DB.

## Tier Distribution

| Tier | Count | Percentage |
|------|-------|------------|
| Tier 1 | 0 | 0% |
| Tier 2 | 0 | 0% |
| Tier 3 | 21 | 100% |
| Tier 4 | 0 | 0% |

## Upgrade Path

All columns could potentially be upgraded to Tier 1 if the production Candles DB (Price:12) upstream wiki is created or if the Market Data team provides column-level documentation for T_PriceCandle60Min / SpreadedPriceCandle tables.
