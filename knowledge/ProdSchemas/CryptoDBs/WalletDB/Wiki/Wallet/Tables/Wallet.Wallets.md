# Wallet.Wallets

> Central registry of all customer and system wallets, linking each wallet to its owner (Gcid), blockchain, and operational purpose (type). The core entity connecting users to their crypto holdings.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK); WalletId (uniqueidentifier, unique business key) |
| **Partition** | No |
| **Indexes** | 7 active NC (2 unique) + 1 clustered PK |
| **Temporal** | Yes - SYSTEM_VERSIONING with history table dbo.Wallets |

---

## 1. Business Meaning

This table is the central wallet registry for the eToro crypto platform. Each row represents a wallet assigned to a customer (Gcid) for a specific blockchain and purpose. With ~1.49M entries, the vast majority (99.99%) are type 5 (Customer) wallets - the standard user-facing wallets for holding, sending, and receiving crypto. A small number of system wallets exist for redemptions, conversions, funding, payments, and staking operations.

Without this table, there would be no mapping between customers and their crypto wallets. It is the core entity that connects a user's identity (Gcid) to their blockchain presence (WalletId). Every transaction, balance lookup, and wallet operation starts by resolving the wallet from this table.

Wallets are created when a user first accesses a cryptocurrency in the wallet. A pool wallet from `Wallet.WalletPool` is assigned to the customer via `Wallet.AssociateWalletToCustomer` / `Wallet.AssignWallet`. The `WalletId` GUID serves as the universal wallet identifier across all dependent tables. The table uses temporal versioning for audit trail of wallet state changes.

---

## 2. Business Logic

### 2.1 Wallet Type Architecture

**What**: Wallets are classified by operational purpose, with customer wallets being the primary type.

**Columns/Parameters Involved**: `WalletTypeId`, `Gcid`, `BlockchainCryptoId`

**Rules**:
- Type 5 (Customer): 1,486,781 wallets - standard user wallets, one per user per blockchain
- Type 1 (Redeem): 13 system wallets for receiving redemption transfers
- Type 2 (Conversion): 8 system wallets for holding crypto during swaps
- Type 3 (Funding): 8 system wallets for pool pre-funding operations
- Type 4 (Payment): 8 system wallets for fiat payment-linked operations
- Type 6 (C2F): 2 system wallets for crypto-to-fiat conversion flows
- Type 7 (StakingRefund): 1 system wallet for staking refunds
- See [Wallet Type](../../_glossary.md#wallet-type). FK to Dictionary.WalletTypes.
- Customer wallets have unique constraint on (Gcid, BlockchainCryptoId, WalletTypeId) excluding types 1 and 6

### 2.2 Wallet Activation

**What**: Wallets track both active status and activation status independently.

**Columns/Parameters Involved**: `IsActive`, `IsActivated`

**Rules**:
- `IsActive`: Whether the wallet is currently operational (can be deactivated by `Wallet.DeactivateWallet`)
- `IsActivated`: Whether the wallet has completed its initial activation process (blockchain confirmation)
- Both default to 1 (true) for new wallets
- A deactivated wallet (IsActive=0) retains its funds but cannot initiate new transactions

---

## 3. Data Overview

| Id | WalletId | Gcid | BlockchainCryptoId | WalletTypeId | IsActive | Meaning |
|---|---|---|---|---|---|---|
| 1571786 | D0D76DE6-... | 35281480 | 2 (ETH) | 5 (Customer) | true | A customer's Ethereum wallet, just created. The most common type of wallet entry. |
| 1571785 | A0284D52-... | 40133357 | 19 (DOGE) | 5 (Customer) | true | A customer's Dogecoin wallet. Each user gets one wallet per supported blockchain. |
| 1571782 | 5FAB6007-... | 46430223 | 1 (BTC) | 5 (Customer) | true | A customer's Bitcoin wallet - the most fundamental wallet type. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | Internal wallet identifier (GUID). Unique constraint. The universal business key used across the entire system. FK target for Wallet.SentTransactions, Wallet.Conversions, Wallet.Payments, Wallet.Redemptions, and Wallet.WalletAssets. Matches the WalletId in Wallet.WalletPool from which this wallet was assigned. |
| 3 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. For system wallets (types 1-4, 6-7), this is a system/service account ID. For customer wallets (type 5), this is the real user. Indexed for per-customer lookups. |
| 4 | BlockchainCryptoId | int | NO | - | VERIFIED | The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Combined with Gcid and WalletTypeId for unique customer wallet constraint. |
| 5 | WalletTypeId | tinyint | NO | - | VERIFIED | Operational purpose: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See [Wallet Type](../../_glossary.md#wallet-type). FK to Dictionary.WalletTypes. |
| 6 | IsActive | bit | NO | 1 | CODE-BACKED | Whether this wallet is currently operational. 1=active, 0=deactivated (funds locked, no new transactions). Set to 0 by Wallet.DeactivateWallet. |
| 7 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this wallet was created/assigned to the customer. |
| 8 | BeginDate | datetime2(7) | NO | - | CODE-BACKED | System-versioned temporal column (ROW START). Tracks when this version of the row became current. |
| 9 | EndDate | datetime2(7) | NO | - | CODE-BACKED | System-versioned temporal column (ROW END). Default 9999-12-31 for current rows. |
| 10 | IsActivated | bit | NO | 1 | CODE-BACKED | Whether the wallet has completed blockchain activation. 1=fully activated, 0=pending activation (awaiting on-chain confirmation). Most wallets are immediately activated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockchainCryptoId | Wallet.BlockchainCryptos | FK | Identifies the blockchain network |
| WalletTypeId | Dictionary.WalletTypes | FK | Classifies the wallet's operational purpose |
| WalletId | Wallet.WalletPool | Implicit | Links back to the pool wallet from which this was assigned |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SentTransactions | WalletId | FK | Outgoing transactions reference the sending wallet |
| Wallet.Conversions | FromWalletId, ToWalletId | FK | Conversion source and target wallets |
| Wallet.Payments | WalletId | FK | Payments reference the associated wallet |
| Wallet.Redemptions | SourceWalletId | FK | Redemptions reference the source wallet |
| Wallet.WalletAssets | WalletId | FK | Asset visibility settings per wallet |
| Wallet.ConversionTransactions | WalletId | FK | Conversion transaction details per wallet |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Wallets (table)
├── Wallet.BlockchainCryptos (table)
└── Dictionary.WalletTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptos | Table | FK target for BlockchainCryptoId |
| Dictionary.WalletTypes | Table | FK target for WalletTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FK on WalletId |
| Wallet.Conversions | Table | FK on FromWalletId, ToWalletId |
| Wallet.Payments | Table | FK on WalletId |
| Wallet.Redemptions | Table | FK on SourceWalletId |
| Wallet.WalletAssets | Table | FK on WalletId |
| Wallet.ConversionTransactions | Table | FK on WalletId |
| Wallet.AssignWallet | Stored Procedure | Assigns pool wallet to customer |
| Wallet.AssociateWalletToCustomer | Stored Procedure | Associates wallet with customer account |
| Wallet.DeactivateWallet | Stored Procedure | Deactivates a wallet |
| Wallet.StoreWallet | Stored Procedure | Inserts/updates wallet records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Wallets | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Wallets__WalletId | NC UNIQUE | WalletId ASC | - | - | Active |
| IX_Wallet_Wallets__Gcid_BlockchainCryptoId_WalletTypeId | NC UNIQUE | Gcid, BlockchainCryptoId, WalletTypeId | - | WHERE IsActive=1 AND WalletTypeId NOT IN (1,6) | Active |
| IX_Wallet_Wallets_BlockchainCryptoId_Occurred_Inc | NC | BlockchainCryptoId, Occurred | WalletId | - | Active |
| IX_Wallet_Wallets_Gcid_BlockchainCryptoId | NC | Gcid, BlockchainCryptoId | - | - | Active |
| IX_Wallets_IsActive_Inc_Gcid_WalletId | NC | IsActive | Gcid, WalletId | - | Active |
| IX_Wallets_IsActive_IsActivated_Inc | NC | IsActive, IsActivated | BlockchainCryptoId, Gcid, WalletId | - | Active |
| nci_wi_Wallets_CryptoId_Gcid_WalletTypeId | NC | BlockchainCryptoId, Gcid, WalletTypeId | WalletId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (IsActive) | DEFAULT | 1 - wallets are active by default |
| DF_Wallet_Wallets__Occurred | DEFAULT | getutcdate() |
| DF (IsActivated) | DEFAULT | 1 - wallets are activated by default |
| FK_...BlockchainCryptoId | FK | BlockchainCryptoId -> Wallet.BlockchainCryptos.Id |
| FK_...WalletTypeId | FK | WalletTypeId -> Dictionary.WalletTypes.Id |

---

## 8. Sample Queries

### 8.1 Get all wallets for a customer
```sql
SELECT w.WalletId, bc.Name AS Blockchain, wt.Name AS WalletType, w.IsActive, w.Occurred
FROM Wallet.Wallets w WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON w.BlockchainCryptoId = bc.Id
JOIN Dictionary.WalletTypes wt WITH (NOLOCK) ON w.WalletTypeId = wt.Id
WHERE w.Gcid = 30351701
ORDER BY w.Occurred
```

### 8.2 Find a wallet by WalletId
```sql
SELECT w.Id, w.Gcid, bc.Name AS Blockchain, wt.Name AS WalletType, w.IsActive, w.IsActivated
FROM Wallet.Wallets w WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON w.BlockchainCryptoId = bc.Id
JOIN Dictionary.WalletTypes wt WITH (NOLOCK) ON w.WalletTypeId = wt.Id
WHERE w.WalletId = 'D0D76DE6-0010-4879-9CB0-FD6C35F3BC2C'
```

### 8.3 Count active customer wallets per blockchain
```sql
SELECT bc.Name AS Blockchain, COUNT(*) AS ActiveWallets
FROM Wallet.Wallets w WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON w.BlockchainCryptoId = bc.Id
WHERE w.WalletTypeId = 5 AND w.IsActive = 1
GROUP BY bc.Name
ORDER BY ActiveWallets DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Wallets | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Wallets.sql*
