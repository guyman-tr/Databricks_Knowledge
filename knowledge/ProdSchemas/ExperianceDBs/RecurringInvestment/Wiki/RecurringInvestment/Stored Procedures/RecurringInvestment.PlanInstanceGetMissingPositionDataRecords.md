# RecurringInvestment.PlanInstanceGetMissingPositionDataRecords

> Retrieves plan instances where a trading order was placed but no position data has been received yet.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No params, returns instances with orders but no position data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds recurring investment plan instances that have progressed past the order placement stage (OrderID is populated) but have not yet received any position data (PositionStatus is NULL or 0). These represent instances that may be stuck in the order-to-position gap of the pipeline.

Without this procedure, the system could not detect instances where orders were placed but position confirmations were never received. This is a critical monitoring query used by a background reconciliation job to identify and resolve stuck instances. Created per EDGE-3688 (Nilly Ron, 12/5/2024).

The procedure returns both instance and plan data via INNER JOIN, filtering for active plans only (PlanStatusID=1). Note that unlike similar SPs, this one does not filter by InstanceStatusID, meaning it catches instances regardless of their current status -- an intentional design to detect even edge cases.

---

## 2. Business Logic

### 2.1 Missing Position Data Detection

**What**: Identifies instances where an order exists but position outcome is unknown.

**Columns/Parameters Involved**: `OrderID`, `PositionStatus`, `PlanStatusID`

**Rules**:
- OrderID IS NOT NULL: an order was placed for this instance
- PositionStatus IS NULL OR PositionStatus = 0: no position data recorded (0 is treated as unknown/unset)
- PlanStatusID = 1: only for active plans (cancelled plans are ignored)
- No InstanceStatusID filter (commented out in code: "in progress phase 0.5") -- catches all stuck orders

**Diagram**:
```
Instance Pipeline:
  Deposit --> Order Placed --> [POSITION GAP] --> Position Recorded
                                     ^
                                     |
                           This SP finds instances
                           stuck in this gap
```

### 2.2 Legacy Column Set

**What**: This SP predates the copy-trading columns and returns a smaller column set than newer SPs.

**Columns/Parameters Involved**: Return columns

**Rules**:
- Does NOT return MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode
- Does NOT return PlanType, CopyType, CopyParentCID, CopyParentGCID, MopType from Plans
- This is an older SP (EDGE-3688) that was not updated with the copy-trading columns added later

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**: None (parameterless procedure).

**Return Columns (PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique plan instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential deposit cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit processing timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason text. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order placement date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID (always NOT NULL in results). |
| 13 | PositionStatus | int | YES | - | VERIFIED | Always NULL or 0 in results (filter condition). See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp (NULL in results). |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD (NULL in results). |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 20 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased from Plans.ID). |
| 21 | GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. |
| 22 | CID | bigint | YES | - | VERIFIED | Plan owner's CID. |
| 23 | InstrumentID | int | YES | - | VERIFIED | Target instrument. |
| 24 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 25 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 26 | CurrencyID | int | NO | - | VERIFIED | Currency of Amount. |
| 27 | PlanStatusID | int | NO | - | VERIFIED | Always 1=Active in results. See [Plan Status](../../_glossary.md#plan-status). |
| 28 | StatusReasonID | int | YES | - | VERIFIED | Plan status reason. |
| 29 | CreationDate | datetime | NO | - | VERIFIED | Plan creation timestamp. |
| 30 | EndDate | datetime | YES | - | VERIFIED | Plan end date. |
| 31 | DepositStartDate | datetime | YES | - | VERIFIED | First deposit date. |
| 32 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 33 | RepeatsOn | int | NO | - | VERIFIED | Day of month. |
| 34 | HasBackupPayment | bit | YES | - | VERIFIED | Backup payment flag. |
| 35 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal period start. |
| 36 | FundingID | int | YES | - | VERIFIED | Payment method ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Source for instance data, filtered by OrderID/PositionStatus |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan data, filtered by PlanStatusID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Position Reconciliation Job | - | EXEC | Detects instances stuck after order placement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetMissingPositionDataRecords (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by OrderID/PositionStatus |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Position Reconciliation Job | Background Service | Identifies instances needing position data resolution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Note: InstanceStatusID filter is commented out in the source code.

---

## 8. Sample Queries

### 8.1 Find all instances missing position data
```sql
EXEC [RecurringInvestment].[PlanInstanceGetMissingPositionDataRecords]
```

### 8.2 Check how many instances are stuck per order status
```sql
SELECT PI.OrderStatusId, COUNT(*) AS MissingPositionCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.OrderID IS NOT NULL AND (PI.PositionStatus IS NULL OR PI.PositionStatus = 0)
    AND P.PlanStatusID = 1
GROUP BY PI.OrderStatusId
```

### 8.3 Find oldest stuck instances
```sql
SELECT TOP 10 PI.InstanceID, PI.OrderID, PI.OrderTradeDate,
    DATEDIFF(HOUR, PI.OrderTradeDate, GETUTCDATE()) AS HoursSinceOrder
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.OrderID IS NOT NULL AND (PI.PositionStatus IS NULL OR PI.PositionStatus = 0)
    AND P.PlanStatusID = 1
ORDER BY PI.OrderTradeDate ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances pipeline stages |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket (Nilly Ron, 12/5/2024) |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstanceGetMissingPositionDataRecords | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetMissingPositionDataRecords.sql*
