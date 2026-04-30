# BackOffice.ScheduledJobHistory

> Execution log for the BackOffice Quartz scheduler - one row per job run, tracking start time, end time, status, and exception text. Written at job start (StatusID=1/Running) and updated at completion or failure. Last run recorded 2024-01-04; all jobs now inactive.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | JobHistoryID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.ScheduledJobHistory is the execution audit trail for the BackOffice Quartz-based scheduler. Every time a scheduled job fires, a row is inserted (StatusID=1, Running). When the job completes or fails, the row is updated with EndDate, final StatusID (2=Completed or 3=Failed), and Exception text for failures.

The table records 33,013 executions of 6 distinct jobs spanning October 2016 to January 2024. All 6 jobs correspond to JobIDs in BackOffice.ScheduledJob (the job configuration table). Since the latest execution was 2024-01-04 and all jobs are currently IsActive=0, the scheduler system appears to have been decommissioned.

140 rows have NULL EndDate and StatusID=1 (Running) - these are stale records from job runs that started but never completed their update (server restart, timeout, or crash during execution).

**Failure pattern**: JobID=1 has a 96.6% failure rate (7,594 failed of 7,857 runs), and JobID=2 has a 98.4% failure rate (316 of 321 runs). These jobs were likely already broken/deprecated for most of their logged history.

---

## 2. Business Logic

### 2.1 Job Execution Lifecycle (Two-Phase Write Pattern)

**What**: Each job run creates a row at start, then updates it at end.

**Columns Involved**: All columns

**Rules**:
- **Phase 1 - Job Start** (ScheduledJobHistoryAdd): INSERT with JobID, StartDate (passed from caller, not DEFAULT getdate()), StatusID=1 (Running), UserID. EndDate and Exception are NOT provided - left NULL. Returns @JobHistoryID via SCOPE_IDENTITY() and SELECT.
- **Phase 2 - Job End** (ScheduledJobHistoryEdit): UPDATE with EndDate=completion time, StatusID=2 (Completed) or 3 (Failed), UserID, Exception (error text or NULL). Keyed on JobHistoryID returned from Phase 1.
- If Phase 2 never runs (process crash, server restart): row remains with EndDate=NULL and StatusID=1 (Running). These are the 140 stale "Running" rows.
- Note: StartDate in ScheduledJobHistoryAdd is a parameter (not using the DEFAULT getdate() on the column). The DEFAULT only applies if StartDate is omitted from the INSERT column list, which it is not in the procedure.

### 2.2 Last Successful Run Query

**What**: ScheduledJobHistoryGetLast retrieves the most recent successfully completed run for a given job.

**Columns Involved**: `JobID`, `EndDate`, `StatusID`, `JobHistoryID`

**Rules**:
- SELECT TOP 1 WHERE JobID=@JobID AND EndDate IS NOT NULL AND StatusID=2 (Completed), ordered by JobHistoryID DESC.
- Used by the scheduler/monitoring to check when a job last succeeded (for retry logic or status display).
- Returns NULL if the job has never completed successfully.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (2026-03-17) | 33,013 |
| Unique JobIDs | 6 |
| Status: 1=Running (stale) | 140 (0.4%) |
| Status: 2=Completed | 24,963 (75.6%) |
| Status: 3=Failed | 7,910 (24.0%) |
| Rows with Exception text | 7,910 (all Failed rows) |
| Earliest StartDate | 2016-10-26 |
| Latest StartDate | 2024-01-04 |

**Per-job execution summary**:

| JobID | JobName | Runs | Completed | Failed | Fail% | Last Run | Avg Duration |
|-------|---------|------|-----------|--------|-------|----------|-------------|
| 5 | BackOfficeNotificationsConsumerJob | 24,655 | 24,629 | 0 | 0% | 2024-01-04 | 1s |
| 1 | (unknown - deprecated) | 7,857 | 149 | 7,594 | 96.6% | 2024-01-04 | 2s |
| 2 | (unknown - deprecated) | 321 | 5 | 316 | 98.4% | 2023-10-21 | 1s |
| 8 | BackOfficeAffiliateTableAlignmentJob | 93 | 93 | 0 | 0% | 2023-10-22 | 2s |
| 4 | ExpiredIDJob | 84 | 84 | 0 | 0% | 2023-10-22 | 0s |
| 9 | ProcessedCashoutsEmailExecuter | 3 | 3 | 0 | 0% | 2017-02-05 | 93s |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobHistoryID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing execution log identifier. Clustered PK. NOT FOR REPLICATION. Returned to the scheduler after ScheduledJobHistoryAdd INSERT (SCOPE_IDENTITY()) so the caller can update the row via ScheduledJobHistoryEdit. |
| 2 | JobID | int | NO | - | VERIFIED | Which scheduled job ran. FK (WITH CHECK) to BackOffice.ScheduledJob(JobID). 6 distinct JobIDs present; all correspond to jobs defined in BackOffice.ScheduledJob. |
| 3 | StartDate | datetime | NO | getdate() | VERIFIED | When this job execution started. DEFAULT getdate() exists on the column but ScheduledJobHistoryAdd passes @StartDate explicitly, so the default is rarely used. |
| 4 | EndDate | datetime | YES | - | VERIFIED | When this job execution ended. NULL = job is still running (StatusID=1) or was never updated (stale). Set by ScheduledJobHistoryEdit on completion or failure. 140 rows have NULL EndDate. |
| 5 | StatusID | int | NO | - | VERIFIED | Current execution status. FK (WITH CHECK) to Dictionary.ScheduledJobStatus. Values: 1=Running (in progress or stale), 2=Completed (success), 3=Failed (error). ScheduledJobHistoryGetLast filters for StatusID=2 AND EndDate IS NOT NULL for last-success queries. |
| 6 | UserID | int | YES | - | VERIFIED | The user who triggered the job. NULL for automated scheduler-triggered runs (most rows). May be a ManagerID when a job is triggered manually from the BackOffice UI. No FK constraint. |
| 7 | Exception | varchar(4000) | YES | - | VERIFIED | Error text captured when a job fails (StatusID=3). Set by ScheduledJobHistoryEdit on failure. NULL for all Completed rows. All 7,910 Failed rows have Exception text. Truncated to 4000 chars if the error message is longer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JobID | BackOffice.ScheduledJob | FK (WITH CHECK) | The job definition that was executed |
| StatusID | Dictionary.ScheduledJobStatus | FK (WITH CHECK) | Execution result status (Running/Completed/Failed) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ScheduledJobHistoryAdd | JobHistoryID | WRITER | Creates execution record at job start |
| BackOffice.ScheduledJobHistoryEdit | JobHistoryID | MODIFIER | Updates record at job completion/failure |
| BackOffice.ScheduledJobHistoryGetLast | JobID | READER | Returns most recent successful run for a job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobHistory (table)
- FK targets: BackOffice.ScheduledJob, Dictionary.ScheduledJobStatus
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJob | Table | FK on JobID; parent job definition |
| Dictionary.ScheduledJobStatus | Table | FK on StatusID; 3 status values (Running, Completed, Failed) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJobHistoryAdd | Procedure | WRITER - logs job start |
| BackOffice.ScheduledJobHistoryEdit | Procedure | MODIFIER - records result |
| BackOffice.ScheduledJobHistoryGetLast | Procedure | READER - last successful run |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_ScheduledJobHistory | CLUSTERED PK | JobHistoryID ASC | - | - | Active (ON [PRIMARY]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_ScheduledJobHistory | PK | JobHistoryID uniqueness |
| BackOffice_Job_STARTED | DEFAULT | StartDate = getdate() |
| FK_BackOffice.ScheduledJob_Dictionary.ScheduledJobStatus | FK (WITH CHECK) | StatusID -> Dictionary.ScheduledJobStatus(ScheduledJobStatusID) |
| FK_BackOffice_ScheduledJob | FK (WITH CHECK) | JobID -> BackOffice.ScheduledJob(JobID) |

### 7.3 Stale Running Records

140 rows have StatusID=1 (Running) with EndDate IS NULL. These represent job runs where Phase 2 (ScheduledJobHistoryEdit) never executed - typically caused by process crashes, server restarts, or unhandled exceptions before the update call. They should not be interpreted as currently-executing jobs; the scheduler has been inactive since January 2024.

---

## 8. Sample Queries

### 8.1 Get recent job executions with status and duration
```sql
SELECT TOP 50
    sjh.JobHistoryID,
    sj.JobName,
    sjh.StartDate,
    sjh.EndDate,
    DATEDIFF(SECOND, sjh.StartDate, sjh.EndDate) AS DurationSecs,
    sjs.ScheduledJobStatusName AS Status,
    LEFT(sjh.Exception, 200) AS ExceptionPreview
FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
JOIN BackOffice.ScheduledJob sj WITH (NOLOCK) ON sj.JobID = sjh.JobID
JOIN Dictionary.ScheduledJobStatus sjs WITH (NOLOCK) ON sjs.ScheduledJobStatusID = sjh.StatusID
ORDER BY sjh.JobHistoryID DESC
```

### 8.2 Get last successful run per job
```sql
SELECT
    sj.JobID,
    sj.JobName,
    last_run.StartDate AS LastSuccessStart,
    last_run.EndDate AS LastSuccessEnd,
    DATEDIFF(SECOND, last_run.StartDate, last_run.EndDate) AS DurationSecs
FROM BackOffice.ScheduledJob sj WITH (NOLOCK)
OUTER APPLY (
    SELECT TOP 1 StartDate, EndDate
    FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
    WHERE sjh.JobID = sj.JobID
      AND sjh.EndDate IS NOT NULL
      AND sjh.StatusID = 2
    ORDER BY sjh.JobHistoryID DESC
) last_run
ORDER BY sj.JobID
```

### 8.3 Failure analysis by job
```sql
SELECT
    sj.JobName,
    COUNT(*) AS TotalRuns,
    SUM(CASE WHEN sjh.StatusID=2 THEN 1 ELSE 0 END) AS Completed,
    SUM(CASE WHEN sjh.StatusID=3 THEN 1 ELSE 0 END) AS Failed,
    CAST(100.0*SUM(CASE WHEN sjh.StatusID=3 THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,1)) AS FailPct
FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
JOIN BackOffice.ScheduledJob sj WITH (NOLOCK) ON sj.JobID = sjh.JobID
GROUP BY sj.JobName
ORDER BY FailPct DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.2/10, Logic: 9.1/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobHistory | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.ScheduledJobHistory.sql*
