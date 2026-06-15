# Column Lineage: main.etoro_kpi.vg_ddr_revenue

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_ddr_revenue` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_ddr_revenue.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_ddr_revenue.json` (rows: 30, mismatches: 1) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\Dim_Revenue_Metrics.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics   (JOIN)
  + main.bi_output.bi_ouput_v_dim_instrumenttype   (JOIN)
        │
        ▼
main.etoro_kpi.vg_ddr_revenue   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `DateID` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.DateID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `Date` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.Date |
| 3 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | dfr.RealCID |
| 4 | `ActionTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `ActionTypeID` | `passthrough` | (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) | dfr.ActionTypeID |
| 5 | `ActionType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `ActionType` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.ActionType |
| 6 | `InstrumentTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `InstrumentTypeID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | dfr.InstrumentTypeID |
| 7 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsSettled` | `passthrough` | (Tier 5 — Expert Review) | dfr.IsSettled |
| 8 | `IsCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsCopy` | `passthrough` | (Tier 2 — Fact_CustomerAction.MirrorID logic via Function_Revenue_*) | dfr.IsCopy |
| 9 | `Metric` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `Metric` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.Metric |
| 10 | `Amount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `Amount` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.Amount |
| 11 | `CountTransactions` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `CountTransactions` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.CountTransactions |
| 12 | `IncludedInTotalRevenue` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IncludedInTotalRevenue` | `passthrough` | (Tier 1 — UC sample) | dfr.IncludedInTotalRevenue |
| 13 | `CountAsActiveTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `CountAsActiveTrade` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.CountAsActiveTrade |
| 14 | `UpdateDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `UpdateDate` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | dfr.UpdateDate |
| 15 | `IsBuy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsBuy` | `passthrough` | (Tier 1 — Trade.PositionTbl) | dfr.IsBuy |
| 16 | `IsLeveraged` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsLeveraged` | `passthrough` | (Tier 2 — Function_Revenue_FullCommissions / AdminFee lineage) | dfr.IsLeveraged |
| 17 | `IsFuture` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsFuture` | `passthrough` | (Tier 2 — Dim_Instrument / Function_Revenue_TVF) | dfr.IsFuture |
| 18 | `IsCopyFund` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsCopyFund` | `passthrough` | (Tier 2 — BI_DB_CopyFund_Positions) | dfr.IsCopyFund |
| 19 | `IsOpenedFromIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsOpenedFromIBAN` | `passthrough` | (Tier 2 — External_bi_output_finance_bi_db_positions_opened_from_iban_parquet) | dfr.IsOpenedFromIBAN |
| 20 | `IsClosedToIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsClosedToIBAN` | `passthrough` | (Tier 2 — External_bi_output_finance_bi_db_positions_closed_to_iban_parquet) | dfr.IsClosedToIBAN |
| 21 | `IsRecurring` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsRecurring` | `passthrough` | (Tier 2 — External_bi_db_recurringinvestment_positions_parquet) | dfr.IsRecurring |
| 22 | `IsAirDrop` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsAirDrop` | `passthrough` | (Tier 2 — Function_Revenue_FullCommissions / Function_Revenue_Commissions) | dfr.IsAirDrop |
| 23 | `IsSQF` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsSQF` | `passthrough` | (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused") | dfr.IsSQF |
| 24 | `RevenueMetricID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `RevenueMetricID` | `passthrough` | (Tier 1 — UC sample) | dfr.RevenueMetricID |
| 25 | `RevenueMetricCategoryID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `RevenueMetricCategoryID` | `passthrough` | (Tier 1 — UC sample) | dfr.RevenueMetricCategoryID |
| 26 | `IsMarginTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsMarginTrade` | `passthrough` | (Tier 2 — Function_Revenue_* / SP_DDR_Fact_Revenue_Generating_Actions) | dfr.IsMarginTrade |
| 27 | `IsC2P` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsC2P` | `passthrough` | (Tier 2 — BI_DB_dbo.V_C2P_Positions) | dfr.IsC2P |
| 28 | `RevenueMetricCategory` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` | `RevenueMetricCategory` | `join_enriched` | (Tier 1 — UC sample) | drm.RevenueMetricCategory |
| 29 | `InstrumentType` | `main.bi_output.bi_ouput_v_dim_instrumenttype` | `InstrumentType` | `join_enriched` | (Tier 2 — from `main.general.bronze_etoro_dictionary_currencytype`) | vit.InstrumentType |
| 30 | `IsICC` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions / main.bi_output.bi_ouput_v_dim_instrumenttype` | `—` | `case` | — | CASE WHEN dfr.IsFuture = 1 OR vit.InstrumentTypeID IN (1, 2, 4) THEN 1 ELSE 0 END AS IsICC |

## Cross-check vs system.access.column_lineage

- Total target columns: **30**
- OK: **29**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsICC` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.isfuture`, `main.bi_output.bi_ouput_v_dim_instrumenttype.instrumenttypeid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics AS drm ON dfr.RevenueMetricID = drm.RevenueMetricID
- `INNER JOIN` — JOIN main.bi_output.bi_ouput_v_dim_instrumenttype AS vit ON dfr.InstrumentTypeID = vit.InstrumentTypeID
