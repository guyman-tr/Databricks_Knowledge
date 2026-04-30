# RecurringInvestment.PlanInstanceGetCopyPendingOrders

> Retrieves copy plan instances that have a successful deposit but no mirror order created yet, ready for copy order placement.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No params, returns instances needing copy order creation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies copy-type recurring investment plan instances that are ready to have their mirror (copy) orders placed. These are instances where the deposit step has completed (or is time-eligible for MopType=2) but the copy order has not yet been initiated. It serves as the work queue for the Copy Order Placement Job.

Without this procedure, the system would have no way to identify which copy plan instances need mirror order creation. The Copy Order Job polls this procedure to discover work items, then initiates copy trading operations for each returned instance.

The procedure filters specifically for PlanType=2 (Copy) plans with PlanStatusID=1 (Active) and InstanceStatusID=5 (InProgress). The deposit readiness check varies by MopType: MopType=1 requires a DepositID, while MopType=2 uses a time-based check against NextOrderDate.

---

## 2. Business Logic

### 2.1 Copy Order Eligibility Filter

**What**: Identifies copy plan instances eligible for mirror order creation based on deposit completion and MOP type.

**Columns/Parameters Involved**: `MirrorOrderCreated`, `InstanceStatusID`, `PlanStatusID`, `PlanType`, `MopType`, `DepositID`, `NextOrderDate`

**Rules**:
- MirrorOrderCreated IS NULL: no copy order has been requested yet
- ISNULL(InstanceStatusID, 5) = 5: instance is in progress (NULL treated as InProgress)
- PlanStatusID = 1: only active plans
- PlanType = 2: only copy plans (not instrument plans)
- Deposit readiness depends on MopType:
  - MopType = 1: DepositID IS NOT NULL (deposit completed)
  - MopType = 2: NextOrderDate IS NOT NULL AND NextOrderDate <= GETUTCDATE() (time-based eligibility)

**Diagram**:
```
Copy Plan Instance
    |
    +-- MirrorOrderCreated IS NULL? ----[No]--> Skip (already ordered)
    |           |
    |          [Yes]
    |           |
    +-- InstanceStatusID = 5 (InProgress)? --[No]--> Skip
    |           |
    |          [Yes]
    |           |
    +-- PlanStatusID = 1 (Active)? --------[No]--> Skip
    |           |
    |          [Yes]
    |           |
    +-- PlanType = 2 (Copy)? -------------[No]--> Skip
    |           |
    |          [Yes]
    |           |
    +-- MopType = 1? --> DepositID NOT NULL? ---> ELIGIBLE
    |           |
    +-- MopType = 2? --> NextOrderDate <= NOW? -> ELIGIBLE
```

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
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date for this cycle. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit ID from Money Group. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential deposit cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit processing timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason text. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order placement date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position creation outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag (will be NULL for all returned rows). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy relationship ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased from Plans.ID). |
| 25 | GCID | bigint | NO | - | VERIFIED | Plan owner's Global Customer ID. |
| 26 | CID | bigint | YES | - | VERIFIED | Plan owner's Customer ID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Target instrument (NULL for copy plans). |
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 29 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 30 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 31 | PlanStatusID | int | NO | - | VERIFIED | Plan status (always 1=Active in results). See [Plan Status](../../_glossary.md#plan-status). |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Plan status reason. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | Plan creation timestamp. |
| 34 | EndDate | datetime | YES | - | VERIFIED | Plan cancellation date (NULL for active). |
| 35 | DepositStartDate | datetime | YES | - | VERIFIED | First deposit date. |
| 36 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 37 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 38 | HasBackupPayment | bit | YES | - | VERIFIED | Backup payment method flag. |
| 39 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System temporal period start. |
| 40 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 41 | PlanType | int | NO | - | VERIFIED | Always 2=Copy in results. See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyType | int | NO | - | VERIFIED | Copy type: 1=PI, 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). |
| 43 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 44 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 45 | MopType | int | NO | - | VERIFIED | Method of payment type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Source for instance execution data |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan configuration and PlanType filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Copy Order Placement Job | - | EXEC | Polls for copy instances needing mirror orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetCopyPendingOrders (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by MirrorOrderCreated/InstanceStatusID |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID/PlanType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy Order Placement Job | Background Service | Discovers copy instances needing mirror orders |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to find pending copy orders
```sql
EXEC [RecurringInvestment].[PlanInstanceGetCopyPendingOrders]
```

### 8.2 Manual equivalent query
```sql
SELECT PI.InstanceID, P.GCID, P.CopyType, P.CopyParentGCID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.MirrorOrderCreated IS NULL
    AND ISNULL(PI.InstanceStatusID, 5) = 5
    AND P.PlanStatusID = 1
    AND P.PlanType = 2
    AND ((P.MopType = 1 AND PI.DepositID IS NOT NULL)
         OR (P.MopType = 2 AND PI.NextOrderDate <= GETUTCDATE()))
```

### 8.3 Count pending copy orders by CopyType
```sql
SELECT P.CopyType, COUNT(*) AS PendingCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.MirrorOrderCreated IS NULL
    AND ISNULL(PI.InstanceStatusID, 5) = 5 AND P.PlanStatusID = 1 AND P.PlanType = 2
GROUP BY P.CopyType
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances and Plans column definitions, copy plan flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Copy order placement job architecture |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanInstanceGetCopyPendingOrders | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetCopyPendingOrders.sql*
