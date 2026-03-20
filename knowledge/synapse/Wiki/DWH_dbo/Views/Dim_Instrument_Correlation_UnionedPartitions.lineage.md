# Column Lineage: DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions` |
| **UC Target** | _Pending_ |
| **Primary Source** | Derived (DWH-computed statistical calculation) |
| **ETL SP** | `DWH_dbo.SP_Dim_Instrument_Correlation_Half_Records` |
| **Secondary Sources** | `DWH_dbo.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted` (staging price candles) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Price Server (hourly candles)
  -> Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted  [staging table, 3-month window]
  -> SP_Dim_Instrument_Correlation_Half_Records  [cross-join + Pearson calc]
  -> Dim_Instrument_Correlation_Half_Records  [logical base table]
  -> Dim_Instrument_Correlation_Half_Records_1 ... _20  [20 physical partitions]
  -> Dim_Instrument_Correlation_UnionedPartitions  [UNION ALL view = this object]
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **cast/convert** | Type conversion only. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateID | — | @auxdate parameter | cast/convert | CONVERT(int, CONVERT(varchar, @auxdate, 112)) = YYYYMMDD |
| InstrumentID_a | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | InstrumentID | ETL-computed | Self-join result: a.InstrumentID WHERE a.InstrumentID <= b.InstrumentID |
| InstrumentID_b | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | InstrumentID | ETL-computed | Self-join result: b.InstrumentID WHERE a.InstrumentID <= b.InstrumentID |
| SampleSize | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | — | ETL-computed | COUNT(*) of hourly candle pairs where both instruments had prices |
| StandardDeviation_a | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | AskLast, AskFirst | ETL-computed | STDEVP((AskLast-AskFirst)/AskFirst) for InstrumentID_a |
| StandardDeviation_b | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | AskLast, AskFirst | ETL-computed | STDEVP((AskLast-AskFirst)/AskFirst) for InstrumentID_b |
| Covariance | Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted | AskLast, AskFirst | ETL-computed | sum(pa*pb)/n - sum(pa)*sum(pb)/n^2 where p=(AskLast-AskFirst)/AskFirst |
| PearsonCorrelation | — | — | ETL-computed | Covariance / NULLIF(StdDev_a * StdDev_b, 0) |
| InsertDate | — | — | ETL-computed | GETDATE() at SP execution time |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 0 |
| **ETL-computed** | 9 |
| **cast/convert** | 1 |
| **Total** | 10 |

## Lost / Added Columns

**Lost from source** (price candle data not passed through):
- rn, BidLast, BidFirst (raw price columns - used only in computation, not stored)
- DateFrom (transformed to DateID YYYYMMDD integer)

**Added in DWH** (computed):
- SampleSize, StandardDeviation_a/b, Covariance, PearsonCorrelation (all derived statistics)
