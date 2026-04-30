# RecurringInvestment.PlansType

> Table-valued parameter type for batch-updating plan configuration fields (amount, funding, schedule) for standard instrument plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with GCID + PlanID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table-valued parameter type enables batch updates to recurring investment plan configuration. It carries the modifiable fields of a plan: Amount, AmountUsd, FundingID, RepeatsOn, DepositStartDate, and HasBackupPayment. Used by UpdatePlansAndUpsertInstances for processing plan modifications.

This is the standard version for instrument-type plans (PlanType=1). Copy-type plans use PlansTypeCopyVersion which adds CopyParentCID/CopyParentGCID columns.

---

## 2. Business Logic

### 2.1 Plan Configuration Update

**What**: Carries modifiable plan fields for batch update operations.

**Columns/Parameters Involved**: `Amount`, `AmountUsd`, `FundingID`, `RepeatsOn`, `DepositStartDate`, `HasBackupPayment`

**Rules**:
- GCID + PlanID identify the plan to update
- Amount/AmountUsd may be changed when user modifies their recurring investment amount
- FundingID may change when user switches payment method
- RepeatsOn may change when user selects a different execution day
- DepositStartDate may be adjusted for schedule changes
- HasBackupPayment indicates whether a fallback payment method is configured

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | VERIFIED | Global Customer ID identifying the plan owner. |
| 2 | PlanID | int | NO | - | VERIFIED | Unique identifier of the plan to update. References Plans.ID. |
| 3 | Amount | decimal(18,2) | YES | - | VERIFIED | New investment amount in the plan's currency. NULL means no change. |
| 4 | AmountUsd | decimal(18,2) | YES | - | VERIFIED | New investment amount converted to USD. NULL means no change. |
| 5 | FundingID | int | YES | - | VERIFIED | New payment method ID. NULL means no change. |
| 6 | RepeatsOn | int | YES | - | VERIFIED | New execution day of the month (1-28). NULL means no change. |
| 7 | DepositStartDate | datetime | YES | - | VERIFIED | New deposit start date. NULL means no change. |
| 8 | HasBackupPayment | bit | YES | - | VERIFIED | Whether the plan has a fallback payment method configured. NULL means no change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID + PlanID | RecurringInvestment.Plans | Implicit FK | Plan being updated |

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
| RecurringInvestment.UpdatePlansAndUpsertInstances | Stored Procedure | Accepts this type for batch plan updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Plans RecurringInvestment.PlansType
INSERT INTO @Plans (GCID, PlanID, Amount, AmountUsd, RepeatsOn)
VALUES (12345678, 100, 500.00, 500.00, 15)
```

### 8.2 Use with update procedure
```sql
DECLARE @Plans RecurringInvestment.PlansType
INSERT INTO @Plans (GCID, PlanID, Amount, AmountUsd) VALUES (12345678, 100, 750.00, 750.00)
EXEC [RecurringInvestment].[UpdatePlansAndUpsertInstances] @Plans = @Plans
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlansType' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table column descriptions including Amount, FundingID, RepeatsOn |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlansType | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlansType.sql*
