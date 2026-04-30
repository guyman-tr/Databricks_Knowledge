# History.CEP_LOG_ConditionToCompoundProperty

> Trigger-based audit log capturing previous versions of condition-to-compound-property assignments in the CEP rules engine; records which conditions belonged to which compound properties at the time of change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CompoundPropertyID, ConditionID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_ConditionToCompoundProperty captures the version history of the many-to-many relationship between conditions and compound properties in the CEP rules engine. A compound property is composed of multiple atomic conditions; this table records which conditions were grouped into each compound property, and when those groupings changed.

CEP.ConditionToCompoundProperty stores the live assignments. When an assignment is updated or deleted, triggers copy the old row here. With 4,892 rows this closely mirrors the Conditions log count, reflecting that condition membership changes often accompany condition definition changes.

---

## 2. Business Logic

### 2.1 Condition-to-Compound-Property Assignment History

**What**: Each row records one prior grouping of a condition into a compound property.

**Columns/Parameters Involved**: `CompoundPropertyID`, `ConditionID`, `ValidFrom`, `ValidTo`

**Rules**:
- CompoundPropertyID: the compound property that contained this condition
- ConditionID: the condition that was a member of this compound property
- No Value column - this is a pure membership link (unlike CompoundPropertyToRule which has a Value bit)
- Same trigger pattern: UPDATE/DELETE on CEP.ConditionToCompoundProperty write old rows here

---

## 3. Data Overview

4,892 rows of condition-to-compound-property assignment change events.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CompoundPropertyID | int | NO | - | CODE-BACKED | The compound property that contained the condition. References CEP.CompoundProperties. Part of composite PK. |
| 2 | ConditionID | int | NO | - | CODE-BACKED | The condition that was a member of this compound property. References CEP.Conditions. Part of composite PK. |
| 3 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this membership version became active. Copied from parent row. Part of composite PK. |
| 4 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this membership was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CompoundPropertyID | CEP.ConditionToCompoundProperty | Trigger audit | Past version of a condition membership |
| ConditionID | CEP.Conditions | Implicit | The condition that was a member |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.ConditionToCompoundProperty | DELETE/UPDATE triggers | Writer | Copies changed membership rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_ConditionToCompoundProperty (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.ConditionToCompoundProperty | Table | Trigger writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEP_LOG_ConditionToCompoundProperty | CLUSTERED PK | CompoundPropertyID ASC, ConditionID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEP_LOG_ConditionToCompoundProperty | PRIMARY KEY | (CompoundPropertyID, ConditionID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 Conditions that were ever part of a compound property
```sql
SELECT CompoundPropertyID, ConditionID, ValidFrom, ValidTo
FROM [History].[CEP_LOG_ConditionToCompoundProperty]
WHERE CompoundPropertyID = @CompoundPropertyID
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_ConditionToCompoundProperty | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_ConditionToCompoundProperty.sql*
