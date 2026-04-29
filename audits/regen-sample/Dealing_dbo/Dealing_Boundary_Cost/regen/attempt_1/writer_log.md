

**MCP PRE-FLIGHT CHECK**
MCP PRE-FLIGHT: PASS

Now loading rules files in order.
Rules loaded. Now proceeding with the pipeline.

**Phase 1 — Structure Analysis**

DDL already provided in the bundle. `Dealing_dbo.Dealing_Boundary_Cost` has 31 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on `DateID ASC`.

PHASE 1 CHECKPOINT: PASS

**Phase 2 — Live Data Sampling + Row Count**
Approximately **2.54 billion rows** across 827 distinct dates (2021-01-01 to 2024-03-17). Minute-level grain.

PHASE 2 CHECKPOINT: PASS

**Phase 3 — Distribution Analysis**
PHASE 3 CHECKPOINT: PASS

**Phase 4 — Lookup Resolution**

Key FK columns: `InstrumentID` → `Dim_Instrument`, `HedgeServerID` → hedge server, `IsSettled` (0/1 flag), `InstrumentTypeID` → instrument type enum. All already documented in bundle.

PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN Analysis**

From the SP code in the bundle, the SP builds minute-by-minute data via complex temp tables joining: `Dim_Instrument`, `Fact_SnapshotCustomer + Dim_Range + Dim_Date` (for valid customer filtering), `Dim_Position` (open/closed positions), `Dim_PositionHedgeServerChangeLog_Snapshot`, `BI_DB_PositionPnL` (previous day NOP), `Fact_CurrencyPriceWithSplit` (FX rates), `etoro_Hedge_InstrumentBoundaries` (boundary config), `PriceLog raw parquet` (minute prices), `Dim_HistorySplitRatio` (split ratios), `Dim_PositionChangeLog` (partial close unit tracking), `etoro_Trade_PositionsHedgeServerChangeLog` (HS move events).

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic Discovery**

From the SP, key business logic patterns:
1. **Minute-level grain**: 1440 minutes per day × instruments × hedge servers × IsSettled
2. **NOP running sum**: Previous day NOP + cumulative (UnitsBuy - UnitsSell) per minute
3. **WAVG prices**: Weighted-average buy/sell prices from position opens/closes
4. **Standard spread**: Rolling 3-month standard deviation of spread/mid
5. **Boundaries**: From `etoro_Hedge_InstrumentBoundaries` with defaults for stocks/ETFs
6. **FX rate chain**: USD conversion using instrument buy/sell currency pairs
7. **HS position moves**: Tracks units moved between hedge servers intraday
8. **Split adjustment**: PriceRatio from Dim_HistorySplitRatio on split dates

PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependency Scan**
No views reference this table. There's a related `Dealing_Boundary_Cost_H_Indices` table (likely a historical/index variant).

PHASE 7 CHECKPOINT: PASS

**Phase 8 — SP Scan**

Writer SP is `Dealing_dbo.SP_Boundary_Cost` — already fully in the bundle.

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic Extraction**

Already analyzed from the bundle SP code. Key column source-to-target mapping:

- `Date` = `@Date` parameter
- `DateID` = `CONVERT(NVARCHAR, @Date, 112)` — ETL-computed
- `FromDate`/`ToDate` = minute interval boundaries from `#FinalPrices` (derived from `#Minutes` + `#RawPrices`)
- `InstrumentID` = from `#FinalPrices` ← `#Ins` ← `Dim_Instrument` (tradable, visible, specific types)
- `InstrumentName` = `Dim_Instrument.InstrumentDisplayName`
- `InstrumentType` = `Dim_Instrument.InstrumentType`
- `StdSpreadPercent` = ETL-computed: 3-month rolling STDEV(Spread/Mid) average
- `LastBid`/`LastAsk`/`Mid`/`LastBidSpreaded`/`LastAskSpreaded` = from raw PriceLog parquet (minute-level last price)
- `UnitsBuy`/`UnitsSell` = SUM of position units opened/closed per minute (buy vs sell direction)
- `WAVG_BuyPrice`/`WAVG_SellPrice` = weighted-average price: SUM(units*rate)/SUM(units)
- `NOP` = running sum: previous-day NOP + cumulative (UnitsBuy - UnitsSell) per minute
- `UpdateDate` = GETDATE()
- `VolumeBuy`/`VolumeSell` = SUM of position Volume per minute per direction
- `VariableSpread` = SUM(units * (Ask-Bid) * USD_conversion)
- `LowerBoundary`/`UpperBoundary`/`HedgeRiskLimit` = from `etoro_Hedge_InstrumentBoundaries` with defaults for stocks/ETFs
- `FX_Bid` = USD conversion rate from FX cross-rate logic
- `InstrumentTypeID` = from `Dim_Instrument.InstrumentTypeID`
- `HedgeServerID` = from position + HS snapshot override
- `IsSettled` = from position (1=real, 0=CFD)
- `PriceRatio` = from `Dim_HistorySplitRatio` on split dates, else 1
- `HS_Moved_Units` = net units moved between hedge servers per minute

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL Orchestration**

The SP runs daily with `@Date` parameter. It DELETEs existing rows for `@Date` then INSERTs from the complex temp table chain. Data loads from PriceLog parquet via COPY INTO for minute-level prices. The SP also reads previous day's NOP from `BI_DB_dbo.BI_DB_PositionPnL`.

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Atlassian**

[-] Skipped — no Atlassian MCP available in this session.

PHASE 10 CHECKPOINT: PASS (skipped)

**Phase 10A — Upstream Wiki**

Bundle contains 9 upstream wikis: Dim_Instrument, Dim_Position, Fact_CurrencyPriceWithSplit, Dim_HistorySplitRatio, Dim_PositionChangeLog, Fact_SnapshotCustomer, Dim_Range, Dim_PositionHedgeServerChangeLog_Snapshot, BI_DB_PositionPnL. All read and analyzed.

PHASE 10A CHECKPOINT: PASS

**Phase 10B — Column Lineage (writing .lineage.md FIRST)**

Now let me check the generic pipeline mapping for UC target.
