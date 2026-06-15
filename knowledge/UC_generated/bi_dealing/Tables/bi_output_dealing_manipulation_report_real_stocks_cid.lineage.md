# Column Lineage: main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid` |
| **Object Type** | `EXTERNAL` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\bi_output_dealing_manipulation_report_real_stocks_cid.py` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\bi_output_dealing_manipulation_report_real_stocks_cid.json` (rows: 21, mismatches: 16) |
| **Parse warning** | `DataFrame write — AST walk not implemented in v1; rely on system.access.column_lineage` |
| **Primary upstream** | `n/a` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 2 | `CID` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 3 | `UserName` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 4 | `Country` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 5 | `Manager` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 6 | `Regulation` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 7 | `Club` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 8 | `InstrumentID` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 9 | `InstrumentDisplayName` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 10 | `InstrumentType` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 11 | `NumberOfTrades` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 12 | `AllTrades` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 13 | `AvgDailyOpen` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 14 | `Volume` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 15 | `Units` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 16 | `PercentOfAvg30Days` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 17 | `PercentOfTotalTrades` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 18 | `UpdateDate` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 19 | `etr_y` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 20 | `etr_ym` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |
| 21 | `etr_ymd` | `—` | `—` | `unknown` | — | DataFrame write (kind=df_save) at notebook L1355 |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **5**, WARN: **0**, ERROR: **16**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `CID` | — | `main.dwh.dim_position.cid` | ERROR |
| `UserName` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.username` | ERROR |
| `Country` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country.name` | ERROR |
| `Manager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `Regulation` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation.name` | ERROR |
| `Club` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel.name` | ERROR |
| `InstrumentID` | — | `main.dwh.dim_position.instrumentid` | ERROR |
| `InstrumentDisplayName` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumentdisplayname` | ERROR |
| `InstrumentType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttype` | ERROR |
| `NumberOfTrades` | — | `main.dwh.dim_position.ispartialclosechild`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.positionid` | ERROR |
| `AllTrades` | — | `main.dwh.dim_position.ispartialclosechild`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.positionid` | ERROR |
| `AvgDailyOpen` | — | `main.dwh.dim_position.positionid` | ERROR |
| `Volume` | — | `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.volume` | ERROR |
| `Units` | — | `main.dwh.dim_position.amountinunitsdecimal`, `main.dwh.dim_position.opendateid` | ERROR |
| `PercentOfAvg30Days` | — | `main.dwh.dim_position.ispartialclosechild`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.positionid` | ERROR |
| `PercentOfTotalTrades` | — | `main.dwh.dim_position.ispartialclosechild`, `main.dwh.dim_position.opendateid`, `main.dwh.dim_position.positionid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **21**
