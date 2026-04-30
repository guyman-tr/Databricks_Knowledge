# RecurringInvestment.PlanInstancesDepositsTypeV2

> Table-valued parameter type for batch-upserting plan instance deposit and execution data - V2 without DepositFailReason column.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with InstanceID, PlanID, NextOrderDate |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This is version 2 of the PlanInstancesDepositsType, carrying plan instance data for batch upsert operations. Compared to V1, this version removes the DepositFailReason column, indicating it was introduced for non-copy plans or before the copy-specific version was created. It carries deposit, order, and position data for standard (non-copy) recurring investment plan instances.

Used by procedures that process standard instrument-based recurring investment instances where copy-specific columns (MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode) are not needed.

---

## 2. Business Logic

No complex multi-column business logic patterns beyond what is described in PlanInstancesDepositsType. This is a data carrier for batch operations.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique identifier of the plan instance to update. References PlanInstances.InstanceID. |
| 2 | PlanID | int | NO | - | VERIFIED | Plan this instance belongs to. References Plans.ID. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance's order. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit identifier from Money ServiceBus. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle number from Billing system. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Date and time the deposit was made or attempted. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status from Billing DB PaymentStatusId enum. |
| 9 | OrderTradeDate | datetime | YES | - | VERIFIED | Date and time the order was requested from Trading API. |
| 10 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state. See [Order Status](../../_glossary.md#order-status). (Dictionary.OrderStatus) |
| 11 | OrderID | int | YES | - | VERIFIED | Order identifier from Trading API. |
| 12 | PositionStatus | int | YES | - | VERIFIED | Position creation outcome. See [Position Status](../../_glossary.md#position-status). (Dictionary.PositionStatus) |
| 13 | PositionExecutionDate | datetime | YES | - | VERIFIED | Date and time the position was opened. |
| 14 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 15 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in the plan's currency. |
| 16 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code from Trading API when position open fails. |
| 17 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state. See [Instance Status](../../_glossary.md#instance-status). (Dictionary.InstanceStatusID) |
| 18 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. See [Plan Event Code](../../_glossary.md#plan-event-code). (Dictionary.PlanEventCode) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstanceID/PlanID | RecurringInvestment.PlanInstances | Implicit FK | Instance being updated |
| HighLevelDepositStatusId | Dictionary.HighLevelDepositStatus | Implicit Lookup | Deposit outcome |
| OrderStatusId | Dictionary.OrderStatus | Implicit Lookup | Order state |
| PositionStatus | Dictionary.PositionStatus | Implicit Lookup | Position outcome |
| InstanceStatusID | Dictionary.InstanceStatusID | Implicit Lookup | Instance state |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type (no PK defined in this version).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Instances RecurringInvestment.PlanInstancesDepositsTypeV2
INSERT INTO @Instances (InstanceID, PlanID, NextOrderDate, DepositID, HighLevelDepositStatusId)
VALUES (1001, 100, '2026-04-15', 5001, 1)
```

### 8.2 Compare with V1 structure
```sql
SELECT tt.name AS TypeName, c.name AS ColumnName, t.name AS DataType
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name IN ('PlanInstancesDepositsType', 'PlanInstancesDepositsTypeV2')
  AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY tt.name, c.column_id
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlanInstancesDepositsTypeV2' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | PlanInstances column descriptions and data flow from Money ServiceBus and Trading API |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 18 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstancesDepositsTypeV2 | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlanInstancesDepositsTypeV2.sql*
