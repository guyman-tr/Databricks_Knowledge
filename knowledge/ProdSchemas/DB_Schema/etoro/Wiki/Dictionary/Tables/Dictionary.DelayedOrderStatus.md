# Dictionary.DelayedOrderStatus

> Memory-optimized lookup table defining the 3 lifecycle states of limit/stop orders (delayed execution orders).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (Memory-Optimized) |
| **Key Identifier** | StatusID (TINYINT, NONCLUSTERED HASH PK) |
| **Partition** | N/A (in-memory) |
| **Indexes** | 1 active (HASH PK, bucket count 8) |

---

## 1. Business Meaning

Dictionary.DelayedOrderStatus defines the three possible states of a pending order (limit order, stop order, or entry order). When a user places an order to buy/sell at a specific price rather than the current market price, that order is "delayed" until the market reaches the target.

This table is critical to the order management system. Every pending order must be in exactly one of three states: waiting for price (PLACED), successfully executed (FILLED), or canceled/expired (REMOVED). The simplicity of this three-state model reflects the clean lifecycle of pending orders.

Notably, this is a **memory-optimized table** (In-Memory OLTP) — indicating it is queried at extremely high frequency by the real-time order matching engine. The HASH index with BUCKET_COUNT=8 is optimized for point lookups by StatusID.

---

## 2. Business Logic

### 2.1 Pending Order Lifecycle

**What**: Simple three-state lifecycle for delayed orders.

**Columns/Parameters Involved**: `StatusID`, `StatusName`

**Rules**:
- PLACED (1) → FILLED (2): Market price reaches the order's trigger level, order executes into a position
- PLACED (1) → REMOVED (3): User cancels, order expires, or system removes (e.g., market close for non-GTC orders)
- FILLED and REMOVED are terminal states — no further transitions

**Diagram**:
```
[Order Created] ──► [1: PLACED] ──┬──► [2: FILLED] ──► (new Position created)
                                  │
                                  └──► [3: REMOVED] ──► (order discarded)
```

---

## 3. Data Overview

| StatusID | StatusName | Meaning |
|---|---|---|
| 1 | PLACED | Order is active in the order book, waiting for the market price to reach the trigger level. The order is monitored in real-time by the matching engine. Can be modified or canceled by the user. |
| 2 | FILLED | Market price reached the trigger level and the order was successfully executed. A new position has been created in Trade.PositionTbl. Terminal state — the order's job is done. |
| 3 | REMOVED | Order was removed without execution. Causes: user cancellation, expiration (non-GTC orders), system cleanup, or instrument delisting. No position was created. Terminal state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | tinyint | NO | - | CODE-BACKED | Primary key (HASH index) identifying the delayed order state. 1=PLACED (active, waiting for price), 2=FILLED (executed into a position), 3=REMOVED (canceled/expired without execution). See [Delayed Order Status](_glossary.md#delayed-order-status). (Dictionary.DelayedOrderStatus) |
| 2 | StatusName | varchar(50) | NO | - | CODE-BACKED | Uppercase status code. Used in order management UI, API responses, and monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade delayed order tables | StatusID | Implicit Lookup | Every pending order has a status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade delayed order tables | Table | Stores StatusID per pending order |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__DelayedOrderStatus_StatusID | NONCLUSTERED HASH PK | StatusID (BUCKET_COUNT=8) | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK__DelayedOrderStatus_StatusID | PRIMARY KEY (HASH) | Unique status identifier. Memory-optimized hash index for O(1) point lookups. |

**Special**: `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA` — This table resides in memory for low-latency access by the real-time order matching engine. Data is persisted to disk for durability (survives restarts).

---

## 8. Sample Queries

### 8.1 List all delayed order statuses
```sql
SELECT StatusID, StatusName
FROM [Dictionary].[DelayedOrderStatus] WITH (NOLOCK) ORDER BY StatusID;
```

### 8.2 Count pending orders by status
```sql
SELECT dos.StatusName, COUNT(*) AS OrderCount
FROM [Trade].[DelayedOrderForOpen] d WITH (NOLOCK)
JOIN [Dictionary].[DelayedOrderStatus] dos WITH (NOLOCK) ON d.StatusID = dos.StatusID
GROUP BY dos.StatusName ORDER BY OrderCount DESC;
```

### 8.3 Find all active (PLACED) pending orders
```sql
SELECT d.OrderID, d.CID, d.CurrencyID, d.Rate, d.Amount
FROM [Trade].[DelayedOrderForOpen] d WITH (NOLOCK)
WHERE d.StatusID = 1 ORDER BY d.InsertDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.DelayedOrderStatus.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DelayedOrderStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DelayedOrderStatus.sql*
