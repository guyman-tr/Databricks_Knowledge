# Recurring.GetPaymentExecutionsDepositsResultByCid

> Retrieves all deposit results for a customer by joining through PaymentExecution to Payment, providing a complete history of billing outcomes across all of a customer's recurring plans.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns set of PaymentExecutionDepositResult rows with PaymentId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a customer-centric view of all deposit results across all their recurring payment plans. It joins three tables (PaymentExecutionDepositResult -> PaymentExecution -> Payment) to navigate from a customer ID down to every billing processor response. Used by the application to display a customer's complete recurring payment history, including successful deposits and declined attempts.

---

## 2. Business Logic

### 2.1 Three-Table Join Chain

**What**: Navigates from customer (Cid) through Payment -> PaymentExecution -> PaymentExecutionDepositResult.

**Columns/Parameters Involved**: `@Cid`, Payment.`Cid`, PaymentExecution.`PaymentId`, PaymentExecutionDepositResult.`PaymentExecutionId`

**Rules**:
- JOIN chain: PaymentExecutionDepositResult -> PaymentExecution ON PaymentExecutionId -> Payment ON PaymentId
- Filters by Payment.Cid = @Cid
- Returns all deposit result columns plus PaymentId (from the Payment table) for grouping
- Uses NOLOCK on all three tables
- No date or status filtering - returns the complete history

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | int (IN) | NO | - | CODE-BACKED | Customer ID. Returns all deposit results for all of this customer's recurring payments. |

**Return Columns**: PaymentExecutionDepositResultId, PaymentExecutionId, CycleNumber, DepositId, PaymentStatusId, StatusCode, GroupKey, ExecutionResultStatusId, PaymentDate, CreateDate, ModificationDate, PaymentId.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecutionDepositResult | READER | Source of deposit results |
| - | Recurring.PaymentExecution | READER | JOIN bridge between deposit result and payment |
| - | Recurring.Payment | READER | Filters by Cid |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPaymentExecutionsDepositsResultByCid (procedure)
├── Recurring.PaymentExecutionDepositResult (table)
├── Recurring.PaymentExecution (table)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionDepositResult | Table | SELECT - deposit result data |
| Recurring.PaymentExecution | Table | INNER JOIN on PaymentExecutionId |
| Recurring.Payment | Table | INNER JOIN on PaymentId, filter by Cid |

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

### 8.1 Get all deposit results for a customer
```sql
EXEC Recurring.GetPaymentExecutionsDepositsResultByCid @Cid = 9252179
```

### 8.2 Equivalent ad-hoc with status names
```sql
SELECT pedr.*, p.PaymentId, ers.Name AS ResultStatus
FROM Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK)
INNER JOIN Recurring.PaymentExecution pe WITH (NOLOCK) ON pedr.PaymentExecutionId = pe.PaymentExecutionId
INNER JOIN Recurring.Payment p WITH (NOLOCK) ON pe.PaymentId = p.PaymentId
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
WHERE p.Cid = 9252179
ORDER BY pedr.CreateDate DESC
```

### 8.3 Count results by outcome for a customer
```sql
SELECT ers.Name, COUNT(*) AS ResultCount
FROM Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK)
INNER JOIN Recurring.PaymentExecution pe WITH (NOLOCK) ON pedr.PaymentExecutionId = pe.PaymentExecutionId
INNER JOIN Recurring.Payment p WITH (NOLOCK) ON pe.PaymentId = p.PaymentId
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
WHERE p.Cid = 9252179
GROUP BY ers.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPaymentExecutionsDepositsResultByCid | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPaymentExecutionsDepositsResultByCid.sql*
