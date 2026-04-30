# Billing.GetScheduledTaskConfig

> Atomically stamps the scheduler heartbeat and returns task configuration: UPDATE ScheduledTaskConfig.LastProcessDate=NOW OUTPUT TaskID, MaxRetries, MaxEntitiesToFetch WHERE TaskID=@TaskID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TaskID; returns one row from Billing.ScheduledTaskConfig via UPDATE...OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskConfig` is the scheduler initialization call for the post-deposit processing framework. Before a scheduler worker begins fetching deposit work items, it calls this procedure with its TaskID to: (1) record its startup time as a heartbeat in `LastProcessDate`, and (2) retrieve its operational parameters - how many items to fetch per batch (`MaxEntitiesToFetch`) and how many retries are allowed (`MaxRetries`).

The UPDATE...OUTPUT pattern achieves both operations atomically in a single round-trip. The `LastProcessDate` serves a dual purpose: configuration read timestamp and scheduler liveness indicator. Monitoring tools check this date to detect stuck schedulers - if LastProcessDate is hours or days old, the scheduler for that TaskID may have stopped.

Created 07 Sep 2016 (Geri Reshef, ticket 40729) as part of the initial ScheduledTask framework.

---

## 2. Business Logic

### 2.1 Heartbeat + Config Read in One Operation

**What**: A single UPDATE...OUTPUT statement both records the scheduler's "I started" timestamp and returns its config.

**Rules**:
- `UPDATE Billing.ScheduledTaskConfig SET LastProcessDate = GetDate() OUTPUT Inserted.TaskID, Inserted.MaxRetries, Inserted.MaxEntitiesToFetch WHERE TaskID = @TaskID`
- OUTPUT clause returns the values as they were after the UPDATE (Inserted.*)
- Returns 1 row if TaskID exists, 0 rows if not
- `GetDate()` uses local server time; most other billing procedures use `GetUTCDate()` - minor timezone inconsistency

### 2.2 Task Registry Context

**What**: The 8 TaskIDs correspond to distinct post-deposit notification/analytics pipelines.

**Known mappings** (from ScheduledTaskConfig data and procedure names):

| TaskID | Procedure | Pipeline |
|--------|-----------|---------|
| 1 | GetScheduledTaskAppsFlyerEntities | AppsFlyer attribution events |
| 2 | GetScheduledTaskRabbitMqFtdEntities | RabbitMQ FTD notification |
| 3 | GetScheduledTaskPixelEntities | Tracking pixel fire |
| 4 | GetScheduledTaskMixpanelEventEntities | Mixpanel analytics |
| 7 | GetScheduledTaskDepositEntities | General deposit entity processing |
| 8 | GetScheduledTaskMonitorProcessingEntities | Payment monitor alerting |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TaskID | INT | NO | - | CODE-BACKED | Identifies which task configuration to load and stamp. FK to `Billing.ScheduledTaskConfig.TaskID`. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | TaskID | INT | NO | - | CODE-BACKED | Echoes the TaskID just updated. From `Billing.ScheduledTaskConfig`. |
| 3 | MaxRetries | INT | YES | - | CODE-BACKED | Maximum number of retry attempts the scheduler should make before marking a work item as failed. Typical values: 3 or 4. |
| 4 | MaxEntitiesToFetch | INT | YES | - | CODE-BACKED | Maximum batch size for this scheduler run. Passed as @MaxEntitiesToFetch to the corresponding `GetScheduledTask*Entities` procedure. Values range from 1 (monitor, processes 1 at a time) to 1000. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TaskID | Billing.ScheduledTaskConfig | UPDATE...OUTPUT | Stamps heartbeat and returns task configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduled task workers (all 8 pipelines) | @TaskID | EXEC | Initialization call before fetching a batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskConfig (procedure)
+-- Billing.ScheduledTaskConfig (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskConfig | Table | UPDATE LastProcessDate; OUTPUT TaskID, MaxRetries, MaxEntitiesToFetch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler workers (all 8 task types) | External | Called on each scheduler cycle to get batch size and retry config |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UPDATE...OUTPUT | Design | Atomic heartbeat + config read in one operation; no separate SELECT needed |
| GetDate() (not UTC) | Minor inconsistency | Uses local server time for LastProcessDate; most billing procs use GetUTCDate() |
| Returns 0 rows for unknown TaskID | Edge case | If @TaskID not in ScheduledTaskConfig, nothing is updated and 0 rows returned |

---

## 8. Sample Queries

### 8.1 Get config for AppsFlyer scheduler (TaskID=1)
```sql
EXEC Billing.GetScheduledTaskConfig @TaskID = 1;
-- Returns: TaskID=1, MaxRetries=3, MaxEntitiesToFetch=1000
-- Also stamps LastProcessDate = NOW in Billing.ScheduledTaskConfig
```

### 8.2 Check all scheduler heartbeats
```sql
SELECT TaskID, MaxRetries, MaxEntitiesToFetch, LastProcessDate,
       DATEDIFF(MINUTE, LastProcessDate, GETDATE()) AS MinutesSinceLastRun
FROM Billing.ScheduledTaskConfig WITH (NOLOCK)
ORDER BY TaskID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskConfig | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskConfig.sql*
