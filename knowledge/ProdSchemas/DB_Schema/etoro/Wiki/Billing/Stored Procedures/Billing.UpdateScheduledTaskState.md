# Billing.UpdateScheduledTaskState

> Updates the processing state of a deposit's post-deposit task record, recording the outcome (done/failed/in-progress) and optional reason after a scheduler worker completes or fails processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID + @TaskID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

After `Billing.DepositAdd` creates a new deposit, it enqueues the deposit for each active post-deposit task type in `Billing.ScheduledTaskState` with `TaskState=0` (Pending). Background scheduler workers poll for pending tasks, lock them by setting `TaskState=3` (In Progress), process them externally (sending data to AppsFlyer, Mixpanel, tracking pixels, RabbitMQ, etc.), and then record the outcome.

`Billing.UpdateScheduledTaskState` is the write-back procedure for recording a task's outcome. It sets the `TaskState` to the result code (typically 1=Done, 2=Secondary Done for some tasks, 4=Final Done for AppsFlyer), optionally records a `ReasonID` (e.g., for failure reasons), and updates the `Created` timestamp to `GETDATE()` as a "last modified" marker.

The procedure is the standard completion path for scheduler workers finishing a task unit. It is called by the AnalyticsService user (as seen in permission grants) and likely other scheduler services for the 8 task types.

Created by Geri Reshef, 07/09/2016, ticket 40729 (DB - New table and SP for Billing ScheduledTask).

---

## 2. Business Logic

### 2.1 Task State Transition (Outcome Recording)

**What**: Records the processing outcome for a single (DepositID, TaskID) work unit after a scheduler finishes.

**Columns/Parameters Involved**: `@DepositID`, `@TaskID`, `@TaskState`, `@ReasonID`

**Rules**:
- Targets exactly one row: `WHERE DepositID = @DepositID AND TaskID = @TaskID`
- Sets `TaskState` to the outcome value:
  - 0 = Pending (reset to re-queue, less common)
  - 1 = Done (most task types on success)
  - 2 = Secondary Done (used by TaskID=3, RabbitMQ remote variant - two-phase completion)
  - 3 = In Progress (typically set by the fetch procedure, not this one)
  - 4 = Final Done (used by TaskID=1, AppsFlyer - 5.6M rows at this state)
- Sets `ReasonID` to `@ReasonID` (NULL by default) - used for failure/skip reasons
- Updates `Created` to `GETDATE()` - acts as the "last modified" timestamp despite the column name
- If no matching row exists, UPDATE silently affects 0 rows

**Diagram**:
```
TaskState=3: In Progress (set by GetScheduledTask* fetch)
  |
  Scheduler processes task (external service call)
  |
  v (EXEC UpdateScheduledTaskState with outcome)
TaskState=1: Done           [most task types, success]
TaskState=2: Secondary Done [TaskID=3, RabbitMQ second phase]
TaskState=4: Final Done     [TaskID=1, AppsFlyer final complete]
TaskState=0: Re-queued      [reset to pending on retry]
```

### 2.2 Task Types and Their Success States

**What**: The 8 scheduled task types have different success state values based on their processing model.

**Rules**:

| TaskID | Description | Success TaskState |
|--------|-------------|------------------|
| 1 | AppsFlyer attribution | 4 (Final Done) |
| 2 | Tracking pixels | 1 (Done) |
| 3 | RabbitMQ FTD notification | 1 or 2 (two-phase) |
| 4 | Mixpanel analytics (inactive since 2017) | 1 |
| 5 | (inactive) | 1 |
| 6 | (inactive) | 1 |
| 7 | Monitoring alerts | 1 (Done) |
| 8 | (active) | 1 (Done) |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | FK to `Billing.Deposit.DepositID`. Together with `@TaskID`, uniquely identifies the task record to update. Part of the composite PK of `Billing.ScheduledTaskState`. |
| 2 | @TaskID | INT | NO | - | CODE-BACKED | The post-deposit task type being reported: 1=AppsFlyer, 2=Pixels, 3=RabbitMQ FTD, 7=Monitoring, 8=active task. Together with `@DepositID`, uniquely identifies the row. |
| 3 | @TaskState | INT | NO | - | CODE-BACKED | The new task state to record: 0=Pending (re-queue), 1=Done, 2=Secondary Done (TaskID=3 two-phase), 3=In Progress, 4=Final Done (TaskID=1 AppsFlyer). Overwrites the current state unconditionally. |
| 4 | @ReasonID | INT | YES | NULL | CODE-BACKED | Optional reason code for the state transition. Used to explain failures or special skip conditions. NULL for normal completions. Lookup table not identified in available code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID + @TaskID | Billing.ScheduledTaskState | UPDATE | Updates the task state record for this deposit+task combination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AnalyticsServiceUser (permission grant) | - | GRANT EXECUTE | Analytics/scheduler service records task completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateScheduledTaskState (procedure)
└── Billing.ScheduledTaskState (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | UPDATE - sets TaskState, ReasonID, Created for the matching (DepositID, TaskID) row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AnalyticsService (application) | Application | Calls after processing analytics tasks (AppsFlyer, Mixpanel, pixels) to record completion |
| Scheduler workers (application) | Application | Called by all active post-deposit task schedulers (TaskID 1-3, 7, 8) after processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None explicit | - | No validation of TaskState value range; no existence check. UPDATE silently affects 0 rows if (DepositID, TaskID) not found. |

---

## 8. Sample Queries

### 8.1 Mark a task as completed (AppsFlyer final done)
```sql
EXEC Billing.UpdateScheduledTaskState
    @DepositID = 123456,
    @TaskID    = 1,      -- AppsFlyer
    @TaskState = 4,      -- Final Done
    @ReasonID  = NULL;
```

### 8.2 Mark a task as done with a reason (failure or skip)
```sql
EXEC Billing.UpdateScheduledTaskState
    @DepositID = 123456,
    @TaskID    = 2,      -- Pixels
    @TaskState = 1,      -- Done
    @ReasonID  = 5;      -- some skip/failure reason
```

### 8.3 Check task state for a specific deposit across all task types
```sql
SELECT
    sts.DepositID,
    sts.TaskID,
    sts.TaskState,
    CASE sts.TaskState
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Done'
        WHEN 2 THEN 'Secondary Done'
        WHEN 3 THEN 'In Progress'
        WHEN 4 THEN 'Final Done'
        ELSE 'Unknown'
    END         AS TaskStateLabel,
    sts.ReasonID,
    sts.Created AS LastModified
FROM Billing.ScheduledTaskState sts WITH (NOLOCK)
WHERE sts.DepositID = 123456
ORDER BY sts.TaskID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateScheduledTaskState | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateScheduledTaskState.sql*
