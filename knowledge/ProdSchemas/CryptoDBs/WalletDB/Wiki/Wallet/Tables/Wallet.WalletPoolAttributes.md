# Wallet.WalletPoolAttributes

> Stores supplementary attributes for pool wallets, including reserved amounts and creation fees, providing additional configuration data beyond the core WalletPool record.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table extends `Wallet.WalletPool` with additional attributes that don't belong in the core table. Each row stores the reserved amount and optional creation fee for a specific pool wallet. The reserved amount represents funds that must remain in the wallet (e.g., for Ripple's minimum reserve requirement or Stellar's base reserve), while the creation fee records the cost of creating the wallet on-chain.

With ~237K rows (compared to 2.47M pool wallets), not every pool wallet has attributes - only blockchains that require minimum reserves or have creation fees.

---

## 2. Business Logic

### 2.1 Blockchain Reserve Requirements

**What**: Some blockchains require wallets to maintain a minimum balance that cannot be spent.

**Columns/Parameters Involved**: `ReservedAmount`, `WalletPoolId`

**Rules**:
- ReservedAmount stores the blockchain's minimum reserve requirement (e.g., 1.2 XRP for Ripple accounts)
- This amount is excluded from the user's "available balance" - they can see it but not spend it
- Recent entries all show ReservedAmount=1.2, consistent with XRP's minimum reserve

---

## 3. Data Overview

| Id | WalletPoolId | ReservedAmount | CreationFee | Meaning |
|---|---|---|---|---|
| 237233 | 2399982 | 1.2 | NULL | XRP wallet with 1.2 XRP minimum reserve. No creation fee. |
| 237232 | 2399981 | 1.2 | NULL | Another XRP wallet with standard reserve |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | WalletPoolId | bigint | NO | - | VERIFIED | The pool wallet this attribute record belongs to. FK to Wallet.WalletPool.Id. Unique constraint - one attributes record per pool wallet. |
| 3 | ReservedAmount | decimal(18,9) | NO | - | CODE-BACKED | Amount of crypto that must remain in the wallet as a blockchain-mandated minimum reserve. Cannot be withdrawn by the user. Common for XRP (1.2) and XLM (1.0). |
| 4 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this attributes record was created. |
| 5 | CreationFee | decimal(18,9) | YES | - | CODE-BACKED | Fee paid to create this wallet on the blockchain. NULL for blockchains without on-chain wallet creation fees. Relevant for account-based blockchains like EOS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletPoolId | Wallet.WalletPool | FK | Links to the pool wallet |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetWalletPoolReservedAmount | - | Reader | Reads reserved amount for balance calculations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.WalletPoolAttributes (table)
└── Wallet.WalletPool (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK target for WalletPoolId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetWalletPoolReservedAmount | Stored Procedure | Reads reserved amounts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletPoolAttributes | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_WalletPoolAttributes__WalletPoolId | NC UNIQUE | WalletPoolId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_WalletPoolAttributes__Occurred | DEFAULT | getutcdate() |
| FK_...WalletPoolId__Wallet_WalletPool_Id | FK | WalletPoolId -> Wallet.WalletPool.Id |

---

## 8. Sample Queries

### 8.1 Get reserved amount for a wallet
```sql
SELECT wpa.ReservedAmount, wpa.CreationFee
FROM Wallet.WalletPoolAttributes wpa WITH (NOLOCK)
JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wpa.WalletPoolId = wp.Id
WHERE wp.WalletId = 'F05F83B8-963A-4796-B160-3BC1E018AAFB'
```

### 8.2 Wallets with creation fees
```sql
SELECT wpa.WalletPoolId, wpa.CreationFee, wpa.ReservedAmount
FROM Wallet.WalletPoolAttributes wpa WITH (NOLOCK)
WHERE wpa.CreationFee IS NOT NULL
```

### 8.3 Total reserved amounts by blockchain
```sql
SELECT bc.Name AS Blockchain, COUNT(*) AS WalletCount, SUM(wpa.ReservedAmount) AS TotalReserved
FROM Wallet.WalletPoolAttributes wpa WITH (NOLOCK)
JOIN Wallet.WalletPool wp WITH (NOLOCK) ON wpa.WalletPoolId = wp.Id
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON wp.BlockchainCryptoId = bc.Id
GROUP BY bc.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletPoolAttributes | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletPoolAttributes.sql*
