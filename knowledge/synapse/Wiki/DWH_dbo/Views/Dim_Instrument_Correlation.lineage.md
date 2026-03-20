# DWH_dbo.Dim_Instrument_Correlation — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Source** | None — DWH-computed internally |
| **Price Data Source** | DWH_dbo.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted |
| **Computation Window** | 3-month rolling (hourly candles) |
| **Storage** | 20 partition tables (Half_Records_1..20) + Archive |
| **Upstream Wiki** | None — original DWH computation |

## Column Lineage

| # | View Column | Source | Transform | Notes |
|---|-----------|--------|-----------|-------|
| 1 | DateID | SP parameter @auxdate | CONVERT(INT, CONVERT(VARCHAR(8), @auxdate, 112)) | Computation date, not data date |
| 2 | InstrumentID_a | #data (self-join) | `a.InstrumentID` or swapped `b.InstrumentID` | View reconstructs symmetric matrix |
| 3 | InstrumentID_b | #data (self-join) | `b.InstrumentID` or swapped `a.InstrumentID` | View reconstructs symmetric matrix |
| 4 | SampleSize | Computed | COUNT(*) of matched hourly candle pairs | Per instrument pair |
| 5 | StandardDeviation_a | Computed | STDEVP(PriceChange_a) | Population standard deviation |
| 6 | StandardDeviation_b | Computed | STDEVP(PriceChange_b) | Population standard deviation |
| 7 | Covariance | Computed | SUM(a*b)/N - SUM(a)*SUM(b)/N² | Manual covariance formula |
| 8 | PearsonCorrelation | Computed | Covariance / NULLIF(StdDev_a * StdDev_b, 0) | NULL when either StdDev = 0 |
| 9 | InsertDate | GETDATE() | ETL timestamp | When correlation was computed |
| 10 | UpdateDate | GETDATE() | ETL timestamp | Same as InsertDate (DELETE+INSERT pattern) |

## Intermediate Objects

| Object | Type | Role |
|--------|------|------|
| Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | External/Table | Hourly price candle source |
| #data (temp table) | Temp | Price changes: (AskLast-AskFirst)/AskFirst |
| Dim_Instrument_Correlation_GroupsInstruments | Table | Instrument-to-group mapping |
| Dim_Instrument_Correlation_Half_Records_1..20 | Tables | Active half-matrix storage |
| Dim_Instrument_Correlation_Archive | Table | Historical half-matrix storage |
| Dim_Instrument_Correlation_UnionedPartitions | View | UNION ALL of 20 partition tables |

## ETL Stored Procedures

| SP | Role |
|----|------|
| SP_Dim_Instrument_Correlation_Build_GroupsInstruments | Partition instruments into groups (~89) |
| SP_Dim_Instrument_Correlation_ByGroupRange | Orchestrator: loop over groups for a table |
| SP_Dim_Instrument_Correlation_FilterByInstrumentID | Worker: compute correlations for one group |
