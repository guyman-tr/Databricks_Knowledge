# Trade.GetMirrorNonStocksPositions

> Returns all open, copy-trade positions for a specified Mirror, joining instrument and tree settings to provide a full position snapshot used by the mirror (CopyTrader) system. Despite its name, it returns ALL instrument types including stocks.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - filters to one mirror's open copy positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorNonStocksPositions` retrieves all currently open positions belonging to a specific CopyTrader mirror (identified by `@MirrorID`). It returns child positions only (`ParentPositionID > 0`), meaning copier positions that were opened as part of following a leader. For each position it joins `Trade.Instrument` for forex currency IDs, `Trade.ProviderToInstrument` for unit/precision configuration, and `Trade.PositionTreeInfo` for stop-loss and take-profit rates.

The procedure exists to support the CopyTrader mirror management flow. When a mirror needs to know what positions its copiers currently hold - for example, to synchronise leader/copier state or to process a mirror-level action such as portfolio rebalancing or detachment - this is the primary read path. It is invoked by the mirror management layer to get a consistent snapshot of all open copy positions routed through the mirror.

**Important naming caveat**: The name "NonStocks" is a legacy artifact. A code comment explains: "The procedure shows also stocks. It got its name at the time that the regular trading system did not work with stocks. Currently it gets all positions that have value of 1 at `Enabled` column in `Trade.ProviderToInstrument`." The only active filter is `TP2I.Enabled = 1` (instrument enabled for that provider) plus `StatusID = 1` (open). All instrument types are included.

---

## 2. Business Logic

### 2.1 Filter: Copy-Trade Positions Only

**What**: Only positions that are children in a copy-trade tree (not root/manual trades).

**Columns/Parameters Involved**: `ParentPositionID`, `MirrorID`, `StatusID`

**Rules**:
- `ParentPositionID > 0`: Only copier positions. Root/manual positions have `ParentPositionID = 0`.
- `MirrorID = @MirrorID`: Scoped to a single mirror.
- `StatusID = 1`: Open positions only. Code comment confirms: "StatusID = 1 Indicates whether the position is still open."
- `TP2I.Enabled = 1`: Instrument must be active/enabled in the provider-instrument configuration.

**Diagram**:
```
Trade.PositionTbl
  WHERE StatusID = 1 (open)
    AND MirrorID = @MirrorID
    AND ParentPositionID > 0 (copier child)
    AND TP2I.Enabled = 1 (active instrument)
       |
       |-- JOIN Trade.Instrument         (forex buy/sell currency IDs)
       |-- JOIN Trade.ProviderToInstrument (Unit, Precision)
       |-- JOIN Trade.PositionTreeInfo    (LimitRate, StopRate, CloseOnEndOfWeek)
       |
       v
  Full position snapshot for mirror management
```

### 2.2 Legacy Name vs. Actual Behavior

**What**: The procedure name implies stock exclusion but this was removed in 2015.

**Columns/Parameters Involved**: `InstrumentID` (implicitly all values)

**Rules**:
- Originally added `InstrumentID < 1000` filter (stocks had IDs >= 1000 at the time). This filter was removed/commented out.
- FB 24690 (07-01-2015): Modified stock detection approach - instruments are now identified via `TP2I.Enabled` flag, not InstrumentID ranges.
- FB 52337 (19-08-2018): Added `StatusID` condition to support async close position flow.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier to filter positions. All returned positions have `Trade.PositionTbl.MirrorID = @MirrorID`. Corresponds to a row in `Trade.Mirror`. Scopes the result to one CopyTrader portfolio. |

**Output columns** (result set - all sourced from joined tables):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Trade.PositionTbl | Customer ID of the copier who owns this position. |
| 2 | PositionID | Trade.PositionTbl | Unique position identifier (BIGINT). |
| 3 | ForexResultID | Trade.PositionTbl | Instrument ID for the forex result currency pair used in PnL conversion. |
| 4 | IsOpened | Hardcoded | Always 1 (open). All returned positions have StatusID=1. |
| 5 | Currency | Trade.PositionTbl.CurrencyID | The account denomination currency ID for this position. |
| 6 | ProviderID | Trade.PositionTbl | Execution provider routing this position. |
| 7 | InstrumentID | Trade.PositionTbl | The traded instrument. |
| 8 | PositionHedgeServerID | Trade.PositionTbl.HedgeServerID | Hedge server assigned to this position. |
| 9 | Leverage | Trade.PositionTbl | Leverage multiplier applied to this position. |
| 10 | ForexBuy | Trade.Instrument.BuyCurrencyID | Buy-side currency of the instrument's forex pair. |
| 11 | ForexSell | Trade.Instrument.SellCurrencyID | Sell-side currency of the instrument's forex pair. |
| 12 | InitForexRate | Trade.PositionTbl | Opening forex conversion rate at position open. |
| 13 | EndForexRate | NULL | Always NULL - position is open, no closing forex rate yet. |
| 14 | InitDateTime | Trade.PositionTbl | Timestamp when the position was opened. |
| 15 | EndDateTime | NULL | Always NULL - position is open. |
| 16 | ActionType | NULL | Always NULL - position is open, no close action type. |
| 17 | NetProfit | NULL | Always NULL - position is open, PnL not yet realized. |
| 18 | LimitRate | Trade.PositionTreeInfo | Take-profit rate. When price reaches this level, position auto-closes. From the copy-trade tree's shared settings. |
| 19 | StopRate | Trade.PositionTreeInfo | Stop-loss rate. When price drops to this level, position auto-closes. From the copy-trade tree's shared settings. |
| 20 | Amount | Trade.PositionTbl | Position size in account currency (dollars). |
| 21 | AmountInUnitsDecimal | Trade.PositionTbl | Position size expressed in instrument units (e.g., shares, barrels). |
| 22 | Commission | Trade.PositionTbl | Opening commission charged on this position. |
| 23 | SpreadedCommission | Trade.PositionTbl | Spread-based commission component. |
| 24 | IsBuy | CASE on Trade.PositionTbl.IsBuy | Direction as string: 'true' = Buy/Long, 'false' = Sell/Short. |
| 25 | CloseOnEndOfWeek | CASE on Trade.PositionTreeInfo.CloseOnEndOfWeek | Weekend close flag as string: 'true' = will auto-close on Friday. |
| 26 | EndOfWeekFee | Trade.PositionTbl | Accumulated weekend rollover fee. |
| 27 | LotCountDecimal | Trade.PositionTbl | Position size in lots (units / instrument lot size). |
| 28 | AdditionalParam | Trade.PositionTbl | Additional parameters field for special instrument configurations. |
| 29 | OpenOccurred | Trade.PositionTbl.Occurred | Timestamp when the open was processed by the trade engine. |
| 30 | CloseOccurred | NULL | Always NULL - position is open. |
| 31 | OrderID | Trade.PositionTbl | The originating order ID that created this position. |
| 32 | TradeRange | Trade.PositionTbl | Market range allowed at open (slippage tolerance). |
| 33 | InitForexPriceRateID | Trade.PositionTbl | Rate ID for the opening forex price, used for historical rate lookup. |
| 34 | ParentPositionID | Trade.PositionTbl | The leader's position ID from which this copier position was cloned. Always > 0 (filter guarantee). |
| 35 | OrigParentPositionID | Trade.PositionTbl | Original parent position ID before any re-parenting (e.g., detach/re-attach flows). |
| 36 | LastOpPriceRate | Trade.PositionTbl | Rate at the last operation on this position (e.g., last partial close or edit). |
| 37 | LastOpPriceRateID | Trade.PositionTbl | Rate ID for the last operation price. |
| 38 | LastOpConversionRate | Trade.PositionTbl | Conversion rate at the last operation. |
| 39 | LastOpConversionRateID | Trade.PositionTbl | Rate ID for the last operation conversion rate. |
| 40 | UnitMargin | Trade.PositionTbl | Margin required per unit of this position. |
| 41 | Units | Trade.ProviderToInstrument.Unit | Lot size for this instrument at this provider (units per lot). |
| 42 | InstrumentPrecision | Trade.ProviderToInstrument.Precision | Decimal precision for price display/calculation for this instrument. |
| 43 | MirrorID | Trade.PositionTbl | The mirror ID (same as @MirrorID parameter). |
| 44 | PositionRatio | Trade.PositionTbl | Ratio of copier's investment vs. leader's investment. Controls proportional sizing. |
| 45 | DirectAggLotCount | Trade.PositionTbl | Direct aggregate lot count for hedge routing. |
| 46 | SpreadGroupID | Trade.PositionTbl | Spread group assigned to this position, determining spread tier. |
| 47 | InitialAmountCents | Trade.PositionTbl | Opening position size in cents. Used alongside Amount (dollars). |
| 48 | HedgeServerID | Trade.PositionTbl | Repeated alias of PositionHedgeServerID - same HedgeServerID column. |
| 49 | InitExecutionID | Trade.PositionTbl | Execution ID assigned at position open. Links to execution audit trail. |
| 50 | EndExecutionID | Hardcoded 0 | Always 0 - position is open, no closing execution recorded. |
| 51 | RootHedgeServerID | Trade.PositionTbl | Hedge server at the root of the copy-trade tree. |
| 52 | IsOpenOpen | Trade.PositionTbl | Flag indicating this is an "open-open" position type (specific order variant). |
| 53 | TreeID | Trade.PositionTbl | Copy-trade tree root PositionID. Used to JOIN Trade.PositionTreeInfo. |
| 54 | IsComputeForHedge | Trade.PositionTbl | Flag indicating whether this position should be computed in hedge exposure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Lookup | Filters positions to those belonging to the specified mirror (CopyTrader portfolio). |
| InstrumentID | Trade.Instrument | JOIN | Resolves BuyCurrencyID and SellCurrencyID for forex rate context. |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | JOIN | Resolves Unit (lot size) and Precision for the instrument-provider pair; Enabled filter. |
| TreeID | Trade.PositionTreeInfo | JOIN | Resolves LimitRate, StopRate, CloseOnEndOfWeek for copy-trade tree settings. |
| PositionTbl (MirrorID + StatusID + ParentPositionID) | Trade.PositionTbl | Primary read | Main source table for all position data. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorNonStocksPositions (procedure)
├── Trade.PositionTbl (table)
├── Trade.Instrument (table)
├── Trade.ProviderToInstrument (table)
└── Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Primary source - all position data, filtered by MirrorID, StatusID=1, ParentPositionID>0 |
| Trade.Instrument | Table | INNER JOIN on InstrumentID - provides BuyCurrencyID, SellCurrencyID |
| Trade.ProviderToInstrument | Table | INNER JOIN on ProviderID + InstrumentID - provides Unit, Precision; Enabled=1 filter |
| Trade.PositionTreeInfo | Table | INNER JOIN on TreeID - provides LimitRate, StopRate, CloseOnEndOfWeek |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all open copy positions for a mirror

```sql
EXEC Trade.GetMirrorNonStocksPositions @MirrorID = 12345;
```

### 8.2 Compare result count against PositionTbl directly

```sql
-- Verify the SP result matches the direct query
SELECT COUNT(*) AS PositionCount
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 12345
  AND ParentPositionID > 0
  AND StatusID = 1
  AND ProviderID IN (
    SELECT ProviderID
    FROM Trade.ProviderToInstrument WITH (NOLOCK)
    WHERE Enabled = 1
      AND InstrumentID = Trade.PositionTbl.InstrumentID
  );
```

### 8.3 Examine tree settings for a mirror's positions

```sql
SELECT
    TPOS.PositionID,
    TPOS.CID,
    TPOS.InstrumentID,
    TPTI.LimitRate AS TakeProfit,
    TPTI.StopRate AS StopLoss,
    TPTI.CloseOnEndOfWeek
FROM Trade.PositionTbl TPOS WITH (NOLOCK)
INNER JOIN Trade.PositionTreeInfo TPTI WITH (NOLOCK)
    ON TPOS.TreeID = TPTI.TreeID
WHERE TPOS.MirrorID = 12345
  AND TPOS.ParentPositionID > 0
  AND TPOS.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorNonStocksPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorNonStocksPositions.sql*
