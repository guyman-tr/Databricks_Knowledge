# Wallet.AddManualApproveTransactionStatus

> Adds a new status entry to a manual approval transaction, tracking the progression of compliance review decisions (e.g., pending, approved, rejected).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.ManualApproveTransactionStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a status change for a manual approval transaction. When a compliance reviewer takes action on a flagged transaction (approves, rejects, requests more information), this procedure creates a status history entry. The status history pattern (append-only) provides a full audit trail of every decision made on the transaction.

Without this procedure, there would be no way to record compliance decisions or track the progression of manual review. The full status history is essential for regulatory audits and compliance reporting.

The procedure first looks up the ManualApproveTransaction record by CorrelationId, then inserts the new status. This two-step approach allows callers to reference transactions by their business correlation ID rather than the internal database ID.

---

## 2. Business Logic

### 2.1 Correlation ID to Internal ID Resolution

**What**: Resolves the business-facing CorrelationId to the internal ManualApproveTransactionId before inserting the status.

**Columns/Parameters Involved**: `@CorrelationId`, `@ManualApproveTransactionStatusId`

**Rules**:
- Looks up ManualApproveTransaction.Id via CorrelationId using NOLOCK hint
- If no matching transaction exists, @ManualApproveTransactionId remains NULL and the INSERT will fail due to NOT NULL constraint on the target table
- Status IDs represent workflow states (see ManualApproveTransactionStatuses table doc)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | The business correlation ID of the manual approval transaction to update. Used to resolve the internal ManualApproveTransactionId. |
| 2 | @ManualApproveTransactionStatusId | int | NO | - | CODE-BACKED | The status to assign. References the status type (e.g., pending review, approved, rejected, escalated). Maps to a status lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.ManualApproveTransaction | Lookup | Resolves correlation ID to internal ID |
| INSERT target | Wallet.ManualApproveTransactionStatuses | Writer | Appends status history entry |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application compliance services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddManualApproveTransactionStatus (procedure)
  ├── Wallet.ManualApproveTransaction (table)
  └── Wallet.ManualApproveTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualApproveTransaction | Table | SELECT to resolve CorrelationId |
| Wallet.ManualApproveTransactionStatuses | Table | INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None beyond the target table's constraints. If CorrelationId is not found, the variable remains NULL and the INSERT will fail.

---

## 8. Sample Queries

### 8.1 View status history for a manual approval transaction
```sql
SELECT mat.CorrelationId, mats.ManualApproveTransactionStatusId, mats.Created
FROM Wallet.ManualApproveTransaction mat WITH (NOLOCK)
JOIN Wallet.ManualApproveTransactionStatuses mats WITH (NOLOCK)
    ON mats.ManualApproveTransactionId = mat.Id
WHERE mat.CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
ORDER BY mats.Id
```

### 8.2 Find transactions still awaiting approval (latest status = 1)
```sql
SELECT mat.Id, mat.CorrelationId, mat.Data
FROM Wallet.ManualApproveTransaction mat WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 ManualApproveTransactionStatusId
    FROM Wallet.ManualApproveTransactionStatuses WITH (NOLOCK)
    WHERE ManualApproveTransactionId = mat.Id
    ORDER BY Id DESC
) latest
WHERE latest.ManualApproveTransactionStatusId = 1
```

### 8.3 Count transactions by latest status
```sql
SELECT latest.ManualApproveTransactionStatusId, COUNT(*) AS Cnt
FROM Wallet.ManualApproveTransaction mat WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 ManualApproveTransactionStatusId
    FROM Wallet.ManualApproveTransactionStatuses WITH (NOLOCK)
    WHERE ManualApproveTransactionId = mat.Id
    ORDER BY Id DESC
) latest
GROUP BY latest.ManualApproveTransactionStatusId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddManualApproveTransactionStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddManualApproveTransactionStatus.sql*
