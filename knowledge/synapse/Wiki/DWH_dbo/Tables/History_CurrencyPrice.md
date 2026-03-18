# DWH_dbo.History_CurrencyPrice

> Synapse external table over the full Bronze PriceLog tick archive - all historical bid/ask prices for every eToro-listed instrument since the Bronze pipeline began. Partitioned by date (etr_y/etr_ym/etr_ymd). Used by SP_Dim_Position and SP_Dim_Instrument via staging derivatives. Always filter by partition or queries will time out.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | External Table (Synapse PolyBase) |
| **Production Source** | PriceLog feed -> Bronze/PriceLog/History/CurrencyPrice/ (ADLS Gen2 Parquet) |
| **Refresh** | Continuous (Bronze PriceLog pipeline writes new tick data; external table reads live) |
| | |
| **Synapse Distribution** | N/A (External Table - no Synapse storage; data in ADLS Gen2) |
| **Synapse Index** | N/A (External Table - no index; access via PolyBase scan) |
| **Data Source** | `internal-sources` (ADLS Gen2) |
| **Location** | `Bronze/PriceLog/History/CurrencyPrice/*/*/*.parquet` |
| **File Format** | SynapseParquetFormat (Parquet) |
| **Partition Columns** | etr_y (year), etr_ym (year-month), etr_ymd (year-month-day) |
| | |
| **UC Target** | Likely already in UC as `bronze.pricelog_history_currencyprice` or similar |
| **UC Format** | Delta or Parquet (from Bronze pipeline) |
| **UC Partitioned By** | etr_y, etr_ym, etr_ymd |
| **UC Table Type** | External (reads from ADLS Bronze container) |

---

## 1. Business Meaning

DWH_dbo.History_CurrencyPrice is a Synapse external table that reads the complete historical price tick archive for all instruments from the Bronze data lake layer. Every tick received by the eToro price feed system is persisted here as a parquet record - capturing bid/ask prices, spread adjustments, USD conversion rates, market rate IDs, and skew values at each point in time.

The production source is `Trade.CurrencyPrice` - the live price cache (one row per ProviderID+InstrumentID, continuously overwritten). When a price update arrives, the tick is also written to `History.CurrencyPrice` (the production database archive) and lands in Bronze via the PriceLog pipeline. The DWH external table reads directly from this Bronze layer.

This is the DWH's primary source for:
- **Position P&L valuation**: SP_Dim_Position_DL_To_Synapse uses staging derivatives (`PriceLog_History_CurrencyPrice_Active`) to get the open/close market prices and USD conversion rates for each position
- **Instrument recency**: SP_Dim_Instrument uses `PriceLog_History_CurrencyPrice_Active` to find when each instrument last had a tick

Key behavioral difference from `Trade.CurrencyPrice` (live cache):
- `Trade.CurrencyPrice`: 1 row per (ProviderID, InstrumentID) - current price only, overwritten continuously
- `History_CurrencyPrice`: All ticks ever - the complete append-only price history archive

**CRITICAL**: This table contains an enormous number of records (tick data for all instruments across all time). A query without a partition filter will timeout or run for very long periods. ALWAYS filter by etr_ymd or etr_ym.

---

## 2. Business Logic

### 2.1 Tick Price Recording

**What**: Each row is a single price tick for one (ProviderID, InstrumentID) pair.

**Columns Involved**: `CurrencyPriceID`, `ProviderID`, `InstrumentID`, `Bid`, `Ask`, `Occurred`, `PriceRateID`

**Rules**:
- `PriceRateID` is the unique tick identifier - joins to position open/close records in Dim_Position (OpenMarketPriceRateID, CloseMarketPriceRateID)
- `MarketPriceRateID`, `BidMarketPriceRateID`, `AskMarketPriceRateID` support split bid/ask source tracking for market data attribution
- `ValidFrom` and `ValidTo` define the interval during which this tick was the "current" price
- `Occurred` is the official tick timestamp; `OccurredOnProvider` is the provider's own timestamp; `ReceivedOnPriceServer` is when eToro received it

### 2.2 Spread Pricing

**What**: Raw market price vs eToro-applied spread for customer execution.

**Columns Involved**: `Bid`, `Ask`, `BidSpreaded`, `AskSpreaded`, `MarkupPips`, `SkewValueBid`, `SkewValueAsk`

**Rules**:
- `Bid`/`Ask`: Raw market bid/ask from the price feed
- `BidSpreaded`/`AskSpreaded`: Customer-facing prices after eToro markup/spread is applied
- `MarkupPips`: The spread markup in PIPs added to the raw market price
- `SkewValueBid`/`SkewValueAsk`: Asymmetric spread adjustments (skew) applied for risk management

### 2.3 USD Conversion Rate

**What**: For non-USD instruments, provides the USD conversion rate at tick time.

**Columns Involved**: `USDConversionRate`, `InstrumentID`

**Rules**:
- For USD-denominated instruments: USDConversionRate = 1.0 (no conversion needed)
- For non-USD instruments (e.g., EUR/USD, GBP/USD): USDConversionRate enables P&L conversion to USD
- SP_Dim_Position uses USDConversionRate (and its spreaded variants) to calculate position USD P&L

### 2.4 Date Partitioning

**What**: Data is physically partitioned in Bronze by date for efficient access.

**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`, `Occurred`

**Rules**:
- `etr_y`: Year partition (e.g., "2024")
- `etr_ym`: Year-month partition (e.g., "2024-06")
- `etr_ymd`: Full date partition (e.g., "2024-06-30") - most granular, use for single-day queries
- These are Parquet partition columns derived from `Occurred`
- ALWAYS include a WHERE clause on etr_ymd or etr_ym to enable partition pruning

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index (External Table)

**In Synapse**, this is an external table - there is NO Synapse storage, no distribution, and no index. All data reads go through PolyBase to ADLS Gen2 Bronze. Performance is entirely determined by partition pruning on etr_y/etr_ym/etr_ymd.

Without partition filter: Query will timeout or run for hours (full parquet scan across years of tick data).
With etr_ymd filter: Reads one day's parquet files only - seconds.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this data is available as the Bronze `pricelog_history_currencyprice` (or similar) table. Partitioned by etr_y, etr_ym, etr_ymd. Access via Delta or Parquet read with partition pushdown.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Price for instrument on specific day | WHERE etr_ymd = '2024-01-15' AND InstrumentID = {id} |
| Latest tick per instrument for a date | WHERE etr_ymd = '{date}' GROUP BY InstrumentID MAX(Occurred) |
| USD conversion rate for position valuation | JOIN ON PriceRateID = position.OpenMarketPriceRateID WHERE etr_ymd BETWEEN dates |
| Spread analysis for an instrument | WHERE InstrumentID = {id} AND etr_ym = '2024-06'; SELECT BidSpreaded - Bid, AskSpreaded - Ask |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON p.OpenMarketPriceRateID = hcp.PriceRateID AND p.InstrumentID = hcp.InstrumentID | Get open price for position P&L |
| DWH_dbo.Dim_Position | ON p.CloseMarketPriceRateID = hcp.PriceRateID AND p.InstrumentID = hcp.InstrumentID | Get close price for position P&L |

### 3.4 Gotchas

- **ALWAYS use partition filter**: Queries without WHERE etr_ymd/etr_ym will timeout. This is a full tick archive - potentially billions of rows.
- **Staging variants**: SP_Dim_Position_DL_To_Synapse and SP_Dim_Instrument use `DWH_staging.PriceLog_History_CurrencyPrice_Active` (1-day window) and `PriceLog_History_CurrencyPrice_Active_5_days` (5-day window), not this full external table. These staging tables are more efficient for ETL.
- **etr_ymd is a string**: Filter as `WHERE etr_ymd = '2024-06-30'` (string comparison), not as a date.
- **No Synapse index or distribution**: All filtering is at the file layer via partition pruning.
- **History_CurrencyPrice_Daily**: A one-day snapshot variant exists (`DWH_dbo.History_CurrencyPrice_Daily`) hardcoded to 2023-03-19, used for testing.
- **Bid/Ask vs BidSpreaded/AskSpreaded**: Raw market prices vs customer-facing prices. Do not confuse for P&L calculations.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

**Identifier Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyPriceID | bigint | YES | Unique tick identifier. Bigint supports high-volume tick stream. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 2 | ProviderID | int | YES | Price provider identifier. Identifies which feed/liquidity provider produced this tick. Composite key with InstrumentID. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 3 | InstrumentID | int | YES | Instrument identifier (EUR/USD=1, GBP=2, etc.). FK to Dim_Instrument. Used to join positions to their price data. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 4 | PriceRateID | bigint | YES | Tick-level rate identifier. Key for joining to Dim_Position.OpenMarketPriceRateID and CloseMarketPriceRateID for P&L calculation. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 5 | MarketPriceRateID | bigint | YES | Market-level rate ID for this tick. Links to the composite market price at this point. Distinct from PriceRateID when bid/ask have separate market sources. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 6 | BidMarketPriceRateID | bigint | YES | Market price rate ID specifically for the bid side. Used when bid and ask are sourced from different market feeds. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 7 | AskMarketPriceRateID | bigint | YES | Market price rate ID specifically for the ask side. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 8 | LiquidityAccountID | int | YES | Liquidity account that provided this price tick. Links to internal liquidity routing configuration. (Tier 4 - inferred from column name) |

**Price Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Bid | numeric(16,8) | YES | Raw market bid price. Best price at which customer can sell. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 10 | Ask | numeric(16,8) | YES | Raw market ask price. Best price at which customer can buy. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 11 | BidSpreaded | numeric(16,8) | YES | Customer-facing bid after eToro markup spread applied. Lower than raw market Bid for sell orders. (Tier 2 - DDL + SP_Dim_Position usage context) |
| 12 | AskSpreaded | numeric(16,8) | YES | Customer-facing ask after eToro markup spread applied. Higher than raw market Ask for buy orders. (Tier 2 - DDL + SP_Dim_Position usage context) |
| 13 | MarkupPips | numeric(19,8) | YES | Spread markup in PIPs added to the raw market price. The DWH-to-customer pricing margin. (Tier 2 - DDL structure) |
| 14 | RateLastEx | numeric(16,8) | YES | Last executed rate at this tick. May differ from Bid/Ask if a trade was executed at a different rate. [UNVERIFIED] (Tier 4 - inferred) |
| 15 | USDConversionRate | numeric(16,8) | YES | USD conversion rate for non-USD instruments at this tick. Used by SP_Dim_Position to convert P&L to USD. 1.0 for USD-based instruments. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 16 | SkewValueBid | numeric(19,8) | YES | Asymmetric spread skew applied to the bid side for risk management. Adjusts effective bid rate. (Tier 2 - DDL structure) |
| 17 | SkewValueAsk | numeric(19,8) | YES | Asymmetric spread skew applied to the ask side. (Tier 2 - DDL structure) |

**Timestamp Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 18 | ValidFrom | datetime2(7) | YES | Start of the period during which this tick was the "current" price. Used for temporal price lookups. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 19 | ValidTo | datetime2(7) | YES | End of the period during which this tick was current. ValidFrom/ValidTo define a non-overlapping time series per (ProviderID, InstrumentID). (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 20 | Occurred | datetime2(7) | YES | Official timestamp of the price tick (eToro system time). Primary temporal reference for price history. Source for partition columns etr_y/etr_ym/etr_ymd. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 21 | OccurredOnProvider | datetime2(7) | YES | Timestamp reported by the external price provider. May differ from Occurred due to network latency. (Tier 1 - upstream wiki, Trade.CurrencyPrice) |
| 22 | ReceivedOnPriceServer | datetime2(7) | YES | Timestamp when eToro price server received this tick. Used by SP_Dim_Instrument to detect instrument recency: "last tick received for this instrument". (Tier 2 - SP_Dim_Instrument usage: min(ReceivedOnPriceServer) for instrument last seen) |
| 23 | MarketReceivedTime | datetime2(7) | YES | Timestamp when the market feed received this tick from the exchange. (Tier 4 - inferred) |

**Partition Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 24 | etr_y | nvarchar(4000) | YES | Year partition column (e.g., "2024"). Physical parquet partition for Bronze/PriceLog/History/CurrencyPrice/etr_y={y}/. ALWAYS include in WHERE for year-level filtering. (Tier 2 - DDL + parquet location pattern) |
| 25 | etr_ym | nvarchar(4000) | YES | Year-month partition column (e.g., "2024-06"). Physical parquet partition. Use for monthly queries. (Tier 2 - DDL + parquet location pattern) |
| 26 | etr_ymd | nvarchar(4000) | YES | Year-month-day partition column (e.g., "2024-06-30"). Most granular partition. Use for daily queries. Filter as string: WHERE etr_ymd = '2024-06-30'. (Tier 2 - DDL + parquet location pattern) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CurrencyPriceID | Trade.CurrencyPrice / History.CurrencyPrice | CurrencyPriceID | passthrough |
| ProviderID | Trade.CurrencyPrice / History.CurrencyPrice | ProviderID | passthrough |
| InstrumentID | Trade.CurrencyPrice / History.CurrencyPrice | InstrumentID | passthrough |
| Bid, Ask | Trade.CurrencyPrice / History.CurrencyPrice | Bid, Ask | passthrough (raw market) |
| BidSpreaded, AskSpreaded | Trade.CurrencyPrice / History.CurrencyPrice | BidSpreaded, AskSpreaded | passthrough |
| PriceRateID | Trade.CurrencyPrice / History.CurrencyPrice | PriceRateID | passthrough |
| USDConversionRate | Trade.CurrencyPrice / History.CurrencyPrice | USDConversionRate | passthrough |
| ValidFrom, ValidTo | Trade.CurrencyPrice / History.CurrencyPrice | ValidFrom, ValidTo | passthrough |
| Occurred | Trade.CurrencyPrice / History.CurrencyPrice | Occurred | passthrough; source for etr_y/etr_ym/etr_ymd partitions |
| etr_y, etr_ym, etr_ymd | Bronze PriceLog pipeline | Occurred | ETL-computed partition columns |
| (all other columns) | Trade.CurrencyPrice / History.CurrencyPrice | same name | passthrough |

### 5.2 ETL Pipeline

```
Price Feed (external providers, market data)
  -> Trade.SetCurrencyPrice (production SP - updates live cache)
       -> Trade.CurrencyPrice (live cache, 1 row per ProviderID+InstrumentID)
  -> History.CurrencyPrice (production DB archive, all ticks)
       -> PriceLog Generic Pipeline -> Bronze/PriceLog/History/CurrencyPrice/etr_y={y}/etr_ym={ym}/etr_ymd={ymd}/*.parquet
            -> DWH_dbo.History_CurrencyPrice (External Table, reads directly from Bronze)

DWH Consumers:
  -> DWH_staging.PriceLog_History_CurrencyPrice_Active (1-day window staging)
       -> SP_Dim_Instrument (ReceivedOnPriceServer for instrument recency)
  -> DWH_staging.PriceLog_History_CurrencyPrice_Active_5_days (5-day window staging)
       -> SP_Dim_Position_DL_To_Synapse (Open/Close market price + USD conversion for P&L)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| PriceRateID | DWH_dbo.Dim_Position (OpenMarketPriceRateID, CloseMarketPriceRateID) | Position P&L valuation join |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_staging.PriceLog_History_CurrencyPrice_Active | - | 1-day staging derivative of this external table |
| DWH_staging.PriceLog_History_CurrencyPrice_Active_5_days | - | 5-day staging derivative |
| DWH_dbo.SP_Dim_Instrument | ReceivedOnPriceServer | Finds last price tick per instrument |
| DWH_dbo.SP_Dim_Position_DL_To_Synapse | PriceRateID, BidSpreaded, AskSpreaded, USDConversionRate | Enriches positions with open/close market prices |
| DWH_dbo.History_CurrencyPrice_Daily | - | Single-day hardcoded variant (2023-03-19 test snapshot) |

---

## 7. Sample Queries

### 7.1 Single-day price sample (ALWAYS filter by etr_ymd!)
```sql
SELECT TOP 10
    InstrumentID, ProviderID, Bid, Ask, BidSpreaded, AskSpreaded,
    USDConversionRate, MarkupPips, Occurred
FROM [DWH_dbo].[History_CurrencyPrice]
WHERE etr_ymd = '2024-06-30'
ORDER BY Occurred DESC;
```

### 7.2 Latest tick per instrument on a specific day
```sql
SELECT InstrumentID, MAX(Occurred) AS LastTick
FROM [DWH_dbo].[History_CurrencyPrice]
WHERE etr_ymd = '2024-06-30'
GROUP BY InstrumentID
ORDER BY LastTick DESC;
```

### 7.3 Look up price for a position (by PriceRateID)
```sql
SELECT hcp.InstrumentID, hcp.Bid, hcp.Ask, hcp.BidSpreaded, hcp.AskSpreaded, hcp.USDConversionRate
FROM [DWH_dbo].[History_CurrencyPrice] hcp
WHERE hcp.etr_ymd = '2024-06-30'
  AND hcp.PriceRateID = {position_price_rate_id}
  AND hcp.InstrumentID = {instrument_id};
```

### 7.4 Daily spread analysis for a specific instrument
```sql
SELECT etr_ymd, AVG(CAST(AskSpreaded - Ask AS float)) AS AvgAskSpread,
       AVG(CAST(Bid - BidSpreaded AS float)) AS AvgBidSpread
FROM [DWH_dbo].[History_CurrencyPrice]
WHERE etr_ym = '2024-06'
  AND InstrumentID = 1
GROUP BY etr_ymd
ORDER BY etr_ymd;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP unavailable this session.)

---

*Generated: 2026-03-18 | Quality: 7.2/10 (★★★★☆) | Phases: 11/14*
*Tiers: 10 T1, 6 T2, 0 T3, 3 T4 [UNVERIFIED], 0 T5 | Elements: 7/10, Logic: 7/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.History_CurrencyPrice | Type: External Table | Production Source: PriceLog Generic Pipeline -> Bronze/PriceLog/History/CurrencyPrice/ (Parquet)*
