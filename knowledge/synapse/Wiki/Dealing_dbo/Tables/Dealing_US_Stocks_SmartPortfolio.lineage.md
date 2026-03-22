# Column Lineage: Dealing_dbo.Dealing_US_Stocks_SmartPortfolio

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_US_Stocks_SmartPortfolio` |
| **UC Target** | N/A (internal concentration monitoring) |
| **Primary Source** | `BI_DB_dbo.BI_DB_PositionPnL` (SmartPortfolio copier positions) |
| **ETL SP** | `Dealing_dbo.SP_US_Stocks_SmartPortfolio` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Mirror`, `DWH_dbo.Dim_Instrument`, `CopyFromLake.Rankings_StockInfo_InstrumentData`, `DWH_staging.Rankings_StockInfo_Metadata`, `DWH_dbo.Fact_CurrencyPriceWithSplit` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
SmartPortfolio Parents → DWH_dbo.Dim_Customer (AccountTypeID=9)
  → Active Copiers → DWH_dbo.Dim_Mirror (ParentCID IN SmartPortfolio parents)
  → Copier Positions → BI_DB_dbo.BI_DB_PositionPnL (DateID=@DateID, MirrorID IN active mirrors)
  + US Instrument Filter → DWH_dbo.Dim_Instrument (InstrumentTypeID=5, SellCurrencyID=1)
  + Market Data → CopyFromLake.Rankings_StockInfo_InstrumentData (ADV, SharesOutstanding)
  + FX Rates → DWH_dbo.Fact_CurrencyPriceWithSplit (for non-USD instruments)
  ↓
ETL: Dealing_dbo.SP_US_Stocks_SmartPortfolio (daily, @Date param, DELETE+INSERT by Date)
  ↓
Target: Dealing_dbo.Dealing_US_Stocks_SmartPortfolio
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived/calculated in ETL SP. |
| **join-enriched** | Joined from secondary source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | SP parameter | `@Date` | ETL-computed | `@Date` | Clustered index |
| `InstrumentID` | BI_DB_PositionPnL | `InstrumentID` | passthrough | Direct — US stocks only (InstrumentTypeID=5, SellCurrencyID=1) | — |
| `InstrumentDisplayName` | Dim_Instrument | `InstrumentDisplayName` | join-enriched | `JOIN Dim_Instrument ON InstrumentID` | From instrument metadata |
| `IsBuy` | BI_DB_PositionPnL | `IsBuy` | passthrough | Direct (bit 0/1) | Not converted to 'Buy'/'Sell' |
| `Symbol` | Dim_Instrument | `Symbol` | join-enriched | `JOIN Dim_Instrument ON InstrumentID` | Ticker symbol |
| `Exchange` | Dim_Instrument | `Exchange` | ETL-computed | `CASE WHEN Exchange IN ('Nasdaq',' NASDAQ') THEN 'Nasdaq' WHEN Exchange IN ('OTCMKTS','OTC Markets...') THEN 'OTC Markets Stock Exchange' ELSE 'NYSE' END` | Normalized 3-category |
| `ADV` | Rankings_StockInfo_InstrumentData | `NumVal` | join-enriched | MetadataID=8557 ('AverageDailyVolumeLast3Months-TTM') | External market data |
| `Units_NOP` | BI_DB_PositionPnL | `AmountInUnitsDecimal` | ETL-computed | `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` for all active SmartPortfolio copier mirrors at @DateID | Net position |
| `SharesOutStanding` | Rankings_StockInfo_InstrumentData | `NumVal` | join-enriched | MetadataID=8444 ('SharesOutstandingCurrent-Annual') | External market data |
| `Units_NOP/Shares Outstanding` | — | — | ETL-computed | `CAST(100 * ABS(Units_NOP / SharesOutStanding) AS DECIMAL(16,4))` | Concentration % — ≥5 triggers alert |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 5 |
| **Join-enriched** | 4 |
| **Total** | 11 |
