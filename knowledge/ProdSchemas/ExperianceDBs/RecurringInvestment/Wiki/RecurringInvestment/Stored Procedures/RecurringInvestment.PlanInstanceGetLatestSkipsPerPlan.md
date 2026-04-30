# RecurringInvestment.PlanInstanceGetLatestSkipsPerPlan

> Returns the latest N completed (non-InProgress) past instances for a given plan, used to analyze skip and failure patterns.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID + @InstanceCount input, returns ranked past instances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the most recent completed instances of a specific plan, ordered by NextOrderDate descending. It is designed to analyze patterns in recent execution cycles, particularly to detect repeated skips, failures, or soft declines that may warrant plan cancellation or user notification.

The business need is to detect degrading plan health. For example, if the last 3 instances were all skipped due to soft declines, the system may choose to cancel the plan or notify the user. Without this procedure, the application would need to load all instances and filter/sort in memory. Created per EDGE-4582 (Nilly Ron, 5/12/24).

The procedure excludes future instances (NextOrderDate >= tomorrow) and instances still in progress (InstanceStatusID = NULL or 5). The CTE with ROW_NUMBER ensures only the top N most recent completed instances are returned.

---

## 2. Business Logic

### 2.1 Latest Completed Instance Ranking

**What**: Uses ROW_NUMBER to rank past completed instances by date, returning only the top N.

**Columns/Parameters Involved**: `@PlanID`, `@InstanceCount`, `NextOrderDate`, `InstanceStatusID`, `ROW_NUMBER()`

**Rules**:
- CTE partitions by PlanID (redundant since @PlanID is fixed, but consistent pattern) and orders by NextOrderDate DESC
- Excludes future instances: NextOrderDate < CAST(GETUTCDATE()+1 AS DATE) (before tomorrow)
- Excludes in-progress instances: InstanceStatusID IS NOT NULL AND InstanceStatusID <> 5
- Final SELECT filters RowNum <= @InstanceCount
- Results ordered by NextOrderDate DESC (most recent first)

**Diagram**:
```
All Instances for @PlanID
    |
    +-- Filter: NextOrderDate < tomorrow (past only)
    |
    +-- Filter: InstanceStatusID NOT NULL and <> 5 (completed only)
    |
    +-- ROW_NUMBER() ORDER BY NextOrderDate DESC
    |
    +-- Keep top @InstanceCount rows
    |
    v
Result: Latest N completed instances
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | ID of the plan whose instances to retrieve. |
| 2 | @InstanceCount | int | NO | - | VERIFIED | Maximum number of recent completed instances to return. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique plan instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID (matches @PlanID). |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date for this cycle. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential deposit cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit processing timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit result. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason text. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order placement date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state (never NULL or 5 in results). See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy relationship ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |
| 24 | RowNum | bigint | NO | - | CODE-BACKED | Ranking position (1 = most recent). Computed by ROW_NUMBER() OVER (PARTITION BY PlanID ORDER BY NextOrderDate DESC). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read | Source for instance data, filtered by PlanID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Skip Analysis Service | - | EXEC | Checks recent instance patterns for plan health evaluation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetLatestSkipsPerPlan (procedure)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | SELECT FROM with NOLOCK, CTE with ROW_NUMBER |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Skip/Failure Analysis Service | Background Service | Analyzes recent skip patterns per plan |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get last 3 completed instances for a plan
```sql
EXEC [RecurringInvestment].[PlanInstanceGetLatestSkipsPerPlan]
    @PlanID = 1001, @InstanceCount = 3
```

### 8.2 Check if all recent instances were skipped
```sql
-- After calling the SP, check if all returned rows have InstanceStatusID IN (3,4)
SELECT PI.InstanceID, PI.InstanceStatusID, PI.InstanceStatusReasonID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
WHERE PI.PlanID = 1001
    AND PI.NextOrderDate < CAST(GETUTCDATE()+1 AS DATE)
    AND PI.InstanceStatusID IS NOT NULL AND PI.InstanceStatusID <> 5
ORDER BY PI.NextOrderDate DESC
```

### 8.3 Count skips vs successes in recent history
```sql
;WITH Recent AS (
    SELECT PI.InstanceStatusID,
        ROW_NUMBER() OVER (ORDER BY PI.NextOrderDate DESC) AS RowNum
    FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
    WHERE PI.PlanID = 1001 AND PI.InstanceStatusID IS NOT NULL AND PI.InstanceStatusID <> 5
)
SELECT InstanceStatusID, COUNT(*) AS Cnt
FROM Recent WHERE RowNum <= 5
GROUP BY InstanceStatusID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances column definitions, instance status values |
| [EDGE-4582](https://etoro-jira.atlassian.net/browse/EDGE-4582) | Jira | Original ticket for skip pattern analysis SP |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstanceGetLatestSkipsPerPlan | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetLatestSkipsPerPlan.sql*
