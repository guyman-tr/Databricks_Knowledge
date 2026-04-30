# RecurringInvestment.PlanInstanceGetPlanInstancesByPlanID

> Retrieves all plan instances for a specific plan by PlanID, returning the complete instance history.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID input, returns all PlanInstances rows for that plan |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves every plan instance associated with a specific plan, providing a complete execution history. Each row represents one execution cycle of the recurring investment plan, from creation through deposit, order, and position stages.

This is used when the application needs to display the full history of a plan -- all cycles, including successful ones, failed ones, skipped ones, and in-progress ones. It is a simple lookup by PlanID against the PlanInstances table only (no JOIN to Plans). Created per EDGE-3688 (Nilly Ron, 16/6/2024).

The procedure is called from plan detail screens where the user wants to see the history of each monthly execution cycle for a specific recurring investment plan.

---

## 2. Business Logic

### 2.1 Full Instance History Retrieval

**What**: Simple SELECT returning all instances for a plan, with no filtering on status or dates.

**Columns/Parameters Involved**: `@PlanID`, `PlanInstances.PlanID`

**Rules**:
- Returns ALL instances regardless of InstanceStatusID (active, completed, cancelled, skipped)
- No date filtering -- includes both past and future instances
- No JOIN to Plans table -- caller must already know the plan context
- Results include all PlanInstances columns including copy-trading fields

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | ID of the plan whose instances to retrieve. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique plan instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID (matches @PlanID). |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date. |
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
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read | Direct SELECT filtered by PlanID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Plan detail screen instance history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetPlanInstancesByPlanID (procedure)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | SELECT FROM with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Reads full instance history for a plan |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instances for a plan
```sql
EXEC [RecurringInvestment].[PlanInstanceGetPlanInstancesByPlanID] @PlanID = 1001
```

### 8.2 Count instances by status for a plan
```sql
SELECT PI.InstanceStatusID, COUNT(*) AS Cnt
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
WHERE PI.PlanID = 1001
GROUP BY PI.InstanceStatusID
```

### 8.3 Get instance timeline for a plan
```sql
SELECT PI.InstanceID, PI.NextOrderDate, PI.InstanceStatusID, PI.OrderID, PI.PositionStatus
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
WHERE PI.PlanID = 1001
ORDER BY PI.NextOrderDate ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances table structure |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket (Nilly Ron, 16/6/2024) |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlanInstanceGetPlanInstancesByPlanID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetPlanInstancesByPlanID.sql*
