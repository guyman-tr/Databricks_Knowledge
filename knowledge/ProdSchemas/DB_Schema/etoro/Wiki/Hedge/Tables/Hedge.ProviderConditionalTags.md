# Hedge.ProviderConditionalTags

> Conditional FIX tag rule header table - each row defines a "IF conditions are met, THEN set FIX tag to value" rule for a specific provider and account, ordered by priority. Conditions are stored in the child table Hedge.ConditionalTagsConditions.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ConditionID (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No (on [DICTIONARY] filegroup, FILLFACTOR=100) |
| **Indexes** | 1 (PK only) |
| **Versioning** | SYSTEM_VERSIONING -> History.ProviderConditionalTags |

---

## 1. Business Meaning

`Hedge.ProviderConditionalTags` is the parent table of a two-table conditional tag rule system. Each row represents a complete conditional rule: "**IF** the conditions in `ConditionalTagsConditions` (matched by ConditionID) are satisfied, **THEN** set FIX tag `TargetTag` to `TargetValue` when submitting orders to this provider/account."

This is the dynamic counterpart to `Hedge.ProviderExternalTags` (which always applies static or template tags). Conditional tags are applied based on order characteristics at runtime - for example, setting a routing code based on order size or instrument type.

The system is consumed by `Hedge.GetConditionalTags(@ProviderTypeID)` which JOINs this table with `ConditionalTagsConditions` and returns the full rule set ordered by `Priority`. The hedge engine processes rules in priority order, applying the first matching rule (or all matching rules - depends on engine implementation).

**Current data** (2 rows, ProviderTypeID=2 = FXCM):
- Rule 1 (Priority=0): IF Tag=1 > "1" THEN set FIX tag 1 = "1"
- Rule 2 (Priority=1): IF Tag=2 > "2" THEN set FIX tag 1 = "2"
Both rules target the same FIX tag (TargetTag=1) with different values, suggesting an escalating tier: the rule that fires sets the tag to indicate the tier.

---

## 2. Business Logic

### 2.1 Rule Priority and Execution Order

**What**: `Priority` determines which conditional rule is evaluated and applied first when multiple rules match for the same provider/account.

**Columns/Parameters Involved**: `Priority`, `ConditionID`, `ProviderTypeID`

**Rules**:
- Lower priority value = evaluated/applied first (0 before 1, 1 before 2, etc.)
- `GetConditionalTags` returns rows `ORDER BY Priority` - hedge engine processes in this order
- If multiple rules can match: depends on engine implementation (first-match-wins vs all-matching)
- Each ConditionID's conditions are AND'd: ALL conditions in ConditionalTagsConditions must be true for the rule to fire

### 2.2 Target Tag Assignment

**What**: When a rule fires, `TargetTag` (FIX tag number) is set to `TargetValue` in the outgoing FIX order message.

**Columns/Parameters Involved**: `TargetTag`, `TargetValue`

**Rules**:
- TargetTag: int = FIX tag number to set (e.g., 1 = FIX Account field)
- TargetValue: varchar(256) = value to assign to that tag
- Multiple rules can target the same TargetTag with different values (priority-based selection)

### 2.3 Account Scoping

**What**: `LiquidityAccountID` scopes the rule to either all accounts or a specific account for a provider.

**Columns/Parameters Involved**: `LiquidityAccountID`

**Rules**:
- 0 = applies to all accounts for this provider (both current rules use 0)
- Non-zero = applies to one specific liquidity account
- Reader `GetConditionalTags` filters only by ProviderTypeID, not LiquidityAccountID - engine must apply account filtering

---

## 3. Data Overview

| ConditionID | ProviderTypeID | Provider | LiquidityAccountID | Priority | TargetTag | TargetValue | Conditions |
|---|---|---|---|---|---|---|---|
| E56A000A-... | 2 | FXCM | 0 | 0 | 1 | "1" | Tag=1 > "1" |
| 82521661-... | 2 | FXCM | 0 | 1 | 1 | "2" | Tag=2 > "2" |

Total: 2 rows. Only FXCM (ProviderTypeID=2) has conditional tag rules configured. History tracked via SYSTEM_VERSIONING.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConditionID | uniqueidentifier | NO | - | VERIFIED | Primary key. Unique GUID identifying this conditional rule. Referenced by ConditionalTagsConditions.ConditionID to link conditions to this rule header. |
| 2 | ProviderTypeID | int | NO | - | VERIFIED | FK to Trade.LiquidityProviderType(LiquidityProviderTypeID). The provider this rule applies to. GetConditionalTags filters by this column. Currently only FXCM (2) has rules. |
| 3 | LiquidityAccountID | int | NO | - (required) | CODE-BACKED | Account scope for this rule. 0 = applies to all accounts for this provider. Non-zero = account-specific rule. No DEFAULT, no FK constraint. Both current rules use 0 (global scope). |
| 4 | Priority | int | NO | - (required) | VERIFIED | Rule evaluation order. Lower value = evaluated first. GetConditionalTags returns rows ORDER BY Priority. 0=first, 1=second, etc. |
| 5 | TargetTag | int | NO | - (required) | VERIFIED | FIX tag number to set when conditions are met. int type supports both standard FIX tags and custom tag numbers. Current rules both target FIX tag 1 (Account field). |
| 6 | TargetValue | varchar(256) | NO | - (required) | VERIFIED | Value to assign to TargetTag in the FIX order message when conditions are satisfied. Current values: "1" and "2" (tier identifiers). |
| 7 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 8 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 9 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 10 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ProviderConditionalTags. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderTypeID | Trade.LiquidityProviderType | FK (FK_Hedge_ProviderConditionalTags_ProviderType) | Provider type must exist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ConditionalTagsConditions | ConditionID | Logical Parent (no FK constraint) | Child conditions reference this table's ConditionID |
| Hedge.GetConditionalTags | ProviderTypeID | READER | JOINs with ConditionalTagsConditions, returns full rule set ordered by Priority |
| History.ProviderConditionalTags | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ProviderConditionalTags (table)
  └── Trade.LiquidityProviderType (table) [FK - ProviderTypeID]
```

```
Hedge.ConditionalTagsConditions (table)
  └── Hedge.ProviderConditionalTags [logical parent via ConditionID - no FK]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderType | Table | FK_Hedge_ProviderConditionalTags_ProviderType - provider must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ConditionalTagsConditions | Table | Logical child via ConditionID (no FK constraint enforced) |
| Hedge.GetConditionalTags | Stored Procedure | READER - loads conditional tag rules for a provider |
| History.ProviderConditionalTags | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProviderConditionalTags | CLUSTERED PK | ConditionID ASC | - | - | Active (FILLFACTOR=100) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ProviderConditionalTags | PRIMARY KEY | ConditionID - globally unique rule identifier |
| FK_Hedge_ProviderConditionalTags_ProviderType | FOREIGN KEY | ProviderTypeID must reference Trade.LiquidityProviderType |
| DF_ProviderConditionalTags_SysStart | DEFAULT | SysStartTime = getutcdate() (implied - temporal) |
| DF_ProviderConditionalTags_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' (implied - temporal) |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ProviderConditionalTags |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_Hedge_ProviderConditionalTags_INSERT | INSERT | No-op self-UPDATE (joins on ProviderTypeID, LiquidityAccountID, TargetTag) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all conditional tag rules with their conditions (matches GetConditionalTags)

```sql
-- Matches Hedge.GetConditionalTags(@ProviderTypeID=2)
SELECT
    pct.ConditionID,
    pct.LiquidityAccountID,
    pct.TargetTag,
    pct.TargetValue,
    ctc.Tag,
    ctc.Operator,
    ctc.Value
FROM Hedge.ProviderConditionalTags pct WITH (NOLOCK)
JOIN Hedge.ConditionalTagsConditions ctc WITH (NOLOCK)
    ON pct.ConditionID = ctc.ConditionID
WHERE pct.ProviderTypeID = 2  -- FXCM
ORDER BY pct.Priority
```

### 8.2 Find all rules targeting a specific FIX tag

```sql
SELECT
    pct.ConditionID,
    pct.ProviderTypeID,
    pct.Priority,
    pct.TargetTag,
    pct.TargetValue
FROM Hedge.ProviderConditionalTags pct WITH (NOLOCK)
WHERE pct.TargetTag = 1
ORDER BY pct.ProviderTypeID, pct.Priority
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ProviderConditionalTags | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ProviderConditionalTags.sql*
