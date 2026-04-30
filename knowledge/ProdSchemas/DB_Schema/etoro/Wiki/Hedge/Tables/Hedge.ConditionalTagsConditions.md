# Hedge.ConditionalTagsConditions

> Child condition table for the conditional FIX tag rule system - each row is one boolean predicate (Tag Operator Value) that must be satisfied for the parent rule in Hedge.ProviderConditionalTags to fire and apply its target FIX tag value.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No (on [DICTIONARY] filegroup, FILLFACTOR=100) |
| **Indexes** | 2 (PK + UNIQUE on ConditionID+Tag+Operator) |
| **Versioning** | SYSTEM_VERSIONING -> History.ConditionalTagsConditions |

---

## 1. Business Meaning

`Hedge.ConditionalTagsConditions` is the child table in the two-table conditional tag rule system. Each row defines one boolean predicate that contributes to a rule:

```
Tag  Operator  Value
  1     >        1     =  "FIX tag 1 is greater than 1"
```

When all conditions for a given `ConditionID` are true, the parent rule in `ProviderConditionalTags` fires and sets `TargetTag = TargetValue` in the outgoing FIX order.

Multiple condition rows under the same `ConditionID` are combined with logical AND: the rule fires only if ALL conditions are satisfied.

The `ConditionID` logically references `Hedge.ProviderConditionalTags.ConditionID` but there is **no FK constraint** in the DDL - integrity is application-managed.

**Current data** (2 rows):
- ConditionID=E56A000A: Tag=1, Operator=">", Value="1" (condition for Priority=0 rule of FXCM)
- ConditionID=82521661: Tag=2, Operator=">", Value="2" (condition for Priority=1 rule of FXCM)

Each condition belongs to a different ConditionID (1:1 in current data), meaning each rule has exactly one condition. The schema supports multiple conditions per rule (AND logic) but only single-condition rules are configured today.

---

## 2. Business Logic

### 2.1 Boolean Predicate Structure

**What**: Each row defines one predicate: `Tag Operator Value`.

**Columns/Parameters Involved**: `Tag`, `Operator`, `Value`

**Rules**:
- `Tag` (int): FIX tag number to evaluate (e.g., 1 = Account, 2 = AdvId, etc.)
- `Operator` (varchar 50): Comparison operator. Current value: ">". Likely supports "=", "!=", "<", ">=", "<=", "LIKE", etc.
- `Value` (varchar 256): The right-hand side of the comparison. Current values: "1" and "2" (numeric strings for comparison with int-like FIX tag values)
- The predicate is evaluated against actual FIX message field values at order submission time

### 2.2 Multiple Conditions = Logical AND

**What**: Multiple rows with the same `ConditionID` define a compound condition where ALL must be true.

**Columns/Parameters Involved**: `ConditionID`, `Tag`, `Operator`

**Rules**:
- All rows with the same ConditionID form a logical AND
- The UNIQUE constraint on (ConditionID, Tag, Operator) prevents duplicate predicates for the same condition
- This means each (conditionID, tag, operator) combination is unique - but you CAN have the same tag with different operators (e.g., Tag=1 > "1" AND Tag=1 < "10")

### 2.3 No FK to Parent Table

**What**: The `ConditionID` column has no FK constraint to `ProviderConditionalTags`.

**Rules**:
- Application is responsible for maintaining referential integrity
- Orphaned conditions (ConditionID not in ProviderConditionalTags) would never be loaded (GetConditionalTags JOIN would exclude them)
- Deleting a ProviderConditionalTags row would NOT cascade to this table

---

## 3. Data Overview

| ID | ConditionID | Tag | Operator | Value | Parent Rule (from ProviderConditionalTags) |
|---|---|---|---|---|---|
| 1 | E56A000A-... | 1 | > | 1 | FXCM Priority=0: IF Tag1 > 1 THEN set FIX Tag1 = "1" |
| 2 | 82521661-... | 2 | > | 2 | FXCM Priority=1: IF Tag2 > 2 THEN set FIX Tag1 = "2" |

Total: 2 rows. History tracked via SYSTEM_VERSIONING.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | auto | VERIFIED | Surrogate PK. Auto-increment identity. Used only as the clustered key; the logical key is (ConditionID, Tag, Operator) enforced by the UNIQUE constraint. |
| 2 | ConditionID | uniqueidentifier | NO | - (required) | VERIFIED | Groups conditions into a single logical rule. Must match a ConditionID in ProviderConditionalTags (no FK - application integrity). All rows with the same ConditionID are AND'd together. |
| 3 | Tag | int | NO | - (required) | VERIFIED | FIX tag number to evaluate in the predicate. Same tag numbering as TargetTag in ProviderConditionalTags. Used as the left-hand side of the boolean expression (Tag Operator Value). |
| 4 | Operator | varchar(50) | NO | - (required) | CODE-BACKED | Comparison operator for the predicate. Current value: ">". Supports standard comparison operators interpreted by the hedge engine (=, !=, <, >, <=, >=, likely). varchar(50) accommodates multi-character operators like "LIKE" or "IN". |
| 5 | Value | varchar(256) | NO | - (required) | VERIFIED | Right-hand side of the predicate comparison. Stored as string; interpreted based on FIX tag type at runtime. Current values are numeric strings "1" and "2". |
| 6 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 7 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 8 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 9 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ConditionalTagsConditions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConditionID | Hedge.ProviderConditionalTags | Logical Parent (no FK constraint) | ConditionID logically references ProviderConditionalTags.ConditionID; no FK enforced |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetConditionalTags | ConditionID | READER | JOINs this table with ProviderConditionalTags; returns full condition set per rule |
| History.ConditionalTagsConditions | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ConditionalTagsConditions (table)
  └── Hedge.ProviderConditionalTags [logical parent via ConditionID - no FK]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderConditionalTags | Table | Logical parent via ConditionID (no FK constraint) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetConditionalTags | Stored Procedure | READER - JOIN target; returns conditions paired with parent rule |
| History.ConditionalTagsConditions | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_ConditionalTagsConditions | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=100) |
| UQ_ConditionID_Tag_Operator | UNIQUE NONCLUSTERED | ConditionID ASC, Tag ASC, Operator ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_ConditionalTagsConditions | PRIMARY KEY | ID IDENTITY - surrogate key |
| UQ_ConditionID_Tag_Operator | UNIQUE | (ConditionID, Tag, Operator) - no duplicate predicate per condition |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ConditionalTagsConditions |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_Hedge_ConditionalTagsConditions_INSERT | INSERT | No-op self-UPDATE (joins on ID from INSERTED) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View conditions for all FXCM rules (as GetConditionalTags would return)

```sql
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

### 8.2 Find rules with multiple conditions (compound AND rules)

```sql
SELECT
    ConditionID,
    COUNT(*) AS ConditionCount
FROM Hedge.ConditionalTagsConditions WITH (NOLOCK)
GROUP BY ConditionID
HAVING COUNT(*) > 1
ORDER BY ConditionCount DESC
-- Currently: 0 rows (each ConditionID has exactly 1 condition)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (via parent) | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ConditionalTagsConditions | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ConditionalTagsConditions.sql*
