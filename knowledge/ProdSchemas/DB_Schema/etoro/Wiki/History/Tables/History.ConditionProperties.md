# History.ConditionProperties

> Temporal HISTORY_TABLE for Dictionary.ConditionProperties - stores versioned row snapshots of condition property definitions used in the CEP rules engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for Dictionary.ConditionProperties |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.ConditionProperties is the SQL Server temporal HISTORY_TABLE automatically managed by Dictionary.ConditionProperties. It stores all prior row versions when property definitions change in Dictionary.ConditionProperties.

Dictionary.ConditionProperties defines the measurable properties that CEP (Complex Event Processing) conditions can evaluate - properties like "instrument type", "position size", "customer tier", etc. These are the "left-hand side" of a condition expression: `<Property> <Operator> <Value>`. When a property definition changes (name, behavior), the old version is written here.

2 rows - Dictionary.ConditionProperties has had 2 version changes since temporal versioning was enabled. This is a very stable reference table.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: When any row in Dictionary.ConditionProperties is modified or deleted, SQL Server automatically inserts the prior row version here.

**Rules**:
- Never written to directly
- Clustered index on (SysEndTime ASC, SysStartTime ASC) for efficient `FOR SYSTEM_TIME AS OF` queries
- 2 total rows = 2 property definition changes in history

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 2 |
| **Status** | Minimal history - Dictionary.ConditionProperties is nearly static |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PropertyID | int | NO | - | VERIFIED | ID of the condition property. Matches Dictionary.ConditionProperties.PropertyID. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable property name (e.g., "InstrumentType", "PositionSize"). The property the condition evaluates. |
| 3 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login name at the time of the change. Audit column. |
| 4 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application-layer login from context_info() at time of change. Audit column. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | When this row version became current in Dictionary.ConditionProperties. |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | When this row version was superseded. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Dictionary.ConditionProperties | HISTORY_TABLE (temporal) | Auto-managed history table for Dictionary.ConditionProperties. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_ConditionProperties | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

## 8. Sample Queries

```sql
-- Full history of property definition changes
SELECT PropertyID, Name, SysStartTime, SysEndTime
FROM Dictionary.ConditionProperties
FOR SYSTEM_TIME ALL
ORDER BY PropertyID, SysStartTime;
```

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.ConditionProperties | Type: Table | Source: etoro/etoro/History/Tables/History.ConditionProperties.sql*
