# Wallet.GetFreeWallets

> Returns a summary count of unassigned wallets in the pool, grouped by cryptocurrency and promotion, distinguishing between standard (Verified) and promotional (FundingVerified) availability.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns grouped counts of free wallets by crypto and promotion |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a dashboard-level view of wallet pool capacity, showing how many pre-created wallets are available for customer assignment across each cryptocurrency and promotion combination. Unlike `Wallet.GetFreeWalletFromPool` which counts for a single crypto, this procedure gives a full inventory snapshot across all cryptocurrencies and promotions simultaneously.

The pool replenishment system and operations team rely on this data to ensure adequate wallet supply. If any crypto/promotion combination shows zero or critically low availability, the system or operators need to trigger wallet creation and/or funding to prevent assignment failures.

The procedure reads from `Wallet.WalletPool` as the master record, uses `Wallet.WalletPoolStatuses` for current status (via subquery for latest status ID), joins to `Dictionary.WalletPoolStatuses` for status name resolution, and `Wallet.PromotionTags` for promotion identification. The key business rule is that standard wallets only need to be "Verified" to be assignable, but promotional wallets must be "FundingVerified" (pre-funded with crypto) before they can be assigned.

---

## 2. Business Logic

### 2.1 Promotional vs Standard Wallet Availability

**What**: Different availability criteria apply based on whether the wallet is promotional.

**Columns/Parameters Involved**: `WalletPoolStatusId`, `PromotionTagId`, `dwps.Name`

**Rules**:
- Standard wallets (PromotionTagId IS NULL): Must have latest status = 'Verified' (2) to be free
- Promotional wallets (PromotionTagId IS NOT NULL): Must have latest status = 'FundingVerified' (6) to be free
- The CASE expression enforces this: `dwps.Name = CASE WHEN PromotionTagId IS NULL THEN 'Verified' ELSE 'FundingVerified' END`
- Rationale: Promotional wallets are pre-funded with crypto as part of a campaign, so they must complete the full funding lifecycle before assignment

**Diagram**:
```
WalletPool (all entries)
    |
    +-- LEFT JOIN Wallets -> filter: w.Id IS NULL (not assigned)
    |
    +-- Subquery: latest WalletPoolStatuses.Id per pool entry
    |
    +-- JOIN Dictionary.WalletPoolStatuses for status name
    |
    +-- LEFT JOIN PromotionTags for promotion name
    |
    +-- CASE filter:
    |     No promotion? -> Status must be 'Verified' (2)
    |     Has promotion? -> Status must be 'FundingVerified' (6)
    |
    v
GROUP BY BlockchainCryptoId, PromotionName -> COUNT(*)
```

### 2.2 Pool Wallet Status Lifecycle Reference

**What**: Context for which statuses make a wallet "free".

**Columns/Parameters Involved**: `WalletPoolStatusId`

**Rules**:
- Full lifecycle: 1=Pending -> 2=Verified -> 4=FundingInitiated -> 5=FundingSent -> 6=FundingVerified -> 11=VerifiedForAssign
- Error states: 3=Failed, 7=FundingFailed, 10=Timeout
- Standard wallets become free at step 2 (Verified)
- Promotional wallets become free at step 6 (FundingVerified)
- See [Wallet Pool Status](../../_glossary.md#wallet-pool-status)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BlockchainCryptoId | INT | NO | - | CODE-BACKED | The cryptocurrency identifier from WalletPool. FK to Wallet.BlockchainCryptos. Each row represents one crypto's free wallet count. |
| 2 | Promotion | varchar | YES | - | CODE-BACKED | The promotion tag name from Wallet.PromotionTags. NULL for standard (non-promotional) wallets. When populated, indicates these free wallets are pre-funded for a specific promotional campaign. |
| 3 | (count) | INT | NO | - | CODE-BACKED | Number of free wallets available for the given crypto/promotion combination. This is the COUNT(*) aggregate. A zero or missing row means no free wallets are available for that combination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | FROM | Primary source of pool wallet records |
| WalletId | Wallet.Wallets | LEFT JOIN | Checks if wallet is assigned to a customer (NULL = unassigned) |
| Id | Wallet.WalletPoolStatuses | Subquery + JOIN | Retrieves latest status and status details per pool entry |
| WalletPoolStatusId | Dictionary.WalletPoolStatuses | JOIN | Resolves status ID to name for the Verified/FundingVerified check |
| PromotionTagId | Wallet.PromotionTags | LEFT JOIN | Resolves promotion tag ID to name for grouping |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Likely called by monitoring/operations dashboards or scheduled reporting jobs.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFreeWallets (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.Wallets (table)
+-- Wallet.WalletPoolStatuses (table)
+-- Dictionary.WalletPoolStatuses (table)
+-- Wallet.PromotionTags (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FROM - master pool records |
| Wallet.Wallets | Table | LEFT JOIN - customer assignment check |
| Wallet.WalletPoolStatuses | Table | Subquery + JOIN - latest status retrieval |
| Dictionary.WalletPoolStatuses | Table | JOIN - status name resolution |
| Wallet.PromotionTags | Table | LEFT JOIN - promotion name resolution |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetFreeWallets;
```

### 8.2 Get detailed pool wallet counts by status for a specific crypto
```sql
SELECT dwps.Name AS StatusName, COUNT(*) AS WalletCount
FROM Wallet.WalletPool wp WITH (NOLOCK)
INNER JOIN Wallet.WalletPoolStatuses wps WITH (NOLOCK) ON wps.Id = (
    SELECT TOP 1 s.Id FROM Wallet.WalletPoolStatuses s WITH (NOLOCK) WHERE s.WalletPoolId = wp.Id ORDER BY s.Id DESC
)
INNER JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
WHERE wp.BlockchainCryptoId = 1
GROUP BY dwps.Name
ORDER BY WalletCount DESC;
```

### 8.3 Compare free vs assigned wallets per crypto
```sql
SELECT wp.BlockchainCryptoId,
       SUM(CASE WHEN w.Id IS NULL THEN 1 ELSE 0 END) AS Unassigned,
       SUM(CASE WHEN w.Id IS NOT NULL THEN 1 ELSE 0 END) AS Assigned
FROM Wallet.WalletPool wp WITH (NOLOCK)
LEFT JOIN Wallet.Wallets w WITH (NOLOCK) ON w.WalletId = wp.WalletId
GROUP BY wp.BlockchainCryptoId
ORDER BY wp.BlockchainCryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFreeWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetFreeWallets.sql*
