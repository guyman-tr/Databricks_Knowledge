# BI_DB_dbo.BI_DB_rsk_Portfolio — Column Lineage

**Generated**: 2026-04-23 | **Pipeline**: SP_rsk_Portfolio (@sd → @date = @sd+1)

## ETL Chain

```
DWH_dbo.Dim_Position (open positions snapshot)
  |-- SP_rsk_Portfolio (@sd → @date=@sd+1) ---|
  |-- JOIN DWH_dbo.Dim_Instrument (Name)      ---|
  v
BI_DB_dbo.BI_DB_rsk_Portfolio (DELETE WHERE Date=@date + INSERT)
  |-- SP_rsk_AgregatedRisk (@sd) -- reads WHERE Date=@eed ---|
  v
BI_DB_dbo.BI_DB_rsk_DailyRiskAgg (risk metrics)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Position | CID | Passthrough (group-by key) | Tier 1 — DWH_dbo.Dim_Position |
| 2 | InstrumentID | DWH_dbo.Dim_Instrument (via Dim_Position JOIN) | InstrumentID | Passthrough (group-by key) | Tier 1 — DWH_dbo.Dim_Instrument |
| 3 | InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough (b.Name AS InstrumentName) | Tier 1 — DWH_dbo.Dim_Instrument |
| 4 | MirrorID | DWH_dbo.Dim_Position | MirrorID | Passthrough (group-by key) | Tier 1 — DWH_dbo.Dim_Position |
| 5 | Net_USD_Vol | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, IsBuy, SellCurrencyID, BuyCurrencyID, LastOpConversionRate | SUM(AmountInUnitsDecimal × InitForexRate × (IsBuy ? +1 : -1) × conversion) — signed net USD exposure | Tier 2 — SP_rsk_Portfolio |
| 6 | USD_Vol | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, SellCurrencyID, BuyCurrencyID, LastOpConversionRate | SUM(AmountInUnitsDecimal × InitForexRate × conversion) — unsigned absolute USD volume | Tier 2 — SP_rsk_Portfolio |
| 7 | Date | ETL parameter | @date = DateAdd(Day,1,@sd) | ETL date stamp — stored date is @sd+1 (current day) | Tier 2 — SP_rsk_Portfolio |
| 8 | UpdateDate | GETDATE() | — | ETL metadata: row write timestamp | Propagation |

## Notes

- **Population**: All open positions at `Date` — WHERE OpenOccurred <= @date AND (CloseOccurred >= @date OR CloseDateID = 0)
- **Date semantics**: SP receives @sd (yesterday). Internally: `@date = DateAdd(Day,1,@sd)`. The stored `Date` value equals the day AFTER the SP @sd parameter. Rows for date D are loaded when SP runs with @sd = D-1.
- **MirrorID=0**: Direct/manual position. **MirrorID>0**: Copy-trade position — join to Dim_Mirror for copier→Popular Investor relationship.
- **Net_USD_Vol vs USD_Vol**: `Net_USD_Vol` is signed (long=positive, short=negative), capturing directional exposure. `USD_Vol` is unsigned (absolute size). For long-only positions: Net_USD_Vol ≈ USD_Vol.
- **Downstream**: `SP_rsk_AgregatedRisk` reads `WHERE Date = @eed` (= @sd+1) from this table to compute instrument covariance and portfolio risk metrics → `BI_DB_rsk_DailyRiskAgg`.
