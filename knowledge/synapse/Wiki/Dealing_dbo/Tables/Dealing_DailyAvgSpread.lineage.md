# Column Lineage: Dealing_dbo.Dealing_DailyAvgSpread

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_DailyAvgSpread` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Dim_Position` |
| **ETL SP** | `Dealing_dbo.SP_DailyAvgSpread` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula |
|-----------|-------------|---------------|-----------|---------------------|
| Date | — | — | ETL-computed | `@Date` SP parameter |
| InstrumentID | Dim_Position | InstrumentID | passthrough | Via Dim_Instrument JOIN |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | join-enriched | Instrument ticker |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | join-enriched | Asset class |
| Hour | Dim_Position | OpenOccurred / CloseOccurred | ETL-computed | `DATEADD(hour, DATEDIFF(hour,0,OpenOccurred), 0)` — truncated to hour |
| HourlyAvg_PPSpread | Dim_Position | InitForex_Ask, InitForex_Bid (+ EndForex*) | ETL-computed | `AVG(ABS(Ask-Bid))` for trades in that hour |
| HourlyAvg_EtoroSpread | Dim_Position | InitForex_AskSpreaded, InitForex_BidSpreaded (+ EndForex*) | ETL-computed | `AVG(ABS(AskSpreaded-BidSpreaded))` for that hour |
| NumberofTradesHourly | — | — | ETL-computed | `SUM(CASE WHEN PPSpread IS NULL THEN 0 ELSE 1 END)` per hour |
| HourlyPPSpread_DividedByEtoroSpread | — | — | ETL-computed | `HourlyAvg_PPSpread / HourlyAvg_EtoroSpread` |
| DailyAvg_PPSpread | Dim_Position | InitForex*, EndForex* | ETL-computed | `AVG(ABS(Ask-Bid))` for all trades in the day |
| DailyAvg_EtoroSpread | Dim_Position | InitForex*Spreaded, EndForex*Spreaded | ETL-computed | `AVG(ABS(AskSpreaded-BidSpreaded))` for the day |
| NumberofTradesDaily | — | — | ETL-computed | Count of trades with non-null PPSpread for the day |
| DailyPPSpread_DividedByEtoroSpread | — | — | ETL-computed | `DailyAvg_PPSpread / DailyAvg_EtoroSpread` |
| YTDAvg_PPSpread | Dim_Position | InitForex*, EndForex* | ETL-computed | `AVG(ABS(Ask-Bid))` for trailing 1 year |
| YTDAvg_EtoroSpread | Dim_Position | InitForex*Spreaded, EndForex*Spreaded | ETL-computed | `AVG(ABS(AskSpreaded-BidSpreaded))` for trailing 1 year |
| YTDPPSpread_DividedByEtoroSpread | — | — | ETL-computed | `YTDAvg_PPSpread / YTDAvg_EtoroSpread` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 14 |
| **Join-enriched** | 2 |
| **Passthrough** | 1 |
| **Total** | 17 |
