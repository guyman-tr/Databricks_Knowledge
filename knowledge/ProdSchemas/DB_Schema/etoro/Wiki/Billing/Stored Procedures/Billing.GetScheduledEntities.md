# Billing.GetScheduledEntities

> Dispatcher procedure for the post-deposit scheduled task framework: routes to the correct batch-fetch SP based on TaskID, enabling the scheduler service to call a single entry point regardless of which task type is being processed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TaskID (dispatch key); returns whatever the target SP returns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetScheduledEntities is the single entry point for the post-deposit scheduled task batch-fetch framework. Instead of the scheduler service needing to know which specific procedure to call for each task type, it calls this dispatcher with a TaskID and gets routed automatically to the correct batch-fetch implementation.

The procedure exists to decouple the scheduler service from the individual task implementations. Adding a new scheduled task type only requires adding a new ELSE IF branch here (and writing the corresponding `GetScheduledTask*Entities` procedure), not changing the caller. As of the original implementation (07 Sep 2016, Geri Reshef, ticket 40729), two task types are registered:

- **TaskID=1 (AppsFlyer)**: Routes to `Billing.GetScheduledTaskAppsFlyerEntities` - claims pending post-deposit rows and returns customer attribution data for AppsFlyer mobile analytics event sending.
- **TaskID=2 (RabbitMQ FTD)**: Routes to `Billing.GetScheduledTaskRabbitMqFtdEntities` - claims pending first-time deposit rows and returns FTD data for RabbitMQ notification publishing.

The scheduler service calls this procedure on each poll cycle, passing the TaskID for the task it is running. The returned rows are then consumed to dispatch attribution events or RabbitMQ messages. The underlying SPs both use the claim-and-return pattern (atomic select + mark as In Progress) to prevent double-processing in concurrent environments.

---

## 2. Business Logic

### 2.1 TaskID Dispatch Routing

**What**: Maps integer TaskID values to concrete batch-fetch SP implementations.

**Columns/Parameters Involved**: `@TaskID`

**Rules**:
- @TaskID=1 -> `EXEC Billing.GetScheduledTaskAppsFlyerEntities` (no parameters passed - callee uses its own defaults)
- @TaskID=2 -> `EXEC Billing.GetScheduledTaskRabbitMqFtdEntities` (no parameters passed)
- Any other @TaskID value: no branch matches, procedure returns an empty result set silently
- The TaskID values correspond to `Billing.ScheduledTaskConfig.TaskID` and `Billing.ScheduledTaskState.TaskID`

**Diagram**:
```
Scheduler service polls
          |
          v
EXEC Billing.GetScheduledEntities @TaskID = {1 or 2}
          |
    +-----+------+
    |            |
  TaskID=1    TaskID=2
    |            |
    v            v
GetScheduled   GetScheduled
TaskApps       TaskRabbitMq
FlyerEntities  FtdEntities
    |            |
    v            v
AppsFlyer     RabbitMQ FTD
attribution   notification
events        events
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TaskID | INT | NO | - | CODE-BACKED | Dispatch key identifying which scheduled task pipeline to serve. 1 = AppsFlyer attribution pipeline (routes to GetScheduledTaskAppsFlyerEntities). 2 = RabbitMQ FTD notification pipeline (routes to GetScheduledTaskRabbitMqFtdEntities). Any other value results in no action and empty result. Maps to Billing.ScheduledTaskConfig.TaskID and Billing.ScheduledTaskState.TaskID. |
| - | (result set) | - | - | - | CODE-BACKED | Returns whatever the dispatched SP returns. For TaskID=1: one row per claimed deposit with AppsFlyer attribution fields (DepositID, GCID, AppsFlyerID, FunnelFromID, IPAddress, etc.). For TaskID=2: one row per claimed FTD deposit with RabbitMQ payload fields (DepositID, IsFTD, GCID, PaymentStatusID, CID, FundingTypeID, IsRefundable, MopCountry, BankName). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TaskID=1 | Billing.GetScheduledTaskAppsFlyerEntities | EXEC (call) | Delegates entirely to this SP for AppsFlyer task processing |
| @TaskID=2 | Billing.GetScheduledTaskRabbitMqFtdEntities | EXEC (call) | Delegates entirely to this SP for RabbitMQ FTD task processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler service (application) | @TaskID | EXEC | Called by the post-deposit scheduler on each poll cycle with the appropriate TaskID |
| PROD_BIadmins | EXECUTE permission | PERMISSIONS | BI admin user group has EXECUTE permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledEntities (procedure)
+-- Billing.GetScheduledTaskAppsFlyerEntities (procedure) [TaskID=1]
|     +-- Billing.ScheduledTaskState (table)
|     +-- Billing.Deposit (table)
|     +-- Customer.CustomerStatic (table)
|     +-- Customer.TrackingId (table)
|     +-- Internal.IPNumToIPAddress (function)
+-- Billing.GetScheduledTaskRabbitMqFtdEntities (procedure) [TaskID=2]
      +-- Billing.ScheduledTaskState (table)
      +-- Billing.Deposit (table)
      +-- Dictionary.CountryBin (table)
      +-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetScheduledTaskAppsFlyerEntities | Stored Procedure | EXEC for TaskID=1 - AppsFlyer attribution batch fetch |
| Billing.GetScheduledTaskRabbitMqFtdEntities | Stored Procedure | EXEC for TaskID=2 - RabbitMQ FTD batch fetch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler service (application) | External | Single entry point for all scheduled task batch-fetch operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Unhandled TaskID | Design | Any @TaskID not matching 1 or 2 silently returns nothing - no error is raised |
| No parameter pass-through | Design | Parameters like @MaxEntitiesToFetch are NOT forwarded to the callees; callees use their own defaults |

---

## 8. Sample Queries

### 8.1 Fetch AppsFlyer batch (TaskID=1)

```sql
-- Claim and retrieve next batch for AppsFlyer attribution
EXEC [Billing].[GetScheduledEntities] @TaskID = 1
-- Returns: DepositID, GCID, AppsFlyerID, FunnelFromID, IPAddress, etc.
-- Side effect: marks claimed rows as TaskState=3 (In Progress) in ScheduledTaskState
```

### 8.2 Fetch RabbitMQ FTD batch (TaskID=2)

```sql
-- Claim and retrieve next batch for RabbitMQ FTD notifications
EXEC [Billing].[GetScheduledEntities] @TaskID = 2
-- Returns: DepositID, IsFTD, GCID, PaymentStatusID, CID, FundingTypeID, IsRefundable, MopCountry, BankName
-- Side effect: marks claimed rows as TaskState=3 (In Progress) in ScheduledTaskState
```

### 8.3 Check pending scheduled task queue sizes

```sql
-- How many items are queued for each task type
SELECT
    sst.TaskID,
    stc.TaskName,
    COUNT(*) AS PendingCount
FROM [Billing].[ScheduledTaskState] sst WITH (NOLOCK)
INNER JOIN [Billing].[ScheduledTaskConfig] stc WITH (NOLOCK) ON stc.TaskID = sst.TaskID
WHERE sst.TaskState = 0  -- Pending
GROUP BY sst.TaskID, stc.TaskName
ORDER BY sst.TaskID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetScheduledEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledEntities.sql*
