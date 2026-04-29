# Dealing_dbo.Dealing_Boundary_Cost

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Boundary_Cost |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `DateID` |
| **Columns** | 33 |
| **Primary Source** | Multi-source ETL: DWH_dbo.Dim_Position, DWH_dbo.Dim_Instrument, BI_DB_dbo.BI_DB_PositionPnL, PriceLog lake (BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp), dbo.etoro_Hedge_InstrumentBoundaries |
| **ETL SP** | `Dealing_dbo.SP_Boundary_Cost` |
| **Refresh** | Daily (parameter-driven per @Date) |
| **PII** | none |
| **Tags** | dealing, hedging, NOP, boundary, intraday, risk |

---

## 1. Business Meaning

`Dealing_Boundary_Cost` stores **per-minute snapshots of Net Open Position (NOP) and hedge boundary metrics** for every tradable instrument × HedgeServer × IsSettled combination, computed for a single trading day. Each row represents a one-minute window for a specific instrument on a specific HedgeServer, tracking how much client exposure (buy/sell units) entered or exited the market in that minute, the running cumulative NOP, current market prices, and whether the NOP is within the configured hedge boundary limits.

The Dealing team uses this table to monitor **intraday hedge risk**: as NOP builds up throughout the trading day, it can breach the `LowerBoundary` (net sell exposure limit) or `UpperBoundary` (net buy exposure limit) configured for each instrument on each HedgeServer. This table is the data source for boundary-cost analysis, showing both the realized volumes and the price impact of client trading activity in real time.

The table is populated once per trading day by `SP_Boundary_Cost(@Date)`. The SP deletes existing rows for `@Date` and re-inserts the full day's minute-by-minute data. The latest available date is 2024-03-17 based on live data sampling.

**IsSettled** distinguishes between real-asset positions (settled=1, primarily stocks/ETFs/crypto) and CFD positions (settled=0). HedgeServerID tracks which hedge server holds the net position — instruments can be distributed across multiple hedge servers, and positions can be moved between servers during the day.

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_Boundary_Cost` accepts a single `@Date` parameter and computes the entire day's minute-by-minute data:

1. **Filter active instruments**: Selects tradable, publicly visible instruments from `Dim_Instrument` where `InstrumentTypeID IN (2,4,5,6)` (commodities, indices, stocks, ETFs) or crypto with `SellCurrencyID = 1` (USD-denominated crypto).
2. **Previous-day NOP baseline**: Reads `BI_DB_PositionPnL` for `@PreviousDay` to establish each instrument's starting NOP at the beginning of `@Date`.
3. **Position universe**: Loads `Dim_Position` rows that opened or closed within the past 2 months (for spread calculation) and joins with `Dim_PositionHedgeServerChangeLog_Snapshot` to assign the correct HedgeServerID at `@Date` (handles HS migrations).
4. **Per-minute volume aggregation**: For each instrument, buckets all position opens and closes into 1-minute windows (`#VolumeByMinute`), computing UnitsBuy, UnitsSell, WAVG prices, and variable spread cost.
5. **Minute timeline spine**: Generates a full 1440-row minute spine for `@Date` and cross-joins with the instrument×HS×IsSettled list, left-joining per-minute volume. This ensures every minute is represented even if no trades occurred (`#SumWithoutNulls`).
6. **Price feed**: Copies real-time price log from the data lake (`/internal-sources/Bronze/PriceLog/History/CurrencyPrice/`) into `BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp` via COPY INTO, then aligns the last price in each minute to the minute spine.
7. **FX conversion**: Computes `FX_Bid` for non-USD instruments by triangulating through `Fact_CurrencyPriceWithSplit`.
8. **Boundary limits**: Reads `dbo.etoro_Hedge_InstrumentBoundaries` for each instrument×HedgeServer pair. `LowerBoundary = (-1) × (CloseThresholdPercentage × OpenThresholdUSD) / 100`; `UpperBoundary = OpenThresholdUSD`. Defaults apply for Stocks/ETFs (InstrumentTypeID 5,6) when no boundary is configured.
9. **HS-moved units**: Tracks units that were moved between HedgeServers during `@Date` (via `Dim_PositionChangeLog` ChangeTypeID=12), building a historical reconstruction of unit movements.
10. **Cumulative NOP**: Computed as a window function: `previous_day_NOP + SUM(UnitsBuy - UnitsSell) OVER (ORDER BY ToDate)` per instrument×HS×IsSettled.

### Spread Calculation

`StdSpreadPercent` is the **standard deviation of the bid-ask spread as a percentage of mid-price**, computed quarterly (trailing 2 months from start of the current month). This is a normalized measure of instrument volatility/spread cost — higher values mean more spread risk for boundary management.

### HS-Moved Units

`HS_Moved_Units` records units that were physically transferred from one HedgeServer to another during the day. These are tracked separately because they affect the NOP of both the source and destination HS but don't represent new client trading activity.

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata source (name, type, currencies) |
| `DWH_dbo.Dim_Position` | `PositionID` | Client position data (volumes, prices, open/close dates) |
| `BI_DB_dbo.BI_DB_PositionPnL` | `InstrumentID, HedgeServerID, IsSettled` | Previous-day NOP baseline |
| `DWH_dbo.Fact_SnapshotCustomer` | `RealCID` | Filters to valid customer population |
| `DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot` | `PositionID` | HS assignment at reporting date |
| `DWH_dbo.Dim_PositionChangeLog` | `PositionID` | HS migration unit tracking |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID` | FX conversion rates |
| `DWH_dbo.Dim_HistorySplitRatio` | `InstrumentID, MaxDate` | Stock split price ratio |
| `dbo.etoro_Hedge_InstrumentBoundaries` | `InstrumentID, HedgeServerID` | Upper/lower boundary thresholds |
| `BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp` | `InstrumentID, minute` | Real-time price log from lake |
| `Dealing_dbo.Dealing_Boundary_Cost_H_Indices` | Related table | Indices-specific historical variant (separate table) |

**Referenced By**: This table is the primary input for boundary cost analysis and dealing dashboard reporting. See `Dealing_dbo.Dealing_Boundary_Cost_H_Indices` for the historical indices-only variant.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki verbatim | `(Tier 1 — DWH_dbo.Dim_Instrument)` |
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Boundary_Cost)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |
| ★ | Tier 4 — inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date for which this set of minute snapshots was computed. All rows in a given batch share the same Date value. Set to `@Date` parameter in SP_Boundary_Cost. (Tier 2 — SP_Boundary_Cost) |
| 2 | DateID | int | YES | Integer representation of Date in YYYYMMDD format (e.g., 20240317). Used as the clustered index key for efficient date-range filtering. Computed as `CONVERT(NVARCHAR, @Date, 112)`. (Tier 2 — SP_Boundary_Cost) |
| 3 | FromDate | datetime | YES | Start of the one-minute time window for this row. Truncated to the minute boundary. Together with ToDate, defines the 1-minute bucket this row represents. (Tier 2 — SP_Boundary_Cost) |
| 4 | ToDate | datetime | YES | End of the one-minute time window (FromDate + 1 minute). Used as the join key when aligning volume data to the minute spine. (Tier 2 — SP_Boundary_Cost) |
| 5 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Referenced by virtually every trading fact table. FK to DWH_dbo.Dim_Instrument. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 6 | InstrumentName | varchar(100) | YES | User-facing instrument display name from `Dim_Instrument.InstrumentDisplayName`. More descriptive than the internal Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 — SP_Boundary_Cost, via Dim_Instrument) |
| 7 | InstrumentType | varchar(50) | YES | Text label for the instrument category: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. DWH-computed via CASE on InstrumentTypeID. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 8 | StdSpreadPercent | decimal(16,6) | YES | Standard deviation of the bid-ask spread as a percentage of mid-price, averaged over the trailing quarterly period (2 months from start of current month). Computed from historical position open/close prices. Higher values indicate instruments with more volatile spreads — relevant for boundary risk estimation. NULL when insufficient price history exists. (Tier 2 — SP_Boundary_Cost) |
| 9 | LastBid | decimal(16,6) | YES | Last bid price observed in this minute window, sourced from the PriceLog lake feed (`PriceLog_History_CurrencyPrice_Active_tmp`). The most recent bid price before or at the ToDate boundary. NULL if no price tick arrived in this minute. (Tier 2 — SP_Boundary_Cost) |
| 10 | LastAsk | decimal(16,6) | YES | Last ask price observed in this minute window from the PriceLog lake feed. NULL if no price tick arrived. (Tier 2 — SP_Boundary_Cost) |
| 11 | Mid | decimal(16,6) | YES | Mid-price computed as `(LastAsk + LastBid) / 2`. Used in spread percentage calculation. NULL when either bid or ask is NULL. (Tier 2 — SP_Boundary_Cost) |
| 12 | LastBidSpreaded | decimal(16,6) | YES | Bid price with eToro's spread markup applied (spreaded = bid adjusted for client-facing spread). Sourced from `PriceLog_History_CurrencyPrice_Active_tmp.BidSpreaded`. This is the price a selling client receives. NULL if no price tick. (Tier 2 — SP_Boundary_Cost) |
| 13 | LastAskSpreaded | decimal(16,6) | YES | Ask price with eToro's spread markup applied. Sourced from `PriceLog_History_CurrencyPrice_Active_tmp.AskSpreaded`. This is the price a buying client pays. NULL if no price tick. (Tier 2 — SP_Boundary_Cost) |
| 14 | UnitsBuy | decimal(16,6) | YES | Net units of new long (buy) positions opened by clients in this minute window, summed across all valid customers active on `@Date`. Derived from `Dim_Position.AmountInUnitsDecimal` for positions where `IsBuy=1`. Zero when no buy activity in this minute. (Tier 2 — SP_Boundary_Cost) |
| 15 | UnitsSell | decimal(16,6) | YES | Net units of new short (sell) positions opened (or long positions closed, which creates reverse exposure) in this minute window. Derived from `Dim_Position.AmountInUnitsDecimal` for positions where `IsBuy=0`. Zero when no sell activity. (Tier 2 — SP_Boundary_Cost) |
| 16 | WAVG_BuyPrice | decimal(16,6) | YES | Volume-weighted average forex rate for buy positions opened in this minute. Computed as `SUM(units × InitForexRate) / SUM(units)` for `IsBuy=1`. Represents the effective price at which the net buy exposure was established. Zero when UnitsBuy=0. (Tier 2 — SP_Boundary_Cost) |
| 17 | WAVG_SellPrice | decimal(16,6) | YES | Volume-weighted average forex rate for sell positions opened (or close events) in this minute. Computed as `SUM(units × EndForexRate) / SUM(units)` for `IsBuy=0`. Zero when UnitsSell=0. (Tier 2 — SP_Boundary_Cost) |
| 18 | NOP | decimal(20,6) | YES | Cumulative Net Open Position in units at the end of this minute. Computed as: `previous_day_NOP (from BI_DB_PositionPnL) + SUM(UnitsBuy - UnitsSell) OVER (PARTITION BY InstrumentID, HedgeServerID, IsSettled ORDER BY ToDate)`. Positive NOP = net long client exposure (eToro is net short, may need to hedge); negative NOP = net short client exposure. This is the key risk metric compared against LowerBoundary / UpperBoundary. (Tier 2 — SP_Boundary_Cost) |
| 19 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_Boundary_Cost (`GETDATE()`). Not a business timestamp. (Tier 2 — SP_Boundary_Cost) |
| 20 | VolumeBuy | decimal(16,6) | YES | Total USD volume from buy position opens in this minute. Computed as `SUM(AmountInUnitsDecimal × InitForexRate)` for `IsBuy=1` × FX conversion. Represents the USD value of buy flow. (Tier 2 — SP_Boundary_Cost) |
| 21 | VolumeSell | decimal(16,6) | YES | Total USD volume from sell position opens (or close events) in this minute. Computed as `SUM(VolumeOnClose)` for `IsBuy=0`. (Tier 2 — SP_Boundary_Cost) |
| 22 | VariableSpread | decimal(16,6) | YES | Total variable spread cost in USD for all positions opened/closed in this minute. Computed as `SUM(units × (Ask - Bid) × FX_conversion_rate)`. This is the spread revenue/cost of the instrument in this window. (Tier 2 — SP_Boundary_Cost) |
| 23 | LowerBoundary | decimal(16,4) | YES | Lower NOP threshold (negative value) for this instrument×HedgeServer combination. Sourced from `dbo.etoro_Hedge_InstrumentBoundaries` as `(-1) × (CloseThresholdPercentage × OpenThresholdUSD) / 100`. When NOP drops below LowerBoundary, the position indicates excessive short client exposure. Default -50,000 for Stocks/ETFs when no boundary configured. (Tier 2 — SP_Boundary_Cost) |
| 24 | UpperBoundary | decimal(16,4) | YES | Upper NOP threshold (positive value) for this instrument×HedgeServer. Sourced from `dbo.etoro_Hedge_InstrumentBoundaries.OpenThresholdUSD`. When NOP exceeds UpperBoundary, the instrument's long client exposure may require hedging. Default 500,000 for Stocks/ETFs when no boundary configured. (Tier 2 — SP_Boundary_Cost) |
| 25 | HedgeRiskLimit | decimal(16,4) | YES | Maximum acceptable hedge risk in USD for this instrument×HedgeServer. Sourced from `dbo.etoro_Hedge_InstrumentBoundaries.HedgeRiskLimitUSD`. Used to cap the total risk exposure managed by the dealing desk. Default 250,000 for Stocks/ETFs when no boundary configured. (Tier 2 — SP_Boundary_Cost) |
| 26 | FX_Bid | decimal(16,6) | YES | FX conversion rate to USD for this instrument's sell currency. Sourced from `Fact_CurrencyPriceWithSplit` for the reporting date. For USD-denominated instruments (SellCurrencyID=1), FX_Bid=1.0. For EUR instruments, FX_Bid = 1/EUR_Bid. Used to normalize NOP and volume metrics to USD equivalents. (Tier 2 — SP_Boundary_Cost) |
| 27 | InstrumentTypeID | int | YES | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Used for boundary default logic (Stocks/ETFs get defaults when no boundary configured). (Tier 1 — DWH_dbo.Dim_Instrument) |
| 28 | HedgeServerID | int | YES | Identifier for the hedge server holding these positions. Positions can be distributed across multiple hedge servers; this dimension tracks per-HS NOP separately. HS assignment at `@Date` is resolved via `Dim_PositionHedgeServerChangeLog_Snapshot` (handles same-day HS migrations). NULL for rows in the UNION ALL that only have NOP carry-forward data. (Tier 2 — SP_Boundary_Cost) |
| 29 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 30 | PriceRatio | decimal(16,6) | YES | Stock split-adjusted price ratio sourced from `DWH_dbo.Dim_HistorySplitRatio`. Applied only to the first minute of the day (ROW_NUMBER()=1 per instrument×HS×IsSettled) when a split occurred on `@Date`. Used to adjust NOP calculations when a stock split changes the unit count. 1.0 when no split occurred or for non-split instruments. (Tier 2 — SP_Boundary_Cost) |
| 31 | HS_Moved_Units | decimal(20,6) | YES | Net units transferred between HedgeServers during `@Date` for this instrument×HS×IsSettled. Tracked via `Dim_PositionChangeLog` ChangeTypeID=12 (HedgeServer change events). Positive values indicate units arriving at this HS; negative values indicate units leaving. Used to reconcile NOP changes that are not due to new client trades but due to HS rebalancing. Zero when no HS moves occurred. (Tier 2 — SP_Boundary_Cost) |

---

## 5. Usage Notes

**Querying intraday NOP evolution**: Filter by `Date`, `InstrumentID`, `HedgeServerID`, and `IsSettled`, then order by `FromDate` to trace how NOP built up through the trading day. Compare `NOP` against `LowerBoundary`/`UpperBoundary` to identify when hedging thresholds were breached.

**Distribution**: ROUND_ROBIN with a clustered index on `DateID`. Efficient for single-date queries (common in dealing dashboard use cases). For multi-date range queries, add `InstrumentID` or `HedgeServerID` to the WHERE clause to limit scanned rows.

**Performance pitfall**: The table can be very large on active trading days — the spine is 1440 minutes × N instruments × M HedgeServers × 2 IsSettled values. For large date ranges, always filter on `DateID` first (the clustered index key) before filtering on InstrumentID.

**HedgeServer granularity**: The same instrument can appear with multiple `HedgeServerID` values on the same date. Always include `HedgeServerID` and `IsSettled` in GROUP BY when aggregating NOP across hedge servers, or you'll double-count.

**Boundary comparison**: `NOP < LowerBoundary` → excessive net short client exposure; `NOP > UpperBoundary` → excessive net long client exposure requiring hedge. Both boundaries use absolute USD values (before FX conversion) — multiply NOP by FX_Bid for USD-equivalent comparison.

**Data staleness**: Max date observed was 2024-03-17 — this table may retain only recent rolling history. The SP re-runs for a specific date on demand.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Multi-source: DWH_dbo dimensions + BI_DB_dbo.BI_DB_PositionPnL + lake price feed + Synapse prod table (etoro_Hedge_InstrumentBoundaries) |
| **Refresh** | Daily per date via `SP_Boundary_Cost(@Date)` — delete+insert pattern |
| **PII** | none — aggregate/instrument level, no CID-level data |
| **Owner** | Dealing team |
| **Migration Note** | See `NoDbObjectsScripts/2024_09_16_Dealing_Migration.Dealing_Boundary_Cost.sql` — migrated from legacy Dealing_Migration schema Sep 2024 |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL, distribution, index analyzed |
| Live Data | 4/5 | Sample confirmed, row count query timed out |
| SP Logic | 5/5 | Complete SP analysis (1300+ line SP) |
| Upstream Wiki | 3/5 | DWH_dbo Dim_Instrument wiki available; no Generic Pipeline production match |
| Business Context | 2/5 | Atlassian MCP unavailable; dealing hedge boundary context inferred from SP |
| **Total** | **7.5/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
