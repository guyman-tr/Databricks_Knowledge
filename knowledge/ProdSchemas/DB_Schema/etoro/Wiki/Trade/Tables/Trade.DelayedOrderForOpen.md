# Trade.DelayedOrderForOpen

> Memory-optimized queue table for pending open orders that execute with a delay (limit/stop orders awaiting market price).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table (Memory-Optimized) |
| **Key Identifier** | RequestIdentifier |
| **Partition** | No |
| **Indexes** | 6 |

---

## 1. Business Meaning

Trade.DelayedOrderForOpen is the in-memory queue for open orders that do not execute immediately at market. When a user places a limit order or stop order to open a position at a specific price (rather than opening at market), that request is inserted as a row here. The order remains in StatusID=1 (PLACED) until the market price reaches the trigger level. When execution occurs, `Trade.OrderForOpenCreate` creates the actual OrderForOpen and calls `Trade.DelayedOrderForOpenStatusUpdate` to set StatusID=2 (FILLED). A nightly job (`Trade.DeleteDelayedOrderForOpenJob`) archives FILLED and REMOVED rows to History.DelayedOrderForOpen and deletes them from this table to keep it lean.

This table exists because many open operations are conditional on price (e.g., "buy EUR/USD when rate hits 1.05"). The trading engine must persist these pending open requests and monitor prices in real time. Memory-optimization and hash indexes enable sub-millisecond lookups by OrderID, StatusID, and CID—critical for the order matching engine. Unlike DelayedOrderForClose, this table includes order sizing (Amount, Leverage, IsBuy) and copy-trading context (MirrorID, ParentPositionID, TreeID, OpenActionType, IsCopyFund).

Data flows: rows are INSERTed by the application/OME when a user places a delayed open order. Status is UPDATEd by `Trade.DelayedOrderForOpenStatusUpdate` when the order fills or is removed. Rows are DELETEd by `Trade.DeleteDelayedOrderForOpenJob` after archiving to History. Key readers: `Trade.GetDelayedOrderForOpenWithPaging`, `Trade.GetPortfolioAggregates`, `Trade.PortfolioForApiInnerMot`, `Trade.GetMirrorDataWithCIDAndMirrorIdForSSE`, `Trade.GetMirrorDataWithCIDForAPI`, `Trade.GetMirrorDataWithCIDAndMirrorIdForAPI`, `Trade.GetMirrorOrderIdForSSEDetach`, `Trade.GetOpenOrdersForCloseMirror`, `Trade.GetUserInstrumentIdsOnly`, `Trade.DelayedOrdersOvernight`.

---

## 2. Business Logic

### 2.1 Delayed Order Lifecycle

**What**: Three-state lifecycle aligned with Dictionary.DelayedOrderStatus.

**Columns/Parameters Involved**: `StatusID`, `RequestIdentifier`, `OrderID`

**Rules**:
- StatusID 1 (PLACED): Order active, waiting for market price
- StatusID 2 (FILLED): Order executed; `Trade.OrderForOpenCreate` passes @DelayedOrderID, then `DelayedOrderForOpenStatusUpdate` sets StatusID=2
- StatusID 3 (REMOVED): Order canceled/expired without execution
- `Trade.DeleteDelayedOrderForOpenJob` archives rows with StatusID in (2,3) to History.DelayedOrderForOpen, then DELETEs from this table

### 2.2 Order Sizing and Direction

**What**: Amount, Leverage, IsBuy define the open order parameters.

**Columns/Parameters Involved**: `Amount`, `Leverage`, `IsBuy`, `InstrumentID`

**Rules**:
- Amount: notional size in money
- Leverage: leverage multiplier
- IsBuy: 1=buy, 0=sell
- InstrumentID: implicit FK to Trade.Instrument

### 2.3 Copy-Trading and Mirror Context

**What**: MirrorID, ParentPositionID, TreeID, IsCopyFund support copy-trading flows.

**Columns/Parameters Involved**: `MirrorID`, `ParentPositionID`, `TreeID`, `IsCopyFund`, `OpenActionType`, `CorrelationID`, `RootHedgeServerID`

**Rules**:
- MirrorID: implicit FK to Trade.Mirror; links to copier-leader relationship
- ParentPositionID: parent position when opening a child (e.g., split)
- TreeID: position tree identifier
- RootSettlementType, SettlementType: settlement method
- OpenActionType: operation type (Dictionary.ExecutionServicesOpeartionType)
- RootHedgeServerID: default 0 (DEFAULT constraint)

---

## 3. Data Overview

| RequestIdentifier | OrderID | CID | InstrumentID | MirrorID | Amount | IsBuy | Leverage | StatusID | Meaning |
|-------------------|---------|-----|--------------|----------|--------|-------|----------|----------|---------|
| (empty) | - | - | - | - | - | - | - | - | Table currently has 0 rows. FILLED/REMOVED rows are archived by job; PLACED rows may be rare in current sample period. |

*Live data sample (2026-03): 0 rows. Populated when users place limit/stop open orders.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestIdentifier | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier allocated on INSERT. Used as DelayedOrderID when OrderForOpenCreate links the open order. |
| 2 | OrderID | bigint | NO | - | CODE-BACKED | The OrderForOpen OrderID created when this delayed request is executed. Hash index IDX_OrderID for O(1) lookups. |
| 3 | OriginalOrderID | bigint | NO | - | CODE-BACKED | Original order reference; may differ from OrderID for replacement/retry flows. |
| 4 | CID | int | YES | - | CODE-BACKED | Customer ID. Index IDX_CID supports lookups by customer. |
| 5 | ParentCID | int | YES | - | CODE-BACKED | Parent (leader) CID in copy-trading. Used when opening copy positions. |
| 6 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the delayed open was requested. |
| 7 | LastUpdate | datetime | YES | - | CODE-BACKED | Last status/modification time. Hash index IDX_LastUpdate for time-based queries. |
| 8 | InstrumentID | int | YES | - | CODE-BACKED | Instrument to open. Implicit FK to Trade.Instrument. |
| 9 | IsBuy | bit | YES | - | CODE-BACKED | 1=buy, 0=sell. |
| 10 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier for the position. |
| 11 | Amount | money | YES | - | CODE-BACKED | Notional amount for the open. |
| 12 | MirrorID | int | YES | - | CODE-BACKED | Mirror (copy) relationship. Implicit FK to Trade.Mirror. |
| 13 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position when opening child (split/hierarchy). |
| 14 | TreeID | bigint | YES | - | CODE-BACKED | Position tree identifier. |
| 15 | RootSettlementType | int | YES | - | CODE-BACKED | Root settlement type. |
| 16 | SettlementType | int | YES | - | CODE-BACKED | Settlement type for the position. |
| 17 | IsCopyFund | bit | YES | - | CODE-BACKED | Flag for copy fund flow. |
| 18 | OpenActionType | int | YES | - | CODE-BACKED | ExecutionServicesOperationType (Dictionary). |
| 19 | CorrelationID | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID for grouped operations. |
| 20 | StatusID | int | YES | - | CODE-BACKED | 1=PLACED, 2=FILLED, 3=REMOVED (Dictionary.DelayedOrderStatus). Hash index IDX_StatusID. |
| 21 | RootHedgeServerID | int | YES | 0 | CODE-BACKED | Hedge server assignment. Default 0. |
| 22 | RequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Idempotency/correlation ID for the request. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Instrument to open |
| CID | Customer.Customer | Implicit | Customer placing the open |
| ParentCID | Customer.Customer | Implicit | Leader in copy-trading |
| MirrorID | Trade.Mirror | Implicit | Copy-trading mirror relationship |
| PositionID/ParentPositionID | Trade.Position | Implicit | Position context |
| StatusID | Dictionary.DelayedOrderStatus | Lookup | PLACED/FILLED/REMOVED |
| OpenActionType | Dictionary.ExecutionServicesOpeartionType | Lookup | Operation type |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreate | DelayedOrderID | Writer | Updates status when open executes |
| Trade.DelayedOrderForOpenStatusUpdate | OrderID | Modifier | Sets StatusID |
| Trade.DeleteDelayedOrderForOpenJob | - | Deleter | Archives to History, then DELETE |
| Trade.GetDelayedOrderForOpenWithPaging | - | Reader | Paged retrieval |
| Trade.GetPortfolioAggregates | - | Reader | Portfolio instrument exposure |
| Trade.PortfolioForApiInnerMot | - | Reader | API portfolio data |
| Trade.GetMirrorDataWithCIDAndMirrorIdForSSE | - | Reader | SSE mirror data |
| Trade.GetMirrorDataWithCIDForAPI | - | Reader | API mirror data |
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | - | Reader | API mirror data |
| Trade.GetMirrorOrderIdForSSEDetach | - | Reader | SSE detach flow |
| Trade.GetOpenOrdersForCloseMirror | - | Reader | Open orders for close mirror |
| Trade.GetUserInstrumentIdsOnly | - | Reader | User instrument IDs |
| Trade.DelayedOrdersOvernight | - | Reader | Overnight delayed orders |
| History.DelayedOrderForOpen | - | Archive | MERGE target from job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DelayedOrderForOpen (table)
├── Trade.Instrument (table) [implicit via InstrumentID]
├── Trade.Mirror (table) [implicit via MirrorID]
├── Trade.Position (table) [implicit via ParentPositionID]
├── Dictionary.DelayedOrderStatus (table) [lookup via StatusID]
└── Dictionary.ExecutionServicesOpeartionType (table) [lookup via OpenActionType]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | InstrumentID references instrument definition |
| Trade.Mirror | Table | MirrorID references copy relationship |
| Trade.Position | Table | ParentPositionID references parent position |
| Dictionary.DelayedOrderStatus | Table | StatusID lookup |
| Dictionary.ExecutionServicesOpeartionType | Table | OpenActionType lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenCreate | Procedure | Receives DelayedOrderID, calls DelayedOrderForOpenStatusUpdate |
| Trade.DelayedOrderForOpenStatusUpdate | Procedure | UPDATE StatusID |
| Trade.DeleteDelayedOrderForOpenJob | Procedure | MERGE to History, DELETE |
| Trade.GetDelayedOrderForOpenWithPaging | Procedure | SELECT |
| Trade.GetPortfolioAggregates | Procedure | SELECT |
| Trade.PortfolioForApiInnerMot | Procedure | SELECT |
| Trade.GetMirrorDataWithCIDAndMirrorIdForSSE | Procedure | SELECT |
| Trade.GetMirrorDataWithCIDForAPI | Procedure | SELECT |
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Procedure | SELECT |
| Trade.GetMirrorOrderIdForSSEDetach | Procedure | SELECT |
| Trade.GetOpenOrdersForCloseMirror | Procedure | SELECT |
| Trade.GetUserInstrumentIdsOnly | Procedure | SELECT |
| Trade.DelayedOrdersOvernight | Procedure | SELECT |
| History.DelayedOrderForOpen | Table | MERGE archive target |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__Trade_DelayedOrderForOpen_RequestIdentifier | NC HASH PK | RequestIdentifier (BUCKET_COUNT=65536) | - | - | Active |
| IDX_CID | NC | CID | - | - | Active |
| IDX_LastUpdate | NC HASH | LastUpdate (BUCKET_COUNT=65536) | - | - | Active |
| IDX_OrderID | NC HASH | OrderID (BUCKET_COUNT=65536) | - | - | Active |
| IDX_OrderID_StatusID | NC | OrderID, StatusID | - | - | Active |
| IDX_StatusID | NC HASH | StatusID (BUCKET_COUNT=8) | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK__Trade_DelayedOrderForOpen_RequestIdentifier | PRIMARY KEY (HASH) | Unique RequestIdentifier |
| DF_RootHedgeServerID | DEFAULT | RootHedgeServerID = 0 |

**Special**: `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA` — In-memory for low-latency order matching.

---

## 8. Sample Queries

### 8.1 Get pending delayed open orders with status name
```sql
SELECT d.RequestIdentifier, d.OrderID, d.CID, d.InstrumentID, d.Amount, d.IsBuy, d.Leverage,
       d.RequestOccurred, d.LastUpdate, dos.StatusName
  FROM Trade.DelayedOrderForOpen d WITH (NOLOCK)
  JOIN Dictionary.DelayedOrderStatus dos WITH (NOLOCK) ON d.StatusID = dos.StatusID
 WHERE d.StatusID = 1
 ORDER BY d.RequestOccurred DESC
```

### 8.2 Count delayed open orders by status
```sql
SELECT dos.StatusName, COUNT(*) AS Cnt
  FROM Trade.DelayedOrderForOpen d WITH (NOLOCK)
  JOIN Dictionary.DelayedOrderStatus dos WITH (NOLOCK) ON d.StatusID = dos.StatusID
 GROUP BY dos.StatusName
```

### 8.3 Delayed open orders for a customer with instrument and mirror
```sql
SELECT d.RequestIdentifier, d.OrderID, d.InstrumentID, d.Amount, d.MirrorID, d.ParentPositionID,
       i.BuyCurrencyID, i.SellCurrencyID, d.RequestOccurred
  FROM Trade.DelayedOrderForOpen d WITH (NOLOCK)
  LEFT JOIN Trade.Instrument i WITH (NOLOCK) ON d.InstrumentID = i.InstrumentID
 WHERE d.CID = 9263423
   AND d.StatusID = 1
 ORDER BY d.RequestOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Procedures*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12+ analyzed | Live rows: 0 | Corrections: 0 applied*
*Object: Trade.DelayedOrderForOpen | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.DelayedOrderForOpen.sql*
