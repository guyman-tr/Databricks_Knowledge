# Dealing_dbo.Dealing_Boundary_Cost

> Minute-level intraday dealing boundary cost analysis table tracking net open position (NOP) evolution, bid/ask prices, spread metrics, volume flows, and hedge server boundary thresholds per instrument per hedge server per settlement type. 827 trading days from 2021-01-01 to 2024-03-17, with ~5-6M rows per weekday across 5,499 instruments and 42 hedge servers. Data loading appears paused since 2024-03-17.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source analytical computation via SP_Boundary_Cost (DWH_dbo.Dim_Position, Dim_Instrument, BI_DB_PositionPnL, PriceLog Data Lake feed, etoro_Hedge_InstrumentBoundaries, Fact_CurrencyPriceWithSplit, Dim_HistorySplitRatio) |
| **Refresh** | Daily via SP_Boundary_Cost(@Date) — DELETE+INSERT per date (currently paused, last data 2024-03-17) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | N/A — Dealing_dbo not in Unity Catalog |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_Boundary_Cost` is a minute-granularity analytical table used by the Dealing/Risk team to monitor intraday net open position (NOP) evolution, spread costs, and boundary threshold compliance per instrument, hedge server, and settlement type (real vs CFD). Each row represents a one-minute time bucket for a specific (InstrumentID, HedgeServerID, IsSettled) combination on a given trading day.

The table is populated daily by `Dealing_dbo.SP_Boundary_Cost(@Date)`, which orchestrates a complex multi-source pipeline:
1. Loads tradable instruments from `Dim_Instrument` (filtered: Tradable=1, VisibleInternallyOnly=0, InstrumentTypeID IN (2,4,5,6) or crypto with SellCurrencyID=1).
2. Identifies valid customers for the day and previous day via `Fact_SnapshotCustomer` + `Dim_Range` + `Dim_Date`.
3. Loads positions from `Dim_Position` covering a 3-month lookback window.
4. Retrieves previous-day NOP from `BI_DB_dbo.BI_DB_PositionPnL` (aggregated by instrument/HS/IsSettled).
5. Resolves hedge server assignments via `Dim_PositionHedgeServerChangeLog_Snapshot`.
6. Computes quarterly spread standard deviation from open/close bid-ask spreads.
7. Generates a 1440-row minute spine for the trading day using `Dim_Date` cross-joins.
8. Aggregates position opens/closes by minute into buy/sell units, volumes, and WAVG prices.
9. Loads intraday raw prices from the Data Lake via `COPY INTO` from PriceLog parquet files.
10. Computes FX bid rates via triangulation using `Fact_CurrencyPriceWithSplit` and `Dim_Instrument` currency pairs.
11. Retrieves instrument boundary thresholds from `dbo.etoro_Hedge_InstrumentBoundaries`.
12. Tracks intraday hedge server movements and partial-close unit adjustments via `etoro_Trade_PositionsHedgeServerChangeLog` and `Dim_PositionChangeLog`.
13. Final INSERT computes NOP as a cumulative window: `previous_day_NOP + SUM(UnitsBuy - UnitsSell) OVER (ORDER BY ToDate)`.

The ETL uses a DELETE+INSERT pattern: all rows for `@Date` are deleted before reinserting. Data spans 2021-01-01 to 2024-03-17 (827 distinct dates). Weekday rows average ~5.7M per day; weekend rows ~500K (crypto-only trading). The table is dominated by Crypto Currencies (~96% of rows on a typical day), followed by Stocks, Commodities, and Indices.

---

## 2. Business Logic

### 2.1 Minute-Level NOP Evolution

**What**: The table tracks how the Net Open Position for each instrument/hedge-server/settlement-type combination evolves minute by minute throughout the trading day.

**Columns Involved**: `NOP`, `UnitsBuy`, `UnitsSell`, `FromDate`, `ToDate`, `InstrumentID`, `HedgeServerID`, `IsSettled`

**Rules**:
- NOP starts from the previous day's closing NOP (sourced from `BI_DB_dbo.BI_DB_PositionPnL` aggregated as `SUM(CASE WHEN IsBuy=1 THEN units ELSE -units END)` by instrument/HS/IsSettled).
- Each minute's NOP = previous_day_NOP + cumulative_sum(UnitsBuy - UnitsSell) from the start of the day to that minute.
- The cumulative sum uses `SUM(...) OVER (PARTITION BY InstrumentID, HedgeServerID, IsSettled ORDER BY ToDate)`.
- For position opens: buy units go to UnitsBuy, sell units to UnitsSell; for closes the direction is FLIPPED (closing a buy = selling back, so buy-close units go to UnitsSell).
- HS_Moved_Units captures units transferred between hedge servers intraday, which affect NOP without being open/close events.

### 2.2 Spread and Price Metrics

**What**: Each minute captures the latest raw and spreaded bid/ask prices plus a quarterly average spread volatility metric.

**Columns Involved**: `LastBid`, `LastAsk`, `Mid`, `LastBidSpreaded`, `LastAskSpreaded`, `StdSpreadPercent`, `VariableSpread`

**Rules**:
- `LastBid`/`LastAsk` are the most recent raw prices within each minute window from the PriceLog Data Lake feed (ROW_NUMBER by Occurred DESC, rn=1 per minute per instrument).
- `Mid = (LastAsk + LastBid) / 2`.
- `LastBidSpreaded`/`LastAskSpreaded` are the broker spread-adjusted prices from the same feed.
- `StdSpreadPercent` is the quarterly average of monthly standard deviations of `(Spread/Mid)` over a 3-month lookback window using position open/close bid-ask data from Dim_Position. It measures spread volatility, not spread level.
- `VariableSpread = SUM(units * (Ask - Bid) * USDConversionRate)` — total spread cost in USD for all positions opened/closed in that minute.

### 2.3 Boundary Threshold Compliance

**What**: Each row carries the instrument's boundary limits from the hedge system, allowing comparison of NOP against risk thresholds.

**Columns Involved**: `LowerBoundary`, `UpperBoundary`, `HedgeRiskLimit`, `FX_Bid`

**Rules**:
- `LowerBoundary = (-1) * (CloseThresholdPercentage * OpenThresholdUSD) / 100` from `dbo.etoro_Hedge_InstrumentBoundaries`. Represents the maximum negative NOP before close-side hedging triggers.
- `UpperBoundary = OpenThresholdUSD` — the maximum positive NOP before open-side hedging triggers.
- `HedgeRiskLimit = HedgeRiskLimitUSD` — the overall risk limit in USD.
- For Stocks and ETFs (InstrumentTypeID IN (5,6)): defaults apply when no boundary is configured: LowerBoundary=-50,000, UpperBoundary=500,000, HedgeRiskLimit=250,000.
- `FX_Bid` provides the USD conversion rate for the instrument via triangulation: if SellCurrencyID=1 (USD-quoted) → 1.0; if BuyCurrencyID=1 (USD-based) → 1/Bid; else cross-rate through a USD-paired instrument.

### 2.4 Hedge Server Movement Tracking

**What**: Positions can be moved between hedge servers intraday. The SP tracks these movements and adjusts NOP accordingly.

**Columns Involved**: `HedgeServerID`, `HS_Moved_Units`

**Rules**:
- `HedgeServerID` is resolved as `ISNULL(snapshot.HedgeServerID, position.HedgeServerID)` — the SP prefers the `Dim_PositionHedgeServerChangeLog_Snapshot` value (point-in-time HS assignment) over the current Dim_Position value.
- `HS_Moved_Units` captures the net units transferred into or out of a hedge server during each minute, computed from `etoro_Trade_PositionsHedgeServerChangeLog` events.
- When positions are moved from HS_A to HS_B: HS_A gets negative HS_Moved_Units, HS_B gets positive.
- Partial closes that occur concurrently with HS movements are tracked via `Dim_PositionChangeLog` (ChangeTypeID=12) to get the correct unit count at the time of movement.

### 2.5 Stock Split Adjustment

**What**: On days when a stock split occurs, the PriceRatio column carries the split adjustment factor for the first minute of each instrument/HS/IsSettled partition.

**Columns Involved**: `PriceRatio`

**Rules**:
- `PriceRatio = ISNULL(sr.PriceRatio, 1)` from `Dim_HistorySplitRatio` where `MaxDate = @DateID`.
- Applied only to the first minute per (InstrumentID, HedgeServerID, IsSettled) partition via `ROW_NUMBER() OVER (... ORDER BY FromDate ASC) = 1`.
- 1.0 for all instruments without a split event on that date.
- Downstream consumers multiply historical prices by PriceRatio to get split-adjusted values.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `DateID ASC`. Date-range queries are efficient via the clustered index. Since distribution is ROUND_ROBIN, no column-based co-location exists — JOINs to HASH-distributed tables (Dim_Position, Dim_Instrument) will require data movement.

Typical daily row counts: ~5.7M rows per weekday, ~500K per weekend day (crypto only). Always filter on DateID to avoid scanning the full table.

### 3.1b UC (Databricks) Storage & Partitioning

This table has no Unity Catalog target. Dealing_dbo is not yet migrated to UC.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| NOP for an instrument at end of day | `WHERE DateID = @dateID AND InstrumentID = @id ORDER BY ToDate DESC` (last minute row) |
| NOP evolution throughout a day | `WHERE DateID = @dateID AND InstrumentID = @id AND HedgeServerID = @hs ORDER BY ToDate` |
| Instruments exceeding boundary limits | `WHERE DateID = @dateID AND (NOP * FX_Bid > UpperBoundary OR NOP * FX_Bid < LowerBoundary)` |
| Total volume by instrument for a day | `SELECT InstrumentID, SUM(VolumeBuy) + SUM(VolumeSell) FROM ... WHERE DateID = @dateID GROUP BY InstrumentID` |
| Spread volatility ranking | `SELECT DISTINCT InstrumentID, StdSpreadPercent FROM ... WHERE DateID = @dateID ORDER BY StdSpreadPercent DESC` |
| Hedge server movements on a day | `WHERE DateID = @dateID AND HS_Moved_Units <> 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve full instrument details, currency pairs |
| DWH_dbo.Dim_Date | ON DateID = Dim_Date.DateKey | Calendar attributes |
| Dealing_dbo.Dealing_Boundary_Cost_H_Indices | ON DateID, InstrumentID | Historical index companion table |

### 3.4 Gotchas

- **Data stopped at 2024-03-17**: The SP appears to be paused or deprecated. No data exists after this date.
- **Weekend rows are crypto-only**: Weekday rows ~5.7M vs weekend ~500K. InstrumentTypeID filter covers Commodities(2), Indices(4), Stocks(5), ETF(6), and Crypto(10) with SellCurrencyID=1 only.
- **IsSettled has 3 values including NULL**: 0=CFD, 1=real asset, NULL for some rows. Always handle NULLs.
- **NOP is cumulative**: Each row's NOP includes the previous day's closing NOP plus all intraday changes up to that minute. It is NOT the delta for that minute.
- **VolumeBuy/VolumeSell direction is flipped for closes**: When a buy position closes, its volume goes to VolumeSell (not VolumeBuy), because closing a long is economically a sell.
- **StdSpreadPercent is the same for all minutes of a given instrument on a given day**: It is a 3-month quarterly average, not a per-minute calculation.
- **LowerBoundary is negative**: It represents the negative NOP threshold. NULL when no boundary is configured and InstrumentTypeID is not 5 or 6.
- **PriceRatio is 1.0 for most rows**: Only the first minute per instrument/HS/IsSettled partition on a split day gets a non-1.0 value.
- **ROUND_ROBIN distribution**: No co-location with any specific column. Large JOINs will involve data movement.
- **FX_Bid can be NULL**: When no cross-rate can be found. Use `ISNULL(FX_Bid, 1)` for USD-equivalent calculations.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki verbatim | `(Tier 1 — source)` |
| ★★★ | Tier 2 — Synapse SP code / DDL | `(Tier 2 — SP_Boundary_Cost)` |
| ★★★★★ | Tier 5 — domain expert confirmed | `(Tier 5 — Expert Review)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot calendar date. Set to the `@Date` input parameter of SP_Boundary_Cost. One day of data per SP invocation. (Tier 2 — SP_Boundary_Cost) |
| 2 | DateID | int | YES | Snapshot date as YYYYMMDD integer (e.g., 20240317). Clustered index key. Always include in WHERE clause for efficient queries. Computed as `CONVERT(NVARCHAR, @Date, 112)`. (Tier 2 — SP_Boundary_Cost) |
| 3 | FromDate | datetime | YES | Start of the one-minute time bucket (inclusive). Generated from a minute spine: `DATEADD(MINUTE, n-1, CAST(@Date AS DATETIME))`. 1440 buckets per full trading day. (Tier 2 — SP_Boundary_Cost) |
| 4 | ToDate | datetime | YES | End of the one-minute time bucket (exclusive). `DATEADD(MINUTE, n, CAST(@Date AS DATETIME))`. Each row spans exactly one minute. (Tier 2 — SP_Boundary_Cost) |
| 5 | InstrumentID | int | YES | Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Filtered to tradable, externally visible instruments in specific type categories (Commodities, Indices, Stocks, ETF, and USD-quoted Crypto). 5,499 distinct instruments observed. (Tier 1 — Trade.Instrument) |
| 6 | InstrumentName | varchar(100) | YES | User-facing instrument display name from Dim_Instrument.InstrumentDisplayName (e.g., 'Apple Inc.', 'Arbitrum'). More descriptive than the internal Name column. NULL for instruments without metadata entries. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 7 | InstrumentType | varchar(50) | YES | Text label for InstrumentTypeID — DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 — SP_Dim_Instrument) |
| 8 | StdSpreadPercent | decimal(16,6) | YES | Quarterly average of monthly standard deviations of relative spread `(Ask-Bid)/Mid`, computed from position open/close bid-ask prices over a 3-month lookback window. Measures spread volatility as a percentage of mid-price. Same value for all minutes of a given instrument on a given day. NULL in the UNION ALL branch for no-trade HS movement rows. (Tier 2 — SP_Boundary_Cost) |
| 9 | LastBid | decimal(16,6) | YES | Last raw bid price within this minute bucket from the PriceLog Data Lake feed (Bronze/PriceLog/History/CurrencyPrice/ parquet). Selected as the most recent price record per minute per instrument (ROW_NUMBER by Occurred DESC, rn=1). NULL when no price record exists for this minute. (Tier 2 — SP_Boundary_Cost) |
| 10 | LastAsk | decimal(16,6) | YES | Last raw ask price within this minute bucket from the PriceLog Data Lake feed. Same selection logic as LastBid. NULL when no price record exists for this minute. (Tier 2 — SP_Boundary_Cost) |
| 11 | Mid | decimal(16,6) | YES | Mid-price computed as `(LastAsk + LastBid) / 2`. NULL when either LastBid or LastAsk is NULL. (Tier 2 — SP_Boundary_Cost) |
| 12 | LastBidSpreaded | decimal(16,6) | YES | Last spread-adjusted bid price within this minute from the PriceLog Data Lake feed (BidSpreaded column). The bid price with broker spread applied. NULL when no price record exists. (Tier 2 — SP_Boundary_Cost) |
| 13 | LastAskSpreaded | decimal(16,6) | YES | Last spread-adjusted ask price within this minute from the PriceLog Data Lake feed (AskSpreaded column). The ask price with broker spread applied. NULL when no price record exists. (Tier 2 — SP_Boundary_Cost) |
| 14 | UnitsBuy | decimal(16,6) | YES | Total units bought (long positions opened + short positions closed) in this minute bucket for the instrument/HS/IsSettled combination. Aggregated from Dim_Position.AmountInUnitsDecimal. 0 when no buy-side activity in this minute. Note: closing a short counts as a buy in this context. (Tier 2 — SP_Boundary_Cost) |
| 15 | UnitsSell | decimal(16,6) | YES | Total units sold (short positions opened + long positions closed) in this minute bucket for the instrument/HS/IsSettled combination. Aggregated from Dim_Position.AmountInUnitsDecimal. 0 when no sell-side activity in this minute. Note: closing a long counts as a sell. (Tier 2 — SP_Boundary_Cost) |
| 16 | WAVG_BuyPrice | decimal(16,6) | YES | Weighted average buy price: `SUM(units * rate) / SUM(units)` for buy-side activity in this minute. Uses InitForexRate for opens and EndForexRate for closes. 0 when UnitsBuy = 0. (Tier 2 — SP_Boundary_Cost) |
| 17 | WAVG_SellPrice | decimal(16,6) | YES | Weighted average sell price: `SUM(units * rate) / SUM(units)` for sell-side activity in this minute. Uses InitForexRate for opens and EndForexRate for closes. 0 when UnitsSell = 0. (Tier 2 — SP_Boundary_Cost) |
| 18 | NOP | decimal(20,6) | YES | Net Open Position in instrument units at the end of this minute. Cumulative: `previous_day_NOP + SUM(UnitsBuy - UnitsSell) OVER (PARTITION BY InstrumentID, HedgeServerID, IsSettled ORDER BY ToDate)`. Positive = net long, negative = net short. Previous-day NOP sourced from BI_DB_dbo.BI_DB_PositionPnL. (Tier 2 — SP_Boundary_Cost) |
| 19 | UpdateDate | datetime | YES | ETL load timestamp set to `GETDATE()` at INSERT time. Not a business date — reflects when SP_Boundary_Cost executed. (Tier 2 — SP_Boundary_Cost) |
| 20 | VolumeBuy | decimal(16,6) | YES | Total USD-equivalent buy-side volume in this minute. For opens: `SUM(Dim_Position.Volume WHERE IsBuy=1)`. For closes: `SUM(Dim_Position.VolumeOnClose WHERE IsBuy=0)` (direction flipped). 0 when no activity. (Tier 2 — SP_Boundary_Cost) |
| 21 | VolumeSell | decimal(16,6) | YES | Total USD-equivalent sell-side volume in this minute. For opens: `SUM(Dim_Position.Volume WHERE IsBuy=0)`. For closes: `SUM(Dim_Position.VolumeOnClose WHERE IsBuy=1)` (direction flipped). 0 when no activity. (Tier 2 — SP_Boundary_Cost) |
| 22 | VariableSpread | decimal(16,6) | YES | Total variable spread cost in USD for all positions opened or closed in this minute: `SUM(AmountInUnitsDecimal * (Ask - Bid) * USDConversionRate)`. For opens, uses InitForex_Ask/Bid and InitForex_USDConversionRate. For closes, uses EndForex_Ask/Bid and LastOpConversionRate. 0 when no activity. NULL in no-trade HS movement rows. (Tier 2 — SP_Boundary_Cost) |
| 23 | LowerBoundary | decimal(16,4) | YES | Lower NOP boundary threshold in USD: `(-1) * (CloseThresholdPercentage * OpenThresholdUSD) / 100` from dbo.etoro_Hedge_InstrumentBoundaries. Represents the maximum negative NOP (in USD terms) before close-side hedging triggers. Default -50,000 for Stocks/ETFs (InstrumentTypeID 5,6) when no boundary configured. NULL for other types without configured boundaries. (Tier 2 — SP_Boundary_Cost) |
| 24 | UpperBoundary | decimal(16,4) | YES | Upper NOP boundary threshold in USD: OpenThresholdUSD from dbo.etoro_Hedge_InstrumentBoundaries. Represents the maximum positive NOP before open-side hedging triggers. Default 500,000 for Stocks/ETFs (InstrumentTypeID 5,6) when no boundary configured. NULL for other types without configured boundaries. (Tier 2 — SP_Boundary_Cost) |
| 25 | HedgeRiskLimit | decimal(16,4) | YES | Overall hedge risk limit in USD: HedgeRiskLimitUSD from dbo.etoro_Hedge_InstrumentBoundaries. Absolute cap on NOP exposure. Default 250,000 for Stocks/ETFs (InstrumentTypeID 5,6) when no limit configured. NULL for other types without configured limits. (Tier 2 — SP_Boundary_Cost) |
| 26 | FX_Bid | decimal(16,6) | YES | USD conversion rate for the instrument, computed via FX triangulation from Fact_CurrencyPriceWithSplit on @DateID: if SellCurrencyID=1 (USD-quoted) → 1.0; if BuyCurrencyID=1 (USD-based) → 1/Bid; else cross-rate via `COALESCE(1/r1.Bid, r2.Bid, 1)`. Multiply NOP * FX_Bid to convert NOP to USD equivalent. NULL when no rate data available. (Tier 2 — SP_Boundary_Cost) |
| 27 | InstrumentTypeID | int | YES | Instrument type category from Dim_Instrument: 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Only these types appear in this table (filtered in SP). Used to determine default boundary values for Stocks/ETFs. (Tier 2 — SP_Dim_Instrument) |
| 28 | HedgeServerID | int | YES | Hedge server managing positions for this instrument. Resolved as `ISNULL(Dim_PositionHedgeServerChangeLog_Snapshot.HedgeServerID, Dim_Position.HedgeServerID)` — prefers the point-in-time SCD2 snapshot value over the current position value. 42 distinct hedge servers observed. (Tier 2 — SP_Boundary_Cost) |
| 29 | IsSettled | int | YES | 1 = real asset, 0 = CFD. Passthrough from Dim_Position.IsSettled. Determines settlement type for the position group. NULL observed in some rows. (Tier 5 — Expert Review) |
| 30 | PriceRatio | decimal(16,6) | YES | Stock split price adjustment factor from Dim_HistorySplitRatio. `ISNULL(sr.PriceRatio, 1)` where `MaxDate = @DateID`. Applied only to the first minute row per (InstrumentID, HedgeServerID, IsSettled) partition. 1.0 for all non-split instruments and all non-first-minute rows. Multiply historical prices by PriceRatio to get split-adjusted values. (Tier 2 — SP_Boundary_Cost) |
| 31 | HS_Moved_Units | decimal(20,6) | YES | Net units moved into or out of this hedge server during this minute due to hedge server reassignment events. Computed from `DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog` (intraday HS movements) combined with `Dim_PositionChangeLog` (ChangeTypeID=12 partial-close unit tracking). Positive = units moved IN, negative = units moved OUT. 0 when no HS movement in this minute. (Tier 2 — SP_Boundary_Cost) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | — | @Date parameter | ETL-computed |
| DateID | — | @Date parameter | ETL-computed: CONVERT(NVARCHAR, @Date, 112) |
| FromDate | Dim_Date cross-join | — | ETL-computed: minute spine generation |
| ToDate | Dim_Date cross-join | — | ETL-computed: minute spine generation |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough (filtered) |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Rename |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| StdSpreadPercent | DWH_dbo.Dim_Position | InitForex_Bid/Ask, EndForex_Bid/Ask | ETL-computed: AVG(STDEV(Spread/Mid)) quarterly |
| LastBid | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | Bid | Rename (last per minute) |
| LastAsk | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | Ask | Rename (last per minute) |
| Mid | — | LastBid, LastAsk | ETL-computed: (LastAsk + LastBid) / 2 |
| LastBidSpreaded | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | BidSpreaded | Rename (last per minute) |
| LastAskSpreaded | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | AskSpreaded | Rename (last per minute) |
| UnitsBuy | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed: SUM by minute |
| UnitsSell | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed: SUM by minute |
| WAVG_BuyPrice | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate | ETL-computed: weighted average |
| WAVG_SellPrice | DWH_dbo.Dim_Position | AmountInUnitsDecimal, EndForexRate | ETL-computed: weighted average |
| NOP | BI_DB_dbo.BI_DB_PositionPnL + Dim_Position | Units (prev day) + UnitsBuy - UnitsSell | ETL-computed: cumulative window |
| UpdateDate | — | — | ETL-computed: GETDATE() |
| VolumeBuy | DWH_dbo.Dim_Position | Volume, VolumeOnClose | ETL-computed: SUM by minute |
| VolumeSell | DWH_dbo.Dim_Position | Volume, VolumeOnClose | ETL-computed: SUM by minute |
| VariableSpread | DWH_dbo.Dim_Position | AmountInUnitsDecimal * (Ask-Bid) * FX | ETL-computed: SUM |
| LowerBoundary | dbo.etoro_Hedge_InstrumentBoundaries | CloseThresholdPercentage, OpenThresholdUSD | ETL-computed: formula + defaults |
| UpperBoundary | dbo.etoro_Hedge_InstrumentBoundaries | OpenThresholdUSD | Passthrough with defaults |
| HedgeRiskLimit | dbo.etoro_Hedge_InstrumentBoundaries | HedgeRiskLimitUSD | Rename with defaults |
| FX_Bid | DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument | Bid, Ask, currency pairs | ETL-computed: FX triangulation |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Passthrough |
| HedgeServerID | Dim_Position + Dim_PositionHedgeServerChangeLog_Snapshot | HedgeServerID | ETL-computed: ISNULL(snapshot, position) |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough |
| PriceRatio | DWH_dbo.Dim_HistorySplitRatio | PriceRatio | ETL-computed: ISNULL + first-minute-only |
| HS_Moved_Units | etoro_Trade_PositionsHedgeServerChangeLog + Dim_PositionChangeLog | unit deltas | ETL-computed: HS movement reconstruction |

### 5.2 ETL Pipeline

```
Production sources (Trade.Instrument, Trade.PositionTbl, PriceLog, Hedge.InstrumentBoundaries)
  ↓ Generic Pipeline → Data Lake
  ↓ DWH ETL → DWH_dbo.Dim_Instrument (15,707 rows)
              DWH_dbo.Dim_Position (partitioned by CloseDateID)
              DWH_dbo.Fact_CurrencyPriceWithSplit (17.2M rows)
              DWH_dbo.Dim_HistorySplitRatio (15,899 rows)
              DWH_dbo.Dim_PositionChangeLog
              DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot
              DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date
  ↓ BI_DB ETL → BI_DB_dbo.BI_DB_PositionPnL (prev-day NOP)
  ↓ COPY INTO from Data Lake parquet
              → BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp (intraday prices)
  ↓ SP_Boundary_Cost(@Date) — DELETE @Date + complex multi-source INSERT
  ↓ Dealing_dbo.Dealing_Boundary_Cost (~5.7M rows/weekday)
```

| Step | Object | Description |
|------|--------|-------------|
| Instruments | DWH_dbo.Dim_Instrument | Filtered: Tradable=1, not internal, specific TypeIDs |
| Customers | DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date | Valid customers for @Date and previous day |
| Positions | DWH_dbo.Dim_Position | 3-month lookback window for spreads + @Date for volumes |
| Prev-day NOP | BI_DB_dbo.BI_DB_PositionPnL | Previous day NOP aggregation |
| HS Snapshot | DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | Point-in-time HS assignment |
| Prices | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | COPY INTO from Data Lake parquet (per-day) |
| FX Rates | DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument | FX triangulation |
| Boundaries | dbo.etoro_Hedge_InstrumentBoundaries | Risk thresholds per instrument per HS |
| Split Ratios | DWH_dbo.Dim_HistorySplitRatio | Split adjustment for first minute |
| Change Log | DWH_dbo.Dim_PositionChangeLog | Partial-close unit tracking |
| HS Movements | DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog | Intraday HS reassignment events |
| **ETL** | **Dealing_dbo.SP_Boundary_Cost(@Date)** | DELETE @Date + multi-step INSERT with cumulative NOP window |
| **Target** | **Dealing_dbo.Dealing_Boundary_Cost** | 827 dates, ~5.7M rows/weekday |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, type, currency pairs, asset class |
| DateID | DWH_dbo.Dim_Date (via DateKey) | Calendar date attributes |
| HedgeServerID | DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | Hedge server assignment history |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.Dealing_Boundary_Cost_H_Indices | DateID, InstrumentID | Historical index companion table |

---

## 7. Sample Queries

### 7.1 NOP evolution for a specific instrument on a day

```sql
SELECT
    FromDate,
    ToDate,
    HedgeServerID,
    IsSettled,
    NOP,
    UnitsBuy,
    UnitsSell,
    LastBid,
    LastAsk,
    FX_Bid,
    NOP * ISNULL(FX_Bid, 1) AS NOP_USD
FROM [Dealing_dbo].[Dealing_Boundary_Cost]
WHERE DateID = 20240315
  AND InstrumentID = 1001
ORDER BY HedgeServerID, IsSettled, ToDate;
```

### 7.2 Instruments exceeding upper boundary on a day

```sql
SELECT DISTINCT
    bc.InstrumentID,
    bc.InstrumentName,
    bc.HedgeServerID,
    bc.IsSettled,
    MAX(bc.NOP * ISNULL(bc.FX_Bid, 1)) AS MaxNOP_USD,
    bc.UpperBoundary
FROM [Dealing_dbo].[Dealing_Boundary_Cost] bc
WHERE bc.DateID = 20240315
  AND bc.NOP * ISNULL(bc.FX_Bid, 1) > bc.UpperBoundary
  AND bc.UpperBoundary IS NOT NULL
GROUP BY bc.InstrumentID, bc.InstrumentName, bc.HedgeServerID, bc.IsSettled, bc.UpperBoundary
ORDER BY MaxNOP_USD DESC;
```

### 7.3 Daily total volume by instrument type

```sql
SELECT
    InstrumentType,
    SUM(CAST(VolumeBuy AS BIGINT)) AS TotalVolumeBuy,
    SUM(CAST(VolumeSell AS BIGINT)) AS TotalVolumeSell,
    COUNT(DISTINCT InstrumentID) AS InstrumentCount
FROM [Dealing_dbo].[Dealing_Boundary_Cost]
WHERE DateID = 20240315
GROUP BY InstrumentType
ORDER BY TotalVolumeBuy DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — regen harness mode.)

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Phases: 11/14*
*Tiers: 1 T1, 28 T2, 0 T3, 0 T4 [UNVERIFIED], 2 T5 | Elements: 31/31, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: Dealing_dbo.Dealing_Boundary_Cost | Type: Table | Production Source: Multi-source via SP_Boundary_Cost*
