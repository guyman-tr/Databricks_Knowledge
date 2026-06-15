# Column Lineage: main.etoro_kpi.ddr_trading_volumes_and_amounts_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_trading_volumes_and_amounts_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_trading_volumes_and_amounts_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_trading_volumes_and_amounts_v.json` (rows: 31, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts   ←── primary upstream
  + main.bi_output.bi_output_vg_date   (JOIN)
  + main.bi_output.bi_ouput_v_dim_instrumenttype   (JOIN)
        │
        ▼
main.etoro_kpi.ddr_trading_volumes_and_amounts_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `Date` | `passthrough` | — | tva.`Date` AS `Date` |
| 3 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 4 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 5 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 6 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `RealCID` | `cast` | — | cast to STRING — CAST(tva.RealCID AS STRING) AS RealCID |
| 7 | `InstrumentTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `InstrumentTypeID` | `passthrough` | — | tva.InstrumentTypeID |
| 8 | `InstrumentType` | `main.bi_output.bi_ouput_v_dim_instrumenttype` | `InstrumentType` | `join_enriched` | (Tier 2 — from `main.general.bronze_etoro_dictionary_currencytype`) | ins.InstrumentType |
| 9 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsSettled` | `passthrough` | — | tva.IsSettled |
| 10 | `IsCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsCopy` | `passthrough` | — | tva.IsCopy |
| 11 | `IsBuy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsBuy` | `passthrough` | — | tva.IsBuy |
| 12 | `IsLeverage` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsLeverage` | `passthrough` | — | tva.IsLeverage |
| 13 | `IsFuture` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsFuture` | `passthrough` | — | tva.IsFuture |
| 14 | `IsCopyFund` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsCopyFund` | `passthrough` | — | tva.IsCopyFund |
| 15 | `IsOpenedFromIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsOpenedFromIBAN` | `passthrough` | — | tva.IsOpenedFromIBAN |
| 16 | `IsClosedToIBAN` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsClosedToIBAN` | `passthrough` | — | tva.IsClosedToIBAN |
| 17 | `IsRecurring` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsRecurring` | `passthrough` | — | tva.IsRecurring |
| 18 | `IsAirDrop` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsAirDrop` | `passthrough` | — | tva.IsAirDrop |
| 19 | `VolumeOpen` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `VolumeOpen` | `passthrough` | — | tva.VolumeOpen |
| 20 | `VolumeClose` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `VolumeClose` | `passthrough` | — | tva.VolumeClose |
| 21 | `InvestedAmountOpen` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `InvestedAmountOpen` | `passthrough` | — | tva.InvestedAmountOpen |
| 22 | `InvestedAmountClosed` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `InvestedAmountClosed` | `passthrough` | — | tva.InvestedAmountClosed |
| 23 | `TotalVolume` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `TotalVolume` | `passthrough` | — | tva.TotalVolume |
| 24 | `NetInvestedAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `NetInvestedAmount` | `passthrough` | — | tva.NetInvestedAmount |
| 25 | `CountOpenTransactions` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `CountOpenTransactions` | `passthrough` | — | tva.CountOpenTransactions |
| 26 | `CountCloseTransactions` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `CountCloseTransactions` | `passthrough` | — | tva.CountCloseTransactions |
| 27 | `CountTotalTransactions` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `CountTotalTransactions` | `passthrough` | — | tva.CountTotalTransactions |
| 28 | `UpdateDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `UpdateDate` | `passthrough` | — | tva.UpdateDate |
| 29 | `IsSQF` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsSQF` | `passthrough` | (Tier 5 — user expert correction; previously mis-described as “Sustainable & Quality-Focused”) | tva.IsSQF |
| 30 | `IsMarginTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsMarginTrade` | `passthrough` | — | tva.IsMarginTrade |
| 31 | `IsC2P` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `IsC2P` | `passthrough` | — | tva.IsC2P |

## Cross-check vs system.access.column_lineage

- Total target columns: **31**
- OK: **31**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **5**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON tva.DateID = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_ouput_v_dim_instrumenttype AS ins ON tva.InstrumentTypeID = ins.InstrumentTypeID
