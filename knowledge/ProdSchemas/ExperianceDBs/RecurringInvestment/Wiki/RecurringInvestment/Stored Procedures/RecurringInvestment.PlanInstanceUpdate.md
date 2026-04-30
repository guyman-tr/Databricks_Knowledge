# RecurringInvestment.PlanInstanceUpdate

> Updates a plan instance with deposit, order, position, and copy trading data as the execution cycle progresses.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID + @NextOrderDate composite key, updates PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary instance update procedure, called multiple times during an instance's lifecycle as new data arrives from different systems. The Deposit Message Handler calls it to fill in deposit data, the Order Execution Job calls it to fill in order data, and the position confirmation flow calls it to fill in position outcome data.

Uses ISNULL-based partial updates: only non-NULL parameters overwrite their columns. This enables progressive enrichment of the instance record. Supports both instrument and copy trading instances through the MirrorOrderCreated, MirrorID, CopyPositionStatusID, and CopyFailErrorCode parameters. Created per EDGE-3688.

---

## 2. Business Logic

### 2.1 Progressive Instance Enrichment

**What**: Instance data is filled in progressively as each stage completes.

**Columns/Parameters Involved**: All 21 optional parameters

**Rules**:
- Identifies the instance by composite key: PlanID + NextOrderDate
- Each parameter uses ISNULL(@Param, ExistingValue) - only non-NULL values update
- Call 1 (Deposit stage): fills DepositID, DepositDate, HighLevelDepositStatusId, DepositStatusID, DepositCycleNumber
- Call 2 (Order stage): fills OrderID, OrderStatusId, OrderTradeDate
- Call 3 (Position stage): fills PositionStatus, PositionAmountUsd/Currency, PositionExecutionDate, PositionFailErrorCode
- Call 4 (Status): fills InstanceStatusID, InstanceStatusReasonID
- Copy trading: fills MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | Plan the instance belongs to. Part of composite key. |
| 2 | @NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date. Part of composite key. |
| 3 | @DepositID | int | YES | NULL | VERIFIED | Deposit ID from Money ServiceBus. |
| 4 | @DepositCycleNumber | int | YES | NULL | VERIFIED | Billing cycle number. |
| 5 | @DepositDate | datetime | YES | NULL | VERIFIED | When deposit was made. |
| 6 | @HighLevelDepositStatusId | int | YES | NULL | VERIFIED | Deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 7 | @DepositFailReason | int | YES | NULL | VERIFIED | Deposit failure reason. |
| 8 | @DepositStatusID | int | YES | NULL | VERIFIED | Detailed deposit status from Billing. |
| 9 | @OrderTradeDate | datetime | YES | NULL | VERIFIED | When order was requested from TAPI. |
| 10 | @OrderStatusId | int | YES | NULL | VERIFIED | Order lifecycle state. See [Order Status](../../_glossary.md#order-status). |
| 11 | @OrderID | int | YES | NULL | VERIFIED | Order ID from TAPI. |
| 12 | @PositionStatus | int | YES | NULL | VERIFIED | Position outcome. See [Position Status](../../_glossary.md#position-status). |
| 13 | @PositionExecutionDate | datetime | YES | NULL | VERIFIED | When position was opened. |
| 14 | @PositionAmountUsd | decimal(18,2) | YES | NULL | VERIFIED | Position amount in USD. |
| 15 | @PositionAmountCurrency | decimal(18,2) | YES | NULL | VERIFIED | Position amount in plan currency. |
| 16 | @PositionFailErrorCode | int | YES | NULL | VERIFIED | Trading API error code on failure. |
| 17 | @InstanceStatusID | int | YES | NULL | VERIFIED | Instance lifecycle state. See [Instance Status](../../_glossary.md#instance-status). |
| 18 | @InstanceStatusReasonID | int | YES | NULL | VERIFIED | Reason for instance status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 19 | @MirrorOrderCreated | int | YES | NULL | VERIFIED | Copy trading: mirror order flag. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 20 | @MirrorID | int | YES | NULL | VERIFIED | Copy trading: mirror relationship ID. |
| 21 | @CopyPositionStatusID | int | YES | NULL | VERIFIED | Copy trading: position step status. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 22 | @CopyFailErrorCode | int | YES | NULL | VERIFIED | Copy trading: failure classification. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write | UPDATE by PlanID + NextOrderDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceUpdate (procedure)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | UPDATE |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update with deposit data
```sql
EXEC [RecurringInvestment].[PlanInstanceUpdate]
  @PlanID = 100, @NextOrderDate = '2026-04-10 14:45:00',
  @DepositID = 75101367, @DepositDate = '2026-04-10 12:00:00',
  @HighLevelDepositStatusId = 1, @DepositStatusID = 1
```

### 8.2 Update with order data
```sql
EXEC [RecurringInvestment].[PlanInstanceUpdate]
  @PlanID = 100, @NextOrderDate = '2026-04-10 14:45:00',
  @OrderID = 1414398671, @OrderStatusId = 3, @OrderTradeDate = '2026-04-10 14:45:00'
```

### 8.3 Update with position data
```sql
EXEC [RecurringInvestment].[PlanInstanceUpdate]
  @PlanID = 100, @NextOrderDate = '2026-04-10 14:45:00',
  @PositionStatus = 1, @PositionAmountUsd = 49.98,
  @PositionExecutionDate = '2026-04-10 14:46:00',
  @InstanceStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Deposit Handler, Order Execution Job, and position confirmation all update instances; code comment references EDGE-3688 |
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | PlanInstances columns and their data sources |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 20 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstanceUpdate | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceUpdate.sql*
