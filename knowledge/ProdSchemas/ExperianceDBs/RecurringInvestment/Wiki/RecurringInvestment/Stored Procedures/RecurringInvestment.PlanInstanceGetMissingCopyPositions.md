# RecurringInvestment.PlanInstanceGetMissingCopyPositions

> Retrieves copy plan instances where a mirror order was created but no position data has been recorded yet.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No params, returns copy instances missing position data after mirror order |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies copy-type plan instances that are stuck in a gap state: the mirror (copy) order was successfully created (MirrorOrderCreated=1) but no position status data has been received yet. These instances need follow-up to determine whether the copy position was actually opened or if the position data is simply delayed.

Without this procedure, copy plan instances that received a mirror order confirmation but never received position confirmation would remain in limbo indefinitely, with no mechanism to detect and resolve them. Created per EDGE-5708 (Nilly Ron, 29/5/2025).

The procedure is called by a background job that monitors copy plan health. When instances are found, the system can query the copy trading platform to reconcile position status and update the instance accordingly.

---

## 2. Business Logic

### 2.1 Missing Copy Position Detection

**What**: Finds copy instances where mirror order was confirmed but position data is absent.

**Columns/Parameters Involved**: `PlanType`, `MopType`, `DepositID`, `NextOrderDate`, `MirrorOrderCreated`, `InstanceStatusID`, `PlanStatusID`

**Rules**:
- PlanType = 2: only copy plans (instrument plans use a different order flow)
- MirrorOrderCreated = 1: the copy order was requested and confirmed
- ISNULL(InstanceStatusID, 5) = 5: instance is still in progress
- PlanStatusID = 1: active plans only
- Deposit readiness varies by MopType:
  - MopType = 1: DepositID IS NOT NULL (deposit-based)
  - MopType = 2: NextOrderDate IS NOT NULL AND NextOrderDate <= GETUTCDATE() (time-based)

**Diagram**:
```
Copy Instance Lifecycle:
  Deposit --> Mirror Order Created --> [GAP] --> Position Data
                                         ^
                                         |
                              This SP finds instances
                              stuck in this gap state
```

### 2.2 MOP-Type Deposit Readiness

**What**: Dual deposit verification logic based on the plan's payment method type.

**Columns/Parameters Involved**: `MopType`, `DepositID`, `NextOrderDate`

**Rules**:
- MopType = 1 (standard deposit): checks DepositID IS NOT NULL - meaning money was transferred
- MopType = 2 (time-based): checks NextOrderDate <= GETUTCDATE() - eligibility by scheduled time
- The OR condition ensures both MOP types are included in the result set

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
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID from Money Group. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential deposit cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit processing timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason text. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order placement date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome (expected NULL or missing for returned rows). See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance state (5=InProgress in results). See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Always 1 in results (filter condition). See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy relationship ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased from Plans.ID). |
| 25 | GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. |
| 26 | CID | bigint | YES | - | VERIFIED | Plan owner's CID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Target instrument (NULL for copy plans). |
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 29 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 30 | CurrencyID | int | NO | - | VERIFIED | Currency of Amount. |
| 31 | PlanStatusID | int | NO | - | VERIFIED | Always 1=Active in results. See [Plan Status](../../_glossary.md#plan-status). |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Plan status reason. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | Plan creation timestamp. |
| 34 | EndDate | datetime | YES | - | VERIFIED | Plan end date (NULL for active). |
| 35 | DepositStartDate | datetime | YES | - | VERIFIED | First deposit date. |
| 36 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 37 | RepeatsOn | int | NO | - | VERIFIED | Day of month. |
| 38 | HasBackupPayment | bit | YES | - | VERIFIED | Backup payment flag. |
| 39 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal period start. |
| 40 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 41 | PlanType | int | NO | - | VERIFIED | Always 2=Copy in results. See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyType | int | NO | - | VERIFIED | Copy type. See [Copy Type](../../_glossary.md#copy-type). |
| 43 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 44 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
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
| Copy Position Monitor Job | - | EXEC | Discovers instances stuck after mirror order creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetMissingCopyPositions (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by MirrorOrderCreated/InstanceStatusID |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanType/PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy Position Monitor Job | Background Service | Monitors stuck copy instances |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find all missing copy positions
```sql
EXEC [RecurringInvestment].[PlanInstanceGetMissingCopyPositions]
```

### 8.2 Count stuck copy instances by CopyType
```sql
SELECT P.CopyType, COUNT(*) AS StuckCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.PlanType = 2 AND PI.MirrorOrderCreated = 1
    AND ISNULL(PI.InstanceStatusID, 5) = 5 AND P.PlanStatusID = 1
GROUP BY P.CopyType
```

### 8.3 Check how long instances have been stuck
```sql
SELECT PI.InstanceID, PI.NextOrderDate, DATEDIFF(HOUR, PI.NextOrderDate, GETUTCDATE()) AS HoursStuck
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.PlanType = 2 AND PI.MirrorOrderCreated = 1
    AND ISNULL(PI.InstanceStatusID, 5) = 5 AND P.PlanStatusID = 1
ORDER BY PI.NextOrderDate ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Copy plan flow and PlanInstances structure |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Copy order and position reconciliation architecture |
| [EDGE-5708](https://etoro-jira.atlassian.net/browse/EDGE-5708) | Jira | Original ticket for missing copy position detection |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanInstanceGetMissingCopyPositions | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetMissingCopyPositions.sql*
