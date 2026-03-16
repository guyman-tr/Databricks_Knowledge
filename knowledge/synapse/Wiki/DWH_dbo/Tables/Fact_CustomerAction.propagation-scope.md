# Propagation Scope Report: gold_sql_dp_prod_we_dwh_dbo_fact_customeraction

**Generated**: 2026-03-16 12:44 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| Columns with descriptions | 74 |
| Discovery methods | synapse_dependency, name_pattern |
| Discovered at | 2026-03-16T12:43:54.610588+00:00 |

## Downstream Objects

**Total**: 62 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|
| `main.bi_output_stg.v_semantic_fact_customeraction` | VIEW | 1 | name_pattern | 70 | 0 | 70 |
| `main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned` | TABLE | 1 | name_pattern | 64 | 0 | 64 |
| `main.data_rooms.vw_fact_customeraction` | VIEW | 1 | name_pattern | 37 | 0 | 37 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts` | TABLE | 2 | synapse_dependency | 7 | 0 | 7 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` | TABLE | 2 | synapse_dependency | 9 | 0 | 9 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level` | TABLE | 2 | synapse_dependency | 4 | 0 | 4 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | TABLE | 2 | synapse_dependency | 4 | 0 | 4 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | TABLE | 2 | synapse_dependency | 7 | 0 | 7 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | TABLE | 2 | synapse_dependency | 17 | 0 | 17 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends` | TABLE | 2 | synapse_dependency | 5 | 0 | 5 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients` | TABLE | 2 | synapse_dependency | 5 | 0 | 5 |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction` | TABLE | 2 | synapse_dependency | 24 | 0 | 24 |
| `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |

## Blacklisted Columns (Excluded)

10 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 366 |
| Identical column matches | 366 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 3 |

- **Batch 1**: 30 objects, 76 statements — `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level`, `gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`, `gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis`, `gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual`, `gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly`, `gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`, `gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard`
- **Batch 2**: 30 objects, 189 statements — `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown`, `gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade`, `gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail`, `gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`, `gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca`, `gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification`, `gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients`, `gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment`, `gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level`, `gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips`, `gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`, `v_semantic_fact_customeraction`
- **Batch 3**: 2 objects, 101 statements — `vw_fact_customeraction`, `rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned`
