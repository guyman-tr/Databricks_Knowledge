# Billing.DeleteScheduledTaskState

> Removes a specific post-deposit processing task state record from Billing.ScheduledTaskState, cancelling or cleaning up a queued task for a given deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID + @TaskID identify the ScheduledTaskState row to delete |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DeleteScheduledTaskState` removes a single task state record from `Billing.ScheduledTaskState` for a specific deposit and task type combination. This is the administrative delete/cancel operation for the post-deposit processing pipeline queue.

`Billing.ScheduledTaskState` tracks the execution state of each deposit's asynchronous post-processing tasks (8 task types including AppsFlyer attribution, tracking pixels, RabbitMQ FTD notifications, Mixpanel analytics, etc.). When `Billing.DepositAdd` creates a deposit, it enqueues all active tasks as Pending (TaskState=0) in this table. Background workers then pick up and process each task.

This procedure is used to:
- Cancel a pending task that should not run for a specific deposit (e.g., test deposits, fraudulent deposits being reversed)
- Clean up orphaned state records after corrections
- Remove re-queued tasks that are no longer needed

Created by Geri Reshef on 07/09/2016 (ticket 40729) as part of the Billing ScheduledTask infrastructure.

---

## 2. Business Logic

### 2.1 Task State Record Removal

**What**: Direct DELETE on the composite primary key (DepositID, TaskID) of the task state table.

**Columns/Parameters Involved**: `@DepositID`, `@TaskID`

**Rules**:
- Simple DELETE - no validation, no audit trail
- If the (DepositID, TaskID) combination doesn't exist, 0 rows deleted silently
- Removing a Pending task prevents the background worker from processing it
- Removing a Completed task has no operational effect (work is already done)
- Should not be called on In-Progress tasks without coordination with the scheduler

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit ID whose task state entry should be removed. References Billing.Deposit.DepositID. Together with @TaskID forms the composite primary key of Billing.ScheduledTaskState. |
| 2 | @TaskID | INT | NO | - | CODE-BACKED | The task type ID to remove for this deposit. References Billing.ScheduledTaskConfig.TaskID. Task types include AppsFlyer (1), pixels (2-3), RabbitMQ FTD (4), Mixpanel (5-8), and others as configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID + @TaskID | Billing.ScheduledTaskState | Delete | Removes the matching post-deposit task state record. See [Billing.ScheduledTaskState](../Tables/Billing.ScheduledTaskState.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by admin tooling for deposit processing management.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DeleteScheduledTaskState (procedure)
└── Billing.ScheduledTaskState (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | DELETE target - removes the specific (DepositID, TaskID) task queue entry |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit operations admin | External | Used to cancel or clean up specific post-deposit processing tasks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Remove a specific pending task for a deposit

```sql
EXEC Billing.DeleteScheduledTaskState
    @DepositID = 12345678,
    @TaskID = 1;  -- AppsFlyer attribution task
```

### 8.2 Check current task states for a deposit before deleting

```sql
SELECT sts.DepositID,
       sts.TaskID,
       sts.TaskState,
       stc.Description AS TaskDescription
FROM Billing.ScheduledTaskState sts WITH (NOLOCK)
    JOIN Billing.ScheduledTaskConfig stc WITH (NOLOCK)
        ON sts.TaskID = stc.TaskID
WHERE sts.DepositID = 12345678
ORDER BY sts.TaskID;
```

### 8.3 Find deposits with pending tasks older than 1 day (potential stuck tasks)

```sql
SELECT sts.DepositID,
       sts.TaskID,
       sts.TaskState,
       d.PaymentDate
FROM Billing.ScheduledTaskState sts WITH (NOLOCK)
    JOIN Billing.Deposit d WITH (NOLOCK)
        ON sts.DepositID = d.DepositID
WHERE sts.TaskState = 0  -- Pending
  AND d.PaymentDate < DATEADD(DAY, -1, GETUTCDATE())
ORDER BY d.PaymentDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DeleteScheduledTaskState | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DeleteScheduledTaskState.sql*
