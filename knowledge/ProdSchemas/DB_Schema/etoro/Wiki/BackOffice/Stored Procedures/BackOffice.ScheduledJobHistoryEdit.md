# BackOffice.ScheduledJobHistoryEdit

> Updates an existing job execution record in ScheduledJobHistory with the final outcome (end time, status, and exception text) when a scheduled job completes or fails.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @JobHistoryID - the execution record to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.ScheduledJobHistoryEdit is Phase 2 of the two-phase job execution write pattern. When a BackOffice Quartz scheduled job finishes - whether successfully or with an error - the scheduler calls this procedure to close out the execution record that was opened by BackOffice.ScheduledJobHistoryAdd at job start.

Without this procedure a job run would remain in StatusID=1 (Running) indefinitely. The 140 stale Running rows in BackOffice.ScheduledJobHistory are all cases where this procedure was never called - typically due to process crash, server restart, or unhandled exception before the update occurred.

The procedure accepts both success and failure outcomes: a successful completion passes StatusID=2 (Completed) with NULL Exception; a failed run passes StatusID=3 (Failed) with the error text in Exception. The UserID parameter tracks whether the job was triggered by the automated scheduler (typically NULL or a system user) or manually triggered from the BackOffice UI (a manager ID).

---

## 2. Business Logic

### 2.1 Two-Phase Execution Write Pattern

**What**: Job execution logging is split into two procedure calls - one at start, one at end.

**Columns/Parameters Involved**: `@JobHistoryID`, `@StatusID`, `@EndDate`, `@Exception`

**Rules**:
- Phase 1 (ScheduledJobHistoryAdd): INSERT creates the row, returns JobHistoryID, sets StatusID=1 (Running)
- Phase 2 (ScheduledJobHistoryEdit, this procedure): UPDATE closes the row with final status and end time
- If Phase 2 never executes: row stays Running (stale). No auto-cleanup mechanism in this procedure.
- StatusID=2 (Completed): EndDate set, Exception should be NULL (success)
- StatusID=3 (Failed): EndDate set, Exception contains the error message (up to 4000 chars)

**Diagram**:
```
Job fires -> ScheduledJobHistoryAdd (INSERT, StatusID=1)
                  |
                  v
             job executes
                  |
              success?
             /         \
           YES           NO
            |             |
    StatusID=2        StatusID=3
    Exception=NULL    Exception=<error text>
            \             /
             ScheduledJobHistoryEdit (UPDATE, this proc)
```

### 2.2 Error Return Pattern

**What**: The procedure returns @@ERROR to the caller as its result code.

**Columns/Parameters Involved**: RETURN @@ERROR

**Rules**:
- Returns 0 on success (no SQL error)
- Returns a non-zero SQL error code if the UPDATE fails (e.g., row lock, constraint violation)
- No RAISERROR or TRY/CATCH - the caller is responsible for interpreting @@ERROR

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @JobHistoryID | INTEGER | NO | - | VERIFIED | The execution record to update. Returned by ScheduledJobHistoryAdd (via SCOPE_IDENTITY()) at job start. The caller holds this ID and passes it back here at job end. FK to BackOffice.ScheduledJobHistory(JobHistoryID). |
| 2 | @EndDate | DATETIME | NO | - | VERIFIED | Timestamp when the job execution ended. Set by the scheduler to getdate() (or job framework time) at the moment the job finishes or fails. Written to ScheduledJobHistory.EndDate. |
| 3 | @StatusID | INTEGER | NO | - | VERIFIED | Final execution result: 2=Completed (success), 3=Failed (error). Value 1 (Running) would be nonsensical here - only used during active execution. Resolves to Dictionary.ScheduledJobStatus via BackOffice.ScheduledJobHistory FK. |
| 4 | @UserID | INTEGER | YES | - | CODE-BACKED | The user who triggered this job run. NULL for automated scheduler-triggered executions (the majority). Populated with a manager's UserID when manually triggered from the BackOffice UI. Passed through directly to BackOffice.ScheduledJobHistory.UserID. |
| 5 | @Exception | VARCHAR(4000) | YES | - | VERIFIED | Error text when StatusID=3 (Failed). NULL when StatusID=2 (Completed). The scheduler captures the exception message/stack trace and truncates to 4000 chars before passing. All 7,910 Failed rows in ScheduledJobHistory have non-NULL Exception values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @JobHistoryID | BackOffice.ScheduledJobHistory | MODIFIER (UPDATE) | Closes out the execution record created by ScheduledJobHistoryAdd |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Scheduler (external app) | - | Caller | Called by the Quartz scheduler service at job completion or failure. No SQL caller found in SSDT. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobHistoryEdit (procedure)
└── BackOffice.ScheduledJobHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJobHistory | Table | Target of UPDATE - sets EndDate, StatusID, UserID, Exception WHERE JobHistoryID=@JobHistoryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Scheduler App | External | Calls this procedure at job completion or failure to close the execution record |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Mark a job as successfully completed
```sql
EXEC BackOffice.ScheduledJobHistoryEdit
    @JobHistoryID = 12345,
    @EndDate      = GETDATE(),
    @StatusID     = 2,       -- Completed
    @UserID       = NULL,    -- automated scheduler
    @Exception    = NULL
```

### 8.2 Mark a job as failed with exception text
```sql
EXEC BackOffice.ScheduledJobHistoryEdit
    @JobHistoryID = 12345,
    @EndDate      = GETDATE(),
    @StatusID     = 3,       -- Failed
    @UserID       = NULL,
    @Exception    = 'System.Exception: Connection timeout at 10:32:15. Stack: ...'
```

### 8.3 Check for stale Running records that were never updated
```sql
SELECT
    sjh.JobHistoryID,
    sj.JobName,
    sjh.StartDate,
    DATEDIFF(MINUTE, sjh.StartDate, GETDATE()) AS MinutesRunning
FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
JOIN BackOffice.ScheduledJob sj WITH (NOLOCK) ON sj.JobID = sjh.JobID
WHERE sjh.StatusID = 1  -- Running
  AND sjh.EndDate IS NULL
ORDER BY sjh.StartDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobHistoryEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobHistoryEdit.sql*
