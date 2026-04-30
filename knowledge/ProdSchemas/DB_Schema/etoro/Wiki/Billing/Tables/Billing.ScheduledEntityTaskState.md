# Billing.ScheduledEntityTaskState

> Task execution state tracker for the "Post Withdrawal to Funding" scheduled pipeline - records which WithdrawToFunding entities are pending processing, in-progress, or complete.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (EntityID, TaskID) (INT composite, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup, PAGE COMPRESSION) |
| **Indexes** | 2 (PK + 1 NCI) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.ScheduledEntityTaskState is the work queue and execution tracker for the "Post Withdrawal to Funding" (PostWTF) scheduled pipeline. When a customer creates a withdrawal-to-funding record (Billing.WithdrawToFunding), a row is inserted here with TaskState=0 (Pending). A background scheduler periodically polls this table, fetches pending entities in batches, and processes them through a post-processing workflow (routing, bank assignment, external notifications).

The table is designed for a generic multi-task architecture (EntityID + TaskID composite PK), but in practice only TaskID=6 is used, pointing all 314,582 rows at the single "Post WTF" task. The CID column allows per-customer deduplication - `InsertScheduledTaskFirstWtf` only creates a new row for a customer if they have no non-completed record (TaskState<>2), enforcing the "first WTF" semantics.

PAGE COMPRESSION is active on the clustered index, reflecting the table's large size and sequential growth pattern.

**314,582 rows** (Jan 2023-present): 277,682 state=0 (pending), 36,900 state=1 (processed/done with ReasonID).

---

## 2. Business Logic

### 2.1 One-Per-Customer Idempotency Guard

**What**: `InsertScheduledTaskFirstWtf` ensures only one non-completed PostWTF task exists per customer at a time.

**Columns/Parameters Involved**: `CID`, `TaskID`, `TaskState`, `EntityID`

**Rules**:
- Before inserting, checks: `NOT EXISTS (WHERE TaskID=6 AND CID=@Cid AND TaskState<>2)`
- If the customer already has a non-completed row (state 0, 1, or 3), no new row is inserted
- Only inserts when the previous task completed (TaskState=2) or no row exists at all
- This prevents duplicate processing of the same customer's WTF entities

**Diagram**:
```
New WithdrawToFunding created (@WtfID, @CID)
        |
        v
InsertScheduledTaskFirstWtf(@WtfID, @CID)
        |
        EXISTS check: TaskID=6 AND CID=@CID AND TaskState<>2?
        |
        +-- NO  (customer has no active task) -> INSERT (EntityID=@WtfID, TaskID=6, TaskState=0)
        +-- YES (customer already has pending/active task) -> no-op (skip insert)
```

### 2.2 Batch Fetch and Processing State Machine

**What**: `GetScheduledTaskWithdrawToFundingEntities` polls for pending tasks, transitions them to in-progress, and returns the batch data for processing.

**Columns/Parameters Involved**: `EntityID`, `TaskID`, `TaskState`, `CID`

**Rules**:
- Fetches: `WHERE TaskID=6 AND TaskState=0` (pending only)
- Joins EntityID to Billing.WithdrawToFunding.ID to get WTF details (CID, FundingTypeID, bank name, country)
- Immediately sets TaskState=3 on fetched rows (locks them against double-processing)
- @MaxEntitiesToFetch=-1 fetches all pending; positive value limits batch size
- State transitions: 0 (Pending) -> 3 (In Progress) -> 1 (Processed/Done) or 2 (Completed)

**State machine**:
```
TaskState=0: Pending
  INSERT via InsertScheduledTaskFirstWtf
        |
        v
TaskState=3: In Progress (fetched by scheduler batch)
  SET by GetScheduledTaskWithdrawToFundingEntities
        |
        v
TaskState=1: Processed (outcome with ReasonID set)
  SET by UpdateScheduledEntityTaskState(@TaskState=1, @ReasonID=1)
  All state=1 rows have ReasonID=1 (success reason)
        |
  OR
        v
TaskState=2: Completed (terminal - allows new task for same customer)
  Referenced as terminal state in InsertScheduledTaskFirstWtf
  No rows currently in state=2 (may be cleaned up)
```

---

## 3. Data Overview

| TaskState | Count | ReasonID | Meaning |
|-----------|-------|----------|---------|
| 0 | 277,682 | NULL | Pending - waiting to be fetched by scheduler. Large backlog may indicate scheduler is processing slowly or has paused. |
| 1 | 36,900 | 1 | Processed with Reason=1. Last state=1 records are from Aug 2023. These represent successfully processed entities. |
| 2 | 0 | - | Completed (terminal state referenced in code). May have been cleaned up or not yet reached. |
| 3 | 0 | - | In-progress (transient state set during batch fetch). None currently in-flight. |

All 314,582 rows use TaskID=6 (PostWTF task). EntityID maps to Billing.WithdrawToFunding.ID.

Note: The lack of state=2 rows and the large pending backlog (277K rows since 2023) suggests this pipeline may no longer be running actively. State=1 rows are from Aug 2023 with no newer completions observed.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntityID | INT | NO | - | CODE-BACKED | The business entity being tracked. Part of the composite PK. In all current data, refers to Billing.WithdrawToFunding.ID (WTF withdrawal record). `GetScheduledTaskWithdrawToFundingEntities` JOINs `Billing.WithdrawToFunding wtf ON BSETS.EntityID=wtf.ID`. No DDL FK constraint. |
| 2 | TaskID | INT | NO | - | CODE-BACKED | The scheduled task type being tracked. Part of the composite PK. All current data = 6 (the "PostWTF" task). The generic PK design supports multiple task types per entity, though only TaskID=6 is active. |
| 3 | TaskState | INT | YES | 0 | CODE-BACKED | Current execution state of this task instance. Default=0 (pending). 0=Pending (waiting to be processed), 1=Processed (done with ReasonID), 2=Completed (terminal - referenced as "done" in idempotency check), 3=In-Progress (transient - set during batch fetch). |
| 4 | ReasonID | INT | YES | - | CODE-BACKED | Outcome reason code set when task is completed. All state=1 rows have ReasonID=1. Passed via `UpdateScheduledEntityTaskState(@ReasonID)`. NULL for pending/in-progress rows. Exact meaning of ReasonID values requires application code review. |
| 5 | Created | DATETIME | YES | getutcdate() | CODE-BACKED | UTC timestamp of the last state change. Defaults to getutcdate() on INSERT. Updated by `UpdateScheduledEntityTaskState` (to GetDate()) and by `GetScheduledTaskWithdrawToFundingEntities` (to GetUTCDate()). Tracks when each state transition occurred. Note: UpdateScheduledEntityTaskState uses GetDate() (local) not GetUTCDate() - minor timezone inconsistency. |
| 6 | CID | INT | YES | - | CODE-BACKED | Customer ID associated with this scheduled task. Used in the idempotency check (`WHERE CID=@Cid AND TaskState<>2`) and indexed via IX_ScheduledEntityTaskState_2 for per-customer state queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EntityID | Billing.WithdrawToFunding | Implicit FK (no DDL constraint) | EntityID = WithdrawToFunding.ID. The only entity type currently tracked. |
| CID | Customer.Customer | Implicit FK (no DDL constraint) | Customer whose WTF entity this task processes. Used for per-customer deduplication. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.InsertScheduledTaskFirstWtf | EntityID, TaskID, TaskState, CID | WRITER (INSERT) | Creates a new pending task row if no active task exists for this customer |
| Billing.GetScheduledTaskWithdrawToFundingEntities | EntityID, TaskID, TaskState | READER + MODIFIER | Fetches pending entities and transitions them to in-progress (TaskState=3) |
| Billing.UpdateScheduledEntityTaskState | EntityID, TaskID, TaskState, ReasonID | MODIFIER | General-purpose state updater - advances task to any state with optional ReasonID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ScheduledEntityTaskState (table)
|- Billing.WithdrawToFunding (implicit - EntityID)
└-- Customer.Customer (implicit - CID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Implicit FK - EntityID references WTF IDs |
| Customer.Customer | Table | Implicit FK - CID references customer records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.InsertScheduledTaskFirstWtf | Stored Procedure | WRITER - creates initial pending rows |
| Billing.GetScheduledTaskWithdrawToFundingEntities | Stored Procedure | READER + MODIFIER - batch fetch and lock |
| Billing.UpdateScheduledEntityTaskState | Stored Procedure | MODIFIER - state transitions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_ScheduledEntityTaskState | CLUSTERED PK | EntityID ASC, TaskID ASC | - | - | Active (PAGE COMPRESSION) |
| IX_ScheduledEntityTaskState_2 | NONCLUSTERED | TaskID ASC, CID ASC, TaskState ASC | - | - | Active |

PAGE COMPRESSION on the clustered PK reduces storage overhead for the large 300K+ row table.
The NCI on (TaskID, CID, TaskState) supports the idempotency check in InsertScheduledTaskFirstWtf: `WHERE TaskID=6 AND CID=@Cid AND TaskState<>2`.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_ScheduledEntityTaskState | PRIMARY KEY CLUSTERED | (EntityID, TaskID) must be unique - one task state per entity per task |
| Df_Billing_ScheduledEntityTaskState_TaskState | DEFAULT | TaskState defaults to 0 (pending) on INSERT |
| Df_Billing_ScheduledEntityTaskState_Created | DEFAULT | Created defaults to getutcdate() on INSERT |

---

## 8. Sample Queries

### 8.1 Get pending task count by task ID

```sql
SELECT
    TaskID,
    TaskState,
    COUNT(*) AS RowCount,
    MIN(Created) AS OldestCreated,
    MAX(Created) AS NewestCreated
FROM [Billing].[ScheduledEntityTaskState] WITH (NOLOCK)
GROUP BY TaskID, TaskState
ORDER BY TaskID, TaskState
```

### 8.2 Check if a customer has an active WTF task

```sql
DECLARE @CID INT = 12345

SELECT
    EntityID,
    TaskID,
    TaskState,
    ReasonID,
    Created
FROM [Billing].[ScheduledEntityTaskState] WITH (NOLOCK)
WHERE CID = @CID
  AND TaskID = 6
ORDER BY Created DESC
```

### 8.3 Find oldest pending tasks (potential processing backlog)

```sql
SELECT TOP 20
    sets.EntityID,
    sets.CID,
    sets.TaskState,
    sets.Created AS PendingSince,
    DATEDIFF(day, sets.Created, GETUTCDATE()) AS DaysWaiting,
    wtf.FundingID,
    wtf.Amount
FROM [Billing].[ScheduledEntityTaskState] sets WITH (NOLOCK)
INNER JOIN [Billing].[WithdrawToFunding] wtf WITH (NOLOCK) ON wtf.ID = sets.EntityID
WHERE sets.TaskID = 6
  AND sets.TaskState = 0
ORDER BY sets.Created ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this table. Comments in the code reference tickets 40729 (Sep 2016) and 51041, 51054, 51056 (Apr 2018) for the original creation.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.6/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.ScheduledEntityTaskState | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ScheduledEntityTaskState.sql*
