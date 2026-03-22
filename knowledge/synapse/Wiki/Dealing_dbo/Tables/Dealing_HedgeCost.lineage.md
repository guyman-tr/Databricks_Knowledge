# Column Lineage: Dealing_dbo.Dealing_HedgeCost

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_HedgeCost` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `etoro.Hedge.ExecutionLog` (etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_HedgeCost` |
| **Secondary Sources** | `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_PositionChangeLog`, `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`, `BI_DB_dbo.BI_DB_VarCommission`, `DWH_dbo.Fact_CurrencyPriceWithSplit` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (etoro.Hedge.ExecutionLog, etoroDB-REAL)
    ↓ Generic Pipeline (hourly) → Bronze/etoro/Hedge/ExecutionLog/
    ↓ → dealing.bronze_etoro_hedge_executionlog
    ↓ → CopyFromLake.etoro_Hedge_ExecutionLog
    ↓ ─────────────────────────────────────────────────────────
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
BI_DB_dbo.BI_DB_VarCommission ← BI_DB ETL
Dealing_dbo.Dealing_DailyZeroPnL_Stocks ← Dealing ETL
    ↓
SP_HedgeCost(@Date) — multi-source aggregation + HC computation
    ↓
Dealing_dbo.Dealing_HedgeCost
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` parameter | |
| InstrumentID | DWH_dbo.Dim_Position / CopyFromLake.etoro_Hedge_ExecutionLog | InstrumentID | passthrough | GROUP BY key | |
| Name | DWH_dbo.Dim_Instrument | Name | passthrough | Direct: Dim_Instrument.Name | |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | ETL-computed | `CASE WHEN HS IN (9,102,112,125,126) THEN 'Real' ELSE 'CFD' END` | String (not int) |
| Clients_Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal, IsBuy | ETL-computed | `SUM((IsBuy×2-1) × AmountInUnitsDecimal)` for opens+closes | Net long/short flow |
| AvgRateClientsNoSpread | DWH_dbo.Dim_Position | InitForexRate/EndForexRate, FullCommissionByUnits | ETL-computed | `(NetUnits × AvgRate - FullCommission) / NetUnits` | Back-calculated rate ex-commission |
| VolumeMarket | DWH_dbo.Dim_Position | Volume | passthrough | `SUM(Volume)` | USD volume |
| LP_Executed_Units | CopyFromLake.etoro_Hedge_ExecutionLog | Units, IsBuy | ETL-computed | `SUM(Units × (IsBuy×2-1)) WHERE Success=1` | LP net units |
| LP_Avg_Rate | CopyFromLake.etoro_Hedge_ExecutionLog | Units, ExecutionRate, IsBuy | ETL-computed | `SUM(Units×ExecutionRate) / SUM(Units×(IsBuy×2-1))` | Weighted avg LP rate |
| LP_Volume | CopyFromLake.etoro_Hedge_ExecutionLog | Units, ExecutionRate | ETL-computed | `SUM(Units × ExecutionRate)` | LP USD volume |
| HC | DWH_dbo.Fact_CurrencyPriceWithSplit, multiple | AskSpreaded + rates | ETL-computed | `AskSpreaded×Clients_Units - (Clients_Units×AvgRate - FullCommission) - (AskSpreaded×LP_Units - LP_Units×LP_AvgRate)` | Hedge Cost KPI |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |
| HedgeServerID | DWH_dbo.Dim_Position / CopyFromLake.etoro_Hedge_ExecutionLog | HedgeServerID | passthrough | GROUP BY key | |
| FullCommission | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | RealizedCommission | rename | `SUM(RealizedCommission)` | Zero-PnL commission |
| VariableSpread | BI_DB_dbo.BI_DB_VarCommission | VarCommission | passthrough | Direct: BI_DB_VarCommission.VarCommission | Variable spread |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 9 |
| **Rename** | 1 |
| **Total** | 14 |
