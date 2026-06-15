# Column Lineage: main.etoro_kpi.ddr_pnl_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_pnl_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_pnl_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_pnl_v.json` (rows: 19, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_PnL.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl   ←── primary upstream
  + main.bi_output.bi_output_vg_date   (JOIN)
  + main.bi_output.bi_ouput_v_dim_instrumenttype   (JOIN)
        │
        ▼
main.etoro_kpi.ddr_pnl_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `Date` | `passthrough` | (Tier 2 — SP_DDR_Fact_PnL) | pnl.`Date` AS `Date` |
| 3 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 4 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 5 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 6 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to STRING — CAST(pnl.RealCID AS STRING) AS RealCID |
| 7 | `InstrumentTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `InstrumentTypeID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | pnl.InstrumentTypeID |
| 8 | `InstrumentType` | `main.bi_output.bi_ouput_v_dim_instrumenttype` | `InstrumentType` | `join_enriched` | (Tier 2 — from `main.general.bronze_etoro_dictionary_currencytype`) | ins.InstrumentType |
| 9 | `IsCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsCopy` | `passthrough` | (Tier 2 — SP_DDR_Fact_PnL) | pnl.IsCopy |
| 10 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsSettled` | `passthrough` | (Tier 5 — Expert Review) | pnl.IsSettled |
| 11 | `IsFuture` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsFuture` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | pnl.IsFuture |
| 12 | `IsLeveraged` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsLeveraged` | `passthrough` | (Tier 2 — Trade.PositionTbl) | pnl.IsLeveraged |
| 13 | `IsBuy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsBuy` | `passthrough` | (Tier 1 — Trade.PositionTbl) | pnl.IsBuy |
| 14 | `IsCopyFund` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsCopyFund` | `passthrough` | (Tier 2 — Function_PnL_Single_Day) | pnl.IsCopyFund |
| 15 | `IsSQF` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `IsSQF` | `passthrough` | (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused") | pnl.IsSQF |
| 16 | `UnrealizedPnLChange` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `UnrealizedPnLChange` | `passthrough` | (Tier 2 — BI_DB_PositionPnL) | pnl.UnrealizedPnLChange |
| 17 | `NetProfit` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `NetProfit` | `passthrough` | (Tier 2 — Trade.PositionTbl) | pnl.NetProfit |
| 18 | `CountPositions` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `CountPositions` | `passthrough` | (Tier 2 — SP_DDR_Fact_PnL) | pnl.CountPositions |
| 19 | `UpdateDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `UpdateDate` | `passthrough` | (Tier 2 — SP_DDR_Fact_PnL) | pnl.UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **19**
- OK: **19**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **5**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON pnl.DateID = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_ouput_v_dim_instrumenttype AS ins ON pnl.InstrumentTypeID = ins.InstrumentTypeID
