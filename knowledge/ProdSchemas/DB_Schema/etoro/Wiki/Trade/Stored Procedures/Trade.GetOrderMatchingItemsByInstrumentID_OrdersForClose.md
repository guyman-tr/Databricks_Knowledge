# Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose

> Returns two result sets for pending close orders and their execution plan positions for a batch of instruments - provides the OME with all data needed to match and execute position closes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates #ordersTempTable with CLUSTERED INDEX CIX on (OrderID) |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_OrdersForClose` retrieves pending close orders (`Trade.OrderForClose` with StatusID=11) for a set of instruments, returning two result sets:
1. The close orders themselves (CID, InstrumentID, OrderID, action type, units, type, request GUID)
2. The close execution plan rows at Level=0 (the specific positions targeted by each order)

**WHY:** The OME needs both pieces to execute a close: the order (what action, how many units) and the execution plan (which specific positions to close). Returning both in one SP call minimizes round-trips and ensures the OME has atomically consistent data.

**HOW:**
1. Load TVP into #instrumentsTable (primary key on InstrumentID).
2. SELECT from Trade.OrderForClose (StatusID=11, InstrumentID matched) into #ordersTempTable.
3. Create CLUSTERED INDEX on #ordersTempTable (OrderID) for the second query.
4. First result set: SELECT * FROM #ordersTempTable.
5. Second result set: SELECT from Trade.CloseExecutionPlan WHERE OrderID IN #ordersTempTable AND Level=0.

---

## 2. Business Logic

### 2.1 StatusID = 11 - Pending Close Orders

**What:** StatusID=11 in Trade.OrderForClose indicates orders that are queued and pending execution by the OME. Already-executed or cancelled close orders have different StatusIDs and are excluded.

**Columns/Parameters Involved:** `StatusID`

**Rules:**
- `WHERE StatusID = 11` -> pending/queued orders awaiting OME processing
- Already processed or cancelled orders are excluded

### 2.2 Two Result Sets - Orders + Execution Plan

**What:** The SP returns two separate result sets in a single execution. Consumer must read both sequentially.

**Rules:**
- Result set 1: The close orders (7 columns: CID, InstrumentID, OrderID, MirrorCloseActionType, UnitsToDeduct, OrderType, RequestGuid)
- Result set 2: The close execution plan at Level=0 (3 columns: OrderID, PositionID, CloseActionType)
- Level=0 in CloseExecutionPlan means the direct position-to-close entries (Level>0 would be sub-executions for complex closes)
- The CLUSTERED INDEX created on #ordersTempTable(OrderID) optimizes the JOIN for result set 2

### 2.3 Request Deduplication (RequestGuid)

**What:** `RequestGuid` enables the OME to detect duplicate close requests (same request submitted twice).

**Columns/Parameters Involved:** `RequestGuid`

**Rules:**
- GUID set when the close request is created
- OME can use this to detect and deduplicate concurrent close requests for the same order

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with InstrumentID INT. Returns close orders for positions in these instruments. |

**Result Set 1 - Close Orders (from Trade.OrderForClose WHERE StatusID=11):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID requesting the close. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the position being closed. Matched by input TVP. |
| 3 | OrderID | INT | NO | - | CODE-BACKED | Close order ID. Primary key and join key for result set 2. |
| 4 | MirrorCloseActionType | INT | YES | - | CODE-BACKED | Close action type for mirror/copy-trade positions. Determines how the close propagates through the copy-trade tree. |
| 5 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | Number of units to close. NULL for full position close; set for partial closes. |
| 6 | OrderType | TINYINT | YES | - | CODE-BACKED | Type of close order (e.g., manual close, stop-loss trigger, take-profit trigger, margin call). |
| 7 | RequestGuid | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Deduplication GUID for the close request. Allows OME to detect duplicate submissions. |

**Result Set 2 - Close Execution Plan (from Trade.CloseExecutionPlan WHERE Level=0):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Close order ID. Joins to result set 1's OrderID. |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Specific position ID to be closed by this order. The OME uses this to find and close the exact position. |
| 3 | CloseActionType | INT | YES | - | CODE-BACKED | Action type for this specific position close within the execution plan. May differ from MirrorCloseActionType for individual position-level close categorization. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Input batch of instrument IDs |
| WHERE StatusID=11 | Trade.OrderForClose | Lookup | Source of pending close orders |
| #ordersTempTable.OrderID = cep.OrderID | Trade.CloseExecutionPlan | JOIN | Level=0 execution plan entries for the close orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose (procedure)
|- Trade.InstrumentIDsTbl (user defined type) - TVP for instrument batch
|- Trade.OrderForClose (table) - pending close orders (StatusID=11)
|- Trade.CloseExecutionPlan (table) - position-level close execution plan (Level=0)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentsTable parameter |
| Trade.OrderForClose | Table | Source of pending close orders (StatusID=11, instrument filter) |
| Trade.CloseExecutionPlan | Table | Second result set - Level=0 execution plan rows for matched orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by OME application code for close order processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. (Temp table #ordersTempTable gets CLUSTERED INDEX CIX on OrderID for optimizing the Level=0 CloseExecutionPlan join)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 11 | Filter | Only pending/queued close orders |
| Level = 0 | Filter | Direct position-to-close entries in the execution plan (not sub-execution levels) |

---

## 8. Sample Queries

### 8.1 Execute for specific instruments

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (2)

EXEC Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose
    @instrumentsTable = @instruments
```

### 8.2 View pending close orders for an instrument

```sql
SELECT TOP 20
    CID, InstrumentID, OrderID, OrderType, UnitsToDeduct, MirrorCloseActionType
FROM Trade.OrderForClose WITH (NOLOCK)
WHERE StatusID = 11 AND InstrumentID = 1
ORDER BY OrderID DESC
```

### 8.3 View close execution plan for a specific order

```sql
SELECT OrderID, PositionID, CloseActionType, Level
FROM Trade.CloseExecutionPlan WITH (NOLOCK)
WHERE OrderID = 12345678 AND Level = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose.sql*
