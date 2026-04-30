# Billing.UpdateScheduledEntityTaskState

> Updates the task state (and optionally reason) for a specific (EntityID, TaskID) scheduled task in Billing.ScheduledEntityTaskState - the entity-based variant of the post-processing task queue (as opposed to the deposit-based ScheduledTaskState).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @EntityID + @TaskID (composite PK) - targets Billing.ScheduledEntityTaskState |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateScheduledEntityTaskState` is the state transition procedure for entity-based scheduled tasks. While `Billing.ScheduledTaskState` tracks post-processing tasks keyed by `DepositID`, `Billing.ScheduledEntityTaskState` uses a generic `EntityID` (with a `CID` customer reference) - enabling the same scheduled task infrastructure to be used for non-deposit entities such as withdrawals, redemptions, or customer-level tasks.

When a scheduler worker processes a task from `Billing.ScheduledEntityTaskState`, it calls this procedure to advance the task from In-Progress (3) to Done (1) or to a failure state with an explanatory `ReasonID`. The `Created` field is updated to the current UTC time on every state change, providing a timestamp of the last state transition.

Created September 2016 (ticket 40729) as part of the Billing ScheduledTask system; the SP itself was refined in April 2018 (ticket 51054).

No explicit EXECUTE grant found in SSDT UsersPermissions - called via schema-level permissions or application role configuration.

---

## 2. Business Logic

### 2.1 Entity Task State Transition

**What**: Advances a scheduled task for a specific entity to the specified state, with an optional reason code for failure/completion context.

**Columns/Parameters Involved**: `@EntityID`, `@TaskID`, `@TaskState`, `@ReasonID`, `Billing.ScheduledEntityTaskState.TaskState`, `Billing.ScheduledEntityTaskState.ReasonID`, `Billing.ScheduledEntityTaskState.Created`

**Rules**:
- `UPDATE Billing.ScheduledEntityTaskState SET TaskState=@TaskState, ReasonID=@ReasonID, Created=GETDATE() WHERE EntityID=@EntityID AND TaskID=@TaskID`
- Uses `GETDATE()` (local time) not `GETUTCDATE()` - minor note: defaults in the table use `GETUTCDATE()`
- `@ReasonID = NULL` (default): no specific reason; typically used for success states
- `@ReasonID <> NULL`: task completed with a reason code (failure/partial success context)
- Two-column WHERE clause: EntityID + TaskID (composite PK) - both required to identify the specific task
- If the (EntityID, TaskID) combination does not exist, the UPDATE silently affects 0 rows

**TaskState values** (consistent with Billing.ScheduledTaskState pattern):
- 0 = Pending (inserted by task creation)
- 3 = In Progress (locked by scheduler)
- 1 = Done (success)
- Other values may indicate failure or partial completion states

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EntityID | INT | NO | - | CODE-BACKED | The entity (e.g., withdrawal ID, customer ID, redemption ID) this task is for. Part of the composite PK of `Billing.ScheduledEntityTaskState`. |
| 2 | @TaskID | INT | NO | - | CODE-BACKED | The task type identifier. Part of the composite PK. Identifies which scheduled task type is being updated (e.g., notification, analytics event, etc.). |
| 3 | @TaskState | INT | NO | - | CODE-BACKED | New state to assign. Written to `Billing.ScheduledEntityTaskState.TaskState`. 0=Pending, 1=Done, 3=In Progress. Other values may represent failure/partial states. |
| 4 | @ReasonID | INT | YES | NULL | CODE-BACKED | Optional reason code for the state change. Written to `Billing.ScheduledEntityTaskState.ReasonID`. NULL for success states; non-NULL to record why a task was completed or failed in a non-standard way. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE EntityID, TaskID | Billing.ScheduledEntityTaskState | UPDATE | Advances task state and updates timestamp for the specified entity/task combination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No SQL dependents found in SSDT. | - | - | Called externally by scheduler workers after processing entity-based scheduled tasks. No explicit EXECUTE grant found in UsersPermissions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateScheduledEntityTaskState (procedure)
`- Billing.ScheduledEntityTaskState (table) - UPDATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledEntityTaskState | Table | UPDATE - sets TaskState, ReasonID, Created WHERE EntityID=@EntityID AND TaskID=@TaskID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by scheduler workers processing entity-based task queues. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. `Billing.ScheduledEntityTaskState` has: PK CLUSTERED on `(EntityID, TaskID)` - used by the WHERE clause; NCI on `(TaskID, CID, TaskState)` - supports polling queries.

### 7.2 Constraints

N/A for stored procedure. Note: The `Created` column is set via `GETDATE()` (server local time) rather than `GETUTCDATE()` - the table default uses `GETUTCDATE()`. This minor inconsistency may cause timezone issues on servers with non-UTC local time. Also: `TaskState DEFAULT (0)` at table level; this SP overrides it with the provided @TaskState.

---

## 8. Sample Queries

### 8.1 Mark a task as done
```sql
EXEC Billing.UpdateScheduledEntityTaskState
    @EntityID = 12345, @TaskID = 2, @TaskState = 1; -- Done, no reason
```

### 8.2 Mark a task as failed with a reason
```sql
EXEC Billing.UpdateScheduledEntityTaskState
    @EntityID = 12345, @TaskID = 2, @TaskState = 5, @ReasonID = 3;
```

### 8.3 Check current state of entity tasks
```sql
SELECT EntityID, TaskID, TaskState, ReasonID, Created, CID
FROM Billing.ScheduledEntityTaskState WITH (NOLOCK)
WHERE EntityID = 12345
ORDER BY TaskID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal code comments reference ticket 40729 (September 2016) for the ScheduledTask system and ticket 51054 (April 2018) for this SP's refinement.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateScheduledEntityTaskState | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateScheduledEntityTaskState.sql*
