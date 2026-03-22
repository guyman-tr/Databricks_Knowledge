# Lineage Map — Dealing_dbo.Dealing_Regime_Flags

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_Regime_Flags()` — no date parameter; full DELETE + INSERT
**Pattern**: DELETE ALL + INSERT (full refresh — entire history recomputed each run)

## ETL Chain

```
Dealing_dbo.Dealing_DealingDashboard_Clients (DateID >= 20190101)
  → #Zero (TotalZero — client hedge coverage, rolling 1/5/10 day windows)
  → #Volume (TotalVolume — trading volume, rolling windows)
  → #NOP → #NOP1 (NOP Change — day-over-day NOP delta)

DWH_dbo.Fact_CurrencyPriceWithSplit (OccurredDateID >= 20190101)
  + DWH_dbo.Dim_Instrument
  → #Price → #Price1 (Price Change Rate — % price change, rolling windows)

#Zero + #Volume + #NOP1 + #Price1 → UNION → #Union
  (filtered by DWH_dbo.Dim_Instrument WHERE Tradable=1 AND VisibleInternallyOnly=0)

Z-score lookup table (#Z: 0.0–3.0 → 0.50–0.9987 percentiles)

#Union → rolling window stats (STDEV, AVG) → #T → #T1 (Z-scores) → #T2 (rounded Z) → #T3 (percentiles)
  → #Final (join InstrumentName from Dim_Instrument)
        └── Dealing_dbo.Dealing_Regime_Flags
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | Dealing_DealingDashboard_Clients / Fact_CurrencyPriceWithSplit | Date | Direct |
| MeasureName | Computed | — | 'Zero', 'Volume', 'NOP Change', 'Price Change Rate' |
| InstrumentID | Source tables | InstrumentID | Direct |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Joined on InstrumentID |
| InstrumentType | Source tables | InstrumentType | Direct |
| DailyMeasure | Computed | TotalZero/TotalVolume/NOP/Bid | Raw daily value |
| WeeklyMeasure | Computed | — | Rolling 5-day SUM or LAG(5) |
| FortnightlyMeasure | Computed | — | Rolling 10-day SUM or LAG(10) |
| NumOfDistribution | Computed | — | 504/252/126 days based on available history |
| Counti | Computed | — | Actual row count in rolling window |
| Is_Included | Computed | — | 1 if Counti >= NumOfDistribution (enough history) |
| Daily_Z_Score_R | Computed | — | ROUND((DailyMeasure - AVG) / STDEV, 1) |
| Weekly_Z_Score_R | Computed | — | ROUND((WeeklyMeasure - WeeklyAVG) / WeeklySP, 1) |
| Fortnightly_Z_Score_R | Computed | — | ROUND((FortnightlyMeasure - FortnightlyAVG) / FortnightlySD, 1) |
| Daily_Percentile | #Z lookup | Percentile | CASE: Z>3→1, Z<-3→0, else lookup |
| Weekly_Percentile | #Z lookup | Percentile | Same pattern |
| Fortnightly_Percentile | #Z lookup | Percentile | Same pattern |
| UpdateDate | GETDATE() | — | ETL timestamp |
| DailyMeasure1 | Computed | — | Raw measure for Zero/Volume; raw NOP/price for NOP/Price types |

## Governance

- **No OpsDB entry** — not tracked in Service Broker orchestration
- **STALE since 2025-01-19** — last run January 2025 (~2 months ago as of Mar 2026)
- **Crypto handling**: Includes weekends (DATEPART dw NOT excluded for Crypto); non-Crypto excludes Sat/Sun
- **History depth**: 504 trading days (~2 years) preferred; 252 if insufficient; 126 minimum
- **Source dependency**: Dealing_DealingDashboard_Clients must be current for accurate regime detection
