# Billing.ScheduledTaskState

> Deposit-level task execution state table - tracks which deposits are pending, in-progress, or completed for each of the 8 post-deposit processing pipelines (AppsFlyer, pixels, RabbitMQ FTD, Mixpanel, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (DepositID, TaskID) (INT composite, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup, PAGE COMPRESSION) |
| **Indexes** | 3 (PK + 2 NCI + 1 filtered NCI + 1 filtered NCCI) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.ScheduledTaskState is the work queue for all post-deposit asynchronous processing. When `Billing.DepositAdd` creates a new deposit, it enqueues the deposit ID for each active task type in this table with TaskState=0 (Pending). Background scheduler workers periodically poll, fetch batches, process them, and mark them done.

Each (DepositID, TaskID) pair represents one unit of work: "run TaskID X for DepositID Y". The 8 task types (1-8) include AppsFlyer attribution, tracking pixels, RabbitMQ FTD notifications, Mixpanel analytics, and monitoring alerts. Together they form the deposit's post-processing fan-out pipeline.

**~43M rows** spread across 8 task types, spanning 2016 to today. Tasks 1, 2, 7, 8 are most active. Tasks 4, 5, 6 have large pending backlogs (7.6M state=0 rows each) from when DepositAdd continued creating rows for them even after the schedulers stopped running.

Heavily indexed: filtered NCI on (TaskID, TaskState) WHERE state=0 for fast pending queue polling; columnstore index on DepositID WHERE state=0 AND TaskID=1 for bulk AppsFlyer scans.

---

## 2. Business Logic

### 2.1 Post-Deposit Enqueue Pattern

**What**: When a deposit is created, a row per active TaskID is inserted to queue post-processing.

**Rules**:
- `Billing.DepositAdd` calls this immediately after deposit creation
- One row inserted per active task: (DepositID, TaskID=1, 0), (DepositID, TaskID=2, 0), etc.
- All rows start with TaskState=0 (Pending), ReasonID=NULL

### 2.2 Scheduler Batch Fetch and Lock

**What**: Schedulers poll for TaskState=0 rows, lock them with TaskState=3, process the batch, then mark done.

**Rules**:
- Pattern in `GetScheduledTask*` procedures:
  1. SELECT TOP (@MaxEntitiesToFetch) WHERE TaskState=0 AND TaskID=X (with JOIN to Billing.Deposit for data)
  2. Immediately UPDATE TaskState=3 (In Progress) via JOIN on temp table (avoids double-pick)
  3. Worker processes the batch externally (sends to AppsFlyer/Mixpanel/etc.)
  4. Worker calls `UpdateScheduledTaskState` or `DeleteScheduledTaskState` with outcome
- State 4 (TaskID=1/AppsFlyer only): 5.6M rows suggest AppsFlyer has an additional "final completed" state
- State 2 (TaskID=3 only): 611K rows suggest a two-phase completion for the RabbitMQ remote variant

**State machine**:
```
TaskState=0: Pending (inserted by DepositAdd)
        |
        v (GetScheduledTask* fetches and locks)
TaskState=3: In Progress (transient)
        |
        +-- Success:
            TaskState=1: Done (most tasks)
            TaskState=2: Second-level done (TaskID=3)
            TaskState=4: Final done (TaskID=1 AppsFlyer)
        |
        +-- Permanent failure after MaxRetries:
            TaskState=??? (not clearly defined in available code)
```

### 2.3 Task Coverage by Active State

Current row distribution by TaskID:

| TaskID | State=0 (Pending) | State=1 (Done) | State=3 (In-Progress) | State=4 | Active? |
|--------|------------------|----------------|----------------------|---------|---------|
| 1 | 2,056,182 | 617 | 82 | 5,620,609 | Yes |
| 2 | 3,201,267 | 4,475,519 | 704 | - | Yes |
| 3 | 2,062,319 | 4,976,768 | 11,937 | - | Yes |
| 4 | 7,662,727 | - | - | - | No (last 2017) |
| 5 | 7,662,727 | - | - | - | No |
| 6 | 7,662,727 | - | - | - | No |
| 7 | - | 7,662,400 | 327 | - | Yes |
| 8 | 3,343,844 | 4,318,643 | 240 | - | Yes |

Tasks 4, 5, 6 show identical 7.6M pending rows - these deposits were enqueued but the schedulers stopped running, creating a permanent backlog.

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositID | INT | NO | - | CODE-BACKED | The deposit being processed. Part of the composite PK. Implicit FK to Billing.Deposit(DepositID). `GetScheduledTask*` procedures JOIN `Billing.Deposit D ON STS.DepositID = D.DepositID` to get deposit data for processing. |
| 2 | TaskID | INT | NO | - | CODE-BACKED | The task type. Part of the composite PK. References Billing.ScheduledTaskConfig(TaskID). Values 1-8. Each TaskID represents a different downstream system: 1=AppsFlyer, 2=RabbitMQ FTD, 3=RabbitMQ FTD remote, 5=Monitor, 7=Deposit processing, 8=Mixpanel (inferred from procedure names). |
| 3 | TaskState | INT | YES | 0 | CODE-BACKED | Execution state. Default=0. 0=Pending (waiting to be fetched), 1=Done/Processed (primary completion), 2=Second-phase done (TaskID=3 only), 3=In-Progress (transient, set during batch fetch), 4=Final done (TaskID=1/AppsFlyer only). |
| 4 | ReasonID | INT | YES | - | CODE-BACKED | Outcome reason code. Set by `UpdateScheduledTaskState`. NULL for pending and in-progress rows. Non-null values indicate specific processing outcomes (success codes, failure reasons). Exact values require application code review. |
| 5 | Created | DATETIME | YES | getutcdate() | CODE-BACKED | UTC timestamp of the last state change. Defaults to getutcdate() on INSERT. Updated by scheduler procedures (using GetDate() - local time inconsistency). For pending rows reflects deposit creation time. For in-progress/done reflects when the state was last changed. |

---

## 4. Relationships

### 4.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.Deposit | Implicit FK (no DDL constraint) | Each row tracks one deposit through one task pipeline |
| TaskID | Billing.ScheduledTaskConfig | Implicit FK (no DDL constraint) | References the task configuration (MaxRetries, batch size) |

### 4.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositAdd | DepositID, TaskID | WRITER (INSERT) | Creates pending rows for all tasks when a deposit is created |
| Billing.GetScheduledTaskDepositEntities | DepositID, TaskID, TaskState | READER + MODIFIER | Fetches pending TaskID=7 entities, locks to state=3 |
| Billing.GetScheduledTaskAppsFlyerEntities | DepositID, TaskID, TaskState | READER + MODIFIER | Fetches pending TaskID=1 entities |
| Billing.GetScheduledTaskPixelEntities | DepositID, TaskID, TaskState | READER + MODIFIER | Fetches pending pixel task entities |
| Billing.GetScheduledTaskMixpanelEventEntities | DepositID, TaskID, TaskState | READER + MODIFIER | Fetches Mixpanel task entities |
| Billing.GetScheduledTaskMonitorProcessingEntities | DepositID, TaskID, TaskState | READER + MODIFIER | Fetches monitor processing entities |
| Billing.GetScheduledTaskRabbitMqFtdEntities | DepositID, TaskID, TaskState | READER + MODIFIER | Fetches RabbitMQ FTD entities |
| Billing.UpdateScheduledTaskState | DepositID, TaskID, TaskState | MODIFIER | General-purpose state updater |
| Billing.DeleteScheduledTaskState | DepositID, TaskID | MODIFIER | Removes completed task rows |

---

## 5. Dependencies

```
Billing.ScheduledTaskState (table)
|- Billing.Deposit (implicit - DepositID)
└-- Billing.ScheduledTaskConfig (implicit - TaskID)
```

---

## 6. Technical Details

### 6.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression |
|-----------|------|-------------|-----------------|--------|-------------|
| PK_Billing_ScheduledTaskState | CLUSTERED PK | DepositID ASC, TaskID ASC | - | - | PAGE |
| IDX_Billing_ScheduledTaskState_TaskID_TaskState_Filtered | NCI FILTERED | TaskID ASC, TaskState ASC | - | WHERE TaskState=0 | PAGE |
| Idx_Billing_ScheduledTaskState_TaskID_TaskState | NCI | TaskID ASC, TaskState ASC | DepositID | - | PAGE |
| IX_FCS_BiliingScheduledTaskState_DepositID | NCI COLUMNSTORE | DepositID | - | WHERE TaskState=0 AND TaskID=1 | COLUMNSTORE |

The filtered NCI on (TaskID, TaskState) WHERE state=0 makes pending queue polling extremely efficient. The full NCI (same keys + DepositID included) handles non-filtered state queries. The COLUMNSTORE index on DepositID for TaskID=1/state=0 enables bulk AppsFlyer scans.

### 6.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_ScheduledTaskState | PRIMARY KEY CLUSTERED | (DepositID, TaskID) must be unique - one task state per deposit per task type |
| Df_Billing_ScheduledTaskState_TaskState | DEFAULT | TaskState defaults to 0 (pending) on INSERT |
| Df_Billing_ScheduledTaskState_Created | DEFAULT | Created defaults to getutcdate() on INSERT |

---

## 7. Sample Queries

### 7.1 Pending task queue sizes per task type

```sql
SELECT
    TaskID,
    SUM(CASE WHEN TaskState = 0 THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN TaskState = 1 THEN 1 ELSE 0 END) AS Done,
    SUM(CASE WHEN TaskState = 3 THEN 1 ELSE 0 END) AS InProgress,
    COUNT(*) AS Total
FROM [Billing].[ScheduledTaskState]
GROUP BY TaskID
ORDER BY TaskID
```

### 7.2 Find recently queued deposits pending a specific task

```sql
DECLARE @TaskID INT = 7
SELECT TOP 20
    sts.DepositID,
    sts.TaskID,
    sts.TaskState,
    sts.Created
FROM [Billing].[ScheduledTaskState] sts
WHERE sts.TaskID = @TaskID
  AND sts.TaskState = 0
ORDER BY sts.Created DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources directly reference this table. Code comments reference ticket 40729 (Sep 2016) for original creation.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.ScheduledTaskState | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ScheduledTaskState.sql*
