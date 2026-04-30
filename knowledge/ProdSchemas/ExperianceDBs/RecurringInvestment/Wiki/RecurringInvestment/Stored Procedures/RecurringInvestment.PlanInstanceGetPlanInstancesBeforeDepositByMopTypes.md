# RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDepositByMopTypes

> Retrieves plan instances eligible for deposit initiation, filtered by specific MOP (Method of Payment) types via a table-valued parameter.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MopTypes TVP input, returns instances eligible for deposit by MOP type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a MOP-type-filtered variant of `PlanInstanceGetPlanInstancesBeforeDeposit`. It identifies plan instances within the +/- 12 hour execution window that have not yet received a deposit, but additionally restricts results to plans using specific payment method types provided via the @MopTypes table-valued parameter.

This variant exists because different MOP types may require different processing pipelines or need to be handled by different services. By filtering on MOP type at the database level, the application can route deposit initiation to the correct payment processor. Created per EDGE-3688 (Nilly Ron, 16/6/2024).

The procedure is called by the Before Deposit Job when it needs to process deposits for a specific subset of payment methods, rather than all eligible instances regardless of MOP type.

---

## 2. Business Logic

### 2.1 MOP-Type Filtered Deposit Eligibility

**What**: Same time-window eligibility as BeforeDeposit SP, but filtered by specific MOP types.

**Columns/Parameters Involved**: `@MopTypes`, `Plans.MopType`, `NextOrderDate`, `DepositID`, `InstanceStatusID`, `PlanStatusID`

**Rules**:
- All rules from PlanInstanceGetPlanInstancesBeforeDeposit apply (time window, NULL DepositID, NULL InstanceStatusID, active plan)
- Additionally: INNER JOIN @MopTypes AS MT ON P.MopType = MT.ColunmINT filters by MOP type
- The TVP uses IntType with column named ColunmINT (note: original spelling preserved)
- Only instances whose plan's MopType is in the provided list are returned

**Diagram**:
```
@MopTypes TVP: [1, 2]
        |
        v
Plans WHERE MopType IN @MopTypes
        |  INNER JOIN
        v
PlanInstances WHERE:
  NextOrderDate within +/-12h
  AND DepositID IS NULL
  AND InstanceStatusID IS NULL
        |
        v
Result: MOP-filtered eligible instances
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MopTypes | RecurringInvestment.IntType (TVP) | NO | - | VERIFIED | Table-valued parameter containing MOP type IDs to filter by. Uses IntType with ColunmINT column. See [MOP Type](../../_glossary.md#mop-type). |

**Return Columns (PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique plan instance identifier. |
| 2 | PlanID | int | NO | - | VERIFIED | Parent plan ID. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled execution date (within +/-12h window). |
| 4 | DepositID | int | YES | - | VERIFIED | Always NULL in results. |
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
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Always NULL in results. |
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
| 45 | MopType | int | NO | - | VERIFIED | Payment method type (matches @MopTypes filter). See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Source for instance data |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan config, filtered by MopType |
| @MopTypes | RecurringInvestment.IntType | TVP | Provides the MOP type filter values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Before Deposit Job (MOP-specific) | - | EXEC | Processes deposit initiation for specific MOP types |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDepositByMopTypes (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.IntType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by time window |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by PlanStatusID and MopType |
| RecurringInvestment.IntType | User Defined Type | TVP parameter for MOP type filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Before Deposit Job | Background Service | MOP-specific deposit initiation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find before-deposit instances for MopType 1
```sql
DECLARE @MopTypes RecurringInvestment.IntType
INSERT INTO @MopTypes (ColunmINT) VALUES (1)
EXEC [RecurringInvestment].[PlanInstanceGetPlanInstancesBeforeDepositByMopTypes] @MopTypes
```

### 8.2 Find before-deposit instances for multiple MOP types
```sql
DECLARE @MopTypes RecurringInvestment.IntType
INSERT INTO @MopTypes (ColunmINT) VALUES (1), (2)
EXEC [RecurringInvestment].[PlanInstanceGetPlanInstancesBeforeDepositByMopTypes] @MopTypes
```

### 8.3 Compare counts between MOP-filtered and unfiltered
```sql
SELECT P.MopType, COUNT(*) AS EligibleCount
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE PI.NextOrderDate >= DATEADD(HOUR, -12, GETUTCDATE())
    AND PI.NextOrderDate < DATEADD(HOUR, 12, GETUTCDATE())
    AND PI.DepositID IS NULL AND PI.InstanceStatusID IS NULL AND P.PlanStatusID = 1
GROUP BY P.MopType
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | MOP type definitions and deposit flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Before Deposit Job architecture with MOP routing |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original ticket for this SP |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDepositByMopTypes | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceGetPlanInstancesBeforeDepositByMopTypes.sql*
