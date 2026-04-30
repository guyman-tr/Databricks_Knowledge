# History.OrdersExitChangeLog

> Lightweight audit log tracking the lifecycle (open, close, and edit events) of exit orders as they move through the trading system, including unit deduction amounts for partial position closes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, surrogate PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.OrdersExitChangeLog records each state-change event for exit orders - orders that are placed to close an existing trading position (either fully or partially). Each exit order generates at minimum two rows: one when the close order is submitted (OperationTypeID=1) and one when it is resolved (OperationTypeID=2). If the order is edited (e.g., the partial close unit count changes) before resolution, an additional edit row (OperationTypeID=3) is recorded. Together, these rows form the complete lifecycle audit trail for a single exit order.

This table is the exit-order counterpart to History.OrdersEntryChangeLog (which tracks entry/open orders). The two extra columns - UnitsToDeduct and PreviousUnitsToDeduct - exist specifically to support partial position closes, recording the before/after unit quantities when a customer closes part of a unit-based position.

Data flows into this table exclusively via the async processing framework. When an exit order is placed (Trade.OrderExitOpen), edited (Trade.OrderExitEdit), or closed (Trade.OrderExitClose), an async task is enqueued. The Trade.AsyncOrdersChangeLog dispatcher calls Trade.OrdersExitChangeLogAdd, which performs the INSERT. For close events (OperationTypeID=2), the dispatcher also archives the exit order record from Trade.OrdersExitTbl into History.OrdersExitTbl.

---

## 2. Business Logic

### 2.1 Exit Order Lifecycle - Multi-Row Pattern

**What**: Each exit order generates two or more rows in this table, one per lifecycle event.

**Columns/Parameters Involved**: `OrderID`, `OperationTypeID`, `Occurred`

**Rules**:
- OperationTypeID=1: Exit order opened/submitted (order placed to close a position). Default value.
- OperationTypeID=2: Exit order closed/resolved (position closure completed). Trade.AsyncOrdersChangeLog also archives the Trade.OrdersExitTbl row to History.OrdersExitTbl at this point.
- OperationTypeID=3: Exit order edited (UnitsToDeduct changed - partial close quantity modified). Only 6 occurrences in the dataset.
- Most exit orders have exactly two rows (open + close). Edit events are rare.

**Diagram**:
```
Exit Order Lifecycle
--------------------
Customer initiates position close
  -> INSERT row: OrderID=X, OperationTypeID=1, Occurred=T1
  -> Order live in Trade.OrdersExitTbl

[Optional] Customer modifies partial close quantity
  -> INSERT row: OrderID=X, OperationTypeID=3, UnitsToDeduct=new, PreviousUnitsToDeduct=old

Order filled / position closed
  -> INSERT row: OrderID=X, OperationTypeID=2, Occurred=T2
  -> Trade.OrdersExitTbl row archived to History.OrdersExitTbl
```

### 2.2 Partial Close Unit Tracking

**What**: For unit-based position closes, the exact number of units being closed is recorded alongside the prior quantity.

**Columns/Parameters Involved**: `UnitsToDeduct`, `PreviousUnitsToDeduct`

**Rules**:
- UnitsToDeduct: the number of instrument units to close in this order. NULL for full closes (where the entire position is closed by amount, not units).
- PreviousUnitsToDeduct: the prior UnitsToDeduct value before an edit (OperationTypeID=3). NULL for the initial open/close events.
- These columns are only populated for unit-based instruments where the customer closes a specific quantity rather than the whole position.

---

## 3. Data Overview

| ID | OrderID | OperationTypeID | UnitsToDeduct | Occurred | Meaning |
|----|---------|-----------------|---------------|----------|---------|
| 8415 | 4285 | 1 | NULL | 2024-05-17 23:11:23 | Exit order 4285 opened - customer requested to close their position |
| 8419 | 4285 | 2 | NULL | 2024-05-19 08:41:36 | Exit order 4285 closed ~33 hours later; Trade.OrdersExitTbl row archived to History |
| 8418 | 4286 | 2 | NULL | 2024-05-19 08:31:20 | Exit order 4286 resolved (open row would be around ID 8416) |
| 8416 | 4283 | 2 | NULL | 2024-05-18 19:01:13 | Exit order 4283 closed - full position close, no unit deduction |
| 8417 | 4284 | 2 | NULL | 2024-05-19 08:28:10 | Exit order 4284 resolved |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Auto-incremented; no business meaning. NOT FOR REPLICATION prevents identity reseeding on replication subscribers. |
| 2 | OrderID | int | NO | - | CODE-BACKED | Exit order identifier being tracked. References Trade.OrdersExitTbl.OrderID (implicit FK - no DDL constraint). Each OrderID appears at least twice: once at open (OperationTypeID=1) and once at close (OperationTypeID=2), plus any edit events. |
| 3 | OperationTypeID | int | NO | - | CODE-BACKED | The lifecycle event type: 1=Exit order opened/submitted (position close requested); 2=Exit order closed/filled (position closure completed, order archived); 3=Exit order edited (partial close unit count changed). Default value is 1. Implicit reference to Dictionary.OperationType. |
| 4 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client-supplied idempotency key passed through from the original API request. Correlates the log entry to the originating client call. NULL in most rows - not all callers supply a GUID. |
| 5 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the async log INSERT executed. Defaults to GETUTCDATE() at write time. Because writes are asynchronous, this captures when the async dispatcher processed the event, not when the original order event occurred in the trading engine. |
| 6 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | For unit-based partial closes: the number of instrument units being closed in this exit order. NULL for full position closes (where the whole position is closed by amount, not units). Set by Trade.OrdersExitChangeLogAdd from the @UnitsToDeduct parameter. |
| 7 | PreviousUnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | For edit events (OperationTypeID=3): the previous UnitsToDeduct value before the edit was applied. Enables audit of how a partial close quantity changed. NULL for open and close events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrdersExitTbl | Implicit | References an exit order that is live until OperationTypeID=2 is written, then archived to History.OrdersExitTbl. |
| OperationTypeID | Dictionary.OperationType | Implicit | Loosely maps to Dictionary.OperationType.ID; only values 1, 2, 3 used in this context. No DDL FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.OrdersExitChangeLogSwitch | - | Partition switch | Switch-partition staging table with identical structure. |

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
| History.OrdersExitChangeLogSwitch | Table | Partition switch staging table - must stay structurally identical |
| Trade.OrdersExitChangeLogAdd | Stored Procedure | WRITER - inserts rows into this table for each lifecycle event |
| Trade.AsyncOrdersChangeLog | Stored Procedure | DISPATCHER - calls Trade.OrdersExitChangeLogAdd asynchronously; triggers History.OrdersExitTbl archival on close |
| Trade.OrderExitOpen | Stored Procedure | INITIATOR - posts async open event (OperationTypeID=1) to the queue |
| Trade.OrderExitEdit | Stored Procedure | INITIATOR - posts async edit event (OperationTypeID=3) with updated UnitsToDeduct |
| Trade.OrderExitClose | Stored Procedure | INITIATOR - posts async close event (OperationTypeID=2) to the queue |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryOrdersExitChangeLog | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryOrdersExitChangeLog | PRIMARY KEY | Unique identity per log row |
| DF_HistoryOrdersExitChangeLog_Occurred | DEFAULT | Occurred defaults to GETUTCDATE() - records async execution time |

---

## 8. Sample Queries

### 8.1 Get full lifecycle for a specific exit order

```sql
SELECT ID, OrderID, OperationTypeID, UnitsToDeduct, PreviousUnitsToDeduct, Occurred
FROM History.OrdersExitChangeLog WITH (NOLOCK)
WHERE OrderID = 4285
ORDER BY Occurred;
```

### 8.2 Find exit orders that were edited (partial close quantity changed)

```sql
SELECT OrderID, UnitsToDeduct AS NewUnits, PreviousUnitsToDeduct AS OldUnits, Occurred AS EditedAt
FROM History.OrdersExitChangeLog WITH (NOLOCK)
WHERE OperationTypeID = 3
ORDER BY Occurred DESC;
```

### 8.3 Summarize activity by operation type with dictionary labels

```sql
SELECT dt.OperationTypeName, COUNT(*) AS EventCount, MIN(cl.Occurred) AS FirstSeen, MAX(cl.Occurred) AS LastSeen
FROM History.OrdersExitChangeLog cl WITH (NOLOCK)
JOIN Dictionary.OperationType dt WITH (NOLOCK) ON dt.ID = cl.OperationTypeID
GROUP BY dt.OperationTypeName
ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersExitChangeLog | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersExitChangeLog.sql*
