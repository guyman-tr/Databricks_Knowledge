# DWH_dbo.Dim_Instrument — Review Needed

## Items Requiring Human Review

### 1. AssetClass / IndustryGroup Source (Tier 3)
- Columns `AssetClass` and `IndustryGroup` are populated via post-insert UPDATE from `DWH_dbo.Ext_Dim_Instrument_Classification_Static`.
- No upstream wiki exists for this table. The ultimate source of the classification data is unknown — it may come from an external vendor feed or internal taxonomy.
- **Action**: Identify the source of `Ext_Dim_Instrument_Classification_Static` and document it to upgrade these from Tier 3.

### 2. Rankings.StockInfo Data Source
- Columns `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `PlatformSector`, `PlatformIndustry` are sourced from `Rankings.StockInfo.InstrumentData` and `Rankings.StockInfo.Metadata` via staging.
- No wiki exists for the Rankings database. These are likely sourced from an external market data vendor (possibly Xignite or similar).
- **Action**: Confirm the external vendor source for Rankings data.

### 3. ReceivedOnPriceServer Static Persistence
- The `ReceivedOnPriceServer` column uses a two-table pattern: `Ext_Dim_Instrument_ReceivedOnPriceServerCurrent` (refreshed daily) feeds into `Ext_Dim_Instrument_ReceivedOnPriceServerStatic` (accumulates first-seen dates). This means the value persists once set and is never overwritten.
- **Action**: Verify this is the intended behavior and document the "first-seen, never-overwritten" semantic.

### 4. ProviderToInstrument Join Cardinality
- The SP joins `Trade.ProviderToInstrument` without a ProviderID filter. In production, ProviderToInstrument has composite PK (ProviderID, InstrumentID), meaning multiple rows per InstrumentID are possible if multiple providers exist. This could cause row duplication in Dim_Instrument.
- **Action**: Verify whether the staging table is pre-filtered to a single provider or whether duplicates exist.

### 5. Unresolved UC Target
- The UC target `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` was listed but not verified against the Generic Pipeline mapping in this regen harness run.
- **Action**: Confirm UC target exists and is correctly mapped.
