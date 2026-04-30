# BackOffice.ScheduledJobAdd

> Inserts a new scheduled job definition into BackOffice.ScheduledJob and returns the new JobID via both OUTPUT parameter and SELECT.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT INTO BackOffice.ScheduledJob; SET @JobID = SCOPE_IDENTITY(); SELECT @JobID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.ScheduledJobAdd` creates a new entry in the BackOffice Quartz-based scheduler's job registry (`BackOffice.ScheduledJob`). Each row defines a recurring background task: its name, cron schedule, execution method, target URI, owner, and whether it is active on startup.

This procedure is the create endpoint in the BackOffice scheduler CRUD API (Add/Edit/EditActivation). It is called from the BackOffice administration interface when adding new scheduled jobs. The scheduler service reads from `BackOffice.ScheduledJob` at startup and during refresh cycles to determine which jobs to run.

Note: All current jobs in the table have `IsActive=0` - the Quartz-based scheduler system appears to have been decommissioned or superseded by newer infrastructure.

---

## 2. Business Logic

### 2.1 Insert and Return New JobID

**What**: Single INSERT into BackOffice.ScheduledJob with all required columns; returns the generated JobID.

**Rules**:
- `SET NOCOUNT ON`: suppresses "rows affected" messages.
- All 9 columns are explicit in the INSERT (no reliance on column defaults for required fields).
- `SET @JobID = SCOPE_IDENTITY()`: captures the IDENTITY value from the INSERT. Safe because SCOPE_IDENTITY() is called immediately after the INSERT with no intervening statements.
- `SELECT @JobID`: returns the new JobID as a single-row result set (for ADO.NET/application caller to read via ExecuteScalar or DataReader).
- `RETURN 0`: always returns success code.
- The OUTPUT parameter (@JobID) and the SELECT result are redundant - callers may use either mechanism.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @JobID | int OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter that receives the new JobID (IDENTITY) after INSERT. Also returned via SELECT. Caller must declare with OUTPUT keyword to receive value. |
| 2 | @JobName | nvarchar(160) | NO | - | CODE-BACKED | Display name of the scheduled job. Examples: 'ExpiredIDJob', 'BackOfficeNotificationsConsumerJob', 'BackOfficeAffiliateTableAlignmentJob'. |
| 3 | @ScheduledJobTypeID | int | NO | - | CODE-BACKED | Job execution model: 1=ApiJob (HTTP POST to Uri), 2=InQueueJob (queue message), 3=InternalJob (direct .NET method call). All current production jobs use type 3. |
| 4 | @Cron | varchar(160) | NO | - | CODE-BACKED | Quartz-format cron expression (6-field: seconds minutes hours dayOfMonth month dayOfWeek). Examples: '0 0/5 * 1/1 * ? *' (every 5 min), '0 15 00 * * ?' (daily at 00:15). |
| 5 | @MethodName | varchar(500) | NO | - | CODE-BACKED | For InternalJob (type 3): 'ClassName.MethodName' of the .NET method to invoke. For ApiJob/InQueueJob: endpoint or queue path. |
| 6 | @Parameters | varchar(2000) | YES | - | CODE-BACKED | JSON or serialized parameters passed to the job method at runtime. NULL for parameterless jobs. |
| 7 | @Uri | nvarchar(500) | YES | - | CODE-BACKED | HTTP endpoint URI for ApiJob (type 1). Empty or NULL for InternalJob (type 3). |
| 8 | @OwnerEmail | varchar(1000) | YES | - | CODE-BACKED | Email address(es) of the team or individual responsible for this job. Used for alerting on job failure. |
| 9 | @IsActive | bit | NO | - | CODE-BACKED | 1=job is active and will be scheduled by Quartz on startup. 0=inactive, job is registered but will not run. All current production jobs are IsActive=0 (scheduler decommissioned). |
| 10 | @JobEnvironmentTypeID | int | NO | - | CODE-BACKED | Environment this job is configured for. Allows different job registrations per environment (staging, production, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | BackOffice.ScheduledJob | Writer | Creates a new scheduled job definition row |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice scheduler administration UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobAdd (procedure)
+-- BackOffice.ScheduledJob (table) [INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJob | Table | INSERT - creates new scheduled job definition |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Add a new internal job

```sql
DECLARE @NewJobID INT;
EXEC BackOffice.ScheduledJobAdd
    @JobID = @NewJobID OUTPUT,
    @JobName = 'MyNewJob',
    @ScheduledJobTypeID = 3,                    -- InternalJob
    @Cron = '0 0/5 * 1/1 * ? *',               -- every 5 minutes
    @MethodName = 'MyService.RunMyJob',
    @Parameters = NULL,
    @Uri = NULL,
    @OwnerEmail = 'team@etoro.com',
    @IsActive = 0,                              -- start inactive
    @JobEnvironmentTypeID = 1;
SELECT @NewJobID AS NewJobID;
```

### 8.2 Verify the new job was registered

```sql
SELECT JobID, JobName, ScheduledJobTypeID, Cron, IsActive
FROM BackOffice.ScheduledJob WITH (NOLOCK)
ORDER BY JobID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobAdd.sql*
