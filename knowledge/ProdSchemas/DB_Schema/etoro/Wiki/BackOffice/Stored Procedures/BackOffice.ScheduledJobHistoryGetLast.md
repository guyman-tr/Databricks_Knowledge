# BackOffice.ScheduledJobHistoryGetLast

> Returns the most recently completed (successful) execution record for a given scheduled job, used by the scheduler to determine when a job last succeeded.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @JobID - the job whose last success is requested |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.ScheduledJobHistoryGetLast is the scheduler's "last success check" query. After registering a job run, the scheduler (or a monitoring component) calls this procedure to find out when a specific job last completed successfully, enabling retry decisions, health monitoring, and status reporting in the BackOffice UI.

Without this procedure the scheduler would have no way to distinguish a job that has never succeeded from one that ran successfully moments ago. The filter `StatusID=2 AND EndDate IS NOT NULL` intentionally excludes stale Running rows (StatusID=1, EndDate=NULL) and Failed rows (StatusID=3) - the caller only wants real completions.

The result drives scheduler retry logic: if the last success is older than a threshold, the scheduler may trigger an immediate re-run. For jobs like BackOfficeNotificationsConsumerJob (every 5 minutes), this check helps detect gaps in execution.

---

## 2. Business Logic

### 2.1 Last-Success Filter Logic

**What**: Returns only successfully completed runs (not still-running and not failed).

**Columns/Parameters Involved**: `@JobID`, `StatusID`, `EndDate`, `JobHistoryID`

**Rules**:
- Filter 1: `JobID = @JobID` - scope to the requested job only
- Filter 2: `EndDate IS NOT NULL` - excludes stale Running rows (140 rows in production)
- Filter 3: `StatusID = 2` (Completed) - excludes failed runs
- `TOP 1 ORDER BY JobHistoryID DESC` - returns the most recent qualifying run (JobHistoryID is IDENTITY so ordering by it gives chronological order)
- Returns NULL result set (0 rows) if the job has never completed successfully

### 2.2 Output Result Set

**What**: Returns all 7 columns of BackOffice.ScheduledJobHistory for the matched row.

**Columns/Parameters Involved**: `JobHistoryID`, `JobID`, `StartDate`, `EndDate`, `StatusID`, `UserID`, `Exception`

**Rules**:
- StatusID in result will always be 2 (Completed) due to WHERE clause
- EndDate in result will never be NULL due to WHERE clause
- Exception in result will typically be NULL (completed runs have no exception)
- Caller can compute job duration as DATEDIFF(SECOND, StartDate, EndDate)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @JobID | INTEGER | NO | - | VERIFIED | The JobID of the job to query. FK to BackOffice.ScheduledJob(JobID). Must be a valid JobID (6 distinct JobIDs exist in ScheduledJobHistory). Pass a specific JobID to get that job's last successful run. |

**Return columns** (from BackOffice.ScheduledJobHistory SELECT TOP 1):

| # | Column | Type | Description |
|---|--------|------|-------------|
| R1 | JobHistoryID | int | PK of the returned execution record |
| R2 | JobID | int | Echoes back the @JobID parameter |
| R3 | StartDate | datetime | When this last-successful run started |
| R4 | EndDate | datetime | When this last-successful run ended (always non-NULL in result) |
| R5 | StatusID | int | Always 2 (Completed) in result due to WHERE filter |
| R6 | UserID | int | User who triggered the run (NULL for automated) |
| R7 | Exception | varchar(4000) | Always NULL for completed runs |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @JobID | BackOffice.ScheduledJob | Lookup | JobID must correspond to a defined job |
| (query) | BackOffice.ScheduledJobHistory | READER (SELECT) | Reads execution history to find last successful run |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Scheduler (external app) | - | Caller | Called to check when a job last succeeded; no SQL caller found in SSDT. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobHistoryGetLast (procedure)
└── BackOffice.ScheduledJobHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJobHistory | Table | SELECT TOP 1 WHERE JobID=@JobID AND EndDate IS NOT NULL AND StatusID=2 ORDER BY JobHistoryID DESC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Scheduler App | External | Calls this procedure to check job last-success timestamp for monitoring and retry decisions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get last successful run for a specific job
```sql
EXEC BackOffice.ScheduledJobHistoryGetLast @JobID = 5  -- BackOfficeNotificationsConsumerJob
```

### 8.2 Equivalent inline query with readable status join
```sql
SELECT TOP 1
    sjh.JobHistoryID,
    sj.JobName,
    sjh.StartDate,
    sjh.EndDate,
    DATEDIFF(SECOND, sjh.StartDate, sjh.EndDate) AS DurationSecs
FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
JOIN BackOffice.ScheduledJob sj WITH (NOLOCK) ON sj.JobID = sjh.JobID
WHERE sjh.JobID = 5
  AND sjh.EndDate IS NOT NULL
  AND sjh.StatusID = 2
ORDER BY sjh.JobHistoryID DESC
```

### 8.3 Get last successful run for all jobs in one query
```sql
SELECT
    sj.JobID,
    sj.JobName,
    last_ok.StartDate AS LastSuccessStart,
    last_ok.EndDate AS LastSuccessEnd,
    DATEDIFF(SECOND, last_ok.StartDate, last_ok.EndDate) AS DurationSecs,
    DATEDIFF(HOUR, last_ok.EndDate, GETDATE()) AS HoursSinceLastSuccess
FROM BackOffice.ScheduledJob sj WITH (NOLOCK)
OUTER APPLY (
    SELECT TOP 1 StartDate, EndDate
    FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
    WHERE sjh.JobID = sj.JobID
      AND sjh.EndDate IS NOT NULL
      AND sjh.StatusID = 2
    ORDER BY sjh.JobHistoryID DESC
) last_ok
ORDER BY sj.JobID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobHistoryGetLast | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobHistoryGetLast.sql*
