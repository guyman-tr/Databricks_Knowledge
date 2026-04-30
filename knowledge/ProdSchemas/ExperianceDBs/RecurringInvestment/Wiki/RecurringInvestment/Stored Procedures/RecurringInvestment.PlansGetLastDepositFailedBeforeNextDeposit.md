# RecurringInvestment.PlansGetLastDepositFailedBeforeNextDeposit

> Identifies active plans approaching their next deposit window that had a soft-decline deposit failure on their previous instance, enabling pre-deposit intervention.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HoursBeforeDeposit input, returns plans with prior soft-decline failures |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports a proactive deposit failure recovery mechanism. When a recurring investment plan's deposit fails with a "soft decline" (temporary payment failure), the system needs to know about it before the next deposit attempt so it can take corrective action -- such as notifying the user, switching to a backup payment method, or pausing the plan.

The procedure finds plans where: (1) the next deposit is approaching within a configurable time window, and (2) the previous deposit cycle failed with a soft decline (HighLevelDepositStatusId = 2, DepositFailReason = 1). This allows the calling service to intervene before the next deposit is attempted, reducing the chance of consecutive failures.

Created per EDGE-5929 (Miri Rismani, 10/08/2025).

---

## 2. Business Logic

### 2.1 Ranked Instance CTE

**What**: Builds a ranked view of all instances per plan, ordered by NextOrderDate descending.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`, `ROW_NUMBER()`, `PlanStatusID`

**Rules**:
- CTE joins PlanInstances to Plans with PlanStatusID = 1 (active only)
- ROW_NUMBER() OVER (PARTITION BY PI.PlanID ORDER BY PI.NextOrderDate DESC) assigns RowNum
- RowNum = 1 is the most recent (upcoming) instance
- RowNum = 2 is the previous (last completed) instance
- Returns all PlanInstances and Plans columns for downstream filtering

### 2.2 Upcoming Deposit Time Window Filter

**What**: Filters the latest instance (RowNum=1) to those within a configurable time window around @HoursBeforeDeposit.

**Columns/Parameters Involved**: `@HoursBeforeDeposit`, `NextOrderDate`, `RowNum`

**Rules**:
- NextOrderDate > DATEADD(HOUR, @HoursBeforeDeposit - 1, GETUTCDATE()) -- lower bound
- NextOrderDate < DATEADD(HOUR, @HoursBeforeDeposit + 1, GETUTCDATE()) -- upper bound
- This creates a +/- 1 hour window centered on @HoursBeforeDeposit hours from now
- Example: @HoursBeforeDeposit = 24 finds plans depositing between 23 and 25 hours from now

### 2.3 Previous Instance Soft Decline Check

**What**: Checks whether the previous instance (RowNum=2) had a soft-decline deposit failure.

**Columns/Parameters Involved**: `HighLevelDepositStatusId`, `DepositFailReason`, `RowNum`

**Rules**:
- RowNum = 2 identifies the previous instance
- HighLevelDepositStatusId = 2 means SoftDecline (see [High Level Deposit Status](../../_glossary.md#high-level-deposit-status))
- DepositFailReason = 1 is a specific failure code
- INNER JOIN between upcoming instances and failed previous instances ensures both conditions are met

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBeforeDeposit | int | NO | - | VERIFIED | Number of hours before the next deposit to look for plans. Creates a +/-1 hour window. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | PlanInstances.InstanceID of the upcoming instance. |
| 2 | PlanID | int | NO | - | VERIFIED | PlanInstances.PlanID. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled date for the upcoming deposit. |
| 4 | DepositID | bigint | YES | - | VERIFIED | Deposit transaction ID (NULL for upcoming instance). |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle counter. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | When deposit was executed. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit status. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | int | YES | - | VERIFIED | Reason code for deposit failure. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | When order was placed. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order status. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trade order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position lifecycle status. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | When position was opened. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code if position failed. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle status. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Whether mirror order was created. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror order identifier. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code). |
| 24 | GCID | bigint | NO | - | VERIFIED | User's Global Customer ID. |
| 25 | CID | bigint | YES | - | VERIFIED | User's Customer ID. |
| 26 | InstrumentID | int | YES | - | VERIFIED | Instrument for instrument-type plans. |
| 27 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 28 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 29 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 30 | PlanStatusID | int | NO | - | VERIFIED | Always 1 (Active). See [Plan Status](../../_glossary.md#plan-status). |
| 31 | StatusReasonID | int | YES | - | VERIFIED | Reason for plan status. |
| 32 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 33 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL for active plans. |
| 34 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 35 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 36 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 37 | HasBackupPayment | bit | YES | - | VERIFIED | Whether fallback payment is configured. |
| 38 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 39 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 40 | CopyType | int | NO | - | VERIFIED | Copy trading type. See [Copy Type](../../_glossary.md#copy-type). |
| 41 | PlanType | int | NO | - | VERIFIED | Instrument (1) or Copy (2). See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 43 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 44 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | Active plans data source |
| - | RecurringInvestment.PlanInstances | Read | Instance ranking and failure detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit Failure Recovery Service | - | EXEC | Pre-deposit soft decline detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetLastDepositFailedBeforeNextDeposit (procedure)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | INNER JOIN in CTE, filtered by PlanStatusID = 1 |
| RecurringInvestment.PlanInstances | Table | CTE source for ROW_NUMBER ranking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit Failure Recovery Service | Application | Checks for plans with prior soft declines before next deposit |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints
- No transaction wrapper (read-only procedure)
- ROW_NUMBER window function partitions by PlanID, orders by NextOrderDate DESC
- Time window calculation uses DATEADD with +/-1 hour margin around @HoursBeforeDeposit

---

## 8. Sample Queries

### 8.1 Find plans with soft decline 24 hours before next deposit
```sql
EXEC [RecurringInvestment].[PlansGetLastDepositFailedBeforeNextDeposit]
    @HoursBeforeDeposit = 24
```

### 8.2 Find plans with soft decline 48 hours before next deposit
```sql
EXEC [RecurringInvestment].[PlansGetLastDepositFailedBeforeNextDeposit]
    @HoursBeforeDeposit = 48
```

### 8.3 Manual verification of soft-decline instances
```sql
SELECT PI.PlanID, PI.NextOrderDate, PI.HighLevelDepositStatusId, PI.DepositFailReason,
       ROW_NUMBER() OVER (PARTITION BY PI.PlanID ORDER BY PI.NextOrderDate DESC) AS RowNum
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.PlanStatusID = 1
ORDER BY PI.PlanID, PI.NextOrderDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances deposit status fields, HighLevelDepositStatusId values |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Deposit failure handling architecture |
| [EDGE-5929](https://etoro-jira.atlassian.net/browse/EDGE-5929) | Jira | Soft decline pre-deposit detection feature |

---

*Generated: 2026-04-13 | Quality: 9.3/10*
*Object: RecurringInvestment.PlansGetLastDepositFailedBeforeNextDeposit | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetLastDepositFailedBeforeNextDeposit.sql*
