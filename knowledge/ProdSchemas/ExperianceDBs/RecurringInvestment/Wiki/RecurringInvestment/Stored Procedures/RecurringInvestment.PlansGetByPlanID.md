# RecurringInvestment.PlansGetByPlanID

> Retrieves a single recurring investment plan by its Plan ID with all configuration and status fields.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID input, returns single plan row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a single plan by its ID. Used by the application when it needs the full details of a specific plan - for example, when displaying plan details to the user, when processing an instance for a specific plan, or when validating a plan before modification. Created per EDGE-3688.

Unlike PlansGetByGCID, this does not aggregate position amounts - it's a simple point lookup returning all plan configuration columns.

---

## 2. Business Logic

No complex business logic. Simple SELECT by primary key with NOLOCK.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | Unique identifier of the plan to retrieve. Maps to Plans.ID. |

**Return Columns**: Same as Plans table columns (PlanID, GCID, CID, InstrumentID, RecurringDepositID, Amount, CurrencyID, PlanStatusID, StatusReasonID, CreationDate, EndDate, DepositStartDate, FrequencyID, RepeatsOn, HasBackupPayment, ValidFrom, FundingID, CopyType, PlanType, CopyParentCID, CopyParentGCID, MopType).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | SELECT by PlanID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetByPlanID (procedure)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | SELECT FROM with NOLOCK |

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

### 8.1 Execute for a specific plan
```sql
EXEC [RecurringInvestment].[PlansGetByPlanID] @PlanID = 100
```

### 8.2 Get plan with resolved statuses
```sql
-- After getting the plan, resolve status IDs:
SELECT p.*, ps.StatusName, pt.Name AS PlanTypeName
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanStatus] ps WITH (NOLOCK) ON p.PlanStatusID = ps.ID
JOIN [Dictionary].[PlanType] pt WITH (NOLOCK) ON p.PlanType = pt.ID
WHERE p.ID = 100
```

### 8.3 Verify plan exists
```sql
IF EXISTS (SELECT 1 FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE ID = @PlanID) EXEC [RecurringInvestment].[PlansGetByPlanID] @PlanID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table structure; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlansGetByPlanID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetByPlanID.sql*
