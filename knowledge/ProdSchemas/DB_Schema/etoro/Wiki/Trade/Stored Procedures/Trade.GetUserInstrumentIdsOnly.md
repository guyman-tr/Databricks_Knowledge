# Trade.GetUserInstrumentIdsOnly

> Lightweight instrument ID collector for UserInstrumentIdsService - returns the distinct set of InstrumentIDs a customer is exposed to via open positions and non-terminal orders, without any position or order detail. ~20x faster than GetPortfolioAggregates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer whose instruments are collected |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserInstrumentIdsOnly` is a purpose-built performance optimization introduced on 2026-02-03 by the Trading Team for the `UserInstrumentIdsService`. Its sole purpose is to answer: "which instruments does this customer currently have exposure to?" - returning only distinct InstrumentIDs with no position amounts, rates, or details.

The DDL comment documents the rationale: GetPortfolioAggregates answers the same exposure question but returns all position and order detail (~20x slower). This SP reuses the same table access patterns as GetPortfolioAggregates (lines 18-50, 140-169) but returns only a UNION of distinct InstrumentIDs.

The three sources combined are:
- `Trade.Orders` - pending/placed orders
- `Trade.OrderForOpen` with non-terminal status filter - open orders in the execution pipeline
- `Trade.DelayedOrderForOpen` with StatusID=1 - delayed/conditional open orders
- `Trade.PositionTbl` with StatusID=1 - open positions

---

## 2. Business Logic

### 2.1 Three-Source Order CTE + Position CTE

**What**: Collects InstrumentIDs from all order and position sources, then deduplicates.

**Sources**:
- `AllOpenOrders` CTE (UNION ALL of 3 order sources):
  1. `Trade.Orders WHERE CID=@CID` - all orders for the customer
  2. `Trade.OrderForOpen WHERE CID=@CID AND IsTerminal=0` (via Dictionary.OrderForExecutionStatus) - non-terminal open orders
  3. `Trade.DelayedOrderForOpen WHERE CID=@CID AND StatusID=1` - active delayed orders

- `AllPositions` CTE:
  - `Trade.PositionTbl WHERE CID=@CID AND StatusID=1` - open positions (no partition filter since CID is used, not PositionID)

**Deduplication**: Final `SELECT InstrumentID FROM AllOpenOrders UNION SELECT InstrumentID FROM AllPositions` - UNION (not UNION ALL) deduplicates across all sources.

### 2.2 Non-Terminal Order Filter

**What**: Includes only orders that are still active in the execution pipeline.

**Rules**:
- `JOIN Dictionary.OrderForExecutionStatus dofe ON oo.StatusID = dofe.ID WHERE dofe.IsTerminal = 0`
- Terminal orders (cancelled, filled, rejected) are excluded
- Matches the pattern used in GetTreeNodesByParentPositionAndTreeId pending close detection

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose instrument exposure is returned. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Distinct instrument ID from any open position or non-terminal order. FK to Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AllOpenOrders CTE | Trade.Orders | FROM | All orders for the customer |
| AllOpenOrders CTE | Trade.OrderForOpen | FROM | Non-terminal open orders |
| AllOpenOrders CTE | Dictionary.OrderForExecutionStatus | JOIN | Terminal status filter |
| AllOpenOrders CTE | Trade.DelayedOrderForOpen | FROM | Active delayed open orders |
| AllPositions CTE | Trade.PositionTbl | FROM | Open positions (StatusID=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| UserInstrumentIdsService | @CID | EXEC caller | Service that tracks customer instrument exposure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserInstrumentIdsOnly (procedure)
+-- Trade.Orders (table)
+-- Trade.OrderForOpen (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Trade.DelayedOrderForOpen (table)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Order InstrumentIDs |
| Trade.OrderForOpen | Table | Non-terminal open order InstrumentIDs |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal filter for OrderForOpen |
| Trade.DelayedOrderForOpen | Table | Delayed open order InstrumentIDs |
| Trade.PositionTbl | Table | Open position InstrumentIDs |

### 6.2 Objects That Depend On This

No documented dependents. Called by UserInstrumentIdsService application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation | All four table reads use NOLOCK for performance |
| UNION (not UNION ALL) | Deduplication | Final result is DISTINCT across all sources |
| StatusID=1 (PositionTbl) | Filter | Open positions only |
| StatusID=1 (DelayedOrderForOpen) | Filter | Active delayed orders only |
| IsTerminal=0 (OrderForOpen) | Filter | Non-terminal orders only |

---

## 8. Sample Queries

### 8.1 Get all instrument IDs for a customer
```sql
EXEC Trade.GetUserInstrumentIdsOnly @CID = 123456
```

### 8.2 Verify coverage across all sources
```sql
-- Check what each source contributes
SELECT 'Trade.Orders' AS Source, InstrumentID FROM Trade.Orders WITH (NOLOCK) WHERE CID = 123456
UNION
SELECT 'Trade.OrderForOpen', oo.InstrumentID
FROM Trade.OrderForOpen oo WITH (NOLOCK)
JOIN Dictionary.OrderForExecutionStatus dofe WITH (NOLOCK) ON oo.StatusID = dofe.ID
WHERE oo.CID = 123456 AND dofe.IsTerminal = 0
UNION
SELECT 'Trade.DelayedOrderForOpen', InstrumentID FROM Trade.DelayedOrderForOpen WITH (NOLOCK) WHERE CID = 123456 AND StatusID = 1
UNION
SELECT 'Trade.PositionTbl', InstrumentID FROM Trade.PositionTbl WITH (NOLOCK) WHERE CID = 123456 AND StatusID = 1
```

### 8.3 Compare speed vs GetPortfolioAggregates
```sql
SET STATISTICS TIME ON;
EXEC Trade.GetUserInstrumentIdsOnly @CID = 123456;  -- Fast: IDs only
-- vs
EXEC Trade.GetPortfolioAggregates @CID = 123456;    -- Full detail (~20x slower)
SET STATISTICS TIME OFF;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Recent SP (2026-02-03) not yet in the Confluence documentation system.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserInstrumentIdsOnly | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserInstrumentIdsOnly.sql*
