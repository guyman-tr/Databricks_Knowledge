# Review Needed: EXW_Wallet.CryptoTypes

## Summary

All 31 production-origin columns are Tier 3 (no upstream wiki located for WalletDB.Wallet.CryptoTypes). Descriptions are grounded in DDL structure, data types, and live data sampling (174 rows).

## Items for Human Review

### 1. No Upstream Wiki Available

- **Issue**: The production source WalletDB.Wallet.CryptoTypes has no documented wiki in the CryptoDBs repository or any other upstream wiki repo. All 31 production columns are Tier 3.
- **Action**: If a wiki is created for WalletDB.Wallet.CryptoTypes in the future, re-run the pipeline to upgrade columns to Tier 1.
- **Marker**: `_no_upstream_found.txt` is present in the regen folder.

### 2. Status Column Values

- **Issue**: Status has values 1 (13 rows) and 3 (161 rows). No value 2 observed. The meaning of these codes is inferred from correlation with AssetTypeId and CryptoCategoryName but not confirmed by documentation.
- **Action**: Verify Status code meanings with the Wallet team. Are there other possible values (e.g., 0 = disabled, 2 = deprecated)?

### 3. CryptoActivityStatus Values

- **Issue**: CryptoActivityStatus has values 2 (173 rows) and 3 (1 row, XRP). Meaning inferred as 2 = active, 3 = limited/restricted, but not confirmed.
- **Action**: Confirm CryptoActivityStatus code definitions with the Wallet team.

### 4. CryptoCategoryName Case Inconsistency

- **Issue**: 'baseCrypto' (10 rows) vs. 'BaseCrypto' (2 rows) — inconsistent casing for the same logical category.
- **Action**: Determine if this is a data quality issue in the production source or intentional.

### 5. AssetTypeId Lookup

- **Issue**: AssetTypeId values 1 and 2 are not linked to a known dictionary or dimension table. Meanings inferred from data patterns.
- **Action**: Verify if a WalletDB.Dictionary.AssetTypes or similar lookup table exists in production.

### 6. No Writer SP

- **Issue**: No Synapse stored procedure writes to this table. It is loaded directly by the Generic Pipeline (Override, daily) from WalletDB.Wallet.CryptoTypes. This is confirmed by SP scan — all 18 referencing SPs are readers.
- **Action**: No action needed. This is the expected pattern for Bronze-layer reference tables.
