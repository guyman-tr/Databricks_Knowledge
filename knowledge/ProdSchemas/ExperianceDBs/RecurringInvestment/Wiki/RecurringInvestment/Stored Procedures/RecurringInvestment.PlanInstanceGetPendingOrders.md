# RecurringInvestment.PlanInstanceGetPendingOrders

> Retrieves instrument-type plan instances that have a successful deposit but no order placed yet, ready for order execution.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No params, returns instrument plan instances needing order placement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies instrument-type recurring investment plan instances that are ready to have their trading orders placed. These are instances where the deposit has completed (or is time-eligible for MopType=2) but no order has been submitted yet. It serves as the primary work queue for the Order Execution Job.

Without this procedure, the system would have no way to discover which instrument plan instances need order placement. The Order Execution Job polls this procedure on a schedule, then places trading orders for each returned instance. Created per EDGE-3688 (Nilly Meyrav, 12/5/2024), with logic updated per EDGE-5030 (Nilly, 13/2) to filter based on InstanceStatusID.

The procedure is the instrument-plan counterpart to `PlanInstanceGetCopyPendingOrders`, which handles copy plans. Together, they cover the full spectrum of plan types needing order execution.

---

## 2. Business Logic

### 2.1 Instrument Order Eligibility Filter

**What**: Identifies instrument plan instances eligible for order placement based on deposit completion and MOP type.

**Columns/Parameters Involved**: `OrderID`, `InstanceStatusID`, `PlanStatusID`, `PlanType`, `MopType`, `DepositID`, `NextOrderDate`

**Rules**:
- OrderID IS NULL: no order has been placed yet
- ISNULL(InstanceStatusID, 5) = 5: instance is in progress
- PlanStatusID = 1: only active plans
- PlanType = 1: only instrument plans (copy plans handled by separate SP)
- Deposit readiness depends on MopType:
  - MopType = 1: DepositID IS NOT NULL OR DepositID > 0 (deposit completed)
  - MopType = 2: NextOrderDate IS NOT NULL AND NextOrderDate <= GETUTCDATE() (time-based)

**Diagram**:
```
Instance Pipeline:
  [Deposit Complete] --> THIS SP finds eligible instances --> [Order Placement]
                                                                    |
                                                                    v
                                                            [Position Opening]
```

### 2.2 MOP-Type Dual Logic

**What**: Different deposit verification depending on payment method.

**Columns/Parameters Involved**: `MopType`, `DepositID`, `NextOrderDate`

**Rules**:
- MopType = 1 (standard): requires DepositID IS NOT NULL (explicit deposit confirmation)
- MopType = 2 (time-based): requires NextOrderDate <= GETUTCDATE() (scheduled time has passed)
- This enables the system to support both deposit-driven and time-driven order flows

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
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order date (NULL in results since no order yet). |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state (NULL in results). See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID (always NULL in results). |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state (5=InProgress in results). See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag (N/A for instrument plans). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased from Plans.ID). |
| 25 | GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. |
| 26 | CID | bigint | YES | - | VERIFIED | Plan owner's CID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Target instrument for the order. |
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Linked deposit plan ID. |
| 29 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 30 | CurrencyID | int | NO | - | VERIFIED | Currency of Amount. |
| 31 | PlanStatusID | int | NO | - | VERIFIED | Always 1=Active. See [Plan Status](../../_glossary.md#plan-status). |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Plan status reason. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | Plan creation timestamp. |
| 34 | EndDate | datetime | YES | - | VERIFIED | Plan end date. |
| 35 | DepositStartDate | datetime | YES | - | VERIFIED | First deposit date. |
| 36 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 37 | RepeatsOn | int | NO | - | VERIFIED | Day of month. |
| 38 | HasBackupPayment | bit | YES | - | VERIFIED | Backup payment flag. |
| 39 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal period start. |
| 40 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 41 | PlanType | int | NO | - | VERIFIED | Always 1=Instrument in results. See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyType | int | NO | - | VERIFIED | Copy type (0=None for instrument plans). See [Copy Type](../../_glossary.md#copy-type). |
| 43 | CopyParentCID | bigint | YES | - | VERIFIED | NULL for instrument plans. |
| 44 | CopyParentGCID | bigint | YES | - | VERIFIED | NULL for instrument plans. |
| 45 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Source for instance data |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan type and status filters |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Order Execution Job | - | EXEC | Discovers instrument instances needing order placement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetPendingOrders (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by OrderID/InstanceStatusID |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID/PlanType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order Execution Job | Background Service | Polls for instances ready for order placement |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to find pending orders
```sql
EXEC [RecurringInvestment].[PlanInstanceGetPendingOrders]
```

### 8.2 Count pending orders by instrument
```sql
SELECT P.InstrumentID, COUNT(*) AS PendingCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.OrderID IS NULL AND ISNULL(PI.InstanceStatusID, 5) = 5
    AND P.PlanStatusID = 1 AND P.PlanType = 1
    AND ((P.MopType = 1 AND PI.DepositID IS NOT NULL) OR (P.MopType = 2 AND PI.NextOrderDate <= GETUTCDATE()))
GROUP BY P.InstrumentID
```

### 8.3 Check deposit details for pending order instances
```sql
SELECT PI.InstanceID, PI.DepositID, PI.HighLevelDepositStatusId, PI.DepositDate, P.InstrumentID, P.Amount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.OrderID IS NULL AND ISNULL(PI.InstanceStatusID, 5) = 5
    AND P.PlanStatusID = 1 AND P.PlanType = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Instance pipeline stages, deposit-to-order flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Order execution job architecture |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original creation ticket |
| [EDGE-5030](https://etoro-jira.atlassian.net/browse/EDGE-5030) | Jira | Updated logic to filter by InstanceStatusID |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanInstanceGetPendingOrders | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetPendingOrders.sql*
