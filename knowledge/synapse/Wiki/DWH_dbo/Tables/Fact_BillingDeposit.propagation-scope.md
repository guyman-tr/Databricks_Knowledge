# Propagation Scope Report: gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit

**Generated**: 2026-03-16 12:40 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| Columns with descriptions | 139 |
| Discovery methods | synapse_dependency, name_pattern |
| Discovered at | 2026-03-16T12:40:07.885762+00:00 |

## Downstream Objects

**Total**: 22 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|
| `main.bi_output.vg_fact_billingdeposit_for_genie` | VIEW | 1 | name_pattern | 135 | 0 | 135 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | TABLE | 2 | synapse_dependency | 4 | 0 | 4 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | TABLE | 2 | synapse_dependency | 9 | 0 | 9 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | TABLE | 2 | synapse_dependency | 9 | 0 | 9 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard` | TABLE | 2 | synapse_dependency | 9 | 0 | 9 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | TABLE | 2 | synapse_dependency | 91 | 0 | 91 |
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |

## Blacklisted Columns (Excluded)

10 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 289 |
| Identical column matches | 289 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 1 |

- **Batch 1**: 22 objects, 289 statements — `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard`, `gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification`, `vg_fact_billingdeposit_for_genie`
