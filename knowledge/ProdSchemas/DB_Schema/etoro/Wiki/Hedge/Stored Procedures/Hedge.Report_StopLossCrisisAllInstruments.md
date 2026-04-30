# Hedge.Report_StopLossCrisisAllInstruments

> Crisis exposure report: shows ACTUAL current open lot count per instrument for a given HedgeServer, filtering to only positions where the stop loss has NOT yet triggered (StopRate has not been breached by current Bid). Used by the dealing desk to monitor residual exposure that cannot auto-close during a crisis or extreme market move.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID INT; DATA_READER has EXECUTE |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_StopLossCrisisAllInstruments` is a dealing desk crisis monitoring tool. During extreme market events (gap openings, flash crashes, sudden price moves), stop-loss orders may fail to execute at their target price ("stop loss that didn't catch"). This procedure shows the portion of the hedge book that is STILL OPEN (not protected by a triggered stop loss) per instrument.

The procedure comment states: "THIS QUERY SHOWS YOU THE ACTUAL CURRENT OPEN LOTCOUNT BY INSTRUMENT WITHOUT STOPLOSS THAT DIDN'T CATCH."

**Logic**: It reads open positions from `Trade.Position`, joins to `Trade.CurrencyPrice` for the current bid price, then applies a CASE statement that zeroes out positions where the stop loss SHOULD HAVE triggered already (i.e., the market has moved through the stop level), returning only positions where the stop has NOT yet been hit.

- `IsBuy=1` (long position): stop is triggered when `StopRate > Bid` (market fell below stop). If `StopRate < Bid` still (market hasn't hit stop yet), the position is still "open at risk" = include in `Long`.
- `IsBuy=0` (short position): stop is triggered when `StopRate < Bid` (market rose above stop). If `StopRate > Bid` still, position is still open = include in `Short`.

A hardcoded test result set (USD/CHF, CHF/JPY, GBP/USD) is commented out for development testing.

---

## 2. Business Logic

### 2.1 Stop-Loss Filter Logic

**What**: Positions are classified based on whether the current market price has already breached their stop-loss level.

**Columns/Parameters Involved**: `StopRate`, `Bid` (from CurrencyPrice), `IsBuy`, `LotCountDecimal`

**Stop-loss trigger conditions** (positions that SHOULD already be stopped out - excluded from results):
- Long (IsBuy=1): `StopRate > Bid` - stop level is above current price, meaning price fell through the stop -> this position should have triggered -> set Lot=0.
- Short (IsBuy=0): `StopRate < Bid` - stop level is below current price, meaning price rose through the stop -> this position should have triggered -> set Lot=0.

**Remaining open positions** (stop NOT yet triggered - included in results):
- Long (IsBuy=1): `StopRate < Bid` - stop is still below current price, not yet triggered -> `Long = LotCountDecimal`.
- Short (IsBuy=0): `StopRate > Bid` - stop is still above current price, not yet triggered -> `Short = -LotCountDecimal`.

**CASE expression summary**:
```
Lot (net position):
  CASE WHEN (StopRate < Bid) AND (IsBuy=0) THEN 0           -- short stop not hit yet? 0 (inverted?)
       WHEN (StopRate > Bid) AND (IsBuy=1) THEN 0           -- long stop triggered -> 0
       WHEN (StopRate > Bid) AND (IsBuy=0) THEN -LotCount   -- short stop not triggered -> include
       WHEN (StopRate < Bid) AND (IsBuy=1) THEN LotCount    -- long stop not triggered -> include
```

**Output columns**:
- `OpenBuy` = `SUM(Long)`: net long lots where stop not triggered
- `OpenSell` = `SUM(Short)`: net short lots where stop not triggered (negative values)
- `CurrentOpen` = `SUM(Lot)`: net position (long + short)

### 2.2 Instrument Scope

**What**: All instruments for the given HedgeServer are included (no hardcoded instrument list).

**Rules**:
- `HedgeServerID = @HedgeServerID` in the WHERE clause (applied via the JOIN ON clause: `AND HedgeServerID = @HedgeServerID`).
- All instruments in Trade.Position for that server are covered.
- Current bid price is from `Trade.CurrencyPrice` via JOIN on InstrumentID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server to analyze. Filters Trade.Position to only that server's positions. |

Result set columns:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | InstrumentID | INT | Instrument identifier |
| 2 | Name | VARCHAR | Instrument display name (from Trade.GetInstrument) |
| 3 | Price | dtPrice | Current bid price from Trade.CurrencyPrice at execution time |
| 4 | OpenBuy | DECIMAL | Net long lot exposure where stop loss not yet triggered (positive) |
| 5 | OpenSell | DECIMAL | Net short lot exposure where stop loss not yet triggered (negative) |
| 6 | CurrentOpen | DECIMAL | Net position: OpenBuy + OpenSell (positive = net long, negative = net short) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.Position | Reader (NOLOCK) | Open positions with StopRate, LotCountDecimal, IsBuy, HedgeServerID |
| - | Trade.CurrencyPrice | Reader (NOLOCK) | Current bid price for stop-loss comparison |
| - | Trade.GetInstrument | Reader (NOLOCK) | InstrumentID -> Name lookup |

### 5.2 Referenced By (other objects point to this)

DATA_READER role holds EXECUTE. Used by dealing desk during market crises to assess unprotected exposure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_StopLossCrisisAllInstruments (procedure)
|-- Trade.Position (table) [READ - StopRate, LotCountDecimal, IsBuy, HedgeServerID]
|-- Trade.CurrencyPrice (table) [READ - current Bid for stop-loss comparison]
+-- Trade.GetInstrument (view/table) [READ - instrument name resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Open positions with stop-loss rate and lot count |
| Trade.CurrencyPrice | Table | Current bid price for stop-loss trigger evaluation |
| Trade.GetInstrument | View/Table | InstrumentID -> Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DATA_READER (role) | Permission | EXECUTE - dealing desk crisis monitoring |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Subquery DerivedTable T | Inline view | All CASE computations done in inner subquery T; GROUP BY on outer query. |
| NOLOCK on all tables | Isolation | Read uncommitted for crisis-time performance (data freshness prioritized). |

---

## 8. Sample Queries

### 8.1 Check crisis exposure for server 1
```sql
EXEC [Hedge].[Report_StopLossCrisisAllInstruments]
    @HedgeServerID = 1
-- Returns: InstrumentID | Name | Price | OpenBuy | OpenSell | CurrentOpen
-- Positive CurrentOpen = net long exposure with stops not yet triggered
```

### 8.2 Find instruments with significant unprotected exposure
```sql
-- After executing above, filter for significant positions:
-- ABS(CurrentOpen) > 1000 would indicate large unprotected lots
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_StopLossCrisisAllInstruments | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_StopLossCrisisAllInstruments.sql*
