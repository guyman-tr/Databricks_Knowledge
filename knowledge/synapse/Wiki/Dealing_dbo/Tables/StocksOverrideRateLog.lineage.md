# Lineage Map — Dealing_dbo.StocksOverrideRateLog

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_StocksOverrideRateLog(@Date)` (created Aug 2023)
**Pattern**: DELETE WHERE Date=@Date + INSERT (daily snapshot)

## ETL Chain

```
Dealing_staging.External_Etoro_Dictionary_InterestRateOverride (active overrides)
  → #Current (EndTime='9999-12-31' → NULL; Status='Active')

Dealing_staging.External_Etoro_History_InterestRateOverride (historical overrides)
  → #History (Status='Historical', with EndTime)

UNION → #concat_data → #Total_data
  JOIN DWH_dbo.Dim_Instrument — SymbolFull, InstrumentDisplayName, Exchange, SellCurrency
  Total_Buy = InterestRateBuy + MarkupBuy
  Total_Sell = InterestRateSell + MarkupSell
        └── Dealing_dbo.StocksOverrideRateLog
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | @Date parameter | — | Snapshot date |
| InstrumentID | Etoro_Dictionary_InterestRateOverride | InstrumentID | Direct |
| SymbolFull | DWH_dbo.Dim_Instrument | SymbolFull | Direct |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | Direct |
| SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | Direct |
| InterestRateBuy | Etoro_Dictionary_InterestRateOverride | InterestRateBuy | Direct |
| InterestRateSell | Etoro_Dictionary_InterestRateOverride | InterestRateSell | Direct |
| MarkupBuy | Etoro_Dictionary_InterestRateOverride | MarkupBuy | Direct |
| MarkupSell | Etoro_Dictionary_InterestRateOverride | MarkupSell | Direct |
| Total_Buy | Computed | InterestRateBuy + MarkupBuy | Summation |
| Total_Sell | Computed | InterestRateSell + MarkupSell | Summation |
| BeginTime | Etoro_Dictionary_InterestRateOverride | BeginTime | Direct |
| EndTime | Etoro_Dictionary_InterestRateOverride | EndTime | NULL if '9999-12-31...' (Active), else actual EndTime (Historical) |
| Status | Computed | — | 'Active' or 'Historical' |
| UpdateDate | GETDATE() | — | ETL timestamp |

## Governance

- **OpsDB**: Priority 0, Daily, SB_Daily
- **Active overrides**: EndTime sentinel '9999-12-31 23:59:59.9999999' → shown as NULL in table
- **Total rates**: InterestRate + Markup = Total (combined financing cost)
- **Source**: Production eToro Dictionary database (InterestRateOverride tables)
