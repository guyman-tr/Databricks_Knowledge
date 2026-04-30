# RecurringInvestment.PlansGetPlansAndItsLatestInstance

> Retrieves all plans for a user (by GCID) with only their most recent instance, with optional plan status filtering.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + optional @PlanStatusID, returns plans with latest instance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a comprehensive view of a user's recurring investment plans along with the current state of each plan's execution cycle. For each plan, it returns only the most recent instance (the one with the latest NextOrderDate), giving a snapshot of where each plan currently stands in its lifecycle.

Unlike PlansGetUserActivePlansAndItsLatestInstance which is restricted to active plans, this procedure can return plans in any status. The optional @PlanStatusID parameter allows filtering to a specific status (e.g., active only, cancelled only) or returning all plans when NULL.

This is the GCID-based version. An equivalent CID-based version exists as PlansGetPlansAndItsLatestInstanceByCID.

Created per Nilly Ron 19/05/2025.

---

## 2. Business Logic

### 2.1 Latest Instance CTE with ROW_NUMBER

**What**: Ranks all instances per plan by NextOrderDate descending to identify the most recent one.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`, `ROW_NUMBER()`, `@GCID`, `@PlanStatusID`

**Rules**:
- CTE selects all PlanInstances columns
- WHERE clause uses a subquery: PlanID IN (SELECT ID FROM Plans WHERE GCID = @GCID AND optional status filter)
- ROW_NUMBER() OVER (PARTITION BY PlanID ORDER BY NextOrderDate DESC) assigns RowNum
- The @PlanStatusID filter uses pattern: (@PlanStatusID IS NULL OR PlanStatusID = @PlanStatusID)
- This allows the parameter to be optional -- NULL means all statuses

### 2.2 Final Join with RowNum = 1 Filter

**What**: Joins the latest instance back to Plans to return the complete plan + instance data.

**Columns/Parameters Involved**: `RowNum`, `PlanID`, all Plans and PlanInstances columns

**Rules**:
- INNER JOIN LatestInstances to Plans on PlanID = ID
- WHERE RowNum = 1 ensures only the most recent instance per plan is returned
- Plans without any instances are NOT returned (INNER JOIN)
- Returns both instance-level columns (deposit, order, position data) and plan-level columns

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user whose plans to retrieve. |
| 2 | @PlanStatusID | int | YES | NULL | VERIFIED | Optional plan status filter. NULL returns all statuses. See [Plan Status](../../_glossary.md#plan-status). |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | PlanInstances.InstanceID of the latest instance. |
| 2 | PlanID | int | NO | - | VERIFIED | PlanInstances.PlanID. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled date for this instance's execution. |
| 4 | DepositID | bigint | YES | - | VERIFIED | Deposit transaction ID. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle counter. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | When deposit was executed. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit status. |
| 8 | DepositFailReason | int | YES | - | VERIFIED | Reason code for deposit failure. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | When order was placed. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order status. |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trade order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position lifecycle status. |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | When position was opened. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code if position failed. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle status. |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Whether mirror order was created. |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror order identifier. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |
| 24 | PlanID | int | NO | - | VERIFIED | Plans.ID (aliased from P.ID). |
| 25 | GCID | bigint | NO | - | VERIFIED | User's Global Customer ID. |
| 26 | CID | bigint | YES | - | VERIFIED | User's Customer ID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Instrument for instrument-type plans. |
| 28 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 29 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 30 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 31 | PlanStatusID | int | NO | - | VERIFIED | Plan lifecycle state. |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Reason for current status. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 34 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL if active. |
| 35 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 36 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. |
| 37 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 38 | HasBackupPayment | bit | YES | - | VERIFIED | Whether fallback payment is configured. |
| 39 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 40 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 41 | CopyType | int | NO | - | VERIFIED | Copy trading type. |
| 42 | PlanType | int | NO | - | VERIFIED | Instrument (1) or Copy (2). |
| 43 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 44 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 45 | MopType | int | NO | - | VERIFIED | Payment method type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | RecurringInvestment.Plans | Read | Filters plans by user's GCID |
| - | RecurringInvestment.PlanInstances | Read | Ranks instances by NextOrderDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring Investment API | - | EXEC | Returns plan + latest instance data for user dashboard |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetPlansAndItsLatestInstance (procedure)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | Subquery filter by GCID and status, INNER JOIN for plan data |
| RecurringInvestment.PlanInstances | Table | CTE source for ROW_NUMBER ranking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring Investment API | Application | User-facing plan + instance retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints
- No transaction wrapper (read-only procedure)
- INNER JOIN means plans with zero instances are excluded from results
- @PlanStatusID defaults to NULL (all statuses)

---

## 8. Sample Queries

### 8.1 Get all plans with latest instance for a user
```sql
EXEC [RecurringInvestment].[PlansGetPlansAndItsLatestInstance]
    @GCID = 12345678
```

### 8.2 Get only active plans with latest instance
```sql
EXEC [RecurringInvestment].[PlansGetPlansAndItsLatestInstance]
    @GCID = 12345678,
    @PlanStatusID = 1
```

### 8.3 Get only cancelled plans with latest instance
```sql
EXEC [RecurringInvestment].[PlansGetPlansAndItsLatestInstance]
    @GCID = 12345678,
    @PlanStatusID = 2
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances table structure, instance lifecycle |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Plan retrieval patterns used by the API layer |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlansGetPlansAndItsLatestInstance | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetPlansAndItsLatestInstance.sql*
