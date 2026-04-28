# Review Needed: Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee

## Summary

8 Tier 1 columns (passthrough from upstream wikis), 34 Tier 2 columns (ETL-computed or passthrough from tables without production-level wikis). No Tier 3 or Tier 4 columns.

## Items for Human Review

### 1. UC Target Unknown

The UC (Unity Catalog / Databricks) target for this table is not yet resolved. Confirm whether this table is migrated to Databricks and what the target table name is.

### 2. Dim_Instrument and Dim_ExchangeInfo Columns — Tier 2 vs Tier 1

Columns sourced from `Dim_Instrument` (InstrumentTypeID, InstrumentType, InstrumentName, Exchange) and `Dim_ExchangeInfo` (ExchangeID) are marked Tier 2 because no production-level upstream wiki was available in the bundle for these dimension tables. If Dim_Instrument or Dim_ExchangeInfo wikis become available, these could be upgraded to Tier 1 with their production origins.

### 3. Suspended Instrument List

The SP hardcodes ~26 InstrumentIDs as excluded from fee calculation. This list may need periodic review as instruments are added/removed from the platform. The list is embedded in the SP source, not in a configuration table.

### 4. InstrumentID 62 Special Logic

InstrumentID 62 has special Thursday triple-charge logic (instead of Wednesday for other ExchangeID=1 instruments). This was added in SR-343388 (2025-11-17). Confirm this instrument identity and whether the special logic is still current.

### 5. German Crypto Exemption

CountryID=79 (Germany) long leverage-1 crypto positions are excluded. Confirm whether this exemption is still active or has been modified by regulation changes.

### 6. IsSettled Column Semantics

The Dim_Position upstream wiki marks IsSettled as `Tier 5 — Expert Review`, indicating uncertainty about the exact semantics (1=real asset, 0=CFD). In this table, only CFD positions (IsSettled=0) appear, so the semantic ambiguity is less impactful, but expert review of the upstream definition is still pending.

---

*Generated: 2026-04-27*
