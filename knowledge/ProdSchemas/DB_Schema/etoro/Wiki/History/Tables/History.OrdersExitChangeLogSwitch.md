# History.OrdersExitChangeLogSwitch

> Partition switch staging table - structural clone of History.OrdersExitChangeLog used for atomic partition management operations on the exit order audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, surrogate PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.OrdersExitChangeLogSwitch is a maintenance-only staging table that mirrors the exact column structure and constraints of History.OrdersExitChangeLog. It exists solely to support SQL Server partition management via ALTER TABLE ... SWITCH PARTITION statements, which require a staging table with an identical schema on the same filegroup.

This table enables DBAs to efficiently archive or purge large batches of rows from History.OrdersExitChangeLog without per-row DELETE operations. Between maintenance operations, the table does not exist in the live database (only in the SSDT project) and holds data only transiently during maintenance windows.

---

## 2. Business Logic

### 2.1 Partition Switch Pattern

**What**: SQL Server partition switching atomically transfers an entire partition between two structurally identical tables.

**Columns/Parameters Involved**: All columns (ID through PreviousUnitsToDeduct)

**Rules**:
- This table must be structurally identical to History.OrdersExitChangeLog - same columns, types, nullability, defaults, and PK.
- A partition SWITCH is near-instantaneous (metadata-only) and does not move data row by row.
- After switching a partition, DBAs truncate this table to discard the old data.
- The table is empty in normal operations; it only holds data transiently during maintenance.

**Diagram**:
```
DBA Maintenance Flow
--------------------
ALTER TABLE History.OrdersExitChangeLog
  SWITCH PARTITION N
  TO History.OrdersExitChangeLogSwitch;
  -> Entire partition atomically moved to staging table

TRUNCATE TABLE History.OrdersExitChangeLogSwitch;
  -> Old partition data discarded
```

---

## 3. Data Overview

Table is typically empty in the live database - exists in SSDT schema definition for maintenance use only. No live rows to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Mirrors History.OrdersExitChangeLog.ID. NOT FOR REPLICATION prevents identity reseeding. |
| 2 | OrderID | int | NO | - | CODE-BACKED | Exit order identifier. Mirrors History.OrdersExitChangeLog.OrderID. |
| 3 | OperationTypeID | int | NO | - | CODE-BACKED | Lifecycle event type. Mirrors History.OrdersExitChangeLog.OperationTypeID. 1=open, 2=close, 3=edit. |
| 4 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client idempotency key. Mirrors History.OrdersExitChangeLog.ClientRequestGuid. Nullable. |
| 5 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | UTC event timestamp. Mirrors History.OrdersExitChangeLog.Occurred. Defaults to GETUTCDATE(). |
| 6 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Partial close unit quantity. Mirrors History.OrdersExitChangeLog.UnitsToDeduct. NULL for full closes. |
| 7 | PreviousUnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Previous unit quantity before an edit. Mirrors History.OrdersExitChangeLog.PreviousUnitsToDeduct. NULL for open/close events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.OrdersExitChangeLog | Structural clone | Schema must remain identical to enable partition SWITCH operations. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used only via DBA-executed DDL during maintenance.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersExitChangeLog | Table | Partition switch source/target - this staging table must stay structurally identical |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryOrdersExitChangeLogSwitch | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryOrdersExitChangeLogSwitch | PRIMARY KEY | Unique identity per row |
| DF_HistoryOrdersExitChangeLog_OccOrdersExitChangeLogSwitchurred | DEFAULT | Occurred defaults to GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Verify staging table is empty before a partition switch

```sql
SELECT COUNT(*) AS RowCount
FROM History.OrdersExitChangeLogSwitch WITH (NOLOCK);
```

### 8.2 Inspect any rows currently in staging (should be 0 outside maintenance windows)

```sql
SELECT TOP 5 ID, OrderID, OperationTypeID, UnitsToDeduct, Occurred
FROM History.OrdersExitChangeLogSwitch WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.3 Verify staging table column count matches main table

```sql
SELECT COUNT(*) AS ColumnCount, 'Switch' AS TableName
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersExitChangeLogSwitch'
UNION ALL
SELECT COUNT(*), 'Main'
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersExitChangeLog';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersExitChangeLogSwitch | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersExitChangeLogSwitch.sql*
