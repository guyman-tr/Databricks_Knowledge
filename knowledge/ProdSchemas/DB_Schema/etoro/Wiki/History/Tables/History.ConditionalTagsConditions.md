# History.ConditionalTagsConditions

> SQL Server temporal history table for Hedge.ConditionalTagsConditions - automatically captures superseded tag-based condition definitions whenever hedge rule conditions are changed or deleted.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime ASC, SysStartTime ASC) - clustered index (temporal history pattern) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEnd/SysStart) |

---

## 1. Business Meaning

History.ConditionalTagsConditions is the SQL Server temporal versioning history table for Hedge.ConditionalTagsConditions. It automatically preserves superseded versions of tag-based conditions used in the hedge rules engine.

Hedge.ConditionalTagsConditions defines the conditions component of conditional hedge rules. Each condition specifies a Tag (an attribute or classification of a customer/position), an Operator (comparison operator), and a Value (the threshold or value to compare against). Conditions are grouped by ConditionID (uniqueidentifier) and evaluated together to determine whether a hedge rule fires.

Only 4 rows in this environment - reflecting a very stable or lightly used conditional tag configuration.

---

## 2. Business Logic

### 2.1 Temporal Versioning

**What**: Automatically records superseded condition definitions.

**Rules**:
- SQL Server SYSTEM_VERSIONING manages all writes
- Hedge.ConditionalTagsConditions has SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[ConditionalTagsConditions])
- Each row in Hedge.ConditionalTagsConditions represents one condition predicate: `Tag Operator Value` (e.g., Tag=5, Operator=">=", Value="1000")
- UNIQUE constraint on (ConditionID, Tag, Operator) in the live table ensures no duplicate condition-tag-operator combinations per condition group
- Live table has INSERT trigger Tr_Hedge_ConditionalTagsConditions_INSERT that does a no-op UPDATE (forces SysStartTime refresh for temporal versioning)

---

## 3. Data Overview

4 historical row versions in this environment. Very low volume - reflects stable condition configuration.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Row identifier from Hedge.ConditionalTagsConditions (IDENTITY in live table). |
| 2 | ConditionID | uniqueidentifier | NO | - | VERIFIED | Groups multiple condition predicates into one logical condition. All conditions with the same ConditionID are evaluated together (AND logic). |
| 3 | Tag | int | NO | - | VERIFIED | The customer/position attribute being evaluated. Integer code for a tag type in the hedge rules engine. |
| 4 | Operator | varchar(50) | NO | - | VERIFIED | Comparison operator: ">=", "<=", "=", ">", "<", "!=", etc. Applied between Tag value and Value. |
| 5 | Value | varchar(256) | NO | - | VERIFIED | The threshold or comparison value for the condition. Stored as string to support various data types (numeric, enum, etc.). |
| 6 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login at change time. |
| 7 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info() at change time. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal row start: when this condition version became current. |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal row end: when this condition was superseded. Clustered index lead column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID, ConditionID | Hedge.ConditionalTagsConditions | Temporal (system) | History of the live condition table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ConditionalTagsConditions (temporal history table)
  <- Hedge.ConditionalTagsConditions (SYSTEM_VERSIONING source)
```

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ConditionalTagsConditions | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION = PAGE. On [DICTIONARY] filegroup.

---

## 8. Sample Queries

### 8.1 View all historical versions of a condition group
```sql
SELECT ID, ConditionID, Tag, Operator, Value, SysStartTime, SysEndTime
FROM Hedge.ConditionalTagsConditions
FOR SYSTEM_TIME ALL
WHERE ConditionID = '00000000-0000-0000-0000-000000000000'
ORDER BY ID, SysStartTime;
```

### 8.2 View condition state at a specific point in time
```sql
SELECT ID, ConditionID, Tag, Operator, Value
FROM Hedge.ConditionalTagsConditions
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00'
ORDER BY ConditionID, ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal auto-managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ConditionalTagsConditions | Type: Table | Source: etoro/etoro/History/Tables/History.ConditionalTagsConditions.sql*
