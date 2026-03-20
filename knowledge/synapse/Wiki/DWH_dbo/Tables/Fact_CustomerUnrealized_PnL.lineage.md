# Fact_CustomerUnrealized_PnL — Production Lineage

## Lineage Classification

| Property | Value |
|----------|-------|
| **Lineage Type** | DWH-Computed (multi-source aggregation) |
| **Single Production Source** | None — aggregated from 8+ staging/external tables |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl` |
| **Lake Path** | `Gold/sql_dp_prod_we/DWH_dbo/Fact_CustomerUnrealized_PnL/` |
| **Copy Strategy** | Append |

## Source Chain

```
Production Databases                    Staging (DWH_staging)                      Ext Tables (DWH_dbo)               Target
─────────────────────                   ─────────────────────                      ────────────────────               ──────
PriceLog.History.SplitRatio          → etoro_History_SplitRatio               → Ext_FCUPNL_History_SplitRatio     ─┐
etoro.History.BackOfficeCustomer     → etoro_History_BackOfficeCustomer       → Ext_FCUPNL_BackOfficeCustomer     ─┤
etoro.Trade.GetInstrument            → etoro_Trade_GetInstrument             → Ext_FCUPNL_Dictionary_Instrument  ─┤
etoro.History.Mirror                 → etoro_History_Mirror                  → Ext_FCUPNL_History_Mirror         ─┼→ SP_Fact_CustomerUnrealized_PnL → Fact_CustomerUnrealized_PnL
etoro.History.ClosePositionEndOfDay  → etoro_History_ClosePositionEndOfDay   → Ext_FCUPNL_History_Position       ─┤                                    + Fact_CustomerUnrealized_PnL_UserAPI
etoro.Trade.OpenPositionEndOfDay     → etoro_Trade_OpenPositionEndOfDay      → Ext_FCUPNL_Trade_Position         ─┤
etoro.History.PositionChangeLog      → etoro_History_PositionChangeLog       → Ext_FCUPNL_PositionChangeLog      ─┤
PriceLog.Candles.CurrencyPriceMax... → PriceLog_Candles_CurrencyPrice...    → Ext_FCUPNL_CurrencyPriceMaxDate.. ─┤
                                                                                                                  │
DWH_dbo.Dim_Instrument (IsFuture)  ──────────────────────────────────────────────────────────────────────────────┤
DWH_dbo.Dim_Instrument_Correlation ──────────────────────────────────────────────────────────────────────────────┤
DWH_dbo.Fact_SnapshotEquity + V_M2M_Date_DateRange ─────────────────────────────────────────────────────────────┘
```

## Column Lineage Summary

All 57 columns (excluding CID, DateModified, UpdateDate) are DWH-computed aggregations. No columns pass through directly from a single production source. Key computation patterns:

| Column Group | Computation | Source Position Fields |
|-------------|-------------|----------------------|
| PnL columns (PositionPnL, *PnL*) | SUM(PnLInDollars) filtered by asset class/ownership/settlement | PnLInDollars from staging |
| NOP columns | SUM(directional USD value) | AmountInUnitsDecimal × Rate × EndConversionRate |
| Notional columns | SUM(ABS(directional USD value)) | Same as NOP but absolute |
| Commission columns | SUM(Commission/FullCommission/CommissionByUnits) filtered | Commission fields from staging |
| StandardDeviation | √(Σ weight_a × weight_b × covariance) | Dim_Instrument_Correlation + Fact_SnapshotEquity |
| PositionPnL_old | SUM(CalculatedNetProfit) — V0 formula | Computed in #UnrealizedPnL temp table |

## Lost/Added Columns vs Production

Not applicable — this table has no single production source equivalent. It is a DWH-native computation that aggregates position-level data into customer-level daily PnL snapshots.
