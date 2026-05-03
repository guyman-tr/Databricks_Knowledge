# EXW_Wallet.CryptoTypes

> 174-row cryptocurrency reference/configuration table listing every crypto asset supported by the eToroX Wallet platform, including blockchain parameters, verification requirements, fee settings, and display metadata. Loaded daily (Override) from WalletDB.Wallet.CryptoTypes via the Generic Pipeline. Data spans from April 2018 to present. Currently all 174 rows are active (IsActive = 1).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.CryptoTypes (Generic Pipeline #625, Override, daily) |
| **Refresh** | Daily (1440 min), Override strategy — full table reload each cycle |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_cryptotypes` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.CryptoTypes is a reference dimension table that defines every cryptocurrency asset available on the eToroX Wallet platform. Each row represents a distinct crypto asset (e.g., BTC, ETH, XRP, ADA) with its blockchain configuration, verification requirements, fee structure, and display properties.

The table currently holds 174 crypto types, with `Occurred` dates ranging from 2018-04-23 (BTC, the first asset onboarded) to 2026-02-16 (most recently added assets). Of the 174 rows, 13 have Status = 1 (the original base cryptocurrencies) and 161 have Status = 3 (ERC-20 tokens added later). All rows are currently active (IsActive = 1).

The table is loaded by the Generic Pipeline (ID #625) using an Override (full reload) strategy daily from the production WalletDB.Wallet.CryptoTypes table. No Synapse stored procedure writes to this table — it is a direct pipeline passthrough. The table is read extensively by 15+ EXW_dbo stored procedures (SP_EXW_WalletInventory, SP_EXW_Hourly, SP_EXW_Fact_Transactions, SP_EXW_C2F_E2E, SP_Prices, etc.) that JOIN on CryptoID or BlockchainCryptoId to resolve crypto asset metadata.

BlockchainCryptoId is a self-referential foreign key pointing back to CryptoID, linking ERC-20 tokens to their parent blockchain's base crypto entry (e.g., all ERC-20 tokens have BlockchainCryptoId = 2, pointing to Ethereum).

---

## 2. Business Logic

### 2.1 Crypto Asset Classification

**What**: Each crypto asset is classified by its category and asset type.
**Columns Involved**: CryptoCategoryName, AssetTypeId, Status
**Rules**:
- AssetTypeId = 1: base cryptocurrency (BTC, ETH, BCH, XRP, LTC, etc.) — 12 assets
- AssetTypeId = 2: ERC-20 token running on an existing blockchain — 162 assets
- CryptoCategoryName = 'baseCrypto' / 'BaseCrypto': native blockchain assets (12 assets, case inconsistent)
- CryptoCategoryName = 'erc20Wave1': first wave of ERC-20 tokens (161 assets)
- CryptoCategoryName = 'erc20Wave3': later wave ERC-20 token (1 asset)
- Status = 1: original base crypto assets (13 rows)
- Status = 3: ERC-20 / later-added tokens (161 rows)

### 2.2 Blockchain Verification Configuration

**What**: Each crypto type defines the verification requirements for on-chain transactions.
**Columns Involved**: MinReqVerifications, MaxVerificationTimeMinutes, WebHookVerifications, StartMonitoringDelaySeconds
**Rules**:
- MinReqVerifications: number of blockchain confirmations required (e.g., BTC = 6, ETH = 10, DOGE = 40)
- MaxVerificationTimeMinutes: maximum wait time for verifications (universally 20160 minutes = 14 days)
- WebHookVerifications: all observed values are 0
- StartMonitoringDelaySeconds: delay before starting to monitor a transaction (universally 120 seconds)

### 2.3 Self-Referential Blockchain Hierarchy

**What**: ERC-20 tokens link back to their parent blockchain's base crypto entry.
**Columns Involved**: CryptoID, BlockchainCryptoId
**Rules**:
- For base cryptos: BlockchainCryptoId equals CryptoID (self-referential)
- For ERC-20 tokens: BlockchainCryptoId points to the base crypto (e.g., all ERC-20 tokens point to CryptoID = 2 for Ethereum)
- SP_EXW_WalletInventory and SP_Prices use this hierarchy to resolve the underlying blockchain

### 2.4 Fee and Balance Configuration

**What**: Fee handling and balance monitoring thresholds per crypto type.
**Columns Involved**: IsEtoroHandlingFee, BalanceThreshold, InitialFeeUnits
**Rules**:
- IsEtoroHandlingFee = True for 164 of 174 assets (eToro handles the network fee)
- IsEtoroHandlingFee = False for 10 base cryptos (BTC, BCH, XRP, LTC, ADA, DOGE, XLM, EOS, and others)
- BalanceThreshold: minimum balance to trigger monitoring (most are 0.00001, some are 0)
- InitialFeeUnits: all observed values are 0

### 2.5 Staking Configuration

**What**: Staking-related display properties for assets that support staking.
**Columns Involved**: StakingDisplayName, StakingAvatarUrl, StakingSymbolFull
**Rules**:
- Most rows have NULL/empty staking fields
- ETH (CryptoID = 2) has staking configured: StakingDisplayName = 'Ethereum 2.0', StakingSymbolFull = 'ETH 2.0'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP (no index). With only 174 rows, this table is fully replicated across all distributions in practice. No performance concerns for any query pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| List all active base cryptocurrencies | `SELECT * FROM EXW_Wallet.CryptoTypes WHERE AssetTypeId = 1` |
| Find the parent blockchain for an ERC-20 token | `SELECT ct.*, parent.Name AS ParentBlockchain FROM EXW_Wallet.CryptoTypes ct JOIN EXW_Wallet.CryptoTypes parent ON ct.BlockchainCryptoId = parent.CryptoID WHERE ct.AssetTypeId = 2` |
| Get crypto display metadata for UI | `SELECT CryptoID, DisplayName, SymbolFull, AvatarUrl, OrderIndex FROM EXW_Wallet.CryptoTypes ORDER BY OrderIndex` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.CryptoMarketRatesMappings | cmrm.CryptoId = ct.CryptoID | Map crypto to market rate symbols |
| EXW_Wallet.CustomerWalletsView | cw.CryptoId = ct.CryptoID | Resolve crypto metadata for customer wallets |
| EXW_Wallet.EXW_Price | ep.CryptoID = ct.CryptoID | Join price data to crypto type details |
| Self-join | ct.BlockchainCryptoId = parent.CryptoID | Resolve ERC-20 token to parent blockchain |

### 3.4 Gotchas

- **CryptoCategoryName case inconsistency**: 'baseCrypto' (10 rows) vs. 'BaseCrypto' (2 rows) — use case-insensitive comparison or UPPER() when filtering.
- **CryptoID is not sequential**: IDs skip values (e.g., 1, 2, 3, 4, 6, 8, 18, 19, 21, 23 ...). Do not assume contiguous integer range.
- **TagName is sparse**: most rows have empty TagName; only XRP ('dt'), XLM ('memoId'), EOS ('memoId') and a few others use it for blockchain-specific transaction tag requirements.
- **All rows are IsActive = 1**: there are no inactive crypto types in the current dataset. Historical deactivations may have been removed by the Override load strategy.
- **BlockchainExplorerFormat contains URL templates**: values contain `{0}` placeholder for transaction hash — not a direct URL.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or framework-generated column |
| Tier 3 | Grounded in DDL + sample data, no upstream wiki available |
| Tier 4 | Inferred from name only (BANNED in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CryptoID | int | YES | Primary identifier for the cryptocurrency type. Non-sequential integer (e.g., 1=BTC, 2=ETH, 3=BCH, 4=XRP). Used as the main join key across EXW_Wallet tables. Self-referenced by BlockchainCryptoId for ERC-20 token hierarchy. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 2 | Name | varchar(max) | YES | Short ticker symbol for the crypto asset (e.g., 'BTC', 'ETH', 'XRP', 'DOGE'). Matches standard cryptocurrency ticker conventions. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 3 | MinReqAccounts | int | YES | Minimum number of accounts required for the crypto type. Observed values: 0 (BTC) or 1 (all others). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 4 | MinUnit | numeric(18,0) | YES | Minimum unit quantity for the crypto type. All observed values are 0. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 5 | Status | int | YES | Status code for the crypto type. 1 = original base crypto assets (13 rows), 3 = ERC-20 / later-added tokens (161 rows). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 6 | MinReqVerifications | int | YES | Minimum number of blockchain confirmations required before a transaction is considered verified. Varies by blockchain: BTC = 6, ETH/ETC = 10, DOGE = 40, most others = 6. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 7 | MaxVerificationTimeMinutes | bigint | YES | Maximum allowed time in minutes for blockchain verification to complete. Universally set to 20160 (14 days) across all crypto types. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 8 | Occurred | datetime2(7) | YES | Timestamp when the crypto type record was created or last modified in the production system. Earliest: 2018-04-23 (BTC), latest: 2026-02-16. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 9 | IsActive | bit | YES | Whether the crypto type is currently active on the platform. All 174 rows are currently True. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 10 | CryptoActivityStatus | int | YES | Activity status code for the crypto type. 2 = active (173 rows), 3 = limited activity (1 row, XRP). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 11 | BalanceAssetName | varchar(max) | YES | External asset identifier used for balance lookups (e.g., 'bitcoin', 'ethereum', 'ripple', 'dogecoin'). Lowercase, hyphenated format matching external API naming conventions. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 12 | WebHookVerifications | int | YES | Number of webhook-based verification checks configured. All observed values are 0. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 13 | StartMonitoringDelaySeconds | int | YES | Delay in seconds before starting to monitor a submitted blockchain transaction. Universally set to 120 seconds across all crypto types. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 14 | BalanceThreshold | numeric(36,18) | YES | Minimum balance threshold that triggers monitoring or alerts. Most assets set to 0.00001; some are 0. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 15 | InitialFeeUnits | numeric(36,18) | YES | Initial fee units charged for the crypto type. All observed values are 0. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 16 | BlockchainExplorerFormat | varchar(max) | YES | URL template for the blockchain explorer transaction page. Contains `{0}` placeholder for the transaction hash (e.g., 'https://www.blockchain.com/btc/tx/{0}'). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 17 | IsEtoroHandlingFee | bit | YES | Whether eToro handles the blockchain network fee for this crypto type. True for 164 of 174 assets (mostly ERC-20 tokens). False for 10 base cryptos (BTC, BCH, XRP, LTC, etc.). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 18 | BlockchainCryptoId | int | YES | Foreign key referencing CryptoID of the parent blockchain's base crypto entry. For base cryptos, equals CryptoID (self-referential). For ERC-20 tokens, points to the base chain (e.g., 2 = Ethereum for all ERC-20 tokens). Used by SP_EXW_WalletInventory to determine blockchain-level properties. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 19 | AssetTypeId | int | YES | Classification of the crypto asset type. 1 = base cryptocurrency / native blockchain asset (12 rows), 2 = ERC-20 token (162 rows). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 20 | SymbolFull | varchar(max) | YES | Full symbol identifier for the crypto asset, typically matching the ticker (e.g., 'BTC', 'ETH', 'ADA'). Used in display and API contexts. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 21 | DisplayName | varchar(max) | YES | Human-readable display name for the crypto asset (e.g., 'Bitcoin', 'Ethereum', 'Cardano', 'Dogecoin'). Used in UI rendering. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 22 | AvatarUrl | varchar(max) | YES | URL to the crypto asset's avatar/logo image on the eToro CDN (e.g., 'https://etoro-cdn.etorostatic.com/market-avatars/btc/150x150.png'). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 23 | Precision | int | YES | Number of decimal places for displaying the crypto asset's value. Most assets use 6; EOS uses 4; XLM uses 7. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 24 | TagName | varchar(max) | YES | Blockchain-specific transaction tag or memo field name required for the crypto asset. Empty for most assets. 'dt' for XRP (destination tag), 'memoId' for XLM and EOS. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 25 | InstrumentId | int | YES | Foreign key to the eToro trading instrument. Maps crypto assets to eToro's instrument system (e.g., BTC = 100000, ETH = 100001, BCH = 100002). Used by SP_Prices to join with EXW_Currency.Instruments. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 26 | AssetBlockchainAddress | varchar(max) | YES | On-chain contract address for the crypto asset. Empty for base cryptos (native coins have no contract address). Populated for ERC-20 tokens with their Ethereum contract address. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 27 | OrderIndex | int | YES | Display sort order for the crypto asset in UI listings. Lower values appear first. Base cryptos have round-number values (BTC = 100, ETH = 200, XRP = 300, LTC = 400). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 28 | CryptoCategoryName | varchar(max) | YES | Category classification for the crypto asset. 'baseCrypto' / 'BaseCrypto' = native blockchain asset (12 rows, case inconsistent), 'erc20Wave1' = first-wave ERC-20 token (161 rows), 'erc20Wave3' = later-wave ERC-20 token (1 row). (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 29 | StakingDisplayName | varchar(max) | YES | Display name for the staking variant of the crypto asset. Populated only for assets that support staking (e.g., ETH has 'Ethereum 2.0'). NULL/empty for non-staking assets. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 30 | StakingAvatarUrl | varchar(max) | YES | URL to the staking variant's avatar image. Populated only for staking-eligible assets (e.g., ETH). NULL/empty for non-staking assets. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 31 | StakingSymbolFull | varchar(max) | YES | Full symbol for the staking variant of the crypto asset (e.g., 'ETH 2.0' for Ethereum staking). NULL/empty for non-staking assets. (Tier 3 — WalletDB.Wallet.CryptoTypes, no upstream wiki located) |
| 32 | etr_y | varchar(max) | YES | ETL partition column: year component of the data load date. Added by the Generic Pipeline framework. Currently empty for all rows (Override strategy reloads full table). (Tier 2 — Generic Pipeline) |
| 33 | etr_ym | varchar(max) | YES | ETL partition column: year-month component of the data load date. Added by the Generic Pipeline framework. Currently empty for all rows (Override strategy reloads full table). (Tier 2 — Generic Pipeline) |
| 34 | etr_ymd | varchar(max) | YES | ETL partition column: year-month-day component of the data load date. Added by the Generic Pipeline framework. Currently empty for all rows (Override strategy reloads full table). (Tier 2 — Generic Pipeline) |
| 35 | SynapseUpdateDate | datetime | YES | Timestamp of the last Synapse data load. All rows share the same value per refresh cycle (e.g., 2026-04-27 06:00:33). Set by the Generic Pipeline at load time. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CryptoID | WalletDB.Wallet.CryptoTypes | CryptoID | Passthrough |
| Name | WalletDB.Wallet.CryptoTypes | Name | Passthrough |
| MinReqAccounts | WalletDB.Wallet.CryptoTypes | MinReqAccounts | Passthrough |
| MinUnit | WalletDB.Wallet.CryptoTypes | MinUnit | Passthrough |
| Status | WalletDB.Wallet.CryptoTypes | Status | Passthrough |
| MinReqVerifications | WalletDB.Wallet.CryptoTypes | MinReqVerifications | Passthrough |
| MaxVerificationTimeMinutes | WalletDB.Wallet.CryptoTypes | MaxVerificationTimeMinutes | Passthrough |
| Occurred | WalletDB.Wallet.CryptoTypes | Occurred | Passthrough |
| IsActive | WalletDB.Wallet.CryptoTypes | IsActive | Passthrough |
| CryptoActivityStatus | WalletDB.Wallet.CryptoTypes | CryptoActivityStatus | Passthrough |
| BalanceAssetName | WalletDB.Wallet.CryptoTypes | BalanceAssetName | Passthrough |
| WebHookVerifications | WalletDB.Wallet.CryptoTypes | WebHookVerifications | Passthrough |
| StartMonitoringDelaySeconds | WalletDB.Wallet.CryptoTypes | StartMonitoringDelaySeconds | Passthrough |
| BalanceThreshold | WalletDB.Wallet.CryptoTypes | BalanceThreshold | Passthrough |
| InitialFeeUnits | WalletDB.Wallet.CryptoTypes | InitialFeeUnits | Passthrough |
| BlockchainExplorerFormat | WalletDB.Wallet.CryptoTypes | BlockchainExplorerFormat | Passthrough |
| IsEtoroHandlingFee | WalletDB.Wallet.CryptoTypes | IsEtoroHandlingFee | Passthrough |
| BlockchainCryptoId | WalletDB.Wallet.CryptoTypes | BlockchainCryptoId | Passthrough |
| AssetTypeId | WalletDB.Wallet.CryptoTypes | AssetTypeId | Passthrough |
| SymbolFull | WalletDB.Wallet.CryptoTypes | SymbolFull | Passthrough |
| DisplayName | WalletDB.Wallet.CryptoTypes | DisplayName | Passthrough |
| AvatarUrl | WalletDB.Wallet.CryptoTypes | AvatarUrl | Passthrough |
| Precision | WalletDB.Wallet.CryptoTypes | Precision | Passthrough |
| TagName | WalletDB.Wallet.CryptoTypes | TagName | Passthrough |
| InstrumentId | WalletDB.Wallet.CryptoTypes | InstrumentId | Passthrough |
| AssetBlockchainAddress | WalletDB.Wallet.CryptoTypes | AssetBlockchainAddress | Passthrough |
| OrderIndex | WalletDB.Wallet.CryptoTypes | OrderIndex | Passthrough |
| CryptoCategoryName | WalletDB.Wallet.CryptoTypes | CryptoCategoryName | Passthrough |
| StakingDisplayName | WalletDB.Wallet.CryptoTypes | StakingDisplayName | Passthrough |
| StakingAvatarUrl | WalletDB.Wallet.CryptoTypes | StakingAvatarUrl | Passthrough |
| StakingSymbolFull | WalletDB.Wallet.CryptoTypes | StakingSymbolFull | Passthrough |
| etr_y | Generic Pipeline | — | ETL partition column (year) |
| etr_ym | Generic Pipeline | — | ETL partition column (year-month) |
| etr_ymd | Generic Pipeline | — | ETL partition column (year-month-day) |
| SynapseUpdateDate | Generic Pipeline | — | ETL load timestamp |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.CryptoTypes (production, WalletDB server)
  |-- Generic Pipeline #625 (Override, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/CryptoTypes/ (Data Lake)
  |-- Generic Pipeline (Bronze import to Synapse) ---|
  v
EXW_Wallet.CryptoTypes (174 rows, Synapse DWH)
  |-- Generic Pipeline (Bronze export, Override, delta) ---|
  v
wallet.bronze_walletdb_wallet_cryptotypes (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| BlockchainCryptoId | EXW_Wallet.CryptoTypes (self) | Self-referential FK: ERC-20 tokens point to their parent blockchain's base crypto entry |
| InstrumentId | eToro Instrument system | Maps to eToro trading instrument IDs (100000+ range) |

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Join Condition | Purpose |
|---------|-------------------|----------------|---------|
| CryptoID | EXW_Wallet.CryptoMarketRatesMappings | cmrm.CryptoId = ct.CryptoID | Map crypto to market rate symbols |
| CryptoID | EXW_Wallet.CustomerWalletsView | cw.CryptoId = ct.CryptoID | Resolve crypto metadata for wallets |
| CryptoID | EXW_Wallet.EXW_Price | ep.CryptoID = ct.CryptoID | Price data crypto resolution |
| BlockchainCryptoId | EXW_dbo.SP_EXW_WalletInventory | wp.BlockchainCryptoId = ct.CryptoID | Wallet pool blockchain resolution |
| CryptoID | EXW_dbo.SP_EXW_Hourly | JOIN on CryptoID | Hourly wallet metrics |
| CryptoID | EXW_dbo.SP_EXW_Fact_Transactions | JOIN on CryptoID | Transaction fact enrichment |
| CryptoID | EXW_dbo.SP_EXW_C2F_E2E | JOIN on CryptoID | Crypto-to-fiat end-to-end flow |
| CryptoID | EXW_dbo.SP_EXW_UserCalculatedBalance | JOIN on CryptoID | User balance calculations |
| CryptoID | EXW_dbo.SP_EXW_FinanceReportsBalancesNew | JOIN on CryptoID | Finance balance reporting |

---

## 7. Sample Queries

### 7.1 List all base cryptocurrencies with their blockchain config

```sql
SELECT
    CryptoID,
    Name,
    DisplayName,
    MinReqVerifications,
    MaxVerificationTimeMinutes / 60 AS MaxVerificationHours,
    IsEtoroHandlingFee,
    BlockchainExplorerFormat
FROM EXW_Wallet.CryptoTypes
WHERE AssetTypeId = 1
ORDER BY OrderIndex;
```

### 7.2 Find ERC-20 tokens and their parent blockchain

```sql
SELECT
    token.CryptoID,
    token.DisplayName AS TokenName,
    token.SymbolFull AS TokenSymbol,
    parent.DisplayName AS ParentBlockchain,
    token.AssetBlockchainAddress AS ContractAddress
FROM EXW_Wallet.CryptoTypes token
JOIN EXW_Wallet.CryptoTypes parent
    ON token.BlockchainCryptoId = parent.CryptoID
WHERE token.AssetTypeId = 2
ORDER BY token.OrderIndex;
```

### 7.3 Crypto types with staking enabled

```sql
SELECT
    CryptoID,
    DisplayName,
    StakingDisplayName,
    StakingSymbolFull
FROM EXW_Wallet.CryptoTypes
WHERE StakingDisplayName IS NOT NULL
    AND StakingDisplayName <> '';
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 12/14*
*Tiers: 0 T1, 4 T2, 31 T3, 0 T4, 0 T5 | Elements: 35/35, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.CryptoTypes | Type: Table | Production Source: WalletDB.Wallet.CryptoTypes (Generic Pipeline)*
