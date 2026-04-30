# History.PaymentExecution

> Temporal history table storing previous versions of payment execution records, capturing every status transition as individual charge attempts progress from planned through billing submission to final resolution.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentExecutionId (mirrors PK of Recurring.PaymentExecution) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.PaymentExecution is the system-versioned temporal history table for `Recurring.PaymentExecution`. Each row represents a previous state of a payment execution - a single charge attempt within a recurring payment's lifecycle. Payment executions represent the operational unit of work: when a scheduled payment date arrives, an execution is created (Planned), picked up for processing (InProcess), sent to the billing provider (SentToBilling), and resolved (Approved, SoftDeclined, HardDeclined, etc.). This table captures every state transition in that journey.

This table exists because payment execution status transitions are the core operational data of the recurring payments system. Every transition generates a history row, making this one of the highest-volume history tables. The audit trail is critical for reconciliation with billing providers, debugging failed charges, tracking dunning retry cycles, and compliance reporting.

Data enters this table automatically via SQL Server's temporal mechanism. Executions are created by `Recurring.CreatePaymentExecution` (idempotent insert with StatusId=1/Planned) and progressed through states by `Recurring.UpdatePaymentExecutionStatus` (optimistic concurrency with @PreviousExecutionStatus). Each status update moves the old version here. The sample data shows the classic transition: StatusId 1->2->3 (Planned->InProcess->SentToBilling) within seconds, reflecting the automated processing pipeline.

---

## 2. Business Logic

### 2.1 Execution Status Lifecycle

**What**: Payment executions progress through a 10-state lifecycle tracking the full journey from scheduling to resolution.

**Columns/Parameters Involved**: `StatusId`, `ModificationDate`

**Rules**:
- StatusId maps to Dictionary.PaymentExecutionStatus: 1=Planned, 2=InProcess, 3=SentToBilling, 4=SendToBillingFailed, 5=SoftDeclined, 6=HardDeclined, 7=Approved, 8=Cancelled, 9=Skipped, 10=Retry. See [Payment Execution Status](../../_glossary.md#payment-execution-status)
- `Recurring.UpdatePaymentExecutionStatus` uses optimistic concurrency: `WHERE StatusId = ISNULL(@PreviousExecutionStatus, StatusId)` ensures transitions only happen from expected states
- ModificationDate is set to GETUTCDATE() on every status transition

**Diagram**:
```
[Planned (1)] --> [InProcess (2)] --> [SentToBilling (3)] --> [Approved (7)]
                                           |                        |
                                           +--> [SendToBillingFailed (4)]
                                           |
                                           +--> [SoftDeclined (5)] --> [Retry (10)]
                                           |
                                           +--> [HardDeclined (6)]
[Planned (1)] --> [Cancelled (8)]
[Planned (1)] --> [Skipped (9)]
```

### 2.2 Idempotent Execution Creation with Duplicate Prevention

**What**: The system prevents duplicate executions for the same payment/status/retry combination.

**Columns/Parameters Involved**: `PaymentId`, `StatusId`, `CycleNumber`, `Retries`

**Rules**:
- `Recurring.CreatePaymentExecution` checks `WHERE PaymentId = @PaymentId AND StatusId = @StatusId AND Retries = @Retries` before insert
- A unique filtered index `UQ_..._PaymentId_CycleNumber_Retries_StatusId WHERE StatusId=1` prevents duplicate Planned executions at the database level
- Default StatusId=1 (Planned) and Retries=1 for new executions
- CycleNumber tracks which recurring cycle this execution belongs to (1st, 2nd, 3rd payment period, etc.)

### 2.3 Retry/Dunning Tracking

**What**: The Retries column tracks dunning attempts for soft-declined payments.

**Columns/Parameters Involved**: `Retries`, `CycleNumber`, `StatusId`

**Rules**:
- Retries=1 is the initial execution attempt (default in CreatePaymentExecution)
- When a SoftDecline occurs, a new execution may be created with Retries incremented for the same CycleNumber
- Each retry generates its own execution record with its own status lifecycle
- The unique filtered index ensures only one Planned execution exists per (PaymentId, CycleNumber, Retries) combination

---

## 3. Data Overview

| PaymentExecutionId | PaymentId | StatusId | CycleNumber | Retries | Meaning |
|---|---|---|---|---|---|
| 1 | 1 | 1 | 1 | 1 | First-ever execution (June 2021) in Planned state - this version existed for ~12 hours before being picked up for processing. Shows the initial state of every execution. |
| 1 | 1 | 2 | 1 | 1 | Same execution after transitioning to InProcess - the processing engine picked it up. This version lasted only ~400ms before moving to SentToBilling, showing rapid automated processing. |
| 1 | 1 | 3 | 1 | 1 | Same execution sent to the billing provider. Each row shows a single state in the execution's journey - 3 history rows for 3 transitions (Planned -> InProcess -> SentToBilling). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentExecutionId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Recurring.PaymentExecution. Identifies which execution this historical version belongs to. Not unique in history - the same ID appears multiple times representing successive status transitions. Created by `Recurring.CreatePaymentExecution`. |
| 2 | PaymentId | int | NO | - | VERIFIED | References the parent recurring payment this execution belongs to. Links to Recurring.Payment / History.Payment. Set at creation and never changed. Indexed in the base table (IX_PaymentExecution_PaymentId). Part of the uniqueness constraint for duplicate prevention. |
| 3 | StatusId | int | NO | - | VERIFIED | Execution lifecycle state. Maps to Dictionary.PaymentExecutionStatus: 1=Planned, 2=InProcess, 3=SentToBilling, 4=SendToBillingFailed, 5=SoftDeclined, 6=HardDeclined, 7=Approved, 8=Cancelled, 9=Skipped, 10=Retry. See [Payment Execution Status](../../_glossary.md#payment-execution-status). Set to 1 (Planned) by CreatePaymentExecution. Updated by UpdatePaymentExecutionStatus with optimistic concurrency via @PreviousExecutionStatus. Indexed heavily in the base table. (Dictionary.PaymentExecutionStatus) |
| 4 | CycleNumber | int | NO | - | CODE-BACKED | Identifies which recurring payment cycle this execution belongs to (1st period, 2nd period, etc.). Passed as @CycleNumber parameter to CreatePaymentExecution. Increments with each scheduled payment period. Part of the unique filtered index for duplicate prevention (with Retries and StatusId=1). |
| 5 | Retries | int | NO | - | CODE-BACKED | Tracks the retry/dunning attempt number within a cycle. Default: 1 (first attempt) in CreatePaymentExecution. Incremented for dunning retries after soft declines. Part of the idempotent creation check and the unique filtered index. Used in alert procedures to monitor execution processing. |
| 6 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the execution was originally created. Set to GETUTCDATE() by CreatePaymentExecution. DEFAULT: getutcdate(). Immutable after creation. |
| 7 | ModificationDate | datetime | YES | - | CODE-BACKED | Timestamp of the most recent status transition. Set to GETUTCDATE() by both CreatePaymentExecution (initial) and UpdatePaymentExecutionStatus (subsequent updates). NULL only if never modified after creation. Indexed in the base table (IX_PaymentExecution_StatusId_ModificationDate) for alert queries that monitor stuck executions. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version became active. Part of the clustered index. |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version was superseded. Part of the clustered index. Sub-second gaps for InProcess transitions show rapid automated processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Recurring.PaymentExecution | Temporal History | This is the system-versioned history table for Recurring.PaymentExecution |
| PaymentId | Recurring.Payment / History.Payment | Implicit FK | The parent recurring payment this execution belongs to |
| StatusId | Dictionary.PaymentExecutionStatus | Implicit Lookup | Execution lifecycle state (10 values) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Execution | PaymentExecutionId | Implicit FK | Scheduler execution records reference the payment execution they process |
| History.Notification | PaymentExecutionId | Implicit FK | Notifications sent about execution outcomes |
| History.PaymentExecutionDepositResult | PaymentExecutionId | Implicit FK | Deposit results for this execution attempt |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | This is the temporal history table (SYSTEM_VERSIONING = ON) |
| Recurring.CreatePaymentExecution | Stored Procedure | WRITER - creates execution records with StatusId=1 |
| Recurring.UpdatePaymentExecutionStatus | Stored Procedure | MODIFIER - transitions execution status with optimistic concurrency |
| Recurring.GetPaymentExecution | Stored Procedure | READER - retrieves execution details |
| Recurring.GetPaymentExecutionsResultsForPayment | Stored Procedure | READER - retrieves execution results for a payment |
| Recurring.Alert_StuckWithTemproraryStatus | Stored Procedure | READER - monitors executions stuck in temporary states |
| Recurring.Alert_SendToBillingFailed | Stored Procedure | READER - alerts on billing submission failures |
| Recurring.Alert_NotTakenPaymentExecutions | Stored Procedure | READER - alerts on unprocessed executions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PaymentExecution | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression is enabled. The base table has 4 additional indexes:
- IX_PaymentExecution_PaymentId (NC, PAGE compressed)
- IX_PaymentExecution_StatusId_ModificationDate (NC)
- IX_Recurring_PaymentExecution_PaymentId_StatusId (NC, PAGE compressed)
- UQ_Recurring_PaymentExecution_... (UNIQUE NC, filtered WHERE StatusId=1, PAGE compressed)

### 7.2 Constraints

None. The base table holds:
- PK_Recurring_PaymentExecution (PK on PaymentExecutionId)
- UQ filtered unique index (prevents duplicate Planned executions)
- DF_Recurring_PaymentExecution_CreateDate (DEFAULT getutcdate())

---

## 8. Sample Queries

### 8.1 Trace the full status history of an execution
```sql
SELECT PaymentExecutionId, StatusId, CycleNumber, Retries,
       SysStartTime AS StateStart, SysEndTime AS StateEnd,
       DATEDIFF(MILLISECOND, SysStartTime, SysEndTime) AS DurationMs
FROM History.PaymentExecution WITH (NOLOCK)
WHERE PaymentExecutionId = 1
ORDER BY SysStartTime ASC
```

### 8.2 Find executions that went through soft decline and retry
```sql
SELECT DISTINCT PaymentExecutionId, PaymentId, CycleNumber, Retries
FROM History.PaymentExecution WITH (NOLOCK)
WHERE StatusId = 5  -- SoftDeclined
ORDER BY PaymentExecutionId DESC
```

### 8.3 Analyze execution processing speed (time in each state)
```sql
SELECT h.PaymentExecutionId,
       pes.Name AS StatusName,
       h.SysStartTime, h.SysEndTime,
       DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS SecondsInState
FROM History.PaymentExecution h WITH (NOLOCK)
JOIN Dictionary.PaymentExecutionStatus pes WITH (NOLOCK) ON pes.PaymentExecutionStatusId = h.StatusId
WHERE h.PaymentExecutionId = 100
ORDER BY h.SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PaymentExecution | Type: Table | Source: RecurringManager/History/Tables/History.PaymentExecution.sql*
