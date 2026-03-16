# Propagation Scope Report: dim_position

**Generated**: 2026-03-16 12:32 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.dwh.dim_position` |
| Columns with descriptions | 133 |
| Discovery methods | synapse_dependency, name_pattern |
| Discovered at | 2026-03-16T12:32:15.694857+00:00 |

## Downstream Objects

**Total**: 63 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|
| `main.api_delta.v_dwh_dim_position` | VIEW | 1 | name_pattern | 26 | 0 | 26 |
| `main.compliance_stg.rnd_output_dwh_dim_position_lc` | TABLE | 1 | name_pattern | 135 | 0 | 135 |
| `main.data_rooms.vw_dim_position` | VIEW | 1 | name_pattern | 106 | 0 | 106 |
| `main.dealing.rnd_output_dealing_bestexecution_dim_position` | TABLE | 1 | name_pattern | 32 | 0 | 32 |
| `main.delta_api.v_dwh_dim_position` | VIEW | 1 | name_pattern | 25 | 0 | 25 |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` | TABLE | 1 | name_pattern | 1 | 0 | 1 |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog` | TABLE | 1 | name_pattern | 5 | 0 | 5 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts` | TABLE | 2 | synapse_dependency | 5 | 0 | 5 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition` | TABLE | 2 | synapse_dependency | 7 | 0 | 7 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | TABLE | 2 | synapse_dependency | 4 | 0 | 4 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | TABLE | 2 | synapse_dependency | 9 | 0 | 9 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl` | TABLE | 2 | synapse_dependency | 26 | 0 | 26 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends` | TABLE | 2 | synapse_dependency | 5 | 0 | 5 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss` | TABLE | 2 | synapse_dependency | 11 | 0 | 11 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee` | TABLE | 2 | synapse_dependency | 10 | 0 | 10 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment` | TABLE | 2 | synapse_dependency | 10 | 0 | 10 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | TABLE | 2 | synapse_dependency | 32 | 0 | 32 |
| `main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk` | TABLE | 2 | synapse_dependency | 4 | 0 | 4 |
| `main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report` | TABLE | 2 | synapse_dependency | 17 | 0 | 17 |

## Blacklisted Columns (Excluded)

10 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 575 |
| Identical column matches | 575 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 3 |

- **Batch 1**: 30 objects, 130 statements — `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level`, `gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata`, `gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new`, `gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl`, `gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata`, `gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual`, `gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro`, `gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition`, `gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`, `gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon`, `gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`, `gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly`, `gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata`
- **Batch 2**: 30 objects, 333 statements — `gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon`, `gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown`, `gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks`, `gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends`, `gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`, `gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`, `gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid`, `gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients`, `gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk`, `gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions`, `gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding`, `gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures`, `v_dwh_dim_position`, `v_dwh_dim_position`, `rnd_output_dwh_dim_position_lc`, `rnd_output_dealing_bestexecution_dim_position`
- **Batch 3**: 3 objects, 112 statements — `vw_dim_position`, `gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`, `gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog`
