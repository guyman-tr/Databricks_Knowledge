# Hedge.GetConditionalTags

> Returns the complete conditional FIX tag rule set for a specific provider type - header rules joined to their condition predicates, ordered by priority. Used by the hedge engine to load its per-provider dynamic tag assignment rules at startup.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderTypeID (required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure loads the conditional FIX tag rules for a specific liquidity provider type. The hedge engine uses these rules to dynamically set FIX message tags when submitting hedge orders - the tag values change based on order characteristics evaluated at runtime.

The conditional tag system is a two-table rule engine:
- **`Hedge.ProviderConditionalTags`** (parent): defines the rule header - "IF conditions are met, THEN set FIX tag X to value Y"
- **`Hedge.ConditionalTagsConditions`** (child): defines the boolean predicates that must all be true for the rule to fire

This procedure joins these two tables and returns the denormalized rule set. The hedge engine evaluates rules in `Priority` order (lower value = first), checking each condition predicate. When a rule's conditions are satisfied, it sets `TargetTag = TargetValue` in the outgoing FIX order message.

**Current configuration**: Only FXCM (ProviderTypeID=2) has conditional tag rules. Two rules are configured, both targeting FIX tag 1 with different values at different priority levels - an escalating tier pattern where the first matching rule wins.

---

## 2. Business Logic

### 2.1 Rule Evaluation Order (Priority)

**What**: Rules are returned in ascending priority order. Lower priority number = evaluated first.

**Columns/Parameters Involved**: `Priority` (from `Hedge.ProviderConditionalTags`)

**Rules**:
- ORDER BY Priority ASC - lowest value evaluated first
- When multiple rules can match for the same order, the first matching rule (lowest priority) typically wins
- Priority is an application-semantic concept; SQL just returns rows in order - the engine applies first-match or all-match logic
- Current FXCM rules: Priority 0 (sets TargetValue="1") and Priority 1 (sets TargetValue="2")

### 2.2 JOIN Between Rule Header and Conditions

**What**: Each rule in the result set is expanded with its condition predicate columns.

**Columns/Parameters Involved**: `ConditionID` (JOIN key), `Tag`, `Operator`, `Value`

**Rules**:
- INNER JOIN `Hedge.ConditionalTagsConditions` ON ConditionID - each rule row is joined with its condition
- If a rule has multiple conditions (same ConditionID, multiple rows in ConditionalTagsConditions), the rule appears multiple times in the result (once per condition) - the engine must AND them
- Currently each FXCM rule has exactly one condition (1:1)
- No FK constraint enforces ConditionID integrity between tables - referential integrity is application-managed

### 2.3 Provider Type Scoping

**What**: @ProviderTypeID filters the result to rules configured for one provider type.

**Columns/Parameters Involved**: `@ProviderTypeID`, `ProviderTypeID` (from `Hedge.ProviderConditionalTags`)

**Rules**:
- WHERE ProviderTypeID = @ProviderTypeID - required filter; no default value
- `LiquidityAccountID = 0` in current data = rules apply to all accounts for this provider; engine must apply account-level filtering if needed
- Only FXCM (ProviderTypeID=2) has rules currently; other provider types would return 0 rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderTypeID | int | NO | - | CODE-BACKED | Required. The liquidity provider type to retrieve conditional tag rules for. FK concept to Trade.LiquidityProviderType.LiquidityProviderTypeID. Only ProviderTypeID=2 (FXCM) has rules configured. All other values return 0 rows. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| ConditionID | Hedge.ProviderConditionalTags (PCT) | GUID identifying the rule. FK to Hedge.ConditionalTagsConditions. Each ConditionID groups all conditions (AND predicates) for one rule. |
| LiquidityAccountID | Hedge.ProviderConditionalTags (PCT) | The account this rule applies to. 0 = all accounts for this provider (current data uses 0); non-zero = specific account. Engine applies account-level filtering. |
| TargetTag | Hedge.ProviderConditionalTags (PCT) | The FIX tag number to set when this rule fires (e.g., 1 = FIX Account field). |
| TargetValue | Hedge.ProviderConditionalTags (PCT) | The value to assign to TargetTag in the outgoing FIX message when this rule fires. |
| Tag | Hedge.ConditionalTagsConditions (CTC) | The FIX tag number to evaluate as the left-hand side of the condition predicate. |
| Operator | Hedge.ConditionalTagsConditions (CTC) | The comparison operator for this condition predicate (e.g., ">", "=", "<"). Current data uses ">" only. |
| Value | Hedge.ConditionalTagsConditions (CTC) | The right-hand side of the condition predicate - the value to compare against FIX tag at runtime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM source | Hedge.ProviderConditionalTags | Direct read | Rule headers: ConditionID, LiquidityAccountID, TargetTag, TargetValue, Priority |
| INNER JOIN | Hedge.ConditionalTagsConditions | INNER JOIN on ConditionID | Rule condition predicates: Tag, Operator, Value |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine on startup to load the conditional FIX tag rule set for a provider.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetConditionalTags (procedure)
├── Hedge.ProviderConditionalTags (table) - rule header data (parent)
└── Hedge.ConditionalTagsConditions (table) - condition predicates (child, INNER JOIN on ConditionID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderConditionalTags | Table | FROM clause base; provides ConditionID, LiquidityAccountID, TargetTag, TargetValue, Priority; filtered by ProviderTypeID |
| Hedge.ConditionalTagsConditions | Table | INNER JOIN on ConditionID; provides Tag, Operator, Value condition predicates |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Isolation | Uses default READ COMMITTED (no WITH NOLOCK hint) on both tables |
| INNER JOIN | Design | Rules without matching conditions are excluded; conditions without a parent rule are excluded |
| ORDER BY Priority | Design | Results returned in evaluation order - engine applies rules top-to-bottom |
| @ProviderTypeID required | Design | No default value - caller must always specify a provider type |
| LiquidityAccountID scoping | Delegation | Returns all account-level variants (LiquidityAccountID=0 and specific IDs); caller/engine must apply account-level filtering |

---

## 8. Sample Queries

### 8.1 View all conditional tag rules for FXCM (ProviderTypeID=2)

```sql
SELECT PCT.ConditionID, PCT.LiquidityAccountID,
       PCT.TargetTag, PCT.TargetValue,
       CTC.Tag, CTC.Operator, CTC.Value,
       PCT.Priority
FROM Hedge.ProviderConditionalTags PCT WITH (NOLOCK)
INNER JOIN Hedge.ConditionalTagsConditions CTC WITH (NOLOCK)
       ON PCT.ConditionID = CTC.ConditionID
WHERE PCT.ProviderTypeID = 2
ORDER BY PCT.Priority
```

### 8.2 Check how many rules are configured per provider type

```sql
SELECT PCT.ProviderTypeID,
       COUNT(DISTINCT PCT.ConditionID) AS RuleCount,
       COUNT(*) AS TotalConditionRows
FROM Hedge.ProviderConditionalTags PCT WITH (NOLOCK)
GROUP BY PCT.ProviderTypeID
ORDER BY RuleCount DESC
```

### 8.3 Find rules targeting a specific FIX tag

```sql
SELECT PCT.ProviderTypeID, PCT.ConditionID,
       PCT.TargetTag, PCT.TargetValue, PCT.Priority,
       CTC.Tag, CTC.Operator, CTC.Value
FROM Hedge.ProviderConditionalTags PCT WITH (NOLOCK)
INNER JOIN Hedge.ConditionalTagsConditions CTC WITH (NOLOCK)
       ON PCT.ConditionID = CTC.ConditionID
WHERE PCT.TargetTag = 1
ORDER BY PCT.ProviderTypeID, PCT.Priority
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetConditionalTags | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetConditionalTags.sql*
