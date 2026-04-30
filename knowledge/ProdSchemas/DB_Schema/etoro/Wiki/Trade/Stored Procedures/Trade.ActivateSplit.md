# Trade.ActivateSplit

> Orchestrates stock split activation: disables BSL (Business/Secondary Logic) jobs via Monitor.SynMonitorJobs, waits for confirmation, executes Trade.ActivateSplit_Inner, waits for price propagation, re-enables BSL jobs, and sends a warning email if jobs fail to re-enable.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (references History.SplitRatio.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ActivateSplit is the top-level orchestrator for stock split processing. A stock split requires exclusive access to position and pricing data, so this procedure manages the lifecycle of disabling and re-enabling critical background jobs (BSL — Business/Secondary Logic) that might interfere with the split operation.

The workflow:
1. **Request BSL job disable**: Sets Monitor.SynMonitorJobs.StatusID = -1 (request to disable) for 'BSLJobs'
2. **Wait for confirmation**: Polls every 2 minutes until StatusID = -2 (confirmed disabled), with a 4-minute timeout
3. **Execute split**: Calls Trade.ActivateSplit_Inner with the split parameters
4. **Wait for price propagation**: WAITFOR DELAY 2 minutes for price feeds to reflect split-adjusted prices
5. **Re-enable BSL jobs**: Sets Monitor.SynMonitorJobs.StatusID = 1 (request to enable)
6. **Verify re-enablement**: After 3 minutes, checks if the BSL job is actually enabled in msdb.dbo.sysjobs
7. **Alert on failure**: If BSL job failed to re-enable, sends a warning email via sp_send_dbmail

The error handler always re-enables BSL jobs even if the split fails, ensuring the system doesn't remain in a degraded state.

---

## 2. Business Logic

### 2.1 BSL Job Lifecycle Management

**What**: Coordinates job disable/enable around the split operation.

**Rules**:
- StatusID = -1: Request to disable jobs
- StatusID = -2: Jobs confirmed disabled (set by monitoring agent)
- StatusID = 1: Request to enable jobs
- 4-minute timeout on disable confirmation → RAISERROR if exceeded
- CATCH block re-enables jobs to prevent system lockout on failure

### 2.2 Price Propagation Wait

**What**: Allows time for price feeds to update with split-adjusted prices.

**Rules**:
- 2-minute WAITFOR after ActivateSplit_Inner completes
- 3-minute WAITFOR after re-enabling BSL jobs
- Total delay: ~5 minutes of waiting after split execution

### 2.3 Failure Alerting

**What**: Sends email alert if BSL jobs fail to re-enable.

**Rules**:
- Checks msdb.dbo.sysjobs for enabled=1 AND name='etoro - SecondaryJob - BSL- RunBSLProcedures'
- If not found: sends email to tradingbackend@etoro.com and DBA@etoro.com
- Subject: "Warninig!!!!! Split Ended Sucssefully, but BSl job failed to enable, call DBA"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | VERIFIED | References History.SplitRatio.ID. Identifies which stock split to activate. Passed to Trade.ActivateSplit_Inner. |
| 2 | @ShouldSplitHistory | TINYINT | YES | 0 | CODE-BACKED | When 1, also adjusts historical closed positions/orders. Passed to Trade.ActivateSplit_Inner. |
| 3 | @IsReRun | TINYINT | YES | 0 | CODE-BACKED | When 1, allows re-execution of a partially completed split. Passed to Trade.ActivateSplit_Inner. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Monitor.SynMonitorJobs | UPDATE | Disables/enables BSL jobs |
| FROM | Monitor.SynMonitorJobs | SELECT | Polls for disable confirmation |
| EXEC | Trade.ActivateSplit_Inner | EXEC | Executes the actual split logic |
| FROM | msdb.dbo.sysjobs | SELECT | Verifies BSL job re-enablement |
| EXEC | msdb.dbo.sp_send_dbmail | EXEC | Sends failure alert email |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called manually by DBA or scheduled job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ActivateSplit (procedure)
+-- Monitor.SynMonitorJobs (table)
+-- Trade.ActivateSplit_Inner (procedure)
+-- msdb.dbo.sysjobs (system table)
+-- msdb.dbo.sp_send_dbmail (system procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Monitor.SynMonitorJobs | Table | UPDATE/SELECT - BSL job lifecycle |
| Trade.ActivateSplit_Inner | Procedure | EXEC - actual split logic |
| msdb.dbo.sysjobs | System Table | SELECT - job verification |
| msdb.dbo.sp_send_dbmail | System Procedure | EXEC - failure alerting |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | Called manually or by job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 4-minute timeout | Safety | Fails if BSL jobs don't disable within 4 minutes |
| Always re-enable | Safety | CATCH block re-enables BSL jobs on any failure |
| Email alert | Monitoring | Sends email if BSL job fails to re-enable |

---

## 8. Sample Queries

### 8.1 Check BSL job status

```sql
SELECT  JobName, StatusID, StatusDescription, StopJobs, StartJobs
FROM    Monitor.SynMonitorJobs
WHERE   JobName = 'BSLJobs';
```

### 8.2 Execute stock split

```sql
EXEC Trade.ActivateSplit @SplitID = 42, @ShouldSplitHistory = 1, @IsReRun = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ActivateSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ActivateSplit.sql*
