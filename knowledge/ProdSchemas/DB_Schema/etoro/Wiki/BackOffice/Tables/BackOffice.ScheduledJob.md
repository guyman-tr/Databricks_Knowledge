# BackOffice.ScheduledJob

> Registry of scheduled background jobs that run on cron schedules, invoking BackOffice service methods or APIs at configured intervals.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | JobID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.ScheduledJob is the configuration registry for the BackOffice scheduler system (Quartz-based, based on cron expression format). Each row defines one recurring background job: its name, schedule (cron expression), the method to invoke, the target service URI, and whether it is currently active. The table drives automated BackOffice processes like expired ID notifications, affiliate table synchronization, notification consumption, and cashout email dispatch.

Without this table the scheduler service has no jobs to run, and all time-triggered BackOffice automation would cease. Jobs are the engine behind non-interactive BackOffice workflows that cannot wait for a human agent to trigger them.

All 7 rows are currently IsActive=0 in production - either this scheduler mechanism was superseded by a newer scheduling infrastructure, or jobs were temporarily disabled. The cron expressions use Quartz format (6-field: seconds minutes hours dayOfMonth month dayOfWeek). History of executions is tracked in BackOffice.ScheduledJobHistory.

---

## 2. Business Logic

### 2.1 Three Job Execution Models

**What**: Jobs are classified into three types that determine how the scheduler invokes them.

**Columns Involved**: `ScheduledJobTypeID`, `Uri`, `MethodName`

**Rules**:
- ScheduledJobTypeID=1 (ApiJob): Scheduler calls an external HTTP API (Uri is populated with the endpoint URL). Original test jobs used localhost URIs
- ScheduledJobTypeID=2 (InQueueJob): Scheduler puts a message on a queue for async processing (Uri may be queue name or empty)
- ScheduledJobTypeID=3 (InternalJob): Scheduler calls an internal .NET method directly by class.method name (Uri is empty, MethodName is "ClassName.MethodName"). Most production jobs use this model

**Diagram**:
```
Quartz Scheduler reads BackOffice.ScheduledJob WHERE IsActive=1
        |
        v
ScheduledJobTypeID = 1 (ApiJob)     -> HTTP POST to Uri
ScheduledJobTypeID = 2 (InQueueJob) -> Enqueue to queue at Uri
ScheduledJobTypeID = 3 (InternalJob) -> Execute MethodName directly
        |
        v
Job result -> INSERT BackOffice.ScheduledJobHistory
```

### 2.2 Cron Schedule Format

**What**: Cron expressions use Quartz 6-field format (seconds, minutes, hours, dayOfMonth, month, dayOfWeek).

**Columns Involved**: `Cron`

**Rules**:
- `0 0 0/1 * * ?` = every hour at :00
- `0 0 22 * * ?` = daily at 22:00
- `0 0/1 * * * ?` = every minute
- `0 15 00 * * ?` = daily at 00:15
- `0 0/5 * 1/1 * ? *` = every 5 minutes
- `0 5 1 1/1 * ? *` = daily at 01:05

---

## 3. Data Overview

| JobID | JobName | ScheduledJobTypeID | Cron | IsActive | Meaning |
|-------|---------|-------------------|------|----------|---------|
| 4 | ExpiredIDJob | 3 (InternalJob) | 0 15 00 * * ? | false | Runs at 00:15 daily to identify customers whose identity documents have expired and trigger re-verification workflows. Currently inactive. |
| 5 | BackOfficeNotificationsConsumerJob | 3 (InternalJob) | 0 0/5 * 1/1 * ? * | false | Polls every 5 minutes to consume pending BackOffice notifications from a queue and process/dispatch them. |
| 8 | BackOfficeAffiliateTableAlignmentJob | 3 (InternalJob) | 0 5 1 1/1 * ? * | false | Runs daily at 01:05 to synchronize the BackOffice affiliate table with an upstream source, keeping affiliate records aligned. |
| 9 | BackOfficeNotificationsConsumerJob | 3 (InternalJob) | 0 0/5 * 1/1 * ? * | false | Processes cashout emails - polls every 5 min for processed cashouts needing email notifications. Duplicate name but different MethodName (ProcessedCashoutsEmailExecuter). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-generated unique job identifier. PK referenced by BackOffice.ScheduledJobHistory. |
| 2 | JobName | nvarchar(160) | NO | - | CODE-BACKED | Human-readable name identifying the job's purpose. Used in monitoring, logging, and ScheduledJobHistory records. |
| 3 | ScheduledJobTypeID | int | NO | - | VERIFIED | Job execution model. FK to Dictionary.ScheduledJobType. Values: 1=ApiJob (HTTP call to Uri), 2=InQueueJob (queue message), 3=InternalJob (direct method invocation). |
| 4 | Cron | varchar(160) | NO | - | CODE-BACKED | Quartz cron expression defining the execution schedule (6-field format: seconds minutes hours dayOfMonth month dayOfWeek). Examples: "0 0/5 * 1/1 * ? *" = every 5 minutes, "0 15 00 * * ?" = daily at 00:15. |
| 5 | MethodName | varchar(500) | NO | - | CODE-BACKED | For InternalJob types: the fully qualified method to invoke (format: "ClassName.MethodName"). For other types: may contain a method hint or be unused. Examples: "BackOfficeNotificationsConsumerExecuter.Execute", "ProcessedCashoutsEmailExecuter.Execute". |
| 6 | Parameters | varchar(2000) | NO | - | NAME-INFERRED | Additional parameters passed to the job at execution time. Empty string in all current rows - may carry JSON or key=value pairs for parameterized job execution. |
| 7 | Uri | nvarchar(500) | NO | - | VERIFIED | Target endpoint for ApiJob/InQueueJob types. Empty string for InternalJob types (ID 3-9). Historical test jobs pointed to "http://localhost:1221/api/TestQuartz". |
| 8 | OwnerEmail | varchar(1000) | YES | - | CODE-BACKED | Email address(es) of the team/individual responsible for this job. Used for alerting when the job fails or is disabled. NULL for all current rows. |
| 9 | CreationDate | datetime | YES | - | CODE-BACKED | Timestamp when the job definition was created. Earliest: 2015-11-01. |
| 10 | UpdateDate | datetime | YES | - | CODE-BACKED | Timestamp of the last modification to the job definition. Latest: 2024-07-23. |
| 11 | IsActive | bit | NO | - | VERIFIED | Whether the scheduler should execute this job. 0=disabled (all 7 rows are currently 0 in production). 1=active. Toggled by BackOffice.ScheduledJobEditActivation procedure without modifying other job properties. |
| 12 | JobEnvironmentTypeID | int | NO | - | NAME-INFERRED | Likely controls which deployment environment this job runs in (e.g., 1=production, 2=staging, 3=dev). All current rows show 1. No FK constraint found - lookup table may be application-side. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ScheduledJobTypeID | Dictionary.ScheduledJobType | FK (WITH CHECK) | Classifies the job execution model |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ScheduledJobHistory | JobID | FK | Execution history records for each run of this job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJob (table)
- FK target: Dictionary.ScheduledJobType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ScheduledJobType | Table | FK constraint on ScheduledJobTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJobHistory | Table | Stores execution history per JobID |
| BackOffice.ScheduledJobAdd | Procedure | WRITER - inserts new job definitions |
| BackOffice.ScheduledJobEdit | Procedure | MODIFIER - updates job configuration |
| BackOffice.ScheduledJobEditActivation | Procedure | MODIFIER - toggles IsActive flag only |
| BackOffice.ScheduledJobsGet | Procedure | READER - returns all job definitions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_ScheduledJob | CLUSTERED PK | JobID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BackOffice.ScheduledJob_Dictionary.ScheduledJobType | FK | ScheduledJobTypeID -> Dictionary.ScheduledJobType(ScheduledJobTypeID) |

---

## 8. Sample Queries

### 8.1 Get all active jobs with type name and next-run interpretation
```sql
SELECT
    sj.JobID,
    sj.JobName,
    sjt.ScheduledJobType AS JobType,
    sj.Cron,
    sj.MethodName,
    sj.IsActive,
    sj.OwnerEmail
FROM BackOffice.ScheduledJob sj WITH (NOLOCK)
JOIN Dictionary.ScheduledJobType sjt WITH (NOLOCK) ON sjt.ScheduledJobTypeID = sj.ScheduledJobTypeID
WHERE sj.IsActive = 1
ORDER BY sj.JobName
```

### 8.2 Get recent job execution history
```sql
SELECT TOP 50
    sj.JobName,
    sjh.StartDate,
    sjh.EndDate,
    DATEDIFF(SECOND, sjh.StartDate, sjh.EndDate) AS DurationSecs,
    sjhs.ScheduledJobStatus AS Status
FROM BackOffice.ScheduledJobHistory sjh WITH (NOLOCK)
JOIN BackOffice.ScheduledJob sj WITH (NOLOCK) ON sj.JobID = sjh.JobID
JOIN Dictionary.ScheduledJobStatus sjhs WITH (NOLOCK) ON sjhs.ScheduledJobStatusID = sjh.ScheduledJobStatusID
ORDER BY sjh.StartDate DESC
```

### 8.3 Get all InternalJob definitions with their executor class
```sql
SELECT
    sj.JobID,
    sj.JobName,
    sj.MethodName,
    sj.Cron,
    sj.IsActive,
    sj.UpdateDate
FROM BackOffice.ScheduledJob sj WITH (NOLOCK)
WHERE sj.ScheduledJobTypeID = 3  -- InternalJob
ORDER BY sj.JobName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJob | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.ScheduledJob.sql*
