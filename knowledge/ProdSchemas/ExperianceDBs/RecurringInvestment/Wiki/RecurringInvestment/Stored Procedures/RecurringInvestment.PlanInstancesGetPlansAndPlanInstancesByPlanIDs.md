# RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByPlanIDs

> Batch version of PnL data retrieval -- returns instances with orders for multiple plans specified via a TVP.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanIDs TVP input, returns instances with OrderID for specified active plans |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the batch equivalent of `PlanInstancesGetPlansAndPlanInstancesByGCID`. Instead of filtering by a single user's GCID, it accepts a table-valued parameter of PlanIDs and returns all instances with orders for those specific active plans. This enables efficient bulk PnL data retrieval across multiple plans in a single database call.

This is used when the application needs PnL data for a specific set of plans, potentially across multiple users, or when it already knows the plan IDs and does not need to discover them by GCID. Created per JIRA-5226 (Nilly Ron).

The procedure applies the same filters as the GCID version: PlanStatusID=1 (active) and OrderID IS NOT NULL (instances with orders only).

---

## 2. Business Logic

### 2.1 Batch PnL Retrieval by PlanIDs

**What**: Returns order-bearing instances for a batch of plan IDs provided via TVP.

**Columns/Parameters Involved**: `@PlanIDs`, `PlanStatusID`, `OrderID`

**Rules**:
- INNER JOIN @PlanIDs on Plans.ID = PID.ColunmINT to filter by plan list
- PlanStatusID = 1: active plans only (in JOIN condition)
- OrderID IS NOT NULL: only instances with orders (in JOIN condition)
- Note: the PlanStatusID and OrderID filters are in the JOIN ON clause rather than WHERE, which is functionally equivalent since all joins are INNER

**Diagram**:
```
@PlanIDs TVP: [1001, 1002, 1003]
        |
        v
Plans WHERE ID IN @PlanIDs AND PlanStatusID = 1
        |  INNER JOIN
        v
PlanInstances WHERE OrderID IS NOT NULL
        |
        v
Result: Instances with orders for specified plans
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanIDs | RecurringInvestment.IntType (TVP) | NO | - | VERIFIED | Table-valued parameter containing plan IDs to retrieve. Uses IntType with ColunmINT. |

**Return Columns (PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID (in @PlanIDs list). |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID (always NOT NULL). |
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
| 25 | GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. |
| 26 | CID | bigint | YES | - | VERIFIED | Plan owner's CID. |
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
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Active plans in TVP |
| @PlanIDs | RecurringInvestment.IntType | TVP | Plan ID filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PnL Calculation Service (batch) | - | EXEC | Bulk PnL data retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByPlanIDs (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.IntType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by OrderID |
| RecurringInvestment.Plans | Table | INNER JOIN to TVP and PlanInstances |
| RecurringInvestment.IntType | User Defined Type | TVP for plan IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PnL Calculation Service | Application | Batch PnL retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get PnL data for specific plans
```sql
DECLARE @PlanIDs RecurringInvestment.IntType
INSERT INTO @PlanIDs (ColunmINT) VALUES (1001), (1002), (1003)
EXEC [RecurringInvestment].[PlanInstancesGetPlansAndPlanInstancesByPlanIDs] @PlanIDs
```

### 8.2 Compare with GCID-based version
```sql
-- First get user's plan IDs, then call batch version
DECLARE @PlanIDs RecurringInvestment.IntType
INSERT INTO @PlanIDs (ColunmINT)
SELECT ID FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE GCID = 12345678 AND PlanStatusID = 1
EXEC [RecurringInvestment].[PlanInstancesGetPlansAndPlanInstancesByPlanIDs] @PlanIDs
```

### 8.3 Aggregate position amounts for batch plans
```sql
SELECT P.ID AS PlanID, P.GCID, SUM(ISNULL(PI.PositionAmountUsd, 0)) AS TotalUsd
FROM [RecurringInvestment].[Plans] P WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK) ON P.ID = PI.PlanID
WHERE P.ID IN (1001, 1002, 1003) AND P.PlanStatusID = 1 AND PI.OrderID IS NOT NULL
GROUP BY P.ID, P.GCID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances structures |
| [JIRA-5226](https://etoro-jira.atlassian.net/browse/JIRA-5226) | Jira | Batch PnL data retrieval requirement |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByPlanIDs | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetPlansAndPlanInstancesByPlanIDs.sql*
