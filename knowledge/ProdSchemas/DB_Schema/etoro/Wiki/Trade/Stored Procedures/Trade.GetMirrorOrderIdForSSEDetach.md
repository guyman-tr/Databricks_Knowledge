# Trade.GetMirrorOrderIdForSSEDetach

> Returns all pending order IDs for a customer within a specific mirror across three order tables (entry orders, delayed orders, pending open orders), used during the SSE mirror detach flow to identify which orders must be cancelled or processed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId + @cid - scopes to one user's orders in one mirror |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorOrderIdForSSEDetach` aggregates all open/pending order IDs belonging to a customer (`@cid`) within a specific mirror (`@mirrorId`). It queries three distinct order tables and returns a unified list with a `Status` discriminator indicating which table each order came from: entry orders (Status=1), delayed open orders (Status=2), and pending open orders (Status=3).

This procedure exists to support the SSE (Server-Sent Events) mirror detach flow. When a copier detaches from a mirror, any pending orders that were created as part of that mirror relationship must be identified so they can be cancelled or otherwise handled before the detachment is finalized. By scanning all three order tables in a single call, the caller gets a complete picture of what needs to be cleaned up.

Data flows: Called during mirror detachment processing. The caller receives the list of `(OrderID, Status)` pairs and invokes the appropriate cancellation or clean-up logic for each order type before completing the detach.

---

## 2. Business Logic

### 2.1 Three Order Table Union

**What**: Pending orders for a mirror user are spread across three tables; this procedure collects them all.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`, `Status` discriminator

**Rules**:
- `Trade.OrdersEntry` (Status=1): Active entry orders belonging to this mirror + customer. No status filter - all rows match.
- `Trade.DelayedOrderForOpen` (Status=2): Delayed open orders with `StatusID = 1` (active/pending). Only active delayed orders need processing at detach.
- `Trade.OrderForOpen` (Status=3): Pending open orders with `StatusID = 11`. Value 11 is the pending/in-flight state in the OrderForOpen lifecycle.

**Diagram**:
```
Trade.OrdersEntry       WHERE MirrorID=@mirrorId AND CID=@cid
                            -> OrderID, Status=1

         UNION ALL

Trade.DelayedOrderForOpen WHERE CID=@cid AND MirrorID=@mirrorId AND StatusID=1
                            -> OrderID, Status=2

         UNION ALL

Trade.OrderForOpen        WHERE CID=@cid AND MirrorID=@mirrorId AND StatusID=11
                            -> OrderID, Status=3

         = Complete pending order list for detach processing
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | INT | NO | - | CODE-BACKED | The mirror identifier to scope the query. Filters all three order tables to orders associated with this mirror. |
| 2 | @cid | INT | NO | - | CODE-BACKED | The customer ID (CID). Together with @mirrorId, uniquely scopes the order search to a specific user's orders within the mirror. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | OrderID | All three order tables | The order identifier. Type and meaning varies by Status value - may be an entry order, delayed order, or open order ID. |
| 2 | Status | Hardcoded discriminator | Order table origin: 1=Trade.OrdersEntry (entry order), 2=Trade.DelayedOrderForOpen (delayed open order), 3=Trade.OrderForOpen (pending open order). Used by caller to route cancellation logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @mirrorId + @cid | Trade.OrdersEntry | Lookup | Reads entry orders for the mirror-customer combination. |
| @mirrorId + @cid | Trade.DelayedOrderForOpen | Lookup | Reads active (StatusID=1) delayed open orders for the mirror-customer combination. |
| @mirrorId + @cid | Trade.OrderForOpen | Lookup | Reads pending (StatusID=11) open orders for the mirror-customer combination. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorOrderIdForSSEDetach (procedure)
├── Trade.OrdersEntry (table)
├── Trade.DelayedOrderForOpen (table)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | Table | SELECT OrderID WHERE MirrorID + CID match - all entry orders for the mirror user |
| Trade.DelayedOrderForOpen | Table | SELECT OrderID WHERE MirrorID + CID + StatusID=1 - active delayed open orders |
| Trade.OrderForOpen | Table | SELECT OrderID WHERE MirrorID + CID + StatusID=11 - pending open orders |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all pending orders for a customer in a mirror

```sql
EXEC Trade.GetMirrorOrderIdForSSEDetach @mirrorId = 12345, @cid = 67890;
```

### 8.2 Count pending orders by type for a mirror detach

```sql
SELECT
    Status,
    CASE Status
        WHEN 1 THEN 'OrdersEntry'
        WHEN 2 THEN 'DelayedOrderForOpen'
        WHEN 3 THEN 'OrderForOpen'
    END AS OrderType,
    COUNT(*) AS OrderCount
FROM (
    SELECT OrderID, 1 AS Status FROM Trade.OrdersEntry WITH (NOLOCK)
    WHERE MirrorID = 12345 AND CID = 67890
    UNION ALL
    SELECT OrderID, 2 AS Status FROM Trade.DelayedOrderForOpen WITH (NOLOCK)
    WHERE CID = 67890 AND MirrorID = 12345 AND StatusID = 1
    UNION ALL
    SELECT OFO.OrderID, 3 AS Status FROM Trade.OrderForOpen AS OFO WITH (NOLOCK)
    WHERE OFO.CID = 67890 AND OFO.MirrorID = 12345 AND OFO.StatusID = 11
) AS AllOrders
GROUP BY Status;
```

### 8.3 Verify entry orders for a mirror customer directly

```sql
SELECT oe.OrderID, oe.MirrorID, oe.CID
FROM Trade.OrdersEntry oe WITH (NOLOCK)
WHERE oe.MirrorID = 12345
  AND oe.CID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorOrderIdForSSEDetach | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorOrderIdForSSEDetach.sql*
