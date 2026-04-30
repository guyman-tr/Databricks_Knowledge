# Dictionary.RuleType

## 1. Business Meaning

**What it is**: A lookup table that classifies CEP (Complex Event Processing) rules by their routing strategy type. CEP rules drive automated hedge execution decisions, and the rule type determines how the routing logic is applied.

**Why it exists**: The CEP engine allows configuring multiple rules that trigger hedge operations based on market conditions. Each rule must specify its routing strategy — whether it uses manual routing (human-defined), hierarchical routing (cascading priority), or no routing at all. This table provides the classification for those strategies.

**How it works**: When a CEP rule is created in `CEP.Rules`, its `RuleTypeID` references this table to classify the routing approach. The `CEP.PropertyToRuleType` junction table links condition properties to specific rule types, controlling which properties are available per rule type.

---

## 2. Business Logic

### Rule Type Classifications
| ID | Description | Meaning |
|----|-------------|---------|
| 0 | NONE | No routing strategy — rule operates without hedge routing |
| 1 | ManualHedgeRouting | Human-defined hedge routing — explicit routing rules set by dealing desk |
| 2 | HeirarchyHedgeRouting | Cascading/hierarchical routing — routes through priority-ordered providers |

### CEP Integration
```
CEP.Rules (defines rule) → RuleTypeID → Dictionary.RuleType (classification)
CEP.PropertyToRuleType → RuleTypeID + PropertyID → which properties apply to which rule type
```

---

## 3. Data Overview

| RuleTypeID | Description | Business Meaning |
|------------|-------------|------------------|
| 0 | NONE | No hedge routing strategy |
| 1 | ManualHedgeRouting | Manual dealer-defined hedge routing |
| 2 | HeirarchyHedgeRouting | Priority-cascading hedge routing |

*3 rows — complete enumeration of all CEP rule routing strategies*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **RuleTypeID** | int | NOT NULL | — | Primary key. Rule type identifier: 0=NONE, 1=ManualHedgeRouting, 2=HeirarchyHedgeRouting. | `MCP` |
| **Description** | varchar(50) | NOT NULL | — | Human-readable label for the routing strategy. Used in Configuration Manager UI and CEP rule display. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| CEP.Rules | RuleTypeID | FK_Rules_RuleType | Each CEP rule has a routing strategy type |
| CEP.PropertyToRuleType | RuleTypeID | FK_CEP_PropToRuleType_RuleType | Maps which condition properties are valid for each rule type (temporal) |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `CEP.Rules` — CEP rule definitions
- `CEP.PropertyToRuleType` — property-to-rule-type mapping (temporal, with history tracking)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `RuleTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 3 |

---

## 8. Sample Queries

```sql
-- Get all rule types
SELECT  RuleTypeID, Description
FROM    Dictionary.RuleType WITH (NOLOCK)
ORDER BY RuleTypeID;

-- Find CEP rules by routing strategy
SELECT  R.RuleID, R.Name, R.IsActive, RT.Description AS RuleType
FROM    CEP.Rules R WITH (NOLOCK)
JOIN    Dictionary.RuleType RT WITH (NOLOCK) ON RT.RuleTypeID = R.RuleTypeID
ORDER BY RT.RuleTypeID, R.RuleID;

-- Properties available per rule type
SELECT  RT.Description AS RuleType, CP.PropertyName
FROM    CEP.PropertyToRuleType PTR WITH (NOLOCK)
JOIN    Dictionary.RuleType RT WITH (NOLOCK) ON RT.RuleTypeID = PTR.RuleTypeID
JOIN    Dictionary.ConditionProperties CP WITH (NOLOCK) ON CP.PropertyID = PTR.PropertyID
ORDER BY RT.RuleTypeID, CP.PropertyName;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table. The CEP engine's rule routing is an internal dealing desk feature.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (3 rows), codebase traced (2 FK consumers: CEP.Rules, CEP.PropertyToRuleType)*
