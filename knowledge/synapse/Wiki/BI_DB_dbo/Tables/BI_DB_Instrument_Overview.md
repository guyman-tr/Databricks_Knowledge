# BI_DB_dbo.BI_DB_Instrument_Overview

> 3.19M-row daily and monthly instrument activity overview tracking trading volume, unique traders, positions, revenue, first actions, and watchlist statistics per instrument across all asset classes (Stocks, ETF, Crypto, Commodities, Indices, Currencies). Rolling 7-month window with auto-purge. Dual granularity: "Daily Data" (3.09M rows, 97%) and "Monthly Data" (97.7K rows, 3%, end-of-month only). Date range: Sep 2025 – Apr 2026. Sourced from Dim_Instrument, Dim_Position, BI_DB_First5Actions, BI_DB_DailyCommisionReport, and DWH_watchlists.Fact_WatchlistsItems. Refreshed daily via SP_Instrument_Overview.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Instrument Analytics — daily + monthly) |
| **Production Source** | Derived — multi-source aggregate from DWH_dbo dimensions + BI_DB reports by SP_Instrument_Overview |
| **Refresh** | Daily delete-insert for current date + monthly insert on EOM; auto-purge >7 months |
| **Synapse Distribution** | HASH(DWHInstrumentID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |
| **Author** | Artyom Bogomolsky (2022-11-16); leveraged/real split + manual watchlist (2022-11-30) |

---

## 1. Business Meaning

`BI_DB_Instrument_Overview` is a **daily and monthly instrument-level activity report** that provides a 360-degree view of each financial instrument on the eToro platform. For every instrument and date, it tracks: how many unique traders opened positions, how many positions were opened, total traded volume, invested amount, average leverage, long vs short ratio, first-time actions, commission + rollover revenue, and watchlist engagement (adds/deletes, manual vs auto).

The table holds 3.19M rows across 224 distinct dates in a rolling 7-month window (Sep 2025 – Apr 2026). Data older than 7 months is automatically purged. Each daily snapshot covers ~15,700 instruments across 6 asset types: Stocks (82%), ETF (8%), Crypto Currencies (4%), Commodities (3%), Indices (2%), Currencies (1%).

### Dual Granularity

- **Daily Data** (Periodind = 'Daily Data'): One row per instrument per day. Trading metrics cover that single day.
- **Monthly Data** (Periodind = 'Monthly Data'): One row per instrument per month (inserted only on end-of-month dates). Trading metrics aggregate the entire month (OpenDateID BETWEEN first-of-month AND EOM).

### Load Pattern

- **Daily**: DELETE WHERE Date = @Date, then INSERT daily rows for all instruments (including those with no activity — LEFT JOIN from Dim_Instrument)
- **Monthly**: On end-of-month only (`WHILE @Date = @EOM`), INSERT additional monthly aggregation rows
- **Auto-purge**: DELETE WHERE Date < 7 months before first-of-month — keeps a rolling 7-month window

---

## 2. Business Logic

### 2.1 Instrument Universe

**What**: All instruments from Dim_Instrument with DWHInstrumentID > 0 are included, even those with zero activity.
**Columns Involved**: DWHInstrumentID, InstrumentTypeID, InstrumentType, InstrumentName
**Rules**:
- LEFT JOIN from instruments to activity tables — instruments with no positions on a given day have NULL trading metrics
- 6 instrument types: Stocks (5), ETF (6), Crypto Currencies (10), Commodities (2), Indices (4), Currencies (1)

### 2.2 Trading Activity Metrics

**What**: Position-level aggregations from Dim_Position for positions opened on the date.
**Columns Involved**: UniqueTraders, Positions, OpenedVolume, InvestedAmount, Average_Traded_Leverage, Long_Transactions
**Rules**:
- Only positions with OpenDateID = @DateID (daily) or BETWEEN first-of-month AND @DateID (monthly)
- IsPartialCloseChild = 0 — excludes partial close fragments
- InvestedAmount = SUM(InitialAmountCents / 100) — converted from cents to dollars
- Long_Transactions = SUM(CAST(IsBuy AS int)) — count of buy/long positions

### 2.3 Leveraged vs Real Split

**What**: Separates leveraged CFD and real (settled) activity.
**Columns Involved**: Leveraged_Volume, Leveraged_Positions, Real_Volume, Real_Positions
**Rules**:
- Leveraged: Leverage > 1 (CFD positions with margin)
- Real: IsSettled > 0 (customer owns the underlying asset)
- A position can be neither leveraged nor real (Leverage=1 AND IsSettled=0 — standard CFD at 1:1)

### 2.4 Revenue

**What**: Daily/monthly commission + rollover fee per instrument.
**Columns Involved**: Revenue
**Rules**:
- Revenue = SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport
- JOIN on InstrumentID = DWHInstrumentID and DateID filter

### 2.5 Watchlist Engagement

**What**: Watchlist add/delete events, split by manual vs auto.
**Columns Involved**: NewAddedToWhatchlist, DeletedFromWatchList, NewManualAddedToWhatchlist, DeletedManualFromWatchList
**Rules**:
- From DWH_watchlists.Fact_WatchlistsItems WHERE ItemType = 'Instrument'
- Manual: ItemAddedReason = 'Manual' — user explicitly added/removed
- Auto: Remaining events (system-suggested watchlist items)
- Note: column names have typo "Whatchlist" preserved from original DDL

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(DWHInstrumentID) distribution with HEAP storage. Instrument-level queries benefit from co-location. Date-range queries require movement across distributions — filter on Date first for efficiency.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top 10 instruments by volume today | `WHERE Date = '2026-04-11' AND Periodind = 'Daily Data' ORDER BY OpenedVolume DESC` |
| Monthly instrument trends | `WHERE Periodind = 'Monthly Data' ORDER BY Date, Revenue DESC` |
| Instrument type breakdown | `GROUP BY InstrumentType, Date WHERE Periodind = 'Daily Data'` |
| Instruments with first-time traders | `WHERE FirstActions > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | DWHInstrumentID = DWHInstrumentID | Additional instrument attributes |
| DWH_dbo.Dim_Currency | BuyCurrencyID or SellCurrencyID | Currency name resolution |

### 3.4 Gotchas

- **NULL activity columns**: Instruments with no trading activity on a given day have NULL for UniqueTraders, Positions, etc. (LEFT JOIN). These are NOT zero — they mean "no positions opened"
- **Dual granularity**: Always filter on Periodind ('Daily Data' or 'Monthly Data') to avoid double-counting
- **7-month rolling window**: Data before 7 months is purged. Historical queries beyond this range return nothing
- **Watchlist typo**: Column names use "Whatchlist" (not "Watchlist") — this is the original DDL naming
- **InvestedAmount vs OpenedVolume**: InvestedAmount = InitialAmountCents/100 (dollar value of initial position), OpenedVolume = SUM(Volume) (trading volume in instrument units)
- **Tradable as varchar**: Dim_Instrument has Tradable as int, but this DDL stores it as varchar(100) — values may be string '1' or '0'

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DWHInstrumentID | int | NO | Always equal to InstrumentID — redundant copy following the DWH DWH{X}ID pattern. Use InstrumentID for all JOINs. Filtered to >0 (excludes placeholder). (Tier 1 — DWH_dbo.Dim_Instrument wiki, originally Trade.Instrument) |
| 2 | InstrumentTypeID | int | NO | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. (Tier 1 — DWH_dbo.Dim_Instrument wiki, originally Trade.Instrument) |
| 3 | InstrumentType | varchar(200) | YES | Text label for InstrumentTypeID — DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 — DWH_dbo.Dim_Instrument wiki) |
| 4 | InstrumentName | varchar(200) | YES | Instrument internal name from Dim_Instrument.Name. Examples: Apple/USD, EURUSD, Bitcoin/USD. Renamed from Dim_Instrument.Name. (Tier 2 — SP_Instrument_Overview, from Dim_Instrument) |
| 5 | BuyCurrencyID | int | YES | The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks). (Tier 1 — DWH_dbo.Dim_Instrument wiki, Trade.Instrument) |
| 6 | SellCurrencyID | int | YES | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). (Tier 1 — DWH_dbo.Dim_Instrument wiki, Trade.Instrument) |
| 7 | BuyCurrency | varchar(50) | YES | Text abbreviation of BuyCurrencyID — denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: EUR, AAPL, BTC. DWH-added for query convenience. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 8 | SellCurrency | varchar(50) | YES | Text abbreviation of SellCurrencyID — denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 9 | IsMajorID | int | YES | Integer representation of the production IsMajor flag (0 or 1). 1=major instrument (popular forex pairs and many popular stocks). 0=non-major. Renamed from production IsMajor to distinguish from text version. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 10 | InstrumentDisplayName | varchar(200) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 11 | Exchange | varchar(200) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 12 | ISINCode | varchar(100) | YES | International Securities Identification Number — 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 13 | Tradable | varchar(100) | YES | Flag indicating if the instrument is currently tradable. CAST from production bit. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 14 | Symbol | varchar(100) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 15 | AddedToServerDate | datetime | YES | First timestamp when the instrument was observed on the price server. From Dim_Instrument.ReceivedOnPriceServer, CAST to DATE. Set once and never updated (static history). (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 16 | CUSIP | varchar(100) | YES | Committee on Uniform Securities Identification Procedures number — 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 17 | UniqueTraders | int | YES | Count of distinct CIDs who opened positions in this instrument on this date (daily) or during this month (monthly). NULL if no positions opened. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 18 | Positions | int | YES | Count of positions opened in this instrument on this date/month. Excludes IsPartialCloseChild=0 fragments. NULL if no positions opened. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 19 | OpenedVolume | bigint | YES | Total traded volume for positions opened in this instrument on this date/month. SUM(CAST(Volume AS bigint)). NULL if no positions opened. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 20 | InvestedAmount | bigint | YES | Total invested dollar amount. Computed as SUM(InitialAmountCents/100). Represents the initial position value in USD. NULL if no positions opened. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 21 | Average_Traded_Leverage | int | YES | Average leverage across all positions opened in this instrument on this date/month. AVG(Leverage). NULL if no positions opened. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 22 | Long_Transactions | int | YES | Count of long (buy) positions opened. SUM(CAST(IsBuy AS int)). IsBuy=1 for long, 0 for short. NULL if no positions. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 23 | FirstActions | int | YES | Count of CIDs whose first-ever action on the platform was in this instrument on this date/month. Matched via FirstInstrument from BI_DB_First5Actions. NULL if no first actions. (Tier 2 — SP_Instrument_Overview, from BI_DB_First5Actions) |
| 24 | Revenue | money | YES | Total revenue from this instrument on this date/month. SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport. NULL if no revenue. (Tier 2 — SP_Instrument_Overview, from BI_DB_DailyCommisionReport) |
| 25 | NewAddedToWhatchlist | int | YES | Count of watchlist add events for this instrument on this date/month. SUM(CASE WHEN IsDeleted=0 THEN 1). Includes both manual and auto-suggested additions. NULL if no events. (Tier 2 — SP_Instrument_Overview, from DWH_watchlists.Fact_WatchlistsItems) |
| 26 | DeletedFromWatchList | int | YES | Count of watchlist delete events for this instrument on this date/month. SUM(IsDeleted). NULL if no events. (Tier 2 — SP_Instrument_Overview, from DWH_watchlists.Fact_WatchlistsItems) |
| 27 | Date | date | YES | Business date for this row. For 'Daily Data': the specific date. For 'Monthly Data': the last day of the month. (Tier 2 — SP_Instrument_Overview) |
| 28 | Periodind | varchar(50) | YES | Granularity indicator. 'Daily Data' = single-day metrics. 'Monthly Data' = full-month aggregation (only on end-of-month dates). (Tier 2 — SP_Instrument_Overview) |
| 29 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by SP_Instrument_Overview. Set to GETDATE(). (Tier 5 — SP_Instrument_Overview) |
| 30 | Leveraged_Volume | bigint | YES | Volume from leveraged positions only (Leverage > 1). SUM(Volume WHERE Leverage > 1). Subset of OpenedVolume. NULL if no positions. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 31 | Leveraged_Positions | int | YES | Count of leveraged positions (Leverage > 1). Subset of Positions. NULL if no positions. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 32 | Real_Volume | bigint | YES | Volume from real (settled) positions only (IsSettled > 0). SUM(Volume WHERE IsSettled > 0). Customer owns the underlying asset. NULL if no positions. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 33 | Real_Positions | int | YES | Count of real (settled) positions (IsSettled > 0). Customer owns the underlying asset. NULL if no positions. (Tier 2 — SP_Instrument_Overview, from Dim_Position) |
| 34 | NewManualAddedToWhatchlist | int | YES | Count of manual watchlist add events (ItemAddedReason = 'Manual' AND IsDeleted = 0). Subset of NewAddedToWhatchlist. NULL if no events. (Tier 2 — SP_Instrument_Overview, from DWH_watchlists.Fact_WatchlistsItems) |
| 35 | DeletedManualFromWatchList | int | YES | Count of manual watchlist delete events (ItemAddedReason = 'Manual' AND IsDeleted = 1). Subset of DeletedFromWatchList. NULL if no events. (Tier 2 — SP_Instrument_Overview, from DWH_watchlists.Fact_WatchlistsItems) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| DWHInstrumentID through CUSIP (cols 1-16) | DWH_dbo.Dim_Instrument (originally Trade.Instrument, Trade.InstrumentMetaData, Trade.InstrumentCusip) | Various | Passthrough from Dim_Instrument |
| UniqueTraders, Positions, OpenedVolume, InvestedAmount, Average_Traded_Leverage, Long_Transactions, Leveraged_*, Real_* | DWH_dbo.Dim_Position (originally Trade.PositionTbl) | CID, PositionID, Volume, InitialAmountCents, Leverage, IsBuy, IsSettled | Aggregate: COUNT/SUM/AVG per instrument per date |
| FirstActions | BI_DB_dbo.BI_DB_First5Actions | CID, FirstInstrument, FirstActionDate | COUNT per instrument match |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM per instrument per date |
| Watchlist columns | DWH_watchlists.Fact_WatchlistsItems | ItemId, IsDeleted, ItemAddedReason | COUNT per instrument per date |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Instrument (instrument master, >15K instruments)
  + DWH_dbo.Dim_Position (positions opened on date, IsPartialCloseChild=0)
  + BI_DB_dbo.BI_DB_First5Actions (first-time instrument actions)
  + BI_DB_dbo.BI_DB_DailyCommisionReport (commission + rollover)
  + DWH_watchlists.Fact_WatchlistsItems (watchlist events, ItemType='Instrument')
    |-- SP_Instrument_Overview @Date (Priority 0, SB_Daily) --|
    |   Step 1: Instrument universe from Dim_Instrument (>0)   |
    |   Step 2: Daily trading aggregates from Dim_Position     |
    |   Step 3: First actions from BI_DB_First5Actions         |
    |   Step 4: Revenue from BI_DB_DailyCommisionReport        |
    |   Step 5: Watchlist from Fact_WatchlistsItems             |
    |   Step 6: LEFT JOIN all → daily insert                   |
    |   Step 7-11: Monthly aggregation on EOM                  |
    |   Purge: DELETE WHERE Date < 7 months ago                |
    v
BI_DB_dbo.BI_DB_Instrument_Overview (3.19M rows, 7-month rolling)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DWHInstrumentID | DWH_dbo.Dim_Instrument | Instrument master |
| BuyCurrencyID, SellCurrencyID | DWH_dbo.Dim_Currency | Currency lookups |
| Trading metrics | DWH_dbo.Dim_Position | Position-level aggregation source |
| FirstActions | BI_DB_dbo.BI_DB_First5Actions | First action source |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | Revenue source |
| Watchlist columns | DWH_watchlists.Fact_WatchlistsItems | Watchlist event source |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Top 10 Instruments by Trading Volume Today

```sql
SELECT DWHInstrumentID, InstrumentName, InstrumentType,
       UniqueTraders, Positions, OpenedVolume, Revenue
FROM [BI_DB_dbo].[BI_DB_Instrument_Overview]
WHERE Date = CAST(GETDATE()-1 AS date)
  AND Periodind = 'Daily Data'
ORDER BY OpenedVolume DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
```

### 7.2 Monthly Revenue Trend by Instrument Type

```sql
SELECT Date, InstrumentType,
       SUM(Revenue) AS total_revenue,
       SUM(Positions) AS total_positions
FROM [BI_DB_dbo].[BI_DB_Instrument_Overview]
WHERE Periodind = 'Monthly Data'
GROUP BY Date, InstrumentType
ORDER BY Date, total_revenue DESC
```

### 7.3 Real vs Leveraged Position Mix

```sql
SELECT Date,
       SUM(Real_Positions) AS real,
       SUM(Leveraged_Positions) AS leveraged,
       SUM(Positions) AS total,
       CAST(SUM(Real_Positions)*100.0/NULLIF(SUM(Positions),0) AS decimal(5,1)) AS pct_real
FROM [BI_DB_dbo].[BI_DB_Instrument_Overview]
WHERE Periodind = 'Daily Data' AND Date >= '2026-04-01'
GROUP BY Date
ORDER BY Date
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 15 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 35/35, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Instrument_Overview | Type: Table | Production Source: Derived — multi-source aggregate*
