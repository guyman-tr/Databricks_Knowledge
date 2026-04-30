# Wallet.GetManualApprovedTransactions

> Retrieves manually approved transactions that are ready for processing but have not yet been completed or rejected.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CorrelationId + Data for approved-but-not-processed transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves crypto transactions that have been manually approved by compliance or operations staff but have not yet progressed to a terminal state (completed, rejected, or further processed). In the wallet system, certain high-risk or high-value transactions require manual review before execution. Once approved (status=2), they sit in a queue for the automated processing system to pick up and execute.

Without this procedure, approved transactions would remain stuck after manual review with no mechanism for the execution service to discover and process them. This is a critical link between human approval workflows and automated transaction execution.

Data comes from `Wallet.ManualApproveTransaction` joined to `Wallet.ManualApproveTransactionStatuses`. The NOT EXISTS clause ensures only transactions whose highest status is "Approved" (2) are returned - transactions that have advanced to status 3+ (e.g., Completed, Rejected) are excluded.

---

## 2. Business Logic

### 2.1 Approved-But-Not-Processed Filter

**What**: Identifies transactions in the approval-complete, execution-pending state.

**Columns/Parameters Involved**: `ManualApproveTransactionStatusId`

**Rules**:
- Status 2 = Approved (transaction has been reviewed and approved for execution)
- NOT EXISTS with StatusId >= 3 ensures the transaction has not progressed beyond approval
- This is a state-machine query: it finds transactions at exactly the "Approved" checkpoint
- StatusId 1 is likely Pending (awaiting review), 2 is Approved, 3+ are post-processing states

**Diagram**:
```
ManualApproveTransaction lifecycle:
  1 (Pending) -> 2 (Approved) -> 3+ (Completed/Rejected/...)
                      ^
                      |
        This SP returns transactions HERE
        (status=2 exists, status>=3 does NOT exist)
```

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
| 1 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Unique correlation identifier linking this manual approval to the original transaction request. Used by the execution service to match the approval back to the pending transaction. |
| 2 | Data | NVARCHAR(MAX) | YES | - | CODE-BACKED | JSON payload containing the full transaction details (amount, addresses, crypto type, etc.). Stored as serialized data to support different transaction types without schema changes. The execution service deserializes this to build the actual blockchain transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ManualApproveTransaction | FROM | Master transaction records requiring manual approval |
| ManualApproveTransactionId | Wallet.ManualApproveTransactionStatuses | JOIN + NOT EXISTS | Status history used to find approved-but-not-completed transactions |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the transaction execution service to pick up approved transactions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetManualApprovedTransactions (procedure)
+-- Wallet.ManualApproveTransaction (table)
+-- Wallet.ManualApproveTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualApproveTransaction | Table | FROM - source of transaction records |
| Wallet.ManualApproveTransactionStatuses | Table | JOIN + NOT EXISTS - status filtering |

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
EXEC Wallet.GetManualApprovedTransactions;
```

### 8.2 Check all manual approval statuses distribution
```sql
SELECT MATS.ManualApproveTransactionStatusId, COUNT(*) AS TxCount
FROM Wallet.ManualApproveTransactionStatuses MATS WITH (NOLOCK)
GROUP BY MATS.ManualApproveTransactionStatusId
ORDER BY MATS.ManualApproveTransactionStatusId;
```

### 8.3 Find transactions stuck in approved state for over 24 hours
```sql
SELECT MAT.Id, MAT.CorrelationId, MATS.Occurred AS ApprovedAt
FROM Wallet.ManualApproveTransaction MAT WITH (NOLOCK)
INNER JOIN Wallet.ManualApproveTransactionStatuses MATS WITH (NOLOCK) ON MAT.Id = MATS.ManualApproveTransactionId
WHERE MATS.ManualApproveTransactionStatusId = 2
    AND MATS.Occurred < DATEADD(HOUR, -24, GETUTCDATE())
    AND NOT EXISTS (
        SELECT 1 FROM Wallet.ManualApproveTransactionStatuses MATS2 WITH (NOLOCK)
        WHERE MAT.Id = MATS2.ManualApproveTransactionId AND MATS2.ManualApproveTransactionStatusId >= 3
    );
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetManualApprovedTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetManualApprovedTransactions.sql*
