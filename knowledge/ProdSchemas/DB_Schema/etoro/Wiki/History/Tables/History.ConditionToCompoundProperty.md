# History.ConditionToCompoundProperty

> Temporal HISTORY_TABLE for CEP.ConditionToCompoundProperty - stores 9,513 versioned snapshots of the many-to-many mapping between CEP conditions and compound properties.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for CEP.ConditionToCompoundProperty |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.ConditionToCompoundProperty is the SQL Server temporal HISTORY_TABLE for CEP.ConditionToCompoundProperty. It stores all prior row versions as the mapping between CEP conditions and compound properties evolves.

CEP.ConditionToCompoundProperty is a junction table: it defines which individual conditions (from CEP.Conditions) are grouped together into a compound property (a logical AND/OR group). A compound property aggregates multiple conditions to define complex trigger criteria for a CEP rule.

9,513 rows - closely matching History.Conditions (9,558), which is expected since condition-to-group mappings change whenever conditions are added, removed, or reassigned to different compound properties.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: Every change to a row in CEP.ConditionToCompoundProperty writes the prior version here.

**Rules**:
- Never written to directly
- 9,513 rows mirrors the activity level of CEP.Conditions changes
- ValidFrom = application-level effective date for the mapping assignment

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 9,513 |
| **Status** | Actively versioned - tracks compound property membership changes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CompoundPropertyID | int | NO | - | VERIFIED | ID of the compound property (logical group). Matches CEP.ConditionToCompoundProperty.CompoundPropertyID. FK to CEP.CompoundProperties. |
| 2 | ConditionID | int | NO | - | VERIFIED | ID of the individual condition being assigned to the compound property. FK to CEP.Conditions. |
| 3 | ValidFrom | datetime | YES | - | CODE-BACKED | Application-level effective date for this mapping. Business logic field. |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login at time of change. Audit column. |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info(). Audit column. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | When this version became current in CEP.ConditionToCompoundProperty. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | CEP.ConditionToCompoundProperty | HISTORY_TABLE (temporal) | Auto-managed history for the compound property junction table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_ConditionToCompoundProperty | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

## 8. Sample Queries

```sql
-- History of which conditions were in a compound property
SELECT CompoundPropertyID, ConditionID, ValidFrom, SysStartTime, SysEndTime
FROM CEP.ConditionToCompoundProperty
FOR SYSTEM_TIME ALL
WHERE CompoundPropertyID = 100
ORDER BY SysStartTime;
```

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.ConditionToCompoundProperty | Type: Table | Source: etoro/etoro/History/Tables/History.ConditionToCompoundProperty.sql*
