# EXW_Wallet.SentTransactions — Review Needed

## 1. Missing Upstream Wiki

- No upstream wiki exists for WalletDB.Wallet.SentTransactions in any known repo (DB_Schema, CryptoDBs, etc.)
- All 8 core columns are Tier 3 (grounded in DDL, SP code, and sample data) rather than Tier 1
- **Action needed**: If a WalletDB wiki is created in CryptoDBs or another upstream repo, re-run documentation to upgrade columns to Tier 1

## 2. Unresolved Dictionary Value

- `TransactionTypeId = 15` appears in the data (141 rows) but has no entry in `EXW_Dictionary.TransactionTypes`
- **Action needed**: Confirm with Wallet team whether this is a new type that needs to be added to the dictionary

## 3. Legacy ETL Columns

- `etr_y`, `etr_ym`, `etr_ymd` are NULL for many recent rows, suggesting these columns are being phased out in favor of `partition_date`
- **Action needed**: Confirm with data engineering whether these columns can be deprecated

## 4. Column Type Observations

- `WalletId` is stored as `varchar(4000)` but contains GUIDs — could potentially be `uniqueidentifier` for consistency with `CorrelationId`
- `BlockchainTransactionId` is `varchar(4000)` — blockchain hashes are typically 64-66 characters; 4000 is significantly oversized
- These are inherited from production schema and are not DWH issues

## 5. Data Freshness

- `SynapseUpdateDate` is NULL for older rows (roughly pre-2022), indicating this metadata column was added to the pipeline after initial historical load
- The Generic Pipeline uses Append strategy, so historical rows were never backfilled with this timestamp
