# RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstance

> Retrieves all active plans for a user (by GCID) with only their most recent instance, providing a snapshot of current plan execution state.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input, returns active plans with latest instance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a focused view of a user's active recurring investment plans along with the current execution state of each. It returns only active plans (PlanStatusID = 1) and for each plan, only the most recent instance (highest NextOrderDate). This combination gives the application a concise snapshot of what is currently happening with each of the user's live plans.

This is the original active-plans-only retrieval procedure. The later PlansGetPlansAndItsLatestInstance extends this by adding an optional status filter parameter, allowing retrieval of plans in any status. This procedure remains in use for callers that specifically need only active plans.

This is the GCID-based version. An equivalent CID-based version exists as PlansGetUserActivePlansAndItsLatestInstanceByCID.

Created per Nilly Ron 16/12/24.

---

## 2. Business Logic

### 2.1 Active Plans Latest Instance CTE

**What**: Ranks instances for active plans only, ordered by NextOrderDate descending.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`, `ROW_NUMBER()`, `PlanStatusID`, `@GCID`

**Rules**:
- CTE selects all PlanInstances columns
- WHERE clause uses a subquery: PlanID IN (SELECT ID FROM Plans WHERE PlanStatusID = 1 AND GCID = @GCID)
- The PlanStatusID = 1 filter is hardcoded (not parameterized) -- only active plans
- ROW_NUMBER() OVER (PARTITION BY PlanID ORDER BY NextOrderDate DESC) assigns RowNum
- RowNum = 1 is the most recent instance for each plan

### 2.2 Final Join with RowNum = 1

**What**: Joins the latest instance back to Plans and filters to only the newest instance per plan.

**Columns/Parameters Involved**: `RowNum`, `PlanID`, all Plans and PlanInstances columns

**Rules**:
- INNER JOIN LatestInstances to Plans on PlanID = ID
- WHERE RowNum = 1 ensures only the most recent instance is returned
- Plans without any instances are NOT returned (INNER JOIN)
- Returns full instance data (deposit, order, position stages) alongside plan configuration

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user whose active plans to retrieve. |

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
| 31 | PlanStatusID | int | NO | - | VERIFIED | Always 1 (Active). See [Plan Status](../../_glossary.md#plan-status). |
| 32 | StatusReasonID | int | YES | - | VERIFIED | Reason for current status. |
| 33 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 34 | EndDate | datetime | YES | - | VERIFIED | NULL for active plans. |
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
| @GCID | RecurringInvestment.Plans | Read | Filters active plans by user's GCID |
| - | RecurringInvestment.PlanInstances | Read | Ranks instances by NextOrderDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring Investment API | - | EXEC | Active plan + current instance retrieval for user dashboard |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstance (procedure)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | Subquery filter by GCID and PlanStatusID = 1, INNER JOIN for plan data |
| RecurringInvestment.PlanInstances | Table | CTE source for ROW_NUMBER ranking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring Investment API | Application | Active plan retrieval for user-facing features |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints
- No transaction wrapper (read-only procedure)
- INNER JOIN means active plans with zero instances are excluded
- Hardcoded PlanStatusID = 1 filter (not parameterized)

---

## 8. Sample Queries

### 8.1 Get active plans with latest instance for a user
```sql
EXEC [RecurringInvestment].[PlansGetUserActivePlansAndItsLatestInstance]
    @GCID = 12345678
```

### 8.2 Count active plans per user
```sql
SELECT GCID, COUNT(*) AS ActivePlanCount
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE PlanStatusID = 1
GROUP BY GCID
ORDER BY ActivePlanCount DESC
```

### 8.3 Verify latest instance selection
```sql
SELECT PI.PlanID, PI.InstanceID, PI.NextOrderDate,
       ROW_NUMBER() OVER (PARTITION BY PI.PlanID ORDER BY PI.NextOrderDate DESC) AS RowNum
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND P.PlanStatusID = 1
ORDER BY PI.PlanID, PI.NextOrderDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances table structure, plan status values |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Plan retrieval patterns and instance lifecycle |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstance | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstance.sql*
