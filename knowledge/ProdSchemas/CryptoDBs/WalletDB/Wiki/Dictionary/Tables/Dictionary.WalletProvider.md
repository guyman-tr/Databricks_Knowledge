# Dictionary.WalletProvider

> Lookup table of blockchain custody providers that manage wallet key generation, transaction signing, and blockchain interaction for the eToro crypto platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This is the most heavily referenced Dictionary table in WalletDB (40+ consumers). It defines the blockchain custody providers that the platform uses for wallet management. Every wallet, wallet pool entry, blockchain crypto provider, and transaction sync run is tagged with a WalletProviderId to identify which custody infrastructure manages it.

The wallet provider determines the entire stack for blockchain interaction: key management, address generation, transaction signing, fee estimation, and blockchain monitoring. Switching providers for a wallet would require key migration - a complex and risky operation.

FK-referenced by `Wallet.WalletPool`, `Wallet.BlockchainCryptoProviders`, `Wallet.TransactionsSyncRuns`, and `Wallet.WebhookTransactions`. Consumed by 40+ stored procedures and views.

---

## 2. Business Logic

### 2.1 Custody Provider Infrastructure

**What**: Three custody providers serving different infrastructure needs.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Bitgo` (1): Primary third-party custody provider (BitGo). Enterprise-grade multi-sig wallet security. Used for the majority of customer wallets and production blockchain operations. Hot wallet and cold storage.
- `CUG` (2): eToro's own custody solution (Crypto Unified Gateway). Internal custody infrastructure for specific blockchain operations. May handle newer chains or custom requirements.
- `None` (3): No custody provider. Used for system-internal records or operations that don't require blockchain key management (e.g., fiat-side operations linked to crypto).

**Diagram**:
```
Wallet Creation Request
    |
    +---> Route to Bitgo (1)  [Primary - most wallets]
    |       Multi-sig security, institutional custody
    |
    +---> Route to CUG (2)    [Internal - custom chains]
    |       eToro's own custody infrastructure
    |
    +---> None (3)             [Non-blockchain records]
            No key management needed
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Bitgo | BitGo Inc. - enterprise cryptocurrency custody provider. Provides multi-signature wallet security, transaction signing, and blockchain monitoring. Used for the majority of customer-facing wallets across Bitcoin, Ethereum, and other major chains. |
| 2 | CUG | Crypto Unified Gateway - eToro's internal custody solution. Provides custody infrastructure for specific use cases not served by BitGo, potentially newer blockchains or custom operational requirements. |
| 3 | None | No custody provider. Placeholder for records that exist in wallet-related tables but do not require actual blockchain key management. Used for fiat-linked operations or system records. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Unique identifier. Values: 1=Bitgo, 2=CUG, 3=None. FK target for WalletPool, BlockchainCryptoProviders, TransactionsSyncRuns, WebhookTransactions, and 40+ SPs. The most referenced column in WalletDB after RequestStatuses.Id. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Provider name. Used throughout the application for routing blockchain operations to the correct custody infrastructure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.WalletPool | WalletProviderId | FK | Each pool address is managed by a provider |
| Wallet.BlockchainCryptoProviders | WalletProviderId | FK | Maps blockchain providers to their custody provider |
| Wallet.TransactionsSyncRuns | WalletProviderId | FK | Tags sync runs by provider |
| Wallet.WebhookTransactions | WalletProviderId | FK | Tags webhook events by provider |
| Dictionary.CryptoCoinProviders | WalletProviderId | FK | Maps coin providers to custody providers |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK |
| Wallet.BlockchainCryptoProviders | Table | FK |
| Dictionary.CryptoCoinProviders | Table | FK |
| Wallet.CustomerWalletsView | View | JOINs for wallet display |
| Wallet.GetWalletProviders | Stored Procedure | Lists all providers |
| Wallet.GetWalletsByGcid | Stored Procedure | Filters wallets by provider |
| Wallet.GetAllWallets | Stored Procedure | Includes provider in results |
| 35+ additional SPs | Various | Provider-based wallet queries and operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletProvider_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all wallet providers
```sql
SELECT Id, Name FROM Dictionary.WalletProvider WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count wallets by provider
```sql
SELECT wp_dict.Name, COUNT(wp.WalletPoolId) AS PoolCount
FROM Dictionary.WalletProvider wp_dict WITH (NOLOCK)
LEFT JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wp.WalletProviderId = wp_dict.Id
GROUP BY wp_dict.Name ORDER BY PoolCount DESC
```

### 8.3 Provider infrastructure overview
```sql
SELECT wp_dict.Name AS Provider, COUNT(DISTINCT bcp.BlockchainCryptoProviderId) AS CryptoProviderCount
FROM Dictionary.WalletProvider wp_dict WITH (NOLOCK)
LEFT JOIN Wallet.BlockchainCryptoProviders bcp WITH (NOLOCK) ON bcp.WalletProviderId = wp_dict.Id
GROUP BY wp_dict.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 40 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WalletProvider | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.WalletProvider.sql*
