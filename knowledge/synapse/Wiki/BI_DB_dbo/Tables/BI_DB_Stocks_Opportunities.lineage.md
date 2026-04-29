# BI_DB_dbo.BI_DB_Stocks_Opportunities — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_Daily_TradeData | BI_DB_dbo | Primary — daily instrument×region×country trade metrics (UsersOpen, EOD_Price) |
| BI_DB_First5Actions | BI_DB_dbo | Join — first action counts per instrument per date per country |
| Dim_Instrument | DWH_dbo | Lookup — IndustryGroup, Industry, Exchange, InstrumentDisplayName |
| Dim_Date | DWH_dbo | Filter — exclude weekends (DayNumberOfWeek_Sun_Start NOT IN 7,1) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | BI_DB_dbo.BI_DB_Daily_TradeData | Date | Passthrough (= @dd) |
| Indicator | SP-computed | — | Literal: 'Instruments_All', 'Region', 'Country', 'IndustryGroup_All', 'Country_All' |
| InstrumentID | BI_DB_dbo.BI_DB_Daily_TradeData | InstrumentID | Passthrough (NULL for aggregate-only indicators) |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough via InstrumentID |
| IndustryGroup | DWH_dbo.Dim_Instrument | IndustryGroup, Industry | ISNULL(IndustryGroup, Industry) |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | Dim-lookup passthrough via InstrumentID |
| Region | BI_DB_dbo.BI_DB_Daily_TradeData | Region | Passthrough (NULL for non-Region indicators) |
| Country | BI_DB_dbo.BI_DB_Daily_TradeData | Country | Passthrough (NULL for non-Country indicators) |
| FirstActions | BI_DB_dbo.BI_DB_First5Actions | CID | COUNT(DISTINCT CID) on @dd, aggregated per slice |
| UsersOpen | BI_DB_dbo.BI_DB_Daily_TradeData | UsersOpen | SUM on @dd per slice |
| Gain_Yesterday | BI_DB_dbo.BI_DB_Daily_TradeData | EOD_Price | (Yesterday_EOD / DayBefore_EOD) - 1 |
| Avg_FirstActions | BI_DB_dbo.BI_DB_First5Actions | CID | AVG(FirstActions) OVER 30-day rolling window |
| Avg_UsersOpen | BI_DB_dbo.BI_DB_Daily_TradeData | UsersOpen | AVG(UsersOpen) OVER 30-day rolling window |
| Gain_30Days | BI_DB_dbo.BI_DB_Daily_TradeData | EOD_Price | (Yesterday_EOD / 30DaysBefore_EOD) - 1 |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Daily_TradeData (instrument×region×country daily metrics)
  + BI_DB_dbo.BI_DB_First5Actions (first action date matching)
  + DWH_dbo.Dim_Instrument (display name, industry, exchange)
  + DWH_dbo.Dim_Date (weekday filter)
  |-- SP_Stocks_Opportunities @dd ---|
  |  Build 5 slices: Instruments_All, Region, Country, IndustryGroup_All, Country_All
  |  30-day rolling AVG via window functions (ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING)
  |  Price gain: yesterday EOD/prior EOD and yesterday EOD/30-day-ago EOD
  |  UNION all slices → UPDATE with Dim_Instrument metadata + gain calculations
  v
BI_DB_dbo.BI_DB_Stocks_Opportunities (3.54M rows, 14-day retention)
```
