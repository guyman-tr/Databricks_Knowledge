# BackOffice.ScheduledJobHistoryAdd

> Inserts a new execution log row into BackOffice.ScheduledJobHistory at job start (Phase 1 of the two-phase write pattern), returning the new JobHistoryID via OUTPUT parameter and SELECT.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT INTO BackOffice.ScheduledJobHistory (JobID, StartDate, StatusID, UserID); SET @JobHistoryID = SCOPE_IDENTITY(); SELECT @JobHistoryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.ScheduledJobHistoryAdd` creates the initial execution record when a BackOffice scheduled job fires. It is **Phase 1** of the two-phase execution log pattern:
- **Phase 1 (this procedure)**: Called at job START. Inserts with StatusID=1 (Running), StartDate, JobID, UserID. EndDate and Exception are NOT inserted - they remain NULL until Phase 2.
- **Phase 2 (`BackOffice.ScheduledJobHistoryEdit`)**: Called at job END. Updates the row with EndDate, final StatusID (2=Completed or 3=Failed), and Exception text.

The JobHistoryID returned by this procedure is the key that links Phase 1 to Phase 2 - the calling application passes it to `ScheduledJobHistoryEdit` after the job completes or fails.

The ScheduledJobHistory table has 33,013 rows spanning Oct 2016-Jan 2024. Rows with NULL EndDate (140 total) represent jobs that started (Phase 1 ran) but never completed their update (Phase 2 never ran - due to server restart or crash). These stale "Running" rows are an artifact of the two-phase pattern when processes are interrupted.

---

## 2. Business Logic

### 2.1 Phase 1 Insert - Job Start Recording

**What**: Minimal INSERT capturing job identity and start time; completion details deferred to Phase 2.

**Rules**:
- `SET NOCOUNT ON`: suppresses "rows affected" messages.
- `INSERT INTO BackOffice.ScheduledJobHistory (JobID, StartDate, StatusID, UserID)`: only 4 of the 6 columns are inserted. EndDate and Exception are NOT in the INSERT list - they default to NULL.
- `@StartDate` is a parameter (not `GETDATE()`): the calling application controls the start timestamp. This allows the scheduler to capture the true job invocation time, even if there is a delay between scheduling and execution.
- `SET @JobHistoryID = SCOPE_IDENTITY()`: safe IDENTITY capture immediately after INSERT.
- `SELECT @JobHistoryID`: returns the new JobHistoryID as a result set (for ExecuteScalar callers).
- `RETURN 0`: always returns success.
- The OUTPUT parameter and SELECT result are redundant - callers can use either.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @JobHistoryID | int OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter that receives the new JobHistoryID (IDENTITY) after INSERT. Must be passed to ScheduledJobHistoryEdit at job completion to update the row. Also returned via SELECT for application callers. |
| 2 | @JobID | int | NO | - | CODE-BACKED | FK to BackOffice.ScheduledJob.JobID. Links this execution log row to the job definition. The same @JobID can have many history rows (one per execution). |
| 3 | @StartDate | datetime | NO | - | CODE-BACKED | Timestamp of job invocation start. Passed by the caller (not defaulted to GETDATE() at INSERT time). Allows precise recording of when the scheduler actually triggered the job. |
| 4 | @StatusID | int | NO | - | CODE-BACKED | Initial status at job start. Expected value: 1=Running. Known status values: 1=Running, 2=Completed, 3=Failed. If passed as 2 or 3, this is a single-phase insert (job completed synchronously before logging). |
| 5 | @UserID | int | NO | - | CODE-BACKED | ID of the user or service account that triggered this job execution. Links to a user/manager table. For scheduled (automatic) executions, this may be a system service account ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | BackOffice.ScheduledJobHistory | Writer | Creates job execution log row (Phase 1 - job start) |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice Quartz scheduler service at job invocation time. Returns JobHistoryID that is then passed to ScheduledJobHistoryEdit at job completion.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobHistoryAdd (procedure)
+-- BackOffice.ScheduledJobHistory (table) [INSERT - Phase 1 job start]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJobHistory | Table | INSERT - creates execution log row with JobID, StartDate, StatusID=1, UserID |

### 6.2 Objects That Depend On This

No SQL-layer dependents found. The application layer uses the returned @JobHistoryID with `ScheduledJobHistoryEdit` to complete the two-phase pattern.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Two-phase write pattern | Design | This procedure is Phase 1. Phase 2 (ScheduledJobHistoryEdit) must be called after job completion to avoid stale "Running" rows in ScheduledJobHistory. |
| @StartDate parameter | Design | Caller controls the timestamp - not defaulted to GETDATE() - allowing accurate recording of scheduler invocation time vs. execution start time. |
| NULL EndDate/Exception | Design | These columns are intentionally not set at insert time. They are filled by ScheduledJobHistoryEdit. Rows with NULL EndDate indicate incomplete executions. |

---

## 8. Sample Queries

### 8.1 Log a job execution start

```sql
DECLARE @NewHistoryID INT;
EXEC BackOffice.ScheduledJobHistoryAdd
    @JobHistoryID = @NewHistoryID OUTPUT,
    @JobID = 5,
    @StartDate = GETDATE(),
    @StatusID = 1,     -- Running
    @UserID = 0;       -- System/scheduler user
SELECT @NewHistoryID AS NewJobHistoryID;
-- Save @NewHistoryID for later call to ScheduledJobHistoryEdit
```

### 8.2 Check for stale "Running" executions (Phase 2 never ran)

```sql
SELECT sjh.JobHistoryID, sj.JobName, sjh.StartDate, sjh.StatusID
FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
JOIN BackOffice.ScheduledJob sj WITH (NOLOCK) ON sj.JobID = sjh.JobID
WHERE sjh.EndDate IS NULL AND sjh.StatusID = 1
ORDER BY sjh.StartDate DESC;
-- 140 stale rows from decommissioned scheduler runs
```

### 8.3 View recent execution history for a specific job

```sql
SELECT TOP 10 JobHistoryID, StartDate, EndDate, StatusID, Exception
FROM BackOffice.ScheduledJobHistory WITH (NOLOCK)
WHERE JobID = 5
ORDER BY JobHistoryID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobHistoryAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobHistoryAdd.sql*
