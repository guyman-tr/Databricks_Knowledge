# BI_DB_dbo.BI_DB_Daily_TradeData

> 409.6M-row daily instrument-level trading activity snapshot (2019-01-01 to 2026-04-12, 2,657 distinct dates) tracking end-of-day price, newly-opened positions, and held positions by instrument × region × country. Grain: Date × InstrumentID × Region × Country. Written by SP_Daily_TradeData (SB_Daily, Priority 20). All instruments in the EOD price feed are represented; instruments with no activity have OpenedPositions=OpenPositions=0.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit via SP_Daily_TradeData |
| **Refresh** | Daily (SB_Daily, Priority 20) — DELETE WHERE DateID=@ddINT + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~409.6M (2019–2026) |
| **Author** | Amir Gurewitz (2020-06-14); Synapse migration: Tal Cohen (2023-04-27) |

---

## 1. Business Meaning

BI_DB_Daily_TradeData is a daily instrument trading activity table covering every instrument in the Synapse price feed (15,415 distinct instruments as of 2026). Each row represents a unique combination of Date × InstrumentID × Region × Country, aggregating two parallel views of trading activity:

1. **Newly-opened positions** ("Open" branch): Positions opened on @dd by valid depositor customers (non-mirror, non-partial-close, tradable instruments). Captured via `DWH_dbo.Dim_Position WHERE OpenDateID = @ddINT`.
2. **Held positions at EOD** ("EOD" branch): All live positions as of end-of-day sourced from `BI_DB_PositionPnL`. Represents the trading stock held by customers at close of business.

The final INSERT grain is driven by `Fact_CurrencyPriceWithSplit` — every instrument with an EOD price appears in the output, even if no customer opened or held a position that day (resulting in OpenedPositions=0 and OpenPositions=0). This ensures complete instrument coverage for charting/reporting purposes.

Key characteristics:
- **NULL InstrumentType** (~2% of YTD rows): instruments present in the price feed that do not have a matching row in `Dim_Instrument` (LEFT JOIN failure). These are typically delisted or inactive instruments.
- **OpenedPositions=0 in 91.7%** of YTD rows: on any given day, most instruments have no new customer opens. These rows are included because the instrument had an EOD price.
- **ROUND_ROBIN distribution**: no natural distribution key since grain is InstrumentID × Region × Country (wide geographic distribution).
- InstrumentType distribution (2026 YTD): Stocks 80%, ETF 11%, Crypto Currencies 5%, NULL 2%, Commodities <1%, Currencies <1%, Indices <1%.
- Top regions: Eastern Europe (17%), South & Central America (13%), North Europe (9%), French (9%), German (7%), UK (7%).

---

## 2. Business Logic

### 2.1 Two-Window Activity Measurement

**What**: The SP computes two independent activity windows per instrument: new opens on @dd and EOD holdings on @dd.

**Columns Involved**: OpenedPositions, UsersOpen (Open window) vs OpenPositions, UsersHold (EOD window)

**Rules**:
- Open window filter: `OpenDateID = @ddINT AND IsDepositor=1 AND MirrorID=0 AND IsPartialCloseChild=0 AND Tradable=1 AND IsValidCustomer=1`
- EOD window filter: `BI_DB_PositionPnL.DateID = @ddINT AND MirrorID=0 AND IsPartialCloseChild=0 AND Tradable=1 AND IsValidCustomer=1` (no IsDepositor filter on EOD branch)
- Same-day open and close: a position opened and closed on the same day appears in OpenedPositions but NOT in OpenPositions (since it won't appear in BI_DB_PositionPnL at EOD)
- A user can contribute to UsersOpen and UsersHold independently — they are not mutually exclusive

### 2.2 Final INSERT Grain (CurrencyPriceWithSplit-Driven)

**What**: The final GROUP BY is on `Fact_CurrencyPriceWithSplit.InstrumentID` (not on the #tmp activity data). The #tmp table is LEFT JOINed — meaning any instrument with an EOD price gets a row regardless of activity.

**Columns Involved**: InstrumentID, Region, Country, EOD_Price, OpenedPositions, OpenPositions

**Rules**:
- InstrumentID = every instrument with `OccurredDateID = @ddINT` in `Fact_CurrencyPriceWithSplit`
- EOD_Price = MAX(Bid) from the price feed (aggregated across multiple intraday price entries)
- NULL Region/Country rows: if a position is held but no country mapping exists in Dim_Customer→Dim_Country, the row will have NULL dimensions (not observed in sample data but theoretically possible)
- NULL InstrumentType: instrument in price feed but missing from Dim_Instrument

### 2.3 Relationship to SP_Stocks_Opportunities

**What**: `SP_Stocks_Opportunities` reads from this table to identify instruments with strong user activity and first-action patterns.

**Columns Involved**: UsersOpen, EOD_Price, InstrumentID, Date

**Rules**:
- JOIN condition: `bddtd.Date = CAST(fa.FirstActionDate AS DATE) AND di.Name = fa.FirstInstrument AND fa.FirstAction = 'Stocks/ETFs'`
- This consumer relies on `BI_DB_First5Actions` (see BI_DB_First5Actions.md) for first-action context

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution means no natural co-location for any specific key. The CLUSTERED INDEX on DateID makes date-range filters (BETWEEN / = / >=) very efficient. Always filter by DateID (int format YYYYMMDD) for best performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Top instruments by holders today | `WHERE DateID=20260412 GROUP BY InstrumentID ORDER BY OpenPositions DESC` |
| Daily new-opens trend by instrument type | `WHERE DateID BETWEEN 20260101 AND 20260412 GROUP BY DateID, InstrumentType` |
| Region activity for a specific instrument | `WHERE InstrumentID=2093 GROUP BY DateID, Region ORDER BY DateID` |
| Instruments with high EOD_Price | `WHERE DateID=20260412 AND EOD_Price > 1000 ORDER BY EOD_Price DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Instrument | ON InstrumentID = di.InstrumentID | Enrich with InstrumentTypeID, Name, Sector |
| DWH_dbo.Dim_Date | ON DateID = dd.DateKey | Calendar dimensions (DayOfWeek, Month, Quarter) |
| BI_DB_dbo.BI_DB_First5Actions | ON Date=CAST(FirstActionDate AS DATE) AND InstrumentDisplayName/InstrumentID | First-action overlay (see SP_Stocks_Opportunities pattern) |

### 3.4 Gotchas

- **NULL InstrumentType**: ~2% of rows have NULL InstrumentType — filter `WHERE InstrumentType IS NOT NULL` to exclude ghost instruments from type-level aggregations.
- **OpenedPositions=0 ≠ No activity**: These rows are price-feed-driven. Most rows represent instruments in the price feed with no new customer opens. Use `WHERE OpenedPositions > 0` or `WHERE OpenPositions > 0` to restrict to instruments with actual activity.
- **ROUND_ROBIN + large date range**: Full scans across the 409.6M row table without a DateID filter will be slow. Always add a DateID filter.
- **EOD_Price is MAX(Bid)**: This is the highest bid price observed in the `Fact_CurrencyPriceWithSplit` feed on that date, not necessarily the closing market price. For instruments with multiple intraday price entries, MAX(Bid) may differ from the true closing price.
- **IsDepositor filter asymmetry**: The "Open" branch requires IsDepositor=1; the "EOD" branch does NOT. UsersHold may include non-depositor users who are holding positions (e.g., demo account users who converted).
- **MirrorID=0 filter**: Copy/mirror positions are excluded from BOTH branches. This table reports manual (non-copy) positions only.
- **Region is marketing region** (from Dim_Country via marketing region join), NOT geographic region. 22 distinct values matching the marketing desk taxonomy.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (DB_Schema / DWH_dbo); highest confidence |
| Tier 2 | Derived from ETL SP code analysis; high confidence |
| Tier 3 | Inferred from data analysis or dimension structure; medium confidence |
| Tier 4 | Best guess / legacy / undocumented source; low confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date for this row (calendar date, YYYY-MM-DD). Set from @dd parameter. Corresponds to DateID in date-integer format. (Tier 2 — SP_Daily_TradeData) |
| 2 | DateID | int | YES | The reporting date as YYYYMMDD integer. CONVERT(CHAR(8), @dd, 112). Used as the CLUSTERED INDEX key and the DELETE/INSERT partitioning key. (Tier 2 — SP_Daily_TradeData) |
| 3 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. Passthrough from DWH_dbo.Dim_Country.Region. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 4 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from DWH_dbo.Dim_Country.Name. (Tier 1 — Dictionary.Country) |
| 5 | InstrumentType | varchar(50) | YES | Text label for InstrumentTypeID — DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. NULL for instruments not in Dim_Instrument (~2% of rows). Passthrough from DWH_dbo.Dim_Instrument.InstrumentType. (Tier 2 — SP_Dim_Instrument) |
| 6 | InstrumentDisplayName | varchar(max) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. Passthrough from DWH_dbo.Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 7 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. Passthrough from DWH_dbo.Dim_Instrument.InstrumentID. (Tier 1 — Trade.Instrument) |
| 8 | EOD_Price | numeric(38,6) | YES | End-of-day bid price for the instrument. MAX(Bid) from DWH_dbo.Fact_CurrencyPriceWithSplit WHERE OccurredDateID=@ddINT. Represents the highest observed bid price across all intraday price feed entries for this instrument on this date. Range: 0.000032 (micro-cap crypto) to 15,359,454 (high-price equity). Never NULL (all instruments in price feed have at least one Bid entry). (Tier 2 — SP_Daily_TradeData) |
| 9 | OpenedPositions | int | YES | Count of positions opened on this date by valid depositor customers for this instrument × region × country combination. Filter: OpenDateID=@ddINT, MirrorID=0, IsPartialCloseChild=0, Tradable=1, IsValidCustomer=1, IsDepositor=1. Excludes mirror/copy positions and partial-close child positions. 91.7% of rows have OpenedPositions=0 (price-feed-driven rows with no new customer activity). (Tier 2 — SP_Daily_TradeData) |
| 10 | UsersOpen | int | YES | Count of distinct customers (CID) who opened at least one position for this instrument on this date. Same filters as OpenedPositions (depositor-only, non-mirror). Subset of the active trading population for the day. (Tier 2 — SP_Daily_TradeData) |
| 11 | OpenPositions | int | YES | Count of positions held open at end-of-day for this instrument × region × country combination. Sourced from BI_DB_PositionPnL WHERE DateID=@ddINT (EOD snapshot). Excludes mirror positions and partial-close children but does NOT require IsDepositor=1 (unlike OpenedPositions). Represents the live trading stock for the instrument as of EOD. (Tier 2 — SP_Daily_TradeData) |
| 12 | UsersHold | int | YES | Count of distinct customers (CID) holding at least one open position for this instrument at end-of-day. Same source as OpenPositions (BI_DB_PositionPnL EOD branch). No depositor filter — may include non-depositor account holders. (Tier 2 — SP_Daily_TradeData) |
| 13 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at INSERT time. Reflects the SP execution time (typically early morning, ~4am UTC). (Tier 2 — SP_Daily_TradeData) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Region | etoro.Dictionary.MarketingRegion | Name | via Dim_Country.Region JOIN chain |
| Country | etoro.Dictionary.Country | Name | passthrough via Dim_Country |
| InstrumentType | etoro.Trade.GetInstrument | InstrumentTypeID | CASE label in Dim_Instrument |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | join-enriched via Dim_Instrument |
| InstrumentID | etoro.Trade.GetInstrument | InstrumentID | passthrough via Dim_Instrument |
| EOD_Price | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | MAX(Bid) per instrument per date |
| OpenedPositions | etoro.Trade.PositionTbl | PositionID | COUNT(*) Open branch |
| UsersOpen | etoro.Trade.PositionTbl | CID | COUNT(DISTINCT CID) Open branch |
| OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | PositionID | COUNT(*) EOD branch |
| UsersHold | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT(DISTINCT CID) EOD branch |

### 5.2 ETL Pipeline

```
etoro.Trade (Dim_Position, Dim_Customer, Dim_Instrument, Dim_Country)
  |-- DWH_dbo dimensions (Synapse-resident) --|
  v
DWH_dbo.Dim_Position / Dim_Customer / Dim_Instrument / Dim_Country
  + DWH_dbo.Fact_CurrencyPriceWithSplit (EOD price feed)
  + BI_DB_dbo.BI_DB_PositionPnL (EOD position snapshot)
  |-- SP_Daily_TradeData @dd (DELETE WHERE DateID=@ddINT + INSERT) --|
  v
BI_DB_dbo.BI_DB_Daily_TradeData (409.6M rows, 2019-01-01 – 2026-04-12)
  |-- UC: Not Migrated --|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK to instrument dimension — resolves to instrument type, name, sector |
| Region, Country | DWH_dbo.Dim_Country | Source of region and country string values |
| OpenPositions, UsersHold | BI_DB_dbo.BI_DB_PositionPnL | EOD position snapshot driving the held-position counts |
| DateID | DWH_dbo.Dim_Date | FK to date dimension — resolves to calendar attributes |

### 6.2 Referenced By (other objects point to this)

| Object | Join Condition | Purpose |
|--------|---------------|---------|
| BI_DB_dbo.SP_Stocks_Opportunities | bddtd.Date, bddtd.InstrumentID | Stock opportunity analysis combining trade activity with first-action patterns from BI_DB_First5Actions |

---

## 7. Sample Queries

### Top instruments by EOD holders on a specific date

```sql
SELECT TOP 20
    InstrumentDisplayName,
    InstrumentType,
    SUM(OpenPositions) AS total_holders,
    SUM(UsersHold) AS unique_holders,
    AVG(EOD_Price) AS avg_price
FROM [BI_DB_dbo].[BI_DB_Daily_TradeData]
WHERE DateID = 20260412
  AND InstrumentType IS NOT NULL
GROUP BY InstrumentDisplayName, InstrumentType
ORDER BY total_holders DESC;
```

### Daily new-opens trend by instrument type (YTD 2026)

```sql
SELECT
    DateID,
    InstrumentType,
    SUM(OpenedPositions) AS new_opens,
    SUM(UsersOpen) AS unique_openers
FROM [BI_DB_dbo].[BI_DB_Daily_TradeData]
WHERE DateID BETWEEN 20260101 AND 20260412
  AND InstrumentType IS NOT NULL
GROUP BY DateID, InstrumentType
ORDER BY DateID, InstrumentType;
```

### Regional activity for a specific instrument (Unilever, InstrumentID=2093)

```sql
SELECT
    DateID,
    Region,
    Country,
    OpenedPositions,
    OpenPositions,
    UsersHold,
    EOD_Price
FROM [BI_DB_dbo].[BI_DB_Daily_TradeData]
WHERE InstrumentID = 2093
  AND DateID >= 20260101
ORDER BY DateID, Region, Country;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table during documentation. The SP header describes it only as "Bla" (placeholder description by original author Amir Gurewitz). Business context derived from SP code analysis and live data sampling.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14*  
*Tiers: 2 T1, 9 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 3/10, Sources: documented*  
*Object: BI_DB_dbo.BI_DB_Daily_TradeData | Type: Table | Production Source: SP_Daily_TradeData (DWH_dbo dimensions + BI_DB_PositionPnL)*
