# RecurringInvestment.PlanInstancesGetThisMonthInstanceOfUserPlans

> Retrieves all plan instances scheduled for the current month for a user's active or paused plans, regardless of deposit status.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input, returns this month's instances with plan data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all plan instances scheduled for the current calendar month, regardless of whether they have been deposited, ordered, or completed. Unlike `PlanInstancesGetThisMonthExecutedInstanceOfUserPlans` which only returns deposited instances, this procedure returns ALL instances for the current month, giving a complete picture of what is planned.

This is used to show users what their plans have scheduled for the current month, including upcoming instances that have not yet been processed. The procedure includes both plan and instance columns, enabling the UI to display plan configuration alongside instance status.

The month boundary calculation uses DATETRUNC (a newer SQL Server function) for cleaner month-start calculation. Updated per EDGE-5030 (Nilly, 13/2) to filter based on NextOrderDate month. Created per EDGE-3688 (Nilly Meyrav, 30/10/2024).

---

## 2. Business Logic

### 2.1 Current Month Instance Retrieval

**What**: Returns all instances for the current UTC month, regardless of execution status.

**Columns/Parameters Involved**: `@GCID`, `PlanStatusID`, `NextOrderDate`

**Rules**:
- PlanStatusID IN (1, 5): active or paused plans
- NextOrderDate >= DATETRUNC(month, GETUTCDATE()): first day of current month
- NextOrderDate < DATETRUNC(month, DATEADD(month, 1, GETUTCDATE())): first day of next month
- No filter on HighLevelDepositStatusId (all instances, not just deposited)
- No filter on InstanceStatusID (all statuses)
- Returns both instance and plan columns

**Diagram**:
```
Current Month (UTC):
  Month Start <--- ALL instances with NextOrderDate here ---> Next Month Start
  (No deposit status filter -- includes pending, in-progress, completed)
```

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
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled order date (within current month). |
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
| 31 | PlanStatusID | int | NO | - | VERIFIED | 1=Active or 5=Paused. See [Plan Status](../../_glossary.md#plan-status). |
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
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Instance data for current month |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Plan config for active/paused plans |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Shows all current-month instances for user dashboard |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesGetThisMonthInstanceOfUserPlans (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, date-filtered by DATETRUNC |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by GCID/PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Current month plan status display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses DATETRUNC function (SQL Server 2022+) for month boundary calculation
- Uses GETUTCDATE() for UTC-based month boundaries

---

## 8. Sample Queries

### 8.1 Get this month's instances for a user
```sql
EXEC [RecurringInvestment].[PlanInstancesGetThisMonthInstanceOfUserPlans] @GCID = 12345678
```

### 8.2 Manual DATETRUNC equivalent
```sql
SELECT PI.InstanceID, PI.PlanID, PI.NextOrderDate, PI.InstanceStatusID, P.InstrumentID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID IN (1, 5)
    AND PI.NextOrderDate >= DATETRUNC(month, GETUTCDATE())
    AND PI.NextOrderDate < DATETRUNC(month, DATEADD(month, 1, GETUTCDATE()))
```

### 8.3 Check which plans still need deposit this month
```sql
SELECT PI.PlanID, PI.InstanceID, PI.NextOrderDate, PI.DepositID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID IN (1, 5) AND PI.DepositID IS NULL
    AND PI.NextOrderDate >= DATETRUNC(month, GETUTCDATE())
    AND PI.NextOrderDate < DATETRUNC(month, DATEADD(month, 1, GETUTCDATE()))
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plan and instance structures |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket (Nilly Meyrav, 30/10/2024) |
| [EDGE-5030](https://etoro-jira.atlassian.net/browse/EDGE-5030) | Jira | Updated to filter by NextOrderDate month |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstancesGetThisMonthInstanceOfUserPlans | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesGetThisMonthInstanceOfUserPlans.sql*
