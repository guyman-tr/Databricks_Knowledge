# Recurring.GetPaymentExecutionsByForPayment

> Retrieves all payment execution records for a given payment, with optional status filtering.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns set of PaymentExecution rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all execution cycles for a specific recurring payment plan, optionally filtered by execution status. Used by the application to display execution history, check for pending executions, or find executions in a specific state. The optional @PaymentExecutionStatusId parameter makes it versatile - pass NULL to get all executions, or a specific status to filter.

---

## 2. Business Logic

### 2.1 Optional Status Filtering

**What**: Returns all executions for a payment, with optional status filtering using ISNULL pattern.

**Columns/Parameters Involved**: `@PaymentId`, `@PaymentExecutionStatusId`

**Rules**:
- `WHERE PaymentId = @PaymentId AND StatusId = ISNULL(@PaymentExecutionStatusId, StatusId)`
- When @PaymentExecutionStatusId is NULL: returns all executions for the payment
- When @PaymentExecutionStatusId is specified: filters to only that status
- No NOLOCK hint used (unlike most other reader SPs in this schema)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | FK to Recurring.Payment. Returns executions for this plan. |
| 2 | @PaymentExecutionStatusId | int (IN) | YES | NULL | CODE-BACKED | Optional status filter. NULL returns all statuses. Maps to Dictionary.PaymentExecutionStatus values. |

**Return Columns**: PaymentExecutionId, CreateDate, CycleNumber, ModificationDate, PaymentId, Retries, StatusId.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | READER | SELECT WHERE PaymentId with optional status filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPaymentExecutionsByForPayment (procedure)
└── Recurring.PaymentExecution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | SELECT WHERE PaymentId and optional StatusId filter |

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

### 8.1 Get all executions for a payment
```sql
EXEC Recurring.GetPaymentExecutionsByForPayment @PaymentId = 200820
```

### 8.2 Get only planned executions
```sql
EXEC Recurring.GetPaymentExecutionsByForPayment @PaymentId = 200820, @PaymentExecutionStatusId = 1
```

### 8.3 Get approved executions
```sql
EXEC Recurring.GetPaymentExecutionsByForPayment @PaymentId = 200820, @PaymentExecutionStatusId = 7
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPaymentExecutionsByForPayment | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPaymentExecutionsByForPayment.sql*
