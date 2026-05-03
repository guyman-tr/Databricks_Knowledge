# EXW_Wallet.BlockchainCryptos — Review Needed

## 1. Upstream Bundle Resolution

- The regen harness bundle reported `_no_upstream_found.txt` — however, an upstream wiki WAS found independently at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md`.
- All 5 production columns inherited Tier 1 descriptions verbatim from this upstream wiki.
- **Action**: Update harness lineage resolution to include CryptoDBs/WalletDB wiki path for EXW_Wallet schema tables.

## 2. DDL vs Production Schema Differences

- **Type widening**: Production `Name` is `varchar(255)` NOT NULL; Synapse DDL is `varchar(max)` NULL. Same for `AddressPattern` (`varchar(255)` NOT NULL → `varchar(max)` NULL).
- **Type change**: Production `CryptoCoinProviderId` is `tinyint` NOT NULL with default 1; Synapse DDL is `int` NULL.
- **Nullability**: All Synapse columns are nullable; production has NOT NULL constraints on all 5 business columns.
- **Missing indexes**: Production has a clustered PK on `Id` and a unique NC index on `Name`; Synapse has HEAP with no indexes.
- These differences are expected for CopyFromLake staging replicas — no action needed.

## 3. ETL Partition Columns

- `etr_y`, `etr_ym`, `etr_ymd` are all empty across all 12 rows, consistent with Override copy strategy.
- Consider whether these columns add value for Override tables or should be excluded from UC target.

## 4. Production Source Confirmation

- Generic Pipeline mapping ID 662 confirmed: WalletDB → Wallet → BlockchainCryptos, Override, daily (1440 min), parquet.
- No writer SP exists in Synapse — table is purely a CopyFromLake replica.
- UC target: `wallet.bronze_walletdb_wallet_blockchaincryptos`.
