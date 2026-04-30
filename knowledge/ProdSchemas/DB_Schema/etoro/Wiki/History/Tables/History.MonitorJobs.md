# History.MonitorJobs

> SQL Server temporal history table automatically maintained by the database engine, recording every past state of Monitor.MonitorJobs - the control table that tracks whether critical SQL Agent jobs (primarily BSL jobs) are enabled or disabled.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (ValidTo, ValidFrom) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo ASC, ValidFrom ASC) |

---

## 1. Business Meaning

History.MonitorJobs is the temporal history backing table for Monitor.MonitorJobs. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in the live table are updated.

Monitor.MonitorJobs has a single row (ID=1, JobName="BSLJobs") that controls whether the BSL (Bonus Safety Level) SQL Agent jobs are enabled or disabled. This control mechanism is used during stock split processing: when `Trade.ActivateSplit` runs (adjusting stock prices and positions), it calls `Trade.DisableBslJobForSplit` to temporarily pause BSL execution, preventing false alarms caused by price adjustments mid-split. After the split completes, BSL jobs are re-enabled.

With 312 history rows, this table records a complete audit trail of every enable/disable cycle for BSL jobs, including the exact timestamps of each state change.

**Architecture note**: `Monitor.SynMonitorJobs` is a synonym pointing to `[AO-REAL-DB].[etoro].[Monitor].[MonitorJobs]` on the Always On primary replica. `Trade.DisableBslJobForSplit` updates via this synonym (to route writes to the primary), but only when the current server is confirmed to be a secondary replica (checked via `sys.dm_hadr_database_replica_states`). This allows secondary replicas to trigger primary writes via the synonym while primaries write directly.

---

## 2. Business Logic

### 2.1 Two-Step State Transition - Request Then Confirm

**What**: The BSL job status changes follow a two-step pattern: a "requested" state is set first, then confirmed once the SQL Agent job actions complete. This prevents race conditions where the state appears changed before the actual SQL Agent job is stopped/started.

**Columns/Parameters Involved**: `StatusID`, `StatusDescription`, `StopJobs`, `StartJobs`

**Rules**:
- StatusID=1 ("Req to Enabled Jobs"): disable request acknowledged, enablement requested. SQL Agent jobs will be started.
- StatusID=2 ("Jobs Enabled"): confirmation that SQL Agent jobs are now running. StartJobs = getdate() at confirmation time.
- StatusID=-1 ("Req to Disabled Jobs"): disable requested. SQL Agent jobs will be stopped.
- StatusID=-2 ("Jobs Disabled"): confirmation that SQL Agent jobs are stopped. StopJobs = getdate() at confirmation time.
- Trade.DisableBslJobForSplit reads Monitor.MonitorJobs (live table, not synonym) to check current status, then writes via Monitor.SynMonitorJobs (primary replica)
- StatusID -1 and -2 together = "disabled state" (jobs blocked during split processing)
- StatusID 1 and 2 together = "enabled state" (normal operation)

**Diagram**:
```
Trade.ActivateSplit called for a stock split:
  --> Trade.DisableBslJobForSplit executes:
      Check Monitor.MonitorJobs: StatusID IN (-2,-1)? -> Jobs already disabled, re-enable them:
        EXEC msdb.sp_update_job 'BSL- RunBSLProcedures', @enabled=1
        UPDATE Monitor.SynMonitorJobs SET StatusID=2, StartJobs=getdate()
          --> temporal history: row with StatusID=1 archived with ValidTo=now

      Check Monitor.MonitorJobs: StatusID IN (1,2)? -> Jobs currently enabled, disable them:
        EXEC msdb.sp_update_job 'BSL- RunBSLProcedures', @enabled=0
        UPDATE Monitor.SynMonitorJobs SET StatusID=-2, StopJobs=getdate()
          --> temporal history: row with StatusID=1 (or -1) archived with ValidTo=now
```

### 2.2 Always On Replica Write Routing

**What**: The synonym Monitor.SynMonitorJobs enables secondary replicas to update the control table on the primary by routing UPDATE statements through a linked server/synonym pointing to the primary replica.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo` (temporal)

**Rules**:
- `Monitor.SynMonitorJobs` -> `[AO-REAL-DB].[etoro].[Monitor].[MonitorJobs]` (linked server pointing to primary)
- Secondary replicas cannot write to Monitor.MonitorJobs directly (Always On secondary is read-only by default)
- Trade.DisableBslJobForSplit checks `sys.dm_hadr_database_replica_states` to detect if running on a secondary; if so, it uses the synonym for writes
- This is why temporal history is recorded: every write through the synonym triggers temporal versioning on the primary, which archives the old state to this History table

---

## 3. Data Overview

312 rows in test environment. Only one job monitored (JobName="BSLJobs", ID=1).

| ID | JobName | StatusID | StatusDescription | StopJobs | StartJobs | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | BSLJobs | -2 | Jobs Disabled | 2025-09-01 09:37:10 | 2025-09-01 08:45:55 | 2025-09-01 09:37:10 | 2025-09-01 09:39:07 | Jobs were disabled for ~2 minutes (09:37:10 to 09:39:07). Likely during a stock split. |
| 1 | BSLJobs | -1 | Req to Disabled Jobs | 2025-09-01 09:37:07 | 2025-09-01 08:45:55 | 2025-09-01 09:37:07 | 2025-09-01 09:37:10 | Request-to-disable state lasted only 3 seconds before confirmation. |
| 1 | BSLJobs | 1 | Req to Enabled Jobs | 2025-09-01 08:44:00 | 2025-09-01 08:45:55 | 2025-09-01 08:45:55 | 2025-09-01 09:37:07 | Jobs were in "requested enable" state from 08:45 to 09:37 (~51 minutes active). |

**StatusID distribution**: -1=91 rows (29.2%), -2=89 rows (28.5%), 1=88 rows (28.2%), 2=44 rows (14.1%).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | The monitor job configuration row ID. Only ID=1 exists (JobName="BSLJobs"). Matches Monitor.MonitorJobs.ID (clustered PK on the live table). In the history table, multiple rows share the same ID as each state change creates a new history entry. |
| 2 | JobName | varchar(500) | YES | - | CODE-BACKED | The logical job group name. Currently only "BSLJobs" exists, controlling the BSL (Bonus Safety Level) SQL Agent job group. varchar(500) allows for future additional job monitors. NULL theoretically possible but never observed. |
| 3 | StopJobs | datetime | YES | - | CODE-BACKED | Local server timestamp when the disable confirmation was last executed (SET StopJobs=getdate() when StatusID transitions to -2). NULL when the jobs have never been disabled or when this row represents an "enabled" state snapshot. Records the exact moment BSL jobs were stopped for audit purposes. |
| 4 | StartJobs | datetime | YES | - | CODE-BACKED | Local server timestamp when the enable confirmation was last executed (SET StartJobs=getdate() when StatusID transitions to 2). NULL for the initial row or when not yet confirmed. Records the exact moment BSL jobs were restarted after a disable period. |
| 5 | StatusID | int | YES | - | CODE-BACKED | The BSL job group status at the time this history row was current: 1="Req to Enabled Jobs" (enable requested), 2="Jobs Enabled" (confirmed enabled), -1="Req to Disabled Jobs" (disable requested), -2="Jobs Disabled" (confirmed disabled). NULL theoretically possible (column is nullable) but not observed. |
| 6 | StatusDescription | varchar(50) | YES | - | CODE-BACKED | Human-readable description of the StatusID value. Stored as a denormalized string alongside StatusID. Values observed: "Req to Disabled Jobs" (-1), "Jobs Disabled" (-2), "Req to Enabled Jobs" (1), "Jobs Enabled" (2). |
| 7 | ValidFrom | datetime2(2) | NO | - | CODE-BACKED | UTC timestamp when this state became current in Monitor.MonitorJobs. Populated automatically by SQL Server SYSTEM_VERSIONING as GENERATED ALWAYS AS ROW START. datetime2(2) provides centisecond precision. The clustered index leads with ValidTo for temporal query optimization. |
| 8 | ValidTo | datetime2(2) | NO | - | CODE-BACKED | UTC timestamp when this state was superseded and archived here. Populated automatically by SQL Server SYSTEM_VERSIONING as GENERATED ALWAYS AS ROW END. For all rows in History, this is always a real past timestamp. The interval [ValidFrom, ValidTo) is the period during which this job status was active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JobName="BSLJobs" | msdb SQL Agent jobs | Implicit | Controls "etoro - SecondaryJob - BSL- RunBSLProcedures" and "etoro - SecondaryJob - Check if BSLRealFunds is null" SQL Agent jobs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitor.MonitorJobs | SYSTEM_VERSIONING | Writer (automatic) | Live table's SYSTEM_VERSIONING = ON makes SQL Server automatically archive old states here |
| Monitor.LastTimeBslJobExecute_DataDog | (reference) | Reader | DataDog monitoring procedure that reads BSL job status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MonitorJobs (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Monitor.MonitorJobs (live temporal table) via SYSTEM_VERSIONING
  - Writes triggered by: Trade.DisableBslJobForSplit (via Monitor.SynMonitorJobs -> primary replica)
    - Called by: Trade.ActivateSplit (stock split processing)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitor.MonitorJobs | Table | Live temporal table - this is its HISTORY_TABLE |
| Monitor.SynMonitorJobs | Synonym | Points to [AO-REAL-DB].[etoro].[Monitor].[MonitorJobs] - routes secondary writes to primary |
| Monitor.LastTimeBslJobExecute_DataDog | Stored Procedure | Reader - DataDog monitoring for BSL job status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MonitorJobs | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Note: Standard temporal history table index pattern (ValidTo, ValidFrom) enabling efficient point-in-time queries. PAGE compression applied. On [DICTIONARY] filegroup (same as live table).

### 7.2 Constraints

No constraints on history table. Live table constraints (for reference):
- PRIMARY KEY CLUSTERED on ID, FILLFACTOR=95

---

## 8. Sample Queries

### 8.1 Full BSL job enable/disable history in chronological order

```sql
-- Combine live + history for complete timeline
SELECT 'History' AS Source, ID, JobName, StatusID, StatusDescription,
       StopJobs, StartJobs, ValidFrom, ValidTo
FROM [History].[MonitorJobs] WITH (NOLOCK)
WHERE JobName = 'BSLJobs'
UNION ALL
SELECT 'Current', ID, JobName, StatusID, StatusDescription,
       StopJobs, StartJobs, ValidFrom, ValidTo
FROM [Monitor].[MonitorJobs] WITH (NOLOCK)
WHERE JobName = 'BSLJobs'
ORDER BY ValidFrom ASC
```

### 8.2 Find all disable periods (duration BSL jobs were off)

```sql
SELECT
    disable_req.ID,
    disable_req.ValidFrom AS DisableRequestedAt,
    enable_after.ValidFrom AS ReenabledAt,
    DATEDIFF(SECOND, disable_req.ValidFrom, enable_after.ValidFrom) AS DisabledForSec
FROM [History].[MonitorJobs] disable_req WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 ValidFrom
    FROM [History].[MonitorJobs] WITH (NOLOCK)
    WHERE ID = disable_req.ID
      AND StatusID IN (1, 2)
      AND ValidFrom > disable_req.ValidFrom
    ORDER BY ValidFrom ASC
) enable_after
WHERE disable_req.StatusID = -2   -- Jobs Disabled confirmation
ORDER BY disable_req.ValidFrom DESC
```

### 8.3 Point-in-time query - what was the BSL job status at a specific time

```sql
SELECT ID, JobName, StatusID, StatusDescription, StopJobs, StartJobs
FROM [Monitor].[MonitorJobs]
FOR SYSTEM_TIME AS OF '2025-09-01 09:00:00'
WHERE JobName = 'BSLJobs'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.DisableBslJobForSplit) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MonitorJobs | Type: Table | Source: etoro/etoro/History/Tables/History.MonitorJobs.sql*
