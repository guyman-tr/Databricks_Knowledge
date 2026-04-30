# RecurringInvestment.PlanInstancesGetMissingPositionsByOrderStatusID

> Retrieves instrument plan instances that have a completed order (in a final status) but no position data yet, for position reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderStatusIds TVP input (final statuses), returns instances missing positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds instrument-type plan instances where the trading order has reached a final status (provided via TVP) but position data has not been recorded. These represent instances stuck in the order-to-position gap: the order completed but the position confirmation was never received.

Unlike `PlanInstanceGetMissingPositionDataRecords` (the older version), this procedure filters by specific final order statuses using a TVP, and also filters by InstanceStatusID=5 (InProgress) and PlanType=1 (Instrument). This makes it more targeted for the position reconciliation job. Created per EDGE-5253 and EDGE-5257 (Nilly Ron, 27/2/25).

The TVP typically contains final order statuses like 3=Filled, 5=PartiallyFilled, 9=CanceledPartiallyFilled, etc. Only orders in these final states should have position data -- if they do not, something went wrong.

---

## 2. Business Logic

### 2.1 Missing Position After Final Order Detection

**What**: Finds instances where a final-status order exists but no position was recorded.

**Columns/Parameters Involved**: `@OrderStatusIds`, `OrderID`, `OrderStatusID`, `PositionStatus`, `InstanceStatusID`, `PlanStatusID`, `PlanType`

**Rules**:
- OrderID IS NOT NULL: an order exists
- OrderStatusID IN @OrderStatusIds: order is in a final status (from TVP)
- PositionStatus IS NULL OR PositionStatus = 0: no position data
- ISNULL(InstanceStatusID, 5) = 5: instance in progress
- PlanStatusID = 1: active plans only
- PlanType = 1 OR PlanType IS NULL: instrument plans

**Diagram**:
```
Instance Pipeline:
  Deposit --> Order (FINAL STATUS) --> [MISSING POSITION] --> ???
                                              ^
                                              |
                                    This SP detects this gap
                                    for instrument plans only
```

### 2.2 TVP-Based Final Status Definition

**What**: Uses a TVP to define which order statuses are considered "final" (order completed, position expected).

**Columns/Parameters Involved**: `@OrderStatusIds`

**Rules**:
- Typical final statuses: 3=Filled, 5=PartiallyFilled, 9=CanceledPartiallyFilled, 10=RejectedPartiallyFilled
- The application controls which statuses mean "position should exist" without modifying the SP
- This is the counterpart to `PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID` which uses non-final statuses

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderStatusIds | RecurringInvestment.IntType (TVP) | NO | - | VERIFIED | Final order status IDs that should have position data. Uses IntType with ColunmINT. See [Order Status](../../_glossary.md#order-status). |

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
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order placement date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Final order status (from TVP filter). See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID (always NOT NULL in results). |
| 13 | PositionStatus | int | YES | - | VERIFIED | Always NULL or 0 in results. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position timestamp (NULL in results). |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state (5=InProgress). See [Instance Status](../../_glossary.md#instance-status). |
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
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Linked deposit plan ID. |
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
| 41 | PlanType | int | YES | - | VERIFIED | 1=Instrument or NULL. See [Plan Type](../../_glossary.md#plan-type). |
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
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Plan type/status filters |
| @OrderStatusIds | RecurringInvestment.IntType | TVP | Final order status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Position Reconciliation Job | - | EXEC | Discovers instances missing position data after final order |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetMissingPositionsByOrderStatusID (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.IntType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by OrderStatusID/PositionStatus |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID/PlanType |
| RecurringInvestment.IntType | User Defined Type | TVP for final order statuses |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Position Reconciliation Job | Background Service | Resolves missing position data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find instances with filled orders but no position
```sql
DECLARE @FinalStatuses RecurringInvestment.IntType
INSERT INTO @FinalStatuses (ColunmINT) VALUES (3), (5) -- Filled, PartiallyFilled
EXEC [RecurringInvestment].[PlanInstancesGetMissingPositionsByOrderStatusID] @FinalStatuses
```

### 8.2 Include all final statuses
```sql
DECLARE @FinalStatuses RecurringInvestment.IntType
INSERT INTO @FinalStatuses (ColunmINT) VALUES (3), (5), (9), (10) -- Filled, Partial, CancelPartial, RejectPartial
EXEC [RecurringInvestment].[PlanInstancesGetMissingPositionsByOrderStatusID] @FinalStatuses
```

### 8.3 Check age of stuck instances
```sql
SELECT PI.InstanceID, PI.OrderID, PI.OrderStatusId, PI.OrderTradeDate,
    DATEDIFF(HOUR, PI.OrderTradeDate, GETUTCDATE()) AS HoursSinceOrder
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.OrderID IS NOT NULL AND PI.OrderStatusId IN (3, 5)
    AND (PI.PositionStatus IS NULL OR PI.PositionStatus = 0)
    AND P.PlanStatusID = 1 AND ISNULL(PI.InstanceStatusID, 5) = 5
ORDER BY PI.OrderTradeDate ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Order and position status definitions |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Position reconciliation architecture |
| [EDGE-5253](https://etoro-jira.atlassian.net/browse/EDGE-5253) | Jira | Trading EH changes |
| [EDGE-5257](https://etoro-jira.atlassian.net/browse/EDGE-5257) | Jira | Trading get order info API changes |

---

*Generated: 2026-04-13 | Quality: 9.3/10*
*Object: RecurringInvestment.PlanInstancesGetMissingPositionsByOrderStatusID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetMissingPositionsByOrderStatusID.sql*
