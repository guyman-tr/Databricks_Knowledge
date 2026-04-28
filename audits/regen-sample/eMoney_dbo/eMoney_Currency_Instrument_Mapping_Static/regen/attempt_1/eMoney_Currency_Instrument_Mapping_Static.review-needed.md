# Review Needed: eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

## Summary

Static reference table with no writer SP and no upstream wiki. All 10 columns assigned Tier 3 (grounded in DDL + live data evidence).

## Items for Human Review

### 1. Production Source Unknown

No writer SP was found in the SSDT repo. All 145 rows share UpdateDate = 2022-11-21 14:12:06.137, suggesting a one-time manual INSERT or script-based load. The original data source (e.g., a production instrument/currency configuration system) could not be traced.

**Action**: Confirm whether this table was loaded from a known production system or manually assembled. If the source is known, update the lineage and potentially upgrade columns to Tier 1 or Tier 2.

### 2. No UC Target

This table does not appear in the Generic Pipeline mapping (`_generic_pipeline_mapping.json`). It has no Unity Catalog target.

**Action**: Confirm if this table is intentionally excluded from UC migration or if a mapping is pending.

### 3. Staleness Risk

The table has not been updated since 2022-11-21. Any currencies or instruments added to the platform after this date are missing. Consumer SPs (SP_eMoney_Dim_Account, SP_eMoney_Calculated_Balance, etc.) rely on this table for USD conversion — missing currencies would result in NULL rates.

**Action**: Verify that all currently supported eMoney currencies are present. If new currencies have been added since Nov 2022, this table needs a refresh.

### 4. DWHInstrumentID vs InstrumentID Redundancy

In all 145 rows, `DWHInstrumentID` equals `InstrumentID`. The purpose of maintaining both columns is unclear.

**Action**: Confirm whether these columns are expected to diverge or if one is deprecated.

### 5. Synthetic Instruments Coverage

The table includes eToro-specific token instruments (ETORIAN series, IDs 600–610) and conversion pseudo-instruments (EURUSD_conversion, GBPUSD_conversion, etc.). These may not have valid FX rates in Fact_CurrencyPriceWithSplit.

**Action**: Verify that consumer SPs handle NULL rates gracefully for these instruments.

## Tier Breakdown

| Tier | Count | Columns |
|------|-------|---------|
| Tier 3 | 10 | Currency, CurrencyISO, InstrumentID, InstrumentName, DWHInstrumentID, BuyCurrencyID, SellCurrencyID, BuyCurrency, SellCurrency, UpdateDate |
