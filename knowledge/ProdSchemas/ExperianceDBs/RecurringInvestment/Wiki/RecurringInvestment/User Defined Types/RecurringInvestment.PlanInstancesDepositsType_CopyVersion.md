# RecurringInvestment.PlanInstancesDepositsType_CopyVersion

> Table-valued parameter type for batch-upserting copy trading plan instance data, including mirror order and copy position tracking columns.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with InstanceID, PlanID, NextOrderDate |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This is the copy-trading-specific version of the PlanInstancesDepositsType. It extends the base type with columns for copy trading mechanics: MirrorOrderCreated, MirrorID, CopyPositionStatusID, and CopyFailErrorCode. Used when processing plan instances for Copy-type plans (PlanType=2, CopyType=1 PI or CopyType=4 SmartPortfolio).

Without this type, the system could not batch-update copy trading instance data that includes the two-step copy registration process (register + add funds) and mirror order tracking.

Used by PlanInstanceUserDepositsUpsert_CopyVersion stored procedure.

---

## 2. Business Logic

### 2.1 Copy Trading Instance Data

**What**: Extends standard instance data with copy-specific tracking for mirror orders and copy position status.

**Columns/Parameters Involved**: `MirrorOrderCreated`, `MirrorID`, `CopyPositionStatusID`, `CopyFailErrorCode`

**Rules**:
- MirrorOrderCreated: 1=TRUE when mirror order initiated (Dictionary.MirrorOrderCreated)
- MirrorID: The ID of the mirror/copy relationship
- CopyPositionStatusID: Two-step process tracking: 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed
- CopyFailErrorCode: Specific error code when copy position fails
- Also includes DepositFailReason column (unlike V2 which removes it)

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique identifier of the plan instance. References PlanInstances.InstanceID. |
| 2 | PlanID | int | NO | - | VERIFIED | Plan this instance belongs to. References Plans.ID. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance. |
| 4 | DepositID | int | YES | - | VERIFIED | Deposit identifier from Money ServiceBus. |
| 5 | DepositCycleNumber | int | YES | - | VERIFIED | Deposit cycle number from Billing system. |
| 6 | DepositDate | datetime | YES | - | VERIFIED | Date and time the deposit was made or attempted. |
| 7 | HighLevelDepositStatusId | int | YES | - | VERIFIED | High-level deposit outcome. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 8 | DepositFailReason | int | YES | - | VERIFIED | Specific reason for deposit failure when applicable. |
| 9 | DepositStatusID | int | YES | - | VERIFIED | Detailed deposit status from Billing DB PaymentStatusId enum. |
| 10 | OrderTradeDate | datetime | YES | - | VERIFIED | Date and time the order was requested. |
| 11 | OrderStatusId | int | YES | - | VERIFIED | Order lifecycle state. See [Order Status](../../_glossary.md#order-status). |
| 12 | OrderID | int | YES | - | VERIFIED | Order identifier from Trading API. |
| 13 | PositionStatus | int | YES | - | VERIFIED | Position creation outcome. See [Position Status](../../_glossary.md#position-status). |
| 14 | PositionExecutionDate | datetime | YES | - | VERIFIED | Date and time the position was opened. |
| 15 | PositionAmountUsd | decimal(18,2) | YES | - | VERIFIED | Position amount in USD. |
| 16 | PositionAmountCurrency | decimal(18,2) | YES | - | VERIFIED | Position amount in the plan's currency. |
| 17 | PositionFailErrorCode | int | YES | - | VERIFIED | Error code from Trading API when position open fails. |
| 18 | InstanceStatusID | int | YES | - | VERIFIED | Instance lifecycle state. See [Instance Status](../../_glossary.md#instance-status). |
| 19 | InstanceStatusReasonID | int | YES | - | VERIFIED | Reason for instance status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 20 | MirrorOrderCreated | int | YES | - | VERIFIED | Flag: 1=TRUE when mirror order was created. See [Mirror Order Created](../../_glossary.md#mirror-order-created). |
| 21 | MirrorID | int | YES | - | VERIFIED | ID of the mirror/copy relationship established for this copy trading instance. |
| 22 | CopyPositionStatusID | int | YES | - | VERIFIED | Copy position creation step status: 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed. See [Copy Position Status](../../_glossary.md#copy-position-status). |
| 23 | CopyFailErrorCode | int | YES | - | VERIFIED | Error code classifying why a copy position failed. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstanceID/PlanID | RecurringInvestment.PlanInstances | Implicit FK | Instance being updated |
| MirrorOrderCreated | Dictionary.MirrorOrderCreated | Implicit Lookup | Mirror order flag |
| CopyPositionStatusID | Dictionary.CopyPositionStatusID | Implicit Lookup | Copy position step status |
| CopyFailErrorCode | Dictionary.CopyFailErrorCode | Implicit Lookup | Copy failure classification |

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
| RecurringInvestment.PlanInstanceUserDepositsUpsert_CopyVersion | Stored Procedure | Accepts this type as parameter for copy plan instance batch updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate with copy data
```sql
DECLARE @Instances RecurringInvestment.PlanInstancesDepositsType_CopyVersion
INSERT INTO @Instances (InstanceID, PlanID, NextOrderDate, MirrorOrderCreated, MirrorID,
  CopyPositionStatusID, InstanceStatusID)
VALUES (1001, 100, '2026-04-15', 1, 5001, 1, 5)
```

### 8.2 Use with copy version upsert procedure
```sql
DECLARE @Instances RecurringInvestment.PlanInstancesDepositsType_CopyVersion
-- populate...
EXEC [RecurringInvestment].[PlanInstanceUserDepositsUpsert_CopyVersion] @Instances = @Instances
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlanInstancesDepositsType_CopyVersion' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | PlanInstances copy trading columns and their data sources |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Copy trading execution flow with mirror order creation |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 23 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstancesDepositsType_CopyVersion | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlanInstancesDepositsType_CopyVersion.sql*
