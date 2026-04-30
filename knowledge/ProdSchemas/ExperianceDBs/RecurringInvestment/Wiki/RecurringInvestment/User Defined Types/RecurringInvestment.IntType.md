# RecurringInvestment.IntType

> Generic table-valued parameter type holding a single integer column, used to pass lists of integer values to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with ColunmINT (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a generic utility table-valued parameter type that holds a list of integer values. It enables stored procedures to accept a set of integers as input - for example, a list of PlanIDs, InstrumentIDs, or other integer identifiers - instead of requiring comma-separated strings or multiple calls.

Without this type, procedures that need to operate on a set of integer values would need to use string splitting, dynamic SQL, or multiple individual calls.

Note: The column name "ColunmINT" contains a typo (missing 'n' in "Column") that has been preserved from the original DDL.

---

## 2. Business Logic

No complex business logic. This is a generic utility type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ColunmINT | int | NO | - | CODE-BACKED | Integer value passed as part of a list. The generic nature of this type means the column can represent any integer domain (PlanID, InstrumentID, etc.) depending on context. Note: column name has a typo ("Colunm" instead of "Column"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

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
DECLARE @Ids RecurringInvestment.IntType
INSERT INTO @Ids (ColunmINT) VALUES (1), (2), (3)
```

### 8.2 Use as filter in a query
```sql
DECLARE @PlanIds RecurringInvestment.IntType
INSERT INTO @PlanIds (ColunmINT) VALUES (100), (200), (300)
SELECT * FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
WHERE p.ID IN (SELECT ColunmINT FROM @PlanIds)
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'IntType' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.IntType | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.IntType.sql*
