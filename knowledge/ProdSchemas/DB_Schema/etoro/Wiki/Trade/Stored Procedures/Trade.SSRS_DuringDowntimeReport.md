# Trade.SSRS_DuringDowntimeReport

> SSRS report procedure that calculates Net Open Position (NOP) exposure per instrument and hedge server for BackTrader orders processed during a system downtime window.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate DATE (downtime window start) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports post-downtime reconciliation by calculating the net open position (NOP) impact of trading activity that occurred via BackTrader during a system maintenance window. BackTrader is a system component that processes position close requests and open orders, and during a downtime (when the main trading system is offline), it may continue accepting orders that need to be accounted for when the system comes back online.

The report is used by operations and risk teams to understand the net exposure (in dollar terms) created by BackTrader activity from a given start date - both positions closed via BackTrader close requests (from the `Trade.SynBackTrader2CloseRequest` synonym) and new positions opened via `dbo.BackTraderOrders`. This is critical for post-downtime reconciliation: if BackTrader processed many closes during downtime, the NOP will show a reduction in exposure per instrument/server.

Data is aggregated per `InstrumentID` and `HedgeServerID`, allowing risk managers to see which hedge servers and instruments were most affected during the downtime period.

---

## 2. Business Logic

### 2.1 BuySell Directional Encoding

**What**: Converts trade direction flags into signed multipliers (+1 / -1) for NOP aggregation arithmetic.

**Columns/Parameters Involved**: `BuySell` (in #tempPos), `IsBuy` (from dbo.BackTraderOrders), `BuySell` (from SynBackTrader2CloseRequest)

**Rules**:
- For close requests (SynBackTrader2CloseRequest): `BuySell` is a string ('Buy' or other) - converted to 1 (Buy) or -1 (Sell/Short) via `IIF(tcr.BuySell = 'Buy', 1, -1)`.
- For open orders (BackTraderOrders): `IsBuy` is a BIT (0 or 1) - converted to +1/-1 via `(IsBuy * 2 - 1)`: IsBuy=1 -> +1, IsBuy=0 -> -1.
- NOP is then calculated as `SUM(BuySell * AmountInUnitsDecimal * UnitMargin)` - positive for net long exposure, negative for net short.

**Diagram**:
```
SynBackTrader2CloseRequest.BuySell = 'Buy'  -> #tempPos.BuySell = +1
SynBackTrader2CloseRequest.BuySell = other  -> #tempPos.BuySell = -1

BackTraderOrders.IsBuy = 1  -> #tempPos.BuySell = +1  (buy order)
BackTraderOrders.IsBuy = 0  -> #tempPos.BuySell = -1  (sell order)

NOP = SUM(BuySell * AmountInUnitsDecimal * UnitMargin)
  Positive NOP = net long exposure
  Negative NOP = net short exposure
```

### 2.2 Deduplication Between Sources

**What**: Prevents double-counting of positions that appear in both BackTraderOrders and the close request synonym.

**Columns/Parameters Involved**: `PositionID` (in #tempPos)

**Rules**:
- #tempPos has a PRIMARY KEY on PositionID, enforcing uniqueness.
- The BackTraderOrders insert explicitly filters: `NOT IN (SELECT PositionID FROM #tempPos)` to exclude positions already loaded from the close request source.
- `SynBackTrader2CloseRequest` is loaded first; `dbo.BackTraderOrders` only fills in positions not yet captured.

**Diagram**:
```
Step 1: Load from SynBackTrader2CloseRequest (CloseTime >= @StartDate, EntityType = 'Position')
Step 2: Load from BackTraderOrders (ReceivedOn >= @StartDate, ActionID = 1)
         WHERE PositionID NOT IN #tempPos  <- prevents duplicates
Step 3: Aggregate NOP via JOIN to Trade.Position + Trade.CurrencyPrice
```

### 2.3 NOP Calculation

**What**: Calculates dollar-denominated net open position exposure per instrument and hedge server.

**Columns/Parameters Involved**: `Units`, `NOP`, `AmountInUnitsDecimal`, `UnitMargin`

**Rules**:
- `Units = SUM(AmountInUnitsDecimal * BuySell)` - net units (positive = net long, negative = net short).
- `NOP = SUM(BuySell * AmountInUnitsDecimal * UnitMargin)` - dollar value of net exposure.
- `UnitMargin` from `Trade.CurrencyPrice` provides the per-unit dollar value at the time of the query.
- Grouped by `HedgeServerID` and `InstrumentID` - gives a breakdown by hedge server routing and instrument.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATE | YES | NULL | CODE-BACKED | Start of the downtime window to report on. Filters SynBackTrader2CloseRequest by CloseTime >= @StartDate and BackTraderOrders by ReceivedOn >= @StartDate. When NULL, defaults to all records (no date filter effectively applied since CloseTime >= NULL evaluates based on SQL NULL comparison). |

### Output Columns (Result Set)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier grouping key. FK to Trade.InstrumentMetaData.InstrumentID. Identifies which tradeable asset the NOP aggregation applies to. |
| 2 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server routing identifier from Trade.Position view. Groups NOP by the hedge server that handles this instrument's hedging. FK to Trade.HedgeServer. |
| 3 | Units | DECIMAL | NO | - | CODE-BACKED | Net signed units of exposure: SUM(AmountInUnitsDecimal * BuySell). Positive = net long (more buys than sells), Negative = net short. Zero indicates balanced exposure for this instrument/server combination. |
| 4 | NOP | MONEY | NO | - | CODE-BACKED | Net Open Position in dollar terms: SUM(BuySell * AmountInUnitsDecimal * UnitMargin). Represents the total dollar-denominated directional exposure created by BackTrader orders during the downtime window. Used for risk reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source) | Trade.SynBackTrader2CloseRequest | Lookup (READ via synonym) | Reads BackTrader close request records for the downtime period. Synonym pointing to a BackTrader integration table. |
| PositionID | dbo.BackTraderOrders | Lookup (READ) | Reads BackTrader open order records (ActionID = 1) from the downtime period. |
| PositionID | Trade.Position | Lookup (JOIN) | Joins to the Trade.Position view to get AmountInUnitsDecimal and HedgeServerID for NOP calculation. |
| InstrumentID | Trade.CurrencyPrice | Lookup (JOIN) | Joins to Trade.CurrencyPrice to get UnitMargin (per-unit dollar value) for NOP dollar calculation. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called directly from SSRS report server. Referenced in UsersPermissions/DATA_READER.sql (EXECUTE permission grant).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRS_DuringDowntimeReport (procedure)
├── Trade.SynBackTrader2CloseRequest (synonym -> BackTrader table)
├── dbo.BackTraderOrders (table)
├── Trade.Position (view)
└── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynBackTrader2CloseRequest | Synonym | SELECT source for BackTrader close requests (CloseTime >= @StartDate, EntityType = 'Position') |
| dbo.BackTraderOrders | Table | SELECT source for BackTrader open orders (ActionID = 1, ReceivedOn >= @StartDate) |
| Trade.Position | View | JOIN source for AmountInUnitsDecimal and HedgeServerID for NOP aggregation |
| Trade.CurrencyPrice | Table | JOIN source for UnitMargin (per-unit dollar value for NOP calculation) |

### 6.2 Objects That Depend On This

No dependents found. Called directly from SSRS report server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Temp table #tempPos has PRIMARY KEY on PositionID (deduplication key).

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run downtime NOP report for a specific downtime window

```sql
EXEC Trade.SSRS_DuringDowntimeReport @StartDate = '2026-01-15'
```

### 8.2 View NOP sorted by largest absolute exposure

```sql
-- Run procedure and check largest NOP by instrument
EXEC Trade.SSRS_DuringDowntimeReport @StartDate = '2026-01-15'
-- Then order result: ORDER BY ABS(NOP) DESC
```

### 8.3 Preview BackTrader orders for a downtime period directly

```sql
SELECT TOP 20
    bto.PositionID,
    bto.IsBuy,
    (bto.IsBuy * 2 - 1) AS BuySell,
    bto.ReceivedOn
FROM dbo.BackTraderOrders bto WITH (NOLOCK)
WHERE bto.ReceivedOn >= '2026-01-15'
    AND bto.ActionID = 1
ORDER BY bto.ReceivedOn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRS_DuringDowntimeReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRS_DuringDowntimeReport.sql*
