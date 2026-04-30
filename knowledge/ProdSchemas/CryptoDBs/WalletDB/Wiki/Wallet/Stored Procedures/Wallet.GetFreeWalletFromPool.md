# Wallet.GetFreeWalletFromPool

> Counts the number of verified but unassigned wallets available in the pool for a given cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FreeWalletsInPool count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure determines how many pre-created wallets are available for assignment in the wallet pool for a specific cryptocurrency. The wallet pool is a pre-provisioning system where wallets are created and verified in advance so they can be instantly assigned to customers when needed, avoiding the delay of on-chain wallet creation at assignment time.

A "free" wallet is one that has been verified (WalletPoolStatusId=2) but not yet assigned to any customer. This count is critical for capacity planning and pool replenishment - if the count drops too low, the system needs to create more wallets to maintain instant-assignment capability.

The procedure queries `Wallet.WalletPool` as the master pool record, uses `Wallet.WalletPoolStatuses` to find the latest status per pool entry (must be Verified=2), and LEFT JOINs to `Wallet.Wallets` to exclude wallets already assigned to customers. The optional `@FreeStartingFrom` parameter allows filtering by wallet age, defaulting to current UTC time.

---

## 2. Business Logic

### 2.1 Free Wallet Definition

**What**: Determines which pool wallets are considered "free" (available for customer assignment).

**Columns/Parameters Involved**: `WalletPoolStatusId`, `WalletId`, `BlockchainCryptoId`, `Occurred`

**Rules**:
- A wallet is "free" when ALL of these conditions are met:
  1. It exists in WalletPool for the requested CryptoId
  2. Its latest status is Verified (WalletPoolStatusId=2) - not Pending, Failed, or in a Funding state
  3. It has NOT been assigned to a customer (LEFT JOIN to Wallets returns NULL)
  4. The wallet's creation date (Occurred) is before the @FreeStartingFrom threshold
- The OUTER APPLY with TOP 1 ORDER BY Id DESC ensures only the most recent status is considered
- Default @FreeStartingFrom = GETUTCDATE() means all wallets created up to now are eligible

**Diagram**:
```
WalletPool (master)
    |
    +-- OUTER APPLY WalletPoolStatuses (TOP 1 ORDER BY Id DESC)
    |       -> Must be StatusId = 2 (Verified)
    |
    +-- LEFT JOIN Wallets ON WalletId + CryptoId + Occurred < threshold
            -> Must be NULL (not assigned)
    |
    v
COUNT(*) = FreeWalletsInPool
```

### 2.2 Pool Status Lifecycle Context

**What**: Only Verified wallets are eligible for assignment.

**Columns/Parameters Involved**: `WalletPoolStatusId`

**Rules**:
- Lifecycle: 1=Pending -> 2=Verified -> 4=FundingInitiated -> 5=FundingSent -> 6=FundingVerified -> 11=VerifiedForAssign
- This procedure specifically checks for status 2 (Verified) as the "free" state
- Wallets in Pending (1), Failed (3), or any Funding state (4-7) are NOT counted as free
- See [Wallet Pool Status](../../_glossary.md#wallet-pool-status) for full lifecycle

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | INT | NO | - | CODE-BACKED | The blockchain cryptocurrency identifier to check pool availability for. FK to Wallet.BlockchainCryptos / Wallet.CryptoTypes. Filters both WalletPool and Wallets to the specified crypto. |
| 2 | @FreeStartingFrom | DATETIME2(7) | YES | NULL (defaults to GETUTCDATE()) | CODE-BACKED | Upper bound for wallet creation date. Only wallets with `Occurred < @FreeStartingFrom` are counted. When NULL, defaults to current UTC time, meaning all existing wallets qualify. Can be set to a past date to count only older pre-created wallets. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FreeWalletsInPool | INT | NO | - | CODE-BACKED | Count of wallets in the pool that are verified, unassigned, and created before the date threshold. Used by pool management services to determine if replenishment is needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CryptoId | Wallet.WalletPool.BlockchainCryptoId | Filter | Filters pool entries to the specified cryptocurrency |
| WalletPoolId | Wallet.WalletPoolStatuses | OUTER APPLY | Retrieves the latest status for each pool wallet |
| WalletId | Wallet.Wallets | LEFT JOIN | Checks if a pool wallet has been assigned to a customer |

### 5.2 Referenced By (other objects point to this)

Multiple database users have EXECUTE permission: ScheduledJobsUser, RedeemSchedulerUser, ExecuterUser, BalanceUser, AmlUser, BackApiUser. This indicates the procedure is called by multiple services for pool capacity monitoring.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFreeWalletFromPool (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolStatuses (table)
+-- Wallet.Wallets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FROM - primary source of pool wallet records |
| Wallet.WalletPoolStatuses | Table | OUTER APPLY - retrieves latest status per pool wallet |
| Wallet.Wallets | Table | LEFT JOIN - checks if wallet is assigned to a customer |

### 6.2 Objects That Depend On This

No direct callers found in SSDT SQL code. Called by application services via multiple user permissions.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check free wallet count for Bitcoin (CryptoId=1)
```sql
EXEC Wallet.GetFreeWalletFromPool @CryptoId = 1;
```

### 8.2 Check free wallets created before a specific date
```sql
EXEC Wallet.GetFreeWalletFromPool @CryptoId = 2, @FreeStartingFrom = '2025-01-01';
```

### 8.3 Check pool availability across all cryptos
```sql
SELECT DISTINCT wp.BlockchainCryptoId, ct.Name
FROM Wallet.WalletPool wp WITH (NOLOCK)
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON wp.BlockchainCryptoId = ct.CryptoID
ORDER BY wp.BlockchainCryptoId;
-- Then call GetFreeWalletFromPool for each CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFreeWalletFromPool | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetFreeWalletFromPool.sql*
