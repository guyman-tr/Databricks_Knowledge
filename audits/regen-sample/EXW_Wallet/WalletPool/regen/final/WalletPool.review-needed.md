# EXW_Wallet.WalletPool — Review Needed

## Tier 3 Coverage

All 12 columns are Tier 3 — no upstream wiki was found for WalletDB.Wallet.WalletPool. The `_no_upstream_found.txt` marker is present. All descriptions are grounded in DDL structure, live data sampling, and SP code analysis.

## Items for Human Review

### 1. WalletProviderId Values
- Only 2 values observed (1 and 2). The provider names are unknown — no dictionary table for WalletProviderId was found in the SSDT repo. A reviewer with domain knowledge should map these IDs to provider names (e.g., Fireblocks, another custody provider).

### 2. SynapseUpdateDate NULL Pattern
- All 10 sampled rows show SynapseUpdateDate as NULL. This may indicate the column is no longer populated by the current CopyFromLake pipeline version, or only populated during full Override loads (not Append). Reviewer should confirm whether this column is actively maintained.

### 3. BlockchainCryptoId Mapping
- 12 distinct values observed. The FK to EXW_Wallet.CryptoTypes should resolve names (BTC=1, ETH=2, etc.), but the exact mapping was not queried. Reviewer should verify the top crypto IDs match expected blockchain types.

### 4. Production Source Confirmation
- No upstream wiki exists for WalletDB.Wallet.WalletPool. If a wiki is created in the CryptoDBs repo or WalletDB documentation, all 7 business columns (Id through WalletProviderId) should be upgraded to Tier 1.

### 5. UC Target Verification
- UC target `wallet.bronze_walletdb_wallet_walletpool` is derived from the Generic Pipeline mapping. Reviewer should verify this table exists in Unity Catalog and is actively populated.
