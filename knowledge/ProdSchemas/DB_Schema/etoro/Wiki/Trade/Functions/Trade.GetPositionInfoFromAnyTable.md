# Trade.GetPositionInfoFromAnyTable

> Inline table-valued function that returns a unified view of position data from both current (Trade.Position) and historical (History.Position) tables. Essential utility for queries that need open and closed positions in a single result set.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline TVF |
| **Key Identifier** | PositionID (returned column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetPositionInfoFromAnyTable provides a unified view over all positions—open and closed—by UNIONing Trade.Position (current live positions) with History.Position (closed positions moved to history). Each returned row represents one position with normalized columns: instrument, direction, SL/TP rates, open/close times, close action type, PnL, and copy-trade linkage (ParentPositionID, MirrorID).

This function exists because the eToro trading engine splits live positions (Trade.Position/PositionTbl) from historical positions (History.Position) for performance and partitioning. Applications often need both in a single query—e.g., BackOffice.JUNK_CashierHistory joins to this function to reconcile position history with cashier operations. Without it, every consumer would have to manually UNION the two tables and normalize the schema differences (e.g., ActionType vs CloseAction label).

Data flows: The function is parameterless. Callers use `Trade.GetPositionInfoFromAnyTable()` in FROM/JOIN. Open positions come from Trade.Position with IsOpened=1, CloseServerTime=NULL, CloseAction=NULL. Closed positions come from History.Position with IsOpened=0, CloseServerTime/CloseAction populated, and ActionType mapped to human-readable labels (REGULAR, DB AUTO STOP LOSS, END OF WEEK, etc.).

---

## 2. Business Logic

### 2.1 Open vs Closed Position Discrimination

**What**: The function distinguishes open positions (live) from closed positions (historical) via IsOpened and nullability of close columns.

**Columns/Parameters Involved**: `IsOpened`, `CloseServerTime`, `CloseAction`, `EndForexRate`

**Rules**:
- IsOpened: 1 = from Trade.Position (live), 0 = from History.Position (closed).
- For open positions: EndForexRate, CloseServerTime, CloseAction are NULL; EndForexPriceRateID=0.
- For closed positions: EndForexRate, CloseOccurred (as CloseServerTime), CloseAction (mapped from ActionType) are populated.
- InitServerTime: from Occurred (open) or OpenOccurred (closed).

### 2.2 Close Action Type Mapping

**What**: History.Position.ActionType (integer) is mapped to human-readable labels for consistency.

**Columns/Parameters Involved**: `CloseAction`, `ActionType`

**Rules**:
- ActionType 0 → 'REGULAR'; 1 → 'DB AUTO STOP LOSS'; 2 → 'END OF WEEK'; 3 → 'SERVER AUTO STOP LOSS'; 4 → 'RETURN TO MARKET'; 5 → 'DB AUTO TAKE PROFIT'; 6 → 'SERVER AUTO TAKE PROFIT'; 7 → 'REGULAR WITHOUT HEDGING'.
- See [Close Position Action Type](_glossary.md#close-position-action-type) for full definitions.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary identifier from Trade.Position or History.Position. Unique per position. |
| 2 | IsOpened | int | NO | - | CODE-BACKED | 1 = open position (from Trade.Position), 0 = closed (from History.Position). |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Financial instrument of the position. |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | 1 = Long/Buy, 0 = Short/Sell. Inherited from base tables. |
| 5 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit trigger price. From PositionTreeInfo via base position. |
| 6 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss trigger price. From PositionTreeInfo via base position. |
| 7 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Opening price at position open. |
| 8 | EndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Closing price. NULL for open positions. |
| 9 | InitServerTime | datetime | YES | - | CODE-BACKED | When position opened. Sourced from Occurred (open) or OpenOccurred (closed). |
| 10 | CloseServerTime | datetime | YES | - | CODE-BACKED | When position closed. NULL for open positions. From CloseOccurred. |
| 11 | CloseAction | varchar | YES | - | CODE-BACKED | Human-readable close reason: REGULAR, DB AUTO STOP LOSS, END OF WEEK, SERVER AUTO STOP LOSS, RETURN TO MARKET, DB AUTO TAKE PROFIT, SERVER AUTO TAKE PROFIT, REGULAR WITHOUT HEDGING. NULL for open. |
| 12 | NetProfit | money | NO | - | CODE-BACKED | Realized PnL. 0 when open; set on close. |
| 13 | OrderID | int | YES | - | CODE-BACKED | Originating order reference. FK to Trade.Orders. |
| 14 | InitForexPriceRateID | bigint | NO | - | CODE-BACKED | Price rate ID at open. References Trade.CurrencyPrice. |
| 15 | EndForexPriceRateID | bigint | NO | - | CODE-BACKED | Price rate ID at close. 0 for open positions. |
| 16 | OrderPriceRateID | bigint | NO | - | CODE-BACKED | Order execution price rate ID. |
| 17 | OrderPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | Order execution rate. |
| 18 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate ID at open. |
| 19 | MarketPriceRate | dbo.dtPrice | YES | - | CODE-BACKED | Market rate at open. |
| 20 | ParentPositionID | bigint | YES | - | CODE-BACKED | Copy-trade parent. 0/1 = root; positive = child of referenced position. |
| 21 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before detachment. |
| 22 | MirrorID | int | YES | - | CODE-BACKED | FK to Trade.Mirror. 0/NULL = manual; positive = copy-trade position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Traded instrument. |
| OrderID | Trade.Orders | Implicit | Originating order. |
| ParentPositionID | Trade.PositionTbl | Implicit | Copy-trade parent position. |
| MirrorID | Trade.Mirror | Implicit | Copy-trade relationship. |
| InitForexPriceRateID, EndForexPriceRateID | Trade.CurrencyPrice | Implicit | Price rate records. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.JUNK_CashierHistory | FROM/JOIN | Reader | Joins for position-instrument reconciliation. |
| Dealing | GRANT SELECT | Permission | Role can SELECT from function. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionInfoFromAnyTable (function)
├── Trade.Position (view)
│     └── Trade.PositionTbl (table)
└── History.Position (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | FROM — open positions (wraps PositionTbl) |
| History.Position | Table | FROM — closed positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_CashierHistory | View | FROM/JOIN |
| Dealing | Role | GRANT SELECT |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all positions (open + closed) for a customer
```sql
SELECT   PositionID, IsOpened, InstrumentID, IsBuy, InitForexRate, EndForexRate,
         InitServerTime, CloseServerTime, CloseAction, NetProfit, MirrorID
FROM     Trade.GetPositionInfoFromAnyTable() HPOS WITH (NOLOCK)
WHERE    HPOS.PositionID IN (
           SELECT PositionID FROM Trade.PositionTbl WITH (NOLOCK) WHERE CID = 14952810
           UNION
           SELECT PositionID FROM History.Position WITH (NOLOCK) WHERE CID = 14952810
         )
ORDER BY InitServerTime DESC;
```

### 8.2 Join to instrument names for position history
```sql
SELECT   HPOS.PositionID, HPOS.InstrumentID, HPOS.IsOpened, HPOS.IsBuy,
         HPOS.InitForexRate, HPOS.EndForexRate, HPOS.CloseAction, HPOS.NetProfit,
         I.InstrumentDisplayName
FROM     Trade.GetPositionInfoFromAnyTable() HPOS WITH (NOLOCK)
         INNER JOIN Trade.Instrument I WITH (NOLOCK) ON HPOS.InstrumentID = I.InstrumentID
WHERE    HPOS.InitServerTime >= DATEADD(day, -30, GETUTCDATE())
ORDER BY HPOS.InitServerTime DESC;
```

### 8.3 Closed positions with close action breakdown
```sql
SELECT   HPOS.CloseAction,
         COUNT(*) AS PositionCount,
         SUM(HPOS.NetProfit) AS TotalPnL
FROM     Trade.GetPositionInfoFromAnyTable() HPOS WITH (NOLOCK)
WHERE    HPOS.IsOpened = 0
         AND HPOS.CloseServerTime >= DATEADD(month, -1, GETUTCDATE())
GROUP BY HPOS.CloseAction
ORDER BY PositionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetPositionInfoFromAnyTable | Type: Inline TVF | Source: etoro/etoro/Trade/Functions/Trade.GetPositionInfoFromAnyTable.sql*
