# RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstanceByCID

> Retrieves all active plans for a user (by CID) with only their most recent instance, providing a snapshot of current plan execution state.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID input, returns active plans with latest instance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the CID-based variant of PlansGetUserActivePlansAndItsLatestInstance. It provides the same focused view of a user's active recurring investment plans with their latest instance data, but identifies the user by their Customer ID (CID) instead of Global Customer ID (GCID).

CID is the entity-specific customer identifier tied to a specific eToro regulatory entity, while GCID is the global identifier across all entities. This variant is needed for API code paths where only the CID is available from the calling context.

This is the original active-only CID-based retrieval. The later PlansGetPlansAndItsLatestInstanceByCID extends this with an optional status filter.

Created per Nilly Ron 17/12/24 (one day after the GCID version).

---

## 2. Business Logic

### 2.1 Active Plans Latest Instance CTE

**What**: Ranks instances for active plans only, filtered by CID and ordered by NextOrderDate descending.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`, `ROW_NUMBER()`, `PlanStatusID`, `@CID`

**Rules**:
- CTE selects all PlanInstances columns
- WHERE clause uses a subquery: PlanID IN (SELECT ID FROM Plans WHERE PlanStatusID = 1 AND CID = @CID)
- The PlanStatusID = 1 filter is hardcoded -- only active plans
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
| 1 | @CID | bigint | NO | - | VERIFIED | Customer ID of the user whose active plans to retrieve. Entity-specific identifier. |

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
| @CID | RecurringInvestment.Plans | Read | Filters active plans by user's CID |
| - | RecurringInvestment.PlanInstances | Read | Ranks instances by NextOrderDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring Investment API | - | EXEC | CID-based active plan + current instance retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstanceByCID (procedure)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | Subquery filter by CID and PlanStatusID = 1, INNER JOIN for plan data |
| RecurringInvestment.PlanInstances | Table | CTE source for ROW_NUMBER ranking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring Investment API | Application | CID-based active plan retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints
- No transaction wrapper (read-only procedure)
- INNER JOIN means active plans with zero instances are excluded
- Hardcoded PlanStatusID = 1 filter (not parameterized)
- Functionally identical to PlansGetUserActivePlansAndItsLatestInstance but filters by CID instead of GCID

---

## 8. Sample Queries

### 8.1 Get active plans with latest instance for a user by CID
```sql
EXEC [RecurringInvestment].[PlansGetUserActivePlansAndItsLatestInstanceByCID]
    @CID = 87654321
```

### 8.2 Find all CIDs with active plans
```sql
SELECT DISTINCT CID, COUNT(*) AS ActivePlanCount
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE PlanStatusID = 1
GROUP BY CID
ORDER BY ActivePlanCount DESC
```

### 8.3 Compare with GCID version
```sql
-- Look up the GCID for a CID
SELECT DISTINCT GCID FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE CID = 87654321

-- Then compare results:
EXEC [RecurringInvestment].[PlansGetUserActivePlansAndItsLatestInstanceByCID] @CID = 87654321
EXEC [RecurringInvestment].[PlansGetUserActivePlansAndItsLatestInstance] @GCID = 12345678
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans table CID column, plan status values |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | CID vs GCID usage patterns in API layer |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstanceByCID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetUserActivePlansAndItsLatestInstanceByCID.sql*
