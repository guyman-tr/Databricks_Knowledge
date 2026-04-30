# RecurringInvestment.PlanInstancesGetThisMonthExecutedInstanceOfUserPlans

> Retrieves plan instances from the current month that have had a successful deposit, for active or paused plans of a user.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @ThisMonth (unused) input, returns this month's deposited instances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves plan instances from the current calendar month where a deposit was successfully processed (HighLevelDepositStatusId=1). It is used to determine which plans have already been executed this month, helping the system and the user understand which plans have completed their monthly cycle.

This information is critical for preventing duplicate executions and for showing users which of their recurring plans have already run this month. The procedure considers both active (PlanStatusID=1) and paused (PlanStatusID=5) plans.

The @ThisMonth parameter exists in the signature but is unused in the query body (marked as "todo remove parameter" in the source code). The month filtering uses DATEADD/DATEDIFF to calculate the first day of the current month and the first day of the next month. Created per EDGE-3688 (Nilly Ron, 30/10/2024).

---

## 2. Business Logic

### 2.1 Current Month Executed Instance Filter

**What**: Returns instances with successful deposits in the current calendar month.

**Columns/Parameters Involved**: `@GCID`, `PlanStatusID`, `NextOrderDate`, `HighLevelDepositStatusId`

**Rules**:
- PlanStatusID IN (1, 5): active or paused plans
- NextOrderDate >= first day of current month (DateAdd/DateDiff calculation)
- NextOrderDate < first day of next month
- HighLevelDepositStatusId = 1: only successfully deposited instances
- Returns instance-only columns (no Plans columns in result set)
- @ThisMonth parameter is declared but NOT used (legacy param)

**Diagram**:
```
Current Month: April 2026
  April 1 <--- NextOrderDate must be within ---> April 30
               AND HighLevelDepositStatusId = 1
               AND PlanStatusID IN (1, 5)
```

### 2.2 Unused Parameter Legacy

**What**: The @ThisMonth parameter is declared but not referenced in the query.

**Columns/Parameters Involved**: `@ThisMonth`

**Rules**:
- The TODO comment in source code indicates this parameter should be removed
- The month boundary is calculated dynamically from GETDATE(), making the parameter redundant
- Callers may still pass a value, but it has no effect on the result

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user. |
| 2 | @ThisMonth | datetime | NO | - | CODE-BACKED | Unused parameter (legacy). The month is calculated dynamically from GETDATE(). Marked for removal in source code. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date (within current month). |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Always 1=Success in results. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason (NULL for successful deposits). |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag. |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Instance data filtered by date and deposit status |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Plan ownership and status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Checks which plans already executed this month |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetThisMonthExecutedInstanceOfUserPlans (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, date/deposit filtered |
| RecurringInvestment.Plans | Table | INNER JOIN, GCID/PlanStatusID filtered |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Monthly execution status check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Note: @ThisMonth parameter is unused (legacy).

---

## 8. Sample Queries

### 8.1 Check which plans executed this month
```sql
EXEC [RecurringInvestment].[PlanInstancesGetThisMonthExecutedInstanceOfUserPlans]
    @GCID = 12345678, @ThisMonth = '2026-04-01'
```

### 8.2 Manual equivalent
```sql
SELECT PI.InstanceID, PI.PlanID, PI.NextOrderDate, PI.HighLevelDepositStatusId
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID IN (1, 5)
    AND PI.NextOrderDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
    AND PI.NextOrderDate < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())+1, 0)
    AND PI.HighLevelDepositStatusId = 1
```

### 8.3 Count executed instances per plan this month
```sql
SELECT PI.PlanID, COUNT(*) AS ExecutedThisMonth
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND PI.HighLevelDepositStatusId = 1
    AND PI.NextOrderDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
    AND PI.NextOrderDate < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())+1, 0)
GROUP BY PI.PlanID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Instance lifecycle, deposit status values |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket (Nilly Ron, 30/10/2024) |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstancesGetThisMonthExecutedInstanceOfUserPlans | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetThisMonthExecutedInstanceOfUserPlans.sql*
