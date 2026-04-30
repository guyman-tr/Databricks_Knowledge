# Billing.UpdateScheduledTask

> Bulk-transitions a list of deposit scheduled tasks to TaskState=3 (In-Progress) using a table-valued parameter, atomically claiming a batch of post-deposit tasks for processing by a scheduler worker.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TaskID + @DepositList (TVP) - targets Billing.ScheduledTaskState |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateScheduledTask` is the bulk "claim" step in the post-deposit asynchronous processing pipeline. When a scheduler worker fetches a batch of pending tasks from `Billing.ScheduledTaskState` (TaskState=0), it needs to immediately lock them as In-Progress (TaskState=3) to prevent other workers from picking up the same deposits. This procedure performs that bulk claim atomically using a table-valued parameter (`@DepositList`) to update all selected deposits at once.

This is the bulk equivalent of the per-deposit `UPDATE ... OUTPUT` pattern used by `Billing.UpdateAppsFlyerDepositData`. While that SP atomically claims one deposit at a time, `UpdateScheduledTask` claims a whole batch in one statement using a JOIN to the TVP.

The procedure always sets `TaskState=3` (hardcoded) - there is no parameterizable target state. This is specifically the "mark as In-Progress" step. After worker completion, the tasks are marked done via `Billing.UpdateScheduledTaskState` or deleted via `Billing.DeleteScheduledTaskState`.

Created March 2021 by Shay O. No explicit EXECUTE grant found in UsersPermissions - called via schema-level permissions.

**Post-deposit pipeline**:
- 8 task types (TaskID 1-8): AppsFlyer, tracking pixels, RabbitMQ FTD notifications, Mixpanel analytics, monitoring alerts
- Workers: SELECT batch (TaskState=0) -> `UpdateScheduledTask` (TaskState=3) -> process -> `UpdateScheduledTaskState` (TaskState=1/2/4)

---

## 2. Business Logic

### 2.1 Bulk Task Batch Claim

**What**: Claims a batch of deposit tasks for a specific task type, preventing duplicate processing by transitioning them to In-Progress before the worker begins external API calls.

**Columns/Parameters Involved**: `@TaskID`, `@DepositList` (TVP), `Billing.ScheduledTaskState.TaskState`, `Billing.ScheduledTaskState.Created`

**Rules**:
- `UPDATE STS SET TaskState=3, Created=GETDATE() FROM Billing.ScheduledTaskState STS INNER JOIN @DepositList PDT ON STS.DepositID = PDT.ID WHERE STS.TaskID = @TaskID`
- `TaskState=3` is hardcoded - this SP only transitions tasks TO In-Progress
- The JOIN to the TVP `@DepositList` (of type `[BackOffice].[IDs]`) filters to exactly the deposits the caller has selected
- `TaskID = @TaskID` filter ensures only the specified task type is updated (e.g., only AppsFlyer tasks, not all tasks for these deposits)
- `Created = GETDATE()` (local time): records when the batch was claimed
- Deposits not in `@DepositList` OR with a different TaskID are unaffected
- Thread-safe: the INNER JOIN to the TVP ensures only the caller's selected batch is updated; no other worker can claim the same deposits (assuming they already selected these DepositIDs)

**Claim sequence**:
```
Scheduler worker (e.g., Analytics service for TaskID=1 AppsFlyer):

  Step 1: SELECT batch
    SELECT TOP N DepositID FROM Billing.ScheduledTaskState
    WHERE TaskID=1 AND TaskState=0
    -> Returns: DepositIDs [101, 102, 103, ...]

  Step 2: Bulk claim (this SP)
    EXEC Billing.UpdateScheduledTask
         @TaskID=1,
         @DepositList=[TVP with DepositIDs 101, 102, 103, ...]
    -> UPDATE SET TaskState=3 WHERE TaskID=1 AND DepositID IN (101,102,103)
    -> Creates locked in-flight batch

  Step 3: Process (external API calls)
    Send deposits to AppsFlyer

  Step 4: Mark done
    EXEC Billing.UpdateScheduledTaskState (TaskState=1/4 per deposit)
    OR
    EXEC Billing.DeleteScheduledTaskState
```

**TVP type `[BackOffice].[IDs]`**:
- Table type with a single INT column `ID`
- Caller populates it with the DepositIDs from their SELECT batch
- Passed as READONLY parameter to the procedure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TaskID | INT | NO | - | CODE-BACKED | The scheduled task type to claim. Matches `Billing.ScheduledTaskState.TaskID`. Examples: 1=AppsFlyer, 2=TrackingPixel, 3=RabbitMQ-FTD, etc. Only tasks with this TaskID are updated. |
| 2 | @DepositList | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the DepositIDs to claim. Each row has a single INT `ID` column. The UPDATE JOINs `Billing.ScheduledTaskState` to this TVP on `DepositID = ID`. Only deposits in this list (combined with @TaskID filter) are transitioned to TaskState=3. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN ON DepositID | Billing.ScheduledTaskState | UPDATE (batch JOIN to TVP) | Bulk-transitions matched tasks to TaskState=3 (In-Progress) |
| @DepositList type | BackOffice.IDs | User Defined Table Type | TVP type definition used to pass the batch of DepositIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler workers | @TaskID, @DepositList | EXEC | Called after selecting a batch of pending tasks to lock them as In-Progress before external processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateScheduledTask (procedure)
|- Billing.ScheduledTaskState (table) - UPDATE (batch)
`- BackOffice.IDs (user defined table type) - TVP parameter type

Post-deposit pipeline context:
  Billing.ScheduledTaskState (queue) ->
  Billing.UpdateScheduledTask (bulk claim to In-Progress) ->
  [external processing] ->
  Billing.UpdateScheduledTaskState / DeleteScheduledTaskState (completion)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | UPDATE - sets TaskState=3, Created=GETDATE() WHERE TaskID=@TaskID AND DepositID IN @DepositList |
| BackOffice.IDs | User Defined Table Type | TVP parameter type - defines the structure of @DepositList (single INT column `ID`) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by post-deposit scheduler workers (no explicit EXECUTE grant in UsersPermissions). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Key indexes on `Billing.ScheduledTaskState`:
- CLUSTERED PK on `(DepositID, TaskID)` - UPDATE uses this with the JOIN
- FILTERED NCI on `(TaskID, TaskState) WHERE TaskState=0` (on clustered PK) - used by the preceding SELECT step
- For bulk updates, the JOIN to the TVP processes each row in the TVP against the clustered index

### 7.2 Constraints

N/A for stored procedure. Note: The `Created` field is updated to `GETDATE()` (server local time, not GETUTCDATE()). All rows transitioned by this call share the same timestamp - the batch claim time. This timestamp differentiates "when was this batch claimed" from the original `Created` time written during task insertion.

---

## 8. Sample Queries

### 8.1 Typical scheduler pattern (SELECT then bulk claim)
```sql
-- Step 1: Select pending tasks
DECLARE @Batch TABLE (ID INT);
INSERT INTO @Batch
SELECT TOP 100 DepositID
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE TaskID = 1 AND TaskState = 0
ORDER BY DepositID;

-- Step 2: Bulk claim (cast @Batch to BackOffice.IDs TVP via application code)
-- EXEC Billing.UpdateScheduledTask @TaskID = 1, @DepositList = @Batch;
```

### 8.2 Check in-progress tasks for a specific task type
```sql
SELECT COUNT(*) AS InProgressCount
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE TaskID = 1 AND TaskState = 3;
```

### 8.3 Find stuck in-progress tasks (older than 1 hour)
```sql
SELECT DepositID, TaskID, TaskState, Created,
       DATEDIFF(MINUTE, Created, GETDATE()) AS MinutesInProgress
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE TaskState = 3
  AND Created < DATEADD(HOUR, -1, GETDATE())
ORDER BY Created;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (UpdateScheduledTaskState, UpdateAppsFlyerDepositData ecosystem) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateScheduledTask | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateScheduledTask.sql*
