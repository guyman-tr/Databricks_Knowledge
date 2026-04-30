# BackOffice.TaskAssign

> Reassigns an existing back-office CRM task to a different manager by updating the ManagerID on the task record.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TaskID - the task to reassign |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.TaskAssign transfers ownership of a legacy back-office CRM task from one manager to another. When a task could not be completed by the originally assigned manager - due to availability, expertise, or workload - a supervisor would use this procedure to hand the task to a different manager without closing and recreating it.

**This feature is retired.** BackOffice.Task has no new records since 2013. This procedure is no longer called in production. It is documented here for historical reference and completeness.

---

## 2. Business Logic

### 2.1 Simple ManagerID Update

**What**: Updates the ManagerID on the specified task.

**Columns/Parameters Involved**: `@TaskID`, `@ManagerID`

**Rules**:
- UPDATE BackOffice.Task SET ManagerID=@ManagerID WHERE TaskID=@TaskID
- Returns @@ERROR (0=success)
- No TRY/CATCH, no @@ROWCOUNT check - if @TaskID not found, silent no-op with RETURN 0
- No validation of @ManagerID against BackOffice.Manager

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TaskID | INTEGER | NO | - | VERIFIED | The task to reassign. Must correspond to a TaskID in BackOffice.Task. Invalid TaskID is a silent no-op (0 rows updated, RETURN 0). |
| 2 | @ManagerID | INTEGER | NO | - | VERIFIED | The manager to assign the task to. Written to BackOffice.Task.ManagerID. No validation against BackOffice.Manager - an invalid ManagerID will be accepted without error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TaskID | BackOffice.Task | MODIFIER (UPDATE ManagerID) | Reassigns the task to a new manager |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice CRM | - | Caller | Called to transfer task ownership between managers (feature retired 2013) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.TaskAssign (procedure)
└── BackOffice.Task (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Task | Table | UPDATE: SET ManagerID=@ManagerID WHERE TaskID=@TaskID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice CRM | External | Task reassignment within the manager workflow (retired) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Reassign a task to another manager (legacy - for reference only)
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.TaskAssign
    @TaskID    = 5000,
    @ManagerID = 77
SELECT @Err AS ErrorCode
```

### 8.2 Find tasks assigned to a specific manager (historical data)
```sql
SELECT TaskID, CID, TaskTypeID, StartDateTime, EndDateTime
FROM BackOffice.Task WITH (NOLOCK)
WHERE ManagerID = 77
ORDER BY StartDateTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.TaskAssign | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.TaskAssign.sql*
