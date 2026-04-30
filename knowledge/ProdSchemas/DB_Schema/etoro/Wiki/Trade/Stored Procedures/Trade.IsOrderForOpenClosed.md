# Trade.IsOrderForOpenClosed

> Natively compiled procedure that checks whether a position-open order is in a terminal (closed) state: sets @IsClosed = 0 if any non-terminal status row exists in Trade.OrderForOpen, or @IsClosed = 1 if all rows are terminal or the order is not found.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID - the open order to check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsOrderForOpenClosed is the position-open order analog of Trade.IsOrderForCloseClosed. It answers: "Is this position-open order in a final state (FILLED, REJECTED, CANCELED, etc.)?" It checks Trade.OrderForOpen (the memory-optimized live open order table) against Dictionary.OrderForExecutionStatus.IsTerminal.

Like its companion procedure, it is natively compiled for sub-millisecond performance to match the execution tier of Trade.OrderForOpen. Used by the trading execution engine to detect when an open order has completed processing, enabling downstream actions (position creation, mirror allocation, confirmation to client).

See Trade.IsOrderForCloseClosed for the close order equivalent. Both procedures use identical logic with different source tables.

---

## 2. Business Logic

### 2.1 Terminal Status Check

**What**: Identical logic to Trade.IsOrderForCloseClosed but reads from Trade.OrderForOpen.

**Columns/Parameters Involved**: `@OrderID`, `@IsClosed OUTPUT`, `Trade.OrderForOpen.StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- SELECT TOP 1 @IsClosed = 0 FROM Trade.OrderForOpen ofo INNER JOIN Dictionary.OrderForExecutionStatus oes ON ofo.StatusID = oes.ID WHERE ofo.OrderID = @OrderID AND oes.IsTerminal != 1.
- If a non-terminal status row exists: @IsClosed = 0 (still processing).
- If no non-terminal rows (all terminal or order archived): @IsClosed = NULL -> SET @IsClosed = 1 (closed/completed).
- Archived orders (moved to History.OrderForOpen) return @IsClosed = 1 (correct: no longer in live table = terminal).

**Diagram**: Identical to Trade.IsOrderForCloseClosed - see that document for the flow diagram.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The open order ID to check. FK to Trade.OrderForOpen.OrderID. |
| 2 | @IsClosed | bit OUTPUT | NO | - | CODE-BACKED | OUTPUT. 1 = order is in terminal state (FILLED, REJECTED, CANCELED, etc. or archived). 0 = order has at least one non-terminal status row (still executing). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT TOP 1 | Trade.OrderForOpen | Reader (Memory-Optimized) | Checks for non-terminal status rows on the live open order |
| JOIN | Dictionary.OrderForExecutionStatus | Reader | IsTerminal flag determines which statuses are final |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by the trading execution engine to detect open order completion.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsOrderForOpenClosed (procedure - natively compiled)
├── Trade.OrderForOpen (memory-optimized table) - live open order status
└── Dictionary.OrderForExecutionStatus (table) - IsTerminal classification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Memory-Optimized Table | Source of live open order status rows; schemabinding required for native compilation |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal flag for status classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading execution engine | External (Application) | Polls to detect open order completion before position creation and client confirmation |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH NATIVE_COMPILATION | Performance | Native code compilation for sub-millisecond execution in the order hot path |
| SCHEMABINDING | Dependency | Schema-bound to Trade.OrderForOpen and Dictionary.OrderForExecutionStatus |
| BEGIN ATOMIC + SNAPSHOT | Isolation | Required for natively compiled procedures; SNAPSHOT isolation |
| Companion procedure | Design | Trade.IsOrderForCloseClosed is the exact analog for close orders |

---

## 8. Sample Queries

### 8.1 Check if an open order has completed

```sql
DECLARE @Closed BIT;
EXEC Trade.IsOrderForOpenClosed @OrderID = 1234567890, @IsClosed = @Closed OUTPUT;
SELECT @Closed AS IsOrderClosed;
-- 1 = terminal (filled/rejected/canceled/archived), 0 = still processing
```

### 8.2 View current non-terminal open orders for debugging

```sql
SELECT ofo.OrderID, ofo.StatusID, oes.Name AS StatusName, oes.IsTerminal
FROM Trade.OrderForOpen ofo WITH (SNAPSHOT)
     JOIN Dictionary.OrderForExecutionStatus oes ON ofo.StatusID = oes.ID
WHERE ofo.OrderID = 1234567890
  AND oes.IsTerminal != 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsOrderForOpenClosed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsOrderForOpenClosed.sql*
