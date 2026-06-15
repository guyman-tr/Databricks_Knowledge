# Column Lineage: main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks` |
| **Object Type** | `EXTERNAL` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\bi_output_dealing_manipulation_report_real_stocks.py` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\bi_output_dealing_manipulation_report_real_stocks.json` (rows: 17, mismatches: 11) |
| **Parse warning** | `DataFrame write — AST walk not implemented in v1; rely on system.access.column_lineage` |
| **Primary upstream** | `n/a` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 2 | `KPI` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 3 | `InstrumentID` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 4 | `InstrumentDisplayName` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 5 | `InstrumentType` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 6 | `Regulation` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 7 | `RN` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 8 | `Volume` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 9 | `Units` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 10 | `Last30DaysAvgVolume` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 11 | `ExchangeUnitsVolume` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 12 | `MA_10Days` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 13 | `MaxToMinChange` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 14 | `UpdateDate` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 15 | `etr_y` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 16 | `etr_ym` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |
| 17 | `etr_ymd` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1340 |

## Cross-check vs system.access.column_lineage

- Total target columns: **17**
- OK: **6**, WARN: **0**, ERROR: **11**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `InstrumentID` | — | `main.dwh.dim_position.instrumentid` | ERROR |
| `InstrumentDisplayName` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumentdisplayname` | ERROR |
| `InstrumentType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttype` | ERROR |
| `Regulation` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation.name` | ERROR |
| `RN` | — | `main.dwh.dim_position.closedateid`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.volume`, `main.dwh.dim_position.volumeonclose`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation.name`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.etr_ymd`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.fundamentalssets_fundamentals_value`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.metadataid` | ERROR |
| `Volume` | — | `main.bi_dealing_stg.tmp_instrumentmetadata_snapshot.exchangeid`, `main.dwh.dim_position.closedateid`, `main.dwh.dim_position.closeoccurred`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.openoccurred`, `main.dwh.dim_position.volume`, `main.dwh.dim_position.volumeonclose` | ERROR |
| `Units` | — | `main.bi_dealing_stg.tmp_instrumentmetadata_snapshot.exchangeid`, `main.dwh.dim_position.amountinunitsdecimal`, `main.dwh.dim_position.closedateid`, `main.dwh.dim_position.closeoccurred`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.openoccurred` | ERROR |
| `Last30DaysAvgVolume` | — | `main.dwh.dim_position.closedateid`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.volume`, `main.dwh.dim_position.volumeonclose` | ERROR |
| `ExchangeUnitsVolume` | — | `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.fundamentalssets_fundamentals_value`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.metadataid` | ERROR |
| `MA_10Days` | — | `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.etr_ymd`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.fundamentalssets_fundamentals_value`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.instrument_id`, `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm.metadataid` | ERROR |
| `MaxToMinChange` | — | `main.dealing.candles_get_spreaded_price_candle60min_splitted.bidmax`, `main.dealing.candles_get_spreaded_price_candle60min_splitted.bidmin` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **17**
