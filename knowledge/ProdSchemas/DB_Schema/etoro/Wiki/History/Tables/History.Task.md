# History.Task

> Archive of closed back-office tasks - when a manager closes a customer follow-up task in BackOffice.Task, it is moved here via DELETE...OUTPUT INTO, preserving the full task lifecycle record.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | TaskID (INT, CLUSTERED PK) |
| **Partition** | No - stored on [HISTORY] filegroup |
| **Indexes** | 4 active (CLUSTERED PK on TaskID, NC on CID, NC on ManagerID, NC on TaskTypeID) |

---

## 1. Business Meaning

History.Task is the closed-task archive of eToro's back-office task management system. In this system, back-office managers (BackOffice.Manager) create tasks in BackOffice.Task to track customer follow-ups, compliance checks, or operational actions. Tasks have a scheduled window (StartDateTime to EndDateTime), can be linked to a customer (CID), and are assigned to a responsible manager.

When a manager closes a task via BackOffice.TaskClose, the record is atomically deleted from BackOffice.Task and inserted into History.Task with the closing details (who closed it, when, and a comment). This table is the permanent record of all completed back-office workflows.

The table contains 5,703 rows covering 2008-2011, indicating the task management system was active in eToro's early years. The current absence of recent data suggests the system is either retired or that new task records are managed in a separate system, with this table serving as a historical reference.

---

## 2. Business Logic

### 2.1 Task Archive Pattern (DELETE...OUTPUT INTO)

**What**: BackOffice.TaskClose atomically moves a task from the live BackOffice.Task table to this archive in a single transaction, ensuring no task is ever lost or duplicated.

**Columns/Parameters Involved**: `TaskID`, `ManagerID`, `CID`, `TaskTypeID`, `StartDateTime`, `EndDateTime`, `OpenComment`, `ClosedOn`, `CloseComment`, `OpenedBy`, `OpenedOn`, `ClosedBy`

**Rules**:
- The close operation: `DELETE FROM BackOffice.Task ... OUTPUT DELETED.* INTO @ClosedTask`, then `INSERT INTO History.Task SELECT * FROM @ClosedTask`
- Both steps are wrapped in a single transaction - if either fails, the entire operation rolls back (task stays in BackOffice.Task)
- ClosedOn is set to `GETDATE()` (not a column default) at the time of deletion
- CloseComment and ClosedBy are provided by the calling manager - they are NOT copied from BackOffice.Task (those fields would be empty/0 on open tasks)
- TaskID is preserved from BackOffice.Task - no re-keying occurs

**Diagram**:
```
Manager closes task (BackOffice.TaskClose @TaskID, @ManagerID, @Comment):

[BackOffice.Task]                [History.Task]
TaskID=5 (open task)  --DELETE-->  TaskID=5 (archived)
ManagerID, CID,                    + ClosedOn = GETDATE()
StartDateTime,                     + CloseComment = @Comment
EndDateTime,                       + ClosedBy = @ManagerID
OpenComment,
OpenedBy, OpenedOn

(Atomic within one transaction - both succeed or both fail)
```

### 2.2 Task Types

**What**: TaskTypeID categorizes the nature of the task, distinguishing between different back-office workflows.

**Columns/Parameters Involved**: `TaskTypeID`

**Rules**:
- 3 distinct values observed in data: 1 (5,659 rows - 99.2%), 2 (24 rows), 3 (20 rows)
- No TaskType lookup table found in the SSDT repo - type meanings are application-defined
- TaskTypeID=1 is overwhelmingly dominant, likely representing the standard customer follow-up task type
- No FK constraint to a lookup table is defined (unlike CID and ManagerID which have FKs)

---

## 3. Data Overview

| TaskID | ManagerID | CID | TaskTypeID | StartDateTime | EndDateTime | OpenComment | CloseComment | Meaning |
|---|---|---|---|---|---|---|---|---|
| 11472 | 27 | 967448 | 1 | 2010-11-29 | 2010-12-06 | check | 16+ | A 7-day customer review task assigned to manager 27. The comment "16+" suggests age verification check - common compliance task for early eToro customers. Closed 4 months later. |
| 11469 | 27 | 757097 | 1 | 2010-11-15 | 2010-11-22 | deposit wire | uilio | A wire transfer follow-up task with a 7-day window. OpenComment indicates the manager was tracking a pending wire deposit for this customer. |
| 11468 | 27 | 926179 | 1 | 2010-11-10 | 2010-11-17 | check sale | kyu | A sales verification task. The "check sale" comment suggests the manager was verifying a transaction or sale-related activity for this customer. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TaskID | INT | NO | - | CODE-BACKED | Primary key, preserved from BackOffice.Task. Uniquely identifies the task. CLUSTERED index with FILLFACTOR=90 for balanced insert/query performance on the archive. |
| 2 | ManagerID | INT | NO | - | CODE-BACKED | The manager responsible for the task. FK to BackOffice.Manager(ManagerID). This is the assigned/owning manager (not necessarily the one who closed it). NC index HTSK_MANAGER supports lookups by manager. |
| 3 | CID | INT | YES | NULL | CODE-BACKED | Customer identifier linked to this task. FK to BackOffice.Customer(CID). NULL for tasks not tied to a specific customer (e.g., operational or system tasks). NC index HTSK_CID supports customer task history lookup. |
| 4 | TaskTypeID | INT | NO | - | CODE-BACKED | Category of the task. Values observed: 1 (standard follow-up, 99.2%), 2, 3. No lookup table found in SSDT - type meanings are defined in application code. NC index HTSK_TASKTYPE supports filtering by task category. |
| 5 | StartDateTime | DATETIME | NO | - | CODE-BACKED | The scheduled start of the task window - when the manager was expected to begin the task. Preserved from BackOffice.Task at time of close. |
| 6 | EndDateTime | DATETIME | NO | - | CODE-BACKED | The scheduled end/deadline of the task window. Preserved from BackOffice.Task at time of close. Typically set 7 days after StartDateTime in observed data. |
| 7 | OpenComment | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Free-text note entered when the task was opened in BackOffice.Task. Describes the reason or context for creating the task (e.g., "check", "deposit wire", "check sale"). Nullable - some tasks may have been opened without a comment. |
| 8 | ClosedOn | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the task was closed. Set to `GETDATE()` by BackOffice.TaskClose at the moment of deletion from BackOffice.Task - not a column default, always provided by the procedure. |
| 9 | CloseComment | VARCHAR(MAX) | NO | - | CODE-BACKED | Free-text note entered by the closing manager explaining the resolution (e.g., "16+", "kyu"). Provided as @Comment parameter to BackOffice.TaskClose. NOT NULL - a close comment is required by the procedure. |
| 10 | OpenedOn | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the task was originally created in BackOffice.Task. Preserved from BackOffice.Task at close time. |
| 11 | OpenedBy | INT | NO | - | CODE-BACKED | Manager ID who created the task. FK to BackOffice.Manager(ManagerID) via FK_BMNG_HTSKO. May differ from ManagerID (assigned manager) - tasks can be created by one manager and assigned to another. |
| 12 | ClosedBy | INT | NO | - | CODE-BACKED | Manager ID who closed the task. FK to BackOffice.Manager(ManagerID) via FK_BMNG_HTSKC. Provided as @ManagerID parameter to BackOffice.TaskClose. May differ from OpenedBy and ManagerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | FK (FK_BCST_HTSK) | The customer linked to this task. Nullable - not all tasks are customer-specific. |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HTSK) | The assigned/responsible manager for the task. |
| OpenedBy | BackOffice.Manager | FK (FK_BMNG_HTSKO) | The manager who created the task. |
| ClosedBy | BackOffice.Manager | FK (FK_BMNG_HTSKC) | The manager who closed and archived the task. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.TaskClose | TaskID | Writer (INSERT via DELETE...OUTPUT) | Sole writer. Moves closed tasks from BackOffice.Task to this archive atomically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Task (table)
  (leaf - no code-level dependencies; FKs to BackOffice.Customer and BackOffice.Manager)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK target for CID (FK_BCST_HTSK) |
| BackOffice.Manager | Table | FK target for ManagerID, OpenedBy, ClosedBy (FK_BMNG_HTSK, FK_BMNG_HTSKO, FK_BMNG_HTSKC) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TaskClose | Stored Procedure | WRITER - sole inserter of closed tasks into this archive |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HTSK | CLUSTERED PK | TaskID ASC | - | - | Active (FILLFACTOR=90) |
| HTSK_CID | NONCLUSTERED | CID ASC | - | - | Active (FILLFACTOR=90) |
| HTSK_MANAGER | NONCLUSTERED | ManagerID ASC | - | - | Active (FILLFACTOR=90) |
| HTSK_TASKTYPE | NONCLUSTERED | TaskTypeID ASC | - | - | Active (FILLFACTOR=90) |

Note: All indexes use FILLFACTOR=90 (10% free space per page) to accommodate potential inserts between existing key values.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BCST_HTSK | FOREIGN KEY | CID -> BackOffice.Customer(CID) - enforces customer existence |
| FK_BMNG_HTSK | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) - enforces assigned manager existence |
| FK_BMNG_HTSKO | FOREIGN KEY | OpenedBy -> BackOffice.Manager(ManagerID) - enforces opening manager existence |
| FK_BMNG_HTSKC | FOREIGN KEY | ClosedBy -> BackOffice.Manager(ManagerID) - enforces closing manager existence |

---

## 8. Sample Queries

### 8.1 Retrieve full task history for a customer
```sql
SELECT
    t.TaskID,
    t.TaskTypeID,
    t.StartDateTime,
    t.EndDateTime,
    t.OpenComment,
    t.ClosedOn,
    t.CloseComment,
    t.OpenedBy,
    t.ClosedBy
FROM History.Task t WITH (NOLOCK)
WHERE t.CID = 967448
ORDER BY t.OpenedOn;
```

### 8.2 Tasks closed by a specific manager with resolution comments
```sql
SELECT
    t.TaskID,
    t.CID,
    t.TaskTypeID,
    t.OpenComment,
    t.ClosedOn,
    t.CloseComment
FROM History.Task t WITH (NOLOCK)
WHERE t.ClosedBy = 27
ORDER BY t.ClosedOn DESC;
```

### 8.3 Task duration analysis (time from open to close)
```sql
SELECT
    t.TaskTypeID,
    COUNT(*) AS TotalTasks,
    AVG(DATEDIFF(DAY, t.OpenedOn, t.ClosedOn)) AS AvgDaysToClose,
    MAX(DATEDIFF(DAY, t.OpenedOn, t.ClosedOn)) AS MaxDaysToClose
FROM History.Task t WITH (NOLOCK)
GROUP BY t.TaskTypeID
ORDER BY t.TaskTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (BackOffice.TaskClose) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Task | Type: Table | Source: etoro/etoro/History/Tables/History.Task.sql*
