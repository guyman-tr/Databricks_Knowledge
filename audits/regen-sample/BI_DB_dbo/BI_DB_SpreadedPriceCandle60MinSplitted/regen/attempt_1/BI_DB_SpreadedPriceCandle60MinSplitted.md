# BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted

> 48.8M-row spread-adjusted 60-minute OHLC price candle table covering 8,445 instruments across 2 providers from 2015-01-01 to 2024-06-02. Sourced externally from the production Candle Builder service (Price:12 / Candles DB). Last updated 2024-06-02; appears dormant since then.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Candle Builder service (Price:12 / Candles DB on AO-CANDLES-LSN); no Synapse writer SP |
| **Refresh** | Dormant since 2024-06-02; previously loaded via external migration pipeline |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateFrom ASC, DateTo ASC, ProviderID ASC, InstrumentID ASC) |
| **Secondary Index** | IX_BI_DB_SpreadedPriceCandle60MinSplitted (InstrumentID ASC, DateFrom ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table stores 60-minute OHLC (Open/High/Low/Close) price candle data with spread-adjusted Ask and Bid prices for financial instruments traded on the eToro platform. Each row represents one 60-minute candle for a specific provider-instrument combination, capturing:

- **Ask prices**: First (open), Last (close), Min (low), Max (high) for the ask side
- **Bid prices**: First (open), Last (close), Min (low), Max (high) for the bid side
- **Occurrence timestamps**: The exact datetime when each Ask/Bid price extreme occurred within the candle window

The table contains 48.8M rows spanning 8,445 distinct instruments and 2 providers (ProviderID=1 with 48.8M rows, ProviderID=0 with 4,349 rows). Date range covers 2015-01-01 through 2024-06-02.

The production source is the Candle Builder service, which generates candle data from incoming real-time rate feeds via RabbitMQ (PriceExchange). The service writes to the Price:12 (Candles DB) on AO-CANDLES-LSN, and the data was migrated into Synapse via an external bulk load pipeline (BI_DB_Migration schema with varchar staging columns). No Synapse stored procedure writes to this table.

The table is consumed by several downstream SPs for NOP (Net Open Position) and exposure calculations: SP_DailyNOP_ByInstrument (last BidLast price per instrument), SP_M_EOMExposures (end-of-month AskLast/BidLast), SP_NOP_LPandClients (AskLast/BidLast for LP/client NOP), and SP_Max_NOP (hourly AskLast/BidLast joined on DateTo for max NOP calculations).

---

## 2. Business Logic

### 2.1 OHLC Candle Structure

**What**: Each row is a standard financial OHLC candle with a 60-minute window, but split into separate Ask and Bid sides to reflect the broker spread.
**Columns Involved**: AskFirst, AskLast, AskMin, AskMax, BidFirst, BidLast, BidMin, BidMax
**Rules**:
- First = opening price at start of the 60-minute window (equivalent to Open)
- Last = closing price at end of the 60-minute window (equivalent to Close)
- Min = lowest price during the window (equivalent to Low)
- Max = highest price during the window (equivalent to High)
- Ask prices are always >= Bid prices (the spread)

### 2.2 Candle Time Windows

**What**: Each candle covers a fixed 60-minute interval defined by DateFrom (inclusive) and DateTo (exclusive).
**Columns Involved**: DateFrom, DateTo
**Rules**:
- DateTo = DateFrom + 1 hour (exact 60-minute windows)
- Windows are contiguous and non-overlapping per provider-instrument pair
- Downstream SPs filter by `DateFrom < @TargetDate` to get the latest candle before a given point

### 2.3 Price Occurrence Timestamps

**What**: Each price extreme (First, Last, Min, Max) has an associated timestamp recording when that price was observed within the candle window.
**Columns Involved**: AskFirstOccurred, AskLastOccurred, AskMinOccurred, AskMaxOccurred, BidFirstOccurred, BidLastOccurred, BidMinOccurred, BidMaxOccurred
**Rules**:
- Occurrence timestamps may fall slightly outside the DateFrom-DateTo window (observed in sample data: AskFirstOccurred can precede DateFrom by hours, likely due to weekend/holiday carryover)
- All 8 occurrence columns are nullable

### 2.4 Provider Segmentation

**What**: Data is partitioned by ProviderID identifying the price feed source.
**Columns Involved**: ProviderID
**Rules**:
- ProviderID=1: primary provider with 48.8M rows (99.99%)
- ProviderID=0: secondary/fallback provider with 4,349 rows (0.01%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table uses ROUND_ROBIN distribution, meaning data is evenly spread across all distributions without affinity to any column. The clustered index on (DateFrom, DateTo, ProviderID, InstrumentID) makes date-range queries efficient. A secondary non-clustered index on (InstrumentID, DateFrom) optimizes instrument-specific lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Get latest price for an instrument | `SELECT TOP 1 BidLast, AskLast FROM ... WHERE InstrumentID = @id ORDER BY DateFrom DESC` (uses NCI) |
| Get last price before a date | `WHERE DateFrom < @date ORDER BY DateFrom DESC` with `ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY DateFrom DESC)` |
| Get all candles for an instrument in a date range | `WHERE InstrumentID = @id AND DateFrom >= @start AND DateFrom < @end` (uses NCI) |
| Calculate daily spread | `AVG(AskLast - BidLast)` grouped by `CAST(DateFrom AS DATE)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name, type, currency pair |
| BI_DB_dbo.BI_DB_PositionPnL | InstrumentID = InstrumentID (+ date alignment) | Price for NOP/PnL calculations |

### 3.4 Gotchas

- **Large table**: 48.8M rows. Always filter by DateFrom or InstrumentID; avoid full scans.
- **Dormant since 2024-06-02**: No new data since June 2024. Do not rely on this table for current prices.
- **Occurrence timestamps outside candle window**: AskFirstOccurred/BidFirstOccurred can precede DateFrom (weekend/holiday carryover from prior candle).
- **ProviderID=0 is nearly empty**: Only 4,349 rows. Most analysis should filter to ProviderID=1.
- **ROUND_ROBIN distribution**: JOINs on InstrumentID will cause data movement. Consider materializing subsets into HASH(InstrumentID) temp tables for multi-join queries (as downstream SPs do).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, sample data, and downstream SP usage; no upstream wiki or writer SP available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProviderID | int | NO | Price feed provider identifier. ProviderID=1 is the primary source (48.8M rows); ProviderID=0 is a secondary/fallback source (4,349 rows). Part of the clustered index. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and data distribution) |
| 2 | InstrumentID | int | NO | Financial instrument identifier. FK to Dim_Instrument. 8,445 distinct instruments observed. Part of the clustered index and NCI. Used by downstream SPs (SP_DailyNOP_ByInstrument, SP_M_EOMExposures, SP_NOP_LPandClients, SP_Max_NOP) to join price data to position/NOP calculations. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL, sample data, and downstream SP JOINs) |
| 3 | DateFrom | datetime | NO | Start of the 60-minute candle window (inclusive). Part of the clustered index and NCI. Downstream SPs filter on this column to locate the most recent candle before a target date. Range: 2015-01-01 to 2024-06-02. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and downstream SP usage) |
| 4 | DateTo | datetime | NO | End of the 60-minute candle window (exclusive). Equals DateFrom + 1 hour. Part of the clustered index. SP_Max_NOP joins on DateTo to match hourly holdings snapshots to candle close prices. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and SP_Max_NOP JOIN logic) |
| 5 | AskFirst | numeric(16,8) | YES | Ask (offer) price at the opening of the 60-minute candle window. The first ask quote recorded in the interval. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention) |
| 6 | AskLast | numeric(16,8) | YES | Ask (offer) price at the close of the 60-minute candle window. The last ask quote recorded in the interval. Used by SP_M_EOMExposures and SP_NOP_LPandClients for end-of-period pricing; SP_Max_NOP uses it to compute LocalAmount for short positions. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and downstream SP usage) |
| 7 | AskMin | numeric(16,8) | YES | Lowest ask (offer) price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention) |
| 8 | AskMax | numeric(16,8) | YES | Highest ask (offer) price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention) |
| 9 | BidFirst | numeric(16,8) | YES | Bid price at the opening of the 60-minute candle window. The first bid quote recorded in the interval. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention) |
| 10 | BidLast | numeric(16,8) | YES | Bid price at the close of the 60-minute candle window. The last bid quote recorded in the interval. Used by SP_DailyNOP_ByInstrument as the last known price per instrument; SP_M_EOMExposures and SP_NOP_LPandClients use it for end-of-period pricing; SP_Max_NOP uses it to compute LocalAmount for long positions. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and downstream SP usage) |
| 11 | BidMin | numeric(16,8) | YES | Lowest bid price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention) |
| 12 | BidMax | numeric(16,8) | YES | Highest bid price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention) |
| 13 | AskFirstOccurred | datetime | YES | Exact timestamp when AskFirst (opening ask price) was recorded. May precede DateFrom due to weekend/holiday carryover from the prior trading session. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 14 | AskLastOccurred | datetime | YES | Exact timestamp when AskLast (closing ask price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 15 | AskMinOccurred | datetime | YES | Exact timestamp when AskMin (lowest ask price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 16 | AskMaxOccurred | datetime | YES | Exact timestamp when AskMax (highest ask price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 17 | BidFirstOccurred | datetime | YES | Exact timestamp when BidFirst (opening bid price) was recorded. May precede DateFrom due to weekend/holiday carryover from the prior trading session. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 18 | BidLastOccurred | datetime | YES | Exact timestamp when BidLast (closing bid price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 19 | BidMinOccurred | datetime | YES | Exact timestamp when BidMin (lowest bid price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 20 | BidMaxOccurred | datetime | YES | Exact timestamp when BidMax (highest bid price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |
| 21 | UpdateDate | datetime | YES | Timestamp of the last ETL load or update for this row. Range: 2019-11-12 to 2024-06-02. Many older rows share UpdateDate=2019-11-12, suggesting a bulk historical reload. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| ProviderID | Price:12 Candles DB | ProviderID | Passthrough |
| InstrumentID | Price:12 Candles DB | InstrumentID | Passthrough |
| DateFrom | Price:12 Candles DB | DateFrom | Passthrough (varchar -> datetime via migration) |
| DateTo | Price:12 Candles DB | DateTo | Passthrough (varchar -> datetime via migration) |
| AskFirst | Price:12 Candles DB | AskFirst | Passthrough |
| AskLast | Price:12 Candles DB | AskLast | Passthrough |
| AskMin | Price:12 Candles DB | AskMin | Passthrough |
| AskMax | Price:12 Candles DB | AskMax | Passthrough |
| BidFirst | Price:12 Candles DB | BidFirst | Passthrough |
| BidLast | Price:12 Candles DB | BidLast | Passthrough |
| BidMin | Price:12 Candles DB | BidMin | Passthrough |
| BidMax | Price:12 Candles DB | BidMax | Passthrough |
| Ask*Occurred | Price:12 Candles DB | Ask*Occurred | Passthrough (varchar -> datetime via migration) |
| Bid*Occurred | Price:12 Candles DB | Bid*Occurred | Passthrough (varchar -> datetime via migration) |
| UpdateDate | Price:12 Candles DB | UpdateDate | Passthrough (varchar -> datetime via migration) |

### 5.2 ETL Pipeline

```
Candle Builder Service (real-time rate feeds via RabbitMQ PriceExchange)
  |-- Writes to T_PriceCandle60Min (production Candles DB, AO-CANDLES-LSN) ---|
  v
Price:12 Candles DB (AO-CANDLES-LSN)
  |-- External migration / bulk load (varchar staging) ---|
  v
BI_DB_Migration.BI_DB_SpreadedPriceCandle60MinSplitted (staging, varchar dates)
  |-- Type conversion (varchar -> datetime, varchar -> datetime) ---|
  v
BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted (48.8M rows, dormant since 2024-06-02)
  |-- Read by SP_DailyNOP_ByInstrument → BI_DB_DailyNOP_ByInstrument
  |-- Read by SP_M_EOMExposures → BI_DB_EOMExposures
  |-- Read by SP_NOP_LPandClients → Dealing_dbo NOP tables
  |-- Read by SP_Max_NOP → Dealing_dbo Max NOP tables
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolves instrument display name, type, currency pair. Used by all 4 downstream SPs. |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element Used | Purpose |
|---|---|---|
| BI_DB_dbo.SP_DailyNOP_ByInstrument | BidLast, InstrumentID, DateFrom | Gets last known bid price per instrument for daily NOP calculation |
| BI_DB_dbo.SP_M_EOMExposures | AskLast, BidLast, InstrumentID, DateFrom | Gets end-of-month prices for exposure reporting |
| Dealing_dbo.SP_NOP_LPandClients | AskLast, BidLast, InstrumentID, DateFrom | Gets prices for LP and client NOP calculations |
| Dealing_dbo.SP_Max_NOP | AskLast, BidLast, InstrumentID, DateFrom, DateTo | Gets hourly prices for max NOP calculations |

---

## 7. Sample Queries

### 7.1 Get Latest Known Price for an Instrument

```sql
SELECT TOP 1
    InstrumentID,
    DateFrom,
    BidLast AS LastBid,
    AskLast AS LastAsk,
    AskLast - BidLast AS Spread
FROM BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted
WHERE InstrumentID = 2  -- EUR/USD
ORDER BY DateFrom DESC
```

### 7.2 Daily Average Spread for an Instrument

```sql
SELECT
    CAST(DateFrom AS DATE) AS TradeDate,
    AVG(AskLast - BidLast) AS AvgSpread,
    MIN(BidMin) AS DailyLow,
    MAX(AskMax) AS DailyHigh
FROM BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted
WHERE InstrumentID = 2
  AND DateFrom >= '2024-01-01'
  AND DateFrom < '2024-02-01'
GROUP BY CAST(DateFrom AS DATE)
ORDER BY TradeDate
```

### 7.3 Last Price Per Instrument Before a Date (as used by downstream SPs)

```sql
SELECT InstrumentID, BidLast AS LastPrice
FROM (
    SELECT InstrumentID, BidLast,
           ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY DateFrom DESC) AS rn
    FROM BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted
    WHERE DateFrom < '2024-06-01'
) sub
WHERE rn = 1
```

---

## 8. Atlassian Knowledge Sources

- [Candle Builder - General](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/11935842494/Candle+Builder+-+General) --- describes the Candle Builder service that generates 60-minute candle data (T_PriceCandle60Min) from incoming real-time rates via RabbitMQ
- [Candle Builder - Database](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/11940167937/Candle+Builder+-+Database) --- documents the production Candles DB (Price:12 on AO-CANDLES-LSN) and stored procedures for candle management
- [Candle API DB](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/12206048752/Candle+API+DB) --- documents the Candle API database connections and table dependencies

---

*Generated: 2026-04-30 | Quality: 6.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 21 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 7/10, Lineage: 6/10*
*Object: BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | Type: Table | Production Source: Candle Builder service (Price:12 / Candles DB, AO-CANDLES-LSN)*
