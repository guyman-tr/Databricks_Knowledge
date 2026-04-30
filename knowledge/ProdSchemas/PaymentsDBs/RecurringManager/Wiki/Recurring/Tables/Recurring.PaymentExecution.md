# Recurring.PaymentExecution

> Core transactional table tracking individual execution cycles of recurring payments - each row represents one attempt to charge a customer's payment method for a specific cycle of their recurring plan.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | PaymentExecutionId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 4 nonclustered (1 unique filtered) |

---

## 1. Business Meaning

Recurring.PaymentExecution is the execution-level table that records each individual charge attempt against a recurring payment plan. While Recurring.Payment represents the subscription itself, PaymentExecution represents each periodic execution cycle - the actual attempt to charge the customer's payment method. A single payment plan generates many executions over its lifetime, one per billing cycle, with possible retries on failure.

This table is critical to the recurring payments pipeline. It sits between the payment plan (what to charge) and the deposit result (what happened when we charged). Without it, the system would have no way to track which cycles have been executed, which are pending, and which failed. It drives the scheduler, billing integration, alert monitoring, and result tracking.

Rows are created by Recurring.CreatePaymentExecution when the scheduler triggers a new cycle. The StatusId progresses through the execution lifecycle (Planned -> InProcess -> SentToBilling -> Approved/SoftDeclined/HardDeclined). UpdatePaymentExecutionStatus transitions statuses with optimistic concurrency (checks previous status before updating). Multiple alert SPs monitor for stuck executions. System-versioned with History.PaymentExecution.

---

## 2. Business Logic

### 2.1 Execution Status Lifecycle

**What**: Each execution progresses through a defined state machine from planning to terminal outcome.

**Columns/Parameters Involved**: `StatusId`, `ModificationDate`

**Rules**:
- StatusId values from Dictionary.PaymentExecutionStatus:
  - 1=Planned (1.9%) - created by scheduler, waiting to be picked up
  - 2=InProcess - being processed (transient, monitored for stuckness)
  - 3=SentToBilling (0.003%) - sent to payment processor (transient, monitored)
  - 4=SendToBillingFailed - failed to reach processor (alert trigger)
  - 5=SoftDeclined (1.3%) - processor declined but retryable
  - 6=HardDeclined (7.5%) - processor permanently declined
  - 7=Approved (76.5%) - payment successful
  - 8=Cancelled (12.6%) - execution cancelled (e.g., plan was cancelled)
  - 9=Skipped (0.2%) - execution skipped (e.g., insufficient conditions)
  - 10=Retry - queued for retry after soft decline
- UpdatePaymentExecutionStatus uses optimistic concurrency: `WHERE StatusId = ISNULL(@PreviousExecutionStatus, StatusId)` - prevents stale state transitions

**Diagram**:
```
[1 Planned] --> [2 InProcess] --> [3 SentToBilling] --> [7 Approved]
                                                    --> [5 SoftDeclined] --> [10 Retry] --> [1 Planned]
                                                    --> [6 HardDeclined]
                                    [4 SendToBillingFailed]
[1 Planned] --> [8 Cancelled]
[1 Planned] --> [9 Skipped]
```

### 2.2 Cycle and Retry Tracking

**What**: Combines CycleNumber and Retries to uniquely identify each execution attempt within a payment plan.

**Columns/Parameters Involved**: `PaymentId`, `CycleNumber`, `Retries`, `StatusId`

**Rules**:
- CycleNumber identifies which billing cycle this execution belongs to (1 = first month, 2 = second month, etc.)
- Retries tracks the retry count within a cycle (1 = first attempt)
- A unique filtered index enforces: only ONE Planned (StatusId=1) execution per (PaymentId, CycleNumber, Retries) combination
- CreatePaymentExecution checks `NOT EXISTS (PaymentId + StatusId + Retries)` before inserting, preventing duplicate planned executions
- If an execution is soft-declined and retried, a new execution row is created with the same CycleNumber but potentially different Retries value

---

## 3. Data Overview

| PaymentExecutionId | PaymentId | StatusId | CycleNumber | Retries | Meaning |
|---|---|---|---|---|---|
| 859547 | 200820 | 1 (Planned) | 1 | 1 | Brand new execution for payment 200820, first cycle, first attempt. Just created by scheduler, waiting to be picked up for processing. |
| 859544 | 200817 | 1 (Planned) | 1 | 1 | Another first-cycle planned execution. The payment (200817) was recently modified (Generation=1), but the execution proceeds normally. |
| (example) | - | 7 (Approved) | - | - | Successfully charged execution. 76.5% of all executions reach this terminal state - the happy path. |
| (example) | - | 6 (HardDeclined) | - | - | Permanently declined by processor. 7.5% of executions. Triggers plan-level status change to Blocked. |
| (example) | - | 8 (Cancelled) | - | - | Cancelled execution, typically because the payment plan was cancelled before this cycle could execute. 12.6% of executions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentExecutionId | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. Current max ~859,547. Referenced by PaymentExecutionDepositResult, PaymentExecutionRequest, Notification, and Scheduler.Execution. |
| 2 | PaymentId | int | NO | - | VERIFIED | FK to Recurring.Payment.PaymentId. Identifies which recurring plan this execution belongs to. Multiple executions per payment over time (one per billing cycle + retries). Indexed for lookup (IX_PaymentExecution_PaymentId) and composite queries. |
| 3 | StatusId | int | NO | - | VERIFIED | Execution lifecycle status. FK to Dictionary.PaymentExecutionStatus: 1=Planned (1.9%), 2=InProcess, 3=SentToBilling (0.003%), 4=SendToBillingFailed, 5=SoftDeclined (1.3%), 6=HardDeclined (7.5%), 7=Approved (76.5%), 8=Cancelled (12.6%), 9=Skipped (0.2%), 10=Retry. Updated by UpdatePaymentExecutionStatus with optimistic concurrency on previous state. |
| 4 | CycleNumber | int | NO | - | CODE-BACKED | Which billing cycle this execution represents (1 = first cycle, 2 = second, etc.). Combined with Retries to uniquely identify an execution attempt. Part of the unique filtered index for Planned executions. |
| 5 | Retries | int | NO | - | CODE-BACKED | Retry count within the cycle (1 = first attempt). Used by CreatePaymentExecution in the duplicate check: `NOT EXISTS (PaymentId + StatusId + Retries)`. Part of the unique filtered index for Planned executions. |
| 6 | CreateDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when this execution was created by CreatePaymentExecution. Auto-set via default constraint. |
| 7 | ModificationDate | datetime | YES | - | CODE-BACKED | UTC timestamp of the last status change. Set to GETUTCDATE() by UpdatePaymentExecutionStatus and CreatePaymentExecution. NULL if never modified after creation. Used by alert SPs for time-window filtering of stuck executions. |
| 8 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | System-versioning row start time (HIDDEN). |
| 9 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end time (HIDDEN). History stored in History.PaymentExecution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentId | Recurring.Payment | Implicit FK | The recurring plan this execution belongs to |
| StatusId | Dictionary.PaymentExecutionStatus | Implicit FK (Lookup) | Execution lifecycle status (10 possible states) |
| - | History.PaymentExecution | System Versioning | Full audit trail of status changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.PaymentExecutionDepositResult | PaymentExecutionId | Implicit FK | Deposit results from the billing processor for this execution |
| Recurring.PaymentExecutionRequest | PaymentExecutionId | Implicit FK | The request parameters sent to billing for this execution |
| Recurring.Notification | PaymentExecutionId | Implicit FK | Notifications triggered by this execution |
| Scheduler.Execution | PaymentExecutionId | Implicit FK (Cross-Schema) | Scheduler execution record linked to this payment execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionDepositResult | Table | PaymentExecutionId FK - stores billing results |
| Recurring.PaymentExecutionRequest | Table | PaymentExecutionId FK - stores billing request params |
| Recurring.Notification | Table | PaymentExecutionId FK - notifications per execution |
| Scheduler.Execution | Table | PaymentExecutionId FK - scheduler linkage |
| Recurring.CreatePaymentExecution | Stored Procedure | WRITER - creates new executions |
| Recurring.UpdatePaymentExecutionStatus | Stored Procedure | MODIFIER - transitions execution status |
| Recurring.GetPaymentExecution | Stored Procedure | READER - retrieves by ID |
| Recurring.GetPaymentExecutionsByForPayment | Stored Procedure | READER - retrieves by PaymentId |
| Recurring.Alert_NotTakenPaymentExecutions | Stored Procedure | READER - monitors stuck executions |
| Recurring.Alert_SendToBillingFailed | Stored Procedure | READER - monitors billing send failures |
| Recurring.Alert_StuckWithTemproraryStatus | Stored Procedure | READER - monitors transient status stuckness |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_PaymentExecution | CLUSTERED | PaymentExecutionId ASC | - | - | Active |
| IX_PaymentExecution_PaymentId | NONCLUSTERED (PAGE) | PaymentId ASC | - | - | Active |
| IX_PaymentExecution_StatusId_ModificationDate | NONCLUSTERED | StatusId ASC, ModificationDate ASC | - | - | Active |
| IX_Recurring_PaymentExecution_PaymentId_StatusId | NONCLUSTERED (PAGE) | PaymentId ASC, StatusId ASC | - | - | Active |
| UQ_Recurring_PaymentExecution_PaymentId_CycleNumber_Retries_StatusId | UNIQUE NONCLUSTERED (PAGE) | PaymentId ASC, CycleNumber ASC, Retries ASC, StatusId ASC | - | WHERE StatusId=1 | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_PaymentExecution | PRIMARY KEY | Clustered on PaymentExecutionId |
| DF_Recurring_PaymentExecution_CreateDate | DEFAULT | getutcdate() for CreateDate |
| DF_PaymentExecution_SysStart | DEFAULT | sysutcdatetime() for SysStartTime |
| DF_PaymentExecution_SysEnd | DEFAULT | CONVERT(datetime2, '9999-12-31 23:59:59.9999999') for SysEndTime |
| UQ filtered index | UNIQUE + FILTER | Ensures only one Planned execution per (PaymentId, CycleNumber, Retries) |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.PaymentExecution |

---

## 8. Sample Queries

### 8.1 Get all executions for a payment with status names
```sql
SELECT pe.PaymentExecutionId, pe.CycleNumber, pe.Retries,
       pes.Name AS ExecutionStatus, pe.CreateDate, pe.ModificationDate
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pe.StatusId = pes.StatusId
WHERE pe.PaymentId = @PaymentId
ORDER BY pe.CycleNumber DESC, pe.Retries DESC
```

### 8.2 Find stuck executions in transient states
```sql
SELECT pe.PaymentExecutionId, pe.PaymentId, pes.Name AS Status,
       pe.ModificationDate, DATEDIFF(MINUTE, pe.ModificationDate, GETUTCDATE()) AS MinutesStuck
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pe.StatusId = pes.StatusId
WHERE pe.StatusId IN (2, 3)
  AND pe.ModificationDate < DATEADD(MINUTE, -30, GETUTCDATE())
ORDER BY pe.ModificationDate ASC
```

### 8.3 Execution outcome summary by status
```sql
SELECT pes.Name AS ExecutionStatus, COUNT(*) AS ExecutionCount,
       MIN(pe.CreateDate) AS Earliest, MAX(pe.CreateDate) AS Latest
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
INNER JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pe.StatusId = pes.StatusId
GROUP BY pes.Name
ORDER BY ExecutionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 11 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.PaymentExecution | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.PaymentExecution.sql*
