# dbo.VW_Plans

> Denormalized view joining Plans, PlanInstances, and UserDeposits into a single flattened result set for reporting and troubleshooting.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base tables: RecurringInvestment.Plans + PlanInstances + UserDeposits |
| **Partition** | N/A |
| **Indexes** | N/A (no SCHEMABINDING) |

---

## 1. Business Meaning

This view provides a single denormalized result set that combines all three core recurring investment tables: Plans (subscription configuration), PlanInstances (execution cycle data), and UserDeposits (deposit tracking). It eliminates the need to manually JOIN these tables when investigating plan execution history, troubleshooting deposit/order/position issues, or building reports.

Without this view, every query that needs plan + instance + deposit data together would require writing the three-table JOIN explicitly. This view centralizes that pattern for ad-hoc querying, the AI Troubleshooting Service (per Confluence), and reporting dashboards.

Created by Noga on 16/4/25. The view uses INNER JOIN between Plans and PlanInstances (so plans with no instances are excluded) and LEFT JOIN to UserDeposits (so instances without deposit records still appear). All tables use NOLOCK hints for non-blocking reads.

---

## 2. Business Logic

### 2.1 JOIN Strategy and Data Completeness

**What**: The JOIN types determine which rows appear and which deposit data is available.

**Columns/Parameters Involved**: Plans.ID -> PlanInstances.PlanID (INNER), Plans.GCID + PlanInstances.DepositID -> UserDeposits.GCID + DepositID (LEFT)

**Rules**:
- INNER JOIN Plans to PlanInstances: Only plans that have at least one instance appear. Plans stuck in Initializing (0) with no instances are excluded.
- LEFT JOIN to UserDeposits: Instances without deposit records (future instances, instances where deposit hasn't occurred yet) still appear with NULL deposit columns (D_DepositID, D_DepositAmountUsd, D_DepositAmountCurrency, D_DepositDate).
- The UserDeposits JOIN uses both GCID and DepositID, matching the user-level deposit to the specific instance's deposit.

### 2.2 Column Aliasing Convention

**What**: Columns from different tables that share names are aliased with prefixes.

**Columns/Parameters Involved**: Multiple aliased columns

**Rules**:
- Plans columns: P_CreationDate, P_Trace, P_ValidFrom, P_ValidTo (prefixed with P_)
- PlanInstances columns: PI_CreationDate, PI_Trace, PI_ValidFrom, PI_ValidTo, PI_InstanceStatusID (prefixed with PI_)
- UserDeposits columns: D_DepositID, D_DepositAmountUsd, D_DepositAmountCurrency, D_DepositDate (prefixed with D_)
- Unprefixed columns come from their primary source table (e.g., PlanID from Plans, InstanceID from PlanInstances)

---

## 3. Data Overview

| PlanID | GCID | InstrumentID | PlanStatusID | InstanceID | NextOrderDate | PositionStatus | PI_InstanceStatusID | D_DepositAmountUsd | Meaning |
|--------|------|--------------|--------------|------------|---------------|----------------|---------------------|--------------------|---------|
| 189 | 17991671 | 100000 | 1 | 209781 | 2026-04-10 | 1 | 1 | 50.00 | Successful cycle: active plan for instrument 100000, instance completed with position opened, deposit of $50 from UserDeposits. Full happy-path execution. |
| 569 | 8796680 | 100000 | 1 | 209782 | 2026-04-10 | 1 | 1 | 285.00 | Another successful cycle for the same instrument but different user. Higher deposit ($285) indicates multiple plans aggregated. |
| 656 | 30774913 | 3040 | 1 | 209786 | 2026-04-10 | 1 | 1 | 117.00 | Successful cycle for a different instrument (3040). Deposit of $117. All three stages completed. |

---

## 4. Elements

**Plan Columns (from RecurringInvestment.Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanID | int | NO | - | VERIFIED | Plans.ID - unique auto-incrementing identifier for the recurring investment plan. Aliased from Plans.ID. Users can have multiple plans. |
| 2 | GCID | bigint | NO | - | VERIFIED | Global Customer ID - unique identifier of the eToro user who owns this plan. From Plans table. |
| 3 | CID | bigint | YES | - | VERIFIED | Customer ID - alternate unique identifier of the user. From Plans table. |
| 4 | InstrumentID | int | YES | - | VERIFIED | ID of the instrument for Instrument-type plans (PlanType=1). NULL for Copy-type plans. From Plans table. |
| 5 | RecurringDepositID | int | YES | - | VERIFIED | ID of the linked Recurring Deposit Plan from Money Group. All active plans for a user share the same RecurringDepositID. From Plans table. |
| 6 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in the plan's CurrencyID. From Plans table. |
| 7 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. Based on [etoro].[Dictionary].[Currency]. From Plans table. |
| 8 | PlanStatusID | int | NO | - | VERIFIED | Plan lifecycle state: 0=Initializing, 1=Active, 2=Cancelled, 3=Stopped (unused), 4=Invalid (unused). See [Plan Status](../../_glossary.md#plan-status). From Plans table. |
| 9 | DepositPlanStatusID | int | YES | - | VERIFIED | DEPRECATED - status of the linked recurring deposit plan. Marked for deletion per Confluence. From Plans table. |
| 10 | StatusReasonID | int | YES | - | VERIFIED | Reason for current plan status. Maps to Dictionary.PlanEventCode. See [Plan Event Code](../../_glossary.md#plan-event-code). From Plans table. |
| 11 | P_CreationDate | datetime | NO | - | VERIFIED | When the plan was created. Aliased from Plans.CreationDate. |
| 12 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL for active plans. From Plans table. |
| 13 | DepositStartDate | datetime | YES | - | VERIFIED | When the plan's first deposit occurred. From Plans table. |
| 14 | FrequencyID | int | NO | - | VERIFIED | Execution cadence: 3=Monthly (only active frequency). See [Plan Frequencies](../../_glossary.md#plan-frequencies). From Plans table. |
| 15 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution (1-28). From Plans table. |
| 16 | FundingID | int | YES | - | VERIFIED | Payment method ID. From Plans table. |
| 17 | P_Trace | computed | NO | - | CODE-BACKED | Computed audit JSON from Plans table. Aliased from Plans.Trace. |
| 18 | P_ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start from Plans table. |
| 19 | P_ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end from Plans table. |

**PlanInstance Columns (from RecurringInvestment.PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 20 | InstanceID | int | NO | - | VERIFIED | Unique surrogate key for the instance. From PlanInstances table. |
| 21 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance. From PlanInstances table. |
| 22 | PI_CreationDate | datetime | NO | - | VERIFIED | When this instance record was created. Aliased from PlanInstances.CreationDate. |
| 23 | DepositID | int | YES | - | VERIFIED | Deposit identifier from Money ServiceBus. From PlanInstances table. Also used in LEFT JOIN to UserDeposits. |
| 24 | DepositAmountUsd | decimal(18,2) | YES | - | VERIFIED | DEPRECATED - deposit amount in USD from PlanInstances. Marked for deletion. |
| 25 | DepositAmountCurrency | decimal(18,2) | YES | - | VERIFIED | DEPRECATED - deposit amount in plan currency from PlanInstances. Marked for deletion. |
| 26 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle number from Billing system. From PlanInstances table. |
| 27 | DepositDate | datetime | YES | - | VERIFIED | When the deposit was made. From PlanInstances table. |
| 28 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). From PlanInstances table. |
| 29 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status from Billing DB. From PlanInstances table. |
| 30 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state: 1=Received through 11=WaitingForMarket. See [Order Status](../../_glossary.md#order-status). From PlanInstances table. |
| 31 | OrderID | int | YES | - | VERIFIED | Order identifier from Trading API. From PlanInstances table. |
| 32 | OrderTradeDate | datetime | YES | - | VERIFIED | When the order was requested from TAPI. From PlanInstances table. |
| 33 | PositionStatus | int | YES | - | VERIFIED | Position outcome: 1=Success, 2=Failed, 3=InProgress, etc. See [Position Status](../../_glossary.md#position-status). From PlanInstances table. |
| 34 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Actual position amount in USD. From PlanInstances table. |
| 35 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Actual position amount in plan currency. From PlanInstances table. |
| 36 | PositionExecutionDate | datetime | YES | - | VERIFIED | When the position was opened. From PlanInstances table. |
| 37 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code from Trading API when position open fails. From PlanInstances table. |
| 38 | NotificationSent | bit | YES | - | VERIFIED | DEPRECATED - notification flag. From PlanInstances table. |
| 39 | NotificationReason | int | YES | - | VERIFIED | DEPRECATED - notification reason. From PlanInstances table. |
| 40 | InstanceStatus | bit | YES | - | VERIFIED | DEPRECATED - legacy done flag. From PlanInstances table. |
| 41 | UpdateDate | datetime | NO | - | VERIFIED | Last modification timestamp. From PlanInstances table. |
| 42 | PI_Trace | computed | NO | - | CODE-BACKED | Computed audit JSON from PlanInstances table. |
| 43 | PI_ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start from PlanInstances table. |
| 44 | PI_ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end from PlanInstances table. |
| 45 | PI_InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state: 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=Technical Issue, 7=Completed without position. Aliased from PlanInstances.InstanceStatusID. See [Instance Status](../../_glossary.md#instance-status). |
| 46 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. Maps to Dictionary.PlanEventCode. From PlanInstances table. |

**UserDeposits Columns (from RecurringInvestment.UserDeposits - LEFT JOIN)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 47 | D_DepositID | int | YES | - | VERIFIED | Deposit identifier from UserDeposits table. NULL when no matching deposit record exists (LEFT JOIN). Aliased from UserDeposits.DepositID. |
| 48 | D_DepositAmountUsd | decimal(18,2) | YES | - | VERIFIED | Deposit amount in USD from UserDeposits. This is the authoritative deposit amount (vs. deprecated PlanInstances columns). NULL for unmatched instances. |
| 49 | D_DepositAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Deposit amount in plan currency from UserDeposits. NULL for unmatched instances. |
| 50 | D_DepositDate | datetime | YES | - | VERIFIED | Deposit date from UserDeposits. NULL for unmatched instances. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlanID | RecurringInvestment.Plans | INNER JOIN | Plans.ID = PlanInstances.PlanID |
| InstanceID | RecurringInvestment.PlanInstances | INNER JOIN | PlanInstances joined to Plans |
| D_DepositID | RecurringInvestment.UserDeposits | LEFT JOIN | UserDeposits.GCID = Plans.GCID AND UserDeposits.DepositID = PlanInstances.DepositID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This view is likely used for ad-hoc querying and the AI Troubleshooting Service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.VW_Plans (view)
+-- RecurringInvestment.Plans (table)
+-- RecurringInvestment.PlanInstances (table)
+-- RecurringInvestment.UserDeposits (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | INNER JOIN - plan configuration data |
| RecurringInvestment.PlanInstances | Table | INNER JOIN - instance execution data |
| RecurringInvestment.UserDeposits | Table | LEFT JOIN - deposit tracking data |

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View (no SCHEMABINDING, no indexed view).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get full execution history for a user
```sql
SELECT PlanID, InstrumentID, NextOrderDate, HighLevelDepositStatusId,
       OrderStatusId, PositionStatus, PI_InstanceStatusID, D_DepositAmountUsd
FROM dbo.VW_Plans WITH (NOLOCK)
WHERE GCID = @GCID
ORDER BY NextOrderDate DESC
```

### 8.2 Find failed instances with deposit and plan context
```sql
SELECT PlanID, GCID, InstrumentID, NextOrderDate, PI_InstanceStatusID,
       InstanceStatusReasonID, HighLevelDepositStatusId, D_DepositAmountUsd
FROM dbo.VW_Plans WITH (NOLOCK)
WHERE PI_InstanceStatusID NOT IN (1, 5)
  AND PlanStatusID = 1
ORDER BY NextOrderDate DESC
```

### 8.3 Aggregate successful investments per user
```sql
SELECT GCID, COUNT(*) AS SuccessfulCycles,
       SUM(PositionAmountUsd) AS TotalInvestedUsd
FROM dbo.VW_Plans WITH (NOLOCK)
WHERE PI_InstanceStatusID = 1
GROUP BY GCID
ORDER BY TotalInvestedUsd DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans, PlanInstances, and UserDeposits table structures and column descriptions |
| [AI Troubleshooting Service](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13388283923/AI+Troubleshooting+Service) | Confluence | Recurring Investments Troubleshooting Service may use this denormalized view for investigation |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Three-stage pipeline (deposit -> order -> position) that produces the data this view exposes |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 44 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.VW_Plans | Type: View | Source: RecurringInvestment/dbo/Views/dbo.VW_Plans.sql*
