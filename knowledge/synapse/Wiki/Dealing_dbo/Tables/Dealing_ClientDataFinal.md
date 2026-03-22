---
object: Dealing_ClientDataFinal
schema: Dealing_dbo
type: Table
description: Weekly per-instrument×country trading behavior summary: average volumes, leverage, position close reasons, order size, time-of-day activity, and order modification rates. Primary input for the Tableau Client Data report.
etl_sp: Dealing_dbo.SP_W_Sat_WeeklyClientData
frequency: Weekly (Saturday)
status: Active (last: 2026-03-06)
row_count: ~18,151
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_ClientDataFinal

Weekly snapshot of client trading behavior broken down by instrument and client country. Covers the prior week's positions (stocks, indices, commodities — InstrumentTypeID IN 4, 2, 1). Used in the Dealing Dashboard Tableau workbook to characterize how clients trade each instrument by geography.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Position-level data: volume, leverage, open/close timing, close reason |
| Dimension | `DWH_dbo.Dim_Instrument` | Instrument name and type filter |
| Dimension | `DWH_dbo.Fact_SnapshotCustomer` | Customer snapshot at run date (IsValidCustomer=1 filter) |
| Dimension | `DWH_dbo.Dim_Country` | Customer country name |
| Source (SL/TP change) | `CopyFromLake.etoro_History_PositionChangeLog` | Stop-loss and limit-rate change counts |
| Writer | `Dealing_dbo.SP_W_Sat_WeeklyClientData` | Weekly Saturday, OpsDB Priority 0 |

**Scope**: InstrumentTypeID IN (4=Stocks, 2=Indices, 1=Commodities). Positions opened OR closed during the last 7 days (Sunday→Saturday). Valid customers only.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `InstrumentID` | int | NOT NULL | Instrument primary key from DWH_dbo.Dim_Instrument. |
| `InstrumentDisplayName` | varchar(100) | NULL | Instrument display name. Denormalized. |
| `AvgUniqueCIDsPerDay` | int | NULL | Average number of distinct CIDs trading this instrument per calendar day during the reporting week. Computed as SUM(daily_unique_CIDs)/5. |
| `AvgDailyTrades` | int | NULL | Average number of trades (opens + closes) per day during the week. Computed as SUM(daily_trades)/5. |
| `AverageLevBuy` | int | NULL | Average leverage on buy positions opened during the week. |
| `AverageLevSell` | int | NULL | Average leverage on sell positions opened during the week. |
| `Country` | varchar(50) | NOT NULL | Client's home country (from Dim_Country). Row is per instrument × country combination. |
| `maxVol` | bigint | NULL | Maximum single-position volume (in instrument units) seen during the week. |
| `WeeklyTotalVolume` | bigint | NULL | Total volume across all positions (opens + closes) during the week. |
| `percentage_of_total` | decimal(37,19) | NULL | This instrument's weekly volume as a percentage of total volume across all instruments for this country. |
| `AvgDailyVolume` | bigint | NULL | Average daily volume (total weekly volume / 5). |
| `AvgWeeklyOrderSize` | bigint | NULL | Average volume per individual position during the week. |
| `MaxWeeklyOrderSize` | bigint | NULL | Maximum single position volume during the week. |
| `AvgWeeklyInvestedAmt` | bigint | NULL | Average invested amount (Volume × InitForexRate) per position. |
| `sl_closed` | float | NULL | Fraction of positions closed by stop-loss trigger during the week. |
| `tp_closed` | float | NULL | Fraction of positions closed by take-profit trigger during the week. |
| `opened` | float | NULL | Fraction of positions that were opened (not yet closed) as of end of week. |
| `other_closed` | float | NULL | Fraction of positions closed by reasons other than SL/TP (manual close, liquidation, etc.). |
| `day_part` | int | NULL | Average day-of-hold duration: integer number of days between open and close. |
| `hour_part` | decimal(38,6) | NULL | Fractional hours beyond day_part: (avg decimal days - avg integer days) × 24. Together with day_part, gives average holding duration. |
| `percentageOfChanged` | float | NULL | Fraction of positions where the client modified the SL or TP rate at least once (from CopyFromLake.etoro_History_PositionChangeLog). |
| `avgStopRateChange` | float | NULL | Average number of times the stop-loss rate was changed per position. |
| `avgLimitRateChange` | float | NULL | Average number of times the take-profit (limit) rate was changed per position. |
| `Date` | date | NULL | Saturday run date (end of the reporting week). |
| `DateID` | int | NULL | Integer date key (YYYYMMDD) for the run date. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2022-03-26 → 2026-03-06 (weekly Saturdays), 18,151 rows
- Granularity: one row per instrument × country × Saturday
- InstrumentTypeID filter (4,2,1) excludes FX, Crypto, ETFs from this table
- AvgDailyTrades and AvgUniqueCIDsPerDay divided by 5 (assumes 5 trading days/week) — weekend activity not separately counted
- percentageOfChanged from CopyFromLake.etoro_History_PositionChangeLog (requires SP_Copy_Temporary_Data load for the week)

## Business Context

Primary data source for the Dealing team's weekly Tableau dashboard on client trading patterns. Answers: "For instrument X in country Y, how often do clients trade it, at what leverage, what is their typical order size, and do they modify their stops?" Used for market surveillance (detecting unusual leverage or order-size spikes) and product analysis.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientDataRecurring` | Sister table — same SP, recurring trader analysis for same instrument set |
| `Dealing_ClientDataTop50` | Sister table — top 50 CIDs by volume per instrument per week |
| `Dealing_ClientsDataChange_3Months` | Sister table — same metrics compared vs. 3 months ago |
| `Dealing_ClientsDataChange_6Months` | Sister table — same metrics compared vs. 6 months ago |

## Quality Score: 8.5/10
*Strong: SP logic traced in detail, all 24 columns documented, holding-duration decomposition (day_part + hour_part) explained. Minor deduction: percentage_of_total denominator not confirmed (assumed all-instrument total per country).*
