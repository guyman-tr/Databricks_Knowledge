# BackOffice.TaskAdd

> Creates a new back-office CRM task for a customer and returns the new TaskID, scheduling a manager follow-up action (Sales, Support, Risk, or Withdraw) within a specified time window.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TaskID OUTPUT - the newly created task identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.TaskAdd creates a task record in the legacy BackOffice CRM system. Tasks represented actionable follow-up items that managers needed to perform for specific customers - a sales call to a prospect, support for a complaint, a risk review, or a withdrawal issue. Each task had an opening manager, an assigned manager, a time window, and notes.

**This feature is retired.** BackOffice.Task has no new records since 2013 (max TaskID ~11,496). The task management function was replaced by external tooling (Zendesk integration). The procedure and table remain in source control but are no longer called in production.

The procedure returns the new TaskID via an OUTPUT parameter using SCOPE_IDENTITY(), allowing callers to reference the created task immediately.

---

## 2. Business Logic

### 2.1 Task Creation with SCOPE_IDENTITY Return

**What**: Inserts a new task row and returns the generated TaskID to the caller.

**Columns/Parameters Involved**: All INSERT columns + `@TaskID OUTPUT`

**Rules**:
- INSERT INTO BackOffice.Task (CID, TaskTypeID, ManagerID, StartDateTime, EndDateTime, OpenComment, OpenedBy, OpenedOn) VALUES (all @params, GETDATE())
- OpenedOn is always server time (GETDATE()) - the caller cannot supply a custom creation timestamp
- SELECT @LocalError = @@ERROR; if non-zero: RAISERROR(60000,16,1,'BackOffice.TaskAdd',@LocalError), RETURN 60000
- SET @TaskID = SCOPE_IDENTITY() - returns the auto-incremented TaskID to the caller
- RETURN 0 on success

**Task Type Values** (from Dictionary.TaskType):

| TaskTypeID | Name |
|-----------|------|
| 1 | Sales |
| 2 | Support |
| 3 | Risk |
| 4 | Withdraw |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | The customer this task is about. Written to BackOffice.Task.CID. FK to BackOffice.Customer (indexed NC_BTask_CID for per-customer task queries). |
| 2 | @TaskTypeID | INTEGER | NO | - | VERIFIED | The category of follow-up action: 1=Sales, 2=Support, 3=Risk, 4=Withdraw. Written to BackOffice.Task.TaskTypeID. FK to Dictionary.TaskType (indexed NC_BTask_TaskTypeID for type-based filtering). |
| 3 | @ManagerID | INTEGER | NO | - | VERIFIED | The manager initially assigned to work on this task. Written to BackOffice.Task.ManagerID. Can be changed later by TaskAssign. FK to BackOffice.Manager (indexed NC_BTask_ManagerID). |
| 4 | @OpenedBy | INTEGER | NO | - | VERIFIED | The manager who created this task (may differ from @ManagerID if the creator assigns to someone else). Written to BackOffice.Task.OpenedBy. |
| 5 | @StartDateTime | DATETIME | NO | - | VERIFIED | The start of the task's due window. Written to BackOffice.Task.StartDateTime. Tasks should not be actioned before this time. |
| 6 | @EndDateTime | DATETIME | NO | - | VERIFIED | The end of the task's due window. Written to BackOffice.Task.EndDateTime. Defines the deadline for completing the task. |
| 7 | @Comment | VARCHAR(MAX) | NO | - | VERIFIED | The reason the task was created; free-text notes from the opening manager. Written to BackOffice.Task.OpenComment. |
| 8 | @TaskID | INTEGER OUTPUT | - | - | VERIFIED | OUTPUT parameter. Set to SCOPE_IDENTITY() after successful INSERT. Returns the new TaskID to the caller for immediate reference (e.g., to link to other records or log). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Task | WRITER (INSERT) | Creates a new task row with all scheduling and assignment data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice CRM | - | Caller | Called when creating follow-up tasks for customer accounts (feature retired 2013) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.TaskAdd (procedure)
└── BackOffice.Task (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Task | Table | INSERT target - creates the new task row; SCOPE_IDENTITY() returns the new TaskID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TaskAssign | Stored Procedure | Reassigns the ManagerID of tasks created by this procedure |
| BackOffice.TaskClose | Stored Procedure | Closes and archives tasks created by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Operational Status

BackOffice.Task has no new records since 2013. This procedure is no longer called in production. The task management function it supported has been replaced by external CRM/ticketing tooling.

---

## 8. Sample Queries

### 8.1 Create a risk follow-up task (legacy - for reference only)
```sql
DECLARE @NewTaskID INTEGER
EXEC BackOffice.TaskAdd
    @CID           = 12345678,
    @TaskTypeID    = 3,                          -- Risk
    @ManagerID     = 42,                         -- assigned manager
    @OpenedBy      = 42,                         -- same manager opens and is assigned
    @StartDateTime = '2013-06-01 09:00:00',
    @EndDateTime   = '2013-06-07 17:00:00',
    @Comment       = 'Review deposit pattern for AML compliance',
    @TaskID        = @NewTaskID OUTPUT
SELECT @NewTaskID AS CreatedTaskID
```

### 8.2 View tasks by type (historical data only)
```sql
SELECT t.TaskID, t.CID, t.TaskTypeID, t.ManagerID, t.StartDateTime, t.EndDateTime, t.OpenComment
FROM BackOffice.Task t WITH (NOLOCK)
WHERE t.TaskTypeID = 3   -- Risk tasks
ORDER BY t.OpenedOn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.TaskAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.TaskAdd.sql*
