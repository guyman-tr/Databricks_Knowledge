# Trade.GetOpenOrdersForCloseMirror

> Returns all pending open orders (waiting-for-market and delayed) for a given mirror and copier, used during mirror-close to identify which open orders must be cancelled before the copy relationship can be terminated.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId INT + @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenOrdersForCloseMirror` finds all open orders that belong to a specific CID+MirrorID combination and are still in a pending state - either waiting for market execution (`OrderForOpen.StatusID = 11`) or scheduled as a delayed open (`DelayedOrderForOpen.StatusID = 1`). Each returned row has an `OrderID` and `OrderType` (0=immediate open order, 1=delayed order).

**WHY:** When a user stops copying a leader (mirror close), any pending open orders that were queued on behalf of that mirror relationship must be cancelled or handled before the mirror can be safely closed. If left unhandled, orphaned open orders would continue to execute even after the copy relationship ends. This SP is the discovery step: find what needs to be cleaned up.

**HOW:** Called from application code as part of the mirror-close workflow. The two result sets are combined with `UNION ALL` - first all waiting-for-market orders from `Trade.OrderForOpen`, then all active delayed orders from `Trade.DelayedOrderForOpen`. The caller uses the returned list to cancel or process each pending order before completing the mirror close.

---

## 2. Business Logic

### 2.1 Two Types of Pending Open Orders

**What:** Pending opens for a mirror can exist in two tables: `OrderForOpen` (immediate market orders waiting for execution) and `DelayedOrderForOpen` (limit/scheduled orders not yet triggered). Both must be handled on mirror close.

**Columns/Parameters Involved:** `OrderType`, `StatusID`, `MirrorID`, `CID`

**Rules:**
- `OrderForOpen.StatusID = 11` = Waiting-For-Market (order placed, waiting for market open or price) -> returned as `OrderType = 0`
- `DelayedOrderForOpen.StatusID = 1` = Active delayed order (a scheduled/limit open not yet triggered) -> returned as `OrderType = 1`
- Only orders matching both `@cid` and `@mirrorId` are returned - scoped to exactly this copy relationship
- `UNION ALL` (not UNION) because the same OrderID cannot appear in both tables - no deduplication needed

**Diagram:**
```
Mirror Close Flow:
  Step 1: GetOpenOrdersForCloseMirror(@mirrorId, @cid)
    -> Returns OrderID=X, OrderType=0 (OrderForOpen waiting-for-market)
    -> Returns OrderID=Y, OrderType=1 (DelayedOrderForOpen active)
  Step 2: Cancel/handle each returned OrderID
  Step 3: Close mirror safely
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | int | NO | - | CODE-BACKED | Input: the mirror relationship ID. Combined with @cid to scope the query to one specific copy relationship. References Trade.Mirror.MirrorID. |
| 2 | @cid | int | NO | - | CODE-BACKED | Input: the copier's Customer ID. The customer whose pending open orders for this mirror are to be retrieved. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | OrderID | bigint | NO | - | CODE-BACKED | The pending open order ID. From Trade.OrderForOpen (OrderType=0) or Trade.DelayedOrderForOpen (OrderType=1). The caller uses this to cancel or process the order. |
| R2 | OrderType | int | NO | - | CODE-BACKED | Discriminator for the source table: 0=Trade.OrderForOpen (immediate market order, StatusID=11 waiting-for-market); 1=Trade.DelayedOrderForOpen (delayed/limit order, StatusID=1 active). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @mirrorId + @cid | Trade.OrderForOpen | Direct query | SELECT orders WHERE StatusID=11 (waiting-for-market) |
| @mirrorId + @cid | Trade.DelayedOrderForOpen | Direct query | SELECT orders WHERE StatusID=1 (active delayed) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application mirror-close service | N/A | CALLER | Called during mirror-close flow to discover pending orders to cancel |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenOrdersForCloseMirror (procedure)
├── Trade.OrderForOpen (table)
└── Trade.DelayedOrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | SELECT OrderID WHERE CID=@cid AND MirrorID=@mirrorId AND StatusID=11 |
| Trade.DelayedOrderForOpen | Table | SELECT OrderID WHERE CID=@cid AND MirrorID=@mirrorId AND StatusID=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application mirror-close workflow | External | Enumerates pending orders before closing the mirror |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** `Trade.OrderForOpen` does not use `NOLOCK` (first SELECT), while `Trade.DelayedOrderForOpen` uses `WITH (NOLOCK)`. This asymmetry may reflect that waiting-for-market orders are actively processed and need consistent reads, while delayed orders are less volatile.

---

## 8. Sample Queries

### 8.1 Find all pending open orders for a mirror before closing
```sql
EXEC Trade.GetOpenOrdersForCloseMirror @mirrorId = 5678901, @cid = 12345678
```

### 8.2 Check pending open orders breakdown by type
```sql
SELECT 'OrderForOpen' AS Source, OrderID, MirrorID, CID, StatusID
FROM   Trade.OrderForOpen WITH (NOLOCK)
WHERE  MirrorID = 5678901 AND CID = 12345678 AND StatusID = 11
UNION ALL
SELECT 'DelayedOrderForOpen', OrderID, MirrorID, CID, StatusID
FROM   Trade.DelayedOrderForOpen WITH (NOLOCK)
WHERE  MirrorID = 5678901 AND CID = 12345678 AND StatusID = 1
```

### 8.3 Count pending orders across mirrors for a customer
```sql
SELECT m.MirrorID, m.ParentCID AS LeaderCID,
       SUM(CASE WHEN ofo.OrderID IS NOT NULL THEN 1 ELSE 0 END) AS WaitingForMarketOrders,
       SUM(CASE WHEN dofo.OrderID IS NOT NULL THEN 1 ELSE 0 END) AS DelayedOrders
FROM   Trade.Mirror m WITH (NOLOCK)
       LEFT JOIN Trade.OrderForOpen ofo WITH (NOLOCK)
           ON ofo.MirrorID = m.MirrorID AND ofo.CID = m.CID AND ofo.StatusID = 11
       LEFT JOIN Trade.DelayedOrderForOpen dofo WITH (NOLOCK)
           ON dofo.MirrorID = m.MirrorID AND dofo.CID = m.CID AND dofo.StatusID = 1
WHERE  m.CID = 12345678 AND m.MirrorStatusID = 0
GROUP  BY m.MirrorID, m.ParentCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenOrdersForCloseMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenOrdersForCloseMirror.sql*
