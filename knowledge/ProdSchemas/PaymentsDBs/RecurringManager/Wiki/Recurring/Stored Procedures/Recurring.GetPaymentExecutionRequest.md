# Recurring.GetPaymentExecutionRequest

> Simple reader that retrieves a single payment execution request record by PaymentExecutionId.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single PaymentExecutionRequest row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Basic point-lookup procedure that returns the billing request parameters for a specific payment execution. Used by the application to retrieve what amount, currency, and funding source were sent to the billing processor for a given execution. Uses NOLOCK.

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
| 1 | @PaymentExecutionId | int (IN) | NO | - | CODE-BACKED | FK to PaymentExecution. Retrieves the request for this execution. |

**Return Columns**: PaymentExecutionRequestId, PaymentExecutionId, FundingId, Amount, CurrencyId.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecutionRequest | READER | SELECT TOP 1 by PaymentExecutionId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPaymentExecutionRequest (procedure)
└── Recurring.PaymentExecutionRequest (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionRequest | Table | SELECT TOP 1 WHERE PaymentExecutionId |

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

### 8.1 Get request for an execution
```sql
EXEC Recurring.GetPaymentExecutionRequest @PaymentExecutionId = 859547
```

### 8.2 Equivalent ad-hoc
```sql
SELECT TOP 1 per.PaymentExecutionRequestId, per.PaymentExecutionId, per.FundingId, per.Amount, per.CurrencyId
FROM Recurring.PaymentExecutionRequest per WITH (NOLOCK)
WHERE per.PaymentExecutionId = 859547
```

### 8.3 Request with execution status context
```sql
SELECT per.Amount, per.CurrencyId, per.FundingId,
       pe.StatusId, pes.Name AS ExecutionStatus
FROM Recurring.PaymentExecutionRequest per WITH (NOLOCK)
INNER JOIN Recurring.PaymentExecution pe WITH (NOLOCK) ON per.PaymentExecutionId = pe.PaymentExecutionId
INNER JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pe.StatusId = pes.StatusId
WHERE per.PaymentExecutionId = 859547
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPaymentExecutionRequest | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPaymentExecutionRequest.sql*
