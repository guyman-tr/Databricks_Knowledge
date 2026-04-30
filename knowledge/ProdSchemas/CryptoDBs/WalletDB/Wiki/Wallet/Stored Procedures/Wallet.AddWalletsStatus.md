# Wallet.AddWalletsStatus

> Batch-inserts wallet pool status records from a table-valued parameter, resolving the blockchain crypto ID from the wallet pool for each entry.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New rows in Wallet.WalletPoolStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records status changes for wallets in the pool in bulk. The wallet pool lifecycle progresses through states (e.g., Created, Verified, FundingInitiated, FundingVerified, Assigned). Each status change is tracked as an append-only record in WalletPoolStatuses, providing a complete history of every wallet pool entry's lifecycle.

Without this procedure, the system could not efficiently batch-update wallet pool statuses, which is needed during bulk operations like pool funding verification, promotion assignments, or pool cleanup.

The procedure accepts a WalletsStatusType TVP with WalletPoolId, StatusId, and PromotionTagId, then JOINs to WalletPool to resolve the BlockchainCryptoId for each wallet.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a batch INSERT that enriches the input with BlockchainCryptoId from the wallet pool. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletsStatus | Wallet.WalletsStatusType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing status updates. Columns: WalletPoolId (target wallet pool entry), StatusId (new status from Dictionary.WalletPoolStatuses), PromotionTagId (associated promotion tag, if any). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletPoolId | Wallet.WalletPool | JOIN | Resolves BlockchainCryptoId for each entry |
| INSERT target | Wallet.WalletPoolStatuses | Writer | Appends status records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application wallet pool services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddWalletsStatus (procedure)
  ├── Wallet.WalletPool (table)
  ├── Wallet.WalletPoolStatuses (table)
  └── Wallet.WalletsStatusType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | JOIN to get BlockchainCryptoId |
| Wallet.WalletPoolStatuses | Table | INSERT target |
| Wallet.WalletsStatusType | User Defined Type | Table-valued parameter |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- READONLY modifier on TVP
- No error handling

---

## 8. Sample Queries

### 8.1 View recent wallet pool status changes
```sql
SELECT TOP 20 wps.Id, wps.WalletPoolId, wps.WalletPoolStatusId, wps.PromotionTagId, wps.CryptoId, wps.Created
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
ORDER BY wps.Id DESC
```

### 8.2 Current status of wallet pool entries
```sql
SELECT wp.Id, wp.WalletId, wp.BlockchainCryptoId, dwps.Name AS CurrentStatus
FROM Wallet.WalletPool wp WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 WalletPoolStatusId FROM Wallet.WalletPoolStatuses WITH (NOLOCK)
    WHERE WalletPoolId = wp.Id ORDER BY Id DESC
) wps
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
```

### 8.3 Status distribution in the pool
```sql
SELECT dwps.Name, COUNT(*) AS Cnt
FROM Wallet.WalletPool wp WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 WalletPoolStatusId FROM Wallet.WalletPoolStatuses WITH (NOLOCK)
    WHERE WalletPoolId = wp.Id ORDER BY Id DESC
) wps
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
GROUP BY dwps.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddWalletsStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddWalletsStatus.sql*
