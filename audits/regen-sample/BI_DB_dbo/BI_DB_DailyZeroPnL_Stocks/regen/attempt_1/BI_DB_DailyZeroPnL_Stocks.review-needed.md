# BI_DB_DailyZeroPnL_Stocks — Review Needed

> Regen attempt_1 | 2026-04-29

## Items Requiring Human Review

### 1. StockIndex source (Tier 3)
- `StockIndex` comes from `BI_DB_dbo.BI_DB_IndexesMapping_Static` which has no upstream wiki.
- Sample values observed: 'US', 'GER30', '' (empty string for some rows), NULL.
- **Question**: What is the authoritative source for stock index classification? Is BI_DB_IndexesMapping_Static maintained manually or via an external feed?

### 2. InstrumentDisplayName table origin ambiguity
- The SP selects `InstrumentDisplayName` without a table prefix in `#Positions` while joining both `Dim_Position a` and `Dim_Instrument i`.
- Attributed to `Dim_Instrument` (Trade.InstrumentMetaData) based on Dim_Instrument wiki entry row 18. Confirm this is correct and that Dim_Position does NOT also contain InstrumentDisplayName.

### 3. Deprecation status
- Table is frozen at 2024-02-09. The wiki notes the successor is `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`.
- **Question**: Should this table be dropped or retained for historical analysis? If retained, should the UC Target remain `_Not_Migrated` or be explicitly marked as `_Deprecated`?

### 4. MifID values
- `MifID` maps to `MifidCategorizationID`. Sample shows values 1, 4, 5.
- No inline dictionary provided because Dim_MifidCategorization wiki was not found in this repo.
- **Review**: Add MifID value mapping (e.g., 1=Retail, 2=Professional, 3=Eligible Counterparty) if known.

### 5. HedgeServerID meaning
- Sample shows HedgeServerIDs: 2, 112, 128. No Dim_HedgeServer wiki was found.
- **Review**: Confirm HedgeServerID lookup table exists and document key values (e.g., 2=?, 112=?, 128=?).

### 6. BI_DB_IndexesMapping_Static
- No wiki exists for this static mapping table. It affects StockIndex values.
- **Action**: Create a wiki for BI_DB_IndexesMapping_Static to elevate StockIndex from Tier 3 to Tier 1.
