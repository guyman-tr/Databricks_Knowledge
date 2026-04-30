# RecurringInvestment.PlansTypeCopyVersion

> Table-valued parameter type for batch-updating copy trading plan configuration fields, extending PlansType with copy-specific columns.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with GCID + PlanID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This is the copy-trading-specific version of PlansType. It extends the base type with columns needed for copy plan management: PlanType, CopyType, CopyParentCID, and CopyParentGCID. Used by UpdatePlansAndUpsertInstancesCopyVersion for processing copy plan modifications.

While standard instrument plans only need amount/schedule updates, copy plans may also need to change their copy relationship (which trader/portfolio they copy).

---

## 2. Business Logic

### 2.1 Copy Plan Configuration

**What**: Extends standard plan updates with copy trading relationship management.

**Columns/Parameters Involved**: `PlanType`, `CopyType`, `CopyParentCID`, `CopyParentGCID`

**Rules**:
- PlanType should be 2 (Copy) for plans using this type
- CopyType: 1=PI (Popular Investor) or 4=SmartPortfolio
- CopyParentCID/CopyParentGCID identify the trader or portfolio being copied
- All standard plan fields (Amount, FundingID, etc.) can also be updated

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | VERIFIED | Global Customer ID identifying the plan owner. |
| 2 | PlanID | int | NO | - | VERIFIED | Unique identifier of the plan to update. References Plans.ID. |
| 3 | Amount | decimal(18,2) | YES | - | VERIFIED | New investment amount in the plan's currency. |
| 4 | AmountUsd | decimal(18,2) | YES | - | VERIFIED | New investment amount converted to USD. |
| 5 | FundingID | int | YES | - | VERIFIED | New payment method ID. |
| 6 | RepeatsOn | int | YES | - | VERIFIED | New execution day of the month (1-28). |
| 7 | DepositStartDate | datetime | YES | - | VERIFIED | New deposit start date. |
| 8 | PlanType | int | YES | - | VERIFIED | Plan type: 1=Instrument, 2=Copy. See [Plan Type](../../_glossary.md#plan-type). (Dictionary.PlanType) |
| 9 | CopyType | int | YES | - | VERIFIED | Copy type: 0=None, 1=PI, 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). (Dictionary.CopyType) |
| 10 | CopyParentCID | bigint | YES | - | VERIFIED | CID of the trader being copied (for PI plans) or the SmartPortfolio identifier. |
| 11 | CopyParentGCID | bigint | YES | - | VERIFIED | GCID of the trader being copied. Used with CopyParentCID for unique identification. |
| 12 | HasBackupPayment | bit | YES | - | VERIFIED | Whether the plan has a fallback payment method configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID + PlanID | RecurringInvestment.Plans | Implicit FK | Plan being updated |
| PlanType | Dictionary.PlanType | Implicit Lookup | Plan investment strategy |
| CopyType | Dictionary.CopyType | Implicit Lookup | Copy trading relationship type |

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
| RecurringInvestment.UpdatePlansAndUpsertInstancesCopyVersion | Stored Procedure | Accepts this type for batch copy plan updates |

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
DECLARE @Plans RecurringInvestment.PlansTypeCopyVersion
INSERT INTO @Plans (GCID, PlanID, Amount, PlanType, CopyType, CopyParentCID, CopyParentGCID)
VALUES (12345678, 100, 500.00, 2, 1, 87654321, 87654321)
```

### 8.2 Use with copy version update procedure
```sql
DECLARE @Plans RecurringInvestment.PlansTypeCopyVersion
INSERT INTO @Plans (GCID, PlanID, Amount, AmountUsd) VALUES (12345678, 100, 750.00, 750.00)
EXEC [RecurringInvestment].[UpdatePlansAndUpsertInstancesCopyVersion] @Plans = @Plans
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlansTypeCopyVersion' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table copy trading columns (CopyParentCID, CopyParentGCID, PlanType, CopyType) |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 12 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlansTypeCopyVersion | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlansTypeCopyVersion.sql*
