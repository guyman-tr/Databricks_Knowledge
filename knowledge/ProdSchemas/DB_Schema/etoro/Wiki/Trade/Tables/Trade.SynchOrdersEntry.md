# Trade.SynchOrdersEntry

> Synchronization queue for entry orders (pending buy/sell orders) relating to copy-trade mirrors. Captures order details for replication across database instances.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK CLUSTERED on ID) |

---

## 1. Business Meaning

Trade.SynchOrdersEntry is a queue-style table that holds entry order events for synchronization across replicated database instances. When a new entry order (pending buy or sell) is placed that relates to a copy-trade mirror, this table captures the OrderID, InstrumentID, CID (customer), MirrorID (copy-trade relationship), and CloseActionType so the order can be replicated or processed consistently in other database instances (e.g., demo, read replicas, or regional copies).

This table exists because copy-trade entry orders must be synchronized across multiple database instances to maintain consistency. When a leader places a pending order and copiers are set to mirror it, the order details need to propagate so all replicas know about the order. Without this queue, demo or replica instances would have stale or missing entry order data.

Data flows: Rows are inserted when entry orders are created for copy-trade-related scenarios. Sync consumers read and process entries, then typically delete or mark them. The table is typically empty when no pending sync events exist. Live data is empty (queue-like, consumed).

---

## 2. Business Logic

### 2.1 Entry Order Sync Lifecycle

**What**: Entry orders for copy-trade mirrors are queued here for cross-instance synchronization.

**Columns/Parameters Involved**: `OrderID`, `InstrumentID`, `CID`, `MirrorID`, `CloseActionType`

**Rules**:
- IDENTITY(1,1) NOT FOR REPLICATION: ID is not auto-generated on subscriber during replication
- OrderID: the entry order that was placed
- InstrumentID: instrument being traded
- CID: customer (leader or copier context)
- MirrorID: copy-trade mirror relationship; links to Trade.Mirror
- CloseActionType: indicates how the position will eventually close (market close, stop loss, take profit, etc.) - used by sync consumers to apply correct close logic

**Diagram**:
```
[Entry order placed for copy-trade mirror] -> INSERT SynchOrdersEntry
        |
        v
  [Sync consumer reads] -> Replicate order to other instance -> DELETE
        |
        v
  Table empty or minimal rows
```

### 2.2 CloseActionType Interpretation

**What**: CloseActionType drives how the synced position will be closed.

**Columns/Parameters Involved**: `CloseActionType`

**Rules**:
- Integer code for close type: market close, stop loss, take profit, or other
- Sync consumers use this to set up correct SL/TP or close-at-market behavior on the destination instance
- Value map would come from dictionary or application enum (not defined in DDL)

---

## 3. Data Overview

| ID | OrderID | InstrumentID | CID | MirrorID | CloseActionType | Meaning |
|---|---|---|---|---|---|---|
| (Table is EMPTY in environment) | - | - | - | - | - | No live rows. Queue-like: consumed after sync. When populated: row would represent an entry order (e.g., pending buy on EUR/USD) for a copy-trade mirror; CloseActionType would indicate stop loss or take profit setup for the eventual position. |

**Selection criteria:**
- Table is empty. Representative rows would show OrderID, InstrumentID, CID, MirrorID, and various CloseActionType values (market, SL, TP).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier for each sync queue entry. NOT FOR REPLICATION: ID is not auto-generated on subscriber during replication. Used for FIFO ordering. |
| 2 | OrderID | int | NO | - | CODE-BACKED | The entry order ID. References Trade.Orders or equivalent. The pending buy/sell order that triggered this sync event. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument.InstrumentID. The instrument for the entry order. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID. Identifies the customer (leader or copier context) associated with this entry order. |
| 5 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror ID. References Trade.Mirror.MirrorID. Indicates this entry order relates to a copy-trade relationship. |
| 6 | CloseActionType | int | NO | - | CODE-BACKED | How the position will eventually close: market close, stop loss, take profit, etc. Sync consumers use this to apply correct close logic when replicating the order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.Orders | Implicit | The entry order. |
| InstrumentID | Trade.Instrument | Implicit | Instrument for the order. |
| MirrorID | Trade.Mirror | Implicit | Copy-trade mirror relationship. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Procedures not analyzed in this phase) | - | Writer/Reader | Insert on entry order create; read/delete by sync consumers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynchOrdersEntry (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Not analyzed in this phase) | Procedure | Inserts on entry order; sync consumers read/delete. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (ID) | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | ID is the primary key. IDENTITY NOT FOR REPLICATION. |

---

## 8. Sample Queries

### 8.1 Read pending sync entries (FIFO)

```sql
SELECT TOP 100 ID, OrderID, InstrumentID, CID, MirrorID, CloseActionType
FROM Trade.SynchOrdersEntry WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find sync entries for a specific mirror

```sql
SELECT ID, OrderID, InstrumentID, CID, MirrorID, CloseActionType
FROM Trade.SynchOrdersEntry WITH (NOLOCK)
WHERE MirrorID = 12345
ORDER BY ID;
```

### 8.3 Join to Instrument and Mirror for context

```sql
SELECT soe.ID, soe.OrderID, soe.InstrumentID, soe.CID, soe.MirrorID, soe.CloseActionType,
       m.LeaderID, m.FollowerID
FROM Trade.SynchOrdersEntry soe WITH (NOLOCK)
JOIN Trade.Mirror m WITH (NOLOCK) ON m.MirrorID = soe.MirrorID
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = soe.InstrumentID
ORDER BY soe.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynchOrdersEntry | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SynchOrdersEntry.sql*
