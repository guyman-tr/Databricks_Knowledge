# Dictionary.CryptoCoinProviders

> Lookup table mapping blockchain-specific provider implementations (e.g., BitGo Bitcoin, BitGo Ethereum) to their parent custody provider (BitGo, CUG).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique (Name) |

---

## 1. Business Meaning

This table maps blockchain-specific provider implementations to their parent wallet custody provider. While `Dictionary.WalletProvider` defines the custody companies (BitGo, CUG), this table defines the specific blockchain integrations each custody provider offers. For example, BitGo provides separate implementations for Bitcoin (BitGoBlockchainProviderV2), Ethereum (BitGoEthereumProviderV2), Ripple, Stellar, EOS, and Tron.

Each crypto coin provider represents a distinct API integration and blockchain interaction layer. The platform routes transactions through the correct coin provider based on the cryptocurrency being transacted.

FK-referenced by `Wallet.BlockchainCryptoProviders` and `Wallet.BlockchainCryptos`.

---

## 2. Business Logic

### 2.1 Provider-to-Blockchain Mapping

**What**: Nine coin-specific provider implementations across two custody providers.

**Columns/Parameters Involved**: `Id`, `Name`, `WalletProviderId`

**Rules**:
- **BitGo implementations** (WalletProviderId=1): BitGoBlockchainProviderV2 (1), BitGoEthereumProviderV2 (2), BitgoRippleProviderV2 (3), BitGoStellarProviderV2 (4), BitGoEOSProviderV2 (5), BitGoTronProviderV2 (7), BitGoEthereumClassicProviderV2 (8)
- **CUG implementations** (WalletProviderId=2): CUGBlockchainProvider (6), CUGAccountBasedBlockchainProvider (9)
- All BitGo providers use "V2" suffix, indicating they are the second-generation API integration
- CUG providers distinguish between UTXO-based (CUGBlockchainProvider) and account-based (CUGAccountBasedBlockchainProvider) chains

**Diagram**:
```
Dictionary.WalletProvider       Dictionary.CryptoCoinProviders
  Bitgo (1) -----------------> BitGoBlockchainProviderV2 (1) [BTC, LTC, BCH]
                            |-> BitGoEthereumProviderV2 (2) [ETH, ERC-20]
                            |-> BitgoRippleProviderV2 (3) [XRP]
                            |-> BitGoStellarProviderV2 (4) [XLM]
                            |-> BitGoEOSProviderV2 (5) [EOS]
                            |-> BitGoTronProviderV2 (7) [TRX]
                            |-> BitGoEthereumClassicProviderV2 (8) [ETC]

  CUG (2) ------------------> CUGBlockchainProvider (6) [UTXO chains]
                            |-> CUGAccountBasedBlockchainProvider (9) [account chains]
```

---

## 3. Data Overview

| Id | Name | WalletProviderId | Meaning |
|---|---|---|---|
| 1 | BitGoBlockchainProviderV2 | 1 | BitGo's generic UTXO blockchain provider. Handles Bitcoin, Litecoin, Bitcoin Cash, and other UTXO-model chains. V2 indicates the second-generation API. |
| 2 | BitGoEthereumProviderV2 | 1 | BitGo's Ethereum-specific provider. Handles ETH native transfers and all ERC-20 token transactions. Manages gas estimation and contract interactions. |
| 6 | CUGBlockchainProvider | 2 | eToro's internal custody (CUG) for UTXO-based blockchains. Alternative to BitGo for specific operational needs. |
| 7 | BitGoTronProviderV2 | 1 | BitGo's Tron-specific provider. Handles TRX and TRC-20 token transactions. Added to support the Tron ecosystem. |
| 9 | CUGAccountBasedBlockchainProvider | 2 | eToro's internal custody for account-based blockchains (e.g., Ethereum-compatible chains managed by CUG instead of BitGo). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1-9 mapping to specific blockchain/provider combinations. FK target for Wallet.BlockchainCryptoProviders and Wallet.BlockchainCryptos. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Unique provider implementation name. Maps to application-layer class names that implement blockchain interaction logic. |
| 3 | WalletProviderId | int | NO | 1 (Bitgo) | CODE-BACKED | FK to Dictionary.WalletProvider. Links this blockchain-specific implementation to its parent custody provider. Default is 1 (BitGo), indicating most coin providers are BitGo-managed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletProviderId | Dictionary.WalletProvider | FK | Parent custody provider for this blockchain implementation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.BlockchainCryptoProviders | CryptoCoinProviderId | FK | Maps supported blockchains to their provider implementation |
| Wallet.BlockchainCryptos | CryptoCoinProviderId | FK | Links individual cryptocurrencies to their provider |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CryptoCoinProviders (table)
  +-- Dictionary.WalletProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WalletProvider | Table | FK on WalletProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptoProviders | Table | FK |
| Wallet.BlockchainCryptos | Table | FK |
| Wallet.GetBlockchainCryptoProviders | Stored Procedure | Reads coin providers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CryptoCoinProviders | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ_CryptoCoinProviders_Name | UNIQUE | Name - No duplicate provider names |
| FK_..._WalletProviderId | FOREIGN KEY | WalletProviderId -> Dictionary.WalletProvider(Id) |
| DEFAULT | DEFAULT | WalletProviderId defaults to 1 (BitGo) |

---

## 8. Sample Queries

### 8.1 List all coin providers with their custody provider
```sql
SELECT ccp.Id, ccp.Name AS CoinProvider, wp.Name AS CustodyProvider
FROM Dictionary.CryptoCoinProviders ccp WITH (NOLOCK)
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON ccp.WalletProviderId = wp.Id
ORDER BY ccp.Id
```

### 8.2 Coin providers by custody provider
```sql
SELECT wp.Name AS CustodyProvider, COUNT(ccp.Id) AS CoinProviderCount
FROM Dictionary.WalletProvider wp WITH (NOLOCK)
LEFT JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON ccp.WalletProviderId = wp.Id
GROUP BY wp.Name
```

### 8.3 Blockchain cryptos with their provider chain
```sql
SELECT bc.Name AS Crypto, ccp.Name AS CoinProvider, wp.Name AS Custody
FROM Wallet.BlockchainCryptos bc WITH (NOLOCK)
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON bc.CryptoCoinProviderId = ccp.Id
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON ccp.WalletProviderId = wp.Id
ORDER BY bc.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoCoinProviders | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.CryptoCoinProviders.sql*
