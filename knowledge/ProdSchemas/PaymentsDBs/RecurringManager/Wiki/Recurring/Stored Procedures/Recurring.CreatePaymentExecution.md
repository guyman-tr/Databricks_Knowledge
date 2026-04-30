# Recurring.CreatePaymentExecution

> Creates a new payment execution record for a billing cycle with duplicate detection, returning the new or existing execution.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns payment execution record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new execution record in Recurring.PaymentExecution when the scheduler triggers a billing cycle. It prevents duplicates by checking for an existing execution with the same (PaymentId, StatusId, Retries) combination. If a duplicate exists, the existing record is returned instead of creating a new one.

Called by the scheduler service when a payment plan's next billing cycle is due.

---

## 2. Business Logic

### 2.1 Idempotent Execution Creation

**What**: Creates exactly one execution per (PaymentId, StatusId, Retries) combination.

**Columns/Parameters Involved**: `@PaymentId`, `@CycleNumber`, `@Retries`, `@StatusId`

**Rules**:
- Checks NOT EXISTS (PaymentId + StatusId + Retries) before INSERT
- Default StatusId=1 (Planned), default Retries=1
- Sets CreateDate and ModificationDate to GETUTCDATE()
- Always returns the execution record (whether new or existing) via SELECT TOP 1
- SET NOCOUNT ON prevents row count messages from confusing the application

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | FK to Recurring.Payment. The recurring plan to create an execution for. |
| 2 | @CycleNumber | int (IN) | NO | - | CODE-BACKED | Which billing cycle (1=first, 2=second, etc.). |
| 3 | @Retries | int (IN) | NO | 1 | CODE-BACKED | Retry count within the cycle. Default 1 for first attempt. |
| 4 | @StatusId | int (IN) | NO | 1 | CODE-BACKED | Initial status. Default 1=Planned from Dictionary.PaymentExecutionStatus. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | WRITER + READER | INSERT new execution, SELECT existing or new |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.CreatePaymentExecution (procedure)
└── Recurring.PaymentExecution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | SELECT for duplicate check, INSERT for new execution |

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

### 8.1 Create first execution for a payment
```sql
EXEC Recurring.CreatePaymentExecution @PaymentId = 200820, @CycleNumber = 1
```

### 8.2 Create a retry execution
```sql
EXEC Recurring.CreatePaymentExecution @PaymentId = 200820, @CycleNumber = 1, @Retries = 2
```

### 8.3 Idempotent call returns existing
```sql
-- Calling again with same params returns the existing execution
EXEC Recurring.CreatePaymentExecution @PaymentId = 200820, @CycleNumber = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.CreatePaymentExecution | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.CreatePaymentExecution.sql*
