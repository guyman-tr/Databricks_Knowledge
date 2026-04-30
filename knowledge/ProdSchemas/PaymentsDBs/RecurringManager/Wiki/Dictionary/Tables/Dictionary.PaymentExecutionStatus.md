# Dictionary.PaymentExecutionStatus

> Lookup table tracking the end-to-end lifecycle of a single payment execution attempt, with 10 states covering the full journey from scheduling through billing provider interaction to final resolution.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PaymentExecutionStatus is the most granular payment-level status in the RecurringManager system. It tracks the complete end-to-end journey of a single payment execution attempt within the Recurring schema, from initial planning through billing provider interaction to final resolution (approved, declined, cancelled, or skipped).

This table serves a different purpose from Dictionary.ExecutionStatus, which tracks the Scheduler pipeline state. PaymentExecutionStatus captures the business-level state of the payment itself, including provider interaction outcomes. While ExecutionStatus knows "processing is done," PaymentExecutionStatus knows "the payment was approved" or "the payment was soft-declined and will be retried."

The PK constraint name "PK_Dictionary_CycleStatus" reveals this table was originally called CycleStatus - it was renamed to PaymentExecutionStatus to better reflect its domain meaning. The Recurring.UpdatePaymentExecutionStatus stored procedure is the primary modifier, with execute permissions granted to multiple pod identities (prod-paymentsrecmgr-pod-identity for both northeurope and westeurope regions).

---

## 2. Business Logic

### 2.1 Ten-State Payment Execution Lifecycle

**What**: A payment execution progresses through up to 10 states as it moves from scheduling through billing and back, with branching paths for success, decline, retry, and cancellation.

**Columns/Parameters Involved**: `StatusId`, `Name`

**Rules**:
- Planned (1) -> InProcess (2) -> SentToBilling (3) -> Approved (7) is the happy path
- SoftDeclined (5) -> Retry (10) creates a new dunning execution
- HardDeclined (6) is terminal - may escalate to plan stoppage
- SendToBillingFailed (4) means the submission itself failed (network/validation error)
- Cancelled (8) means the execution was stopped before reaching the provider
- Skipped (9) means the execution was intentionally bypassed (e.g., duplicate cycle)

**Diagram**:
```
Planned (1)
    |
    v
InProcess (2)
    |
    v
SentToBilling (3) -------> SendToBillingFailed (4) [terminal]
    |
    +-------> Approved (7) [terminal - success]
    |
    +-------> SoftDeclined (5) --> Retry (10) --> [new dunning execution]
    |
    +-------> HardDeclined (6) [terminal - may stop plan]
    
Cancelled (8) [terminal - can occur from Planned/InProcess]
Skipped (9) [terminal - intentional bypass]
```

---

## 3. Data Overview

| StatusId | Name | Meaning |
|---|---|---|
| 1 | Planned | Execution scheduled for a future date. Initial state before processing begins. |
| 2 | InProcess | Execution picked up by the processing engine and actively being handled. |
| 3 | SentToBilling | Submitted to the external billing provider (Worldpay/Checkout). Awaiting response. |
| 4 | SendToBillingFailed | Submission to billing provider failed (network error, validation failure). Terminal failure. |
| 5 | SoftDeclined | Provider declined with a recoverable reason (insufficient funds, temporary hold). Eligible for dunning retry. |
| 6 | HardDeclined | Provider permanently declined (card expired, account closed, fraud). No further retries. May trigger plan stoppage. |
| 7 | Approved | Provider approved the charge. Funds will be collected. Terminal success. |
| 8 | Cancelled | Execution canceled before reaching the billing provider. Terminal. |
| 9 | Skipped | Execution intentionally skipped (duplicate cycle, manual override). Terminal. |
| 10 | Retry | Execution marked for retry. Will be re-attempted in the next dunning cycle. Transitional state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusId | int | NO | - | VERIFIED | Primary key identifying the payment execution lifecycle state. 1=Planned, 2=InProcess, 3=SentToBilling, 4=SendToBillingFailed, 5=SoftDeclined, 6=HardDeclined, 7=Approved, 8=Cancelled, 9=Skipped, 10=Retry. Terminal states: 4, 6, 7, 8, 9. See [Payment Execution Status](../../_glossary.md#payment-execution-status) for full definitions. (Dictionary.PaymentExecutionStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Recurring.PaymentExecution) | StatusId | Implicit FK | Tracks the current lifecycle state of each payment execution |
| Recurring.UpdatePaymentExecutionStatus | @PaymentExecutionStatusId | Parameter | Primary procedure for updating payment execution status. Granted to multiple production pod identities. |
| Recurring.GetPaymentExecutionsByForPayment | @PaymentExecutionStatusId | Parameter | Optional filter to retrieve executions in a specific status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.UpdatePaymentExecutionStatus | Stored Procedure | Updates payment execution to a new status |
| Recurring.GetPaymentExecutionsByForPayment | Stored Procedure | Filters by optional @PaymentExecutionStatusId parameter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_CycleStatus | CLUSTERED PK | StatusId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_CycleStatus | PRIMARY KEY | Legacy constraint name reveals this table was originally "CycleStatus" before being renamed to PaymentExecutionStatus |

---

## 8. Sample Queries

### 8.1 List all payment execution statuses
```sql
SELECT StatusId, Name
FROM Dictionary.PaymentExecutionStatus WITH (NOLOCK)
ORDER BY StatusId
```

### 8.2 Classify statuses by terminal vs transitional
```sql
SELECT StatusId, Name,
    CASE WHEN StatusId IN (4, 6, 7, 8, 9) THEN 'Terminal'
         WHEN StatusId = 10 THEN 'Transitional (awaiting dunning)'
         ELSE 'Active (in processing pipeline)'
    END AS StatusCategory
FROM Dictionary.PaymentExecutionStatus WITH (NOLOCK)
ORDER BY StatusId
```

### 8.3 Payment execution outcome distribution
```sql
SELECT pes.Name AS ExecutionStatus, COUNT(*) AS ExecutionCount
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pe.StatusId = pes.StatusId
GROUP BY pes.Name
ORDER BY ExecutionCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD- Recurring Integration with provider](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1860534325) | Confluence | Business context: Provider integration uses Worldpay and Checkout; SoftDecline/HardDecline handling follows provider response codes |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business flow: Deposit Message Handler processes execution results; Before Deposit Job checks eligibility |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 2 analyzed (references) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentExecutionStatus | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.PaymentExecutionStatus.sql*
