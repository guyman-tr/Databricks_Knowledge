# ADF Pipeline POC Proof — DWH_Daily_Process_-_Entry_Point

## Candidate selection proof
- Candidate source: `tools/migration_autoloop/runtime/candidate_not_in_jobs.csv`
- Selected pipeline: `DWH_Daily_Process_-_Entry_Point` (unmatched to Databricks jobs)

## Snapshot readiness check
- Latest `daily_snapshot` table alter: `2026-06-19T07:12:05.652Z`
- Sample table: `fiktivo_dbo_tblaff_tier2members`
- Snapshot age hours: `3.24`

## Relevant items resolved
| Migration table | Gold table | Procedure | Date param |
|---|---|---|---|
| `dwh_daily_process.migration_tables.dim_customer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `sp_dim_customer` | `False` |
| `dwh_daily_process.migration_tables.dim_historysplitratio` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio` | `sp_dim_historysplitratio_dl_to_synapse` | `False` |
| `dwh_daily_process.migration_tables.dim_mirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `sp_dim_mirror_dl_to_synapse` | `True` |
| `dwh_daily_process.migration_tables.fact_cashout_state` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state` | `sp_fact_cashout_state` | `True` |
| `dwh_daily_process.migration_tables.fact_currencypricewithsplit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | `sp_fact_currencypricewithsplit_dl_to_synapse` | `True` |
| `dwh_daily_process.migration_tables.fact_deposit_state` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state` | `sp_fact_deposit_state` | `True` |

## Orchestration execution
| Procedure | Status |
|---|---|
| `sp_dim_customer` | `ok` |
| `sp_dim_historysplitratio_dl_to_synapse` | `ok` |
| `sp_dim_mirror_dl_to_synapse` | `ok` |
| `sp_fact_cashout_state` | `ok` |
| `sp_fact_currencypricewithsplit_dl_to_synapse` | `ok` |
| `sp_fact_deposit_state` | `ok` |

## Full QA parity (migration vs gold)
| Migration table | Gold table | migration_rows | gold_rows | only_in_migration | only_in_gold | parity_pass |
|---|---:|---:|---:|---:|---:|---|
| `dwh_daily_process.migration_tables.dim_customer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | 48116472 | 48135887 | 48116471 | 48135886 | `False` |
| `dwh_daily_process.migration_tables.dim_historysplitratio` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio` | 16650 | 16650 | 16650 | 16650 | `False` |
| `dwh_daily_process.migration_tables.dim_mirror` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | 11371074 | 11372901 | 698868 | 700695 | `False` |
| `dwh_daily_process.migration_tables.fact_cashout_state` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state` | 11895162 | 11612082 | 283080 | 0 | `False` |
| `dwh_daily_process.migration_tables.fact_currencypricewithsplit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | 18739917 | 18771939 | 8147391 | 8179413 | `False` |
| `dwh_daily_process.migration_tables.fact_deposit_state` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state` | 21514083 | 21188267 | 325816 | 0 | `False` |

## Verdict
- Full QA parity pass: `False`
