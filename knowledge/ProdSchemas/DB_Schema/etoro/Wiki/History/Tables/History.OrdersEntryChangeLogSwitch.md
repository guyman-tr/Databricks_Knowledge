# History.OrdersEntryChangeLogSwitch

> Partition switch staging table - structural clone of History.OrdersEntryChangeLog used for atomic partition management operations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, surrogate PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.OrdersEntryChangeLogSwitch is a maintenance-only staging table that mirrors the exact column structure and constraints of History.OrdersEntryChangeLog. It exists solely to support SQL Server partition management via ALTER TABLE ... SWITCH PARTITION statements, which require a staging table with an identical schema on the same filegroup.

This table exists because partition switching is the standard DBA technique for efficiently archiving or purging large batches of rows from a partitioned table without individual row deletes. Without a structurally identical staging table, SQL Server's partition SWITCH command cannot execute.

Data flows into this table during maintenance windows only: rows are switched out of History.OrdersEntryChangeLog into this table (or vice versa) as entire partitions. Between maintenance operations, the table is typically empty or does not exist in the live database.

---

## 2. Business Logic

### 2.1 Partition Switch Pattern

**What**: SQL Server partition switching atomically transfers an entire partition between two structurally identical tables.

**Columns/Parameters Involved**: All columns (ID, OrderID, OperationTypeID, ClientRequestGuid, Occurred)

**Rules**:
- This table must be structurally identical to History.OrdersEntryChangeLog - same columns, types, nullability, defaults, and PK.
- A partition SWITCH operation is near-instantaneous (metadata-only) and does not move data row by row.
- DBAs run ALTER TABLE History.OrdersEntryChangeLog SWITCH PARTITION N TO History.OrdersEntryChangeLogSwitch PARTITION 1 to move an old partition into this staging table, then truncate or drop as needed.
- The table is typically empty in normal operations; it only holds data transiently during a maintenance window.

**Diagram**:
```
Maintenance Operation Flow
--------------------------
ALTER TABLE History.OrdersEntryChangeLog
  SWITCH PARTITION N
  TO History.OrdersEntryChangeLogSwitch;
  -> Entire partition atomically moved to staging table

TRUNCATE TABLE History.OrdersEntryChangeLogSwitch;
  -> Staging data discarded

Main table now has one fewer partition (old data purged)
```

---

## 3. Data Overview

Table is typically empty in the live database - exists in SSDT schema definition for maintenance use only. No live rows to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Mirrors History.OrdersEntryChangeLog.ID exactly. NOT FOR REPLICATION prevents identity reseeding during replication. |
| 2 | OrderID | int | NO | - | CODE-BACKED | Entry order identifier. Mirrors History.OrdersEntryChangeLog.OrderID. References Trade.OrdersEntryTbl.OrderID (implicit). |
| 3 | OperationTypeID | int | NO | - | CODE-BACKED | Lifecycle event type. Mirrors History.OrdersEntryChangeLog.OperationTypeID. 1=Order opened, 2=Order closed. |
| 4 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client idempotency key. Mirrors History.OrdersEntryChangeLog.ClientRequestGuid. Nullable. |
| 5 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of the event. Mirrors History.OrdersEntryChangeLog.Occurred. Defaults to GETUTCDATE(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.OrdersEntryChangeLog | Structural clone | Schema must remain identical to enable partition SWITCH operations. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures reference this table by name; it is used only via DBA-executed DDL statements during maintenance.

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
| History.OrdersEntryChangeLog | Table | Partition switch source/target - this staging table must stay structurally identical |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryOrdersEntryChangeLogSwitch | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryOrdersEntryChangeLogSwitch | PRIMARY KEY | Unique identity per row - mirrors OrdersEntryChangeLog PK |
| DF_HistoryOrdersEntryChangeLog_OccurredSwitch | DEFAULT | Occurred defaults to GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Verify staging table is empty before a partition switch

```sql
SELECT COUNT(*) AS RowCount
FROM History.OrdersEntryChangeLogSwitch WITH (NOLOCK);
```

### 8.2 Compare schema alignment with main table (column count check)

```sql
SELECT COUNT(*) AS ColumnCount, 'Switch' AS TableName
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersEntryChangeLogSwitch'
UNION ALL
SELECT COUNT(*), 'Main'
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersEntryChangeLog';
```

### 8.3 Check any rows currently in staging (should be 0 outside maintenance windows)

```sql
SELECT TOP 5 ID, OrderID, OperationTypeID, Occurred
FROM History.OrdersEntryChangeLogSwitch WITH (NOLOCK)
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersEntryChangeLogSwitch | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersEntryChangeLogSwitch.sql*
