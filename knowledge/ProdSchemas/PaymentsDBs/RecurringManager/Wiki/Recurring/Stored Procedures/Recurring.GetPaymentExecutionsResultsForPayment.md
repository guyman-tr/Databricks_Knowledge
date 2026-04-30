# Recurring.GetPaymentExecutionsResultsForPayment

> Retrieves the N most recent execution results for a specific payment, joining deposit results with request parameters to provide a combined billing outcome view.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns set of combined deposit result + request rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a comprehensive view of recent execution outcomes for a specific payment plan. It joins four tables (PaymentExecutionDepositResult + PaymentExecution + PaymentExecutionRequest + Payment) to combine what was requested (amount, currency) with what happened (deposit result, status). The @TakeLastCount parameter limits results to the N most recent executions, making it useful for displaying recent history in the UI.

Uses a temp table (#lastResult) to first identify the N most recent executions, then joins back to get full details. Groups by PaymentExecutionId to handle multiple result rows per execution, taking the MAX deposit result and request IDs.

---

## 2. Business Logic

### 2.1 Top-N Recent Results with Request+Result Join

**What**: Retrieves the last N execution results with combined request and deposit outcome data.

**Columns/Parameters Involved**: `@PaymentId`, `@TakeLastCount`

**Rules**:
- Creates #lastResult temp table to identify top N executions (by PaymentExecutionId DESC)
- Groups by PaymentExecutionId, taking MAX(PaymentExecutionDepositResultId) and MAX(PaymentExecutionRequestId) per execution
- Joins back to get full deposit result columns + request Amount + CurrencyId + Cid + RecurringProgramTypeId
- Ordered by PaymentExecutionId DESC (most recent first)
- Four-table join: DepositResult -> PaymentExecution -> Payment (for Cid, RecurringProgramTypeId) + PaymentExecutionRequest (for Amount, CurrencyId)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | FK to Recurring.Payment. Returns results for this payment plan. |
| 2 | @TakeLastCount | int (IN) | NO | - | CODE-BACKED | Number of most recent execution results to return. |

**Return Columns**: PaymentExecutionDepositResultId, PaymentExecutionId, CycleNumber, DepositId, PaymentStatusId, StatusCode, GroupKey, ExecutionResultStatusId, PaymentDate, CreateDate, ModificationDate, AmountInUsd, Amount (from Request), CurrencyId (from Request), Cid (from Payment), RecurringProgramTypeId (from Payment).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecutionDepositResult | READER | Deposit outcome data |
| - | Recurring.PaymentExecution | READER | JOIN bridge, ordering by execution ID |
| - | Recurring.PaymentExecutionRequest | READER | Request parameters (amount, currency) |
| - | Recurring.Payment | READER | Customer and program type context |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPaymentExecutionsResultsForPayment (procedure)
├── Recurring.PaymentExecutionDepositResult (table)
├── Recurring.PaymentExecution (table)
├── Recurring.PaymentExecutionRequest (table)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionDepositResult | Table | INNER JOIN for deposit results |
| Recurring.PaymentExecution | Table | INNER JOIN for execution linkage |
| Recurring.PaymentExecutionRequest | Table | INNER JOIN for request params |
| Recurring.Payment | Table | INNER JOIN for Cid and ProgramTypeId |

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

### 8.1 Get last 5 results for a payment
```sql
EXEC Recurring.GetPaymentExecutionsResultsForPayment @PaymentId = 200820, @TakeLastCount = 5
```

### 8.2 Get last 10 results
```sql
EXEC Recurring.GetPaymentExecutionsResultsForPayment @PaymentId = 200820, @TakeLastCount = 10
```

### 8.3 Get single most recent result
```sql
EXEC Recurring.GetPaymentExecutionsResultsForPayment @PaymentId = 200820, @TakeLastCount = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPaymentExecutionsResultsForPayment | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPaymentExecutionsResultsForPayment.sql*
