# Trade.GetOrderForOpenIdsForCloseMirror

> Returns OrderIDs of waiting-for-market open orders for a specific mirror and customer - used during mirror close to find which open orders must be cancelled before the copy relationship can be terminated.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId INT + @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForOpenIdsForCloseMirror` returns only the `OrderID` list of open orders in `Trade.OrderForOpen` that are in `StatusID=11` (WaitingForMarket) for a specific CID+MirrorID combination. This is a simplified version of `Trade.GetOpenOrdersForCloseMirror` - it returns only WaitingForMarket orders (not delayed orders), and returns only the OrderID without the OrderType discriminator.

**WHY:** During mirror close, all pending open orders for that mirror must be cancelled. This SP provides a direct list of WaitingForMarket open order IDs to cancel. The caller uses the returned IDs to cancel each order before completing the mirror close.

**HOW:** Simple `SELECT OrderID FROM Trade.OrderForOpen WHERE CID=@cid AND MirrorID=@mirrorId AND StatusID=11`. No NOLOCK hint is specified (uses default isolation level of the caller's session).

---

## 2. Business Logic

### 2.1 Comparison with GetOpenOrdersForCloseMirror

**What:** This SP and `Trade.GetOpenOrdersForCloseMirror` both serve mirror-close workflows but differ in scope and output:

| Feature | GetOrderForOpenIdsForCloseMirror | GetOpenOrdersForCloseMirror |
|---------|----------------------------------|----------------------------|
| Tables covered | OrderForOpen only | OrderForOpen + DelayedOrderForOpen |
| StatusID filter | 11 (WaitingForMarket) | 11 for OFO + 1 for DOFO |
| Return columns | OrderID only | OrderID + OrderType discriminator |
| NOLOCK | No | Yes (on DOFO) |

**Rules:**
- `StatusID = 11` = WaitingForMarket (order is in the queue waiting for market open or price condition)
- Returns only OrderID - caller does not need to know the order type from this SP

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | int | NO | - | CODE-BACKED | Mirror relationship ID. Combined with @cid to scope to one specific copy relationship. |
| 2 | @cid | int | NO | - | CODE-BACKED | Copier's Customer ID. The customer whose WaitingForMarket open orders for this mirror are returned. |

**Return Columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | bigint | NO | CODE-BACKED | The open order ID. From Trade.OrderForOpen where StatusID=11 (WaitingForMarket). Caller cancels each returned OrderID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid + @mirrorId + StatusID=11 | Trade.OrderForOpen | Direct query | SELECT OrderID WHERE WaitingForMarket |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Mirror-close workflow | N/A | CALLER | Enumerate WaitingForMarket orders to cancel during mirror close |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForOpenIdsForCloseMirror (procedure)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | SELECT OrderID WHERE CID=@cid AND MirrorID=@mirrorId AND StatusID=11 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Mirror-close service | External | Gets list of open orders to cancel when closing a mirror |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** Unlike `GetOpenOrdersForCloseMirror`, this SP does NOT include `DelayedOrderForOpen` - it only handles WaitingForMarket orders from OrderForOpen. Callers that need to handle delayed orders too should use `GetOpenOrdersForCloseMirror`.

**Note:** No `NOLOCK` hint on the SELECT. The behavior depends on the session's isolation level.

---

## 8. Sample Queries

### 8.1 Get WaitingForMarket open orders for a mirror
```sql
EXEC Trade.GetOrderForOpenIdsForCloseMirror @mirrorId = 5678901, @cid = 12345678
```

### 8.2 Manual equivalent
```sql
SELECT OrderID
FROM   Trade.OrderForOpen
WHERE  CID = 12345678
AND    MirrorID = 5678901
AND    StatusID = 11
```

### 8.3 Compare with GetOpenOrdersForCloseMirror (which covers more)
```sql
-- GetOpenOrdersForCloseMirror equivalent (both WFM + delayed):
SELECT OrderID, 0 AS OrderType FROM Trade.OrderForOpen
WHERE  CID = 12345678 AND MirrorID = 5678901 AND StatusID = 11
UNION ALL
SELECT OrderID, 1 AS OrderType FROM Trade.DelayedOrderForOpen WITH (NOLOCK)
WHERE  CID = 12345678 AND MirrorID = 5678901 AND StatusID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForOpenIdsForCloseMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForOpenIdsForCloseMirror.sql*
