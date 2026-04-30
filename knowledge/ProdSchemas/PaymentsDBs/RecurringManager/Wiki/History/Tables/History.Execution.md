# History.Execution

> Temporal history table storing previous versions of scheduler execution records, capturing every state transition as the scheduling engine processes planned payment charges through to completion.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ExecutionId (mirrors PK of Scheduler.Execution) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.Execution is the system-versioned temporal history table for `Scheduler.Execution`. Each row represents a previous state of a scheduler execution record - the scheduling-layer representation of a payment charge attempt. While `Recurring.PaymentExecution` tracks the business-level execution lifecycle (planned through approved/declined), `Scheduler.Execution` tracks the scheduling-layer lifecycle (planned through sent/done/canceled). This table bridges the Plan (when to charge) with the PaymentExecution (the charge result). This is the highest-volume history table in the schema (2.5M+ rows), reflecting the frequent state transitions in the automated processing pipeline.

This table exists because the scheduling engine's internal state transitions are critical for operational monitoring and debugging. Each execution goes through Planned -> WaitingForProcess (stamped/locked) -> Sent -> Done, and each transition generates a history row. The Stamp column (GUID) is central to the lock-based processing model - it marks which executions have been claimed by a processing worker.

Data enters this table automatically via SQL Server's temporal mechanism. Executions are created by `Scheduler.CreateOrGetExecution` (idempotent by PaymentExecutionId) and progressed through states by various Scheduler procedures (SetStampForExecutionsWithLock, GetExecutionsToProcessWithLock, RevertExecution). The base table has 9 indexes, reflecting the heavy query load from the scheduling engine.

---

## 2. Business Logic

### 2.1 Scheduler Execution Lifecycle

**What**: Scheduler executions progress through states as the automated processing engine picks up and processes planned charges.

**Columns/Parameters Involved**: `ExecutionStatusId`, `Stamp`, `ActualExecutionDate`

**Rules**:
- ExecutionStatusId maps to Dictionary.ExecutionStatus: 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. See [Execution Status](../../_glossary.md#execution-status)
- Distribution: Planned (33%), WaitingForProcess (28%), Sent (28%), Done (10%), Canceled (<1%)
- Stamp (GUID) is NULL when Planned; set when a processing worker claims the execution (transition to WaitingForProcess)
- ActualExecutionDate is NULL when Planned; set when processing begins
- Status 6 (Done) does NOT imply payment success - the actual outcome is recorded in the PaymentExecution's status

**Diagram**:
```
[Planned (1)]        -- Stamp=NULL, ActualExecDate=NULL
     |
     v  (SetStampForExecutionsWithLock)
[WaitingForProcess (2)]  -- Stamp=GUID, ActualExecDate set
     |
     v  (GetExecutionsToProcessWithLock)
[Sent (3)]           -- Processing dispatched to billing
     |
     v
[Done (6)]           -- Processing complete (result in PaymentExecution)
     |
     +--> [Canceled (4)]  (plan stopped)
     +--> [Failed (5)]    (processing error)
```

### 2.2 Lock-Based Processing Model

**What**: The Stamp column implements a distributed lock pattern to prevent multiple workers from processing the same execution.

**Columns/Parameters Involved**: `Stamp`, `ExecutionStatusId`, `PlannedDate`

**Rules**:
- `Scheduler.SetStampForExecutionsWithLock` assigns a unique GUID Stamp to Planned executions, transitioning them to WaitingForProcess
- `Scheduler.GetExecutionsToProcessWithLock` retrieves executions with a matching Stamp for processing
- `Scheduler.RevertExecution` can reset an execution back to an earlier state (e.g., if processing fails)
- Multiple indexes on (ExecutionStatusId, Stamp, PlannedDate) optimize the lock-and-process queries
- Unique filtered index prevents duplicate Planned executions per (PaymentExecutionId, ExecutionTypeId) combination

### 2.3 Planned vs Dunning Executions

**What**: Executions are classified as either regular planned charges or dunning (retry) attempts.

**Columns/Parameters Involved**: `ExecutionTypeId`, `RecurringProgramTypeId`

**Rules**:
- ExecutionTypeId maps to Dictionary.ExecutionType: 1=Planned, 2=Dunning. See [Execution Type](../../_glossary.md#execution-type)
- RecurringProgramTypeId maps to Dictionary.RecurringProgramType: 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](../../_glossary.md#recurring-program-type). Added later (NULL in early data)
- Code comment in CreateOrGetExecution warns: "ON WORKING ON DUNNING SHOULD ADD FILTER BY ExecutionTypeId and ExecutionStatusId" - indicating dunning support was in development

---

## 3. Data Overview

| ExecutionId | PlanId | PaymentExecutionId | ExecutionStatusId | Stamp | ActualExecutionDate | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 1 | NULL | NULL | First execution in Planned state - not yet picked up. Stamp is NULL (not locked), ActualExecutionDate is NULL (not started). |
| 1 | 1 | 1 | 2 | F9F20D26-... | 2021-06-09 00:00:00 | Same execution after being stamped/locked (WaitingForProcess). The GUID Stamp claims this for a processing worker. ActualExecutionDate now set. Version lasted only ~1 second. |
| 1 | 1 | 1 | 3 | F9F20D26-... | 2021-06-09 00:00:01 | Same execution dispatched to billing (Sent). Shows the rapid Planned -> WaitingForProcess -> Sent progression in the automated pipeline. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Scheduler.Execution. Identifies which scheduler execution this historical version belongs to. Not unique in history - same ID appears for each state transition. |
| 2 | PlanId | int | NO | - | VERIFIED | References the schedule plan this execution was generated from. Links to Scheduler.Plan / History.Plan. Set at creation and never changed. Indexed in the base table (IX_Scheduler_Execution_PlanId_ExecutionStatusId). |
| 3 | PaymentExecutionId | int | NO | - | VERIFIED | References the payment execution (business-level charge attempt) this scheduler execution processes. Links to Recurring.PaymentExecution / History.PaymentExecution. Used as the idempotent key in CreateOrGetExecution. Indexed and part of a unique filtered index. |
| 4 | PlannedDate | datetime | NO | - | CODE-BACKED | UTC date/time when this execution was originally scheduled to run. Set at creation. Can be updated by `Scheduler.UpdateExecutionPlannedDate`. Used in processing queries to determine which executions are due. Part of multiple composite indexes. |
| 5 | ExecutionTypeId | int | NO | - | VERIFIED | Classifies the execution type. Maps to Dictionary.ExecutionType: 1=Planned, 2=Dunning. See [Execution Type](../../_glossary.md#execution-type). Set at creation via @ExecutionTypeId parameter. Determines which processing pipeline handles the execution. (Dictionary.ExecutionType) |
| 6 | ExecutionStatusId | int | NO | - | VERIFIED | Scheduler-level lifecycle state. Maps to Dictionary.ExecutionStatus: 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. See [Execution Status](../../_glossary.md#execution-status). Progressed by SetStampForExecutionsWithLock, GetExecutionsToProcessWithLock, and RevertExecution. Heavily indexed in the base table. (Dictionary.ExecutionStatus) |
| 7 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the execution was created. Set to GETDATE() by CreateOrGetExecution. Immutable after creation. |
| 8 | Stamp | uniqueidentifier | YES | - | VERIFIED | Processing lock GUID. NULL when Planned (unclaimed). Set to a unique GUID by SetStampForExecutionsWithLock when a processing worker claims the execution (transition to WaitingForProcess). Used by GetExecutionsToProcessWithLock to retrieve claimed work. Part of multiple composite indexes for lock-query optimization. |
| 9 | ActualExecutionDate | datetime | YES | - | CODE-BACKED | Timestamp when processing actually began (as opposed to PlannedDate). NULL when Planned; set when the execution is picked up for processing. Indexed (IX_SchedulerExecution_ActualExecutionDate) for reporting and monitoring queries. |
| 10 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Part of the clustered index. |
| 11 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Part of the clustered index. Sub-second gaps show rapid automated processing. |
| 12 | RecurringProgramTypeId | int | YES | - | VERIFIED | Classifies the recurring program type. Maps to Dictionary.RecurringProgramType: 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](../../_glossary.md#recurring-program-type). Added later (NULL in early data). Set at creation via @RecurringProgramTypeId. Routes execution results to the correct downstream handler. (Dictionary.RecurringProgramType) |
| 13 | VersionStamp | nvarchar(100) | YES | - | CODE-BACKED | Optimistic concurrency token. NULL in all sample data. Likely used for coordinating updates between the scheduling engine and external systems. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Scheduler.Execution | Temporal History | This is the system-versioned history table for Scheduler.Execution |
| PlanId | Scheduler.Plan / History.Plan | Implicit FK | The schedule plan this execution was generated from |
| PaymentExecutionId | Recurring.PaymentExecution / History.PaymentExecution | Implicit FK | The business-level payment execution this scheduler execution processes |
| ExecutionTypeId | Dictionary.ExecutionType | Implicit Lookup | Execution type: 1=Planned, 2=Dunning |
| ExecutionStatusId | Dictionary.ExecutionStatus | Implicit Lookup | Scheduler lifecycle: 1=Planned through 6=Done |
| RecurringProgramTypeId | Dictionary.RecurringProgramType | Implicit Lookup | Program type: 1=RecurringDeposit, 2=RecurringInvestment |

### 5.2 Referenced By (other objects point to this)

No objects in the History schema reference History.Execution directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | This is the temporal history table (SYSTEM_VERSIONING = ON) |
| Scheduler.CreateOrGetExecution | Stored Procedure | WRITER - creates executions idempotently by PaymentExecutionId |
| Scheduler.SetStampForExecutionsWithLock | Stored Procedure | MODIFIER - stamps/locks planned executions for processing |
| Scheduler.GetExecutionsToProcessWithLock | Stored Procedure | READER - retrieves stamped executions for processing |
| Scheduler.RevertExecution | Stored Procedure | MODIFIER - resets execution state on failure |
| Scheduler.GetExecutionsForPlan | Stored Procedure | READER - lists executions for a plan |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Execution | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression. The base table (Scheduler.Execution) has 9 NC indexes optimizing lock-query, status-filter, and plan-lookup patterns.

### 7.2 Constraints

None. The base table holds:
- PK_Scheduler_Execution (PK on ExecutionId)
- UQ filtered unique index (WHERE ExecutionStatusId=1, prevents duplicate Planned executions)

---

## 8. Sample Queries

### 8.1 Trace full processing history of an execution
```sql
SELECT ExecutionId, ExecutionStatusId, Stamp,
       PlannedDate, ActualExecutionDate,
       SysStartTime AS StateStart, SysEndTime AS StateEnd,
       DATEDIFF(MILLISECOND, SysStartTime, SysEndTime) AS DurationMs
FROM History.Execution WITH (NOLOCK)
WHERE ExecutionId = 1
ORDER BY SysStartTime ASC
```

### 8.2 Find executions that were reverted (went back to earlier state)
```sql
SELECT h1.ExecutionId, h1.ExecutionStatusId AS FromStatus,
       h2.ExecutionStatusId AS ToStatus, h2.SysStartTime AS RevertedAt
FROM History.Execution h1 WITH (NOLOCK)
JOIN History.Execution h2 WITH (NOLOCK) ON h2.ExecutionId = h1.ExecutionId
    AND h2.SysStartTime = h1.SysEndTime
WHERE h2.ExecutionStatusId < h1.ExecutionStatusId  -- went backwards
ORDER BY h2.SysStartTime DESC
```

### 8.3 Analyze processing throughput by joining to plan and status dictionaries
```sql
SELECT h.ExecutionId, h.PlanId, h.PaymentExecutionId,
       es.Name AS SchedulerStatus, et.Name AS ExecType,
       h.PlannedDate, h.ActualExecutionDate,
       DATEDIFF(MINUTE, h.PlannedDate, h.ActualExecutionDate) AS DelayMinutes
FROM History.Execution h WITH (NOLOCK)
JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON es.ExecutionStatusId = h.ExecutionStatusId
JOIN Dictionary.ExecutionType et WITH (NOLOCK) ON et.ExecutionTypeId = h.ExecutionTypeId
WHERE h.ExecutionStatusId = 3  -- Sent
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Execution | Type: Table | Source: RecurringManager/History/Tables/History.Execution.sql*
