# RecurringInvestment.PlanInstancesDepositsType

> Table-valued parameter type for batch-upserting plan instance deposit and execution data in a single database call.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with InstanceID (PK, CLUSTERED) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on InstanceID |

---

## 1. Business Meaning

This table-valued parameter type carries comprehensive plan instance data for batch upsert operations. It mirrors the core columns of the PlanInstances table, enabling the application to update multiple instances in a single database round-trip with deposit results, order status, position outcomes, and instance status.

Without this type, each instance update would require an individual procedure call, increasing latency and transaction complexity during batch processing by the Deposit Message Handler and Order Execution Job.

Used by PlanInstanceUserDepositsUpsert to process deposit results from Money ServiceBus for multiple plan instances simultaneously.

---

## 2. Business Logic

### 2.1 Full Instance Lifecycle Data Carrier

**What**: Carries all data needed to update a plan instance through the deposit -> order -> position pipeline.

**Columns/Parameters Involved**: All 19 columns covering deposit, order, and position data.

**Rules**:
- InstanceID uniquely identifies which instance to update (PK)
- Deposit columns (DepositID, DepositCycleNumber, DepositDate, HighLevelDepositStatusId, DepositStatusID) come from Money ServiceBus
- Order columns (OrderStatusId, OrderID, OrderTradeDate) come from Trading API
- Position columns (PositionStatus, PositionExecutionDate, PositionAmountUsd/Currency, PositionFailErrorCode) come from Trading API
- Instance status columns (InstanceStatusID, InstanceStatusReasonID) are calculated by the application

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique identifier of the plan instance to update. Primary key. References PlanInstances.InstanceID. |
| 2 | PlanID | int | NO | - | VERIFIED | Plan this instance belongs to. References Plans.ID. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance's order. Part of PlanInstances composite PK. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit identifier from Money ServiceBus. References Billing DB [Recurring].[Payment]. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle number from Billing system. Identifies which recurring deposit cycle this instance corresponds to. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Date and time the deposit was made or attempted. Source: Billing DB via Money ServiceBus. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). (Dictionary.HighLevelDepositStatus) |
| 8 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status from Billing DB PaymentStatusId enum. More granular than HighLevelDepositStatusId. |
| 9 | OrderTradeDate | datetime | YES | - | VERIFIED | Date and time the order was requested from Trading API. |
| 10 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state: 1=Received through 11=WaitingForMarket. See [Order Status](../../_glossary.md#order-status). (Dictionary.OrderStatus) |
| 11 | OrderID | int | YES | - | VERIFIED | Order identifier from Trading API (TAPI). |
| 12 | PositionStatus | int | YES | - | VERIFIED | Position creation outcome: 1=Success, 2=Failed, etc. See [Position Status](../../_glossary.md#position-status). (Dictionary.PositionStatus) |
| 13 | PositionExecutionDate | datetime | YES | - | VERIFIED | Date and time the position was opened. |
| 14 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 15 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in the plan's currency. |
| 16 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code from Trading API's TradingOpenPositionErrorCodes enum when position open fails. |
| 17 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state: 1=Success through 7=Completed without position. See [Instance Status](../../_glossary.md#instance-status). (Dictionary.InstanceStatusID) |
| 18 | InstanceStatusReasonID | int | YES | - | VERIFIED | Specific reason for instance status. Maps to Dictionary.PlanEventCode. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 19 | DepositFailReason | int | YES | - | VERIFIED | Reason for deposit failure when applicable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstanceID/PlanID | RecurringInvestment.PlanInstances | Implicit FK | Instance being updated |
| HighLevelDepositStatusId | Dictionary.HighLevelDepositStatus | Implicit Lookup | Deposit outcome classification |
| OrderStatusId | Dictionary.OrderStatus | Implicit Lookup | Order lifecycle state |
| PositionStatus | Dictionary.PositionStatus | Implicit Lookup | Position creation outcome |
| InstanceStatusID | Dictionary.InstanceStatusID | Implicit Lookup | Instance lifecycle state |
| InstanceStatusReasonID | Dictionary.PlanEventCode | Implicit Lookup | Reason for instance status |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstanceUserDepositsUpsert | Stored Procedure | Accepts this type as parameter for batch instance updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type (has clustered PK on InstanceID within the type definition).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK on InstanceID | PRIMARY KEY CLUSTERED | Ensures uniqueness of instances within the batch |

---

## 8. Sample Queries

### 8.1 Declare and populate with deposit data
```sql
DECLARE @Instances RecurringInvestment.PlanInstancesDepositsType
INSERT INTO @Instances (InstanceID, PlanID, NextOrderDate, DepositID, DepositCycleNumber,
  DepositDate, HighLevelDepositStatusId, DepositStatusID, InstanceStatusID, InstanceStatusReasonID)
VALUES (1001, 100, '2026-04-15', 5001, 12, GETUTCDATE(), 1, 1, 5, 101)
```

### 8.2 Use with upsert procedure
```sql
DECLARE @Instances RecurringInvestment.PlanInstancesDepositsType
-- populate...
EXEC [RecurringInvestment].[PlanInstanceUserDepositsUpsert] @Instances = @Instances
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlanInstancesDepositsType' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | PlanInstances column descriptions and data sources (Money ServiceBus, Trading API, Billing DB) |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Deposit Message Handler processes deposits; Order Execution Job handles orders and positions |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 19 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstancesDepositsType | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlanInstancesDepositsType.sql*
