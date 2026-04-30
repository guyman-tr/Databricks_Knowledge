# Dictionary.ConditionOperators

> Temporal lookup table defining the 8 comparison operators used in CEP (Complex Event Processing) rule conditions — Equal, NotEqual, Greater Than, Smaller Than, Contains, and their variants.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OperatorID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ConditionOperators defines the comparison operators available when building conditions in the CEP (Complex Event Processing) rules engine. The CEP system evaluates real-time trading events against configurable rules — each rule has conditions that compare a property value against a threshold using one of these operators (e.g., "if Leverage >= 100" or "if InstrumentType = Crypto").

This is a system-versioned temporal table with history tracked in `History.ConditionOperators`, meaning all changes to operator definitions are preserved with timestamps. The table includes audit columns (`DbLoginName`, `AppLoginName`) computed at query time for tracking who accessed the data. An INSERT trigger (`TRG_T_ConditionOperators`) fires on new rows to populate the temporal history.

The `CEP.Conditions` table references these operators to define the comparison logic in each rule condition. Changes to this table are permissioned via the `PROD_CEP_UI_USER` role.

---

## 2. Business Logic

### 2.1 Operator Categories

**What**: Three categories of comparison operators for CEP rule conditions.

**Columns/Parameters Involved**: `OperatorID`, `Name`

**Rules**:
- **Equality operators (IDs 1-2)**: `Equal` and `NotEqual` — exact value matching for discrete/categorical properties like InstrumentType, CountryID, or OrderType.
- **Comparison operators (IDs 3-6)**: `Greater Than`, `Greater Equal Than`, `SmallerThan`, `Equal Smaller Than` — numeric range comparisons for continuous properties like Leverage, Amount, or TreeSize.
- **String operators (IDs 7-8)**: `Contains` and `Not Contains` — substring matching for text-based properties. Used when conditions need pattern matching rather than exact equality.

---

## 3. Data Overview

| OperatorID | Name | Meaning |
|---|---|---|
| 1 | Equal | Exact match — condition passes when the property value equals the specified threshold. Used for matching specific IDs, types, or status values (e.g., "InstrumentType = 5"). |
| 3 | Greater Than | Strict greater-than — condition passes when property value exceeds the threshold. Used for minimum-amount rules (e.g., "LotCount > 10"). |
| 6 | Equal Smaller Than | Less-than-or-equal — condition passes when property value is at or below the threshold. Used for maximum-limit rules (e.g., "Leverage <= 50"). |
| 7 | Contains | Substring match — condition passes when the property value contains the specified text. Used for flexible text matching in rules. |
| 8 | Not Contains | Negative substring match — condition passes when the property value does NOT contain the specified text. Used for exclusion-based rules. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperatorID | int | NO | - | VERIFIED | Primary key identifying the comparison operator. Values 1-8. Referenced by `CEP.Conditions` to define how a property value is compared against a threshold in rule evaluation. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Operator label (e.g., 'Equal', 'Greater Than', 'Contains'). Used in the CEP configuration UI to display available operators and in rule evaluation to determine comparison logic. |
| 3 | DbLoginName | computed | - | suser_name() | CODE-BACKED | Computed column — returns the current SQL Server login name at query time. Audit trail column showing which database account is reading the data. Not persisted. |
| 4 | AppLoginName | computed | - | CONVERT(varchar(500), context_info()) | CODE-BACKED | Computed column — returns the application-layer context info set via `SET CONTEXT_INFO`. Identifies which application service is accessing the data. Returns NULL when no context info is set. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioned temporal start timestamp. Records when this row version became current. Used by temporal queries (`FOR SYSTEM_TIME`) to retrieve historical operator definitions. |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System-versioned temporal end timestamp. Value '9999-12-31' indicates the row is currently active. When a row is updated or deleted, this gets set to the modification time and the row moves to `History.ConditionOperators`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.Conditions | OperatorID | Implicit FK | Each CEP rule condition specifies which comparison operator to use when evaluating the property against the threshold value |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.Conditions | Table | References operator ID for rule condition evaluation |
| History.ConditionOperators | Table | Temporal history table storing previous versions of operator rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeConditionOperators | CLUSTERED PK | OperatorID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ConditionOperators_SysStart | DEFAULT | SysStartTime defaults to getutcdate() — auto-stamps when row becomes current |
| DF_ConditionOperators_SysEnd | DEFAULT | SysEndTime defaults to '9999-12-31 23:59:59.9999999' — indicates row is currently active |
| SYSTEM_VERSIONING | Temporal | History tracked in History.ConditionOperators |
| TRG_T_ConditionOperators | Trigger (FOR INSERT) | Forces temporal history capture by performing a self-update on INSERT |

---

## 8. Sample Queries

### 8.1 List all current operators
```sql
SELECT  OperatorID,
        Name
FROM    Dictionary.ConditionOperators WITH (NOLOCK)
ORDER BY OperatorID;
```

### 8.2 Show CEP conditions with resolved operator names
```sql
SELECT  C.ConditionID,
        CO.Name AS OperatorName,
        C.*
FROM    CEP.Conditions C WITH (NOLOCK)
INNER JOIN Dictionary.ConditionOperators CO WITH (NOLOCK)
        ON CO.OperatorID = C.OperatorID
ORDER BY C.ConditionID;
```

### 8.3 View operator change history (temporal query)
```sql
SELECT  OperatorID,
        Name,
        SysStartTime,
        SysEndTime
FROM    Dictionary.ConditionOperators
FOR SYSTEM_TIME ALL
ORDER BY OperatorID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConditionOperators | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ConditionOperators.sql*
