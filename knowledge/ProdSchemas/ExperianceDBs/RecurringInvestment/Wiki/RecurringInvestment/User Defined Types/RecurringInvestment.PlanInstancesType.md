# RecurringInvestment.PlanInstancesType

> Minimal table-valued parameter type for identifying plan instances by their composite key (PlanID + NextOrderDate) with optional InstanceID.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with PlanID + NextOrderDate |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This is a lightweight table-valued parameter type used to pass a list of plan instance identifiers to stored procedures. It carries only the minimum data needed to identify instances: PlanID and NextOrderDate (the composite PK of PlanInstances), plus an optional InstanceID.

Used by procedures like PlanInstancesInsertMultiple for batch creation of new plan instances by the Plan Instances Job.

---

## 2. Business Logic

No complex business logic. This is a minimal identifier type for batch operations.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | YES | - | VERIFIED | Optional unique identifier for the instance. NULL when creating new instances (auto-generated IDENTITY). |
| 2 | PlanID | int | NO | - | VERIFIED | Plan this instance belongs to. References Plans.ID. Required for instance identification. |
| 3 | NextOrderDate | datetime | NO | - | VERIFIED | Scheduled execution date for this instance. Part of PlanInstances composite PK. Calculated by Plan Instances Job. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlanID | RecurringInvestment.Plans | Implicit FK | Plan the instance belongs to |
| PlanID + NextOrderDate | RecurringInvestment.PlanInstances | Implicit FK | Instance composite key |

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
| RecurringInvestment.PlanInstancesInsertMultiple | Stored Procedure | Accepts this type for batch instance creation |

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
DECLARE @Instances RecurringInvestment.PlanInstancesType
INSERT INTO @Instances (PlanID, NextOrderDate) VALUES (100, '2026-05-01'), (101, '2026-05-01')
```

### 8.2 Use with insert procedure
```sql
DECLARE @Instances RecurringInvestment.PlanInstancesType
INSERT INTO @Instances (PlanID, NextOrderDate) VALUES (100, '2026-05-01')
EXEC [RecurringInvestment].[PlanInstancesInsertMultiple] @Instances = @Instances
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlanInstancesType' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan Instances Job creates new instance records with calculated NextOrderDate |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstancesType | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlanInstancesType.sql*
