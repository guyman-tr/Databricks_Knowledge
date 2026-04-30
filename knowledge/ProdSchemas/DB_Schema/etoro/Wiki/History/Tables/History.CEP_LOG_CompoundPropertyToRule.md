# History.CEP_LOG_CompoundPropertyToRule

> Trigger-based audit log capturing previous versions of compound property-to-rule assignments in the CEP rules engine; records which compound properties were attached to which rules and the expected value at time of change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (RuleID, CompoundPropertyID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_CompoundPropertyToRule is part of the CEP audit log family. It captures the history of the many-to-many relationship between CEP rules and compound properties - specifically, which compound property was assigned to which rule and the expected evaluation result (Value bit) that determines rule activation.

CEP.CompoundPropertyToRule stores the live assignments. When an assignment is updated or deleted, triggers copy the old row here. With 9,931 rows this is the most heavily changed of the CEP_LOG tables, reflecting that rule-to-compound-property wiring is frequently modified during rules engine tuning.

---

## 2. Business Logic

### 2.1 Rule-to-Compound-Property Assignment History

**What**: Each row captures one prior version of a rule-compound-property binding.

**Columns/Parameters Involved**: `RuleID`, `CompoundPropertyID`, `Value`, `ValidFrom`, `ValidTo`

**Rules**:
- RuleID: the CEP rule that was assigned this compound property
- CompoundPropertyID: the compound property (named condition group) assigned to the rule
- Value (bit): the expected evaluation result of the compound property for rule activation. True = compound property must evaluate to true; False = must evaluate to false (negation)
- Same trigger pattern as other CEP_LOG tables: UPDATE and DELETE on CEP.CompoundPropertyToRule write old rows here
- ValidFrom copied from parent; ValidTo defaults to getutcdate() at INSERT

---

## 3. Data Overview

9,931 rows - the most actively changed of the CEP_LOG tables, indicating frequent rewiring of rule-to-compound-property assignments during rules engine development and tuning.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleID | int | NO | - | CODE-BACKED | The CEP rule this compound property was assigned to. References CEP.Rules (RuleID). Part of composite PK. |
| 2 | CompoundPropertyID | int | NO | - | CODE-BACKED | The compound property (named condition group) assigned to the rule. References CEP.CompoundProperties (CompoundPropertyID). Part of composite PK. |
| 3 | Value | bit | YES | - | CODE-BACKED | Expected evaluation outcome of the compound property. True = the compound property must evaluate to true for rule activation; False = must evaluate to false (logical negation). Nullable. |
| 4 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this assignment version became active. Copied from parent row. Part of composite PK. |
| 5 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this assignment was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RuleID | CEP.CompoundPropertyToRule | Trigger audit | Past version of a rule-to-compound-property binding |
| CompoundPropertyID | CEP.CompoundProperties | Implicit | The compound property that was assigned |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.CompoundPropertyToRule | DELETE trigger | Writer | Copies deleted assignment rows here |
| CEP.CompoundPropertyToRule | UPDATE trigger | Writer | Copies pre-update assignment rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_CompoundPropertyToRule (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.CompoundPropertyToRule | Table | Trigger writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEP_LOG_CompoundPropertyToRule | CLUSTERED PK | RuleID ASC, CompoundPropertyID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEP_LOG_CompoundPropertyToRule | PRIMARY KEY | (RuleID, CompoundPropertyID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View assignment history for a specific rule
```sql
SELECT RuleID, CompoundPropertyID, Value, ValidFrom, ValidTo
FROM [History].[CEP_LOG_CompoundPropertyToRule]
WHERE RuleID = @RuleID
ORDER BY ValidFrom DESC
```

### 8.2 Find rules where a specific compound property assignment changed
```sql
SELECT RuleID, CompoundPropertyID, Value, ValidFrom, ValidTo
FROM [History].[CEP_LOG_CompoundPropertyToRule]
WHERE CompoundPropertyID = @CompoundPropertyID
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_CompoundPropertyToRule | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_CompoundPropertyToRule.sql*
