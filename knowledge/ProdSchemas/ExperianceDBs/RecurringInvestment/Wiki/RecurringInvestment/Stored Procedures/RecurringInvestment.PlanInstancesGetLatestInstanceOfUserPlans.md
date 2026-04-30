# RecurringInvestment.PlanInstancesGetLatestInstanceOfUserPlans

> Returns the most recent plan instance for each active or paused plan belonging to a user.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input, returns one instance per plan (latest by NextOrderDate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a summary view of a user's recurring investment plans by returning only the most recent instance for each plan. It uses ROW_NUMBER partitioned by PlanID to rank instances by NextOrderDate descending, then returns only the top-ranked instance per plan.

This is used to show users the current state of each of their plans without loading the full instance history. For example, a dashboard might show "Your Bitcoin plan: last cycle deposited successfully on April 1" by using this procedure to get the latest instance per plan.

The procedure only considers active (PlanStatusID=1) or paused (PlanStatusID=5) plans, skipping cancelled ones. Created per EDGE-3688 (Nilly Ron, 30/10/2024).

---

## 2. Business Logic

### 2.1 Latest Instance Per Plan (ROW_NUMBER)

**What**: Uses CTE with ROW_NUMBER to return only the most recent instance for each of the user's active/paused plans.

**Columns/Parameters Involved**: `@GCID`, `PlanStatusID`, `ROW_NUMBER()`, `NextOrderDate`

**Rules**:
- CTE partitions by PlanID, orders by NextOrderDate DESC
- WHERE RowNum = 1 returns only the latest instance per plan
- PlanStatusID IN (1, 5) filters for active and paused plans
- Results ordered by PlanID, InstanceID DESC
- JOIN to Plans ensures plan ownership by GCID

**Diagram**:
```
User's Plans (Active/Paused)
    |
    +-- Plan A: Instance 3 (latest), Instance 2, Instance 1
    |           Return: Instance 3 only
    |
    +-- Plan B: Instance 5 (latest), Instance 4
    |           Return: Instance 5 only
    |
    v
Result: One instance per plan (most recent)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user whose latest instances to retrieve. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique plan instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date (latest per plan). |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order placement date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |
| 24 | RowNum | bigint | NO | - | CODE-BACKED | Always 1 in results (filter condition). ROW_NUMBER() OVER (PARTITION BY PlanID ORDER BY NextOrderDate DESC). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read | CTE source with ROW_NUMBER ranking |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Filtered by GCID and PlanStatusID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Dashboard/summary views for user's plans |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetLatestInstanceOfUserPlans (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | CTE source, ranked by NextOrderDate |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by GCID and PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Retrieves latest instance per plan for user dashboard |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get latest instance per plan for a user
```sql
EXEC [RecurringInvestment].[PlanInstancesGetLatestInstanceOfUserPlans] @GCID = 12345678
```

### 8.2 Manual equivalent
```sql
;WITH RankedInstances AS (
    SELECT PI.*, ROW_NUMBER() OVER (PARTITION BY PI.PlanID ORDER BY PI.NextOrderDate DESC) AS RowNum
    FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
    INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
    WHERE P.GCID = 12345678 AND P.PlanStatusID IN (1, 5)
)
SELECT * FROM RankedInstances WHERE RowNum = 1
```

### 8.3 Check latest status per plan
```sql
;WITH RankedInstances AS (
    SELECT PI.PlanID, PI.InstanceStatusID, PI.NextOrderDate,
        ROW_NUMBER() OVER (PARTITION BY PI.PlanID ORDER BY PI.NextOrderDate DESC) AS RowNum
    FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
    INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
    WHERE P.GCID = 12345678 AND P.PlanStatusID IN (1, 5)
)
SELECT PlanID, InstanceStatusID, NextOrderDate FROM RankedInstances WHERE RowNum = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances and Plans structures |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket (Nilly Ron, 30/10/2024) |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstancesGetLatestInstanceOfUserPlans | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetLatestInstanceOfUserPlans.sql*
