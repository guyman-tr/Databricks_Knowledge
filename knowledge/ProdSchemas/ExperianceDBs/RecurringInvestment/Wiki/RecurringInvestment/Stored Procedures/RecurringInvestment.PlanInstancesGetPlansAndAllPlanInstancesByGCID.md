# RecurringInvestment.PlanInstancesGetPlansAndAllPlanInstancesByGCID

> Retrieves all plan instances for all active plans of a user, providing a complete execution history across all plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input, returns all instances of all active plans |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns every plan instance for every active plan belonging to a specific user. Unlike `PlanInstancesGetPlansAndPlanInstancesByGCID` (which filters for instances with orders only), this procedure returns ALL instances regardless of their pipeline stage, including those still awaiting deposit.

This is used when the application needs a complete view of a user's recurring investment history, including pending and in-progress instances. Typical use cases include admin dashboards, support tools, and comprehensive plan history screens. Created per JIRA-4832 (Nilly Ron).

The procedure joins Plans to PlanInstances and filters only for PlanStatusID=1 (active plans), returning both plan configuration columns and instance execution columns.

---

## 2. Business Logic

### 2.1 Complete Active-Plan Instance Retrieval

**What**: Returns all instances for all active plans of a user, without filtering by instance stage.

**Columns/Parameters Involved**: `@GCID`, `PlanStatusID`

**Rules**:
- INNER JOIN Plans to PlanInstances on PlanID
- Plans filtered by GCID = @GCID and PlanStatusID = 1 (active only)
- No filter on InstanceStatusID, OrderID, or DepositID -- returns ALL instances
- Results include both plan-level and instance-level columns
- Cancelled plans are excluded

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
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
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
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | All instances for active plans |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Active plans for user |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Complete plan history view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetPlansAndAllPlanInstancesByGCID (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by GCID/PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Complete plan+instance history retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instances for a user's active plans
```sql
EXEC [RecurringInvestment].[PlanInstancesGetPlansAndAllPlanInstancesByGCID] @GCID = 12345678
```

### 8.2 Count instances per plan
```sql
SELECT PI.PlanID, COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID = 1
GROUP BY PI.PlanID
```

### 8.3 Compare with orders-only version
```sql
-- This SP returns ALL instances; PlanInstancesGetPlansAndPlanInstancesByGCID returns only those with OrderID
SELECT PI.PlanID, PI.InstanceID, PI.OrderID,
    CASE WHEN PI.OrderID IS NULL THEN 'Pre-Order' ELSE 'Has Order' END AS Stage
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances structures |
| [JIRA-4832](https://etoro-jira.atlassian.net/browse/JIRA-4832) | Jira | Original ticket for complete instance retrieval |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlanInstancesGetPlansAndAllPlanInstancesByGCID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetPlansAndAllPlanInstancesByGCID.sql*
