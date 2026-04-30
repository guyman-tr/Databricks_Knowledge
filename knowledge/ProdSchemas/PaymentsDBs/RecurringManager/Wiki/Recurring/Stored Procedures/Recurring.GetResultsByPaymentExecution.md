# Recurring.GetResultsByPaymentExecution

> Retrieves all deposit result records for a specific payment execution.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns set of PaymentExecutionDepositResult rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Simple reader that returns all deposit results for a specific payment execution. Used by the application to check the billing processor's response for a given execution cycle. Unlike GetPaymentExecutionsDepositsResultByCid (which traverses from customer), this procedure goes directly from execution ID to results.

---

## 2. Business Logic

No complex business logic. Simple `SELECT ... FROM Recurring.PaymentExecutionDepositResult WHERE PaymentExecutionId = @PaymentExecutionId` with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentExecutionId | int (IN) | NO | - | CODE-BACKED | FK to PaymentExecution. Returns all deposit results for this execution. |

**Return Columns**: PaymentExecutionDepositResultId, PaymentExecutionId, CycleNumber, DepositId, PaymentStatusId, StatusCode, GroupKey, ExecutionResultStatusId, PaymentDate, CreateDate, ModificationDate.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecutionDepositResult | READER | SELECT WHERE PaymentExecutionId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetResultsByPaymentExecution (procedure)
└── Recurring.PaymentExecutionDepositResult (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionDepositResult | Table | SELECT WHERE PaymentExecutionId |

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

### 8.1 Get results for an execution
```sql
EXEC Recurring.GetResultsByPaymentExecution @PaymentExecutionId = 859547
```

### 8.2 Equivalent with result status name
```sql
SELECT pedr.*, ers.Name AS ResultStatus
FROM Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK)
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
WHERE pedr.PaymentExecutionId = 859547
```

### 8.3 Check if execution has any results
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Recurring.PaymentExecutionDepositResult WITH (NOLOCK) WHERE PaymentExecutionId = 859547
) THEN 1 ELSE 0 END AS HasResults
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetResultsByPaymentExecution | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetResultsByPaymentExecution.sql*
