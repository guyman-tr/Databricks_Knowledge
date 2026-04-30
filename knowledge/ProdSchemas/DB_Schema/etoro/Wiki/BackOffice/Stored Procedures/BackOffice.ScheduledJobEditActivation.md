# BackOffice.ScheduledJobEditActivation

> Toggles the IsActive flag on a single scheduled job in BackOffice.ScheduledJob to activate or deactivate it without touching any other configuration fields. Returns @@ERROR.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE BackOffice.ScheduledJob SET IsActive = @IsActive WHERE JobID = @JobID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.ScheduledJobEditActivation` enables or disables a scheduled job without modifying any of its other configuration fields (cron, method, URI, etc.). This is the targeted alternative to `ScheduledJobEdit` (which overwrites all fields) for the common operational task of simply turning a job on or off.

Use cases:
- Temporarily disabling a job during a deployment or maintenance window.
- Re-enabling a job after it is safe to run again.
- Emergency shutdown of a runaway or problematic scheduled job.

The Quartz scheduler reads `IsActive` to determine which jobs to schedule. Setting `IsActive=0` stops future executions; the currently running execution (if any) is not interrupted.

---

## 2. Business Logic

### 2.1 Single-Column IsActive Toggle

**What**: Minimal UPDATE touching only the IsActive column for one job.

**Rules**:
- `SET NOCOUNT ON`: suppresses "rows affected" messages.
- `UPDATE BackOffice.ScheduledJob SET IsActive = @IsActive WHERE JobID = @JobID`: single-column UPDATE. No other columns are touched - no UpdateDate stamp (unlike ScheduledJobEdit).
- `WHERE JobID = @JobID`: targets one job by PK. If JobID does not exist, 0 rows affected (no error).
- `RETURN @@ERROR`: returns the SQL Server error code. 0 = success. Non-zero = error.
- No validation that the job exists or that the current IsActive value differs from @IsActive.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @JobID | int | NO | - | CODE-BACKED | PK of the scheduled job to activate/deactivate. FK to BackOffice.ScheduledJob.JobID. If no row exists with this ID, 0 rows affected (no error). |
| 2 | @IsActive | bit | NO | - | CODE-BACKED | New activation state: 1=active (Quartz will schedule this job), 0=inactive (job will not run). All current production jobs are IsActive=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | BackOffice.ScheduledJob | Writer | Toggles IsActive flag for the specified job |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice scheduler administration UI for job activation/deactivation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ScheduledJobEditActivation (procedure)
+-- BackOffice.ScheduledJob (table) [UPDATE IsActive only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJob | Table | UPDATE IsActive = @IsActive WHERE JobID = @JobID |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Single-column update | Design | Only IsActive is modified. No UpdateDate stamp (unlike ScheduledJobEdit). Caller does not need to supply other field values. |
| RETURN @@ERROR | Error propagation | Returns actual SQL error code, not always 0. |

---

## 8. Sample Queries

### 8.1 Disable a job (emergency shutdown)

```sql
EXEC BackOffice.ScheduledJobEditActivation
    @JobID = 5,        -- BackOfficeNotificationsConsumerJob
    @IsActive = 0;     -- Disable
```

### 8.2 Re-enable a job after maintenance

```sql
EXEC BackOffice.ScheduledJobEditActivation
    @JobID = 5,
    @IsActive = 1;     -- Enable
```

### 8.3 Check current activation status

```sql
SELECT JobID, JobName, IsActive, UpdateDate
FROM BackOffice.ScheduledJob WITH (NOLOCK)
ORDER BY JobID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ScheduledJobEditActivation | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ScheduledJobEditActivation.sql*
