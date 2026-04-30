# BackOffice.ScheduledJobsGet

> Returns all scheduled job definitions from BackOffice.ScheduledJob - the full registry that the BackOffice scheduler uses to discover and execute configured background jobs.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.ScheduledJobsGet is the scheduler bootstrap query - it returns every row from BackOffice.ScheduledJob, giving the Quartz scheduler service its complete list of jobs to manage. On startup, the scheduler calls this procedure to load all job definitions (name, cron schedule, execution type, method to invoke, and active status) and builds its in-memory job registry.

Without this procedure the scheduler service would have no mechanism to discover which jobs to run, and the entire BackOffice automated processing pipeline would not start. It also serves the BackOffice management UI for displaying, editing, and monitoring the job configuration list.

The procedure returns all 7 rows (all IsActive=0 in current production state). Operators can view the job registry through the BackOffice UI which calls this procedure to populate the scheduled jobs management screen.

---

## 2. Business Logic

### 2.1 Full Table Scan Design

**What**: The procedure intentionally returns all rows without any filter.

**Columns/Parameters Involved**: All columns (no WHERE clause)

**Rules**:
- No parameters, no filtering: the caller receives all job definitions regardless of IsActive status
- The scheduler service itself decides which jobs to activate (filtering by IsActive=1 in application code)
- This design allows the BackOffice UI to show ALL jobs (including inactive) for management purposes
- WITH (NOLOCK) read consistency is acceptable since job configuration changes are rare

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return columns** (all columns from BackOffice.ScheduledJob):

| # | Column | Type | Description |
|---|--------|------|-------------|
| R1 | JobID | int | Auto-generated unique job identifier (PK) |
| R2 | JobName | nvarchar(160) | Human-readable job name (e.g., "BackOfficeNotificationsConsumerJob") |
| R3 | ScheduledJobTypeID | int | Execution model: 1=ApiJob (HTTP), 2=InQueueJob (queue), 3=InternalJob (direct method) |
| R4 | Cron | varchar(160) | Quartz 6-field cron schedule expression |
| R5 | MethodName | varchar(500) | For InternalJob: "ClassName.MethodName" to invoke directly |
| R6 | Parameters | varchar(2000) | Additional execution parameters (empty in all current rows) |
| R7 | Uri | nvarchar(500) | HTTP endpoint for ApiJob, queue name for InQueueJob, empty for InternalJob |
| R8 | OwnerEmail | varchar(1000) | Responsible team/individual email for alerts (NULL in all current rows) |
| R9 | CreationDate | datetime | When the job definition was created |
| R10 | UpdateDate | datetime | When the job definition was last modified |
| R11 | IsActive | bit | 0=disabled, 1=active. All 7 rows currently 0 in production. |
| R12 | JobEnvironmentTypeID | int | Deployment environment scope (1=production in all current rows) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | BackOffice.ScheduledJob | READER (SELECT) | Reads the complete job configuration registry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Scheduler App | - | Caller | Called on startup to load all job definitions for Quartz scheduler registration |
| BackOffice Management UI | - | Caller | Called to populate the scheduled jobs management screen |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobsGet (procedure)
└── BackOffice.ScheduledJob (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJob | Table | SELECT of all columns, all rows (no filter), WITH NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Scheduler App | External | Reads job registry at startup |
| BackOffice Management UI | External | Reads job list for display and management |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC BackOffice.ScheduledJobsGet
```

### 8.2 Equivalent inline query with type name join
```sql
SELECT
    sj.JobID,
    sj.JobName,
    sjt.ScheduledJobType AS JobTypeName,
    sj.Cron,
    sj.MethodName,
    sj.IsActive,
    sj.OwnerEmail,
    sj.UpdateDate
FROM BackOffice.ScheduledJob sj WITH (NOLOCK)
JOIN Dictionary.ScheduledJobType sjt WITH (NOLOCK) ON sjt.ScheduledJobTypeID = sj.ScheduledJobTypeID
ORDER BY sj.JobName
```

### 8.3 Find active jobs only (post-processing the procedure result)
```sql
SELECT *
FROM BackOffice.ScheduledJob sj WITH (NOLOCK)
WHERE sj.IsActive = 1
ORDER BY sj.JobName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobsGet | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobsGet.sql*
