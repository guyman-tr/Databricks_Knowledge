# Wallet.GetPendingStakeAndRewardsRefundTransactions

> Retrieves active staking/rewards refund requests that have not yet been processed into formal requests, ready for execution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unprocessed refund records limited by @MaxRecords |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds staking and rewards refund transactions that are awaiting processing. When a customer is owed a refund related to staking rewards (e.g., overpayment correction, staking penalty reversal, reward adjustment), a record is created in `Wallet.StakeAndRewardsRefunds`. This procedure picks up those records so the refund execution service can process them into formal request/transaction flows.

The "unprocessed" detection follows the same pattern as `Wallet.GetPendingOmnibusManualOutTransactions`: a LEFT JOIN to Requests on CorrelationId where r.Id IS NULL means no request has been created yet. Only active refunds (IsActive=1) are included, ordered by Occurred (FIFO).

---

## 2. Business Logic

### 2.1 Unprocessed Refund Detection

**What**: Finds active refund records not yet converted to formal requests.

**Columns/Parameters Involved**: `CorrelationId`, `IsActive`, `Requests.Id`

**Rules**:
- IsActive=1: Only active (not cancelled) refund records
- LEFT JOIN Requests ON CorrelationId with r.Id IS NULL: No formal request created yet
- TOP @MaxRecords with ORDER BY Occurred: FIFO batch processing
- Once processed, a Request record with the same CorrelationId will exist, excluding the refund from future queries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxRecords | INT | NO | - | CODE-BACKED | Maximum number of refund records to return. Controls batch size for the refund processing service. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Id | BIGINT | NO | - | CODE-BACKED | StakeAndRewardsRefunds record ID. Primary identifier. |
| 3 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID to receive the refund. |
| 4 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency of the refund. FK to Wallet.CryptoTypes. |
| 5 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Customer's wallet to receive the refund. |
| 6 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Unique correlation ID for tracking. Will be used to create the formal Request. |
| 7 | Amount | DECIMAL | NO | - | CODE-BACKED | Refund amount in crypto units. |
| 8 | Comment | NVARCHAR | YES | - | CODE-BACKED | Description of the refund reason (e.g., "Staking reward adjustment", "Penalty reversal"). |
| 9 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the refund record was created. Used for FIFO ordering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.StakeAndRewardsRefunds | FROM | Source of refund records |
| CorrelationId | Wallet.Requests | LEFT JOIN | Checks if refund has been processed into a request |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the staking refund processing service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingStakeAndRewardsRefundTransactions (procedure)
+-- Wallet.StakeAndRewardsRefunds (table)
+-- Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StakeAndRewardsRefunds | Table | FROM - refund records |
| Wallet.Requests | Table | LEFT JOIN - processed state check |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get pending refunds
```sql
EXEC Wallet.GetPendingStakeAndRewardsRefundTransactions @MaxRecords = 50;
```

### 8.2 Count pending refunds by crypto
```sql
SELECT sarr.CryptoId, COUNT(*) AS PendingCount, SUM(sarr.Amount) AS TotalRefundAmount
FROM Wallet.StakeAndRewardsRefunds sarr WITH (NOLOCK)
LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = sarr.CorrelationId
WHERE r.Id IS NULL AND sarr.IsActive = 1
GROUP BY sarr.CryptoId;
```

### 8.3 Check all refund records with processing status
```sql
SELECT TOP 20 sarr.Id, sarr.Gcid, sarr.CryptoId, sarr.Amount, sarr.Comment,
       CASE WHEN r.Id IS NULL THEN 'Pending' ELSE 'Processed' END AS Status
FROM Wallet.StakeAndRewardsRefunds sarr WITH (NOLOCK)
LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = sarr.CorrelationId
WHERE sarr.IsActive = 1
ORDER BY sarr.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingStakeAndRewardsRefundTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingStakeAndRewardsRefundTransactions.sql*
