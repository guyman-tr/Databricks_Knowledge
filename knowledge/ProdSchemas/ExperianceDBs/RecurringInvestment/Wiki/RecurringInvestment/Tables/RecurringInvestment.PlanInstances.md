# RecurringInvestment.PlanInstances

> Core table tracking each execution cycle of a recurring investment plan - deposit, order, and position data for every monthly instance.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | PlanID + NextOrderDate (CLUSTERED PK), InstanceID (UNIQUE NC) |
| **Partition** | No |
| **Indexes** | 3 active (PK + CIX_InstanceID unique + IX_PlanInstances_OrderTime_OrderID) |

---

## 1. Business Meaning

This table tracks each execution cycle (instance) of a recurring investment plan. Every month (or cycle), each active plan generates an instance that progresses through three stages: deposit, order, and position. Each instance row captures the complete lifecycle data for that cycle - when the deposit was made, its status, when the order was placed, its status, and whether a position was successfully opened.

Without this table, the system would have no record of individual execution cycles. Plans would exist as static configurations with no history of what actually happened each month. This table is the operational core that all backend jobs read from and write to.

Data flows in from multiple sources: the Plan Instances Job creates new rows with NextOrderDate calculated, the Deposit Message Handler fills in deposit data from Money ServiceBus, the Order Execution Job fills in order data from the Trading API (TAPI), and the position confirmation flow fills in position outcome data. The table has 227,402 rows across all plans.

---

## 2. Business Logic

### 2.1 Three-Stage Execution Pipeline

**What**: Each instance progresses through deposit -> order -> position stages, with each stage tracked independently.

**Columns/Parameters Involved**: Deposit columns, Order columns, Position columns, InstanceStatusID

**Rules**:
- Stage 1 (Deposit): DepositID, DepositDate, HighLevelDepositStatusId, DepositStatusID filled by Deposit Message Handler
- Stage 2 (Order): OrderID, OrderStatusId, OrderTradeDate filled by Order Execution Job
- Stage 3 (Position): PositionStatus, PositionAmountUsd/Currency, PositionExecutionDate, PositionFailErrorCode filled by position confirmation
- Each stage can fail independently, resulting in different InstanceStatusID outcomes

**Diagram**:
```
Instance Created (Plan Instances Job)
    |
    v
[Deposit Stage]
DepositID, DepositDate, HighLevelDepositStatusId
    |
    +-- Success (1) --> [Order Stage]
    |                   OrderID, OrderStatusId, OrderTradeDate
    |                       |
    |                       +-- Filled (3) --> [Position Stage]
    |                       |                  PositionStatus, PositionAmountUsd
    |                       |                      |
    |                       |                      +-- Success (1) --> InstanceStatus=1
    |                       |                      +-- Failed (2) --> InstanceStatus=6 or 7
    |                       |
    |                       +-- Rejected/Canceled --> InstanceStatus=7
    |
    +-- SoftDecline (2) --> InstanceStatus=3 (Skipped)
    +-- HardDecline (3) --> InstanceStatus=2 or 3
```

### 2.2 Copy Trading Extensions

**What**: Copy-type plan instances have additional tracking columns for the mirror order process.

**Columns/Parameters Involved**: `MirrorOrderCreated`, `MirrorID`, `CopyPositionStatusID`, `CopyFailErrorCode`

**Rules**:
- MirrorOrderCreated=1 when the mirror order was initiated
- MirrorID tracks the copy relationship ID
- CopyPositionStatusID tracks the two-step copy process: 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed
- CopyFailErrorCode captures specific copy failure reasons
- These columns are NULL for Instrument-type plan instances

### 2.3 Composite Primary Key Design

**What**: PK is PlanID + NextOrderDate, not InstanceID, which is a unique identity column.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`, `InstanceID`

**Rules**:
- PlanID + NextOrderDate is the clustered PK - each plan has at most one instance per scheduled date
- InstanceID is an auto-incrementing identity used as a surrogate key for application lookups
- InstanceID has a unique nonclustered index (CIX_InstanceID)
- This design optimizes range queries by PlanID (clustered) while allowing point lookups by InstanceID

---

## 3. Data Overview

| InstanceID | PlanID | NextOrderDate | DepositID | OrderStatusId | PositionStatus | InstanceStatusID | Meaning |
|------------|--------|---------------|-----------|---------------|----------------|------------------|---------|
| 225616 | 32725 | 2026-05-28 | NULL | NULL | NULL | NULL | Future instance: not yet executed. All data columns are NULL because the execution date hasn't arrived. Created by Plan Instances Job. |
| 209781 | 189 | 2026-04-10 | 75101367 | 1 | 1 | 1 | Successful instance: deposit received, order placed (Received), position opened. Full happy-path completion. PositionAmountUsd=$49.98. |
| 209782 | 569 | 2026-04-10 | 75101371 | 1 | 1 | 1 | Another successful instance from the same date. PositionAmountUsd=$116.08. Higher amount indicates a larger plan. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int IDENTITY | NO | - | VERIFIED | Unique auto-incrementing surrogate key for the instance. Used for application lookups. Not part of PK (PK is PlanID+NextOrderDate). (Source: Confluence: "Unique identifier for the recurring investment plan that triggered the open position") |
| 2 | PlanID | int | NO | - | VERIFIED | FK to Plans.ID. Identifies which plan this instance belongs to. Part of composite PK. (Source: Confluence: "Same ID as [RecurringInvestment].[Plans].ID") |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance. Part of composite PK. Calculated by Plan Instances Job based on FrequencyID and RepeatsOn. (Source: Confluence: "The upcoming date of the next execution") |
| 4 | CreationDate | datetime | NO | GETUTCDATE() | VERIFIED | When this instance record was created by the Plan Instances Job. |
| 5 | DepositID | int | YES | - | VERIFIED | Deposit identifier from Money ServiceBus. References Billing DB [Recurring].[Payment]. Also appears in UserDeposits table. (Source: Confluence) |
| 6 | DepositAmountUsd | decimal(18,2) | YES | - | VERIFIED | DEPRECATED - marked for deletion per Confluence. Deposit amount in USD. Data sourced from Billing DB via Money ServiceBus. |
| 7 | DepositAmountCurrency | decimal(18,2) | YES | - | VERIFIED | DEPRECATED - marked for deletion per Confluence. Deposit amount in plan currency. |
| 8 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle number from Billing system. Identifies which recurring deposit cycle this instance corresponds to. (Source: Confluence) |
| 9 | DepositDate | datetime | YES | - | VERIFIED | When the deposit was made or attempted. Source: Billing DB via Money ServiceBus. (Source: Confluence) |
| 10 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. Source: [Dictionary].[ExecutionResultStatus] in Billing DB per Confluence. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 11 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status from Billing DB PaymentStatusId enum. More granular than HighLevelDepositStatusId. (Source: Confluence) |
| 12 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state from Trading API enum: 1=Received, 2=Placed, 3=Filled, 4=Rejected...11=WaitingForMarket. See [Order Status](../../_glossary.md#order-status). (Dictionary.OrderStatus) (Source: Confluence confirms Trading enum) |
| 13 | OrderID | int | YES | - | VERIFIED | Order identifier from Trading API (TAPI). The ID of the request to open a position before it was opened. (Source: Confluence: "this value is from TAPI") |
| 14 | OrderTradeDate | datetime | YES | - | VERIFIED | The time that the order needs to be requested from Trading API. Indexed for efficient order processing. (Source: Confluence) |
| 15 | PositionStatus | int | YES | - | VERIFIED | Position creation outcome: 1=Success, 2=Failed, 3=InProgress, 4=Unknown, 6=CanceledByUser, 7=ExpiredOrCanceledByEtoro. See [Position Status](../../_glossary.md#position-status). (Dictionary.PositionStatus) |
| 16 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Actual position amount in USD. May differ from plan Amount due to partial fills or market conditions. |
| 17 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Actual position amount in the plan's currency. |
| 18 | PositionExecutionDate | datetime | YES | - | VERIFIED | When the position was actually opened. (Source: Confluence) |
| 19 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code from Trading API's TradingOpenPositionErrorCodes enum when position open fails. (Source: Confluence) |
| 20 | NotificationSent | bit | YES | - | VERIFIED | DEPRECATED - marked for deletion per Confluence. Flag indicating if a notification was sent to the client. |
| 21 | NotificationReason | int | YES | - | VERIFIED | DEPRECATED - marked for deletion per Confluence. Reason for notification, based on PlanEventCode. |
| 22 | InstanceStatus | bit | YES | - | VERIFIED | DEPRECATED - marked for deletion per Confluence. Legacy done flag: 1=Done, NULL=not done. Replaced by InstanceStatusID. |
| 23 | UpdateDate | datetime | NO | GETUTCDATE() | VERIFIED | Last modification timestamp for this instance record. |
| 24 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with connection details. |
| 25 | ValidFrom | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | System-versioned period start. |
| 26 | ValidTo | datetime2(7) | NO | 9999-12-31 | CODE-BACKED | System-versioned period end. |
| 27 | InstanceStatusReasonID | int | YES | - | VERIFIED | Specific reason for the instance's final status. Maps to Dictionary.PlanEventCode ("same as PlanEventCode" per Confluence). See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 28 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state: 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=Technical Issue, 7=Completed without position. See [Instance Status](../../_glossary.md#instance-status). (Dictionary.InstanceStatusID) |
| 29 | MirrorOrderCreated | int | YES | - | VERIFIED | Copy trading flag: 1=TRUE when mirror order was initiated. NULL for instrument-type plans. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 30 | MirrorID | int | YES | - | CODE-BACKED | ID of the mirror/copy relationship for copy trading instances. NULL for instrument-type plans. |
| 31 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position creation step: 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed. NULL for instrument-type plans. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 32 | CopyFailErrorCode | int | YES | - | VERIFIED | Error code for copy position failures. NULL for instrument-type plans. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code). |
| 33 | DepositFailReason | int | YES | - | CODE-BACKED | Reason for deposit failure when applicable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlanID | RecurringInvestment.Plans | Implicit FK | Plan this instance belongs to |
| HighLevelDepositStatusId | Dictionary.HighLevelDepositStatus | Implicit Lookup | Deposit outcome classification |
| OrderStatusId | Dictionary.OrderStatus | Implicit Lookup | Order lifecycle state |
| PositionStatus | Dictionary.PositionStatus | Implicit Lookup | Position creation outcome |
| InstanceStatusID | Dictionary.InstanceStatusID | Implicit Lookup | Instance lifecycle state |
| InstanceStatusReasonID | Dictionary.PlanEventCode | Implicit Lookup | Specific reason for instance status |
| MirrorOrderCreated | Dictionary.MirrorOrderCreated | Implicit Lookup | Mirror order flag |
| CopyPositionStatusID | Dictionary.CopyPositionStatusID | Implicit Lookup | Copy position step status |
| CopyFailErrorCode | Dictionary.CopyFailErrorCode | Implicit Lookup | Copy failure classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.UserDeposits | DepositID | Implicit | Deposit data linked via DepositID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.Plans (table) [via PlanID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | PlanID references Plans.ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstanceInsert | SP | Writer - creates new instances |
| RecurringInvestment.PlanInstanceUpdate | SP | Modifier - updates instance data |
| RecurringInvestment.PlanInstancesInsertMultiple | SP | Writer - batch creates instances |
| RecurringInvestment.PlanInstancesUpdateMultiple | SP | Modifier - batch updates status |
| RecurringInvestment.PlanInstanceUserDepositsUpsert | SP | Modifier - upserts deposit data |
| RecurringInvestment.PlanInstanceGetByInstanceID | SP | Reader - lookup by InstanceID |
| RecurringInvestment.PlanInstanceGetPlanInstancesByPlanID | SP | Reader - instances for a plan |
| RecurringInvestment.PlanInstanceGetPendingOrders | SP | Reader - finds pending orders |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlanID | CLUSTERED PK | PlanID, NextOrderDate | - | - | Active |
| CIX_InstanceID | UNIQUE NC | InstanceID | - | - | Active |
| IX_PlanInstances_OrderTime_OrderID | NONCLUSTERED | OrderTradeDate, OrderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PlanInstances_CreationDate | DEFAULT | GETUTCDATE() |
| DF_PlanInstances_UpdateDate | DEFAULT | GETUTCDATE() |
| DF_ValidFrom | DEFAULT | GETUTCDATE() |
| DF_ValidTo | DEFAULT | CONVERT(datetime2, '9999-12-31 23:59:59.9999999') |

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentPlanInstances`.

---

## 8. Sample Queries

### 8.1 Get all instances for a plan with resolved statuses
```sql
SELECT pi.InstanceID, pi.NextOrderDate, pi.DepositID,
       hlds.HighLevelDepositStatus, os.OrderStatus, ps.PositionStatus AS PosStatusName,
       ist.InstanceStatusID AS InstanceStatusName
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
LEFT JOIN [Dictionary].[HighLevelDepositStatus] hlds WITH (NOLOCK) ON pi.HighLevelDepositStatusId = hlds.ID
LEFT JOIN [Dictionary].[OrderStatus] os WITH (NOLOCK) ON pi.OrderStatusId = os.ID
LEFT JOIN [Dictionary].[PositionStatus] ps WITH (NOLOCK) ON pi.PositionStatus = ps.ID
LEFT JOIN [Dictionary].[InstanceStatusID] ist WITH (NOLOCK) ON pi.InstanceStatusID = ist.ID
WHERE pi.PlanID = @PlanID
ORDER BY pi.NextOrderDate DESC
```

### 8.2 Find failed instances with their reasons
```sql
SELECT pi.InstanceID, pi.PlanID, pi.NextOrderDate,
       ist.InstanceStatusID AS StatusName, pec.EventName AS ReasonName
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[InstanceStatusID] ist WITH (NOLOCK) ON pi.InstanceStatusID = ist.ID
LEFT JOIN [Dictionary].[PlanEventCode] pec WITH (NOLOCK) ON pi.InstanceStatusReasonID = pec.ID
WHERE pi.InstanceStatusID NOT IN (1, 5)
ORDER BY pi.NextOrderDate DESC
```

### 8.3 Get instance with full plan context
```sql
SELECT p.ID AS PlanID, p.GCID, p.InstrumentID, pt.Name AS PlanTypeName,
       pi.InstanceID, pi.NextOrderDate, pi.PositionAmountUsd, pi.InstanceStatusID
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK) ON p.ID = pi.PlanID
JOIN [Dictionary].[PlanType] pt WITH (NOLOCK) ON p.PlanType = pt.ID
WHERE p.GCID = @GCID
ORDER BY pi.NextOrderDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Complete PlanInstances table documentation: column descriptions, data sources (Money ServiceBus, TAPI, Billing DB), deprecated columns, Dictionary references |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan Instances Job, Deposit Message Handler, Order Execution Job - all write to this table; sequence diagrams show data flow |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 25 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstances | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.sql*
