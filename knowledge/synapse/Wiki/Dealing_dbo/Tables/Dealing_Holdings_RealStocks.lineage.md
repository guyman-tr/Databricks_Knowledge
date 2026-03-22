# Column Lineage: Dealing_dbo.Dealing_Holdings_RealStocks

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Holdings_RealStocks` |
| **UC Target** | N/A (BNY Mellon custodian holdings report) |
| **Primary Source** | `Dealing_staging.etoro_Hedge_Netting` + `etoro_History_Netting_History` (temporal hedge positions) |
| **ETL SP** | `Dealing_dbo.SP_Holdings_RealStocks` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_CurrencyPriceWithSplit` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Current Hedge Positions → Dealing_staging.etoro_Hedge_Netting
  (UpdateTime < @Date+1, HedgeServerID IN (3,9,102,128,112,125,126,2,101,129))
UNION
Historical Hedge Positions → Dealing_staging.etoro_History_Netting_History
  (SysEndTime >= @Date+1 AND SysStartTime < @Date+1, same HS filter)
  + EOD Prices + FX Rates → DWH_dbo.Fact_CurrencyPriceWithSplit (OccurredDateID=@DateID)
  + Instrument Metadata → DWH_dbo.Dim_Instrument
  ↓
ETL: Dealing_dbo.SP_Holdings_RealStocks (daily, @Date param, DELETE+INSERT by Date)
  ↓
Target: Dealing_dbo.Dealing_Holdings_RealStocks
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived/calculated in ETL SP. |
| **join-enriched** | Joined from secondary source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | SP parameter | `@Date` | ETL-computed | `@Date` | Clustered index |
| `InstrumentID` | etoro_Hedge_Netting | `InstrumentID` | passthrough | Direct from netting tables | Grouped per instrument×IsSettled |
| `InstrumentDisplayName` | Dim_Instrument | `InstrumentDisplayName` | join-enriched | `LEFT JOIN Dim_Instrument ON InstrumentID` | — |
| `ISIN` | Dim_Instrument | `ISINCode` | rename | `ISINCode AS ISIN` | Note: renamed from ISINCode |
| `Units` | etoro_Hedge_Netting | `Units, IsBuy` | ETL-computed | `SUM((2*IsBuy-1)*Units)` per instrument×IsSettled | Net position; positive=long |
| `Amount_USD` | etoro_Hedge_Netting + Fact_CurrencyPriceWithSplit | `Units, IsBuy` + `Bid/Ask` | ETL-computed | `SUM((2*IsBuy-1)*Units*EOD_Price*ConversionRate)` where EOD_Price=Bid(Buy)/Ask(Sell), ConversionRate=multi-step FX chain | USD market value at EOD |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |
| `IsSettled` | etoro_Hedge_Netting | `HedgeServerID` | ETL-computed | `CASE WHEN HedgeServerID IN (3,9,102,128,112,125,126) THEN 'Real' ELSE 'CFD' END` | Settlement type classification |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 5 |
| **Join-enriched** | 1 |
| **Total** | 8 |
