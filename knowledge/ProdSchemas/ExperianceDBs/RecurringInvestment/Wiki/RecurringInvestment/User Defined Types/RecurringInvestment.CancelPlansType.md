# RecurringInvestment.CancelPlansType

> Table-valued parameter type used to batch-cancel multiple recurring investment plans in a single database call.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with GCID + PlanID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This table-valued parameter (TVP) type enables batch cancellation of multiple recurring investment plans in a single stored procedure call. Instead of cancelling plans one at a time, the calling application can populate a CancelPlansType variable with multiple plan records and pass it to a cancellation procedure (e.g., PlansCancelAllUserPlansUpdateInstanceStatus).

Without this type, cancelling multiple plans would require individual procedure calls per plan, increasing network round-trips, transaction overhead, and potential for partial failures.

The type is populated by the recurring investment backend service (eToro/recurring-investment-back) when a batch cancellation is triggered - such as when a user requests cancellation of all their plans, or when a system rule requires mass cancellation.

---

## 2. Business Logic

### 2.1 Batch Plan Cancellation

**What**: Enables atomic batch cancellation with status tracking per plan.

**Columns/Parameters Involved**: `GCID`, `PlanID`, `PlanStatusID`, `StatusReasonId`, `EndDate`

**Rules**:
- Each row represents one plan to cancel
- PlanStatusID specifies the target status (typically 2=Cancelled)
- StatusReasonId captures why (from Dictionary.PlanEventCode - e.g., 700=CancelPlanByUser, 300=DepositPlanCancelled)
- EndDate records when the cancellation takes effect

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | VERIFIED | Global Customer ID identifying the user whose plan is being cancelled. Must match the plan owner in Plans table. |
| 2 | PlanID | int | NO | - | VERIFIED | Unique identifier of the recurring investment plan to cancel. References RecurringInvestment.Plans.ID. |
| 3 | PlanStatusID | int | NO | - | VERIFIED | Target plan status to set. Typically 2=Cancelled. See [Plan Status](../../_glossary.md#plan-status). (Dictionary.PlanStatus) |
| 4 | StatusReasonId | int | NO | - | VERIFIED | Reason for the cancellation. Maps to Dictionary.PlanEventCode (e.g., 700=CancelPlanByUser, 300=DepositPlanCancelled). See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 5 | EndDate | datetime | NO | - | VERIFIED | Date and time when the plan cancellation takes effect. Stored in Plans.EndDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlanID | RecurringInvestment.Plans | Implicit FK | Plan to be cancelled |
| PlanStatusID | Dictionary.PlanStatus | Implicit Lookup | Target status for the plan |
| StatusReasonId | Dictionary.PlanEventCode | Implicit Lookup | Reason for cancellation |

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
| RecurringInvestment.PlansCancelAllUserPlansUpdateInstanceStatus | Stored Procedure | Accepts this type as a parameter for batch plan cancellation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate the type
```sql
DECLARE @PlansToCancel RecurringInvestment.CancelPlansType
INSERT INTO @PlansToCancel (GCID, PlanID, PlanStatusID, StatusReasonId, EndDate)
VALUES (12345678, 100, 2, 700, GETUTCDATE())
```

### 8.2 Use with cancellation procedure
```sql
DECLARE @PlansToCancel RecurringInvestment.CancelPlansType
INSERT INTO @PlansToCancel (GCID, PlanID, PlanStatusID, StatusReasonId, EndDate)
VALUES (12345678, 100, 2, 700, GETUTCDATE()),
       (12345678, 101, 2, 700, GETUTCDATE())
EXEC [RecurringInvestment].[PlansCancelAllUserPlansUpdateInstanceStatus] @Plans = @PlansToCancel
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'CancelPlansType' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan cancellation flows triggered by user, system, or BO actions |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.CancelPlansType | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.CancelPlansType.sql*
