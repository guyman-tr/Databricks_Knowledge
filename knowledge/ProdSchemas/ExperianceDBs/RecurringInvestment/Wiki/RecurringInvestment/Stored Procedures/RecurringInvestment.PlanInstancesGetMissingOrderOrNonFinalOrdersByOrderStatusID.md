# RecurringInvestment.PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID

> Retrieves instrument plan instances that either have no order or have an order in a non-final status, for the Order Execution Job to process.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderStatusIds TVP input, returns instances needing order action |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary work queue for the Order Execution Job in the recurring investment pipeline. It finds instrument-type plan instances that need order action: either they have no order at all (OrderID IS NULL) or their existing order is in a non-final status that may need follow-up (e.g., Received, Placed, WaitingForMarket).

The non-final order statuses are provided via the @OrderStatusIds TVP, allowing the application to define which order statuses are considered "non-final" and worth retrying or monitoring. This design decouples the status classification from the stored procedure. Created per EDGE-5253 and EDGE-5257 (Nilly Ron, 27/2/25).

The deposit readiness check varies by MopType: MopType=1 requires HighLevelDepositStatusID=1 (successful deposit), while MopType=2 uses time-based eligibility via NextOrderDate.

---

## 2. Business Logic

### 2.1 Missing or Non-Final Order Detection

**What**: Finds instances where an order needs to be placed or an existing non-final order needs follow-up.

**Columns/Parameters Involved**: `@OrderStatusIds`, `OrderID`, `OrderStatusID`, `InstanceStatusID`, `PlanStatusID`, `PlanType`, `MopType`, `HighLevelDepositStatusID`, `NextOrderDate`

**Rules**:
- Two scenarios captured with OR:
  - OrderID IS NULL: no order has been placed yet
  - OrderStatusID IN @OrderStatusIds: order exists but is in a non-final (retriable/monitorable) status
- ISNULL(InstanceStatusID, 5) = 5: instance is in progress
- PlanStatusID = 1: active plans only
- PlanType = 1 OR PlanType IS NULL: instrument plans (NULL check for legacy data)
- Deposit readiness:
  - MopType = 1: HighLevelDepositStatusID = 1 (deposit succeeded)
  - MopType = 2: NextOrderDate <= GETUTCDATE() (time-based)

**Diagram**:
```
Eligible Instances:
    |
    +-- No Order (OrderID IS NULL)
    |       |
    |       +-- Deposit ready? --> Return for order placement
    |
    +-- Non-Final Order (OrderStatusID in TVP)
    |       |
    |       +-- Deposit ready? --> Return for order monitoring/retry
    |
    Filters: Active plan, InProgress instance, Instrument type
```

### 2.2 TVP-Based Status Classification

**What**: Uses a table-valued parameter to define which order statuses are considered non-final.

**Columns/Parameters Involved**: `@OrderStatusIds`, `OrderStatusID`

**Rules**:
- The TVP contains IntType rows with ColunmINT values matching non-final OrderStatus IDs
- Typical non-final statuses: 1=Received, 2=Placed, 6=PendingCancel, 11=WaitingForMarket
- This design allows the application to change which statuses trigger re-processing without modifying the SP

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderStatusIds | RecurringInvestment.IntType (TVP) | NO | - | VERIFIED | Non-final order status IDs to include. Uses IntType with ColunmINT column. See [Order Status](../../_glossary.md#order-status). |

**Return Columns (PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique plan instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state (NULL or in TVP list). See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID (may be NULL). |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state (5=InProgress). See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag. |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased). |
| 25 | GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. |
| 26 | CID | bigint | YES | - | VERIFIED | Plan owner's CID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Target instrument. |
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Linked deposit plan ID. |
| 29 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 30 | CurrencyID | int | NO | - | VERIFIED | Currency of Amount. |
| 31 | PlanStatusID | int | NO | - | VERIFIED | Always 1=Active. See [Plan Status](../../_glossary.md#plan-status). |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Plan status reason. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | Plan creation timestamp. |
| 34 | EndDate | datetime | YES | - | VERIFIED | Plan end date. |
| 35 | DepositStartDate | datetime | YES | - | VERIFIED | First deposit date. |
| 36 | FrequencyID | int | NO | - | VERIFIED | Frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 37 | RepeatsOn | int | NO | - | VERIFIED | Day of month. |
| 38 | HasBackupPayment | bit | YES | - | VERIFIED | Backup payment flag. |
| 39 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal period start. |
| 40 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 41 | PlanType | int | YES | - | VERIFIED | 1=Instrument or NULL (legacy). See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyType | int | NO | - | VERIFIED | Copy type. See [Copy Type](../../_glossary.md#copy-type). |
| 43 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader CID. |
| 44 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader GCID. |
| 45 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Source for instance data |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan type/status filters |
| @OrderStatusIds | RecurringInvestment.IntType | TVP | Non-final order status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Order Execution Job | - | EXEC | Discovers instances needing order action |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.IntType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by order status |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID/PlanType |
| RecurringInvestment.IntType | User Defined Type | TVP for non-final order statuses |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order Execution Job | Background Service | Polls for instances needing order action |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find instances with missing or non-final orders
```sql
DECLARE @StatusIds RecurringInvestment.IntType
INSERT INTO @StatusIds (ColunmINT) VALUES (1), (2), (6), (11) -- Received, Placed, PendingCancel, WaitingForMarket
EXEC [RecurringInvestment].[PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID] @StatusIds
```

### 8.2 Count by order status category
```sql
SELECT CASE WHEN PI.OrderID IS NULL THEN 'No Order' ELSE 'Non-Final Order' END AS Category, COUNT(*) AS Cnt
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE ISNULL(PI.InstanceStatusID, 5) = 5 AND P.PlanStatusID = 1 AND (P.PlanType = 1 OR P.PlanType IS NULL)
    AND ((P.MopType = 1 AND PI.HighLevelDepositStatusID = 1) OR (P.MopType = 2 AND PI.NextOrderDate <= GETUTCDATE()))
GROUP BY CASE WHEN PI.OrderID IS NULL THEN 'No Order' ELSE 'Non-Final Order' END
```

### 8.3 Check order statuses of returned instances
```sql
SELECT PI.InstanceID, PI.OrderID, PI.OrderStatusId, P.InstrumentID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE ISNULL(PI.InstanceStatusID, 5) = 5 AND P.PlanStatusID = 1
    AND PI.OrderStatusId IN (1, 2, 6, 11)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Order status definitions, instance pipeline |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Order execution job architecture |
| [EDGE-5253](https://etoro-jira.atlassian.net/browse/EDGE-5253) | Jira | Trading EH changes affecting order flow |
| [EDGE-5257](https://etoro-jira.atlassian.net/browse/EDGE-5257) | Jira | Trading get order info API changes |

---

*Generated: 2026-04-13 | Quality: 9.3/10*
*Object: RecurringInvestment.PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID.sql*
