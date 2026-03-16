# Propagation Scope Report: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates

**Generated**: 2026-03-16 12:49 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates` |
| Columns with descriptions | 139 |
| Discovery methods | synapse_dependency, name_pattern |
| Discovered at | 2026-03-16T12:48:56.747649+00:00 |

## Downstream Objects

**Total**: 19 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | TABLE | 1 | name_pattern | 138 | 0 | 138 |
| `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` | VIEW | 1 | name_pattern | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | TABLE | 2 | synapse_dependency | 2 | 0 | 2 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata` | TABLE | 2 | synapse_dependency | 11 | 0 | 11 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly` | TABLE | 2 | synapse_dependency | 3 | 0 | 3 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel` | TABLE | 2 | synapse_dependency | 8 | 0 | 8 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual` | TABLE | 2 | synapse_dependency | 4 | 0 | 4 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport` | TABLE | 2 | synapse_dependency | 6 | 0 | 6 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | TABLE | 2 | synapse_dependency | 5 | 0 | 5 |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis` | TABLE | 2 | synapse_dependency | 10 | 0 | 10 |
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | TABLE | 2 | synapse_dependency | 9 | 0 | 9 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata` | TABLE | 2 | synapse_dependency | 5 | 0 | 5 |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv` | TABLE | 2 | synapse_dependency | 1 | 0 | 1 |

## Blacklisted Columns (Excluded)

10 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 233 |
| Identical column matches | 233 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 1 |

- **Batch 1**: 19 objects, 233 statements — `gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view`, `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`
