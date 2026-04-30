# History.CEP_LOG_ConditionToRule

> Trigger-based audit log capturing previous versions of direct condition-to-rule assignments in the CEP rules engine; records which conditions were directly attached to rules (as opposed to via compound properties).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (RuleID, ConditionID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_ConditionToRule captures the version history of direct condition-to-rule bindings in the CEP rules engine. While most conditions are attached to rules via compound properties (see History.CEP_LOG_ConditionToCompoundProperty), it is also possible to attach conditions directly to rules without grouping them into a compound property first.

CEP.ConditionToRule stores the live direct bindings. With only 2 rows in this history table, direct condition-to-rule assignments are extremely rare - the vast majority of rule wiring goes through compound properties.

---

## 2. Business Logic

### 2.1 Direct Condition-to-Rule Assignment History

**What**: Each row records one prior direct binding of a condition to a rule.

**Columns/Parameters Involved**: `RuleID`, `ConditionID`, `ValidFrom`, `ValidTo`

**Rules**:
- RuleID: the rule that directly contained this condition
- ConditionID: the condition directly assigned to the rule
- Same trigger pattern: UPDATE/DELETE on CEP.ConditionToRule write old rows here
- Only 2 historical rows indicates this path is rarely used; compound properties are the standard mechanism

---

## 3. Data Overview

2 rows - near-unused audit log. Direct condition-to-rule bindings are extremely rare in the CEP configuration.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleID | int | NO | - | CODE-BACKED | The rule that directly contained the condition. References CEP.Rules. Part of composite PK. |
| 2 | ConditionID | int | NO | - | CODE-BACKED | The condition directly bound to the rule. References CEP.Conditions. Part of composite PK. |
| 3 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this direct binding became active. Copied from parent row. Part of composite PK. |
| 4 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this direct binding was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RuleID | CEP.ConditionToRule | Trigger audit | Past version of a direct condition binding |
| ConditionID | CEP.Conditions | Implicit | The condition that was directly assigned |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.ConditionToRule | DELETE/UPDATE triggers | Writer | Copies changed direct binding rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_ConditionToRule (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.ConditionToRule | Table | Trigger writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEP_LOG_ConditionToRule | CLUSTERED PK | RuleID ASC, ConditionID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEP_LOG_ConditionToRule | PRIMARY KEY | (RuleID, ConditionID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View all direct condition-rule binding history
```sql
SELECT RuleID, ConditionID, ValidFrom, ValidTo
FROM [History].[CEP_LOG_ConditionToRule]
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_ConditionToRule | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_ConditionToRule.sql*
