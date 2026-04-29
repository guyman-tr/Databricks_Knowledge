# Review Needed: Dealing_dbo.Dealing_CME_Reporting

## Summary

All 5 columns are Tier 2 (ETL-computed aggregations and date arithmetic). No Tier 1 passthroughs are possible because every column is either an aggregate (COUNT DISTINCT, SUM), a CASE-transformed value, or an ETL timestamp. The upstream wikis (Dim_Position, Dim_Instrument) were used to ground the source column descriptions but no verbatim inheritance applies.

## Items for Human Review

### 1. Instrument List Completeness

The SP hardcodes 24 InstrumentIDs plus a LIKE '%crude oil%' filter. The instrument list has been updated twice (SR-261943, SR-303463). Verify that the current hardcoded list covers all CME-reportable instruments required by the latest regulatory guidance.

### 2. Volume Definition Clarification

Monthly_Volume sums both open-side Volume and close-side VolumeOnClose. Confirm with the Dealing desk whether this bidirectional volume is the intended CME reporting metric, or whether open-only or close-only volume is required.

### 3. Crude Oil Consolidation

All crude oil variants (different expiry dates, WTI sub-types) are consolidated under 'Crude Oil Future'. Confirm whether CME requires per-contract reporting or whether consolidated reporting is acceptable.

### 4. Historical Restatement

Re-running the SP with a newer instrument list would change historical months' data. Confirm whether historical months should be restated when the instrument list changes, or whether they should reflect the list at the time of original execution.

### 5. UC Migration Status

This table is marked `_Not_Migrated`. Confirm whether migration to Unity Catalog is planned or if this remains Synapse-only for regulatory reporting purposes.
