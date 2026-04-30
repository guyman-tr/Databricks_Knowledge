# History.OrdersEntryTblSwitch

> Partition switch staging table - structural clone of History.OrdersEntryTbl used for atomic partition management operations on the entry order archive.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrderID (INT, clustered PK) |
| **Partition** | No (but mirrors partitioned table structure; PK on PRIMARY, NC index on MAIN) |
| **Indexes** | 2 (CLUSTERED PK on OrderID, NC on CID) |

---

## 1. Business Meaning

History.OrdersEntryTblSwitch is a maintenance-only staging table that mirrors the exact column structure, constraints, and index layout of History.OrdersEntryTbl. It exists solely to support SQL Server partition management via ALTER TABLE ... SWITCH PARTITION statements, which require a staging table with an identical schema on matching filegroups.

This table exists to enable efficient bulk archival and purging of large historical batches from History.OrdersEntryTbl without per-row DELETE operations. When a partition of History.OrdersEntryTbl needs to be archived or purged, DBAs switch the partition into this staging table and then truncate it.

Between maintenance operations, this table does not exist in the live database (only defined in the SSDT project). It holds data transiently during maintenance windows only.

---

## 2. Business Logic

### 2.1 Partition Switch Pattern

**What**: SQL Server partition switching atomically moves an entire partition between two structurally identical tables.

**Columns/Parameters Involved**: All columns (OrderID through IsDiscounted)

**Rules**:
- This table must be structurally identical to History.OrdersEntryTbl - same columns, types, nullability, defaults, PK, and NC index.
- The NC index IX_HOrdersEntry_CIDSwitch must be on the same filegroup ([MAIN]) as History.OrdersEntryTbl's NC index to satisfy the partition switch requirement.
- A partition SWITCH is near-instantaneous (metadata-only) and does not move data row by row.
- DBAs run ALTER TABLE History.OrdersEntryTbl SWITCH PARTITION N TO History.OrdersEntryTblSwitch PARTITION 1, then TRUNCATE TABLE History.OrdersEntryTblSwitch.

**Diagram**:
```
DBA Maintenance Flow
--------------------
ALTER TABLE History.OrdersEntryTbl
  SWITCH PARTITION N
  TO History.OrdersEntryTblSwitch;
  -> Entire old partition atomically moved to staging table

TRUNCATE TABLE History.OrdersEntryTblSwitch;
  -> Old partition data discarded

History.OrdersEntryTbl now has one fewer partition (data purged)
```

---

## 3. Data Overview

Table is typically empty in the live database - exists in SSDT schema definition for maintenance use only. No live rows to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Primary key. Copy-trading entry order identifier. Matches Trade.OrdersEntryTbl.OrderID and History.OrdersEntryTbl.OrderID. Each entry order has exactly one row when this staging table is in use. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer identifier of the copier who placed the entry order. Mirrors History.OrdersEntryTbl.CID. Indexed (IX_HOrdersEntry_CIDSwitch) for efficient partition operations. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument the entry order was for. Mirrors History.OrdersEntryTbl.InstrumentID. Implicit FK to Dictionary/Trade instrument tables. |
| 4 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier applied to the entry order. Mirrors History.OrdersEntryTbl.Leverage. |
| 5 | Amount | money | YES | - | CODE-BACKED | Order notional amount in the account's base currency. Mirrors History.OrdersEntryTbl.Amount. |
| 6 | IsBuy | bit | YES | - | CODE-BACKED | Trade direction: 1=Buy (long), 0=Sell (short). Mirrors History.OrdersEntryTbl.IsBuy. |
| 7 | StopLosPercentage | money | YES | - | CODE-BACKED | Stop-loss level as a percentage of the position value. Mirrors History.OrdersEntryTbl.StopLosPercentage. |
| 8 | TakeProfitPercentage | money | YES | - | CODE-BACKED | Take-profit level as a percentage of the position value. Mirrors History.OrdersEntryTbl.TakeProfitPercentage. |
| 9 | OpenOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the entry order was originally placed in Trade.OrdersEntryTbl. Mirrors History.OrdersEntryTbl.OpenOccurred. |
| 10 | CloseActionType | int | NO | - | CODE-BACKED | Reason the entry order was closed/resolved. Mirrors History.OrdersEntryTbl.CloseActionType. Set by Trade.OrderEntryClose before archival. |
| 11 | ClosedOccurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the entry order was closed. Defaults to GETUTCDATE(). Mirrors History.OrdersEntryTbl.ClosedOccurred. |
| 12 | ParentPositionID | bigint | YES | - | CODE-BACKED | The position being copied. For copy-trading entry orders, this is the popular investor's open position. Mirrors History.OrdersEntryTbl.ParentPositionID. |
| 13 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship (mirror) that generated this entry order. Mirrors History.OrdersEntryTbl.MirrorID. |
| 14 | InitialMirrorAmountInCents | money | YES | - | CODE-BACKED | Original allocated amount for this copy relationship in cents at the time of the entry order. Mirrors History.OrdersEntryTbl.InitialMirrorAmountInCents. |
| 15 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Whether Trailing Stop Loss was enabled for this entry order. 0=disabled (default). Mirrors History.OrdersEntryTbl.IsTslEnabled. |
| 16 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size in instrument units (for unit-based instruments). Mirrors History.OrdersEntryTbl.AmountInUnitsDecimal. |
| 17 | OrderTypeID | int | YES | 13 | CODE-BACKED | Entry order type. Default 13. Mirrors History.OrdersEntryTbl.OrderTypeID. All observed rows in the main table have OrderTypeID=13. |
| 18 | OpenOpenOperationTypeID | int | YES | - | CODE-BACKED | Operation type that triggered the open-open entry order creation. Mirrors History.OrdersEntryTbl.OpenOpenOperationTypeID. |
| 19 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a discount was applied to this entry order. Mirrors History.OrdersEntryTbl.IsDiscounted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.OrdersEntryTbl | Structural clone | Schema must remain identical to enable partition SWITCH operations. |

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
| History.OrdersEntryTbl | Table | Partition switch source/target - this staging table must stay structurally identical |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OrdersEntryTblSwitch | CLUSTERED PK | OrderID ASC | - | - | Active |
| IX_HOrdersEntry_CIDSwitch | NONCLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_OrdersEntryTblSwitch | PRIMARY KEY | Unique per entry order - mirrors History.OrdersEntryTbl PK |
| DF_TradeOrdersEntry_ClosedOccurredSwitch | DEFAULT | ClosedOccurred defaults to GETUTCDATE() |
| DF_HistoryOrdersEntry_IsTslEnabledSwitch | DEFAULT | IsTslEnabled defaults to 0 (disabled) |
| DF_HistoryOrdersEntry_OrderTypeIDSwitch | DEFAULT | OrderTypeID defaults to 13 |

---

## 8. Sample Queries

### 8.1 Verify staging table is empty before a partition switch

```sql
SELECT COUNT(*) AS RowCount
FROM History.OrdersEntryTblSwitch WITH (NOLOCK);
```

### 8.2 Inspect rows currently in staging (should be 0 outside maintenance windows)

```sql
SELECT TOP 5 OrderID, CID, InstrumentID, OpenOccurred, ClosedOccurred, CloseActionType
FROM History.OrdersEntryTblSwitch WITH (NOLOCK)
ORDER BY ClosedOccurred DESC;
```

### 8.3 Verify staging table structure matches main table (column count)

```sql
SELECT COUNT(*) AS ColumnCount, 'Switch' AS TableName
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersEntryTblSwitch'
UNION ALL
SELECT COUNT(*), 'Main'
FROM INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
WHERE TABLE_SCHEMA = 'History' AND TABLE_NAME = 'OrdersEntryTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersEntryTblSwitch | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersEntryTblSwitch.sql*
