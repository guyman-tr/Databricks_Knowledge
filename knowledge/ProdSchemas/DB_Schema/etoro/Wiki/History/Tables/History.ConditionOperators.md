# History.ConditionOperators

> Temporal HISTORY_TABLE for Dictionary.ConditionOperators - stores all versioned row snapshots for condition operator lookup values used by the CEP rules engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for Dictionary.ConditionOperators |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.ConditionOperators is the SQL Server temporal HISTORY_TABLE automatically managed by Dictionary.ConditionOperators. It stores all prior row versions when operator lookup values are inserted, updated, or deleted in Dictionary.ConditionOperators.

Dictionary.ConditionOperators defines the set of comparison operators available in the CEP (Complex Event Processing) rules engine - operators like "equals", "greater than", "less than", "contains", etc. used when building CEP conditions. When any operator definition changes, the old version is automatically written here by SQL Server's temporal versioning mechanism.

0 rows - Dictionary.ConditionOperators has never had a row version expire, meaning its data has been static since temporal versioning was enabled.

This table should NOT be queried directly for current state. Use `SELECT ... FROM Dictionary.ConditionOperators` for current data. Use `FOR SYSTEM_TIME AS OF` or `FOR SYSTEM_TIME ALL` on Dictionary.ConditionOperators for historical queries.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: When any row in Dictionary.ConditionOperators is modified or deleted, SQL Server automatically inserts the prior row version here, with SysStartTime and SysEndTime reflecting the validity window.

**Rules**:
- Never written to directly - all rows come from SQL Server's temporal engine
- No PK constraint (temporal history tables never have PKs on the versioned columns)
- Clustered index on (SysEndTime ASC, SysStartTime ASC) - standard temporal history table pattern for efficient `FOR SYSTEM_TIME AS OF` queries
- DbLoginName, AppLoginName: audit columns copied from the base table at time of version creation

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 0 |
| **Status** | No history yet - Dictionary.ConditionOperators has not changed since temporal versioning was enabled |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperatorID | int | NO | - | VERIFIED | ID of the condition operator. Matches Dictionary.ConditionOperators.OperatorID. Part of the versioned snapshot. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the operator (e.g., "Equals", "GreaterThan", "Contains"). Part of the versioned snapshot. |
| 3 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login name that was active when the row version was created in the base table. Audit column. |
| 4 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application-layer login name from context_info() at the time of the change. Audit column. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version became the current row in Dictionary.ConditionOperators. Set by SQL Server temporal engine. |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version was superseded (when the next version was created). Set by SQL Server temporal engine. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Dictionary.ConditionOperators | HISTORY_TABLE (temporal) | This is the auto-managed history table for Dictionary.ConditionOperators. Rows here are past versions of rows there. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ConditionOperators (temporal HISTORY_TABLE)
  -> Dictionary.ConditionOperators (base table - auto-manages this)
```

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_ConditionOperators | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

Standard temporal history table index. Ordered by SysEndTime first for efficient point-in-time queries (`FOR SYSTEM_TIME AS OF`).

---

## 8. Sample Queries

### 8.1 Point-in-time query for operator names (use base table)
```sql
SELECT OperatorID, Name
FROM Dictionary.ConditionOperators
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY OperatorID;
```

### 8.2 Full history of all operator changes
```sql
SELECT OperatorID, Name, SysStartTime, SysEndTime
FROM Dictionary.ConditionOperators
FOR SYSTEM_TIME ALL
ORDER BY OperatorID, SysStartTime;
```

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Base table SYSTEM_VERSIONING config verified via SSDT*
*Object: History.ConditionOperators | Type: Table | Source: etoro/etoro/History/Tables/History.ConditionOperators.sql*
