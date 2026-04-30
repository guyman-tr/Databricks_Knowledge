# RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByGCID

> Retrieves plan instances with orders for all active plans of a user, used for PnL (Profit and Loss) data calculation.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input, returns instances with OrderID for active plans |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves plan instances that have reached the order stage (OrderID IS NOT NULL) for all active plans belonging to a user. It is specifically designed for PnL (Profit and Loss) data calculation, where only instances with actual orders are relevant since they represent real investment actions.

Unlike `PlanInstancesGetPlansAndAllPlanInstancesByGCID` which returns all instances including pre-order ones, this procedure filters to only instances where a trading order was placed. This reduces the result set to only the instances that affect the user's portfolio. Created per JIRA-5226 (Nilly Ron) for PnL data.

The procedure is the single-user version; `PlanInstancesGetPlansAndPlanInstancesByPlanIDs` provides the same functionality in batch mode by PlanIDs.

---

## 2. Business Logic

### 2.1 Order-Filtered Instance Retrieval for PnL

**What**: Returns only instances that have an OrderID, indicating a real investment action took place.

**Columns/Parameters Involved**: `@GCID`, `PlanStatusID`, `OrderID`

**Rules**:
- INNER JOIN Plans to PlanInstances on PlanID
- Plans filtered by GCID = @GCID and PlanStatusID = 1 (active)
- Additional filter: OrderID IS NOT NULL (only instances with orders)
- This ensures PnL calculations only consider cycles where money was actually invested

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user. |

**Return Columns (PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID (always NOT NULL in results). |
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

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased). |
| 25 | GCID | bigint | NO | - | VERIFIED | User's GCID. |
| 26 | CID | bigint | YES | - | VERIFIED | User's CID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Target instrument. |
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Deposit plan ID. |
| 29 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount. |
| 30 | CurrencyID | int | NO | - | VERIFIED | Currency. |
| 31 | PlanStatusID | int | NO | - | VERIFIED | Always 1=Active. See [Plan Status](../../_glossary.md#plan-status). |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Plan status reason. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | Plan creation date. |
| 34 | EndDate | datetime | YES | - | VERIFIED | Plan end date. |
| 35 | DepositStartDate | datetime | YES | - | VERIFIED | First deposit date. |
| 36 | FrequencyID | int | NO | - | VERIFIED | Frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 37 | RepeatsOn | int | NO | - | VERIFIED | Day of month. |
| 38 | HasBackupPayment | bit | YES | - | VERIFIED | Backup payment flag. |
| 39 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal period start. |
| 40 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 41 | PlanType | int | NO | - | VERIFIED | Plan type. See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyType | int | NO | - | VERIFIED | Copy type. See [Copy Type](../../_glossary.md#copy-type). |
| 43 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader CID. |
| 44 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader GCID. |
| 45 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Instances with orders |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Active plans for user |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PnL Calculation Service | - | EXEC | Retrieves order-bearing instances for PnL |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByGCID (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by OrderID IS NOT NULL |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by GCID/PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PnL Calculation Service | Application | PnL data for user's recurring investments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get PnL data for a user
```sql
EXEC [RecurringInvestment].[PlanInstancesGetPlansAndPlanInstancesByGCID] @GCID = 12345678
```

### 8.2 Sum position amounts per plan
```sql
SELECT P.ID AS PlanID, P.InstrumentID, SUM(PI.PositionAmountUsd) AS TotalInvestedUsd
FROM [RecurringInvestment].[Plans] P WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK) ON P.ID = PI.PlanID
WHERE P.GCID = 12345678 AND P.PlanStatusID = 1 AND PI.OrderID IS NOT NULL
GROUP BY P.ID, P.InstrumentID
```

### 8.3 Count orders by status for PnL instances
```sql
SELECT PI.OrderStatusId, COUNT(*) AS OrderCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID = 1 AND PI.OrderID IS NOT NULL
GROUP BY PI.OrderStatusId
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances structures |
| [JIRA-5226](https://etoro-jira.atlassian.net/browse/JIRA-5226) | Jira | PnL data retrieval requirement |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByGCID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByGCID.sql*
