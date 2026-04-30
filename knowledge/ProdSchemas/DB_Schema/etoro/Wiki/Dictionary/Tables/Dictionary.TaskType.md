# Dictionary.TaskType

> Classifies BackOffice tasks by department/function for workflow routing and tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TaskTypeID (int, PK) |
| **Row Count** | 4 |
| **Indexes** | 2 (clustered PK + unique nonclustered on Name) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TaskType is a lookup table that categorizes BackOffice tasks by functional area — Sales, Support, Risk, or Withdraw. Each task created in the BackOffice system is tagged with a type to route it to the appropriate team.

### Why It Exists
The BackOffice task management system enables internal teams to create, assign, and track work items related to customer accounts. Task types ensure proper routing: sales-related tasks go to the sales team, risk tasks to compliance, withdrawal tasks to the finance team, etc.

### How It Works
The `TaskTypeID` is stored in `BackOffice.Task` (active tasks) and `History.Task` (completed/archived tasks). `BackOffice.TaskAdd` creates new tasks with a type, and `BackOffice.TaskClose` resolves them. The unique index on `Name` ensures no duplicate type labels.

---

## 2. Business Logic

### Value Map (Complete — 4 rows)

| TaskTypeID | Name | Business Meaning |
|------------|------|------------------|
| 1 | Sales | Task for the sales/account management team (outreach, follow-up, conversion) |
| 2 | Support | Task for customer support team (issue resolution, complaints) |
| 3 | Risk | Task for risk/compliance team (fraud review, AML investigation, account verification) |
| 4 | Withdraw | Task for withdrawal processing team (manual withdrawal review, funds release) |

---

## 3. Data Overview

| TaskTypeID | Name | Scenario |
|------------|------|----------|
| 1 | Sales | Account manager creates follow-up task for high-value depositor |
| 2 | Support | Customer files complaint, support task created for agent |
| 3 | Risk | Suspicious activity flagged, risk team task to investigate |
| 4 | Withdraw | Large withdrawal requires manual approval, task routed to finance |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TaskTypeID | int | NO | — | HIGH | Primary key identifying the task category. `1`=Sales, `2`=Support, `3`=Risk, `4`=Withdraw. Referenced by BackOffice.Task and History.Task. |
| 2 | Name | varchar(50) | NO | — | HIGH | Unique functional area label. Enforced unique by DTTP_NAME index. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| BackOffice.Task | TaskTypeID | Implicit FK → TaskTypeID | Active task assignments |
| History.Task | TaskTypeID | Implicit FK → TaskTypeID | Archived/completed tasks |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| BackOffice.TaskAdd | INSERT (into BackOffice.Task) | Creates new task with TaskTypeID |
| BackOffice.TaskClose | UPDATE | Closes/resolves a task |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `BackOffice.Task` — stores TaskTypeID for active tasks
- `History.Task` — archived task records

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DTTP | CLUSTERED PK | TaskTypeID ASC | FILLFACTOR 90 |
| DTTP_NAME | UNIQUE NONCLUSTERED | Name ASC | FILLFACTOR 90 — enforces unique task type labels |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |

---

## 8. Sample Queries

```sql
-- Get all task types
SELECT  TaskTypeID,
        Name
FROM    Dictionary.TaskType WITH (NOLOCK)
ORDER BY TaskTypeID;

-- Count active tasks by type
SELECT  tt.Name AS TaskType,
        COUNT(*) AS ActiveTasks
FROM    BackOffice.Task t WITH (NOLOCK)
JOIN    Dictionary.TaskType tt WITH (NOLOCK)
        ON t.TaskTypeID = tt.TaskTypeID
GROUP BY tt.Name
ORDER BY ActiveTasks DESC;

-- Find all risk tasks
SELECT  t.*
FROM    BackOffice.Task t WITH (NOLOCK)
JOIN    Dictionary.TaskType tt WITH (NOLOCK)
        ON t.TaskTypeID = tt.TaskTypeID
WHERE   tt.Name = 'Risk';
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TaskType`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.TaskType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TaskType.sql*
