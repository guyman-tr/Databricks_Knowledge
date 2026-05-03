# EXW_Wallet.BlockchainCryptos

> 12-row reference table listing all supported blockchain networks in the eToro crypto wallet platform, replicated daily from WalletDB.Wallet.BlockchainCryptos via Generic Pipeline (Override). Each row defines a blockchain's ticker, address validation regex, and provider mapping.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.BlockchainCryptos via Generic Pipeline (ID 662, Override, daily) |
| **Refresh** | Daily (every 1440 minutes), Override (full replace) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_blockchaincryptos` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (CopyFromLake replica) |

---

## 1. Business Meaning

This table is a direct CopyFromLake replica of `WalletDB.Wallet.BlockchainCryptos`, the master reference of all blockchain networks supported by the eToro crypto wallet platform. It contains 12 rows, one per supported blockchain (BTC, ETH, BCH, XRP, LTC, ETC, ADA, DOGE, XLM, EOS, TRX, SOL), spanning from the original platform launch batch (2019-06-11) to the newest addition (SOL, 2026-02-16).

Each row defines a blockchain's unique identifier, ticker symbol, address validation regex pattern, and the coin provider implementation used for API interactions. This table is the foundational reference for the entire wallet system — virtually every wallet-related table references it directly or indirectly through `EXW_Wallet.CryptoTypes`.

The table is loaded via Generic Pipeline (Override strategy, daily) with no writer SP. It is consumed by `SP_EXW_WalletInventory` and `SP_EXW_Hourly` as a JOIN target for resolving blockchain names from IDs.

---

## 2. Business Logic

### 2.1 Address Validation via Regex Patterns

**What**: Each blockchain has a unique address format validated by a regex pattern stored in `AddressPattern`.
**Columns Involved**: AddressPattern, Name
**Rules**:
- Before any send or receive operation, the target address is validated against the `AddressPattern` for the relevant blockchain
- Bitcoin accepts base58 (1/3 prefix) and bech32 (bc1 prefix); Ethereum accepts 0x-prefixed hex; Ripple accepts r-prefixed base58check with optional destination tags
- The default pattern `(.*?)` (used for EOS) means all addresses are accepted — validation is deferred to the provider
- Patterns are updated when blockchains add new address formats (e.g., Bitcoin adding SegWit bech32)

### 2.2 Provider Routing

**What**: Each blockchain is assigned a specific coin provider that handles all API interactions with that chain.
**Columns Involved**: CryptoCoinProviderId
**Rules**:
- Each blockchain maps to exactly one CryptoCoinProviderId in Dictionary.CryptoCoinProviders
- 1=BitGoBlockchainProviderV2 (UTXO chains: BTC, LTC, BCH, and also SOL, ADA, DOGE, TRX, ETC)
- 2=BitGoEthereumProviderV2 (ETH/ERC-20)
- 3=BitgoRippleProviderV2 (XRP)
- 4=BitGoStellarProviderV2 (XLM)
- 5=BitGoEOSProviderV2 (EOS)
- The provider determines the API used for wallet creation, transaction signing, balance queries, and webhook notifications

### 2.3 ETL Partition Columns

**What**: Generic Pipeline adds three partition columns that are empty for Override-strategy tables.
**Columns Involved**: etr_y, etr_ym, etr_ymd
**Rules**:
- All three columns are NULL/empty for this table because Override strategy replaces the full table each load
- These columns would contain extraction date parts for Delta/Incremental copy strategies

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. With only 12 rows, distribution strategy has no performance impact. The table is small enough to fit entirely in cache on any single distribution.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which blockchains are supported? | `SELECT Id, Name FROM EXW_Wallet.BlockchainCryptos ORDER BY Id` |
| What provider handles a given blockchain? | `SELECT Name, CryptoCoinProviderId FROM EXW_Wallet.BlockchainCryptos WHERE Name = 'BTC'` |
| When was a blockchain added? | `SELECT Name, Occurred FROM EXW_Wallet.BlockchainCryptos ORDER BY Occurred` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.CryptoTypes | CryptoTypes.BlockchainCryptoId = BlockchainCryptos.Id | Resolve blockchain name for a crypto asset type |
| EXW_dbo.EXW_WalletInventory | WalletInventory.BlockchainCryptoId = BlockchainCryptos.Id | Look up blockchain for wallet inventory records |

### 3.4 Gotchas

- **Id gaps**: IDs are not sequential (e.g., 5, 7, 9-17, 20, 22, 24-26 are missing). These may be reserved for blockchains planned but not launched.
- **etr_* columns always empty**: Override copy strategy means partition columns are never populated. Do not filter on them.
- **Name vs CryptoTypes.Name**: This table's `Name` is the blockchain ticker (BTC, ETH). `CryptoTypes.Name` may differ for ERC-20 tokens that share the ETH blockchain.
- **AddressPattern contains pipe characters**: The regex patterns use `|` (alternation) which can interfere with CSV/pipe-delimited exports.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or pipeline-added column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | int | YES | Unique blockchain network identifier. Manually assigned (not IDENTITY) to maintain stable IDs across environments. Referenced by Wallet.CryptoTypes, Wallet.Wallets, Wallet.WalletPool, and Wallet.BlockchainCryptoProviders as BlockchainCryptoId. Gaps exist in sequence (e.g., 5, 7 missing) - likely reserved IDs for blockchains that were planned but not launched. (Tier 1 — Wallet.BlockchainCryptos) |
| 2 | Name | varchar(max) | YES | Standard ticker symbol for the blockchain (e.g., BTC, ETH, XRP, SOL). Unique constraint enforced by IX_Wallet_BlockchainCryptos__Name. Used for human-readable identification and API parameter matching. (Tier 1 — Wallet.BlockchainCryptos) |
| 3 | Occurred | datetime2(7) | YES | Timestamp when this blockchain was added to the system. Original blockchains (BTC, ETH, BCH, XRP, LTC, XLM) all share the same date (2019-06-11), indicating the initial platform launch batch. Newer chains have later dates tracking their go-live. (Tier 1 — Wallet.BlockchainCryptos) |
| 4 | CryptoCoinProviderId | int | YES | Blockchain provider implementation used for this chain: 1=BitGoBlockchainProviderV2 (UTXO chains like BTC, LTC, BCH, also SOL, ADA, DOGE, TRX, ETC), 2=BitGoEthereumProviderV2 (ETH/ERC-20), 3=BitgoRippleProviderV2 (XRP), 4=BitGoStellarProviderV2 (XLM), 5=BitGoEOSProviderV2 (EOS). FK to Dictionary.CryptoCoinProviders. (Tier 1 — Wallet.BlockchainCryptos) |
| 5 | AddressPattern | varchar(max) | YES | Regex pattern for validating blockchain addresses before any transaction. Each blockchain has a unique pattern matching its address format. The default `(.*?)` accepts all strings (used when provider handles validation). Updated when chains add new address formats (e.g., Bitcoin SegWit). (Tier 1 — Wallet.BlockchainCryptos) |
| 6 | etr_y | varchar(max) | YES | Generic Pipeline extraction year partition column. Always empty for this table because Override copy strategy replaces all rows each load cycle. (Tier 2 — Generic Pipeline) |
| 7 | etr_ym | varchar(max) | YES | Generic Pipeline extraction year-month partition column. Always empty for this table because Override copy strategy replaces all rows each load cycle. (Tier 2 — Generic Pipeline) |
| 8 | etr_ymd | varchar(max) | YES | Generic Pipeline extraction year-month-day partition column. Always empty for this table because Override copy strategy replaces all rows each load cycle. (Tier 2 — Generic Pipeline) |
| 9 | SynapseUpdateDate | datetime | YES | Timestamp when the row was last loaded into Synapse by the Generic Pipeline. Reflects the most recent Override refresh, not the production modification time. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| Id | Wallet.BlockchainCryptos | Id | Passthrough |
| Name | Wallet.BlockchainCryptos | Name | Passthrough |
| Occurred | Wallet.BlockchainCryptos | Occurred | Passthrough |
| CryptoCoinProviderId | Wallet.BlockchainCryptos | CryptoCoinProviderId | Passthrough |
| AddressPattern | Wallet.BlockchainCryptos | AddressPattern | Passthrough |
| etr_y | Generic Pipeline | — | ETL partition column |
| etr_ym | Generic Pipeline | — | ETL partition column |
| etr_ymd | Generic Pipeline | — | ETL partition column |
| SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.BlockchainCryptos (production, 12 rows)
  |-- Generic Pipeline (ID 662, Override, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/BlockchainCryptos/ (Data Lake)
  |-- CopyFromLake (External Table / CTAS) ---|
  v
EXW_Wallet.BlockchainCryptos (Synapse, 12 rows)
  |-- Generic Pipeline (Bronze export) ---|
  v
wallet.bronze_walletdb_wallet_blockchaincryptos (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CryptoCoinProviderId | Dictionary.CryptoCoinProviders (WalletDB) | Links blockchain to its technical API provider implementation |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| EXW_dbo.SP_EXW_WalletInventory | BlockchainCryptoId | JOINs on Id to resolve BlockchainCryptoName for wallet inventory |
| EXW_dbo.SP_EXW_Hourly | BlockchainCryptoId | JOINs on Id to resolve BlockchainCryptoName for hourly reporting |

---

## 7. Sample Queries

### 7.1 List all supported blockchains with providers

```sql
SELECT Id, Name, CryptoCoinProviderId, Occurred
FROM EXW_Wallet.BlockchainCryptos
ORDER BY Id
```

### 7.2 Find the newest blockchain additions

```sql
SELECT Name, Occurred
FROM EXW_Wallet.BlockchainCryptos
ORDER BY Occurred DESC
```

### 7.3 Count blockchains per provider

```sql
SELECT CryptoCoinProviderId, COUNT(*) AS BlockchainCount,
       STRING_AGG(Name, ', ') AS Blockchains
FROM EXW_Wallet.BlockchainCryptos
GROUP BY CryptoCoinProviderId
ORDER BY BlockchainCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode).

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 7/10, Relationships: 7/10, Sources: 8/10*
*Object: EXW_Wallet.BlockchainCryptos | Type: Table | Production Source: WalletDB.Wallet.BlockchainCryptos*
