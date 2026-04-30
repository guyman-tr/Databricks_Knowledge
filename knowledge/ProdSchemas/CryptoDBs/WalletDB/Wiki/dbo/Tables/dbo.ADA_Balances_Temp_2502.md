# dbo.ADA_Balances_Temp_2502

> Temporary snapshot table holding Cardano (ADA) wallet balances, created for a one-time reconciliation or audit in February 2025.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK defined) |
| **Partition** | No |
| **Indexes** | 0 active |

---

## 1. Business Meaning

This table is a one-time temporary snapshot of ADA (Cardano, CryptoID=18) wallet balances, likely created for a balance reconciliation or audit exercise in February 2025 (suffix `_2502`). It captures the wallet ID, customer GCID, blockchain address, and both total and available balances at a point in time.

Without this table, there would be no static reference point for comparing ADA balances against the live Wallet schema tables during the reconciliation. The table's existence in the SSDT project suggests it was scripted rather than ad-hoc, but it has no ongoing operational role.

No stored procedures, views, or functions reference this table. It is an orphaned artifact with no active data flow - rows were likely inserted via ad-hoc query or one-time script.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| WalletId | GCID | Address | Balance | AvailableBalance | Meaning |
|----------|------|---------|---------|------------------|---------|
| f0f4dede-... | 20267280 | addr1qy3h... | 1114.65 | 1114.65 | Customer wallet with ~1,115 ADA fully available - no staking or pending transactions locking funds |
| de790005-... | 7311046 | addr1qyay... | 1.53 | 1.53 | Small-balance wallet, likely dormant or post-redemption remainder |
| 5f8d24cb-... | 12896013 | addr1q85n... | 2473.31 | 2473.31 | Larger ADA holder; Balance equals AvailableBalance indicating no locked funds |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | nvarchar(150) | NO | - | CODE-BACKED | Blockchain provider wallet identifier (GUID as string). Maps to Wallet.CustomerWallets.BlockchainProviderWalletId or similar wallet reference in the Wallet schema. |
| 2 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID - the eToro customer identifier who owns the wallet. References the customer master in the platform's customer system. |
| 3 | Address | nvarchar(150) | NO | - | CODE-BACKED | Cardano blockchain public address (Bech32 format starting with `addr1q`). The on-chain address associated with the customer's ADA wallet. |
| 4 | Balance | decimal(18,10) | NO | - | CODE-BACKED | Total ADA balance in the wallet at snapshot time, in native ADA units (not Lovelace). Includes both available and any locked/staked amounts. |
| 5 | AvailableBalance | decimal(18,10) | NO | - | CODE-BACKED | Available (unlocked) ADA balance at snapshot time. In the sampled data, always equals Balance, suggesting no funds were locked at the time of capture. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all ADA balances above 1000
```sql
SELECT WalletId, GCID, Balance, AvailableBalance
FROM dbo.ADA_Balances_Temp_2502 WITH (NOLOCK)
WHERE Balance > 1000
ORDER BY Balance DESC
```

### 8.2 Find wallets with locked funds
```sql
SELECT WalletId, GCID, Balance, AvailableBalance,
       Balance - AvailableBalance AS LockedAmount
FROM dbo.ADA_Balances_Temp_2502 WITH (NOLOCK)
WHERE Balance <> AvailableBalance
```

### 8.3 Aggregate total ADA across all wallets
```sql
SELECT COUNT(*) AS WalletCount,
       SUM(Balance) AS TotalADA,
       SUM(AvailableBalance) AS TotalAvailableADA
FROM dbo.ADA_Balances_Temp_2502 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ADA_Balances_Temp_2502 | Type: Table | Source: WalletDB/dbo/Tables/dbo.ADA_Balances_Temp_2502.sql*
