# RecurringInvestment.PlanInstancesInsertMultiple

> Batch-inserts new plan instance records from a TVP with duplicate prevention, ensuring no future instance already exists.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanInstancesInsertMultiple TVP, inserts into PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates new plan instance records in bulk from a table-valued parameter. It is the batch version of `PlanInstanceInsert`, designed for the Instance Creation Job that generates next-month instances for all active plans. Each new instance represents a future execution cycle of a recurring investment plan.

The procedure includes a critical duplicate-prevention check: it only inserts a new instance if the plan does not already have a future instance more than 2 days from now. This prevents double-creation in case the Instance Creation Job runs multiple times. Created per EDGE-4377 (Nilly, 1/1/25).

New instances are created with only PlanID and NextOrderDate -- all other columns start as NULL, representing a fresh instance awaiting the deposit step.

---

## 2. Business Logic

### 2.1 Duplicate-Prevention Insert

**What**: Inserts new instances only if no future instance already exists for the plan.

**Columns/Parameters Involved**: `@PlanInstancesInsertMultiple` (PlanInstancesType TVP), `PlanID`, `NextOrderDate`

**Rules**:
- INSERT INTO PlanInstances (PlanID, NextOrderDate) from TVP
- NOT EXISTS subquery checks: no existing instance for the same PlanID with NextOrderDate > DATEADD(DAY, 2, GETUTCDATE())
- The 2-day buffer prevents creating duplicates when the job runs near month boundaries
- If a future instance already exists (>2 days ahead), the INSERT is skipped for that plan
- Only PlanID and NextOrderDate are inserted; all other instance columns remain NULL

**Diagram**:
```
Instance Creation Job
    |
    v
@PlanInstancesInsertMultiple TVP: [(PlanA, May 15), (PlanB, May 1), ...]
    |
    For each row:
    +-- EXISTS future instance for PlanA (>2 days ahead)? --[Yes]--> Skip
    |                                                        |
    |                                                       [No]
    |                                                        |
    +-- INSERT (PlanA, May 15) into PlanInstances
```

### 2.2 Minimal Initial State

**What**: New instances are created with only scheduling data; execution data is populated later.

**Columns/Parameters Involved**: `PlanID`, `NextOrderDate`

**Rules**:
- Only PlanID and NextOrderDate are set at creation
- DepositID, OrderID, PositionStatus, InstanceStatusID all start as NULL
- The instance progresses through the pipeline as each stage completes
- This enables the Before Deposit Job to detect fresh instances (InstanceStatusID IS NULL)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanInstancesInsertMultiple | RecurringInvestment.PlanInstancesType (TVP) | NO | - | VERIFIED | Table-valued parameter containing PlanID and NextOrderDate pairs for new instances. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (INSERT) | Creates new instance records |
| @PlanInstancesInsertMultiple | RecurringInvestment.PlanInstancesType | TVP | Input type for batch insert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instance Creation Job | - | EXEC | Creates next-month instances for all active plans |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesInsertMultiple (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.PlanInstancesType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | INSERT INTO with NOT EXISTS duplicate check |
| RecurringInvestment.PlanInstancesType | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instance Creation Job | Background Service | Batch instance creation for active plans |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOT EXISTS prevents duplicate future instances (>2 days ahead)
- TVP is READONLY

---

## 8. Sample Queries

### 8.1 Batch-insert instances for next month
```sql
DECLARE @TVP RecurringInvestment.PlanInstancesType
INSERT INTO @TVP (PlanID, NextOrderDate) VALUES (1001, '2026-05-15'), (1002, '2026-05-01'), (1003, '2026-05-20')
EXEC [RecurringInvestment].[PlanInstancesInsertMultiple] @PlanInstancesInsertMultiple = @TVP
```

### 8.2 Check which plans already have future instances
```sql
SELECT PlanID, NextOrderDate
FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK)
WHERE NextOrderDate > DATEADD(DAY, 2, GETUTCDATE())
ORDER BY PlanID
```

### 8.3 Verify new instances were created
```sql
SELECT PI.InstanceID, PI.PlanID, PI.NextOrderDate, PI.InstanceStatusID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
WHERE PI.NextOrderDate > GETUTCDATE()
ORDER BY PI.NextOrderDate ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances creation flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Instance creation job architecture |
| [EDGE-4377](https://etoro-jira.atlassian.net/browse/EDGE-4377) | Jira | Batch instance creation implementation |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanInstancesInsertMultiple | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesInsertMultiple.sql*
