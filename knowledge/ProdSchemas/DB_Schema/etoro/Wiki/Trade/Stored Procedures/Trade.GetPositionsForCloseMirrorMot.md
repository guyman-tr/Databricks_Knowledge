# Trade.GetPositionsForCloseMirrorMot

> Natively compiled in-memory procedure that returns three result sets for a pre-fetched list of positions: the positions themselves, those with active close orders, and those with pending delayed close orders - used as the inner engine of the CopyTrader mirror closure workflow.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionList Trade.PositionList, @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the natively compiled (in-memory OLTP) inner procedure of the CopyTrader mirror close flow. It is NOT called directly by applications; it is always invoked via its wrapper `Trade.GetPositionsForCloseMirror`, which first populates the @PositionList TVP from Trade.PositionTbl and then passes it here. The native compilation provides maximum throughput for what is a performance-critical operation in stop-copy/close-mirror flows.

This procedure answers three questions at once: (1) Which positions are in the list? (2) Which of those already have an active close order in the standard execution pipeline? (3) Which of those already have a pending delayed close order? The caller uses all three result sets together to determine which positions still need fresh close orders.

Data flows: Runs with SNAPSHOT isolation (TRANSACTION ISOLATION LEVEL = SNAPSHOT) in an ATOMIC block. Three SELECTs execute sequentially: first the @PositionList TVP passthrough (no I/O), then a JOIN to Trade.CloseExecutionPlan + Trade.OrderForClose + Dictionary.OrderForExecutionStatus (non-terminal orders), then a JOIN to Trade.DelayedOrderForClose (pending delayed orders with StatusID=1). Caller is `Trade.GetPositionsForCloseMirror`.

---

## 2. Business Logic

### 2.1 Three-Result-Set Pattern: Open, Closing, Delayed

**What**: Returns three complementary sets for mirror closure decision-making.

**Columns/Parameters Involved**: `@PositionList`, `Trade.CloseExecutionPlan`, `Trade.DelayedOrderForClose`

**Rules**:
- Result set 1: Passthrough of @PositionList (PositionID, InstrumentID). These are the open positions to process.
- Result set 2: Positions from @PositionList that have a non-terminal order in Trade.CloseExecutionPlan (standard execution pipeline). Non-terminal = IsTerminal=0: RECEIVED, PLACED, PARTIALLY_FILLED, PENDING_CANCEL, WAITING_FOR_MARKET.
- Result set 3: Positions from @PositionList with a pending delayed close in Trade.DelayedOrderForClose (StatusID=1 = pending/active).
- Caller logic: positions_to_close = ResultSet1 MINUS ResultSet2 MINUS ResultSet3.
- This design prevents both duplicate standard close orders AND duplicate delayed close orders.

**Diagram**:
```
@PositionList (open positions for mirror)
   |           |            |
   v           v            v
RS1: all    RS2: in     RS3: in
             standard    delayed
             pipeline    pipeline
              (non-        (Status=1)
             terminal)
```

### 2.2 Native Compilation and SNAPSHOT Isolation

**What**: The procedure uses WITH NATIVE_COMPILATION, SCHEMABINDING and executes with SNAPSHOT isolation in an ATOMIC block for in-memory OLTP performance.

**Columns/Parameters Involved**: Applies to all queries

**Rules**:
- SNAPSHOT isolation: reads a consistent view of data as of transaction start, no blocking.
- ATOMIC block: the entire procedure is one atomic unit; on error, all effects roll back.
- NATIVE_COMPILATION: compiled to native code at creation time, not interpreted T-SQL. Reduces per-row overhead.
- SCHEMABINDING: all referenced objects must exist and cannot be altered without dropping this procedure first.
- This procedure can ONLY reference memory-optimized objects or those compatible with native compilation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionList | Trade.PositionList READONLY | NO | - | CODE-BACKED | TVP containing the pre-loaded list of open positions for the mirror. Populated by the wrapper `Trade.GetPositionsForCloseMirror` from Trade.PositionTbl. Contains PositionID and InstrumentID pairs. |
| 2 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Used to scope the CloseExecutionPlan and DelayedOrderForClose lookups to this customer only. |

**Result Set 1: Position List (passthrough)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | Open position ID from the input list. Returned as-is for the caller to process. |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the open position. Returned so the caller can route close orders by instrument. |

**Result Set 2: Positions Already Closing (standard pipeline)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | PositionID of a position that has a non-terminal close order in Trade.CloseExecutionPlan. Caller should exclude these from new close order submissions. |

**Result Set 3: Positions with Pending Delayed Close**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | PositionID of a position that has a pending delayed close order in Trade.DelayedOrderForClose (StatusID=1). Caller should exclude these from new submissions to avoid duplicate delayed closes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionList | Trade.PositionList | TVP type | In-memory user-defined table type containing PositionID, InstrumentID |
| PositionID | Trade.CloseExecutionPlan | JOIN | Standard close execution plan lookup |
| OrderID | Trade.OrderForClose | JOIN | Close order status lookup |
| IsTerminal | Dictionary.OrderForExecutionStatus | Lookup | Non-terminal filter (IsTerminal=0) |
| PositionID | Trade.DelayedOrderForClose | JOIN | Delayed close order lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForCloseMirror | EXEC | Caller | The public-facing wrapper procedure that populates @PositionList from PositionTbl and calls this Mot procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForCloseMirrorMot (procedure, natively compiled)
├── Trade.PositionList (user-defined type, TVP)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table)
├── Dictionary.OrderForExecutionStatus (table)
└── Trade.DelayedOrderForClose (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionList | User Defined Type | TVP parameter type; contains the input position list |
| Trade.CloseExecutionPlan | Table | JOIN to detect active standard close orders |
| Trade.OrderForClose | Table | JOIN to get close order execution status |
| Dictionary.OrderForExecutionStatus | Table | Filter non-terminal statuses (IsTerminal=0) |
| Trade.DelayedOrderForClose | Table | JOIN to detect pending delayed close orders (StatusID=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForCloseMirror | Procedure | Wrapper that calls this procedure after loading @PositionList |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH NATIVE_COMPILATION | Performance | Compiled to native code for in-memory OLTP performance |
| WITH SCHEMABINDING | DDL constraint | All referenced objects are schema-bound; cannot be altered without dropping this procedure |
| TRANSACTION ISOLATION LEVEL = SNAPSHOT | Concurrency | Reads consistent snapshot; no blocking on CloseExecutionPlan or DelayedOrderForClose |
| BEGIN ATOMIC | Transaction | All three SELECTs execute as an atomic unit |

---

## 8. Sample Queries

### 8.1 Execute via the wrapper (normal usage)

```sql
-- Use Trade.GetPositionsForCloseMirror; do not call this procedure directly
EXEC Trade.GetPositionsForCloseMirror @mirrorId = 12345, @cid = 1234567;
```

### 8.2 Check non-terminal close orders for positions in a mirror

```sql
DECLARE @cid INT = 1234567;
SELECT cep.PositionID, ofc.StatusID, os.Status
FROM Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.OrderForClose ofc WITH (NOLOCK) ON cep.OrderID = ofc.OrderID
INNER JOIN Dictionary.OrderForExecutionStatus os WITH (NOLOCK) ON ofc.StatusID = os.ID
INNER JOIN Trade.PositionTbl pt WITH (NOLOCK) ON cep.PositionID = pt.PositionID AND pt.MirrorID = 12345
WHERE cep.CID = @cid AND os.IsTerminal = 0;
```

### 8.3 Check pending delayed close orders for a customer's mirror positions

```sql
SELECT d.PositionID, d.StatusID
FROM Trade.DelayedOrderForClose d WITH (NOLOCK)
INNER JOIN Trade.PositionTbl pt WITH (NOLOCK) ON d.PositionID = pt.PositionID
WHERE d.CID = 1234567
  AND d.StatusID = 1
  AND pt.MirrorID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed (GetPositionsForCloseMirror) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForCloseMirrorMot | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForCloseMirrorMot.sql*
