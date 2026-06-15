# Column Lineage: main.etoro_kpi.ddr_revenue_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_revenue_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_revenue_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_revenue_v.json` (rows: 30, mismatches: 3) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md` |
| `main.bi_output.bi_output_customer_ddr_revenue_metrics` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_ddr_revenue_metrics.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions   ←── primary upstream
  + main.bi_output.bi_output_vg_date   (JOIN)
  + main.bi_output.bi_ouput_v_dim_instrumenttype   (JOIN)
  + main.bi_output.bi_output_customer_ddr_revenue_metrics   (JOIN)
        │
        ▼
main.etoro_kpi.ddr_revenue_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `Date` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | rga.Date AS `Date` |
| 3 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 4 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 5 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 6 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to STRING — CAST(rga.RealCID AS STRING) AS RealCID |
| 7 | `ActionTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `ActionTypeID` | `passthrough` | (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) | rga.ActionTypeID |
| 8 | `ActionType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `ActionType` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | rga.ActionType |
| 9 | `InstrumentTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `InstrumentTypeID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | rga.InstrumentTypeID |
| 10 | `InstrumentType` | `main.bi_output.bi_ouput_v_dim_instrumenttype` | `InstrumentType` | `join_enriched` | (Tier 2 — from `main.general.bronze_etoro_dictionary_currencytype`) | ins.InstrumentType |
| 11 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsSettled` | `passthrough` | (Tier 5 — Expert Review) | rga.IsSettled |
| 12 | `IsCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsCopy` | `passthrough` | (Tier 2 — Fact_CustomerAction.MirrorID logic via Function_Revenue_*) | rga.IsCopy |
| 13 | `Metric` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `Metric` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | rga.Metric |
| 14 | `CountAsActiveTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `CountAsActiveTrade` | `passthrough` | (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) | rga.CountAsActiveTrade |
| 15 | `IncludedInTotalRevenue` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IncludedInTotalRevenue` | `passthrough` | (Tier 1 — UC sample) | rga.IncludedInTotalRevenue |
| 16 | `RevenueMetricCategory` | `main.bi_output.bi_output_customer_ddr_revenue_metrics` | `RevenueMetricCategory` | `join_enriched` | — | rmtr.RevenueMetricCategory |
| 17 | `RevenueMetricCategoryID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `RevenueMetricCategoryID` | `passthrough` | (Tier 1 — UC sample) | rga.RevenueMetricCategoryID |
| 18 | `IsBuy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsBuy` | `passthrough` | (Tier 1 — Trade.PositionTbl) | rga.IsBuy |
| 19 | `IsLeveraged` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsLeveraged` | `passthrough` | (Tier 2 — Function_Revenue_FullCommissions / AdminFee lineage) | rga.IsLeveraged |
| 20 | `IsFuture` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsFuture` | `passthrough` | (Tier 2 — Dim_Instrument / Function_Revenue_TVF) | rga.IsFuture |
| 21 | `IsCopyFund` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsCopyFund` | `passthrough` | (Tier 2 — BI_DB_CopyFund_Positions) | rga.IsCopyFund |
| 22 | `IsOpenedFromIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsOpenedFromIBAN` | `passthrough` | (Tier 2 — External_bi_output_finance_bi_db_positions_opened_from_iban_parquet) | rga.IsOpenedFromIBAN |
| 23 | `IsClosedToIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsClosedToIBAN` | `passthrough` | (Tier 2 — External_bi_output_finance_bi_db_positions_closed_to_iban_parquet) | rga.IsClosedToIBAN |
| 24 | `IsRecurring` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsRecurring` | `passthrough` | (Tier 2 — External_bi_db_recurringinvestment_positions_parquet) | rga.IsRecurring |
| 25 | `IsAirDrop` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsAirDrop` | `passthrough` | (Tier 2 — Function_Revenue_FullCommissions / Function_Revenue_Commissions) | rga.IsAirDrop |
| 26 | `IsSQF` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsSQF` | `passthrough` | (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused") | rga.IsSQF |
| 27 | `IsMarginTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsMarginTrade` | `passthrough` | (Tier 2 — Function_Revenue_* / SP_DDR_Fact_Revenue_Generating_Actions) | rga.IsMarginTrade |
| 28 | `IsC2P` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `IsC2P` | `passthrough` | (Tier 2 — BI_DB_dbo.V_C2P_Positions) | rga.IsC2P |
| 29 | `CountTransactions` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `—` | `aggregate` | — | SUM(rga.CountTransactions) AS CountTransactions |
| 30 | `RevenueAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `—` | `aggregate` | — | SUM(rga.Amount) AS RevenueAmount |

## Cross-check vs system.access.column_lineage

- Total target columns: **30**
- OK: **27**, WARN: **1**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IncludedInTotalRevenue` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.includedintotalrevenue` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.includedintotalrevenue`, `main.bi_output.bi_output_customer_ddr_revenue_metrics.includedintotalrevenue` | WARN |
| `CountTransactions` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.counttransactions` | ERROR |
| `RevenueAmount` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.amount` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **8**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON rga.DateID = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_ouput_v_dim_instrumenttype AS ins ON rga.InstrumentTypeID = ins.InstrumentTypeID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_customer_ddr_revenue_metrics AS rmtr ON rga.Metric = rmtr.Metric
