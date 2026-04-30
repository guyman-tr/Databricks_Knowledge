# Wallet.GetPendingManualApproveTransactions

> Retrieves transactions awaiting initial manual approval (no status recorded yet), enriched with request details including customer, amount, and destination address.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unapproved manual transactions with request context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves crypto send transactions that require manual compliance/operations approval but have not yet received any approval action. Unlike `Wallet.GetManualApprovedTransactions` which finds already-approved transactions ready for execution, this finds transactions still waiting for the first human review.

When a customer initiates a crypto withdrawal that triggers manual review criteria (high value, flagged address, etc.), a ManualApproveTransaction record is created. This procedure surfaces those records - enriched with the original request details (customer, amount, address) - to the compliance dashboard where a reviewer can approve or reject them.

Data joins `Wallet.ManualApproveTransaction` to `Wallet.Requests` (RequestTypeId=1, Send requests) to extract customer context and transaction details from the request's DetailsJson. Only transactions with no status records beyond 1 (initial) are included.

---

## 2. Business Logic

### 2.1 Unapproved Transaction Filter

**What**: Finds transactions awaiting first approval action.

**Columns/Parameters Involved**: `ManualApproveTransactionStatusId`, `RequestTypeId`

**Rules**:
- NOT EXISTS with StatusId > 1 means no approval/rejection has occurred
- RequestTypeId=1 (Send requests) - only outgoing transactions require manual approval
- Amount and ToAddress are extracted from Request.DetailsJson via JSON_VALUE
- Amount is CAST to decimal(19,10) for consistent formatting

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
| 1 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID linking the manual approval to the send request. Used to process the approval decision. |
| 2 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID from the request. Identifies who initiated the withdrawal. |
| 3 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency of the send request. FK to Wallet.CryptoTypes. |
| 4 | Occurred | DATETIME2 | NO | - | CODE-BACKED | Timestamp when the request was created (aliased from Request.Timestamp). Shows how long the transaction has been waiting for approval. |
| 5 | Amount | DECIMAL(19,10) | YES | - | CODE-BACKED | Withdrawal amount extracted from Request.DetailsJson via JSON_VALUE. In crypto units. |
| 6 | ToAddress | NVARCHAR | YES | - | CODE-BACKED | Destination address extracted from Request.DetailsJson via JSON_VALUE. The address the customer wants to send crypto to. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ManualApproveTransaction | FROM | Transactions requiring manual approval |
| CorrelationId | Wallet.Requests | JOIN | Original send request with customer context |
| ManualApproveTransactionId | Wallet.ManualApproveTransactionStatuses | NOT EXISTS | Filters to unapproved (no status > 1) |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the compliance/operations approval dashboard.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingManualApproveTransactions (procedure)
+-- Wallet.ManualApproveTransaction (table)
+-- Wallet.Requests (table)
+-- Wallet.ManualApproveTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualApproveTransaction | Table | FROM - manual approval records |
| Wallet.Requests | Table | JOIN - request context (Gcid, CryptoId, DetailsJson) |
| Wallet.ManualApproveTransactionStatuses | Table | NOT EXISTS - approval status check |

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

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetPendingManualApproveTransactions;
```

### 8.2 Count pending approvals by crypto
```sql
SELECT R.CryptoId, COUNT(*) AS PendingCount
FROM Wallet.ManualApproveTransaction MAT WITH (NOLOCK)
JOIN Wallet.Requests R WITH (NOLOCK) ON R.CorrelationId = MAT.CorrelationId
WHERE NOT EXISTS (SELECT 1 FROM Wallet.ManualApproveTransactionStatuses MATS WITH (NOLOCK)
    WHERE MAT.Id = MATS.ManualApproveTransactionId AND MATS.ManualApproveTransactionStatusId > 1)
AND R.RequestTypeId = 1
GROUP BY R.CryptoId;
```

### 8.3 Find oldest pending approval
```sql
SELECT TOP 1 MAT.CorrelationId, R.Timestamp, R.Gcid, DATEDIFF(HOUR, R.Timestamp, GETUTCDATE()) AS HoursWaiting
FROM Wallet.ManualApproveTransaction MAT WITH (NOLOCK)
JOIN Wallet.Requests R WITH (NOLOCK) ON R.CorrelationId = MAT.CorrelationId
WHERE NOT EXISTS (SELECT 1 FROM Wallet.ManualApproveTransactionStatuses MATS WITH (NOLOCK)
    WHERE MAT.Id = MATS.ManualApproveTransactionId AND MATS.ManualApproveTransactionStatusId > 1)
AND R.RequestTypeId = 1
ORDER BY R.Timestamp ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingManualApproveTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingManualApproveTransactions.sql*
