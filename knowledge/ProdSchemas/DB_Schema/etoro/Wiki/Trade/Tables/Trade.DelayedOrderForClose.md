# Trade.DelayedOrderForClose

> Memory-optimized queue table for pending close orders that execute with a delay (limit/stop close orders awaiting market price).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table (Memory-Optimized) |
| **Key Identifier** | RequestIdentifier |
| **Partition** | No |
| **Indexes** | 7 |

---

## 1. Business Meaning

Trade.DelayedOrderForClose is the in-memory queue for close orders that do not execute immediately at market. When a user places a limit order or stop order to close a position at a specific price (rather than closing at market), that request is inserted as a row here. The order remains in StatusID=1 (PLACED) until the market price reaches the trigger level. When execution occurs, `Trade.OrderForCloseCreate` creates the actual close order and calls `Trade.DelayedOrderForCloseStatusUpdate` to set StatusID=2 (FILLED). A nightly job (`Trade.DeleteDelayedOrderForCloseJob`) archives FILLED and REMOVED rows to History.DelayedOrderForClose and deletes them from this table to keep it lean.

This table exists because many close operations are conditional on price (e.g., "close my EUR/USD position when rate hits 1.05"). The trading engine must persist these pending close requests and monitor prices in real time. Memory-optimization and hash indexes enable sub-millisecond lookups by OrderID, StatusID, CID, and PositionID—critical for the order matching engine.

Data flows: rows are INSERTed by the application/OME when a user places a delayed close order. Status is UPDATEd by `Trade.DelayedOrderForCloseStatusUpdate` when the order fills or is removed. Rows are DELETEd by `Trade.DeleteDelayedOrderForCloseJob` after archiving to History. Key readers: `Trade.GetDelayedOrderForCloseWithPaging`, `Trade.GetPortfolioAggregates`, `Trade.PortfolioForApiInnerMot`, `Trade.GetMirrorDataWithCIDAndMirrorIdForSSE`, `Trade.GetDataForCloseMirrorPositions`, `Trade.GetPositionsForCloseMirrorMot`, `Trade.GetTreeNodesByParentPositionAndTreeId`, `Trade.GetOrphanedPositionsData`, `Trade.AlertForMirrors_which_should_have_clsoed`, `Trade.DelayedOrdersOvernight`, `Trade.GetMirrorDataWithCIDForAPI`, `Trade.GetMirrorDataWithCIDAndMirrorIdForAPI`.

---

## 2. Business Logic

### 2.1 Delayed Order Lifecycle

**What**: Three-state lifecycle aligned with Dictionary.DelayedOrderStatus.

**Columns/Parameters Involved**: `StatusID`, `RequestIdentifier`, `OrderID`

**Rules**:
- StatusID 1 (PLACED): Order active, waiting for market price
- StatusID 2 (FILLED): Order executed; `Trade.OrderForCloseCreate` passes @DelayedOrderID, then `DelayedOrderForCloseStatusUpdate` sets StatusID=2
- StatusID 3 (REMOVED): Order canceled/expired without execution
- `Trade.DeleteDelayedOrderForCloseJob` archives rows with StatusID in (2,3) to History.DelayedOrderForClose, then DELETEs from this table

### 2.2 Position-to-Order Uniqueness

**What**: At most one pending delayed close per position.

**Columns/Parameters Involved**: `PositionID`

**Rules**:
- UNIQUE constraint `UC_DelayedOrderForClose_PositionID` enforces one row per PositionID
- Prevents duplicate pending close requests for the same position

### 2.3 Instrument and Units Context

**What**: InstrumentID and UnitsToDeduct support portfolio aggregation and close execution planning.

**Columns/Parameters Involved**: `InstrumentID`, `UnitsToDeduct`

**Rules**:
- InstrumentID: FK to Trade.Instrument (implicit); used for portfolio aggregates by instrument
- UnitsToDeduct: units to close when order executes; NULL when not yet determined

---

## 3. Data Overview

| RequestIdentifier | OrderID | OriginalOrderID | CID | PositionID | InstrumentID | StatusID | ActionType | Meaning |
|-------------------|---------|-----------------|-----|------------|---------------|----------|-------------|---------|
| 505 | 24156891 | 24156890 | 9263423 | 2152963122 | 5201 | 1 | 17 | Pending close order for position 2152963122, instrument 5201. ActionType 17 (ExecutionServicesOperationType). |
| 504 | 24156889 | 24156888 | 9263423 | 2152963124 | 1706 | 1 | 17 | Same CID, different position—mirror copy close. |
| 503 | 24156887 | 24156886 | 9263423 | 2152963121 | 4280 | 1 | 17 | Pending close, instrument 4280. |
| 502 | 24156885 | 24156884 | 9263423 | 2152963120 | 9119 | 1 | 17 | Pending close, instrument 9119. |
| 501 | 24156883 | 24156882 | 9263423 | 2152963123 | 1002 | 1 | 17 | Pending close, instrument 1002. |

*Sample from live data (2026-03). All 23 rows have StatusID=1 (PLACED). FILLED/REMOVED rows are archived by job.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestIdentifier | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier allocated on INSERT. Used as DelayedOrderID when OrderForCloseCreate links the close order. |
| 2 | OrderID | bigint | NO | - | CODE-BACKED | The OrderForClose OrderID created when this delayed request is executed. Hash index IDX_OrderID for O(1) lookups. |
| 3 | OriginalOrderID | bigint | NO | - | CODE-BACKED | Original order reference; may differ from OrderID for replacement/retry flows. |
| 4 | CID | int | YES | - | CODE-BACKED | Customer ID. Index IDX_CID supports lookups by customer. |
| 5 | PositionID | bigint | YES | - | CODE-BACKED | Position to close. UNIQUE constraint UC_DelayedOrderForClose_PositionID—one pending close per position. |
| 6 | InstrumentID | int | YES | - | CODE-BACKED | Instrument being closed. Implicit FK to Trade.Instrument. Used in portfolio aggregates. |
| 7 | RequestOccurred | datetime | YES | getutcdate() | CODE-BACKED | When the delayed close was requested. |
| 8 | LastUpdate | datetime | YES | - | CODE-BACKED | Last status/modification time. Hash index IDX_LastUpdate for time-based queries. |
| 9 | ActionType | int | YES | - | CODE-BACKED | ExecutionServicesOperationType (e.g., 17). Dictionary.ExecutionServicesOpeartionType. |
| 10 | StatusID | int | YES | - | CODE-BACKED | 1=PLACED, 2=FILLED, 3=REMOVED (Dictionary.DelayedOrderStatus). Hash index IDX_StatusID. |
| 11 | RequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Idempotency/correlation ID for the request. |
| 12 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Units to close when order executes. NULL when not yet computed. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Instrument being closed |
| CID | Customer.Customer | Implicit | Customer placing the close |
| PositionID | Trade.Position | Implicit | Position to close |
| StatusID | Dictionary.DelayedOrderStatus | Lookup | PLACED/FILLED/REMOVED |
| ActionType | Dictionary.ExecutionServicesOpeartionType | Lookup | Operation type |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForCloseCreate | DelayedOrderID | Writer | Updates status when close executes |
| Trade.DelayedOrderForCloseStatusUpdate | OrderID | Modifier | Sets StatusID |
| Trade.DeleteDelayedOrderForCloseJob | - | Deleter | Archives to History, then DELETE |
| Trade.GetDelayedOrderForCloseWithPaging | - | Reader | Paged retrieval |
| Trade.GetPortfolioAggregates | - | Reader | Portfolio instrument exposure |
| Trade.PortfolioForApiInnerMot | - | Reader | API portfolio data |
| Trade.GetMirrorDataWithCIDAndMirrorIdForSSE | - | Reader | SSE mirror data |
| Trade.GetDataForCloseMirrorPositions | - | Reader | Close mirror positions |
| Trade.GetPositionsForCloseMirrorMot | - | Reader | Positions for close mirror |
| Trade.GetTreeNodesByParentPositionAndTreeId | - | Reader | Tree node resolution |
| Trade.GetOrphanedPositionsData | - | Reader | Orphan detection |
| Trade.AlertForMirrors_which_should_have_clsoed | - | Reader | Alert logic |
| Trade.DelayedOrdersOvernight | - | Reader | Overnight delayed orders |
| Trade.GetMirrorDataWithCIDForAPI | - | Reader | API mirror data |
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | - | Reader | API mirror data |
| History.DelayedOrderForClose | - | Archive | MERGE target from job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DelayedOrderForClose (table)
├── Trade.Instrument (table) [implicit via InstrumentID]
├── Trade.Position (table) [implicit via PositionID]
├── Dictionary.DelayedOrderStatus (table) [lookup via StatusID]
└── Dictionary.ExecutionServicesOpeartionType (table) [lookup via ActionType]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | InstrumentID references instrument definition |
| Trade.Position | Table | PositionID references position to close |
| Dictionary.DelayedOrderStatus | Table | StatusID lookup |
| Dictionary.ExecutionServicesOpeartionType | Table | ActionType lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForCloseCreate | Procedure | Receives DelayedOrderID, calls DelayedOrderForCloseStatusUpdate |
| Trade.DelayedOrderForCloseStatusUpdate | Procedure | UPDATE StatusID |
| Trade.DeleteDelayedOrderForCloseJob | Procedure | MERGE to History, DELETE |
| Trade.GetDelayedOrderForCloseWithPaging | Procedure | SELECT |
| Trade.GetPortfolioAggregates | Procedure | SELECT |
| Trade.PortfolioForApiInnerMot | Procedure | SELECT |
| Trade.GetMirrorDataWithCIDAndMirrorIdForSSE | Procedure | SELECT |
| Trade.GetDataForCloseMirrorPositions | Procedure | SELECT |
| Trade.GetPositionsForCloseMirrorMot | Procedure | SELECT |
| Trade.GetTreeNodesByParentPositionAndTreeId | Procedure | LEFT JOIN |
| Trade.GetOrphanedPositionsData | Procedure | LEFT JOIN |
| Trade.AlertForMirrors_which_should_have_clsoed | Procedure | NOT IN subquery |
| Trade.DelayedOrdersOvernight | Procedure | SELECT |
| Trade.GetMirrorDataWithCIDForAPI | Procedure | SELECT |
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Procedure | SELECT |
| History.DelayedOrderForClose | Table | MERGE archive target |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__Trade_DelayedOrderForClose_RequestIdentifier | NC HASH PK | RequestIdentifier (BUCKET_COUNT=65536) | - | - | Active |
| UC_DelayedOrderForClose_PositionID | NC UNIQUE | PositionID | - | - | Active |
| IDX_CID | NC | CID | - | - | Active |
| IDX_LastUpdate | NC HASH | LastUpdate (BUCKET_COUNT=65536) | - | - | Active |
| IDX_OrderID | NC HASH | OrderID (BUCKET_COUNT=65536) | - | - | Active |
| IDX_OrderID_StatusID | NC | OrderID, StatusID | - | - | Active |
| IDX_StatusID | NC HASH | StatusID (BUCKET_COUNT=8) | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK__Trade_DelayedOrderForClose_RequestIdentifier | PRIMARY KEY (HASH) | Unique RequestIdentifier |
| UC_DelayedOrderForClose_PositionID | UNIQUE | One pending close per PositionID |
| DF_RequestOccurred | DEFAULT | RequestOccurred = getutcdate() |

**Special**: `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA` — In-memory for low-latency order matching.

---

## 8. Sample Queries

### 8.1 Get pending delayed close orders with status name
```sql
SELECT d.RequestIdentifier, d.OrderID, d.CID, d.PositionID, d.InstrumentID,
       d.RequestOccurred, d.LastUpdate, dos.StatusName
  FROM Trade.DelayedOrderForClose d WITH (NOLOCK)
  JOIN Dictionary.DelayedOrderStatus dos WITH (NOLOCK) ON d.StatusID = dos.StatusID
 WHERE d.StatusID = 1
 ORDER BY d.RequestOccurred DESC
```

### 8.2 Count delayed close orders by status
```sql
SELECT dos.StatusName, COUNT(*) AS Cnt
  FROM Trade.DelayedOrderForClose d WITH (NOLOCK)
  JOIN Dictionary.DelayedOrderStatus dos WITH (NOLOCK) ON d.StatusID = dos.StatusID
 GROUP BY dos.StatusName
```

### 8.3 Delayed close orders for a customer with instrument
```sql
SELECT d.RequestIdentifier, d.OrderID, d.PositionID, d.InstrumentID, d.UnitsToDeduct,
       i.BuyCurrencyID, i.SellCurrencyID, d.RequestOccurred
  FROM Trade.DelayedOrderForClose d WITH (NOLOCK)
  LEFT JOIN Trade.Instrument i WITH (NOLOCK) ON d.InstrumentID = i.InstrumentID
 WHERE d.CID = 9263423
   AND d.StatusID = 1
 ORDER BY d.RequestOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.3/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Procedures*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | Live rows: 23 | Corrections: 0 applied*
*Object: Trade.DelayedOrderForClose | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.DelayedOrderForClose.sql*
