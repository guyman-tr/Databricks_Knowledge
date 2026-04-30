# BackOffice.ScheduledJobEdit

> Full-replacement UPDATE of all configurable fields for an existing scheduled job in BackOffice.ScheduledJob, identified by JobID. Also auto-stamps UpdateDate = GETDATE(). Returns @@ERROR.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE BackOffice.ScheduledJob SET [all fields] WHERE JobID = @JobID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.ScheduledJobEdit` updates all configurable fields of an existing scheduled job in the BackOffice Quartz scheduler registry. Unlike `ScheduledJobEditActivation` (which targets only the IsActive toggle), this procedure performs a full-replacement UPDATE - every modifiable column is overwritten with the supplied parameter values.

Use cases:
- Changing a job's cron schedule (e.g., from every 5 minutes to every 10 minutes).
- Updating the method name or URI after a service refactor.
- Rotating the owner email after team changes.
- Changing the job type (e.g., from InQueueJob to InternalJob).

The `UpdateDate` column is auto-stamped with `GETDATE()` by the procedure, providing an audit trail of when the job configuration last changed.

---

## 2. Business Logic

### 2.1 Full-Replacement Update

**What**: All 9 configurable columns are overwritten in a single UPDATE statement.

**Rules**:
- `SET NOCOUNT ON`: suppresses "rows affected" messages.
- `UpdateDate = GetDate()`: auto-stamped by the procedure - not a parameter. This means every call to ScheduledJobEdit records a timestamp of the last configuration change.
- All other fields (JobName, ScheduledJobTypeID, Cron, MethodName, Parameters, Uri, OwnerEmail, IsActive, JobEnvironmentTypeID) are fully overwritten with the provided parameter values. There is no partial-update / IIF pattern - caller must supply all values.
- `WHERE JobID = @JobID`: single row targeted by PK. If JobID does not exist, 0 rows affected (no error).
- `RETURN @@ERROR`: returns the SQL Server error code. 0 = success, non-zero = error. Unlike most procedures that return 0 explicitly, this propagates the actual error code to the caller.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @JobID | int | NO | - | CODE-BACKED | PK of the scheduled job to update. FK to BackOffice.ScheduledJob.JobID. If no row with this ID exists, 0 rows affected (no error). |
| 2 | @JobName | nvarchar(160) | NO | - | CODE-BACKED | New display name for the job. Overwrites existing JobName. |
| 3 | @ScheduledJobTypeID | int | NO | - | CODE-BACKED | New execution model: 1=ApiJob, 2=InQueueJob, 3=InternalJob. |
| 4 | @Cron | varchar(160) | NO | - | CODE-BACKED | New Quartz-format cron expression (6-field). Overwrites existing schedule. |
| 5 | @MethodName | varchar(500) | NO | - | CODE-BACKED | New method name or endpoint for the job invocation. Overwrites existing MethodName. |
| 6 | @Parameters | varchar(2000) | YES | - | CODE-BACKED | New serialized parameters for the job. NULL clears existing parameters. |
| 7 | @Uri | nvarchar(500) | YES | - | CODE-BACKED | New target URI (for ApiJob type). NULL for InternalJob type. |
| 8 | @OwnerEmail | varchar(1000) | YES | - | CODE-BACKED | New owner email address(es). NULL to clear ownership. |
| 9 | @IsActive | bit | NO | - | CODE-BACKED | New activation state. 1=active (will be scheduled), 0=inactive. |
| 10 | @JobEnvironmentTypeID | int | NO | - | CODE-BACKED | New environment type classification. Overwrites existing value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | BackOffice.ScheduledJob | Writer | Full-replacement update of all job configuration fields + UpdateDate timestamp |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice scheduler administration UI when editing job configurations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobEdit (procedure)
+-- BackOffice.ScheduledJob (table) [UPDATE - full replacement]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJob | Table | UPDATE - overwrites all configurable columns + stamps UpdateDate |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Full-replacement pattern | Design | All fields overwritten on every call - caller must supply all values (no partial update). Read current values first if only changing one field. |
| RETURN @@ERROR | Error propagation | Unlike other ScheduledJob SPs (which RETURN 0), this returns the actual SQL error code. Callers should check the return value. |

---

## 8. Sample Queries

### 8.1 Update a job's cron schedule

```sql
-- First read current values (ScheduledJobsGet or direct query)
-- Then call edit with ALL fields (full replacement):
EXEC BackOffice.ScheduledJobEdit
    @JobID = 4,
    @JobName = 'ExpiredIDJob',
    @ScheduledJobTypeID = 3,
    @Cron = '0 30 01 * * ?',      -- changed to 01:30 daily
    @MethodName = 'ExpiredIDExecuter.Execute',
    @Parameters = NULL,
    @Uri = NULL,
    @OwnerEmail = 'compliance@etoro.com',
    @IsActive = 0,
    @JobEnvironmentTypeID = 1;
```

### 8.2 Verify the update

```sql
SELECT JobID, JobName, Cron, UpdateDate, IsActive
FROM BackOffice.ScheduledJob WITH (NOLOCK)
WHERE JobID = 4;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobEdit.sql*
