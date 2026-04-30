# History.OrdersExitTblSwitch

> Partition switch staging table - structural clone of History.OrdersExitTbl used for atomic partition management operations on the copy-trading exit order archive.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrderID (INT, clustered PK) |
| **Partition** | No (mirrors partitioned table structure; PK on PRIMARY, NC index on HISTORY filegroup) |
| **Indexes** | 2 (CLUSTERED PK on OrderID, NC on CID+PositionID) |

---

## 1. Business Meaning

History.OrdersExitTblSwitch is a maintenance-only staging table that mirrors the exact column structure, constraints, and index layout of History.OrdersExitTbl. It exists solely to support SQL Server partition management via ALTER TABLE ... SWITCH PARTITION statements for the copy-trading exit order archive.

This table enables DBAs to efficiently bulk-archive or purge old partitions from History.OrdersExitTbl without per-row DELETE operations. The NC index is on the [HISTORY] filegroup to match History.OrdersExitTbl's NC index filegroup requirement for the SWITCH operation to succeed.

Between maintenance operations, this table does not exist in the live database (only in the SSDT project) and holds data only transiently during maintenance windows.

---

## 2. Business Logic

### 2.1 Partition Switch Pattern

**What**: SQL Server partition switching atomically transfers an entire partition between two structurally identical tables.

**Columns/Parameters Involved**: All columns (OrderID through CloseByUnitsID)

**Rules**:
- This table must be structurally identical to History.OrdersExitTbl - same columns, types, nullability, defaults, PK, and NC index on [HISTORY] filegroup.
- A partition SWITCH is near-instantaneous (metadata-only) and does not move data row by row.
- After switching, DBAs truncate this table to discard the old exit order archive data.
- The table is empty in normal operations.

**Diagram**:
```
DBA Maintenance Flow
--------------------
ALTER TABLE History.OrdersExitTbl
  SWITCH PARTITION N
  TO History.OrdersExitTblSwitch;
  -> Entire old partition atomically moved to staging

TRUNCATE TABLE History.OrdersExitTblSwitch;
  -> Old copy-trading exit order archive purged
```

---

## 3. Data Overview

Table is typically empty in the live database - exists in SSDT schema definition for maintenance use only. No live rows to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Primary key. Exit order identifier. Mirrors History.OrdersExitTbl.OrderID - matches Trade.OrdersExitTbl.OrderID before archival. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer (copier) identifier who placed the exit order. Mirrors History.OrdersExitTbl.CID. Part of the NC index key. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | The trading position being closed by this exit order. Mirrors History.OrdersExitTbl.PositionID. Part of the NC index key. |
| 4 | OpenOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the exit order was originally placed in Trade.OrdersExitTbl. Mirrors History.OrdersExitTbl.OpenOccurred. |
| 5 | CloseOccurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the exit order was resolved/filled. Defaults to GETUTCDATE(). Mirrors History.OrdersExitTbl.CloseOccurred. |
| 6 | CloseActionType | int | YES | - | CODE-BACKED | Reason the exit order was closed. Mirrors History.OrdersExitTbl.CloseActionType. |
| 7 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship (mirror) that triggered this exit order. Mirrors History.OrdersExitTbl.MirrorID. |
| 8 | MirrorCloseActionType | int | YES | - | CODE-BACKED | How the mirror relationship closed (e.g., deregistration, SL trigger). Mirrors History.OrdersExitTbl.MirrorCloseActionType. |
| 9 | OpenActionType | int | NO | 0 | CODE-BACKED | The action type that initiated this exit order. Default 0. Mirrors History.OrdersExitTbl.OpenActionType. |
| 10 | RedeemID | int | YES | - | CODE-BACKED | Redemption event identifier if the close was triggered by a copy-trading redemption. Mirrors History.OrdersExitTbl.RedeemID. |
| 11 | RedeemReasonID | int | YES | - | CODE-BACKED | Reason code for the redemption that triggered this exit order. Mirrors History.OrdersExitTbl.RedeemReasonID. |
| 12 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | For partial closes: number of instrument units closed by this exit order. NULL for full position closes. Mirrors History.OrdersExitTbl.UnitsToDeduct. |
| 13 | CloseByUnitsID | bigint | YES | - | CODE-BACKED | Identifier linking to a unit-based close event that caused this exit order. Mirrors History.OrdersExitTbl.CloseByUnitsID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.OrdersExitTbl | Structural clone | Schema must remain identical to enable partition SWITCH operations. |

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
| History.OrdersExitTbl | Table | Partition switch source/target - this staging table must stay structurally identical |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HOrdersExitSwitch | CLUSTERED PK | OrderID ASC | - | - | Active |
| His_NonClusteredIndex_CID_PIDSwitch | NONCLUSTERED | CID ASC, PositionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HOrdersExitSwitch | PRIMARY KEY | Unique per exit order |
| DF_TradeExitOrders_DateExecutedSwitch | DEFAULT | CloseOccurred defaults to GETUTCDATE() |
| DF_HistoryOrderExist_OpenActionTypeSwitch | DEFAULT | OpenActionType defaults to 0 |

---

## 8. Sample Queries

### 8.1 Verify staging table is empty before a partition switch

```sql
SELECT COUNT(*) AS RowCount
FROM History.OrdersExitTblSwitch WITH (NOLOCK);
```

### 8.2 Inspect any rows currently in staging (should be 0 outside maintenance windows)

```sql
SELECT TOP 5 OrderID, CID, PositionID, OpenOccurred, CloseOccurred, CloseActionType
FROM History.OrdersExitTblSwitch WITH (NOLOCK)
ORDER BY CloseOccurred DESC;
```

### 8.3 Verify staging table column count matches main table

```sql
SELECT COUNT(*) AS ColumnCount, 'Switch' AS TableName
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersExitTblSwitch'
UNION ALL
SELECT COUNT(*), 'Main'
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersExitTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersExitTblSwitch | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersExitTblSwitch.sql*
