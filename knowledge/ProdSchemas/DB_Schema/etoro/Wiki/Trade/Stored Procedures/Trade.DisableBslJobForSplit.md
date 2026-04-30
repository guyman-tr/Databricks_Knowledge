# Trade.DisableBslJobForSplit

> Manages BSL (Buy/Sell Limit) SQL Agent jobs during stock split operations — disabling them when a split is imminent and re-enabling them when complete.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (none — parameterless) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

During stock split events, BSL (Buy/Sell Limit) processing must be paused to prevent incorrect order execution at pre-split prices. This procedure is the **automated job controller** that reads from the Monitor.MonitorJobs table and either **disables** or **re-enables** two SQL Agent jobs:

1. `etoro - SecondaryJob - BSL- RunBSLProcedures` — the main BSL processing job
2. `etoro - SecondaryJob - Check if BSLRealFunds is null` — a BSL data validation job

The procedure operates as a state machine driven by Monitor.MonitorJobs.StatusID:
- **StatusID IN (-2, -1)**: Split is beginning → disable and stop both jobs
- **StatusID IN (1, 2)**: Split is complete → re-enable both jobs

On Always On Availability Group secondaries, it also updates Monitor.SynMonitorJobs to synchronize the job state across replicas.

---

## 2. Business Logic

### 2.1 Disable BSL Jobs (Split Start)

**What**: Disables and stops BSL jobs when a stock split is starting.

**Columns/Parameters Involved**: `Monitor.MonitorJobs.StatusID`, `msdb.dbo.sysjobs`

**Rules**:
- Triggered when Monitor.MonitorJobs has StatusID IN (-2, -1) for JobName='BSLJobs'
- Only acts if the jobs are currently enabled (checks msdb.dbo.sysjobs.enabled=1)
- Calls msdb.dbo.sp_update_job to disable both jobs (enabled=0)
- Calls msdb.dbo.sp_stop_job to immediately stop any running execution
- On AG secondary replicas: updates Monitor.SynMonitorJobs SET StatusID=-2, StopJobs=GETDATE()
- Wrapped in explicit transaction with TRY/CATCH (THROW on error)

### 2.2 Re-enable BSL Jobs (Split Complete)

**What**: Re-enables BSL jobs after the stock split is finalized.

**Columns/Parameters Involved**: `Monitor.MonitorJobs.StatusID`, `msdb.dbo.sysjobs`

**Rules**:
- Triggered when Monitor.MonitorJobs has StatusID IN (1, 2) for JobName='BSLJobs'
- Only acts if the jobs are currently disabled (checks msdb.dbo.sysjobs.enabled != 1)
- Calls msdb.dbo.sp_update_job to enable both jobs (enabled=1)
- On AG secondary replicas: updates Monitor.SynMonitorJobs SET StatusID=2, StartJobs=GETDATE()
- Wrapped in explicit transaction with TRY/CATCH (THROW on error)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has **no parameters**. It reads its control state from Monitor.MonitorJobs.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Monitor.MonitorJobs | Read | Reads job control state (StatusID for 'BSLJobs') |
| (UPDATE) | Monitor.SynMonitorJobs | Write | Updates synchronized job state on AG secondary replicas |
| (EXEC) | msdb.dbo.sp_update_job | System procedure | Enables/disables SQL Agent jobs |
| (EXEC) | msdb.dbo.sp_stop_job | System procedure | Immediately stops running SQL Agent jobs |
| (SELECT) | sys.dm_hadr_database_replica_states | DMV | Checks if running on AG secondary replica |
| (SELECT) | sys.availability_replicas | DMV | Checks AG replica availability mode |
| (SELECT) | msdb.dbo.sysjobs | System table | Checks current job enabled state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent job) | N/A | Scheduled execution | Likely called by a monitoring/orchestration job during split events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DisableBslJobForSplit (procedure)
+-- Monitor.MonitorJobs (table)
+-- Monitor.SynMonitorJobs (table)
+-- msdb.dbo.sysjobs (system table)
+-- msdb.dbo.sp_update_job (system proc)
+-- msdb.dbo.sp_stop_job (system proc)
+-- sys.dm_hadr_database_replica_states (DMV)
+-- sys.availability_replicas (DMV)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Monitor.MonitorJobs | Table | Control state for BSL job management |
| Monitor.SynMonitorJobs | Table | Synchronized replica job state |
| msdb.dbo.sysjobs | System table | Current job enabled status |
| msdb.dbo.sp_update_job | System procedure | Enable/disable jobs |
| msdb.dbo.sp_stop_job | System procedure | Stop running jobs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: The procedure checks for Always On AG secondary replicas before updating Monitor.SynMonitorJobs, ensuring cross-replica synchronization only occurs when appropriate. Both enable and disable paths use explicit transactions. The job names are hardcoded strings.

---

## 8. Sample Queries

### 8.1 Check current BSL job control state

```sql
SELECT  JobName, StatusID, StopJobs, StartJobs, StatusDescription
FROM    Monitor.MonitorJobs WITH (NOLOCK)
WHERE   JobName = 'BSLJobs';
```

### 8.2 Check SQL Agent job status

```sql
SELECT  name, enabled, date_modified
FROM    msdb.dbo.sysjobs
WHERE   name LIKE '%BSL%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: N/A, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DisableBslJobForSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DisableBslJobForSplit.sql*
