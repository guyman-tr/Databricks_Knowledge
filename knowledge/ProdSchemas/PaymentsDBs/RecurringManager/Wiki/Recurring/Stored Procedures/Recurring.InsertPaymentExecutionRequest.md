# Recurring.InsertPaymentExecutionRequest

> Creates a billing request record capturing the exact amount, currency, and payment method to charge for a specific execution.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into PaymentExecutionRequest (no return) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates an immutable billing request record in Recurring.PaymentExecutionRequest. It snapshots the exact amount, currency, funding source, and authentication details that will be sent to the billing processor for a specific execution cycle. Called just before the billing API call, it ensures there is a permanent record of what was requested even if the billing call fails.

Unlike UpsertPaymentExecutionDepositResult (which updates on subsequent calls), this is a pure INSERT - each execution gets exactly one request record that never changes.

---

## 2. Business Logic

### 2.1 Write-Once Request Capture

**What**: Creates an immutable record of billing parameters for an execution.

**Columns/Parameters Involved**: `@PaymentExecutionId`, `@FundingId`, `@Amount`, `@CurrencyId`, `@AuthenticationId`

**Rules**:
- Simple INSERT with no existence check (assumes one request per execution)
- SET NOCOUNT ON prevents row count interference
- AuthenticationId is optional (NULL for pre-authorized payment methods)
- No OUTPUT clause - does not return the inserted record

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentExecutionId | int (IN) | NO | - | CODE-BACKED | FK to PaymentExecution. The execution this request is for. |
| 2 | @FundingId | int (IN) | NO | - | CODE-BACKED | Payment method reference (snapshot from Payment at execution time). |
| 3 | @Amount | money (IN) | NO | - | CODE-BACKED | Amount to charge in the specified currency. |
| 4 | @CurrencyId | int (IN) | NO | - | CODE-BACKED | Currency of the charge amount. |
| 5 | @AuthenticationId | int (IN) | YES | NULL | CODE-BACKED | SCA/authentication reference if required by the payment method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecutionRequest | WRITER | INSERT - creates request record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.InsertPaymentExecutionRequest (procedure)
└── Recurring.PaymentExecutionRequest (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionRequest | Table | INSERT |

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

### 8.1 Create a billing request
```sql
EXEC Recurring.InsertPaymentExecutionRequest @PaymentExecutionId = 859547, @FundingId = 16809114, @Amount = 100, @CurrencyId = 1
```

### 8.2 With authentication
```sql
EXEC Recurring.InsertPaymentExecutionRequest @PaymentExecutionId = 859547, @FundingId = 16809114, @Amount = 50, @CurrencyId = 2, @AuthenticationId = 12248
```

### 8.3 Verify the request was created
```sql
SELECT * FROM Recurring.PaymentExecutionRequest WITH (NOLOCK) WHERE PaymentExecutionId = 859547
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.InsertPaymentExecutionRequest | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.InsertPaymentExecutionRequest.sql*
