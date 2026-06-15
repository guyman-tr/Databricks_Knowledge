# Column Lineage: main.etoro_kpi.ddr_aum_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_aum_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_aum_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_aum_v.json` (rows: 52, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md` |
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum   ←── primary upstream
  + main.bi_output.bi_output_vg_date   (JOIN)
        │
        ▼
main.etoro_kpi.ddr_aum_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to STRING — CAST(aum.RealCID AS STRING) AS RealCID |
| 2 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateID |
| 3 | `RealizedEquityTradingPlatform` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `RealizedEquityTP` | `rename` | (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) | aum.RealizedEquityTP AS RealizedEquityTradingPlatform |
| 4 | `TotalPositionPNL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalPositionPNL` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.TotalPositionPNL |
| 5 | `TotalInvestedAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalInvestedAmount` | `passthrough` | (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) | aum.TotalInvestedAmount |
| 6 | `EquityTradingPlatform` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalEquityTP` | `rename` | (Tier 2 — SP_DDR_Fact_AUM) | aum.TotalEquityTP AS EquityTradingPlatform |
| 7 | `CashInCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CashInCopy` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorCash) | aum.CashInCopy |
| 8 | `InvestedAmountCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `InvestedAmountCopy` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.InvestedAmountCopy |
| 9 | `EquityCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `EquityCopy` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.EquityCopy |
| 10 | `EquityStocksManual` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `EquityStocksManual` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.EquityStocksManual |
| 11 | `InvestedAmountStocksManual` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `InvestedAmountStocksManual` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.InvestedAmountStocksManual |
| 12 | `InvestedAmountCryptoManual` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `InvestedAmountCryptoManual` | `passthrough` | (Tier 2 — DWH_dbo.V_Liabilities) | aum.InvestedAmountCryptoManual |
| 13 | `BalanceTradingPlatfrom` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CreditTP` | `rename` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) | aum.CreditTP AS BalanceTradingPlatfrom |
| 14 | `BalanceIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `IBANBalance` | `rename` | (Tier 2 — SP_DDR_Fact_AUM) | aum.IBANBalance AS BalanceIBAN |
| 15 | `RealizedEquityGlobal` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `RealizedEquityGlobal` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.RealizedEquityGlobal |
| 16 | `EquityGlobal` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `EquityGlobal` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.EquityGlobal |
| 17 | `CreditGlobal` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CreditGlobal` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.CreditGlobal |
| 18 | `OptionsTotalEquity` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `OptionsTotalEquity` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.OptionsTotalEquity |
| 19 | `WeekNumberYear` | `main.bi_output.bi_output_vg_date` | `WeekNumberYear` | `join_enriched` | (Tier 1 — DDL) | dd.WeekNumberYear |
| 20 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 21 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 22 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 23 | `IsLastDayWeek` | `main.bi_output.bi_output_vg_date` | `IsLastDayWeek` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayWeek |
| 24 | `IsLastDayMonth` | `main.bi_output.bi_output_vg_date` | `IsLastDayMonth` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayMonth |
| 25 | `IsLastDayQuarter` | `main.bi_output.bi_output_vg_date` | `IsLastDayQuarter` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayQuarter |
| 26 | `IsLastDayYear` | `main.bi_output.bi_output_vg_date` | `IsLastDayYear` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayYear |
| 27 | `SnapshotDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `Date` | `rename` | (Tier 2 — SP_DDR_Fact_AUM) | aum.`Date` AS SnapshotDate |
| 28 | `TotalLiabilityTP` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalLiabilityTP` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.TotalLiabilityTP |
| 29 | `InProcessCashout` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `InProcessCashout` | `passthrough` | (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) | aum.InProcessCashout |
| 30 | `NOP` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `NOP` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.NOP |
| 31 | `NOPCrypto` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `NOPCrypto` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.NOPCrypto |
| 32 | `NOPCryptoCFD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `NOPCryptoCFD` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.NOPCryptoCFD |
| 33 | `NOPStocks` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `NOPStocks` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.NOPStocks |
| 34 | `NOPStocksCFD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `NOPStocksCFD` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.NOPStocksCFD |
| 35 | `TotalRealCryptoLoan` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalRealCryptoLoan` | `passthrough` | (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) | aum.TotalRealCryptoLoan |
| 36 | `Bonus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `Bonus` | `passthrough` | (Tier 2 — SP_Client_Balance_New) | aum.Bonus |
| 37 | `CopyInvestedAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CopyInvestedAmount` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorPositionsAmount) | aum.CopyInvestedAmount |
| 38 | `CopyStockOrders` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CopyStockOrders` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockOrders) | aum.CopyStockOrders |
| 39 | `CopyPositionPnL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CopyPositionPnL` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.CopyPositionPnL) | aum.CopyPositionPnL |
| 40 | `StockInvestedAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `StockInvestedAmount` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockPositionAmount) | aum.StockInvestedAmount |
| 41 | `StockOrders` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `StockOrders` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockOrders) | aum.StockOrders |
| 42 | `StocksPositionPnL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `StocksPositionPnL` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.StocksPositionPnL) | aum.StocksPositionPnL |
| 43 | `MirrorStockInvestedAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `MirrorStockInvestedAmount` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockPositionAmount) | aum.MirrorStockInvestedAmount |
| 44 | `MirrorStocksPositionPnL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `MirrorStocksPositionPnL` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL) | aum.MirrorStocksPositionPnL |
| 45 | `CryptoManualPositionPnL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CryptoManualPositionPnL` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL) | aum.CryptoManualPositionPnL |
| 46 | `EquityCryptoManual` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `EquityCryptoManual` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.EquityCryptoManual |
| 47 | `TotalRealCrypto` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalRealCrypto` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealCrypto) | aum.TotalRealCrypto |
| 48 | `TotalRealStocks` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalRealStocks` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealStocks) | aum.TotalRealStocks |
| 49 | `CreditTP` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `CreditTP` | `passthrough` | (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) | aum.CreditTP AS CreditTP |
| 50 | `ActualNWA` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `ActualNWA` | `passthrough` | (Tier 2 — DWH_dbo.V_Liabilities) | aum.ActualNWA |
| 51 | `TotalLiabilityGlobal` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `TotalLiabilityGlobal` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.TotalLiabilityGlobal |
| 52 | `UpdateDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `UpdateDate` | `passthrough` | (Tier 2 — SP_DDR_Fact_AUM) | aum.UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **52**
- OK: **52**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **9**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON aum.DateID = dd.DateID
