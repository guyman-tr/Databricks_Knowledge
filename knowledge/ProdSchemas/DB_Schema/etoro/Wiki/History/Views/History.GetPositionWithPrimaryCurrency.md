# History.GetPositionWithPrimaryCurrency

> Position view that resolves the primary settlement currency for each closed position based on the game type - returns 7 columns from History.Position joined with History.ForexResult and Game.ForexGame, computing PrimaryCurrencyID via a scalar function for MAP/ROPE game subtypes and natively from Game.ForexGame for other types. Used by position editing, position open/close procedures, and monitoring.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.GetPositionWithPrimaryCurrency provides the **primary settlement currency** for each closed position. The primary currency determines how profits and losses are denominated and converted - it varies by game type and instrument direction.

In eToro's position lifecycle, when computing P&L or fees, the system needs to know which currency is "primary" for the position. For most game types this is a static property of the game (stored in Game.ForexGame.PrimaryCurrencyID). For two special game subtypes - MAP (GameSubTypeID=4) and ROPE (GameSubTypeID=6) - the primary currency is direction-dependent and computed dynamically via `Internal.GetPrimaryCurrencyForMapAndRope(InstrumentID, IsBuy, PrimaryCurrencyDirection)`.

The view is compact (7 columns) and is used as a subquery or JOIN source by procedures that need to retrieve the primary currency context for a position without loading the full 124-column History.Position schema.

The view appears in 14 procedure files spanning Trade operations (PositionOpen, PositionEditTakeProfit, DetachFromParentPosition, PostOpenPositionActions, PostEditStopLossPosition, ClaimEndOfWeekFee, GetPriceLatency, PositionAdjustment) and monitoring (PR_Dashboard_ORG, PR_Report_FailDashbordNew).

---

## 2. Business Logic

### 2.1 PrimaryCurrencyID Computation

**What**: The primary currency is resolved differently for MAP/ROPE game subtypes vs. all others.

**Columns/Parameters Involved**: `PrimaryCurrencyID`, `GameSubTypeID`, `IsBuy`, `PrimaryCurrencyDirection`

**Rules**:
```sql
CASE GFXG.GameSubTypeID
  WHEN 4 THEN Internal.GetPrimaryCurrencyForMapAndRope(HPOS.InstrumentID, HPOS.IsBuy, HFXR.PrimaryCurrencyDirection)  -- MAP
  WHEN 6 THEN Internal.GetPrimaryCurrencyForMapAndRope(HPOS.InstrumentID, HPOS.IsBuy, HFXR.PrimaryCurrencyDirection)  -- ROPE
  ELSE GFXG.PrimaryCurrencyID
END AS PrimaryCurrencyID
```
- GameSubTypeID = 4 (MAP) or 6 (ROPE): scalar UDF call - currency depends on instrument, direction, and the PrimaryCurrencyDirection from the ForexResult
- All other game subtypes: use Game.ForexGame.PrimaryCurrencyID directly - static per game

### 2.2 Join Path (Position -> ForexResult -> ForexGame)

**What**: Three-way join resolves the game context for each position.

**Columns/Parameters Involved**: `ForexResultID`, `ForexGameID`, `GameSubTypeID`, `PrimaryCurrencyDirection`

**Rules**:
- History.Position.ForexResultID -> History.ForexResult.ForexResultID: links position to its game result record
- History.ForexResult.ForexGameID -> Game.ForexGame.ForexGameID: links game result to the game configuration
- History.ForexResult provides PrimaryCurrencyDirection (direction-aware currency info for MAP/ROPE)
- Game.ForexGame provides GameSubTypeID and static PrimaryCurrencyID

---

## 3. Data Overview

7-column output per closed position with primary currency context:

| ForexResultID | PositionID | InstrumentID | PrimaryCurrencyID | NetProfit | Leverage | LotCountDecimal |
|--------------|------------|-------------|-------------------|-----------|----------|----------------|
| (varies) | 2152976743 | 100000 (BTC) | (USD=1 or other) | varies | varies | varies |

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ForexResultID | int | YES | CODE-BACKED | Game result ID from History.Position. Links to History.ForexResult. |
| 2 | PositionID | bigint | NO | CODE-BACKED | Position identifier. |
| 3 | InstrumentID | int | NO | CODE-BACKED | Traded instrument. Used as input to Internal.GetPrimaryCurrencyForMapAndRope for MAP/ROPE positions. |
| 4 | PrimaryCurrencyID | int | YES | CODE-BACKED | Settlement currency ID. For MAP/ROPE: computed by Internal.GetPrimaryCurrencyForMapAndRope(InstrumentID, IsBuy, PrimaryCurrencyDirection). For other types: Game.ForexGame.PrimaryCurrencyID. FK to Dictionary.Currency (implied). |
| 5 | NetProfit | money | YES | CODE-BACKED | Position net P&L in USD. |
| 6 | Leverage | int | YES | CODE-BACKED | Position leverage multiplier. |
| 7 | LotCountDecimal | decimal(16,6) | YES | CODE-BACKED | Position lot count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | History.Position | View (source) | All closed positions |
| ForexResultID | History.ForexResult | INNER JOIN (implicit WHERE) | Game result for this position |
| ForexGameID | Game.ForexGame | INNER JOIN (implicit WHERE) | Game configuration (type and primary currency) |
| PrimaryCurrencyID (MAP/ROPE) | Internal.GetPrimaryCurrencyForMapAndRope | Scalar function call | Direction-dependent primary currency |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpen | PositionID/PrimaryCurrencyID | Read | Open position currency context |
| Trade.PositionEditTakeProfit | PositionID/PrimaryCurrencyID | Read | Edit take profit currency context |
| Trade.PositionEditTakeProfit25102021 | PositionID/PrimaryCurrencyID | Read | TP edit variant |
| Trade.PostEditStopLossPosition | PositionID/PrimaryCurrencyID | Read | Post-SL edit currency context |
| Trade.PostOpenPositionActions | PositionID/PrimaryCurrencyID | Read | Post-open currency context |
| Trade.DetachFromParentPosition | PositionID/PrimaryCurrencyID | Read | Detach operation currency context |
| Trade.ClaimEndOfWeekFee | PositionID/PrimaryCurrencyID | Read | EOW fee currency |
| Trade.GetPriceLatency | PositionID/PrimaryCurrencyID | Read | Price latency monitoring |
| Trade.PositionAdjustment | PositionID/PrimaryCurrencyID | Read | Position data fix operations |
| Trade.GetRealEditSLMMRecovery | PositionID/PrimaryCurrencyID | Read | SL/MM recovery view |
| Trade.PositionChange | PositionID/PrimaryCurrencyID | Read | Position change view |
| History.GetForexResult | PositionID/PrimaryCurrencyID | Read | Forex result enrichment |
| dbo.PR_Dashboard_ORG | PositionID | Read (report) | ORG dashboard |
| dbo.PR_Report_FailDashbordNew | PositionID | Read (report) | Failure dashboard |

---

## 6. Dependencies

```
History.GetPositionWithPrimaryCurrency (view)
|- History.Position (view - full position history)
|- History.ForexResult (table - game results with PrimaryCurrencyDirection)
|- Game.ForexGame (table - cross-schema, game configuration)
+- Internal.GetPrimaryCurrencyForMapAndRope (scalar function - MAP/ROPE currency computation)
```

---

## 8. Sample Queries

### 8.1 Get primary currency for a customer's recent positions
```sql
SELECT
    gpwpc.PositionID,
    gpwpc.InstrumentID,
    gpwpc.PrimaryCurrencyID,
    gpwpc.NetProfit,
    gpwpc.Leverage
FROM History.GetPositionWithPrimaryCurrency gpwpc WITH (NOLOCK)
WHERE gpwpc.PositionID IN (
    SELECT PositionID FROM History.Position_Active WHERE CID = 14952810
)
ORDER BY gpwpc.PositionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for History.GetPositionWithPrimaryCurrency.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.6/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 14 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetPositionWithPrimaryCurrency | Type: View | Source: etoro/etoro/History/Views/History.GetPositionWithPrimaryCurrency.sql*
