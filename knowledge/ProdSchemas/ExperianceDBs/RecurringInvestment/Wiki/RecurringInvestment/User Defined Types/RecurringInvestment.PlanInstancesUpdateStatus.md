# RecurringInvestment.PlanInstancesUpdateStatus

> Table-valued parameter type for batch-updating plan instance statuses - identical structure to PlanInstancesTypeUpdateStatus.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with InstanceID + PlanID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table-valued parameter type is structurally identical to PlanInstancesTypeUpdateStatus - it carries instance identifiers with target status and reason for batch status update operations. The existence of two identically-structured types likely reflects an evolution in naming convention or different consuming procedures.

Used by procedures that need to batch-update instance lifecycle states.

---

## 2. Business Logic

No complex business logic. Same structure and purpose as PlanInstancesTypeUpdateStatus.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | VERIFIED | Unique identifier of the plan instance to update. References PlanInstances.InstanceID. |
| 2 | PlanID | int | NO | - | VERIFIED | Plan this instance belongs to. References Plans.ID. |
| 3 | InstanceStatusID | int | NO | - | VERIFIED | Target instance status. See [Instance Status](../../_glossary.md#instance-status). (Dictionary.InstanceStatusID) |
| 4 | InstanceStatusReasonID | int | NO | - | VERIFIED | Reason for the status change. See [Plan Event Code](../../_glossary.md#plan-event-code). (Dictionary.PlanEventCode) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstanceID/PlanID | RecurringInvestment.PlanInstances | Implicit FK | Instance being updated |
| InstanceStatusID | Dictionary.InstanceStatusID | Implicit Lookup | Target status |
| InstanceStatusReasonID | Dictionary.PlanEventCode | Implicit Lookup | Reason for status change |

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

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Updates RecurringInvestment.PlanInstancesUpdateStatus
INSERT INTO @Updates (InstanceID, PlanID, InstanceStatusID, InstanceStatusReasonID)
VALUES (1001, 100, 2, 300)
```

### 8.2 Compare with PlanInstancesTypeUpdateStatus
```sql
SELECT tt.name AS TypeName, c.name AS ColumnName, t.name AS DataType, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name IN ('PlanInstancesUpdateStatus', 'PlanInstancesTypeUpdateStatus')
  AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY tt.name, c.column_id
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PlanInstancesUpdateStatus' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInstancesUpdateStatus | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.PlanInstancesUpdateStatus.sql*
