# Recurring.UpsertPaymentExecutionDepositResult

> Upserts a billing processor deposit result for a payment execution by (PaymentExecutionId + CycleNumber), recording the processor's response including deposit ID, status, and decline classification.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the upserted PaymentExecutionDepositResult row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records the billing processor's response for a payment execution cycle. It upserts by (PaymentExecutionId, CycleNumber) - if a result already exists for this execution cycle (e.g., from a partial response), it updates all fields with the latest response; otherwise it creates a new record. Returns the final state of the result row.

Called by the execution pipeline when a billing processor response is received, this is the primary mechanism for recording whether a charge succeeded, was soft-declined (retryable), or hard-declined (terminal).

---

## 2. Business Logic

### 2.1 Upsert by (PaymentExecutionId, CycleNumber)

**What**: Creates or updates a deposit result for a specific execution cycle.

**Columns/Parameters Involved**: `@PaymentExecutionId`, `@CycleNumber`, `@DepositId`, `@PaymentStatusId`, `@StatusCode`, `@GroupKey`, `@ExecutionResultStatusId`, `@PaymentDate`, `@AmountInUsd`

**Rules**:
- IF EXISTS (WHERE PaymentExecutionId AND CycleNumber): UPDATE all fields (DepositId, PaymentStatusId, StatusCode, GroupKey, ExecutionResultStatusId, PaymentDate, AmountInUsd, ModificationDate)
- ELSE: INSERT new row with all fields + CreateDate/ModificationDate = GETUTCDATE()
- Returns TOP 1 result row after upsert
- @AmountInUsd defaults to 0 if not provided
- @StatusCode, @GroupKey, @ExecutionResultStatusId, @PaymentDate are optional (nullable)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentExecutionId | int (IN) | NO | - | CODE-BACKED | FK to PaymentExecution. Part of upsert key. |
| 2 | @CycleNumber | int (IN) | NO | - | CODE-BACKED | Billing cycle number. Part of upsert key. |
| 3 | @DepositId | int (IN) | NO | - | CODE-BACKED | External deposit transaction reference from billing processor. |
| 4 | @PaymentStatusId | int (IN) | NO | - | CODE-BACKED | Billing processor status (2=Approved, 3=Declined, 35=Severe failure). |
| 5 | @StatusCode | int (IN) | YES | NULL | CODE-BACKED | Specific processor sub-code for decline categorization. |
| 6 | @GroupKey | nvarchar(10) (IN) | YES | NULL | CODE-BACKED | Grouping key for batched transactions. |
| 7 | @ExecutionResultStatusId | int (IN) | YES | NULL | CODE-BACKED | Decline classification: 1=Success, 2=SoftDecline, 3=HardDecline. |
| 8 | @PaymentDate | datetime (IN) | YES | NULL | CODE-BACKED | When the processor actually processed the payment. |
| 9 | @AmountInUsd | money (IN) | NO | 0 | CODE-BACKED | USD-equivalent amount of the deposit. |

**Return Columns**: PaymentExecutionDepositResultId, PaymentExecutionId, CycleNumber, DepositId, PaymentStatusId, StatusCode, GroupKey, AmountInUsd, ExecutionResultStatusId, PaymentDate, CreateDate, ModificationDate.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecutionDepositResult | WRITER + MODIFIER + READER | Upsert by (PaymentExecutionId, CycleNumber), then SELECT |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.UpsertPaymentExecutionDepositResult (procedure)
└── Recurring.PaymentExecutionDepositResult (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionDepositResult | Table | SELECT for existence, INSERT or UPDATE, then SELECT |

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

### 8.1 Record a successful deposit
```sql
EXEC Recurring.UpsertPaymentExecutionDepositResult @PaymentExecutionId = 859547, @CycleNumber = 1,
    @DepositId = 75251630, @PaymentStatusId = 2, @ExecutionResultStatusId = 1,
    @PaymentDate = '2026-04-16T10:00:00', @AmountInUsd = 100.50
```

### 8.2 Record a soft decline
```sql
EXEC Recurring.UpsertPaymentExecutionDepositResult @PaymentExecutionId = 859547, @CycleNumber = 1,
    @DepositId = 75251631, @PaymentStatusId = 3, @StatusCode = 1214,
    @ExecutionResultStatusId = 2, @AmountInUsd = 0
```

### 8.3 Record a hard decline
```sql
EXEC Recurring.UpsertPaymentExecutionDepositResult @PaymentExecutionId = 859547, @CycleNumber = 1,
    @DepositId = 75251632, @PaymentStatusId = 3, @StatusCode = 1960,
    @ExecutionResultStatusId = 3, @AmountInUsd = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.UpsertPaymentExecutionDepositResult | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.UpsertPaymentExecutionDepositResult.sql*
