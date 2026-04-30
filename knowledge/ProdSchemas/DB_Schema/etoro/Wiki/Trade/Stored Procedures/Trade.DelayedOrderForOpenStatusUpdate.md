# Trade.DelayedOrderForOpenStatusUpdate

> Natively compiled procedure that transitions a pending open order's status in the memory-optimized DelayedOrderForOpen queue, returning the updated row.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure (Natively Compiled) |
| **Key Identifier** | @OrderID (identifies the delayed open order to update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DelayedOrderForOpenStatusUpdate is a natively compiled stored procedure that advances a delayed open order from PLACED status to a terminal status (FILLED or REMOVED). It operates on the memory-optimized Trade.DelayedOrderForOpen table, which queues limit/stop open orders awaiting the right market price.

This procedure is essential for the delayed order lifecycle. When a limit/stop open order reaches its trigger price and the order matching engine executes it, Trade.OrderForOpenCreate calls this procedure with StatusID=2 (FILLED). The application layer also calls it via the DelayedOrderRepository when orders are cancelled or otherwise need status changes. Without this procedure, delayed open orders would remain stuck in PLACED status after execution.

The procedure only affects rows where StatusID=1 (PLACED), acting as an optimistic concurrency guard - if another process already moved the order past PLACED, the UPDATE is a no-op. After updating, it returns the full updated row via OUTPUT INSERTED.*, allowing the caller to confirm the transition and read the current state (including order sizing, copy-trading context, and instrument details).

---

## 2. Business Logic

### 2.1 Status Transition Guard

**What**: Only PLACED orders can be transitioned.

**Columns/Parameters Involved**: `@OrderID`, `@StatusID`, `StatusID`

**Rules**:
- UPDATE only fires WHERE StatusID = 1 (PLACED) - prevents double-processing or re-processing of already-filled/removed orders
- If the row does not exist or is already in a terminal state, zero rows are affected

### 2.2 Delayed Open Order Status Values

**What**: Three-state lifecycle for delayed open orders, aligned with Dictionary.DelayedOrderStatus.

**Columns/Parameters Involved**: `@StatusID`

**Rules**:
- 1 = PLACED - order is pending, waiting for market price trigger
- 2 = FILLED - order executed successfully, set by Trade.OrderForOpenCreate
- 3 = REMOVED - order cancelled or expired

**Diagram**:
```
PLACED (1) --[price triggered]--> FILLED (2)
PLACED (1) --[cancelled/expired]--> REMOVED (3)
```

### 2.3 Native Compilation & ATOMIC Transaction

**What**: The procedure uses natively compiled execution with ATOMIC semantics.

**Rules**:
- SCHEMABINDING ensures the table structure cannot change while the proc exists
- ATOMIC with SNAPSHOT isolation provides optimistic concurrency - no locks held on the memory-optimized table
- LANGUAGE = 'us_english' is required for natively compiled procs

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | BIGINT | NO | - | VERIFIED | The unique identifier of the delayed open order to update. Maps to Trade.DelayedOrderForOpen.OrderID. |
| 2 | @StatusID | INT | NO | - | VERIFIED | The new status to set: 2=FILLED (order executed at market), 3=REMOVED (order cancelled/expired). See Dictionary.DelayedOrderStatus. |

**Output**: Returns all columns of the updated row via OUTPUT INSERTED.*.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.DelayedOrderForOpen | MODIFIER | Updates StatusID for the specified OrderID where current status is PLACED (1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreate | EXEC | Caller | Calls with StatusID=2 (FILLED) when a delayed open order executes |
| DelayedOrderRepository.cs | SqlCommand | Application Caller | Called from trading-shared via C# repository layer (Source: trading-shared) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DelayedOrderForOpenStatusUpdate (procedure, natively compiled)
+-- Trade.DelayedOrderForOpen (table, memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelayedOrderForOpen | Table (Memory-Optimized) | Target of UPDATE SET StatusID WHERE OrderID and StatusID=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenCreate | Stored Procedure | Calls via EXEC to mark delayed order as FILLED after execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| native_compilation | Compilation | Natively compiled for sub-millisecond execution on memory-optimized table |
| schemabinding | Binding | Schema-bound to Trade.DelayedOrderForOpen - DDL changes blocked while proc exists |
| ATOMIC (SNAPSHOT) | Transaction | Automatic atomic transaction with snapshot isolation - no lock contention |

---

## 8. Sample Queries

### 8.1 Mark a delayed open order as FILLED

```sql
EXEC Trade.DelayedOrderForOpenStatusUpdate @OrderID = 12345678, @StatusID = 2
```

### 8.2 Mark a delayed open order as REMOVED (cancelled)

```sql
EXEC Trade.DelayedOrderForOpenStatusUpdate @OrderID = 12345678, @StatusID = 3
```

### 8.3 Check pending delayed open orders before status update

```sql
SELECT  OrderID, CID, InstrumentID, IsBuy, Leverage, Amount, StatusID, RequestOccurred
FROM    Trade.DelayedOrderForOpen WITH (NOLOCK)
WHERE   StatusID = 1
ORDER BY RequestOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 1 files | Corrections: 0 applied*
*Object: Trade.DelayedOrderForOpenStatusUpdate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DelayedOrderForOpenStatusUpdate.sql*
