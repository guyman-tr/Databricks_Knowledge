# Recurring.PaymentExecutionRequest

> Stores the billing request parameters sent to the payment processor for each execution - the amount, currency, funding source, and authentication details that define what was actually charged.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | PaymentExecutionRequestId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 nonclustered (PAGE) |

---

## 1. Business Meaning

Recurring.PaymentExecutionRequest captures the exact parameters sent to the billing processor for each payment execution. While the Payment table stores the plan's current amount and funding source (which can change over time), the Request table freezes the specific values used for each individual charge. This is critical because a customer may modify their recurring plan between cycles, and each execution needs an immutable record of what was actually billed.

This table exists for financial accuracy and auditability. Without it, there would be no way to know what amount and payment method were used for a specific execution if the customer later changes their plan. It pairs with PaymentExecutionDepositResult: the Request records what was sent, the Result records what came back.

Data enters through Recurring.InsertPaymentExecutionRequest (simple INSERT, not upsert). One request per execution. Read by GetPaymentExecutionRequest and joined in GetPaymentExecutionsResultsForPayment for combined request+result views. Not system-versioned (immutable after creation).

---

## 2. Business Logic

### 2.1 Point-in-Time Billing Snapshot

**What**: Each request row freezes the billing parameters at the time of execution, independent of subsequent plan changes.

**Columns/Parameters Involved**: `PaymentExecutionId`, `FundingId`, `Amount`, `CurrencyId`, `AuthenticationId`

**Rules**:
- Values are copied from the Payment table (or derived by the application) at execution time, then stored here immutably
- Amount and CurrencyId here may differ from Payment.Amount/CurrencyId if the customer modified their plan between this execution's creation and a prior cycle
- FundingId captures which specific payment method was charged (may differ from current Payment.FundingId if customer switched cards)
- AuthenticationId links to an SCA/authentication record if the payment method required re-authentication
- No UPDATE stored procedure exists - rows are write-once (InsertPaymentExecutionRequest only inserts)

---

## 3. Data Overview

| PaymentExecutionRequestId | PaymentExecutionId | FundingId | Amount | CurrencyId | Meaning |
|---|---|---|---|---|---|
| 354414 | 854711 | 15717423 | 100 | 2 (EUR) | Billing request for 100 EUR using funding source 15717423. No SCA authentication required (AuthenticationId NULL). |
| 354413 | 854704 | 12572973 | 10 | 3 (GBP) | Small recurring deposit of 10 GBP. A minimal-amount plan. |
| 354412 | 851004 | 17315677 | 50 | 3 (GBP) | 50 GBP request. This execution's deposit result shows AmountInUsd=67.18, providing the USD conversion rate at time of processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentExecutionRequestId | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. Current max ~354,414. |
| 2 | PaymentExecutionId | int | NO | - | VERIFIED | FK to Recurring.PaymentExecution.PaymentExecutionId. Links this request to its execution. One request per execution. Indexed (PAGE compressed). |
| 3 | FundingId | int | NO | - | CODE-BACKED | External reference to the payment method used for this specific charge. Snapshot of the funding source at execution time - may differ from Payment.FundingId if the customer changed cards between cycles. |
| 4 | Amount | money | NO | - | CODE-BACKED | The amount charged in the original currency (specified by CurrencyId). Snapshot of the billing amount at execution time. May differ from Payment.Amount if the plan was modified. |
| 5 | CurrencyId | int | NO | - | CODE-BACKED | Currency of the charged amount. References external currency dictionary. Snapshot at execution time. The USD equivalent is stored in PaymentExecutionDepositResult.AmountInUsd. |
| 6 | AuthenticationId | int | YES | - | CODE-BACKED | External reference to an SCA/authentication record. NULL when no re-authentication was required for this charge. Populated when the payment method triggered Strong Customer Authentication. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentExecutionId | Recurring.PaymentExecution | Implicit FK | The execution this request was sent for |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.InsertPaymentExecutionRequest | - | Stored Procedure (WRITER) | Creates request records |
| Recurring.GetPaymentExecutionRequest | - | Stored Procedure (READER) | Reads by PaymentExecutionId |
| Recurring.GetPaymentExecutionsResultsForPayment | - | Stored Procedure (READER) | Joins request + result for combined view |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.InsertPaymentExecutionRequest | Stored Procedure | WRITER - inserts request records |
| Recurring.GetPaymentExecutionRequest | Stored Procedure | READER - reads by execution ID |
| Recurring.GetPaymentExecutionsResultsForPayment | Stored Procedure | READER - joins for combined view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_PaymentExecutionRequest | CLUSTERED | PaymentExecutionRequestId ASC | - | - | Active |
| IX_PaymentExecutionReques_PaymentExecutionId | NONCLUSTERED (PAGE) | PaymentExecutionId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_PaymentExecutionRequest | PRIMARY KEY | Clustered on PaymentExecutionRequestId |

---

## 8. Sample Queries

### 8.1 Get the billing request for an execution
```sql
SELECT per.PaymentExecutionRequestId, per.FundingId,
       per.Amount, per.CurrencyId, per.AuthenticationId
FROM Recurring.PaymentExecutionRequest per WITH (NOLOCK)
WHERE per.PaymentExecutionId = @PaymentExecutionId
```

### 8.2 Combined request + result for a payment
```sql
SELECT pe.PaymentExecutionId, pe.CycleNumber,
       per.Amount AS RequestAmount, per.CurrencyId,
       pedr.AmountInUsd, pedr.PaymentStatusId,
       ers.Name AS ResultStatus
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Recurring.PaymentExecutionRequest per WITH (NOLOCK) ON pe.PaymentExecutionId = per.PaymentExecutionId
LEFT JOIN Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK) ON pe.PaymentExecutionId = pedr.PaymentExecutionId
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
WHERE pe.PaymentId = @PaymentId
ORDER BY pe.CycleNumber DESC
```

### 8.3 Find requests without matching deposit results (in-flight)
```sql
SELECT per.PaymentExecutionRequestId, per.PaymentExecutionId,
       per.Amount, per.CurrencyId
FROM Recurring.PaymentExecutionRequest per WITH (NOLOCK)
LEFT JOIN Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK) ON per.PaymentExecutionId = pedr.PaymentExecutionId
WHERE pedr.PaymentExecutionDepositResultId IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.PaymentExecutionRequest | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.PaymentExecutionRequest.sql*
