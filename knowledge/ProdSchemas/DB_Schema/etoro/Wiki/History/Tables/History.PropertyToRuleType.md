# History.PropertyToRuleType

> Temporal history backing table for CEP.PropertyToRuleType - storing all past versions of the mapping between condition properties and rule types in the Complex Event Processing (CEP) rules engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.PropertyToRuleType` is the **temporal history backing table** for `CEP.PropertyToRuleType`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `CEP.PropertyToRuleType` defines which condition properties are applicable to each rule type in the Complex Event Processing (CEP) system. CEP is the rules engine that evaluates customer behavior and market conditions to trigger automated actions (alerts, restrictions, etc.). Each `RuleTypeID` corresponds to a category of rules, and `PropertyID` identifies a measurable condition property (e.g., position size, trade frequency, account balance). The mapping table answers: "which properties can be evaluated as conditions for rules of this type?"

With 101 history rows (52 for RuleTypeID=1, 49 for RuleTypeID=2), only two rule types have ever been configured. Changes to this mapping are infrequent and operationally significant - they alter which condition properties the CEP engine can evaluate for each rule category. Editors observed in live data include `TRAD\bonniegr` and `TRAD\rivkaya`, indicating this is maintained by the risk/rules team directly via SQL access rather than through an automated API.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to CEP.PropertyToRuleType automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC timestamp when this property-to-rule-type mapping became active in CEP.PropertyToRuleType
- `SysEndTime` = UTC timestamp when this mapping was superseded
- Rows here are EXPIRED versions only - current mappings live in CEP.PropertyToRuleType
- Both timestamps set by SQL Server temporal engine

**Diagram**:
```
CEP.PropertyToRuleType (live - current property/rule-type mappings)
    SYSTEM_VERSIONING = ON
    HISTORY_TABLE = History.PropertyToRuleType
    |
    v
History.PropertyToRuleType (this table - past mapping configurations)
```

### 2.2 Two-Dimensional CEP Rule Configuration

**What**: The mapping table controls which condition properties can be used when building rules of each type.

**Columns/Parameters Involved**: `RuleTypeID`, `PropertyID`

**Rules**:
- `RuleTypeID` FK to `Dictionary.RuleType(RuleTypeID)` - 2 rule types currently active (IDs 1 and 2)
- `PropertyID` FK to `Dictionary.ConditionProperties(PropertyID)` - the measurable conditions
- History shows ~52 properties mapped to RuleTypeID=1, ~49 to RuleTypeID=2 (counts from history rows)
- The composite PK (RuleTypeID, PropertyID) on the live table prevents duplicate mappings
- Adding/removing a property from a rule type generates a history row here

---

## 3. Data Overview

101 rows. 52 associated with RuleTypeID=1, 49 with RuleTypeID=2. Infrequent changes by risk/rules team.

| RuleTypeID | PropertyID | DbLoginName | Context |
|---|---|---|---|
| 1 | (various) | TRAD\bonniegr or TRAD\rivkaya | Property assignments for rule type 1 |
| 2 | (various) | TRAD\bonniegr or TRAD\rivkaya | Property assignments for rule type 2 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleTypeID | int | NO | - | CODE-BACKED | Identifies the rule type category. Part of the composite PK in the live CEP.PropertyToRuleType table. FK to Dictionary.RuleType(RuleTypeID). Only 2 distinct values in history: 1 and 2, representing the two CEP rule categories currently in use. |
| 2 | PropertyID | int | NO | - | CODE-BACKED | Identifies the condition property applicable to this rule type. Part of the composite PK in the live table. FK to Dictionary.ConditionProperties(PropertyID). Represents a measurable attribute (e.g., trade frequency, account balance) that can be used as a condition when building rules of the paired RuleTypeID. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login name captured at write time via suser_name() on the live table. Observed values: TRAD\bonniegr and TRAD\rivkaya - risk/rules team members who maintain the CEP property configuration directly via SQL. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() set before writing. May contain null-byte padding from varchar(500) context_info() storage. Indicates whether changes were made via application or direct SQL access. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this property-to-rule-type mapping became active in CEP.PropertyToRuleType. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this mapping was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column for efficient temporal queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RuleTypeID | Dictionary.RuleType | Implicit (FK enforced on live table) | The CEP rule type category this property applies to |
| PropertyID | Dictionary.ConditionProperties | Implicit (FK enforced on live table) | The condition property applicable to this rule type |
| (all columns) | CEP.PropertyToRuleType | Temporal | This is the history backing table for the live CEP table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when CEP.PropertyToRuleType is modified |
| CEP.Tr_T_PropertyToRuleType_INSERT | Trigger | Related | No-op touch trigger on live table that forces temporal row versioning on INSERT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PropertyToRuleType (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.PropertyToRuleType | Table | Live table - SQL Server moves expired rows here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PropertyToRuleType | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Clustered on (SysEndTime, SysStartTime) - standard temporal history pattern optimizing FOR SYSTEM_TIME AS OF queries.*

### 7.2 Constraints

None (no FK constraints on history table - constraints enforced on live CEP table).

---

## 8. Sample Queries

### 8.1 Point-in-time property-to-rule-type mappings (via live table)

```sql
SELECT RuleTypeID, PropertyID, DbLoginName, SysStartTime, SysEndTime
FROM CEP.PropertyToRuleType
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY RuleTypeID, PropertyID
```

### 8.2 Full change history for a specific rule type

```sql
SELECT RuleTypeID, PropertyID, DbLoginName, AppLoginName, SysStartTime, SysEndTime,
    DATEDIFF(DAY, SysStartTime, SysEndTime) AS DaysActive
FROM History.PropertyToRuleType WITH (NOLOCK)
WHERE RuleTypeID = @RuleTypeID
ORDER BY SysStartTime ASC
```

### 8.3 Recent property mapping changes

```sql
SELECT RuleTypeID, PropertyID, DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM History.PropertyToRuleType WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PropertyToRuleType | Type: Table | Source: etoro/etoro/History/Tables/History.PropertyToRuleType.sql*
