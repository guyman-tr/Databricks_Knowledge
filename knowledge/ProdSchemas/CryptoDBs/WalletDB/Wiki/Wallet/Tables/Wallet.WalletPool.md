# Wallet.WalletPool

> Pre-generated pool of blockchain wallets created in advance and ready for assignment to customers, providing instant wallet provisioning without waiting for on-chain creation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK); WalletId (uniqueidentifier, unique business key) |
| **Partition** | No |
| **Indexes** | 6 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table stores a pool of pre-created blockchain wallets that have been generated on the blockchain provider (BitGo or CUG) but not yet assigned to any customer. When a user needs a new wallet, the system picks an available wallet from this pool rather than creating one on-chain in real time, enabling near-instant wallet provisioning.

Without this pool, every wallet creation would require an on-chain transaction and confirmation wait (which can take minutes to hours depending on the blockchain). The pool eliminates this latency by maintaining a ready supply of wallets. With ~2.47M entries, this is a substantial pre-provisioning system.

Pool wallets are created by background processes that monitor pool levels and top up when supply runs low. Each wallet has a unique `WalletId` (GUID) and a `PublicAddress` on the blockchain. When assigned to a customer, the wallet is linked via `Wallet.Wallets` and `Wallet.WalletAddresses`. The WalletId serves as the key reference point - it is the FK target for `Wallet.WalletAddresses`, `Wallet.ReceivedTransactions`, and `Wallet.AmlValidations`.

---

## 2. Business Logic

### 2.1 Pool Management Lifecycle

**What**: Wallets move through creation, verification, optional funding, and assignment stages managed by `Wallet.WalletPoolStatuses`.

**Columns/Parameters Involved**: `WalletId`, `BlockchainCryptoId`, `WalletProviderId`

**Rules**:
- Wallets are created per blockchain (BlockchainCryptoId) and per provider (WalletProviderId)
- Pool levels are maintained by background processes that create new wallets when supply drops below thresholds
- See [Wallet Pool Status](../../_glossary.md#wallet-pool-status) for the lifecycle: Pending -> Verified -> FundingInitiated -> FundingVerified -> VerifiedForAssign
- Recent pool entries show SOL (BlockchainCryptoId=64) wallets via CUG provider, indicating active SOL onboarding

### 2.2 Provider Wallet Mapping

**What**: Each pool wallet has both an internal WalletId and a provider-specific identifier.

**Columns/Parameters Involved**: `WalletId`, `ProviderWalletId`, `PublicAddress`

**Rules**:
- `WalletId` is the internal GUID used across the entire wallet system
- `ProviderWalletId` is the identifier assigned by BitGo or CUG
- `PublicAddress` is the blockchain address users can send crypto to
- The unique index on WalletId ensures no duplicate wallets

---

## 3. Data Overview

| Id | WalletId | BlockchainCryptoId | PublicAddress (truncated) | WalletProviderId | Meaning |
|---|---|---|---|---|---|
| 2469129 | DBA0BC4B-... | 64 (SOL) | DRudbp68Muz... | 2 (CUG) | A Solana pool wallet created via CUG, ready for customer assignment. Part of the newest blockchain onboarding. |
| 2469125 | 8383A904-... | 64 (SOL) | 31Ph5Yn6muN... | 2 (CUG) | Another SOL pool wallet. Multiple wallets created in rapid succession indicates pool top-up batch running. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | Internal wallet identifier (GUID). The primary business key used across the wallet system. Unique constraint. FK target for Wallet.WalletAddresses, Wallet.ReceivedTransactions, and Wallet.AmlValidations. Also referenced by Wallet.Wallets (logical link, not FK). |
| 3 | BlockchainCryptoId | int | NO | - | VERIFIED | The blockchain this pool wallet was created for. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain network the PublicAddress belongs to. |
| 4 | ProviderWalletId | nvarchar(100) | NO | - | CODE-BACKED | Wallet identifier assigned by the external custody provider (BitGo or CUG). Used for all API interactions with the provider. Format varies by provider. |
| 5 | PublicAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address associated with this wallet. Users send crypto to this address. NULL during initial creation before address generation completes. Format depends on blockchain (e.g., bc1... for BTC, 0x... for ETH). |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this pool wallet was created. Used for pool age monitoring and FIFO assignment ordering. |
| 7 | WalletProviderId | int | NO | - | VERIFIED | Custody provider that holds the keys: 1=BitGo, 2=CUG, 3=None. See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockchainCryptoId | Wallet.BlockchainCryptos | FK | Identifies which blockchain network |
| WalletProviderId | Dictionary.WalletProvider | FK | Identifies the custody provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.WalletAddresses | WalletId | FK | Links wallet to its blockchain addresses |
| Wallet.ReceivedTransactions | WalletId | FK | Incoming transactions reference the receiving wallet |
| Wallet.AmlValidations | WalletId | FK | AML screenings reference the wallet involved |
| Wallet.WalletPoolStatuses | WalletPoolId (implicit) | Implicit | Tracks pool wallet lifecycle statuses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.WalletPool (table)
├── Wallet.BlockchainCryptos (table)
└── Dictionary.WalletProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptos | Table | FK target for BlockchainCryptoId |
| Dictionary.WalletProvider | Table | FK target for WalletProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | FK on WalletId |
| Wallet.ReceivedTransactions | Table | FK on WalletId |
| Wallet.AmlValidations | Table | FK on WalletId |
| Wallet.InsertWalletToPool | Stored Procedure | Inserts new pool wallets |
| Wallet.GetFreeWalletFromPool | Stored Procedure | Picks an available wallet for assignment |
| Wallet.GetAllWalletsFromPool | Stored Procedure | Lists pool wallets |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletPool_Id | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_WalletPool__WalletId | NC UNIQUE | WalletId ASC | - | - | Active |
| IX_Wallet_WalletPool_BlockchainCryptoId_Created | NC | BlockchainCryptoId, Created | - | - | Active |
| IX_WalletPool_PublicAddress_Inc_WalletId | NC | PublicAddress | WalletId | - | Active |
| ix_WalletPool_WalletId_Inc_ProviderWalletId_PublicAddress | NC | WalletId | ProviderWalletId, PublicAddress | - | Active |
| IX_WalletWalletPool_ProviderWalletId | NC | ProviderWalletId | - | - | Active |
| nci_wi_WalletPool_... | NC | BlockchainCryptoId | PublicAddress, WalletId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_...BlockchainCryptoId__Wallet_BlockchainCryptos_Id | FK | BlockchainCryptoId -> Wallet.BlockchainCryptos.Id |
| FK_...WalletProviderId__Dictionary_WalletProvider_Id | FK | WalletProviderId -> Dictionary.WalletProvider.Id |

---

## 8. Sample Queries

### 8.1 Count pool wallets per blockchain
```sql
SELECT bc.Name AS Blockchain, COUNT(*) AS PoolSize
FROM Wallet.WalletPool wp WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON wp.BlockchainCryptoId = bc.Id
GROUP BY bc.Name
ORDER BY PoolSize DESC
```

### 8.2 Find a wallet by public address
```sql
SELECT wp.WalletId, wp.BlockchainCryptoId, wp.PublicAddress, wp.WalletProviderId, wp.Created
FROM Wallet.WalletPool wp WITH (NOLOCK)
WHERE wp.PublicAddress = 'DRudbp68Muznc6SBsQ687EXe7f8iK41xhyy1xZZLi5VQ'
```

### 8.3 Recent pool wallet creations
```sql
SELECT TOP 10 wp.Id, bc.Name AS Blockchain, wpr.Name AS Provider, wp.Created
FROM Wallet.WalletPool wp WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON wp.BlockchainCryptoId = bc.Id
JOIN Dictionary.WalletProvider wpr WITH (NOLOCK) ON wp.WalletProviderId = wpr.Id
ORDER BY wp.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletPool | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletPool.sql*
