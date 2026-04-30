# Billing.ScheduledTaskConfig

> Configuration registry for deposit-level scheduled tasks - defines retry limits, batch sizes, and tracks last run time for each of the 8 post-deposit processing pipelines.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | TaskID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup, PAGE COMPRESSION) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.ScheduledTaskConfig is the control table for the post-deposit scheduled task framework. When a deposit is created (via `Billing.DepositAdd`), multiple downstream tasks are queued in `Billing.ScheduledTaskState` to handle the asynchronous post-processing pipeline: AppsFlyer attribution events, tracking pixels, RabbitMQ FTD messages, monitor processing, and more.

Each task type has a row in this table defining how it should be executed: MaxRetries (how many times to retry before giving up), MaxEntitiesToFetch (batch size per scheduler run), and LastProcessDate (updated each time the scheduler polls this task). `GetScheduledTaskConfig` both reads the config and stamps LastProcessDate in one atomic update.

**8 rows** - 6 currently active (LastProcessDate today), 2 inactive (TaskID=4 last ran 2017-07-12, TaskID=6 last ran 2023-08-03).

---

## 2. Business Logic

### 2.1 Heartbeat via Config Read

**What**: `GetScheduledTaskConfig` uses an UPDATE...OUTPUT pattern to both stamp the heartbeat timestamp and return the configuration in a single operation.

**Rules**:
- `UPDATE ScheduledTaskConfig SET LastProcessDate=GetDate() OUTPUT Inserted.* WHERE TaskID=@TaskID`
- Every time a scheduler worker starts processing, it calls this and gets back MaxRetries and MaxEntitiesToFetch
- LastProcessDate serves as both the configuration read time and a liveness heartbeat
- If LastProcessDate is old (days/years), the task is no longer running

### 2.2 Task Registry

**What**: The 8 TaskIDs correspond to distinct post-deposit processing pipelines.

**Current task registry** (inferred from procedure names and data):

| TaskID | Likely Purpose | Max Retries | MaxEntitiesToFetch | Active? |
|--------|---------------|-------------|--------------------|----|
| 1 | AppsFlyer attribution events | 3 | 1000 | Yes |
| 2 | RabbitMQ FTD events | 4 | 500 | Yes |
| 3 | RabbitMQ FTD (variant/remote) | 3 | 1000 | Yes |
| 4 | (Unknown - legacy) | 3 | 1000 | No (last 2017) |
| 5 | Monitor processing | 3 | 1 | Yes (1 at a time) |
| 6 | Post-WTF (PostWithdrawToFunding) | 3 | 500 | No (last 2023-08) |
| 7 | Deposit entities processing | 4 | 500 | Yes |
| 8 | Mixpanel events | 3 | 1000 | Yes |

---

## 3. Data Overview

| TaskID | MaxRetries | MaxEntitiesToFetch | LastProcessDate | Active |
|--------|-----------|-------------------|----------------|--------|
| 1 | 3 | 1000 | 2026-03-17 | Yes |
| 2 | 4 | 500 | 2026-03-17 | Yes |
| 3 | 3 | 1000 | 2026-03-17 | Yes |
| 4 | 3 | 1000 | 2017-07-12 | No |
| 5 | 3 | 1 | 2026-03-17 | Yes |
| 6 | 3 | 500 | 2023-08-03 | No |
| 7 | 4 | 500 | 2026-03-17 | Yes |
| 8 | 3 | 1000 | 2026-03-17 | Yes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TaskID | INT | NO | - | CODE-BACKED | Primary key and task identifier. References tasks in Billing.ScheduledTaskState(TaskID). Values 1-8 represent different post-deposit processing pipelines. Not an identity column - values are manually assigned. |
| 2 | MaxRetries | INT | YES | 0 | CODE-BACKED | Maximum number of retry attempts for failed task executions. Default=0 (no retries). Range: 3-4 in current data. When a task entity fails, it can be retried up to MaxRetries times before being permanently marked as failed. |
| 3 | MaxEntitiesToFetch | INT | YES | 0 | CODE-BACKED | Batch size for each scheduler run - how many pending entities to fetch and process at once. Default=0. Range: 1 (single-entity for TaskID=5) to 1000. Passed to `GetScheduledTask*` procedures as @MaxEntitiesToFetch. Controls throughput/load. |
| 4 | LastProcessDate | DATETIME | YES | - | CODE-BACKED | Timestamp of the last time `GetScheduledTaskConfig` was called for this TaskID. Updated by the UPDATE...OUTPUT statement in GetScheduledTaskConfig (uses GetDate() - local time, not UTC). Serves as a liveness heartbeat. NULL means the task has never been polled via this mechanism. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. TaskID values reference the same TaskID in Billing.ScheduledTaskState implicitly.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetScheduledTaskConfig | TaskID | MODIFIER + READER | Stamps LastProcessDate and returns MaxRetries, MaxEntitiesToFetch for the scheduler |

---

## 6. Dependencies

```
Billing.ScheduledTaskConfig (table) - no dependencies
```

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_ScheduledTaskConfig | CLUSTERED PK | TaskID ASC | - | - | Active (PAGE COMPRESSION) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_ScheduledTaskConfig | PRIMARY KEY CLUSTERED | TaskID must be unique |
| Df_Billing_ScheduledTaskConfig_MaxRetries | DEFAULT | MaxRetries defaults to 0 on INSERT |
| Df_Billing_ScheduledTaskConfig_MaxEntitiesToFetch | DEFAULT | MaxEntitiesToFetch defaults to 0 on INSERT |

---

## 8. Sample Queries

### 8.1 View all task configurations with activity status

```sql
SELECT
    TaskID,
    MaxRetries,
    MaxEntitiesToFetch,
    LastProcessDate,
    DATEDIFF(day, LastProcessDate, GETUTCDATE()) AS DaysSinceLastRun,
    CASE
        WHEN DATEDIFF(day, LastProcessDate, GETUTCDATE()) < 1 THEN 'Active'
        WHEN DATEDIFF(day, LastProcessDate, GETUTCDATE()) < 7 THEN 'Recent'
        ELSE 'Inactive/Stopped'
    END AS ActivityStatus
FROM [Billing].[ScheduledTaskConfig] WITH (NOLOCK)
ORDER BY TaskID
```

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.2/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.ScheduledTaskConfig | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ScheduledTaskConfig.sql*
