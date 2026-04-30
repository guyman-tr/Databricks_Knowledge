# BackOffice.Task

> Legacy back-office task management table tracking CRM tasks (Sales, Support, Risk, Withdraw) assigned to managers for follow-up on customer accounts. No new data since 2013.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BTask: TaskID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

`BackOffice.Task` was the back-office CRM task system, used to create and track follow-up actions that managers needed to perform on customer accounts. When a customer required follow-up (a sales call, a support inquiry, a risk review, or a withdrawal issue), a task was created and assigned to a manager with a start/end window and notes.

The table is a legacy artifact. Live data shows a maximum TaskID of ~11,496 with the latest entry dated 2013. The task management function has since been replaced by other tooling (likely the Zendesk/ticketing integration based on `ZendeskDocuments` presence in this schema). The schema structure - foreign keys to `BackOffice.Customer`, `BackOffice.Manager`, and `Dictionary.TaskType` - reflects a fully-featured mini-CRM that was once actively used. The three NC indexes (CID, ManagerID, TaskTypeID) confirm it was queried by all three dimensions in its operational lifetime.

SPs: `TaskAdd` (creates tasks), `TaskAssign` (reassigns manager), `TaskClose` (closes with end datetime).

---

## 2. Business Logic

### 2.1 Task Lifecycle

**What**: Tasks are created, assigned, and closed as back-office managers work through customer follow-up queues.

**Columns/Parameters Involved**: `TaskID`, `CID`, `TaskTypeID`, `ManagerID`, `StartDateTime`, `EndDateTime`, `OpenComment`, `OpenedOn`, `OpenedBy`

**Rules**:
- A task is created by a manager (`OpenedBy`) for a customer (`CID`) with a type (`TaskTypeID`).
- `StartDateTime` and `EndDateTime` define the due window for the task.
- `ManagerID` is the currently assigned manager; can change via `TaskAssign`.
- `EndDateTime` NULL = task still open; non-NULL = task has been closed.
- `OpenComment` stores the reason the task was created (free text notes from opening manager).
- `OpenedOn` is the creation timestamp.

**Task Type Values** (from Dictionary.TaskType live data):

| TaskTypeID | Name |
|-----------|------|
| 1 | Sales |
| 2 | Support |
| 3 | Risk |
| 4 | Withdraw |

### 2.2 Legacy Status

**What**: Table is no longer written to (last data from 2013).

**Rules**:
- Maximum TaskID ~11,496; all entries dated 2013 or earlier.
- Legacy CRM replacement - current customer task management uses Zendesk/other systems.
- SPs (TaskAdd, TaskAssign, TaskClose) still exist in codebase but are no longer called in production.

---

## 3. Data Overview

| Column | Observed Values |
|--------|----------------|
| Max TaskID | ~11,496 |
| Latest entry | 2013 |
| TaskType distribution | 1=Sales (dominant), 2=Support, 3=Risk, 4=Withdraw |
| Row status | Legacy - no new data since 2013 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TaskID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each back-office task. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer this task relates to. FK to BackOffice.Customer.CID. Indexed (NC_BTask_CID) for per-customer task lookups. |
| 3 | TaskTypeID | int | NO | - | CODE-BACKED | FK to Dictionary.TaskType. 1=Sales, 2=Support, 3=Risk, 4=Withdraw. Classifies what kind of follow-up action is needed. Indexed (NC_BTask_TaskTypeID) for type-based filtering. |
| 4 | ManagerID | int | NO | - | CODE-BACKED | Currently assigned manager. FK to BackOffice.Manager.ManagerID. Can be changed by TaskAssign. Indexed (NC_BTask_ManagerID) for manager workload views. |
| 5 | StartDateTime | datetime | YES | - | CODE-BACKED | The start of the task's due window. Tasks should be actioned after this time. |
| 6 | EndDateTime | datetime | YES | - | CODE-BACKED | The end of the task's due window, or the datetime it was closed. NULL = task is still open. |
| 7 | OpenComment | varchar(500) | YES | - | CODE-BACKED | Free-text notes entered by the opening manager explaining why the task was created. |
| 8 | OpenedOn | datetime | YES | - | CODE-BACKED | Timestamp when the task was created. |
| 9 | OpenedBy | int | YES | - | CODE-BACKED | FK to BackOffice.Manager.ManagerID. The manager who created this task (may differ from the assigned ManagerID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer.CID | FK (FK_BC_BTask) | The customer this task is for |
| TaskTypeID | Dictionary.TaskType.TaskTypeID | FK (FK_DT_BTask) | Type of follow-up action |
| ManagerID | BackOffice.Manager.ManagerID | FK (FK_BM_BTask) | Currently assigned manager |
| OpenedBy | BackOffice.Manager.ManagerID | FK (FK_BM2_BTask) | Manager who created the task |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.TaskAdd | INSERT | Writer | Creates new task records |
| BackOffice.TaskAssign | UPDATE | Writer | Reassigns ManagerID on existing tasks |
| BackOffice.TaskClose | UPDATE | Writer | Sets EndDateTime to close a task |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Task (table)
+-- BackOffice.Customer (table) [FK_BC_BTask]
+-- BackOffice.Manager (table) [FK_BM_BTask, FK_BM2_BTask]
+-- Dictionary.TaskType (table) [FK_DT_BTask]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK: CID must be a valid customer |
| BackOffice.Manager | Table | FK: ManagerID and OpenedBy must be valid managers |
| Dictionary.TaskType | Table | FK: TaskTypeID must be a valid task type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TaskAdd | Stored Procedure | Creates task records |
| BackOffice.TaskAssign | Stored Procedure | Reassigns task to different manager |
| BackOffice.TaskClose | Stored Procedure | Closes task by setting EndDateTime |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BTask | CLUSTERED PK | TaskID ASC | - | - | Active |
| NC_BTask_CID | NONCLUSTERED | CID ASC | - | - | Active |
| NC_BTask_ManagerID | NONCLUSTERED | ManagerID ASC | - | - | Active |
| NC_BTask_TaskTypeID | NONCLUSTERED | TaskTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BC_BTask | FK | CID -> BackOffice.Customer |
| FK_DT_BTask | FK | TaskTypeID -> Dictionary.TaskType |
| FK_BM_BTask | FK | ManagerID -> BackOffice.Manager |
| FK_BM2_BTask | FK | OpenedBy -> BackOffice.Manager |

---

## 8. Sample Queries

### 8.1 Get all tasks for a specific customer

```sql
SELECT
    t.TaskID, t.TaskTypeID, tt.Name AS TaskType,
    t.ManagerID, t.StartDateTime, t.EndDateTime,
    t.OpenComment, t.OpenedOn
FROM BackOffice.Task t WITH (NOLOCK)
JOIN Dictionary.TaskType tt WITH (NOLOCK) ON tt.TaskTypeID = t.TaskTypeID
WHERE t.CID = 99999
ORDER BY t.OpenedOn DESC;
```

### 8.2 Get open tasks for a manager

```sql
SELECT t.TaskID, t.CID, t.TaskTypeID, t.StartDateTime, t.OpenComment
FROM BackOffice.Task t WITH (NOLOCK)
WHERE t.ManagerID = 701
  AND t.EndDateTime IS NULL
ORDER BY t.StartDateTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Live Data, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Task | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Task.sql*
