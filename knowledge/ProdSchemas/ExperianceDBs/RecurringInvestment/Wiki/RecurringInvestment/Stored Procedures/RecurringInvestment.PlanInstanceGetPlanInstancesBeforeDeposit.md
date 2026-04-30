# RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDeposit

> Retrieves plan instances within a 24-hour window around their scheduled execution time that have not yet received a deposit, for the Before Deposit Job eligibility check.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No params, returns instances eligible for deposit initiation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies plan instances that are approaching or have just passed their scheduled execution time and have not yet received a deposit. It serves as the work queue for the Before Deposit Job, which performs eligibility checks and initiates the deposit process for each qualifying instance.

The procedure uses a 24-hour window centered on the current UTC time (+/- 12 hours from NextOrderDate). This window ensures instances are picked up even if the job runs slightly before or after the exact scheduled time. Only instances with no prior deposit (DepositID IS NULL) and no processing status (InstanceStatusID IS NULL) are returned.

Without this procedure, the system would have no way to discover which instances need their deposit cycle initiated. This is the starting point of the recurring investment execution pipeline. Created per EDGE-3688 (Nilly Ron, 16/6/2024).

---

## 2. Business Logic

### 2.1 Time-Window Eligibility Check

**What**: Identifies instances within a +/- 12 hour window of their NextOrderDate that are ready for deposit initiation.

**Columns/Parameters Involved**: `NextOrderDate`, `DepositID`, `InstanceStatusID`, `PlanStatusID`

**Rules**:
- NextOrderDate IS NOT NULL: instance has a scheduled date
- NextOrderDate >= DATEADD(HOUR, -12, GETUTCDATE()): not more than 12 hours in the past
- NextOrderDate < DATEADD(HOUR, 12, GETUTCDATE()): not more than 12 hours in the future
- DepositID IS NULL: no deposit has been initiated yet
- InstanceStatusID IS NULL: instance has not started processing (fresh instance)
- PlanStatusID = 1: only active plans

**Diagram**:
```
Timeline:
  -12h        NOW        +12h
   |-----------|-----------|
   ^                       ^
   |  Eligible Window      |
   |                       |
   Instances with NextOrderDate in this range
   AND DepositID IS NULL
   AND InstanceStatusID IS NULL
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
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled execution date (within +/-12h of now). |
| 4 | DepositID | int | YES | - | VERIFIED | Always NULL in results (filter condition). |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential cycle number. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Deposit timestamp. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Deposit failure reason. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Order date. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Trading order ID. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Position open timestamp. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in plan currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Position failure error code. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Always NULL in results (filter condition). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Instance status reason. |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy order flag. |
| 21 | MirrorID | bigint | YES | - | VERIFIED | Mirror/copy ID. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position status. |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Copy failure error code. |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | PlanID | int | NO | - | VERIFIED | Plan ID (aliased from Plans.ID). |
| 25 | GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. |
| 26 | CID | bigint | YES | - | VERIFIED | Plan owner's CID. |
| 27 | InstrumentID | int | YES | - | VERIFIED | Target instrument. |
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
| 41 | PlanType | int | NO | - | VERIFIED | Plan type. See [Plan Type](../../_glossary.md#plan-type). |
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
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Before Deposit Job | - | EXEC | Discovers instances ready for deposit initiation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDeposit (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by NextOrderDate window |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Before Deposit Job | Background Service | Initiates deposit process for eligible instances |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the before-deposit check
```sql
EXEC [RecurringInvestment].[PlanInstanceGetPlanInstancesBeforeDeposit]
```

### 8.2 Preview what the SP would return
```sql
SELECT PI.InstanceID, PI.NextOrderDate, P.GCID, P.Amount, P.MopType
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.NextOrderDate >= DATEADD(HOUR, -12, GETUTCDATE())
    AND PI.NextOrderDate < DATEADD(HOUR, 12, GETUTCDATE())
    AND PI.DepositID IS NULL AND PI.InstanceStatusID IS NULL AND P.PlanStatusID = 1
```

### 8.3 Count eligible instances by plan type
```sql
SELECT P.PlanType, COUNT(*) AS EligibleCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.NextOrderDate >= DATEADD(HOUR, -12, GETUTCDATE())
    AND PI.NextOrderDate < DATEADD(HOUR, 12, GETUTCDATE())
    AND PI.DepositID IS NULL AND PI.InstanceStatusID IS NULL AND P.PlanStatusID = 1
GROUP BY P.PlanType
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Instance lifecycle and deposit initiation flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Before Deposit Job architecture |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket for this SP |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDeposit | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDeposit.sql*
