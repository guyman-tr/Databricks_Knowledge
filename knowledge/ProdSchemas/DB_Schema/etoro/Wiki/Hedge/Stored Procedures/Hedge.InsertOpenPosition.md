# Hedge.InsertOpenPosition

> Inserts a single open position record into CustomerOpenPositions_New (via synonym to the [Real] linked server), computing the commission from active Trade.PositionTbl rows for the given server and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.SynCustomerOpenPositions_New (synonym -> [Real].[etoro].[Hedge].[CustomerOpenPositions_New]) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.InsertOpenPosition` creates a single open position record in the CustomerOpenPositions_New table for a given (HedgeServerID, InstrumentID) combination, inserting the provided market data (unrealized P&L, buy/sell units, price rate) along with a live-computed commission sum.

The procedure is a hybrid: it computes `CommissionOnOpen` on the fly by summing `Trade.PositionTbl.Commission` for all open positions (StatusID=1) for the given server and instrument, then inserts the composite row. `NetOpenInUSD` is hardcoded to 0 at insert time (likely updated or computed separately).

The write target, `Hedge.SynCustomerOpenPositions_New`, is a synonym pointing to `[Real].[etoro].[Hedge].[CustomerOpenPositions_New]`. The "Real" linked server in this context is the write destination (primary database), following the same cross-server write pattern used by other Hedge procedures (e.g., InsertKPIData writing to [AO-REAL-DB] via RW_ synonyms). The HedgeCostService database role holds EXECUTE permission on this procedure.

---

## 2. Business Logic

### 2.1 Live Commission Aggregation

**What**: CommissionOnOpen is computed at INSERT time from current active positions.

**Columns/Parameters Involved**: `@HedgeServerID`, `@InstrumentID`, `CommissionOnOpen`

**Rules**:
- `SELECT SUM(TP.Commission) FROM Trade.PositionTbl WHERE InstrumentID = @InstrumentID AND HedgeServerID = @HedgeServerID AND StatusID = 1`
- StatusID=1 = open positions (active customer positions on this server/instrument).
- ISNULL(..., 0): if no open positions exist, CommissionOnOpen defaults to 0.
- This aggregation provides the total commission accrued on all current open positions for the instrument, snapshotted at the moment of insert.

### 2.2 NetOpenInUSD Placeholder

**What**: NetOpenInUSD is always inserted as 0.

**Columns/Parameters Involved**: `NetOpenInUSD`

**Rules**:
- Hardcoded to 0 in the INSERT VALUES clause.
- This column likely represents the net open exposure in USD and is expected to be updated separately or computed at query time by the consuming system.

**Diagram**:
```
Caller provides:
  @HedgeServerID, @InstrumentID, @UnrealizedPL,
  @OpenBuyUnits, @OpenSellUnits, @PriceRateID
          |
          | SELECT SUM(Commission) FROM Trade.PositionTbl
          | WHERE InstrumentID=@InstrumentID AND HedgeServerID=@HedgeServerID AND StatusID=1
          v
@Commission = (computed)
          |
          | INSERT INTO Hedge.SynCustomerOpenPositions_New
          | (HedgeServerID, InstrumentID, UnrealizedPL, OpenedBuyUnits, OpenedSellUnits,
          |  PriceRateID, CommissionOnOpen, NetOpenInUSD=0)
          v
Row committed to [Real].[etoro].[Hedge].[CustomerOpenPositions_New]
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server this open position record belongs to. Used as filter key in the commission SELECT from Trade.PositionTbl and as the HedgeServerID in the INSERT. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | The financial instrument for this open position. Used as filter key in the commission SELECT and stored in the output row. |
| 3 | @UnrealizedPL | DECIMAL | NO | - | CODE-BACKED | Current unrealized profit/loss for the open position. Stored as UnrealizedPL in CustomerOpenPositions_New. Represents the mark-to-market P&L at the time of the snapshot. |
| 4 | @OpenBuyUnits | INT | NO | - | CODE-BACKED | Total open buy units for this server/instrument combination. Stored as OpenedBuyUnits. Long position volume currently held by the hedge account. |
| 5 | @OpenSellUnits | INT | NO | - | CODE-BACKED | Total open sell units for this server/instrument combination. Stored as OpenedSellUnits. Short position volume currently held by the hedge account. |
| 6 | @PriceRateID | BIGINT | NO | - | CODE-BACKED | Reference to the price rate used for the position valuation. Stored as PriceRateID. Links to the specific price snapshot used when this open position record was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.PositionTbl | READ (NOLOCK) | Reads SUM(Commission) for open positions (StatusID=1) per server/instrument |
| - | Hedge.SynCustomerOpenPositions_New | Writer (INSERT via synonym) | Inserts one open position snapshot row to [Real].[etoro].[Hedge].[CustomerOpenPositions_New] |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. HedgeCostService database role holds EXECUTE permission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InsertOpenPosition (procedure)
|-- Trade.PositionTbl (table) [READ - commission sum for open positions]
+-- Hedge.SynCustomerOpenPositions_New (synonym) [INSERT - open position snapshot]
    +-- [Real].[etoro].[Hedge].[CustomerOpenPositions_New] (external table - [Real] server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Reads SUM(Commission) for active open positions (StatusID=1) per HedgeServerID + InstrumentID |
| Hedge.SynCustomerOpenPositions_New | Synonym | Write target - routes INSERT to [Real].[etoro].[Hedge].[CustomerOpenPositions_New] |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from HedgeCostService application. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(..., 0) | NULL guard | If no open positions exist for the server/instrument, CommissionOnOpen defaults to 0 instead of NULL. |
| NetOpenInUSD = 0 | Placeholder | Net open exposure in USD is hardcoded to 0 at insert. Expected to be computed/updated by downstream process. |

---

## 8. Sample Queries

### 8.1 Execute for a server/instrument with a known price rate
```sql
EXEC [Hedge].[InsertOpenPosition]
    @HedgeServerID  = 1,
    @InstrumentID   = 1,
    @UnrealizedPL   = 1500.50,
    @OpenBuyUnits   = 100000,
    @OpenSellUnits  = 0,
    @PriceRateID    = 9999999
```

### 8.2 Check current commission that would be inserted for a server/instrument
```sql
SELECT SUM(Commission) AS CommissionOnOpen
FROM [Trade].[PositionTbl] WITH (NOLOCK)
WHERE InstrumentID = 1
  AND HedgeServerID = 1
  AND StatusID = 1
```

### 8.3 Verify recent open position records via synonym
```sql
SELECT TOP 10 *
FROM [Hedge].[SynCustomerOpenPositions_New] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InsertOpenPosition | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.InsertOpenPosition.sql*
