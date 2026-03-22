# Lineage Map — Dealing_dbo.Dealing_FactSet_NewPIs_History

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_FactSet_NewPIs_History(@Date)`
**Pattern**: TRUNCATE + INSERT (full daily snapshot)

## ETL Chain

```
Gold Data Lake (parquet)
  └── FactSet_PositionPnL_stg (External Table — Gold/Dealing/FactSet_stg/)
        └── #PositionPnL (temp) — position units, price, leverage, IsBuy, CopyType per CID
              + DWH_dbo.Dim_Customer — UserName, RealCID
              + DWH_dbo.Dim_Instrument — InstrumentDisplayName, InstrumentType, ISINCode, SellCurrency
              + DWH_dbo.Dim_GuruStatus (via Fact_SnapshotCustomer) — GuruStatusName (→ Tier)
              + DWH_dbo.V_Liabilities — StandardDeviation (→ LastNightRiskScore), TotalCash, RealizedEquity
              + BI_DB_dbo.BI_DB_Guru_Copiers — AUM (Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL)
              + DWH_dbo.Fact_CurrencyPriceWithSplit — AskSpreaded / BidSpreaded (→ Price)
              + BI_DB_dbo.DWH_GainDaily — Gain_d (→ RETURN_D)
                    └── Dealing_dbo.Dealing_FactSet_NewPIs_History
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | @Date parameter | — | Injection date |
| PortfolioDate | #PositionPnL (lake parquet) | Date | Direct |
| CopyType | #PositionPnL (lake parquet) | CopyType | Direct |
| Username | DWH_dbo.Dim_Customer | UserName | Direct |
| Tier | DWH_dbo.Dim_GuruStatus | GuruStatusName | Via Fact_SnapshotCustomer |
| LastNightRiskScore | DWH_dbo.V_Liabilities | StandardDeviation | CASE ladder 0.0011–0.0475 → 1–10 |
| AUM | BI_DB_dbo.BI_DB_Guru_Copiers | Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL | SUM |
| CashBalance | DWH_dbo.V_Liabilities | TotalCash / RealizedEquity | Ratio |
| InstrumentID | #PositionPnL (lake parquet) | InstrumentID | Direct |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Direct |
| ISIN | DWH_dbo.Dim_Instrument | ISINCode | Direct |
| Units | #PositionPnL (lake parquet) | AmountInUnitsDecimal | Direct |
| Price | DWH_dbo.Fact_CurrencyPriceWithSplit | AskSpreaded (IsBuy=1) / BidSpreaded (IsBuy=0) | CASE on IsBuy |
| Direction | #PositionPnL (lake parquet) | IsBuy | CASE: 1→'Long', 0→'Short' |
| Leverage | #PositionPnL (lake parquet) | Leverage | Direct |
| CID | #PositionPnL (lake parquet) | CID | Direct |
| Currency | DWH_dbo.Dim_Instrument | SellCurrency | Direct |
| RETURN_D | BI_DB_dbo.DWH_GainDaily | Gain_d | ISNULL(Gain_d, 0) |
| UpdateDate | GETDATE() | — | ETL timestamp |

## Governance

- **Generic Pipeline mapping**: Not applicable — source is lake parquet (Gold tier) external table, not Generic Pipeline ingestion
- **Scope filter**: Dealing_FactSet_Management.IsActive=1 AND HistorySendFlag=1 (only PIs whose history needs sending)
- **STALE since**: 2024-06-04 (last UpdateDate) — HistorySendFlag management likely paused

## Lost / Added Columns

**Added by ETL**:
- `LastNightRiskScore` — computed from V_Liabilities.StandardDeviation (10-bucket risk ladder)
- `AUM` — computed from BI_DB_Guru_Copiers aggregation
- `CashBalance` — ratio TotalCash/RealizedEquity
- `Direction` — decoded from IsBuy (Long/Short)
- `RETURN_D` — daily gain from DWH_GainDaily
