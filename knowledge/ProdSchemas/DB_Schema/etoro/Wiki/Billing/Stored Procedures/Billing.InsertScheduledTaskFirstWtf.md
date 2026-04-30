# Billing.InsertScheduledTaskFirstWtf

> Enqueues a customer's withdrawal-to-funding (WTF) entity into the PostWTF scheduled processing pipeline (TaskID=6) if the customer has no currently active task in that pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Billing.ScheduledEntityTaskState (EntityID + TaskID composite PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.InsertScheduledTaskFirstWtf` registers a withdrawal-to-funding entity in the PostWTF (Post Withdrawal to Funding) scheduled pipeline. The PostWTF pipeline is a background scheduler that processes `Billing.WithdrawToFunding` records after they are created - handling routing, bank assignment, and external notifications. When a new WithdrawToFunding record is created for a customer, this procedure is called to queue it for post-processing by inserting a "Pending" task row into `Billing.ScheduledEntityTaskState`.

The procedure enforces a one-active-task-per-customer constraint: if the customer already has an unfinished PostWTF task (TaskState not equal to 2=Completed), no new row is inserted. This prevents duplicate processing of the same customer's withdrawal entities through the pipeline concurrently.

Data flows: a calling process (typically triggered after a new WithdrawToFunding record is created) supplies the WtfID and the customer's CID. The procedure guards against duplicates and inserts a pending task row. The background scheduler then picks up Pending rows via `Billing.GetScheduledTaskWithdrawToFundingEntities`, processes them, and updates TaskState to Completed via dedicated update procedures.

---

## 2. Business Logic

### 2.1 One-Active-Task-Per-Customer Idempotency Guard

**What**: Prevents multiple concurrent PostWTF tasks from being created for the same customer.

**Columns/Parameters Involved**: `@WtfID`, `@Cid`, `TaskID` (hardcoded=6), `TaskState`

**Rules**:
- Existence check: `NOT EXISTS (SELECT TOP 1 1 FROM Billing.ScheduledEntityTaskState WHERE TaskID=6 AND CID=@Cid AND TaskState<>2)`
- TaskState<>2 means: any state that is NOT Completed (0=Pending, 1=InProgress/Processed) qualifies as "active"
- If an active row already exists for this customer under TaskID=6, the INSERT is skipped silently - no error, no return code
- If the customer's last task completed (TaskState=2) or they have no prior row, a new Pending task is inserted
- This enforces the "first WTF" semantics: only the first unprocessed WTF triggers a new scheduled task

**Diagram**:
```
WithdrawToFunding created (@WtfID, @CID)
        |
        v
InsertScheduledTaskFirstWtf(@WtfID=WtfID, @Cid=CID)
        |
        EXISTS check: TaskID=6 AND CID=@Cid AND TaskState<>2 ?
        |
        +-- YES (active task exists) -> no-op, return
        |
        +-- NO  (no active task) -> INSERT into ScheduledEntityTaskState:
                (EntityID=@WtfID, TaskID=6, TaskState=0, ReasonID=NULL,
                 CreationDate=GETUTCDATE(), CID=@Cid)
        |
        v
Background scheduler polls for TaskState=0 rows
        |
        v
GetScheduledTaskWithdrawToFundingEntities -> processes batch
        |
        v
TaskState updated to 1 (InProgress) then 2 (Completed)
```

### 2.2 Error Handling via PRINT Logging

**What**: Errors are caught and logged via PRINT with a detailed diagnostic message rather than re-raised.

**Columns/Parameters Involved**: all (general error context)

**Rules**:
- TRY/CATCH wraps the entire body
- On error, PRINT outputs: server name, DB name, procedure name, error procedure, error line, error message, error severity, transaction count, and UTC timestamp
- The error is NOT re-raised - callers receive no exception signal on failure; the task simply is not inserted
- This pattern is consistent with bulk-insert scheduled pipeline procedures where a single customer's failure should not block the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WtfID | INT | NO | - | CODE-BACKED | The EntityID of the WithdrawToFunding record being queued for PostWTF processing. Stored as EntityID in Billing.ScheduledEntityTaskState. Identifies which specific withdrawal-to-funding entity needs post-processing. |
| 2 | @Cid | INT | NO | - | CODE-BACKED | The customer ID (CID) owning this withdrawal-to-funding record. Used both in the existence check (to find any active TaskID=6 row for this customer) and stored in the inserted row to enable per-customer deduplication. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXISTS check + INSERT | Billing.ScheduledEntityTaskState | READ + INSERT | Reads to check for active tasks (TaskID=6, CID=@Cid, TaskState<>2); inserts Pending task row if guard passes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Caller | Called by the service that creates WithdrawToFunding records, to queue the newly created entity for PostWTF pipeline processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.InsertScheduledTaskFirstWtf (procedure)
└── Billing.ScheduledEntityTaskState (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledEntityTaskState | Table | Existence-checked (SELECT TOP 1) for duplicate guard, then INSERT if safe |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetScheduledTaskWithdrawToFundingEntities | Stored Procedure | Downstream consumer - fetches the Pending rows (TaskState=0) created by this SP for batch processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Uses `SELECT TOP 1 1` in the existence check for maximum efficiency (stops at first matching row)
- Hardcoded constants: `TaskID=6` (PostWTF task), `TaskState=0` (Pending), `ReasonID=NULL`
- INSERT uses positional VALUES list (column order matches table DDL): `(EntityID, TaskID, TaskState, ReasonID, CreationDate, CID)`
- TRY/CATCH catches all errors; diagnostic info is PRINTed with Format(GetUTCDate(), 'yyyyMMdd HH:mm:ss.fff') timestamp precision
- Author: Geri Reshef, 18/04/2018, internal ticket 51056

---

## 8. Sample Queries

### 8.1 Enqueue a WTF entity for PostWTF processing
```sql
EXEC Billing.InsertScheduledTaskFirstWtf
    @WtfID = 123456,
    @Cid   = 7890123
```

### 8.2 Verify whether a customer's PostWTF task was inserted
```sql
SELECT EntityID, TaskID, TaskState, ReasonID, CreationDate, CID
FROM Billing.ScheduledEntityTaskState WITH (NOLOCK)
WHERE CID = 7890123 AND TaskID = 6
ORDER BY CreationDate DESC
```

### 8.3 Check for customers with active (non-completed) PostWTF tasks
```sql
SELECT CID, COUNT(*) AS ActiveTasks, MIN(CreationDate) AS OldestTask
FROM Billing.ScheduledEntityTaskState WITH (NOLOCK)
WHERE TaskID = 6 AND TaskState <> 2
GROUP BY CID
HAVING COUNT(*) > 0
ORDER BY OldestTask ASC
-- Customers with active tasks will be skipped by InsertScheduledTaskFirstWtf
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure. Related pages found (PostWTF pipeline context) did not contain direct references to InsertScheduledTaskFirstWtf.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 consumer analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.InsertScheduledTaskFirstWtf | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.InsertScheduledTaskFirstWtf.sql*
