# Recurring.GetPaymentExecution

> Simple reader that retrieves a single payment execution record by PaymentExecutionId.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single PaymentExecution row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Basic point-lookup procedure that returns all business columns of a single payment execution by its primary key. Used by application services to check execution status, cycle number, and retry count during the execution pipeline. Uses NOLOCK.

---

## 2. Business Logic

No complex business logic. Simple `SELECT TOP 1 ... WHERE PaymentExecutionId = @PaymentExecutionId`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentExecutionId | int (IN) | NO | - | CODE-BACKED | PK of the execution to retrieve. |

**Return Columns**: PaymentExecutionId, PaymentId, StatusId, CycleNumber, Retries, CreateDate, ModificationDate.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | READER | SELECT TOP 1 by PK |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPaymentExecution (procedure)
└── Recurring.PaymentExecution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | SELECT TOP 1 WHERE PaymentExecutionId = @PaymentExecutionId |

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

### 8.1 Get an execution
```sql
EXEC Recurring.GetPaymentExecution @PaymentExecutionId = 859547
```

### 8.2 Equivalent ad-hoc with status name
```sql
SELECT pe.*, pes.Name AS StatusName
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pe.StatusId = pes.StatusId
WHERE pe.PaymentExecutionId = 859547
```

### 8.3 Get execution with parent payment info
```sql
SELECT pe.PaymentExecutionId, pe.StatusId, pe.CycleNumber, pe.Retries,
       p.Cid, p.Amount, p.CurrencyId
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Recurring.Payment p WITH (NOLOCK) ON pe.PaymentId = p.PaymentId
WHERE pe.PaymentExecutionId = 859547
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPaymentExecution | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPaymentExecution.sql*
