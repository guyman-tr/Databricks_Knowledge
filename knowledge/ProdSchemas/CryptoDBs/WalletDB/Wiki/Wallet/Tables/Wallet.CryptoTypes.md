# Wallet.CryptoTypes

> Master registry of all supported cryptocurrency assets (native coins and ERC-20 tokens) defining each asset's configuration, display properties, blockchain mapping, fee parameters, and trading instrument linkage.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | CryptoID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table is the central crypto asset registry for the entire wallet platform. Each row defines a cryptocurrency asset that can be held, sent, received, converted, or staked within eToro wallets. The 174 entries include 12 native blockchain coins (BTC, ETH, LTC, etc.) and 162 ERC-20 tokens (USDT, LINK, UNI, etc.) that all share the Ethereum blockchain. This is the most widely-referenced table in the Wallet schema - virtually every transactional table has a FK to CryptoTypes.

Without this table, the system would not know which crypto assets are available, how to display them, what precision to use for amounts, which blockchain they belong to, or what fees to charge. It is the single source of truth for crypto asset configuration.

Rows are inserted when new crypto assets are added to the platform. Configuration columns (fees, thresholds, activity status) may be updated over time. The table is consumed by nearly every wallet operation - from wallet creation (`Wallet.Wallets.BlockchainCryptoId` resolved through this table) to transaction processing, balance display, conversion pricing, and monitoring. Key FK dependents include `Wallet.SentTransactions`, `Wallet.ReceivedTransactions`, `Wallet.WalletBalances`, `Wallet.WalletAssets`, `Wallet.Conversions`, `Wallet.Payments`, `Wallet.AmlProviderContracts`, `Wallet.CryptoMarketRatesMappings`, and `Wallet.PromotionTags`.

---

## 2. Business Logic

### 2.1 Asset Type Architecture

**What**: Assets are classified as either native coins (with their own blockchain) or ERC-20 tokens (sharing Ethereum's blockchain).

**Columns/Parameters Involved**: `AssetTypeId`, `BlockchainCryptoId`, `AssetBlockchainAddress`

**Rules**:
- AssetTypeId=1 (Coin): 12 native coins - each has its own blockchain (BTC on blockchain 1, ETH on blockchain 2, etc.)
- AssetTypeId=2 (ERC20): 162 tokens - all share BlockchainCryptoId=2 (Ethereum) and have an `AssetBlockchainAddress` (the token contract address)
- See [Asset Type](../../_glossary.md#asset-type). FK to Dictionary.AssetTypes.
- Native coins can be sent on their own blockchain; ERC-20 tokens use Ethereum's transaction system

### 2.2 Crypto Activity Status

**What**: Controls whether a crypto asset is available for wallet operations, used as a feature flag for gradual rollouts and wind-downs.

**Columns/Parameters Involved**: `CryptoActivityStatus`, `IsActive`

**Rules**:
- 173 assets have status 2 (Available) - full send, receive, convert operations permitted
- 1 asset (XRP, CryptoID=4) has status 3 (AvailableRedeemOnly) - users can only redeem (withdraw) existing holdings, no new deposits or purchases
- See [Crypto Activity Status](../../_glossary.md#crypto-activity-status). FK to Dictionary.CryptoActivityStatuses.
- `IsActive` (bit) provides a secondary on/off toggle independent of the activity status

### 2.3 Fee Configuration

**What**: Each crypto asset has configurable fee parameters for blockchain operations.

**Columns/Parameters Involved**: `InitialFeeUnits`, `BalanceThreshold`, `IsEtoroHandlingFee`

**Rules**:
- `InitialFeeUnits`: base fee units charged for transactions in this crypto
- `BalanceThreshold`: minimum balance below which the wallet is considered empty
- `IsEtoroHandlingFee`: whether eToro charges an additional handling fee on top of blockchain fees

---

## 3. Data Overview

| CryptoID | Name | DisplayName | BlockchainCryptoId | AssetTypeId | CryptoActivityStatus | Meaning |
|---|---|---|---|---|---|---|
| 1 | BTC | Bitcoin | 1 | 1 (Coin) | 2 (Available) | Bitcoin - the flagship crypto. Native coin on its own blockchain. Fully available for all wallet operations. |
| 2 | ETH | Ethereum | 2 | 1 (Coin) | 2 (Available) | Ethereum - native coin AND the blockchain host for 162 ERC-20 tokens. |
| 4 | XRP | Ripple | 4 | 1 (Coin) | 3 (RedeemOnly) | Ripple - restricted to redemption only. Users can withdraw existing XRP but cannot deposit or buy more. Likely due to regulatory considerations. |
| 64 | SOL | Solana | 64 | 1 (Coin) | 2 (Available) | Solana - newest native coin added (Feb 2026). |
| 107 | (ERC-20) | (token) | 2 | 2 (ERC20) | 2 (Available) | Example ERC-20 token. Shares Ethereum blockchain (Id=2). Has AssetBlockchainAddress pointing to its smart contract. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoID | int | NO | - | VERIFIED | Unique identifier for this crypto asset. Manually assigned (not IDENTITY). Referenced as FK by Wallet.SentTransactions, Wallet.ReceivedTransactions, Wallet.WalletBalances, Wallet.WalletAssets, Wallet.Conversions, Wallet.Payments, Wallet.AmlProviderContracts, Wallet.CryptoMarketRatesMappings, Wallet.PromotionTags, and many stored procedures. The most widely-referenced PK in the schema. |
| 2 | Name | nvarchar(256) | NO | - | VERIFIED | Ticker symbol (e.g., BTC, ETH, USDT, LINK). Used for API parameter matching and internal identification. |
| 3 | MinReqAccounts | int | NO | - | NAME-INFERRED | Minimum number of accounts/signers required for wallet operations on this crypto. Related to multi-signature wallet configuration. |
| 4 | MinUnit | decimal(18,0) | NO | - | NAME-INFERRED | Minimum transferable unit (satoshi-equivalent) for this crypto. Defines the smallest amount that can be sent. |
| 5 | Status | int | NO | - | CODE-BACKED | Legacy status field. Superseded by CryptoActivityStatus for business logic. Maintained for backward compatibility. |
| 6 | MinReqVerifications | int | YES | - | CODE-BACKED | Minimum number of blockchain confirmations required before a received transaction is considered confirmed. Varies by blockchain (e.g., BTC needs more confirmations than ETH). |
| 7 | MaxVerificationTimeMinutes | bigint | YES | - | CODE-BACKED | Maximum time in minutes to wait for blockchain confirmations before timing out a transaction. Used for monitoring stuck transactions. |
| 8 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp when this crypto asset was added to the system. |
| 9 | IsActive | bit | NO | 0 | CODE-BACKED | Secondary activation toggle. 1=active, 0=disabled. Works alongside CryptoActivityStatus to control asset availability. Most active assets have IsActive=1. |
| 10 | CryptoActivityStatus | int | YES | - | VERIFIED | Availability level for wallet operations: 0=NotActive, 1=ComingSoon, 2=Available (173 assets), 3=AvailableRedeemOnly (XRP only). See [Crypto Activity Status](../../_glossary.md#crypto-activity-status). FK to Dictionary.CryptoActivityStatuses. |
| 11 | BalanceAssetName | varchar(100) | YES | - | NAME-INFERRED | Asset name as known by the balance/custody provider (e.g., BitGo's internal asset identifier). May differ from the display name. |
| 12 | WebHookVerifications | tinyint | YES | - | CODE-BACKED | Number of webhook-based verification callbacks required from the blockchain provider before confirming a transaction. |
| 13 | StartMonitoringDelaySeconds | int | NO | 120 | CODE-BACKED | Delay in seconds before starting to monitor a newly submitted transaction. Default 120s allows the blockchain network to propagate the transaction. |
| 14 | BalanceThreshold | decimal(36,18) | NO | 0.00001 | CODE-BACKED | Minimum balance threshold below which a wallet is considered effectively empty. Used for balance checks and dust amount detection. |
| 15 | InitialFeeUnits | decimal(36,18) | NO | 0 | CODE-BACKED | Base fee units charged per transaction for this crypto. 0 means no initial fee (blockchain fee only). |
| 16 | BlockchainExplorerFormat | nvarchar(100) | YES | - | NAME-INFERRED | URL format string for generating blockchain explorer links (e.g., "https://blockchain.com/btc/tx/{txId}"). Used in UI to link transactions to explorer pages. |
| 17 | IsEtoroHandlingFee | bit | YES | - | CODE-BACKED | Whether eToro charges an additional handling fee on top of blockchain network fees for this crypto. 1=yes, 0/NULL=no. |
| 18 | BlockchainCryptoId | int | NO | - | VERIFIED | The blockchain network this crypto asset runs on. For native coins, maps 1:1 (BTC->1, ETH->2). For ERC-20 tokens, all point to 2 (Ethereum). FK to Wallet.BlockchainCryptos.Id. |
| 19 | AssetTypeId | tinyint | NO | - | VERIFIED | Asset classification: 1=Coin (12 native blockchain coins), 2=ERC20 (162 Ethereum tokens). See [Asset Type](../../_glossary.md#asset-type). FK to Dictionary.AssetTypes. |
| 20 | SymbolFull | nvarchar(100) | YES | - | CODE-BACKED | Full ticker symbol used in API responses and market data integration. Usually identical to Name. |
| 21 | DisplayName | nvarchar(100) | YES | - | CODE-BACKED | Human-readable asset name shown in the UI (e.g., "Bitcoin", "Ethereum", "Cardano"). More descriptive than the ticker symbol. |
| 22 | AvatarUrl | nvarchar(100) | YES | - | NAME-INFERRED | URL to the crypto asset's logo/icon image. Used in the wallet UI for visual identification. |
| 23 | Precision | int | YES | - | CODE-BACKED | Number of decimal places used when displaying amounts of this crypto. BTC/ETH=6, XLM=7, EOS=4. Controls UI formatting. |
| 24 | TagName | nvarchar(100) | YES | - | CODE-BACKED | Name of the secondary address field required by some blockchains (e.g., "Destination Tag" for XRP, "Memo" for XLM). NULL for blockchains that don't require a tag. |
| 25 | InstrumentId | int | YES | - | VERIFIED | Links to the eToro trading platform's instrument for this crypto (e.g., BTC=100000, ETH=100001). Used for market rate lookups and position valuation. Implicit reference to Wallet.Instruments.InstrumentId. |
| 26 | AssetBlockchainAddress | nvarchar(255) | YES | - | CODE-BACKED | Smart contract address for ERC-20 tokens on the Ethereum blockchain. NULL for native coins. Used to identify the token when interacting with the Ethereum network. |
| 27 | OrderIndex | int | NO | 0 | CODE-BACKED | Controls display order in the wallet UI. Lower values appear first. |
| 28 | CryptoCategoryName | varchar(50) | YES | - | NAME-INFERRED | Category classification for the crypto asset (e.g., "DeFi", "Payment", "Meme"). Used for UI grouping and filtering. |
| 29 | StakingDisplayName | nvarchar(100) | YES | - | CODE-BACKED | Display name specifically for staking context (e.g., "Cardano Staking"). NULL for non-stakeable assets. |
| 30 | StakingAvatarUrl | nvarchar(100) | YES | - | NAME-INFERRED | Logo URL for the staking variant. May differ from the regular avatar. |
| 31 | StakingSymbolFull | nvarchar(100) | YES | - | CODE-BACKED | Ticker symbol for staking context. NULL for non-stakeable assets. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockchainCryptoId | Wallet.BlockchainCryptos | FK | Links asset to its blockchain network |
| AssetTypeId | Dictionary.AssetTypes | FK | Classifies as Coin or ERC20 |
| CryptoActivityStatus | Dictionary.CryptoActivityStatuses | FK | Controls operational availability |
| InstrumentId | Wallet.Instruments | Implicit | Links to trading instrument for rates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SentTransactions | CryptoId | FK | Identifies which crypto was sent |
| Wallet.ReceivedTransactions | CryptoId | FK | Identifies which crypto was received |
| Wallet.WalletBalances | CryptoId | FK | Balance snapshots per crypto |
| Wallet.WalletAssets | CryptoId | FK | Asset visibility settings per wallet |
| Wallet.Conversions | FromCryptoId, ToCryptoId | FK | Source and target crypto in conversions |
| Wallet.Payments | CryptoId | FK | Crypto used in payment operations |
| Wallet.AmlProviderContracts | CryptoId | FK | AML provider mapping per crypto |
| Wallet.CryptoMarketRatesMappings | CryptoId | FK | Market rate feed mapping |
| Wallet.PromotionTags | CryptoId | FK | Promotional campaigns per crypto |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.CryptoTypes (table)
├── Wallet.BlockchainCryptos (table)
├── Dictionary.CryptoActivityStatuses (table)
└── Dictionary.AssetTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptos | Table | FK target for BlockchainCryptoId |
| Dictionary.CryptoActivityStatuses | Table | FK target for CryptoActivityStatus |
| Dictionary.AssetTypes | Table | FK target for AssetTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FK on CryptoId |
| Wallet.ReceivedTransactions | Table | FK on CryptoId |
| Wallet.WalletBalances | Table | FK on CryptoId |
| Wallet.WalletAssets | Table | FK on CryptoId |
| Wallet.Conversions | Table | FK on FromCryptoId, ToCryptoId |
| Wallet.Payments | Table | FK on CryptoId |
| Wallet.AmlProviderContracts | Table | FK on CryptoId |
| Wallet.CryptoMarketRatesMappings | Table | FK on CryptoId |
| Wallet.PromotionTags | Table | FK on CryptoId |
| Wallet.GetCryptoData | Stored Procedure | Primary crypto configuration reader |
| Wallet.AssignWallet | Stored Procedure | Reads crypto config during wallet assignment |
| Wallet.GetAllCryptoAcctTypes | Stored Procedure | Lists all crypto asset types |
| 14+ additional procedures | Stored Procedure | Various operations using crypto configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CryptoTypes | CLUSTERED PK | CryptoID ASC | - | - | Active |
| IX_Wallet_CryptoTypes__InstrumentId | NC | InstrumentId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Occurred) | DEFAULT | getutcdate() |
| DF (IsActive) | DEFAULT | 0 - new assets start inactive until explicitly enabled |
| DF (StartMonitoringDelaySeconds) | DEFAULT | 120 - 2 minute monitoring delay |
| DF (BalanceThreshold) | DEFAULT | 0.00001 - dust detection threshold |
| DF (InitialFeeUnits) | DEFAULT | 0 - no initial fee by default |
| DF (OrderIndex) | DEFAULT | 0 |
| FK_...CryptoActivityStatus | FK | CryptoActivityStatus -> Dictionary.CryptoActivityStatuses.Id |
| FK_...AssetTypeId | FK | AssetTypeId -> Dictionary.AssetTypes.Id |
| FK_...BlockchainCryptoId | FK | BlockchainCryptoId -> Wallet.BlockchainCryptos.Id |

---

## 8. Sample Queries

### 8.1 List all available native coins
```sql
SELECT ct.CryptoID, ct.Name, ct.DisplayName, bc.Name AS Blockchain, at.Name AS AssetType
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON ct.BlockchainCryptoId = bc.Id
JOIN Dictionary.AssetTypes at WITH (NOLOCK) ON ct.AssetTypeId = at.Id
WHERE ct.AssetTypeId = 1  -- Native coins
  AND ct.CryptoActivityStatus = 2  -- Available
ORDER BY ct.OrderIndex
```

### 8.2 Find ERC-20 tokens on Ethereum
```sql
SELECT ct.CryptoID, ct.Name, ct.DisplayName, ct.AssetBlockchainAddress
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
WHERE ct.AssetTypeId = 2  -- ERC20
  AND ct.IsActive = 1
ORDER BY ct.OrderIndex
```

### 8.3 Crypto configuration with activity status
```sql
SELECT ct.CryptoID, ct.DisplayName, cas.Name AS ActivityStatus,
    ct.MinReqVerifications, ct.MaxVerificationTimeMinutes, ct.[Precision]
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Dictionary.CryptoActivityStatuses cas WITH (NOLOCK) ON ct.CryptoActivityStatus = cas.Id
ORDER BY ct.CryptoID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Blockchain Glossary | Confluence | General blockchain terminology applicable to crypto asset classification |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 8.7/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 17 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CryptoTypes | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.CryptoTypes.sql*
