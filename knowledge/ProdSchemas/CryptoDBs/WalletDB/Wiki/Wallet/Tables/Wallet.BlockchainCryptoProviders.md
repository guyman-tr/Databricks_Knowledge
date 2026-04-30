# Wallet.BlockchainCryptoProviders

> Junction table mapping which wallet providers (BitGo, CUG) serve each blockchain network, linking blockchains to their specific coin provider implementations for multi-provider support.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table maps each supported blockchain to the wallet providers and coin provider implementations that can serve it. While `Wallet.BlockchainCryptos.CryptoCoinProviderId` defines the primary provider for a blockchain, this table enables multi-provider support - a blockchain can be served by BitGo, CUG (Crypto Unified Gateway), or both. Each row represents a specific combination of blockchain, wallet provider, and coin provider implementation.

This mapping is essential for provider routing and failover. When the system needs to create a wallet or sign a transaction for a blockchain, it looks up which providers are available here. Most blockchains have two entries: one for their active provider (BitGo or CUG) and one for "None" (WalletProviderId=3), which represents internal/virtual operations that don't require an external provider.

Data is inserted when new blockchains are onboarded or when a blockchain migrates to a new provider. The 25 rows cover all 12 blockchains, with most having 2 entries. Referenced by `Wallet.GetBlockchainCryptoProviders` for provider resolution during wallet operations.

---

## 2. Business Logic

### 2.1 Multi-Provider Architecture

**What**: Each blockchain can be served by multiple wallet providers simultaneously, enabling provider-specific routing and gradual migrations.

**Columns/Parameters Involved**: `BlockchainCryptoId`, `WalletProviderId`, `CryptoCoinProviderid`

**Rules**:
- Unique constraint on (BlockchainCryptoId, WalletProviderId) - one implementation per provider per blockchain
- WalletProviderId 1 (BitGo) entries exist for original blockchains (BTC, ETH, BCH, XRP, LTC, XLM, EOS, ETC)
- WalletProviderId 2 (CUG) entries exist for newer chains (ADA, BTC secondary, DOGE, SOL) and migrated chains
- WalletProviderId 3 (None) exists for most blockchains - represents internal-only operations
- CryptoCoinProviderid identifies the specific implementation class (see [Crypto Coin Provider](../../_glossary.md#crypto-coin-provider))

**Diagram**:
```
Blockchain (e.g., BTC, Id=1)
├── WalletProvider: BitGo (1) --> CryptoCoinProvider: BitGoBlockchainProviderV2 (1)
├── WalletProvider: CUG (2) --> CryptoCoinProvider: CUGBlockchainProvider (6)
└── WalletProvider: None (3) --> CryptoCoinProvider: BitGoBlockchainProviderV2 (1)
```

---

## 3. Data Overview

| Id | BlockchainCryptoId | WalletProviderId | CryptoCoinProviderid | Meaning |
|---|---|---|---|---|
| 1 | 1 (BTC) | 1 (BitGo) | 1 (BitGoBlockchainProviderV2) | Bitcoin served by BitGo using their UTXO blockchain provider - the primary production path for BTC wallets |
| 17 | 18 (ADA) | 2 (CUG) | 6 (CUGBlockchainProvider) | Cardano served by CUG - newer chains use eToro's internal gateway instead of BitGo |
| 19 | 1 (BTC) | 2 (CUG) | 6 (CUGBlockchainProvider) | Bitcoin also available via CUG - enables gradual migration or A/B testing of providers |
| 24 | 64 (SOL) | 2 (CUG) | 9 (CUGAccountBasedBlockchainProvider) | Solana served by CUG's account-based provider - the newest blockchain addition |
| 2 | 1 (BTC) | 3 (None) | 1 (BitGoBlockchainProviderV2) | BTC "None" provider entry - used for internal operations that don't require external provider calls |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | BlockchainCryptoId | int | NO | - | VERIFIED | The blockchain network this mapping applies to. FK to Wallet.BlockchainCryptos.Id. Values: 1=BTC, 2=ETH, 3=BCH, 4=XRP, 6=LTC, 8=ETC, 18=ADA, 19=DOGE, 21=XLM, 23=EOS, 27=TRX, 64=SOL. |
| 3 | WalletProviderId | int | NO | - | VERIFIED | Top-level wallet custody provider: 1=BitGo (institutional multi-sig custody), 2=CUG (Crypto Unified Gateway, eToro internal), 3=None (internal/virtual operations). See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider. |
| 4 | CryptoCoinProviderid | tinyint | NO | - | VERIFIED | Specific coin provider implementation class for this blockchain/provider combination. Maps to the technical API adapter: 1=BitGoBlockchainProviderV2, 2=BitGoEthereumProviderV2, 3=BitgoRippleProviderV2, 4=BitGoStellarProviderV2, 5=BitGoEOSProviderV2, 6=CUGBlockchainProvider, 7=BitGoTronProviderV2, 8=BitGoEthereumClassicProviderV2, 9=CUGAccountBasedBlockchainProvider. See [Crypto Coin Provider](../../_glossary.md#crypto-coin-provider). FK to Dictionary.CryptoCoinProviders. |
| 5 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this provider mapping was created. Enables tracking when blockchains were onboarded to specific providers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockchainCryptoId | Wallet.BlockchainCryptos | FK | Identifies which blockchain network this mapping is for |
| WalletProviderId | Dictionary.WalletProvider | FK | Identifies the top-level wallet custody provider |
| CryptoCoinProviderid | Dictionary.CryptoCoinProviders | FK | Identifies the specific coin provider implementation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetBlockchainCryptoProviders | - | Reader | Retrieves provider mappings for routing decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.BlockchainCryptoProviders (table)
├── Wallet.BlockchainCryptos (table)
├── Dictionary.WalletProvider (table)
└── Dictionary.CryptoCoinProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptos | Table | FK target for BlockchainCryptoId |
| Dictionary.WalletProvider | Table | FK target for WalletProviderId |
| Dictionary.CryptoCoinProviders | Table | FK target for CryptoCoinProviderid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetBlockchainCryptoProviders | Stored Procedure | Reads all provider mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlockchainCryptoProviders | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_BlockchainCryptoProviders__BlockchainCryptoId_WalletProviderId | NC UNIQUE | BlockchainCryptoId ASC, WalletProviderId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_BlockchainCryptoProviders__Occurred | DEFAULT | getutcdate() |
| FK_...BlockchainCryptoId__Wallet_BlockchainCryptos_Id | FK | BlockchainCryptoId -> Wallet.BlockchainCryptos.Id |
| FK_...WalletProviderId__Dictionary_WalletProvider_Id | FK | WalletProviderId -> Dictionary.WalletProvider.Id |
| FK_...CryptoCoinProviderId__Dictionary_CryptoCoinProviders_Id | FK | CryptoCoinProviderid -> Dictionary.CryptoCoinProviders.Id |

---

## 8. Sample Queries

### 8.1 List all blockchain-provider mappings with names
```sql
SELECT bc.Name AS Blockchain, wp.Name AS WalletProvider, ccp.Name AS CoinProvider, bcp.Occurred
FROM Wallet.BlockchainCryptoProviders bcp WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON bcp.BlockchainCryptoId = bc.Id
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON bcp.WalletProviderId = wp.Id
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON bcp.CryptoCoinProviderid = ccp.Id
ORDER BY bc.Name, wp.Name
```

### 8.2 Find providers for a specific blockchain
```sql
SELECT wp.Name AS Provider, ccp.Name AS Implementation
FROM Wallet.BlockchainCryptoProviders bcp WITH (NOLOCK)
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON bcp.WalletProviderId = wp.Id
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON bcp.CryptoCoinProviderid = ccp.Id
WHERE bcp.BlockchainCryptoId = 1  -- BTC
```

### 8.3 Blockchains using CUG provider
```sql
SELECT bc.Name AS Blockchain, ccp.Name AS Implementation
FROM Wallet.BlockchainCryptoProviders bcp WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON bcp.BlockchainCryptoId = bc.Id
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON bcp.CryptoCoinProviderid = ccp.Id
WHERE bcp.WalletProviderId = 2  -- CUG
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.BlockchainCryptoProviders | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.BlockchainCryptoProviders.sql*
