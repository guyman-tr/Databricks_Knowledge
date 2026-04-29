# BI_DB_dbo.BI_DB_Stocks_Opportunities

> 3.54M-row marketing-oriented stock and ETF opportunity analysis table with 5 indicator slices (Instruments_All, Region, Country, IndustryGroup_All, Country_All), tracking first-action counts, users with open positions, price gains (yesterday and 30-day), and 30-day rolling averages per instrument/geography/industry. 14-day rolling retention window. Sourced from BI_DB_Daily_TradeData + BI_DB_First5Actions via SP_Stocks_Opportunities (Amir Gurewitz, Nov 2020). ~355K rows per day.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_Daily_TradeData + BI_DB_First5Actions → SP_Stocks_Opportunities (Amir Gurewitz, 2020) |
| **Refresh** | Daily DELETE+INSERT by Date (retains 14 days: DELETE WHERE Date = @dd OR Date < DATEADD(DAY,-14,@dd)) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC, [InstrumentID] ASC) |
| **UC Target** | _Not_Migrated (not in Generic Pipeline mapping) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Stocks_Opportunities is a marketing analytics table that identifies stock and ETF trading opportunities by analyzing first-action adoption, open-position activity, and price momentum across multiple geographic and instrument dimensions. Each row represents one indicator slice (instrument-level, region, country, industry group, or country aggregate) for a single date.

The SP builds 5 separate aggregation slices from a 40-day lookback window of BI_DB_Daily_TradeData (stocks and ETFs only, weekdays only), computes 30-day rolling averages via window functions, calculates price-based gain metrics, and UNIONs all slices into a single output table. Only the @dd date rows are retained in the output (historical context is used only for rolling computations).

Key facts:
- 3.54M total rows with 14-day retention (2026-03-30 to 2026-04-10)
- ~355K rows per day across 5 indicators: Country (248K, 70%), Region (96K, 27%), Instruments_All (9.6K, 3%), Country_All (142), IndustryGroup_All (86)
- Sources: BI_DB_Daily_TradeData (instrument × region × country daily metrics), BI_DB_First5Actions (first stock/ETF action per customer), Dim_Instrument (metadata), Dim_Date (weekday filter)
- Grain varies by indicator: instrument×country, instrument×region, instrument-only, country-only, industry-only
- Weekends excluded via Dim_Date.DayNumberOfWeek_Sun_Start NOT IN (7,1)

---

## 2. Business Logic

### 2.1 Indicator Slicing

**What**: Five separate aggregation dimensions are computed and UNIONed.
**Columns Involved**: Indicator, InstrumentID, Region, Country, IndustryGroup
**Rules**:
- `Instruments_All`: Per instrument, all geographies combined. Has InstrumentID, no Region/Country/IndustryGroup
- `Region`: Per instrument × region. Has InstrumentID + Region, no Country
- `Country`: Per instrument × country. Has InstrumentID + Country, no Region
- `IndustryGroup_All`: Per industry group, all instruments combined. Has IndustryGroup, no InstrumentID
- `Country_All`: Per country, all instruments combined. Has Country, no InstrumentID
- NULL columns indicate the column is not relevant for that indicator slice

### 2.2 Rolling Average Computation

**What**: 30-day trailing averages of first-action and user-open metrics.
**Columns Involved**: Avg_FirstActions, Avg_UsersOpen
**Rules**:
- Window: `AVG(...) OVER (PARTITION BY {slice keys} ORDER BY Date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING)`
- Excludes the current day (starts from 1 PRECEDING)
- Partitioned by the appropriate dimension for each indicator slice

### 2.3 Price Gain Calculation

**What**: Price-based momentum indicators.
**Columns Involved**: Gain_Yesterday, Gain_30Days
**Rules**:
- Gain_Yesterday = (EOD_Price on @dd / EOD_Price on prior day) - 1
- Gain_30Days = (EOD_Price on @dd / EOD_Price 22 trading days ago) - 1
- EOD_Price = MAX(EOD_Price) from #pop per instrument per date
- LAG(22) used for 30 calendar days ≈ 22 trading days

### 2.4 First Action Matching

**What**: Count of new stock/ETF traders per instrument per date per country.
**Columns Involved**: FirstActions
**Rules**:
- LEFT JOIN to BI_DB_First5Actions on Date = FirstActionDate AND Dim_Instrument.Name = FirstInstrument AND FirstAction = 'Stocks/ETFs' AND Country match
- COUNT(DISTINCT CID) — each customer counted once regardless of action count
- ISNULL(..., 0) when no first actions exist

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CI on (Date, InstrumentID). Always filter on Date for efficient access. The composite index supports Date+InstrumentID lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Top instruments by first-action surge | `WHERE Indicator = 'Instruments_All' AND Date = @date ORDER BY FirstActions DESC` |
| Regional instrument trends | `WHERE Indicator = 'Region' AND Date = @date AND Region = 'X'` |
| Industry-level opportunity signals | `WHERE Indicator = 'IndustryGroup_All' AND Date = @date ORDER BY Gain_Yesterday DESC` |
| Country-level adoption trends | `WHERE Indicator = 'Country_All' AND Date = @date ORDER BY FirstActions DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Extended instrument metadata (symbol, ISIN, asset class) |

### 3.4 Gotchas

- **14-day retention only**: Data older than 14 days from the latest run date is deleted. No historical trend analysis beyond 2 weeks.
- **Indicator-dependent NULLs**: InstrumentID is NULL for Country_All and IndustryGroup_All indicators. Region/Country/IndustryGroup are NULL depending on the indicator slice.
- **IndustryGroup fallback**: Uses ISNULL(Dim_Instrument.IndustryGroup, Dim_Instrument.Industry) — Bloomberg IndustryGroup preferred, falls back to Trade.InstrumentMetaData.Industry.
- **Gain uses trading days**: Gain_30Days uses LAG(22) = 22 trading days, not 30 calendar days.
- **FirstActions matching by Name**: JOIN uses Dim_Instrument.Name (not InstrumentID) to match BI_DB_First5Actions.FirstInstrument — may miss instruments where Name differs from FirstInstrument.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Description | Tag Pattern |
|------|-------------|-------------|
| Tier 1 | Upstream wiki verbatim | `(Tier 1 — source)` |
| Tier 2 | SP code / DDL evidence | `(Tier 2 — SP)` |
| Tier 3 | Live data / structure | `(Tier 3 — source)` |
| Tier 5 | ETL metadata | `(Tier 5 — ETL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot calendar date — the SP parameter @dd. One slice per indicator dimension per date. (Tier 2 — SP_Stocks_Opportunities, BI_DB_Daily_TradeData.Date) |
| 2 | Indicator | varchar(50) | YES | Aggregation dimension slice: 'Instruments_All' (per instrument), 'Region' (per instrument×region), 'Country' (per instrument×country), 'IndustryGroup_All' (per industry), 'Country_All' (per country). Determines which columns are populated vs NULL. (Tier 2 — SP_Stocks_Opportunities, literal string) |
| 3 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. NULL for Country_All and IndustryGroup_All indicators (aggregate slices without instrument detail). Passthrough from BI_DB_Daily_TradeData. (Tier 1 — Trade.Instrument) |
| 4 | InstrumentName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for aggregate-only indicators and instruments without metadata. Passthrough from Dim_Instrument. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 5 | IndustryGroup | varchar(50) | YES | Bloomberg-style industry group or fallback to Trade.InstrumentMetaData.Industry when IndustryGroup is NULL. ISNULL(Dim_Instrument.IndustryGroup, Dim_Instrument.Industry). Populated for instrument-level indicators; primary key for IndustryGroup_All indicator. (Tier 2 — SP_Stocks_Opportunities, Dim_Instrument.IndustryGroup/Industry) |
| 6 | Exchange | varchar(50) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-instrument indicators and instruments without metadata. Passthrough from Dim_Instrument. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 7 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Populated only for Region indicator; NULL for all other indicators. Passthrough from BI_DB_Daily_TradeData. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | Country | varchar(100) | YES | Full country name in English. Populated for Country and Country_All indicators; NULL for other indicators. Passthrough from BI_DB_Daily_TradeData. (Tier 1 — Dictionary.Country) |
| 9 | FirstActions | int | YES | Count of distinct customers (CID) whose first stock/ETF action was on this date for this instrument/country combination. Sourced from BI_DB_First5Actions LEFT JOIN matching on FirstActionDate + Dim_Instrument.Name + Country + FirstAction='Stocks/ETFs'. ISNULL(..., 0). (Tier 2 — SP_Stocks_Opportunities, COUNT DISTINCT BI_DB_First5Actions.CID) |
| 10 | UsersOpen | int | YES | Count of users with open positions for this instrument/geography on @dd. SUM from BI_DB_Daily_TradeData.UsersOpen aggregated per indicator slice. (Tier 2 — SP_Stocks_Opportunities, BI_DB_Daily_TradeData.UsersOpen) |
| 11 | Gain_Yesterday | float | YES | Price change from prior trading day: (EOD_Price on @dd / EOD_Price on prior day) - 1. Computed from MAX(EOD_Price) per instrument. NULL for aggregate-only indicators without InstrumentID. (Tier 2 — SP_Stocks_Opportunities, computed from BI_DB_Daily_TradeData.EOD_Price) |
| 12 | Avg_FirstActions | float | YES | 30-day trailing average of daily FirstActions for this slice. AVG(FirstActions) OVER (ORDER BY Date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING). Excludes the current day. (Tier 2 — SP_Stocks_Opportunities, window function) |
| 13 | Avg_UsersOpen | float | YES | 30-day trailing average of daily UsersOpen for this slice. AVG(UsersOpen) OVER (ORDER BY Date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING). Excludes the current day. (Tier 2 — SP_Stocks_Opportunities, window function) |
| 14 | Gain_30Days | float | YES | Price change over ~30 calendar days (22 trading days): (EOD_Price on @dd / LAG(EOD_Price, 22)) - 1. NULL for aggregate-only indicators without InstrumentID. (Tier 2 — SP_Stocks_Opportunities, computed from BI_DB_Daily_TradeData.EOD_Price) |
| 15 | UpdateDate | datetime | YES | Row load timestamp set to GETDATE() at insert time. Not a business date. (Tier 5 — ETL metadata, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | BI_DB_dbo.BI_DB_Daily_TradeData | Date | Passthrough |
| Indicator | SP-computed | — | Literal string per aggregation slice |
| InstrumentID | BI_DB_dbo.BI_DB_Daily_TradeData | InstrumentID | Passthrough (NULL for aggregates) |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough |
| IndustryGroup | DWH_dbo.Dim_Instrument | IndustryGroup / Industry | ISNULL(IndustryGroup, Industry) |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | Dim-lookup passthrough |
| Region | BI_DB_dbo.BI_DB_Daily_TradeData | Region | Passthrough (NULL for non-Region) |
| Country | BI_DB_dbo.BI_DB_Daily_TradeData | Country | Passthrough (NULL for non-Country) |
| FirstActions | BI_DB_dbo.BI_DB_First5Actions | CID | COUNT(DISTINCT) per slice on @dd |
| UsersOpen | BI_DB_dbo.BI_DB_Daily_TradeData | UsersOpen | SUM per slice on @dd |
| Gain_Yesterday | BI_DB_dbo.BI_DB_Daily_TradeData | EOD_Price | (Yesterday/Prior) - 1 |
| Avg_FirstActions | BI_DB_dbo.BI_DB_First5Actions | CID | AVG 30-day rolling window |
| Avg_UsersOpen | BI_DB_dbo.BI_DB_Daily_TradeData | UsersOpen | AVG 30-day rolling window |
| Gain_30Days | BI_DB_dbo.BI_DB_Daily_TradeData | EOD_Price | (Yesterday/LAG22) - 1 |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Daily_TradeData (instrument×region×country daily metrics)
  + BI_DB_dbo.BI_DB_First5Actions (first stock/ETF action per CID per date per country)
  + DWH_dbo.Dim_Instrument (IndustryGroup, Industry, Exchange, InstrumentDisplayName)
  + DWH_dbo.Dim_Date (weekday filter: DayNumberOfWeek_Sun_Start NOT IN 7,1)
  |-- SP_Stocks_Opportunities @dd ---|
  |  #pop: base population (40-day lookback, stocks/ETFs, weekdays)
  |  5 CTEs: Instruments_All, Region, Country, IndustryGroup_All, Country_All
  |  30-day rolling AVG(FirstActions), AVG(UsersOpen) via window functions
  |  #Gain: yesterday/prior and yesterday/30-day price ratios
  |  UNION all slices → UPDATE with Dim_Instrument metadata + gains
  |  DELETE Date=@dd and Date < @dd-14 → INSERT
  v
BI_DB_dbo.BI_DB_Stocks_Opportunities (3.54M rows, 14-day retention, ~355K/day)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata lookup |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship |
|-------------------|-------------|
| Marketing dashboards | Primary consumer (external) |

---

## 7. Sample Queries

### 7.1 Top Instruments by First-Action Surge vs 30-Day Average

```sql
SELECT InstrumentName, InstrumentID, FirstActions, Avg_FirstActions,
       CASE WHEN Avg_FirstActions > 0
            THEN (FirstActions - Avg_FirstActions) / Avg_FirstActions
            ELSE NULL END AS SurgeRatio
FROM BI_DB_dbo.BI_DB_Stocks_Opportunities
WHERE Indicator = 'Instruments_All'
  AND Date = '2026-04-10'
  AND FirstActions > 0
ORDER BY SurgeRatio DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
```

### 7.2 Regional Instrument Adoption

```sql
SELECT Region, InstrumentName, FirstActions, UsersOpen,
       Gain_Yesterday, Gain_30Days
FROM BI_DB_dbo.BI_DB_Stocks_Opportunities
WHERE Indicator = 'Region'
  AND Date = '2026-04-10'
  AND Region = 'ROW'
ORDER BY FirstActions DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
```

### 7.3 Industry Group Momentum

```sql
SELECT IndustryGroup, FirstActions, UsersOpen,
       Avg_FirstActions, Avg_UsersOpen
FROM BI_DB_dbo.BI_DB_Stocks_Opportunities
WHERE Indicator = 'IndustryGroup_All'
  AND Date = '2026-04-10'
ORDER BY FirstActions DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 11 T2, 0 T3, 0 T4, 1 T5 | Elements: 15/15, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Stocks_Opportunities | Type: Table | Production Source: BI_DB_Daily_TradeData + BI_DB_First5Actions via SP_Stocks_Opportunities*
