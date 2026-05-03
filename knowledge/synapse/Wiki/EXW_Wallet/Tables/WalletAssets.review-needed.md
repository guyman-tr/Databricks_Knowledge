# Review Needed: EXW_Wallet.WalletAssets

## Summary

All 10 columns are Tier 3 (grounded in DDL + live data, no upstream wiki available). The `_no_upstream_found.txt` marker confirms no resolvable upstream wiki exists for WalletDB.Wallet.WalletAssets.

## Items for Human Review

### 1. CryptoId Lookup Resolution

- **Issue**: CryptoId (174 distinct values) has no Synapse-side dictionary table. EXW_Dictionary.CryptoCoinProviders maps blockchain providers (Id 1-7), not cryptocurrency types.
- **Action**: Locate the production WalletDB cryptocurrency dictionary and document the CryptoId-to-coin mapping. Top CryptoIds by volume: 1 (593K), 2 (223K), 6 (185K), 21 (172K), 3 (161K).
- **Impact**: Without this mapping, analysts cannot determine which cryptocurrency each row refers to.

### 2. etr_y/etr_ym/etr_ymd Column Population Gap

- **Issue**: ETL partition columns (etr_y, etr_ym, etr_ymd) are populated for historical data (2019-2022 sample) but empty/NULL for recent data (~2025 onwards).
- **Action**: Confirm whether the Generic Pipeline partition strategy changed and whether these columns are still used by downstream processes.
- **Impact**: Any queries relying on etr_* columns for recent data will return no results.

### 3. SynapseUpdateDate NULL for Early Data

- **Issue**: SynapseUpdateDate is NULL for all rows loaded before ~April 2025. Only rows from the daily Append loads after that date have a populated timestamp.
- **Action**: Determine if this is expected behavior (column added later) or a data quality issue.

### 4. WalletId Column Sizing

- **Issue**: WalletId is varchar(4000) but actual values are 36-character GUIDs. This over-sizing may impact storage and JOIN performance.
- **Action**: Consider whether the production schema intentionally uses varchar(4000) or if this is a legacy artifact.

### 5. IsShown = False Records

- **Issue**: Only 66 out of 1,780,223 rows have IsShown = False. This may represent deactivated, hidden, or erroneously flagged assets.
- **Action**: Verify the business meaning of IsShown = False and whether these records should be filtered in downstream analytics.

### 6. Upstream Wiki Gap

- **Issue**: No upstream wiki exists for WalletDB.Wallet.WalletAssets in any documented repository (DB_Schema, CryptoDBs, etc.). All columns are Tier 3.
- **Action**: If a WalletDB wiki is created in the future, re-run documentation to upgrade columns to Tier 1.

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 3 | 10 | Id, WalletId, CryptoId, Occurred, etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date, IsShown |
