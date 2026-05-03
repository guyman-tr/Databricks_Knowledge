# Dealing_dbo.Dealing_IndiciesIntraHour_Clients

> ~13.3M-row minute-level aggregation table capturing client-side intra-hour hedging activity for three index instruments (IDs 27, 28, 32) from 2022-05-22 to present — recording per-minute buy/sell volumes, open position values, unrealized and realized P&L, and bid/ask prices, sourced from Dim_Position + PriceLog via SP_IntraHourIndexReport daily.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice via SP_IntraHourIndexReport |
| **Refresh** | Daily (1440 min, Append via Generic Pipeline) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| | |
| **UC Target** | `general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients` |
| **UC Format** | Delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Append) |

---

## 1. Business Meaning

Dealing_IndiciesIntraHour_Clients is the client-side component of the intra-hour hedging activity report, tracking minute-by-minute trading metrics for three hardcoded index instruments: S&P 500 (InstrumentID=27), DJ30 (InstrumentID=28), and GER30 (InstrumentID=32). The table captures what eToro's clients are doing in aggregate at each minute of the trading day — how much they're buying, selling, holding in open positions, and realizing in P&L.

The companion table `Dealing_dbo.Dealing_IndiciesIntraHour_Etoro` records the eToro hedging side for the same instruments using execution log and netting data from liquidity providers.

**Data volume**: ~13.3M rows spanning 2022-05-22 to 2026-04-26. Each day produces ~8,638 rows (1,440 minutes × 3 instruments × active HedgeServerIDs). Annual volumes grew from ~907K (2022, partial year) to ~5.8M (2024).

**ETL pattern**: `SP_IntraHourIndexReport @Date` runs daily. It DELETEs existing rows for @Date, then INSERTs fresh aggregated data. The SP:
1. Resolves index instruments to their hedge-mapped counterparts via PortfolioConversionConfigurations
2. Generates a minute-by-minute grid for the day
3. Pulls prices from CopyFromLake.PriceLog_History_CurrencyPrice (with gap-filling via OUTER APPLY)
4. Aggregates client positions from Dim_Position (filtered to IsValidCustomer=1 via Dim_Customer)
5. Computes volumes, open position values, unrealized P&L, and realized P&L per minute per instrument per HedgeServerID

**HedgeServerID**: Added 2024-04-30 (SR-249626). Prior to this, hedge server filters were hardcoded; after, HedgeServerID became a grouping dimension. Current active servers: 5, 8, 20, 1776. Older rows have NULL HedgeServerID.

---

## 2. Business Logic

### 2.1 Volume Calculation (VolumeBuy / VolumeSell)

**What**: Aggregated USD trade volumes per minute, combining new opens and closes.

**Columns Involved**: `VolumeBuy`, `VolumeSell`

**Rules**:
- For positions **opened** in the minute: VolumeBuy = SUM(Volume) where IsBuy=1; VolumeSell = SUM(Volume) where IsBuy=0
- For positions **closed** in the minute: VolumeBuy = SUM(VolumeOnClose) where IsBuy=0 (closing a sell is a buy); VolumeSell = SUM(VolumeOnClose) where IsBuy=1 (closing a buy is a sell)
- Both UNIONed and re-aggregated. ISNULL(,0) applied on final INSERT.
- Volume values from Dim_Position are ETL-computed approximations (ROUND of AmountInUnitsDecimal * rate * conversion)

### 2.2 Open Position Values (OP_Buy / OP_Sell / OP_Buy_Units / OP_Sell_Units)

**What**: Total open position exposure at each minute, split by direction.

**Columns Involved**: `OP_Buy_Units`, `OP_Buy`, `OP_Sell_Units`, `OP_Sell`

**Rules**:
- OP_Buy_Units = SUM(AmountInUnitsDecimal) for IsBuy=1 positions open at that minute
- OP_Buy = SUM(AmountInUnitsDecimal × FirstBid × ConversionFirst) — USD-equivalent value of all buy open positions, priced at start-of-minute bid
- OP_Sell_Units / OP_Sell = same for IsBuy=0 positions, using FirstAsk
- A position is "open at minute X" if OpenOccurred <= X AND (CloseOccurred > X OR CloseDateID=0)
- Positions opened in the same minute are excluded from the metric (CASE WHEN DATEADD(...) = pf.fromMinute THEN 0)

### 2.3 Unrealized P&L (UnrealizedStart / UnrealizedEnd)

**What**: Aggregate unrealized P&L for all open client positions at start and end of each minute.

**Columns Involved**: `UnrealizedStart`, `UnrealizedEnd`

**Rules**:
- UnrealizedStart = SUM(AmountInUnitsDecimal × ConversionFirst × (price_delta from InitForexRate) + FullCommissionByUnits) for all positions open at that minute (excluding newly opened ones)
- For buy positions: price_delta = FirstBid − InitForexRate
- For sell positions: price_delta = InitForexRate − FirstAsk
- UnrealizedEnd = UnrealizedStart of the **next** minute (self-join: o2.fromMinute = o.toMinute). NULL for the last minute of the day.

### 2.4 Realized P&L

**What**: Total realized P&L from positions closing in the minute.

**Columns Involved**: `Realized`

**Rules**:
- Realized = SUM(NetProfit + FullCommissionOnClose) for positions closing in the minute (CloseDateID = @DateInt)
- ISNULL(,0) on final INSERT — 0 for minutes with no closes

### 2.5 Price Smoothing (Bid / Ask)

**What**: Start-of-minute bid/ask prices with gap-filling for missing intervals.

**Columns Involved**: `Bid`, `Ask`

**Rules**:
- Raw prices from PriceLog_History_CurrencyPrice, bucketed to 1-minute intervals (last price per minute wins, via ROW_NUMBER ORDER BY Occurred DESC)
- Prices are mapped from hedge instruments to source instruments via PortfolioConversionConfigurations (UNIONed)
- NULL-minute gaps are forward-filled using OUTER APPLY (find latest non-NULL price before this minute)
- Bid = LAG(LastBid, 1) = previous minute's last bid (i.e., the price at the START of the current minute)
- Ask = LAG(LastAsk, 1) = same logic for ask

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: All data evenly spread across distributions with no co-location benefit. No single column dominates query patterns enough for HASH distribution.

**Clustered Index on [Date]**: Date-range queries are efficient. Always include `WHERE [Date] BETWEEN ... AND ...` for partition-like behavior.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Intra-day volume profile for a specific day | `WHERE [Date] = '2026-04-25' AND InstrumentID = 27 ORDER BY Minute_Start` |
| Daily totals for an instrument | `SELECT [Date], SUM(VolumeBuy), SUM(VolumeSell) WHERE InstrumentID = 28 GROUP BY [Date]` |
| Peak unrealized exposure | `SELECT TOP 10 * WHERE InstrumentID = 32 ORDER BY ABS(UnrealizedStart) DESC` |
| Compare buy vs sell open position value | `SELECT Minute_Start, OP_Buy, OP_Sell WHERE [Date] = '2026-04-25'` |
| Realized P&L by minute | `WHERE Realized <> 0 AND [Date] = '2026-04-25' ORDER BY Minute_Start` |
| Client vs eToro comparison | JOIN with `Dealing_IndiciesIntraHour_Etoro` ON Date, Minute_Start, InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | ON Date, Minute_Start, InstrumentID, HedgeServerID | Compare client-side vs eToro hedging activity |

### 3.4 Gotchas

- **Only 3 instruments**: This table ONLY contains data for InstrumentIDs 27, 28, 32 (major indices). Do not expect other instruments.
- **HedgeServerID is NULL for pre-2024 data**: The column was added 2024-04-30 (SR-249626). Older rows have NULL HedgeServerID; newer rows have values like 5, 8, 20, 1776.
- **UnrealizedEnd can be NULL**: For the last minute of the day, there is no "next minute" to self-join, so UnrealizedEnd = NULL.
- **Volume is in USD (approximate)**: VolumeBuy/VolumeSell inherit Volume/VolumeOnClose from Dim_Position, which are ETL-computed rounded approximations.
- **Bid/Ask are start-of-minute prices**: They represent the previous minute's last traded price (LAG), not the current minute's price.
- **Minute_Start/Minute_End are datetime, not time**: They include the full date+time (e.g., '2026-04-25 14:30:00').
- **Delete-insert pattern per day**: Re-running SP_IntraHourIndexReport for a past date will replace all rows for that date.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — description copied as-is from Dim_Position |
| Tier 2 | ETL-computed in SP_IntraHourIndexReport — transform documented from SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trading date extracted from the minute bucket. CONVERT(DATE, fromMinute). One row per instrument per minute per HedgeServerID per date. (Tier 2 — SP_IntraHourIndexReport) |
| 2 | Minute_Start | datetime | YES | Start of the 1-minute time bucket (e.g., '2026-04-25 14:30:00'). Generated from a minute grid covering the full 24-hour day. (Tier 2 — SP_IntraHourIndexReport) |
| 3 | Minute_End | datetime | YES | End of the 1-minute time bucket (Minute_Start + 1 minute, e.g., '2026-04-25 14:31:00'). (Tier 2 — SP_IntraHourIndexReport) |
| 4 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. Filtered to three index instruments: 27 (S&P 500), 28 (DJ30), 32 (GER30). (Tier 1 — Trade.PositionTbl) |
| 5 | VolumeBuy | bigint | YES | Aggregated USD buy volume for the minute. Combines new long opens (SUM of Volume where IsBuy=1) and short closes (SUM of VolumeOnClose where IsBuy=0). ISNULL defaults to 0. (Tier 2 — Dim_Position) |
| 6 | VolumeSell | bigint | YES | Aggregated USD sell volume for the minute. Combines new short opens (SUM of Volume where IsBuy=0) and long closes (SUM of VolumeOnClose where IsBuy=1). ISNULL defaults to 0. (Tier 2 — Dim_Position) |
| 7 | OP_Buy_Units | float | YES | Total units (AmountInUnitsDecimal) of all open buy positions at start of this minute. SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal). (Tier 2 — Dim_Position) |
| 8 | OP_Buy | float | YES | USD-equivalent value of all open buy positions at start of this minute. SUM(AmountInUnitsDecimal × Bid × USDConversionRate). (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 9 | OP_Sell_Units | float | YES | Total units of all open sell positions at start of this minute. SUM(CASE WHEN IsBuy=0 THEN AmountInUnitsDecimal). (Tier 2 — Dim_Position) |
| 10 | OP_Sell | float | YES | USD-equivalent value of all open sell positions at start of this minute. SUM(AmountInUnitsDecimal × Ask × USDConversionRate). (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 11 | UnrealizedStart | float | YES | Aggregate unrealized P&L for all open client positions at start of this minute. SUM(AmountInUnitsDecimal × ConversionRate × (price − InitForexRate) + FullCommissionByUnits), direction-adjusted. Excludes positions opened in the same minute. (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 12 | UnrealizedEnd | float | YES | Aggregate unrealized P&L at end of this minute. Equals UnrealizedStart of the next minute (self-join on toMinute=fromMinute). NULL for the last minute of the day. (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 13 | Realized | float | YES | Total realized P&L from positions closing in this minute. SUM(NetProfit + FullCommissionOnClose). ISNULL defaults to 0 when no positions close. (Tier 2 — Dim_Position) |
| 14 | Bid | float | YES | Instrument bid price at start of this minute. LAG of last bid from PriceLog_History_CurrencyPrice, with NULL gap-filling via forward-fill. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| 15 | Ask | float | YES | Instrument ask price at start of this minute. LAG of last ask from PriceLog_History_CurrencyPrice, with NULL gap-filling via forward-fill. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| 16 | UpdateDate | datetime | YES | ETL execution timestamp. Set to GETDATE() at SP_IntraHourIndexReport run time. (Tier 2 — SP_IntraHourIndexReport) |
| 17 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows. (Tier 1 — Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | (generated) | — | CONVERT(DATE, minute bucket) |
| Minute_Start | (generated) | — | Minute grid start |
| Minute_End | (generated) | — | Minute grid end |
| InstrumentID | Trade.PositionTbl | InstrumentID | Passthrough (via Dim_Position) |
| VolumeBuy | Dim_Position | Volume, VolumeOnClose | SUM by direction, combining opens and closes |
| VolumeSell | Dim_Position | Volume, VolumeOnClose | SUM by direction, combining opens and closes |
| OP_Buy_Units | Dim_Position | AmountInUnitsDecimal | SUM for IsBuy=1 open positions |
| OP_Buy | Dim_Position + PriceLog | AmountInUnitsDecimal, Bid, ConversionRate | SUM(units × bid × conversion) |
| OP_Sell_Units | Dim_Position | AmountInUnitsDecimal | SUM for IsBuy=0 open positions |
| OP_Sell | Dim_Position + PriceLog | AmountInUnitsDecimal, Ask, ConversionRate | SUM(units × ask × conversion) |
| UnrealizedStart | Dim_Position + PriceLog | Multiple | Unrealized P&L formula (see Section 2.3) |
| UnrealizedEnd | Dim_Position + PriceLog | Multiple | Self-join to next minute's UnrealizedStart |
| Realized | Dim_Position | NetProfit, FullCommissionOnClose | SUM for closing positions |
| Bid | PriceLog_History_CurrencyPrice | Bid | LAG(LastBid, 1) with gap-fill |
| Ask | PriceLog_History_CurrencyPrice | Ask | LAG(LastAsk, 1) with gap-fill |
| UpdateDate | (generated) | — | GETDATE() |
| HedgeServerID | Trade.PositionTbl | HedgeServerID | Passthrough (via Dim_Position) |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl (open positions)
etoro.History.ClosePosition (closed positions)
  |-- Generic Pipeline (Bronze export) --|
  v
DWH_staging.etoro_Trade_OpenPositionEndOfDay
DWH_staging.etoro_History_ClosePositionEndOfDay
  |-- SP_Dim_Position_DL_To_Synapse @dt --|
  v
DWH_dbo.Dim_Position (~200M+ rows)     DWH_dbo.Dim_Customer
  |                                       |
  |-- JOIN ON CID=RealCID, IsValidCustomer=1 --|
  |
CopyFromLake.PriceLog_History_CurrencyPrice
  |-- SP_Copy_Temporary_Data (load 5 days of prices) --|
  |
Dealing_staging.etoro_History_PortfolioConversionConfigurations
Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations
  |-- Instrument-to-hedge mapping --|
  |
  |-- SP_IntraHourIndexReport @Date --|
  |   (DELETE+INSERT for @Date)
  v
Dealing_dbo.Dealing_IndiciesIntraHour_Clients (~13.3M rows)
  |-- Generic Pipeline (Append, delta, daily) --|
  v
general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolve instrument name, asset class (only IDs 27, 28, 32) |
| HedgeServerID | Trade.HedgeServer | Hedge server identifier |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|-------------------|-------------|-------------|
| Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | Companion table | eToro hedging side of the same intra-hour report; typically joined on Date, Minute_Start, InstrumentID, HedgeServerID |

---

## 7. Sample Queries

### 7.1 Intra-Day Volume Profile for an Instrument

```sql
SELECT Minute_Start,
       VolumeBuy,
       VolumeSell,
       VolumeBuy - VolumeSell AS NetVolume
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients
WHERE [Date] = '2026-04-25'
  AND InstrumentID = 27
ORDER BY Minute_Start;
```

### 7.2 Daily P&L Summary by Instrument

```sql
SELECT [Date],
       InstrumentID,
       SUM(Realized) AS TotalRealized,
       MAX(UnrealizedStart) AS PeakUnrealized
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients
WHERE [Date] >= '2026-04-01'
GROUP BY [Date], InstrumentID
ORDER BY [Date], InstrumentID;
```

### 7.3 Client vs eToro Comparison

```sql
SELECT c.[Date],
       c.Minute_Start,
       c.InstrumentID,
       c.VolumeBuy AS ClientVolumeBuy,
       c.VolumeSell AS ClientVolumeSell,
       e.VolumeBuy AS EtoroVolumeBuy,
       e.VolumeSell AS EtoroVolumeSell
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients c
JOIN Dealing_dbo.Dealing_IndiciesIntraHour_Etoro e
  ON c.[Date] = e.[Date]
  AND c.Minute_Start = e.Minute_Start
  AND c.InstrumentID = e.InstrumentID
  AND c.HedgeServerID = e.HedgeServerID
WHERE c.[Date] = '2026-04-25'
  AND c.InstrumentID = 28
ORDER BY c.Minute_Start;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources were searched in this regen run (Phase 10 skipped in harness mode). SP change history references SR-249626 (HedgeServerID addition) and SR-257613 (CopyFromLake migration).

---

*Generated: 2026-04-30 | Phases: 11/14*
*Tiers: 2 T1, 15 T2, 0 T3, 0 T4, 0 T5 | Elements: 17/17, Logic: 5 subsections*
*Object: Dealing_dbo.Dealing_IndiciesIntraHour_Clients | Type: Table | Production Source: Dim_Position + PriceLog via SP_IntraHourIndexReport*
