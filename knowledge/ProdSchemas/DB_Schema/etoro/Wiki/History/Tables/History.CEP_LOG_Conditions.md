# History.CEP_LOG_Conditions

> Trigger-based audit log capturing previous versions of CEP conditions whenever they are updated or deleted; each row records one past state of a condition's operator, value, and property.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ConditionID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_Conditions captures the version history of atomic conditions in the CEP rules engine. A condition is the fundamental evaluation unit: it tests a specific property (PropertyID) against a value (Value) using a comparison operator (OperatorID). Conditions are the building blocks that compound properties and rules are composed from.

CEP.Conditions stores the live condition definitions. When a condition is modified or deleted, triggers copy the prior row here. With 4,920 rows, this table reflects active condition tuning during rules development.

---

## 2. Business Logic

### 2.1 Condition Audit Pattern

**What**: Each row is a snapshot of one condition definition before it was changed.

**Columns/Parameters Involved**: `ConditionID`, `OperatorID`, `Value`, `PropertyID`, `ValidFrom`, `ValidTo`

**Rules**:
- ConditionID: the condition that was modified
- OperatorID: the comparison operator (e.g., equals, greater than, contains); references a Dictionary lookup
- Value: the target value the property is compared against (stored as varchar - can be numeric or string)
- PropertyID: the property being evaluated (e.g., InstrumentID, CID, position size); references CEP property definitions
- Same trigger pattern: UPDATE/DELETE on CEP.Conditions write old rows here

---

## 3. Data Overview

4,920 rows of condition change events.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConditionID | int | NO | - | CODE-BACKED | Identifies the condition that was changed. References CEP.Conditions. Part of composite PK. |
| 2 | OperatorID | int | NO | - | CODE-BACKED | The comparison operator used in the condition (e.g., 1=equals, 2=greater than). References a CEP operator lookup. |
| 3 | Value | varchar(50) | NO | - | CODE-BACKED | The comparison target value as it existed before this change. Stored as string to accommodate diverse property types (numeric, ID, flag). |
| 4 | PropertyID | int | NO | - | CODE-BACKED | The CEP property being evaluated (e.g., customer tier, instrument type, position magnitude). References CEP property definitions. |
| 5 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this condition version became active. Copied from parent row. Part of composite PK. |
| 6 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this condition was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConditionID | CEP.Conditions | Trigger audit | Past version of a live condition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.Conditions | DELETE/UPDATE triggers | Writer | Copies changed condition rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_Conditions (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.Conditions | Table | Trigger writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Conditions | CLUSTERED PK | ConditionID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Conditions | PRIMARY KEY | (ConditionID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View history of a specific condition
```sql
SELECT ConditionID, OperatorID, Value, PropertyID, ValidFrom, ValidTo
FROM [History].[CEP_LOG_Conditions]
WHERE ConditionID = @ConditionID
ORDER BY ValidFrom DESC
```

### 8.2 Conditions changed in a date range
```sql
SELECT ConditionID, OperatorID, Value, PropertyID, ValidFrom, ValidTo
FROM [History].[CEP_LOG_Conditions]
WHERE ValidTo BETWEEN @StartDate AND @EndDate
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_Conditions | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_Conditions.sql*
