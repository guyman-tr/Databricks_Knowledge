# Trade.IsOrderForCloseClosed

> Natively compiled procedure that checks whether a close order is in a terminal (closed) state: sets @IsClosed = 0 if any non-terminal status row exists in Trade.OrderForClose, or @IsClosed = 1 if all rows are terminal or the order is not found.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID - the close order to check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsOrderForCloseClosed is a natively compiled predicate procedure that answers: "Is this position-close order in a final state?" It checks the current status of a close order in Trade.OrderForClose (the memory-optimized In-Memory OLTP table for live close order execution) against Dictionary.OrderForExecutionStatus.IsTerminal.

The procedure is natively compiled (WITH NATIVE_COMPILATION) for sub-millisecond throughput, matching the performance tier of Trade.OrderForClose itself. It is used by the trading execution engine to poll order state during the close execution lifecycle: as long as the order has non-terminal status rows, it is still processing. Once all status rows are terminal (or the order has been archived off to History.OrderForClose), @IsClosed = 1 signals completion.

The SNAPSHOT isolation level in the ATOMIC block ensures a consistent read within the natively compiled context.

Data flow: Close order created -> Trading engine polls Trade.IsOrderForCloseClosed -> when @IsClosed = 1, downstream processing proceeds (position archived, mirror adjusted, etc.).

---

## 2. Business Logic

### 2.1 Terminal Status Check

**What**: Checks whether any non-terminal OrderForClose row exists for the given OrderID.

**Columns/Parameters Involved**: `@OrderID`, `@IsClosed OUTPUT`, `Trade.OrderForClose.StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- SELECT TOP 1 @IsClosed = 0 FROM Trade.OrderForClose ofc INNER JOIN Dictionary.OrderForExecutionStatus oes ON ofc.StatusID = oes.ID WHERE ofc.OrderID = @OrderID AND oes.IsTerminal != 1.
- If a non-terminal status row is found: @IsClosed is set to 0 (order still in progress).
- If no non-terminal rows are found (either all are terminal, or order not found): @IsClosed remains NULL (not set by the SELECT).
- IF @IsClosed IS NULL: SET @IsClosed = 1 (order is closed/terminal).
- Result: @IsClosed = 1 means the order has completed (or no longer exists in live table); @IsClosed = 0 means still processing.

**Note on absence**: If @OrderID is not in Trade.OrderForClose at all (order was already archived to History.OrderForClose), the SELECT returns nothing, @IsClosed = NULL -> SET to 1. This means an archived order is treated as "closed", which is correct behavior.

**Diagram**:
```
@OrderID
    |
    v
SELECT TOP 1 @IsClosed = 0
FROM Trade.OrderForClose
     JOIN Dictionary.OrderForExecutionStatus ON StatusID = ID
WHERE OrderID = @OrderID AND IsTerminal != 1
    |
    +-- [Row found (non-terminal status exists)] -> @IsClosed = 0 (still open)
    |
    +-- [No row found (all terminal or not in table)] -> @IsClosed = NULL
                                                              |
                                                              v
                                                         IF NULL: SET @IsClosed = 1 (closed)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The close order ID to check. FK to Trade.OrderForClose.OrderID. Bigint to support high-volume order numbering. |
| 2 | @IsClosed | bit OUTPUT | NO | - | CODE-BACKED | OUTPUT. 1 = order is in terminal state (fully processed or archived). 0 = order has at least one non-terminal status row (still being executed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT TOP 1 | Trade.OrderForClose | Reader (Memory-Optimized) | Checks for non-terminal status rows on the live close order |
| JOIN | Dictionary.OrderForExecutionStatus | Reader | IsTerminal flag determines which statuses are final |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by the trading execution engine during close order processing to determine completion.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsOrderForCloseClosed (procedure - natively compiled)
├── Trade.OrderForClose (memory-optimized table) - live close order status
└── Dictionary.OrderForExecutionStatus (table) - IsTerminal classification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Memory-Optimized Table | Source of live close order status rows; schemabinding required for native compilation |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal flag - 1 = terminal (final) status, != 1 = still processing |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading execution engine | External (Application) | Polls this procedure to detect close order completion before proceeding with post-close processing |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH NATIVE_COMPILATION | Performance | Compiled to native machine code; required for In-Memory OLTP integration |
| SCHEMABINDING | Dependency | Schema-bound to referenced objects; prevents structural changes to Trade.OrderForClose or Dictionary.OrderForExecutionStatus without dropping this procedure |
| BEGIN ATOMIC + SNAPSHOT | Isolation | Required pattern for natively compiled procedures; SNAPSHOT isolation ensures consistent read |
| NULL -> 1 promotion | Design | If SELECT finds no matching row (order gone from live table), @IsClosed is 1 (correct: archived = closed) |
| Companion procedure | Design | Trade.IsOrderForOpenClosed is the exact analog for open orders |

---

## 8. Sample Queries

### 8.1 Check if a close order is completed

```sql
DECLARE @Closed BIT;
EXEC Trade.IsOrderForCloseClosed @OrderID = 9876543210, @IsClosed = @Closed OUTPUT;
SELECT @Closed AS IsOrderClosed;
-- 1 = terminal (closed/archived), 0 = still processing
```

### 8.2 View current non-terminal close orders for debugging

```sql
SELECT ofc.OrderID, ofc.StatusID, oes.Name AS StatusName, oes.IsTerminal
FROM Trade.OrderForClose ofc WITH (SNAPSHOT)
     JOIN Dictionary.OrderForExecutionStatus oes ON ofc.StatusID = oes.ID
WHERE ofc.OrderID = 9876543210
  AND oes.IsTerminal != 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsOrderForCloseClosed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsOrderForCloseClosed.sql*
