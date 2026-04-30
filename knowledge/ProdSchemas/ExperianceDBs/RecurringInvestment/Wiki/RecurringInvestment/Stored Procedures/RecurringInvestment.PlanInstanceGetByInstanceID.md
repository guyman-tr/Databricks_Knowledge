# RecurringInvestment.PlanInstanceGetByInstanceID

> Retrieves all columns for a single plan instance by its InstanceID.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstanceID input, returns single PlanInstances row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete set of columns for a single plan instance identified by its InstanceID. Unlike `PlanGetPlanAndItsInstanceByInstanceId`, this procedure returns only instance-level data without joining to the Plans table, making it a lightweight lookup for when the caller already has the plan context.

This procedure serves as the foundational instance-level read operation. It is used by the application when it needs to check the current state of a specific execution cycle, for example to determine whether the deposit succeeded, whether an order was placed, or what position resulted. Created per EDGE-3688 (Nilly Ron, 03/07/2024).

The application calls this procedure during various stages of the recurring investment pipeline, such as after receiving a deposit callback or after an order status update, to fetch the latest instance state.

---

## 2. Business Logic

### 2.1 Direct Instance Lookup

**What**: Simple single-row retrieval from PlanInstances by primary key.

**Columns/Parameters Involved**: `@InstanceID`, `PlanInstances.InstanceID`

**Rules**:
- SELECT returns all PlanInstances columns for the matching InstanceID
- No JOIN to Plans table -- this is a pure instance-only read
- Uses NOLOCK hint for non-blocking reads
- Returns zero rows if the InstanceID does not exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstanceID | int | NO | - | VERIFIED | Unique identifier of the plan instance to retrieve. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique identifier for this plan instance. |
| 2 | PlanID | int | NO | - | VERIFIED | Foreign key to the parent plan. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled date for order execution. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID from Money Group. NULL if no deposit yet. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential deposit cycle number within the plan. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Timestamp of deposit processing. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit result: 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Textual deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status code. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Date the trading order was placed. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID from the trading system. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position creation outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Timestamp when position was opened. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | USD amount of the opened position. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code for position open failure. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason code for the instance status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag: 1=created, NULL=not created. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy relationship ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position creation status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Error code for copy position failure. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read | Direct SELECT by InstanceID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Called to check instance state at various pipeline stages |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetByInstanceID (procedure)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | SELECT FROM with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Reads instance state during pipeline processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Retrieve instance by ID
```sql
EXEC [RecurringInvestment].[PlanInstanceGetByInstanceID] @InstanceID = 5001
```

### 8.2 Compare instance state with plan
```sql
SELECT PI.InstanceID, PI.InstanceStatusID, PI.HighLevelDepositStatusId, PI.OrderID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
WHERE PI.InstanceID = 5001
```

### 8.3 Check instance pipeline progress
```sql
SELECT PI.InstanceID,
    CASE WHEN PI.DepositID IS NULL THEN 'Pre-Deposit'
         WHEN PI.OrderID IS NULL THEN 'Post-Deposit/Pre-Order'
         WHEN PI.PositionStatus IS NULL THEN 'Post-Order/Pre-Position'
         ELSE 'Complete' END AS PipelineStage
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
WHERE PI.InstanceID = 5001
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances column definitions |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket for this SP creation (Nilly Ron, 03/07/2024) |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlanInstanceGetByInstanceID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetByInstanceID.sql*
