# RecurringInvestment.PlanInstanceInsert

> Creates a new plan instance record for the next execution cycle, with duplicate prevention (no future instance within 2 days).

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID + @NextOrderDate input, inserts into PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new plan instance record for the next execution cycle. Called by the Plan Instances Job (which runs daily at 18:20) when it detects that an active plan needs a new instance record. The instance is created with just PlanID and NextOrderDate - all other columns are initially NULL and get populated as the cycle progresses through deposit, order, and position stages.

Includes duplicate prevention: only inserts if no instance exists for this plan with NextOrderDate more than 2 days in the future. This prevents the daily job from creating duplicate future instances. Created per EDGE-3688.

---

## 2. Business Logic

### 2.1 Duplicate Prevention

**What**: Prevents creating duplicate future instances for the same plan.

**Columns/Parameters Involved**: `@PlanID`, `@NextOrderDate`, `GETUTCDATE()`

**Rules**:
- Checks: NOT EXISTS (instance for this PlanID with NextOrderDate > GETUTCDATE() + 2 days)
- Only inserts if no future instance exists (beyond 2-day buffer)
- The 2-day buffer prevents edge cases around the execution date

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | Plan to create the instance for. References Plans.ID. |
| 2 | @NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance. Calculated by Plan Instances Job. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write + Read | INSERT INTO (with existence check) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceInsert (procedure)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INSERT INTO with NOT EXISTS check |

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

### 8.1 Create a new instance
```sql
EXEC [RecurringInvestment].[PlanInstanceInsert] @PlanID = 100, @NextOrderDate = '2026-05-01 14:45:00'
```

### 8.2 Check if instance would be created
```sql
SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK) WHERE PlanID = 100 AND NextOrderDate > DATEADD(DAY, 2, GETUTCDATE())) THEN 'Would insert' ELSE 'Skipped (future instance exists)' END
```

### 8.3 Verify the insert
```sql
SELECT TOP 1 * FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK) WHERE PlanID = 100 ORDER BY NextOrderDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan Instances Job creates new instance records daily at 18:20; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstanceInsert | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceInsert.sql*
