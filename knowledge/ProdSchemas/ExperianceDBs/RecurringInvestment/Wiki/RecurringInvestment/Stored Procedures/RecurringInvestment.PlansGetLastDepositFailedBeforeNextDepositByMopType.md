# RecurringInvestment.PlansGetLastDepositFailedBeforeNextDepositByMopType

> Identifies active plans approaching their next deposit window that had a soft-decline failure on their previous instance, filtered by specific payment method (MOP) types.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HoursBeforeDeposit + @MopTypes TVP input, returns plans with prior soft-decline filtered by MOP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the MOP-type-filtered variant of PlansGetLastDepositFailedBeforeNextDeposit. It performs the same soft-decline detection logic but adds an additional filter to only return plans using specific payment method types (MOP types such as credit card, wire transfer, PayPal, etc.).

Different payment processors may have different retry policies or failure handling requirements. By filtering on MOP type, the calling service can apply payment-method-specific recovery strategies. For example, credit card soft declines may warrant an automatic retry, while other payment methods may require user notification.

Created per EDGE-5929 (Miri Rismani, 10/08/2025).

---

## 2. Business Logic

### 2.1 Ranked Instance CTE with MOP Type Filter

**What**: Builds a ranked view of all instances per plan, restricted to specific MOP types.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`, `ROW_NUMBER()`, `PlanStatusID`, `MopType`, `@MopTypes`

**Rules**:
- CTE joins PlanInstances to Plans with PlanStatusID = 1 (active only)
- INNER JOIN to @MopTypes TVP on P.MopType = MT.ColunmINT filters to specified payment methods
- ROW_NUMBER() OVER (PARTITION BY PI.PlanID ORDER BY PI.NextOrderDate DESC) assigns RowNum
- RowNum = 1 is the most recent (upcoming) instance; RowNum = 2 is the previous one
- Note: The join column name "ColunmINT" in IntType contains a typo preserved from the original DDL

### 2.2 Upcoming Deposit Time Window Filter

**What**: Filters the latest instance (RowNum=1) to those within the deposit time window.

**Columns/Parameters Involved**: `@HoursBeforeDeposit`, `NextOrderDate`, `RowNum`

**Rules**:
- NextOrderDate > DATEADD(HOUR, @HoursBeforeDeposit - 1, GETUTCDATE()) -- lower bound
- NextOrderDate < DATEADD(HOUR, @HoursBeforeDeposit + 1, GETUTCDATE()) -- upper bound
- Creates a +/- 1 hour window centered on @HoursBeforeDeposit hours from now

### 2.3 Previous Instance Soft Decline Check

**What**: Checks whether the previous instance (RowNum=2) had a soft-decline deposit failure.

**Columns/Parameters Involved**: `HighLevelDepositStatusId`, `DepositFailReason`, `RowNum`

**Rules**:
- RowNum = 2 identifies the previous instance
- HighLevelDepositStatusId = 2 means SoftDecline
- DepositFailReason = 1 is the specific failure reason
- INNER JOIN between upcoming and failed-previous subqueries on PlanID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBeforeDeposit | int | NO | - | VERIFIED | Number of hours before the next deposit to look for plans. Creates a +/-1 hour window. |
| 2 | @MopTypes | RecurringInvestment.IntType (TVP) | NO | - | VERIFIED | List of MOP type IDs to filter by. See [MOP Type](../../_glossary.md#mop-type). |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | PlanInstances.InstanceID of the upcoming instance. |
| 2 | PlanID | int | NO | - | VERIFIED | PlanInstances.PlanID. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled date for the upcoming deposit. |
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
| 24 | GCID | bigint | NO | - | VERIFIED | User's Global Customer ID. |
| 25 | CID | bigint | YES | - | VERIFIED | User's Customer ID. |
| 26 | InstrumentID | int | YES | - | VERIFIED | Instrument for instrument-type plans. |
| 27 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 28 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle. |
| 29 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 30 | PlanStatusID | int | NO | - | VERIFIED | Always 1 (Active). |
| 31 | StatusReasonID | int | YES | - | VERIFIED | Reason for plan status. |
| 32 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 33 | EndDate | datetime | YES | - | VERIFIED | NULL for active plans. |
| 34 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 35 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. |
| 36 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 37 | HasBackupPayment | bit | YES | - | VERIFIED | Whether fallback payment is configured. |
| 38 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 39 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 40 | CopyType | int | NO | - | VERIFIED | Copy trading type. |
| 41 | PlanType | int | NO | - | VERIFIED | Instrument (1) or Copy (2). |
| 42 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 43 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 44 | MopType | int | NO | - | VERIFIED | Payment method type (filtered by @MopTypes). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | Active plans data source, MopType filter target |
| - | RecurringInvestment.PlanInstances | Read | Instance ranking and failure detection |
| @MopTypes | RecurringInvestment.IntType | TVP | MOP type filter list |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit Failure Recovery Service | - | EXEC | MOP-specific pre-deposit soft decline detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetLastDepositFailedBeforeNextDepositByMopType (procedure)
├── RecurringInvestment.Plans (table)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.IntType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | INNER JOIN in CTE, filtered by PlanStatusID = 1 |
| RecurringInvestment.PlanInstances | Table | CTE source for ROW_NUMBER ranking |
| RecurringInvestment.IntType | User Defined Type | TVP for MOP type filter list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit Failure Recovery Service | Application | MOP-specific soft decline pre-check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints
- No transaction wrapper (read-only procedure)
- @MopTypes TVP is READONLY
- Identical logic to PlansGetLastDepositFailedBeforeNextDeposit with added MOP type INNER JOIN

---

## 8. Sample Queries

### 8.1 Find credit card plans with soft decline 24 hours before deposit
```sql
DECLARE @MopTypes RecurringInvestment.IntType
INSERT INTO @MopTypes (ColunmINT) VALUES (1), (3)  -- Credit card MOP types

EXEC [RecurringInvestment].[PlansGetLastDepositFailedBeforeNextDepositByMopType]
    @HoursBeforeDeposit = 24,
    @MopTypes = @MopTypes
```

### 8.2 Find all wire transfer plans with soft decline 48 hours before deposit
```sql
DECLARE @MopTypes RecurringInvestment.IntType
INSERT INTO @MopTypes (ColunmINT) VALUES (2)  -- Wire transfer MOP type

EXEC [RecurringInvestment].[PlansGetLastDepositFailedBeforeNextDepositByMopType]
    @HoursBeforeDeposit = 48,
    @MopTypes = @MopTypes
```

### 8.3 Verify MOP type distribution of affected plans
```sql
SELECT P.MopType, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] P WITH (NOLOCK)
WHERE P.PlanStatusID = 1
GROUP BY P.MopType
ORDER BY PlanCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | MopType column in Plans, deposit status fields in PlanInstances |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Payment method handling and deposit failure architecture |
| [EDGE-5929](https://etoro-jira.atlassian.net/browse/EDGE-5929) | Jira | MOP-type-filtered soft decline detection feature |

---

*Generated: 2026-04-13 | Quality: 9.3/10*
*Object: RecurringInvestment.PlansGetLastDepositFailedBeforeNextDepositByMopType | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetLastDepositFailedBeforeNextDepositByMopType.sql*
