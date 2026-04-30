# Trade.ExecuteAllFeeJobs

> Orchestrates the nightly fee processing pipeline by logging data preparation completion and launching 10 parallel NightFeeProcess SQL Agent jobs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Triggers jobs NightFeeProcess 0-9 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the orchestrator for the nightly overnight fee processing pipeline. After all fee data preparation work completes (rates calculated, instruments classified), this procedure records the successful preparation timestamp and launches 10 parallel SQL Agent jobs (`etoro - NightFeeProcess 0` through `etoro - NightFeeProcess 9`) that process the actual fee charges across customer positions.

The 10 parallel jobs represent a modular partitioning strategy (likely CID % 10) that distributes the fee calculation workload across parallel execution streams. This is necessary because overnight fee processing touches every open position across all customers - a workload too large for a single sequential process.

The procedure first updates `Trade.FeeNightProcessJobsLogs` with `Mod = -1` to record the data preparation completion timestamp. The `-1` Mod value distinguishes this from the per-job logs (Mod 0-9) and serves as a checkpoint indicating that fee rates and instrument configurations are ready for consumption by the fee processing jobs.

---

## 2. Business Logic

### 2.1 Data Preparation Checkpoint

**What**: Records that fee data preparation completed successfully before launching processing jobs.

**Columns/Parameters Involved**: `Trade.FeeNightProcessJobsLogs.LastExecuteSuccessfully`, `Mod = -1`

**Rules**:
- Updates the Mod=-1 record with current UTC time, serving as a "preparation complete" checkpoint
- This must happen before jobs are launched to ensure all fee rate data is ready
- The -1 sentinel distinguishes the preparation log from individual job logs (0-9)

### 2.2 Parallel Job Launch

**What**: Starts 10 SQL Agent jobs simultaneously for parallel fee processing.

**Columns/Parameters Involved**: Job names `etoro - NightFeeProcess 0` through `9`

**Rules**:
- All 10 jobs are launched via `msdb.dbo.sp_start_job` in sequence (they execute asynchronously)
- Each job likely processes customers where CID % 10 = {job number}
- Jobs run independently and in parallel after being started
- No wait/synchronization logic - this procedure fires-and-forgets all 10 jobs

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Procedure uses no inputs - all configuration is implicit in the job definitions and FeeNightProcessJobsLogs table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Trade.FeeNightProcessJobsLogs | MODIFIER | Updates Mod=-1 record with preparation completion timestamp |
| EXEC | msdb.dbo.sp_start_job | System Call | Launches 10 SQL Agent jobs for parallel fee processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | Job | Called after fee data preparation completes in the nightly pipeline |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExecuteAllFeeJobs (procedure)
+-- Trade.FeeNightProcessJobsLogs (table)
+-- msdb.dbo.sp_start_job (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeNightProcessJobsLogs | Table | UPDATE - records preparation completion timestamp |
| msdb.dbo.sp_start_job | System Procedure | Launches SQL Agent jobs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Permissions**: Comment in code notes "need to verify that user of the link server has the right permissions for execute Job" - requires appropriate permissions on msdb to start SQL Agent jobs.

---

## 8. Sample Queries

### 8.1 Run the Fee Job Orchestrator

```sql
EXEC Trade.ExecuteAllFeeJobs
```

### 8.2 Check Fee Processing Job Log Status

```sql
SELECT Mod,
       LastExecuteSuccessfully
  FROM Trade.FeeNightProcessJobsLogs WITH (NOLOCK)
 ORDER BY Mod
```

### 8.3 Check SQL Agent Job Status for NightFeeProcess Jobs

```sql
SELECT j.name,
       ja.start_execution_date,
       ja.stop_execution_date,
       ja.last_executed_step_id,
       CASE ja.last_executed_step_id WHEN 0 THEN 'Not Yet Run' ELSE 'Running/Complete' END AS Status
  FROM msdb.dbo.sysjobs j WITH (NOLOCK)
  JOIN msdb.dbo.sysjobactivity ja WITH (NOLOCK) ON j.job_id = ja.job_id
 WHERE j.name LIKE 'etoro - NightFeeProcess%'
 ORDER BY j.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExecuteAllFeeJobs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ExecuteAllFeeJobs.sql*
