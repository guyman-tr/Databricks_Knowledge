# EXW_Wallet.CustomerWalletsView — Review Needed

## Summary

12 of 17 columns are Tier 3 (traceable to production source via code, but no upstream wiki exists for WalletDB). 5 columns are Tier 2 (ETL-computed or pipeline infrastructure). No Tier 1 columns — no upstream wiki documentation exists for any WalletDB.Wallet.* tables.

## Items Requiring Human Review

### 1. WalletTypeId Values — Meaning Unknown

WalletTypeId has 7 distinct values (1-7), with type 5 comprising 99.99% of rows (1,780,070). The business meaning of each type ID is unknown:
- **1**: 60 rows — unknown
- **2**: 25 rows — unknown
- **3**: 8 rows — unknown
- **4**: 8 rows — unknown
- **5**: 1,780,070 rows — appears to be the standard/default type
- **6**: 2 rows — unknown
- **7**: 1 row — unknown

**Action**: Wallet team should confirm the wallet type dictionary. Check if `WalletDB.Wallet.WalletTypes` or a similar dictionary table exists in production.

### 2. WalletProviderId Values — Provider Names Inferred

Only 2 distinct values observed (1 and 2). Provider 1 appears to be BitGo (majority), Provider 2 may be Fireblocks. These names are inferred from Confluence context and should be confirmed.

**Action**: Confirm provider ID mapping with the Wallet infrastructure team.

### 3. CryptoId vs BlockchainCryptoId — Relationship Unclear

Both columns reference crypto identifiers but from different tables:
- `CryptoId` from WalletAssets — seems to identify the specific crypto asset
- `BlockchainCryptoId` from Wallets — seems to identify the blockchain network

In some rows these match (e.g., CryptoId=2, BlockchainCryptoId=2 for ETH), but in others they differ (e.g., CryptoId=21, BlockchainCryptoId=21 for XLM but ERC-20 tokens would differ).

**Action**: Confirm the semantic difference. Is CryptoId the token-level identifier and BlockchainCryptoId the chain-level identifier?

### 4. etr_y / etr_ym / etr_ymd — Empty in All Sampled Rows

These Generic Pipeline partition columns are empty strings (not NULL) across all sampled rows. This is unusual — most CopyFromLake tables populate these with the extraction date.

**Action**: Verify if this is expected for Override-strategy tables or if the pipeline configuration needs review.

### 5. No Upstream Wiki — All WalletDB Sources Undocumented

No upstream wiki exists for `WalletDB.Wallet.Wallets`, `WalletDB.Wallet.WalletPool`, or `WalletDB.Wallet.WalletAssets`. Column descriptions are grounded in DDL structure and the production view definition (`EXW_Wallet.EXW_CustomerWalletsView`), but lack business context from the source team.

**Action**: Request WalletDB schema documentation from the Wallet team to upgrade Tier 3 columns to Tier 1.

### 6. PII Columns — Address and BlockchainProviderWalletId

Both `Address` (blockchain public address) and `BlockchainProviderWalletId` (provider wallet ID) contain PII-sensitive data. These should be tagged accordingly in Unity Catalog.

**Action**: Confirm PII classification and apply appropriate tags during UC migration.
