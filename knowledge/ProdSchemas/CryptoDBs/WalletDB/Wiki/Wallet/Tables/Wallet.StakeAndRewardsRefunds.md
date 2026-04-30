# Wallet.StakeAndRewardsRefunds

> Records pending and completed staking refund operations where staked crypto principal and accumulated rewards are returned to the customer's wallet.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active NC (1 unique filtered) + 1 clustered PK |

---

## 1. Business Meaning

This table records staking refund requests - operations where crypto that was previously staked for rewards is returned to the customer's wallet. Each row represents one refund request linking a wallet, crypto, amount, and processing status. With 1,396 rows, staking refunds are relatively infrequent, corresponding to the StakeAndRewardsRefund transaction type (14) in SentTransactions.

The `IsActive` flag with a filtered unique index on (WalletId, CryptoId) WHERE IsActive=1 ensures only one active refund per wallet-crypto combination at a time, preventing double-refunds.

---

## 2. Business Logic

### 2.1 Single Active Refund Constraint

**What**: Only one refund can be active per wallet-crypto combination.

**Columns/Parameters Involved**: `WalletId`, `CryptoId`, `IsActive`

**Rules**:
- IsActive=1: Refund is pending or in-progress. Unique constraint prevents a second active refund.
- IsActive=0/NULL: Refund completed or cancelled. Slot freed for a new refund.
- Processing handled by GetPendingStakeAndRewardsRefundTransactions and InsertStakeAndRewardsRefundRequest procedures.

---

## 3. Data Overview

N/A for low-volume operational table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID requesting the refund. |
| 3 | CryptoId | int | NO | - | VERIFIED | Cryptocurrency being refunded. FK to Wallet.CryptoTypes.CryptoID. |
| 4 | WalletId | uniqueidentifier | NO | - | VERIFIED | Customer wallet receiving the refund. FK to Wallet.Wallets.WalletId. |
| 5 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent request. |
| 6 | Amount | decimal(26,18) | NO | - | CODE-BACKED | Amount of crypto being refunded (principal + rewards). |
| 7 | IsActive | bit | YES | 1 | CODE-BACKED | Whether this refund is currently active/pending. Part of unique constraint. |
| 8 | Comment | nvarchar(256) | NO | - | CODE-BACKED | Description of the refund reason. |
| 9 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of refund creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Crypto being refunded |
| WalletId | Wallet.Wallets | FK | Target wallet |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertStakeAndRewardsRefundRequest | - | Writer | Creates refund requests |
| Wallet.GetPendingStakeAndRewardsRefundTransactions | - | Reader | Finds pending refunds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StakeAndRewardsRefunds (table)
├── Wallet.CryptoTypes (table)
└── Wallet.Wallets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.Wallets | Table | FK target for WalletId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertStakeAndRewardsRefundRequest | Stored Procedure | Creates records |
| Wallet.GetPendingStakeAndRewardsRefundTransactions | Stored Procedure | Finds pending refunds |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StakeAndRewardsRefunds | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Unique_Active_Wallet | NC UNIQUE | WalletId, CryptoId | - | WHERE IsActive=1 | Active |
| IX_...CryptoId_WalletId | NC | CryptoId, WalletId | - | - | Active |
| IX_...Occurred | NC | Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (IsActive) | DEFAULT | 1 |
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...CryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Find active refund requests
```sql
SELECT Id, Gcid, ct.Name AS Crypto, Amount, Comment, Occurred
FROM Wallet.StakeAndRewardsRefunds sar WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON sar.CryptoId = ct.CryptoID
WHERE sar.IsActive = 1
```

### 8.2 Refund history for a customer
```sql
SELECT Id, ct.Name AS Crypto, Amount, IsActive, Occurred
FROM Wallet.StakeAndRewardsRefunds sar WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON sar.CryptoId = ct.CryptoID
WHERE sar.Gcid = 35569867
ORDER BY sar.Occurred DESC
```

### 8.3 Total refunded by crypto
```sql
SELECT ct.Name AS Crypto, COUNT(*) AS Cnt, SUM(sar.Amount) AS TotalRefunded
FROM Wallet.StakeAndRewardsRefunds sar WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON sar.CryptoId = ct.CryptoID
GROUP BY ct.Name ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StakeAndRewardsRefunds | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.StakeAndRewardsRefunds.sql*
