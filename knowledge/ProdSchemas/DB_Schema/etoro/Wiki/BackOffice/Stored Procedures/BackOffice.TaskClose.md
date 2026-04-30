# BackOffice.TaskClose

> Closes a back-office CRM task by atomically deleting it from BackOffice.Task and archiving the full record (including close comment and closing manager) to History.Task within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TaskID - the task to close |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.TaskClose completes the lifecycle of a legacy back-office CRM task. When a manager finishes the follow-up action (a sales call, a support resolution, a risk review, or a withdrawal action), they close the task with a comment explaining what was done. The procedure moves the completed task from the active BackOffice.Task table into the History.Task archive, preserving the full record for audit and reporting.

The closure pattern uses DELETE ... OUTPUT to capture the pre-delete row in a table variable, then inserts that captured snapshot into History.Task along with close metadata (@Comment, @ManagerID as ClosedBy, GETDATE() as ClosedOn). This is a robust atomic move - if either the DELETE or the INSERT fails, the entire transaction rolls back.

**This feature is retired.** BackOffice.Task has no new records since 2013. This procedure is no longer called in production.

---

## 2. Business Logic

### 2.1 Atomic Delete-and-Archive Pattern

**What**: The task is deleted from the active table and immediately inserted into the history table using the OUTPUT clause to capture the deleted row.

**Columns/Parameters Involved**: `@TaskID`, `@ManagerID`, `@Comment`, all BackOffice.Task columns

**Rules**:
- BEGIN TRANSACTION
- DELETE FROM BackOffice.Task ... OUTPUT DELETED.* + GETDATE() as ClosedOn + @Comment as CloseComment + @ManagerID as ClosedBy INTO @ClosedTask (table variable)
- If @@Error != 0: ROLLBACK, RAISERROR(60000,16,1,'BackOffice.TaskClose',@LocalError), RETURN 60000
- INSERT INTO History.Task (...) SELECT ... FROM @ClosedTask
- If @@Error != 0: ROLLBACK, RAISERROR(60000,16,1,'BackOffice.TaskClose',@LocalError), RETURN 60000
- COMMIT TRANSACTION
- RETURN 0

**Task archival column mapping**:

| History.Task Column | Source |
|--------------------|--------|
| TaskID | DELETED.TaskID (original ID preserved) |
| ManagerID | DELETED.ManagerID (last assigned manager) |
| CID | DELETED.CID |
| TaskTypeID | DELETED.TaskTypeID |
| StartDateTime | DELETED.StartDateTime |
| EndDateTime | DELETED.EndDateTime |
| OpenComment | DELETED.OpenComment (original open notes) |
| ClosedOn | GETDATE() (server timestamp at close) |
| CloseComment | @Comment (closing notes from closing manager) |
| OpenedBy | DELETED.OpenedBy |
| OpenedOn | DELETED.OpenedOn |
| ClosedBy | @ManagerID (the manager who closed the task) |

### 2.2 Transaction Safety

**What**: Ensures the delete and archive are always atomic - no task is lost or duplicated.

**Rules**:
- If DELETE succeeds but INSERT into History.Task fails: transaction ROLLS BACK - task remains in BackOffice.Task
- If @TaskID does not exist: DELETE affects 0 rows, table variable @ClosedTask is empty, History INSERT inserts 0 rows - silent no-op with RETURN 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TaskID | INTEGER | NO | - | VERIFIED | The task to close. Identifies the row to DELETE from BackOffice.Task and archive to History.Task. If not found: silent no-op (0-row delete, 0-row insert, RETURN 0). |
| 2 | @ManagerID | INTEGER | NO | - | VERIFIED | The manager closing the task. Written to History.Task.ClosedBy. May be the same as the currently assigned ManagerID (task completer) or a supervisor closing on behalf of the assigned manager. |
| 3 | @Comment | VARCHAR(MAX) | NO | - | VERIFIED | The closing notes explaining what action was taken. Written to History.Task.CloseComment. Complements the original OpenComment preserved from BackOffice.Task. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TaskID | BackOffice.Task | WRITER (DELETE) | Removes the active task from the open task queue |
| All columns | History.Task | WRITER (INSERT) | Archives the full closed task record including close metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice CRM | - | Caller | Called when a manager completes a customer follow-up task (feature retired 2013) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.TaskClose (procedure)
├── BackOffice.Task (table) - DELETE source
└── History.Task (table) - INSERT archive target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Task | Table | DELETE WHERE TaskID=@TaskID; OUTPUT clause captures pre-delete row into @ClosedTask table variable |
| History.Task | Table | INSERT of the captured @ClosedTask snapshot plus close metadata (ClosedOn, CloseComment, ClosedBy) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TaskAdd | Stored Procedure | Creates tasks that this procedure closes |
| BackOffice.TaskAssign | Stored Procedure | Reassigns tasks before closure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 OUTPUT Clause Pattern

The procedure uses the SQL Server OUTPUT clause to capture deleted rows into a table variable (`@ClosedTask`) without requiring a SELECT before the DELETE. This is more efficient and race-condition-safe than a SELECT-then-DELETE approach: the captured row is guaranteed to be the exact row that was deleted, even in concurrent environments.

---

## 8. Sample Queries

### 8.1 Close a task (legacy - for reference only)
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.TaskClose
    @TaskID    = 5000,
    @ManagerID = 77,
    @Comment   = 'Called customer - issue resolved. Account upgraded per request.'
SELECT @Err AS ErrorCode
```

### 8.2 View closed tasks in history (historical data)
```sql
SELECT TOP 100
    h.TaskID, h.CID, h.TaskTypeID,
    h.OpenedBy, h.OpenedOn, h.OpenComment,
    h.ClosedBy, h.ClosedOn, h.CloseComment
FROM History.Task h WITH (NOLOCK)
ORDER BY h.ClosedOn DESC
```

### 8.3 Find tasks that were closed by a specific manager
```sql
SELECT TaskID, CID, TaskTypeID, ClosedOn, CloseComment
FROM History.Task WITH (NOLOCK)
WHERE ClosedBy = 77
ORDER BY ClosedOn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.TaskClose | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.TaskClose.sql*
