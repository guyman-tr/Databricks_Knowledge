# History.OrdersEntryChangeLog

> Lightweight audit log tracking the lifecycle (open and close events) of entry orders as they move through the trading system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, surrogate PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.OrdersEntryChangeLog records each state-change event for entry orders - orders placed to open a trading position that are pending execution by a liquidity provider. Each entry order generates exactly two rows in this table: one when the order is submitted (OperationTypeID=1) and one when it is closed or cancelled (OperationTypeID=2). Together, these two rows form the complete lifecycle record for a single entry order.

This table exists to give the trading infrastructure an immutable audit trail of entry order events. Without it, there is no historical record of when an order was activated versus when it was resolved - critical for debugging order-processing failures, auditing trade flows, and reconciling positions.

Data flows into this table exclusively via the async processing framework. When an entry order opens or closes, a calling procedure (e.g., Trade.OrderEntryClose) posts an async task to Trade.InsertAsyncRecord. The Trade.AsyncOrdersChangeLog dispatcher picks it up and calls Trade.OrdersEntryChangeLogAdd, which performs the INSERT. For close events (OperationTypeID=2), the dispatcher also moves the order record from Trade.OrdersEntryTbl into History.OrdersEntryTbl.

---

## 2. Business Logic

### 2.1 Entry Order Lifecycle - Two-Row Pattern

**What**: Each entry order generates exactly two rows in this table, one per lifecycle stage.

**Columns/Parameters Involved**: `OrderID`, `OperationTypeID`, `Occurred`

**Rules**:
- OperationTypeID=1 is written when the entry order is submitted/activated (default value in Trade.OrdersEntryChangeLogAdd).
- OperationTypeID=2 is written when the entry order is closed/resolved. At this point, Trade.AsyncOrdersChangeLog also migrates the order from Trade.OrdersEntryTbl into History.OrdersEntryTbl.
- The pair of rows for the same OrderID brackets the time the order was live in the system.

**Diagram**:
```
Entry Order Lifecycle
---------------------
Order submitted
  -> INSERT row: OrderID=X, OperationTypeID=1, Occurred=T1
  -> Order live in Trade.OrdersEntryTbl

Order closed/cancelled
  -> INSERT row: OrderID=X, OperationTypeID=2, Occurred=T2
  -> Trade.OrdersEntryTbl row migrated to History.OrdersEntryTbl
```

### 2.2 Async Write Pattern

**What**: Writes to this table are always asynchronous, decoupled from the main trading transaction.

**Columns/Parameters Involved**: `ClientRequestGuid`, `Occurred`

**Rules**:
- The calling procedure (e.g., Trade.OrderEntryClose) posts an XML async record to the queue rather than calling the INSERT directly.
- Trade.AsyncOrdersChangeLog dispatches the actual INSERT by calling Trade.OrdersEntryChangeLogAdd.
- Occurred defaults to GETUTCDATE() at INSERT time, capturing when the async task executed (not when the order event was initiated).
- ClientRequestGuid is passed through from the original client request for idempotency / deduplication but is nullable and often NULL.

---

## 3. Data Overview

| ID | OrderID | OperationTypeID | Occurred |  Meaning |
|----|---------|-----------------|----------|---------|
| 7525 | 3802 | 1 | 2024-05-17 00:01:22 | Entry order 3802 submitted and activated for execution |
| 7526 | 3802 | 2 | 2024-05-17 01:00:05 | Entry order 3802 closed ~1 hour later; Trade.OrdersEntryTbl row archived to History |
| 7523 | 3801 | 1 | 2024-05-16 23:01:24 | Entry order 3801 opened - prior order in the same session |
| 7524 | 3801 | 2 | 2024-05-17 00:01:15 | Entry order 3801 closed shortly after the next open |
| 7522 | 3800 | 2 | 2024-05-16 01:00:06 | Entry order 3800 closed (the open row would be ID 7521) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Auto-incremented by SQL Server; has no business meaning beyond row identity. NOT FOR REPLICATION flag prevents identity reseeding on replication subscribers. |
| 2 | OrderID | int | NO | - | CODE-BACKED | Identifies the entry order this log record belongs to. References Trade.OrdersEntryTbl.OrderID (implicit FK - no DDL constraint). Each OrderID appears exactly twice: once at open (OperationTypeID=1) and once at close (OperationTypeID=2). |
| 3 | OperationTypeID | int | NO | - | CODE-BACKED | The lifecycle event being recorded: 1=Order opened/submitted (entry order activated in Trade.OrdersEntryTbl); 2=Order closed/resolved (entry order archived to History.OrdersEntryTbl). Only values 1 and 2 appear in the data. Implicit reference to Dictionary.OperationType (ID column), though only the simplified open/close semantics are used here. |
| 4 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client-supplied idempotency key passed through from the original API request. Used to correlate the log entry back to the originating client call. NULL in most rows (not all callers supply a GUID). |
| 5 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of when the async log INSERT executed. Defaults to GETUTCDATE() at write time. Note: because writes are asynchronous, this timestamp reflects when the async dispatcher processed the event, not when the original order event occurred in the trading engine. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrdersEntryTbl | Implicit | Each log row references an entry order. The order is live in Trade.OrdersEntryTbl until OperationTypeID=2, after which it is archived to History.OrdersEntryTbl. |
| OperationTypeID | Dictionary.OperationType | Implicit | Loosely maps to Dictionary.OperationType.ID, but only values 1 and 2 are used in practice (open/close). No DDL FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.OrdersEntryChangeLogSwitch | - | Partition switch | Switch-partition staging table with identical structure, used for partition management operations on this table. |

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
| History.OrdersEntryChangeLogSwitch | Table | Partition switch staging table - same schema, used for partition swap operations |
| Trade.OrdersEntryChangeLogAdd | Stored Procedure | WRITER - inserts rows into this table for each lifecycle event |
| Trade.AsyncOrdersChangeLog | Stored Procedure | DISPATCHER - calls Trade.OrdersEntryChangeLogAdd asynchronously; also triggers History.OrdersEntryTbl archival on close |
| Trade.OrderEntryClose | Stored Procedure | INITIATOR - posts the async close event (OperationTypeID=2) to the queue |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryOrdersEntryChangeLog | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryOrdersEntryChangeLog | PRIMARY KEY | Unique identity per log row |
| DF_HistoryOrdersEntryChangeLog_Occurred | DEFAULT | Occurred defaults to GETUTCDATE() - records async execution time |

---

## 8. Sample Queries

### 8.1 Get full lifecycle for a specific entry order

```sql
SELECT ID, OrderID, OperationTypeID, ClientRequestGuid, Occurred
FROM History.OrdersEntryChangeLog WITH (NOLOCK)
WHERE OrderID = 3802
ORDER BY Occurred;
```

### 8.2 Find entry orders that have an open record but no close record (orphans)

```sql
SELECT open_log.OrderID, open_log.Occurred AS OpenedAt
FROM History.OrdersEntryChangeLog open_log WITH (NOLOCK)
WHERE open_log.OperationTypeID = 1
  AND NOT EXISTS (
    SELECT 1 FROM History.OrdersEntryChangeLog close_log WITH (NOLOCK)
    WHERE close_log.OrderID = open_log.OrderID
      AND close_log.OperationTypeID = 2
  )
ORDER BY open_log.Occurred DESC;
```

### 8.3 Lookup operation type names for recent log entries

```sql
SELECT cl.ID, cl.OrderID, dt.OperationTypeName, cl.ClientRequestGuid, cl.Occurred
FROM History.OrdersEntryChangeLog cl WITH (NOLOCK)
JOIN Dictionary.OperationType dt WITH (NOLOCK) ON dt.ID = cl.OperationTypeID
ORDER BY cl.Occurred DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersEntryChangeLog | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersEntryChangeLog.sql*
