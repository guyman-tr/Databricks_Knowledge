# History.CompoundPropertyToRule

> SQL Server temporal history table for CEP.CompoundPropertyToRule - automatically captures superseded compound-property-to-rule assignments whenever a mapping is changed or deleted.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime ASC, SysStartTime ASC) - clustered index (temporal history pattern) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEnd/SysStart) |

---

## 1. Business Meaning

History.CompoundPropertyToRule is the SQL Server temporal versioning history table for CEP.CompoundPropertyToRule. It automatically captures superseded versions of the many-to-many mapping between CEP rules and compound properties whenever that mapping changes.

CEP.CompoundPropertyToRule maps each CEP rule to the compound properties that must evaluate to specific values (true/false via the Value bit column) for the rule to fire. History.CompoundPropertyToRule preserves the full audit trail of how these rule-to-property assignments have changed over time.

14,032 rows - tracking rule-to-property mapping change history.

---

## 2. Business Logic

### 2.1 Temporal Versioning

**What**: Automatically records superseded rows when CEP.CompoundPropertyToRule changes.

**Rules**:
- SQL Server SYSTEM_VERSIONING manages all writes (no manual inserts)
- Each modification to a rule-property mapping creates a history row
- Value (bit): 1 = the compound property must be TRUE for the rule to fire; 0 = must be FALSE

---

## 3. Data Overview

14,032 historical row versions. Tracks the change history of CEP rule-to-compound-property associations.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleID | int | NO | - | VERIFIED | ID of the CEP rule. Matches CEP.CompoundPropertyToRule.RuleID. Implicit FK to CEP.Rules. |
| 2 | CompoundPropertyID | int | NO | - | VERIFIED | ID of the compound property. Matches CEP.CompoundPropertyToRule.CompoundPropertyID. Implicit FK to CEP.CompoundProperties. |
| 3 | Value | bit | YES | - | VERIFIED | Expected boolean value of the compound property for rule evaluation: 1=must be true, 0=must be false. |
| 4 | ValidFrom | datetime | YES | - | VERIFIED | Application-level timestamp when this mapping version became valid. |
| 5 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login that made the change. |
| 6 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info() at change time. |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal row start: when this version became current. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal row end: when this version was superseded. Clustered index lead column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RuleID, CompoundPropertyID | CEP.CompoundPropertyToRule | Temporal (system) | History of the live mapping table. |

### 5.2 Referenced By (other objects point to this)

Temporal history tables are queried via `FOR SYSTEM_TIME` on the live table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CompoundPropertyToRule (temporal history table)
  <- CEP.CompoundPropertyToRule (SYSTEM_VERSIONING source)
```

### 6.1 Objects This Depends On

No direct dependencies (managed by SQL Server temporal).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_CompoundPropertyToRule | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION = PAGE.

---

## 8. Sample Queries

### 8.1 View all historical rule-property mappings for a rule
```sql
SELECT RuleID, CompoundPropertyID, Value, SysStartTime, SysEndTime
FROM CEP.CompoundPropertyToRule
FOR SYSTEM_TIME ALL
WHERE RuleID = 88
ORDER BY CompoundPropertyID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal auto-managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CompoundPropertyToRule | Type: Table | Source: etoro/etoro/History/Tables/History.CompoundPropertyToRule.sql*
