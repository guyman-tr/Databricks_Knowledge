# Column Lineage: Dealing_dbo.Dealing_CEP_ExecutionMonitoring

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_CEP_ExecutionMonitoring` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `Dealing_staging.Etoro_Hedge_ExecutionLog` (LP) + `DWH_dbo.Dim_Position` (Clients) |
| **ETL SP** | `SP_CEP_ExecutionMonitoring` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_CurrencyPriceWithSplit` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Dealing_staging.Etoro_Hedge_ExecutionLog ──┐
DWH_dbo.Dim_Position ─────────────────────┤
DWH_dbo.Dim_Customer ─────────────────────┼──► SP_CEP_ExecutionMonitoring ──► Dealing_CEP_ExecutionMonitoring
DWH_dbo.Dim_Instrument ───────────────────┤
DWH_dbo.Fact_CurrencyPriceWithSplit ──────┘
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| HedgeServerID | ExecutionLog / Dim_Position | HedgeServerID | passthrough | LP: ExecutionLog.HedgeServerID. Clients: Dim_Position.HedgeServerID. | Liquidity provider server |
| InstrumentID | ExecutionLog / Dim_Position | InstrumentID | passthrough | — | Instrument FK |
| Instrument | DWH_dbo.Dim_Instrument | Name | join-enriched | Dim_Instrument.Name | Instrument name |
| TranType | — | — | ETL-computed | LP rows: literal 'LP'. Client rows: `CASE WHEN IsComputeForHedge=0 THEN 'IsComputeForHedge=0' WHEN LabelID=30 THEN 'LabelID=30' ELSE 'Clients' END` | Transaction source type |
| IsBuy | ExecutionLog / Dim_Position | IsBuy | ETL-computed | LP: direct. Clients: open=IsBuy, close=flipped (`CASE WHEN IsBuy=1 THEN 0 ELSE 1 END`) | Direction (flipped for closes) |
| Volume | Various | Volume, VolumeOnClose, Units*Rate | ETL-computed | LP: `SUM(Units * ExecutionRate * currency_conversion)`. Clients: `SUM(CAST(Volume AS BIGINT))` for opens, `SUM(CAST(VolumeOnClose AS BIGINT))` for closes. All in USD. | USD volume |
| Units | ExecutionLog / Dim_Position | Units, AmountInUnitsDecimal | ETL-computed | LP: `SUM(Units)`. Clients: `SUM(AmountInUnitsDecimal)`. | Instrument units |
| DateID | — | — | ETL-computed | `Dealing_dbo.DateToDateID(@Date)` | YYYYMMDD int |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |
| Date | — | — | ETL-computed | `@Date` SP parameter | Report date |
| Success | ExecutionLog | Success | passthrough | LP only. NULL for client rows. | Execution success flag |
| LiquidityAccountID | ExecutionLog | LiquidityAccountID | passthrough | LP only. NULL for client rows. | LP account ID |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 6 |
| **Join-enriched** | 1 |
| **Infrastructure** | 1 |
| **Total** | 12 |
