# Trade.FeeNightProcessJobsLogs

> Tracking table for the modular overnight fee processing jobs, recording the last successful execution time for each job partition.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | JobName (PK, CLUSTERED) |
| **Partition** | No (stored on DICTIONARY filegroup) |
| **Indexes** | 2 active |

---

## 1. Business Meaning

This table tracks the execution status of the overnight fee processing pipeline, which is split into multiple parallel SQL Agent jobs. Each row represents one job partition (identified by Mod number 0-9 plus a "Data Preparation" step). The LastExecuteSuccessfully timestamp records when each job last completed successfully, enabling the orchestration procedure to determine which jobs have finished and whether the full pipeline is complete.

Without this table, the fee processing orchestrator (Trade.ExecuteAllFeeJobs) would have no way to track which parallel fee jobs have completed. The Mod-based partitioning allows 10 parallel fee calculation jobs to process different customer segments (CID % 10 = Mod) simultaneously, with the orchestrator monitoring this table to know when all are done.

Rows are updated by Trade.PayForFeeProcess upon successful completion of each job. Trade.ExecuteAllFeeJobs reads the table to track overall pipeline progress. The table has a fixed set of 11 rows (Mod -1 through 9) that persist between runs with their timestamps being updated.

---

## 2. Business Logic

### 2.1 Modular Fee Processing Pipeline

**What**: Overnight fee processing is partitioned into 10 parallel jobs by customer CID modulo, plus a data preparation step.

**Columns/Parameters Involved**: `JobName`, `Mod`, `LastExecuteSuccessfully`

**Rules**:
- Mod = -1: "Data Preparation" step that runs first, preparing the fee data before individual jobs execute
- Mod 0-9: "etoro - NightFeeProcess N" - each processes customers where CID % 10 = Mod
- The unique index on Mod ensures exactly one row per partition
- LastExecuteSuccessfully is updated only on successful completion, allowing retry detection

---

## 3. Data Overview

| JobName | Mod | LastExecuteSuccessfully | Meaning |
|---------|-----|------------------------|---------|
| Data Preparation | -1 | 2026-01-29 12:33:58 | Initial data preparation step completed - prepares fee calculation data before parallel jobs run |
| etoro - NightFeeProcess 0 | 0 | 2026-01-29 12:34:00 | Fee job for CIDs where CID%10=0 completed successfully |
| etoro - NightFeeProcess 5 | 5 | 2026-01-29 12:33:59 | Fee job for CIDs where CID%10=5 completed - among the fastest to finish |
| etoro - NightFeeProcess 3 | 3 | 2026-01-29 12:34:40 | Fee job for CIDs where CID%10=3 - took longest (~42 seconds after prep) |
| etoro - NightFeeProcess 1 | 1 | 2026-01-29 12:34:34 | Fee job for CIDs where CID%10=1 - second longest running partition |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobName | varchar(100) | NO | - | CODE-BACKED | SQL Agent job name identifying this fee processing partition. Fixed values: "Data Preparation" and "etoro - NightFeeProcess 0" through "etoro - NightFeeProcess 9". Used as the primary key. |
| 2 | Mod | int | NO | - | CODE-BACKED | Partition number for the fee job. -1 = Data Preparation step, 0-9 = customer CID modulo partitions (CID % 10 = Mod). Has a unique index ensuring one row per partition. |
| 3 | LastExecuteSuccessfully | datetime | NO | - | CODE-BACKED | Timestamp of the last successful execution of this job partition. Updated by Trade.PayForFeeProcess on completion. Used by Trade.ExecuteAllFeeJobs to track pipeline progress. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExecuteAllFeeJobs | - | Reader | Reads job completion status to orchestrate the fee pipeline |
| Trade.PayForFeeProcess | - | Writer | Updates LastExecuteSuccessfully on job completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecuteAllFeeJobs | Stored Procedure | Reads to monitor pipeline progress |
| Trade.PayForFeeProcess | Stored Procedure | Writes completion timestamps |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | JobName ASC | - | - | Active |
| IX_FeeNightProcessJobsLogs_Mod | NC UNIQUE | Mod ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | One row per job name |
| IX_FeeNightProcessJobsLogs_Mod | UNIQUE | One row per Mod partition number |

---

## 8. Sample Queries

### 8.1 Check if all fee jobs completed for today
```sql
SELECT JobName, Mod, LastExecuteSuccessfully
FROM   Trade.FeeNightProcessJobsLogs WITH (NOLOCK)
ORDER BY Mod
```

### 8.2 Find jobs that haven't run recently
```sql
SELECT JobName, Mod, LastExecuteSuccessfully,
       DATEDIFF(HOUR, LastExecuteSuccessfully, GETDATE()) AS HoursSinceLastRun
FROM   Trade.FeeNightProcessJobsLogs WITH (NOLOCK)
WHERE  DATEDIFF(HOUR, LastExecuteSuccessfully, GETDATE()) > 24
ORDER BY LastExecuteSuccessfully
```

### 8.3 Check which job took longest in the last run
```sql
SELECT JobName, Mod, LastExecuteSuccessfully
FROM   Trade.FeeNightProcessJobsLogs WITH (NOLOCK)
WHERE  Mod >= 0
ORDER BY LastExecuteSuccessfully DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FeeNightProcessJobsLogs | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FeeNightProcessJobsLogs.sql*
