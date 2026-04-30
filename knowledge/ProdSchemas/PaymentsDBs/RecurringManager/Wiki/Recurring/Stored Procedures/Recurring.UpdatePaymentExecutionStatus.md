# Recurring.UpdatePaymentExecutionStatus

> Transitions a payment execution's status with optimistic concurrency on the previous status, preventing stale state transitions.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns updated PaymentExecution row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary status transition procedure for Recurring.PaymentExecution. It changes the execution's status (e.g., Planned -> InProcess -> SentToBilling -> Approved/Declined) with an optimistic concurrency guard on the previous status. This prevents race conditions where two processes try to transition the same execution simultaneously.

---

## 2. Business Logic

### 2.1 Optimistic Concurrency Status Transition

**What**: Updates StatusId only if the current status matches the expected previous status.

**Columns/Parameters Involved**: `@PaymentExecutionId`, `@Status`, `@PreviousExecutionStatus`

**Rules**:
- UPDATE SET StatusId = @Status, ModificationDate = GETUTCDATE()
- WHERE: `PaymentExecutionId = @PaymentExecutionId AND StatusId = ISNULL(@PreviousExecutionStatus, StatusId)`
- When @PreviousExecutionStatus is NULL: no guard, updates regardless of current status
- When @PreviousExecutionStatus is provided: only updates if current status matches (optimistic lock)
- If the guard fails (status already changed), UPDATE affects 0 rows but SELECT still returns the current state
- Always returns the current execution state via SELECT (whether update was applied or not)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentExecutionId | int (IN) | NO | - | CODE-BACKED | PK of the execution to update. |
| 2 | @Status | int (IN) | NO | - | VERIFIED | New StatusId to set. Maps to Dictionary.PaymentExecutionStatus (1=Planned through 10=Retry). |
| 3 | @PreviousExecutionStatus | int (IN) | YES | - | VERIFIED | Expected current status for optimistic concurrency. NULL = update unconditionally. When set, UPDATE is a no-op if current status doesn't match. |

**Return Columns**: PaymentExecutionId, PaymentId, StatusId, CycleNumber, Retries, CreateDate, ModificationDate, SysStartTime, SysEndTime.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | MODIFIER + READER | UPDATE with status guard, then SELECT |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.UpdatePaymentExecutionStatus (procedure)
└── Recurring.PaymentExecution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | UPDATE WHERE PaymentExecutionId AND StatusId guard |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Transition from Planned to InProcess
```sql
EXEC Recurring.UpdatePaymentExecutionStatus @PaymentExecutionId = 859547, @Status = 2, @PreviousExecutionStatus = 1
```

### 8.2 Mark as Approved (unconditional)
```sql
EXEC Recurring.UpdatePaymentExecutionStatus @PaymentExecutionId = 859547, @Status = 7
```

### 8.3 Conditional transition (will fail if not in expected state)
```sql
-- Only succeeds if execution is currently SentToBilling (3)
EXEC Recurring.UpdatePaymentExecutionStatus @PaymentExecutionId = 859547, @Status = 7, @PreviousExecutionStatus = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.UpdatePaymentExecutionStatus | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.UpdatePaymentExecutionStatus.sql*
