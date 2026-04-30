# RecurringInvestment.PlanGetPlanAndItsInstanceByInstanceId

> Retrieves a single plan instance along with its parent plan details by GCID and InstanceID.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @InstanceID input, returns combined plan + instance row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the full details of a specific plan instance together with all columns from its parent plan. It is designed to provide a complete snapshot of a single execution cycle within a recurring investment plan, combining both the plan configuration and the instance's runtime state in one result set.

Without this procedure, the application would need to make two separate queries to get the plan and its instance, or rely on generic query patterns. This procedure encapsulates the JOIN logic and provides a single entry point for instance-level detail screens. It was created per EDGE-6008 (Miri, 27/07) and later updated by Boris (3/8/25) to align its column list with `PlansGetPlansAndItsLatestInstance`.

The procedure is called when the application needs to display detailed information about a specific instance, such as its deposit status, order progress, and position outcome, in the context of its plan configuration. The GCID parameter ensures user-level security by restricting access to plans owned by that user.

---

## 2. Business Logic

### 2.1 User-Scoped Instance Retrieval

**What**: Ensures that the requested instance belongs to a plan owned by the specified user, preventing cross-user data access.

**Columns/Parameters Involved**: `@GCID`, `@InstanceID`, `Plans.GCID`, `PlanInstances.InstanceID`

**Rules**:
- The INNER JOIN on Plans.ID = PlanInstances.PlanID links the instance to its plan
- The WHERE clause requires both P.GCID = @GCID AND PI.InstanceID = @InstanceID
- If the instance does not belong to a plan owned by the given GCID, no rows are returned
- This acts as a security boundary ensuring users can only access their own data

**Diagram**:
```
Client Request (@GCID, @InstanceID)
        |
        v
  PlanInstances (InstanceID = @InstanceID)
        |  INNER JOIN
        v
  Plans (GCID = @GCID)
        |
        v
  Combined Result: Instance columns + Plan columns
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the plan owner. Used to scope the query to a specific user's plans for security. |
| 2 | @InstanceID | int | NO | - | VERIFIED | Unique identifier of the plan instance to retrieve. Filters PlanInstances to one specific execution cycle. |

**Return Columns (PlanInstances)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique identifier for this plan instance (execution cycle). |
| 2 | PlanID | int | NO | - | VERIFIED | Foreign key to the parent plan in Plans table. |
| 3 | NextOrderDate | datetime | YES | - | VERIFIED | Scheduled date for this instance's order execution. |
| 4 | DepositID | int | YES | - | VERIFIED | ID of the deposit created for this cycle. NULL if deposit not yet attempted. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Sequential number of the deposit cycle within the plan. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Timestamp when the deposit was processed. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | nvarchar | YES | - | VERIFIED | Textual reason for deposit failure, if applicable. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Granular deposit status ID for detailed tracking. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Date when the trading order was placed. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Status of the order. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | bigint | YES | - | VERIFIED | Unique trading order ID assigned by the trading system. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Outcome of position creation. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Timestamp when the position was opened. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | USD amount of the opened position. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in the plan's currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code if position open failed. See [Plan Event Code](../../_glossary.md#plan-event-code) 1200-range. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state: 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=TechnicalIssue, 7=CompletedWithoutPosition. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason code for the instance status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Whether a mirror (copy) order was created: 1=TRUE, NULL=not created. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | bigint | YES | - | VERIFIED | ID of the mirror/copy relationship. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Status of copy position creation. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Error code if copy position failed. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code). |

**Return Columns (Plans)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | GCID | bigint | NO | - | VERIFIED | Global Customer ID of the plan owner. |
| 25 | CID | bigint | YES | - | VERIFIED | Customer ID of the plan owner. |
| 26 | InstrumentID | int | YES | - | VERIFIED | Target instrument for instrument-type plans (PlanType=1). NULL for copy plans. |
| 27 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID from Money Group. |
| 28 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in plan currency. |
| 29 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 30 | PlanStatusID | int | NO | - | VERIFIED | Plan lifecycle state: 0=Initializing, 1=Active, 2=Cancelled. See [Plan Status](../../_glossary.md#plan-status). |
| 31 | StatusReasonID | int | YES | - | VERIFIED | Reason for current plan status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 32 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 33 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL if active. |
| 34 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 35 | FrequencyID | int | NO | - | VERIFIED | Execution frequency: 3=Monthly (only active value). See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 36 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution (1-28). |
| 37 | HasBackupPayment | bit | YES | - | VERIFIED | Whether a fallback payment method is configured. |
| 38 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned temporal period start column. |
| 39 | FundingID | int | YES | - | VERIFIED | Payment method ID used for deposits. |
| 40 | CopyType | int | NO | - | VERIFIED | Copy trading type: 0=None, 1=PI, 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). |
| 41 | PlanType | int | NO | - | VERIFIED | Plan type: 1=Instrument, 2=Copy. See [Plan Type](../../_glossary.md#plan-type). |
| 42 | CopyParentCID | bigint | YES | - | VERIFIED | CID of the copied trader (for copy plans). |
| 43 | CopyParentGCID | bigint | YES | - | VERIFIED | GCID of the copied trader (for copy plans). |
| 44 | MopType | int | NO | - | VERIFIED | Method of payment type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN) | Source for instance-level execution data |
| - | RecurringInvestment.Plans | Read (INNER JOIN) | Source for plan configuration data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Called from API to display instance detail view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanGetPlanAndItsInstanceByInstanceId (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INNER JOIN, filtered by InstanceID |
| RecurringInvestment.Plans | Table | INNER JOIN, filtered by GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Calls to retrieve instance + plan detail |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Retrieve a specific instance for a user
```sql
EXEC [RecurringInvestment].[PlanGetPlanAndItsInstanceByInstanceId]
    @GCID = 12345678,
    @InstanceID = 5001
```

### 8.2 Verify the instance belongs to the user
```sql
SELECT PI.InstanceID, P.GCID, P.PlanStatusID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND PI.InstanceID = 5001
```

### 8.3 Check instance progress stage
```sql
SELECT PI.InstanceID, PI.DepositID, PI.OrderID, PI.PositionStatus, PI.InstanceStatusID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND PI.InstanceID = 5001
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances table structures, column definitions |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Instance retrieval flow within the recurring investment lifecycle |
| [EDGE-6008](https://etoro-jira.atlassian.net/browse/EDGE-6008) | Jira | Original ticket for creating this SP (Miri, 27/07) |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanGetPlanAndItsInstanceByInstanceId | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanGetPlanAndItsInstanceByInstanceId.sql*
