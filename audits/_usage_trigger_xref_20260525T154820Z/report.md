# Usage ↔ Skills Trigger Cross-Reference Report

- Generated: `2026-05-25T15:48:56.569659+00:00`
- Lookback: `7` days
- Client applications: `Databricks SQL Genie Space, Databricks SQL Editor, Databricks SQL MCP`
- Queries pulled: `15037`
- Distinct users: `263`
- Distinct Genie spaces: `40`
- Skills loaded: `51` (10 hubs, 41 sub-skills)
- Min query count for promotion: `3`

**Total gaps: 12793** (A=1353, B=10920, C=482, D=38)

## Class A

**Class A — Hub trigger gap**: Sub-skill owns a heavily-used table, but its hub has no trigger matching the user vocabulary. **Action**: promote phrase to hub triggers.

| Phrase / Table | Queries | Owning skill | Hub | Action |
|---|---:|---|---|---|
| `dateid` | 2256 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'dateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `dateid` | 2256 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'dateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `dateid` | 2256 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'dateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `dateid` | 2256 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'dateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `dateid` | 2256 | pricing-and-currency-history | domain-trading | PROMOTE phrase 'dateid' from sub-skill triggers to hub 'domain-trading' triggers |
| `fromdateid` | 1833 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'fromdateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `fromdateid` | 1833 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'fromdateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `fromdateid` | 1833 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'fromdateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `fromdateid` | 1833 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'fromdateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `todateid` | 1803 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'todateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `todateid` | 1803 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'todateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `todateid` | 1803 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'todateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `todateid` | 1803 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'todateid' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `gcid` | 1495 | emoney-accounts-and-cards | domain-payments | PROMOTE phrase 'gcid' from sub-skill triggers to hub 'domain-payments' triggers |
| `gcid` | 1495 | emoney-accounts-and-cards | domain-payments | PROMOTE phrase 'gcid' from sub-skill triggers to hub 'domain-payments' triggers |
| `gcid` | 1495 | emoney-accounts-and-cards | domain-payments | PROMOTE phrase 'gcid' from sub-skill triggers to hub 'domain-payments' triggers |
| `country` | 1403 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-payments' triggers |
| `country` | 1403 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-payments' triggers |
| `country` | 1403 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-payments' triggers |
| `country` | 1403 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-payments' triggers |
| `country` | 1403 | oltp-customer-static-and-breaches | domain-customer-and-identity | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `country` | 1403 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-payments' triggers |
| `country` | 1403 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'country' from sub-skill triggers to hub 'domain-payments' triggers |
| `region` | 1308 | oltp-customer-static-and-breaches | domain-customer-and-identity | PROMOTE phrase 'region' from sub-skill triggers to hub 'domain-customer-and-identity' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-payments' triggers |
| `name` | 1196 | fees-deposit-withdraw-fx | domain-revenue-and-fees | PROMOTE phrase 'name' from sub-skill triggers to hub 'domain-revenue-and-fees' triggers |
| `regulation` | 1081 | aml-risk-scoring | domain-compliance-and-aml | PROMOTE phrase 'regulation' from sub-skill triggers to hub 'domain-compliance-and-aml' triggers |
| `regulation` | 1081 | aml-risk-scoring | domain-compliance-and-aml | PROMOTE phrase 'regulation' from sub-skill triggers to hub 'domain-compliance-and-aml' triggers |
| `regulation` | 1081 | aml-risk-scoring | domain-compliance-and-aml | PROMOTE phrase 'regulation' from sub-skill triggers to hub 'domain-compliance-and-aml' triggers |
| `regulation` | 1081 | aml-risk-scoring | domain-compliance-and-aml | PROMOTE phrase 'regulation' from sub-skill triggers to hub 'domain-compliance-and-aml' triggers |
| `regulation` | 1081 | aml-risk-scoring | domain-compliance-and-aml | PROMOTE phrase 'regulation' from sub-skill triggers to hub 'domain-compliance-and-aml' triggers |
| `regulation` | 1081 | aml-risk-scoring | domain-compliance-and-aml | PROMOTE phrase 'regulation' from sub-skill triggers to hub 'domain-compliance-and-aml' triggers |

_(1303 more rows in `report.csv`)_

## Class B

**Class B — Sub-skill trigger gap**: Skill body mentions the phrase, but the skill triggers don't. **Action**: add phrase to skill triggers.

| Phrase / Table | Queries | Owning skill | Hub | Action |
|---|---:|---|---|---|
| `realcid` | 3127 | aml-alert-routing |  | ADD phrase 'realcid' to skill 'aml-alert-routing' triggers (already in body) |
| `realcid` | 3127 | aml-regtech-pipeline |  | ADD phrase 'realcid' to skill 'aml-regtech-pipeline' triggers (already in body) |
| `realcid` | 3127 | aml-risk-scoring |  | ADD phrase 'realcid' to skill 'aml-risk-scoring' triggers (already in body) |
| `realcid` | 3127 | domain-compliance-and-aml |  | ADD phrase 'realcid' to skill 'domain-compliance-and-aml' triggers (already in body) |
| `realcid` | 3127 | crypto-to-fiat |  | ADD phrase 'realcid' to skill 'crypto-to-fiat' triggers (already in body) |
| `realcid` | 3127 | compliance-customer-snapshot-and-club |  | ADD phrase 'realcid' to skill 'compliance-customer-snapshot-and-club' triggers (already in body) |
| `realcid` | 3127 | crm-cases-csat-and-churn |  | ADD phrase 'realcid' to skill 'crm-cases-csat-and-churn' triggers (already in body) |
| `realcid` | 3127 | customer-action-audit-trail |  | ADD phrase 'realcid' to skill 'customer-action-audit-trail' triggers (already in body) |
| `realcid` | 3127 | customer-models-and-segmentation |  | ADD phrase 'realcid' to skill 'customer-models-and-segmentation' triggers (already in body) |
| `realcid` | 3127 | identity-jurisdiction-and-regulation |  | ADD phrase 'realcid' to skill 'identity-jurisdiction-and-regulation' triggers (already in body) |
| `realcid` | 3127 | oltp-customer-static-and-breaches |  | ADD phrase 'realcid' to skill 'oltp-customer-static-and-breaches' triggers (already in body) |
| `realcid` | 3127 | crypto-wallet |  | ADD phrase 'realcid' to skill 'crypto-wallet' triggers (already in body) |
| `realcid` | 3127 | deposits-and-withdrawals |  | ADD phrase 'realcid' to skill 'deposits-and-withdrawals' triggers (already in body) |
| `realcid` | 3127 | emoney-accounts-and-cards |  | ADD phrase 'realcid' to skill 'emoney-accounts-and-cards' triggers (already in body) |
| `realcid` | 3127 | finance-recon-and-balances |  | ADD phrase 'realcid' to skill 'finance-recon-and-balances' triggers (already in body) |
| `realcid` | 3127 | mimo-panel-and-ddr |  | ADD phrase 'realcid' to skill 'mimo-panel-and-ddr' triggers (already in body) |
| `realcid` | 3127 | domain-payments |  | ADD phrase 'realcid' to skill 'domain-payments' triggers (already in body) |
| `realcid` | 3127 | fees-deposit-withdraw-fx |  | ADD phrase 'realcid' to skill 'fees-deposit-withdraw-fx' triggers (already in body) |
| `realcid` | 3127 | fees-misc-dormant-options-interest |  | ADD phrase 'realcid' to skill 'fees-misc-dormant-options-interest' triggers (already in body) |
| `realcid` | 3127 | domain-revenue-and-fees |  | ADD phrase 'realcid' to skill 'domain-revenue-and-fees' triggers (already in body) |
| `realcid` | 3127 | trading-revenue-and-fees |  | ADD phrase 'realcid' to skill 'trading-revenue-and-fees' triggers (already in body) |
| `realcid` | 3127 | portfolio-value-aum-pnl |  | ADD phrase 'realcid' to skill 'portfolio-value-aum-pnl' triggers (already in body) |
| `realcid` | 3127 | position-state-and-grain |  | ADD phrase 'realcid' to skill 'position-state-and-grain' triggers (already in body) |
| `realcid` | 3127 | domain-trading |  | ADD phrase 'realcid' to skill 'domain-trading' triggers (already in body) |
| `realcid` | 3127 | trading-volumes |  | ADD phrase 'realcid' to skill 'trading-volumes' triggers (already in body) |
| `realcid` | 3127 | mimo |  | ADD phrase 'realcid' to skill 'mimo' triggers (already in body) |
| `realcid` | 3127 | trading-volumes |  | ADD phrase 'realcid' to skill 'trading-volumes' triggers (already in body) |
| `realcid` | 3127 | valid-users-filter-contract |  | ADD phrase 'realcid' to skill 'valid-users-filter-contract' triggers (already in body) |
| `dateid` | 2256 | aml-risk-scoring |  | ADD phrase 'dateid' to skill 'aml-risk-scoring' triggers (already in body) |
| `dateid` | 2256 | crypto-to-fiat |  | ADD phrase 'dateid' to skill 'crypto-to-fiat' triggers (already in body) |
| `dateid` | 2256 | provider-reconciliation |  | ADD phrase 'dateid' to skill 'provider-reconciliation' triggers (already in body) |
| `dateid` | 2256 | recurring-deposit-to-trade |  | ADD phrase 'dateid' to skill 'recurring-deposit-to-trade' triggers (already in body) |
| `dateid` | 2256 | tribe-emoney-audit |  | ADD phrase 'dateid' to skill 'tribe-emoney-audit' triggers (already in body) |
| `dateid` | 2256 | compliance-customer-snapshot-and-club |  | ADD phrase 'dateid' to skill 'compliance-customer-snapshot-and-club' triggers (already in body) |
| `dateid` | 2256 | customer-action-audit-trail |  | ADD phrase 'dateid' to skill 'customer-action-audit-trail' triggers (already in body) |
| `dateid` | 2256 | customer-master-record |  | ADD phrase 'dateid' to skill 'customer-master-record' triggers (already in body) |
| `dateid` | 2256 | customer-models-and-segmentation |  | ADD phrase 'dateid' to skill 'customer-models-and-segmentation' triggers (already in body) |
| `dateid` | 2256 | oltp-customer-static-and-breaches |  | ADD phrase 'dateid' to skill 'oltp-customer-static-and-breaches' triggers (already in body) |
| `dateid` | 2256 | domain-customer-and-identity |  | ADD phrase 'dateid' to skill 'domain-customer-and-identity' triggers (already in body) |
| `dateid` | 2256 | deposits-and-withdrawals |  | ADD phrase 'dateid' to skill 'deposits-and-withdrawals' triggers (already in body) |
| `dateid` | 2256 | emoney-accounts-and-cards |  | ADD phrase 'dateid' to skill 'emoney-accounts-and-cards' triggers (already in body) |
| `dateid` | 2256 | finance-recon-and-balances |  | ADD phrase 'dateid' to skill 'finance-recon-and-balances' triggers (already in body) |
| `dateid` | 2256 | mimo-panel-and-ddr |  | ADD phrase 'dateid' to skill 'mimo-panel-and-ddr' triggers (already in body) |
| `dateid` | 2256 | domain-payments |  | ADD phrase 'dateid' to skill 'domain-payments' triggers (already in body) |
| `dateid` | 2256 | fees-deposit-withdraw-fx |  | ADD phrase 'dateid' to skill 'fees-deposit-withdraw-fx' triggers (already in body) |
| `dateid` | 2256 | fees-misc-dormant-options-interest |  | ADD phrase 'dateid' to skill 'fees-misc-dormant-options-interest' triggers (already in body) |
| `dateid` | 2256 | revenue-moneyfarm |  | ADD phrase 'dateid' to skill 'revenue-moneyfarm' triggers (already in body) |
| `dateid` | 2256 | revenue-options-platform |  | ADD phrase 'dateid' to skill 'revenue-options-platform' triggers (already in body) |
| `dateid` | 2256 | revenue-staking-and-share-lending |  | ADD phrase 'dateid' to skill 'revenue-staking-and-share-lending' triggers (already in body) |
| `dateid` | 2256 | domain-revenue-and-fees |  | ADD phrase 'dateid' to skill 'domain-revenue-and-fees' triggers (already in body) |

_(10870 more rows in `report.csv`)_

## Class C

**Class C — Coverage gap**: Table queried ≥ threshold times but is in no skill's `required_tables`. **Action**: document the table in the appropriate skill.

| Phrase / Table | Queries | Owning skill | Hub | Action |
|---|---:|---|---|---|
| `main.etoro_kpi.ddr_customer_snapshot_scd_v` | 1530 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.etoro_kpi.ddr_customer_dailystatus` | 776 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dwh.dim_position` | 493 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_output_stg.bi_output_operations_documentanalysis` | 278 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.config.monitoring_mcp_logs_mcp_gateway` | 231 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.etoro_kpi.crm_case_v` | 193 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.data_rooms.vw_cidfirstdates` | 191 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.trading.bronze_etoro_history_positionchangelog` | 183 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | 178 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.crm.silver_crm_user` | 168 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.crm.silver_crm_case` | 164 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_dealing_stg.tree3` | 162 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.mixpanel.silver` | 160 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | 137 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.etoro_kpi.vg_dealing_clicks_openclose_breakdown` | 137 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.regtech.gold_exposure_business_undertaking` | 132 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | 131 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_dealing_stg.tree1` | 120 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dealing.bronze_kafka_dealingstreaming_dealing_dollars_volume_anomalies_per_instrument` | 118 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_compliance.bi_compliance_bui_tables_compliance_bui_illegal_trades_enrichments` | 117 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.etoro_kpi.ddr_trading_volumes_and_amounts_v` | 104 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | 99 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` | 99 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_output.bi_output_customer_customer_support_case` | 96 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates` | 95 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | 92 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.product_analytics_stg.bi_output_product_analytics_abtoro_experiment_participants` | 92 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.pii_data.bronze_userapidb_customer_extendeduserfield` | 91 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.data_rooms.vw_dim_position` | 90 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.de_output.vw_bronze_public_api_operations` | 88 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_db.bronze_etoro_price_accountratesource` | 88 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_dealing_stg.tree0` | 88 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation` | 84 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | 84 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | 83 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_output.vg_promo_card_cashback` | 81 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.billing.bronze_etoro_backoffice_customerdocument` | 78 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.crm.silver_crm_surveytaker__c` | 78 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype` | 71 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | 70 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl` | 69 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_compliance_stg.bi_compliance_validation_tables_validation_update` | 69 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.general.bronze_etoro_customer_customer_masked` | 68 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.asset_universe.gold_masterinstruments` | 67 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.crm.silver_crm_survey__c` | 66 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.data_rooms.vw_dim_instrument` | 65 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients` | 65 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation` | 65 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.crm.silver_crm_messagingsession` | 64 |  |  | DOCUMENT — table queried but not in any skill's required_tables |
| `main.compliance.bronze_userapidb_dictionary_extendeduservaluetype` | 64 |  |  | DOCUMENT — table queried but not in any skill's required_tables |

_(432 more rows in `report.csv`)_

## Class D

**Class D — Genie-space mismatch**: A Genie space's registered tables diverge from actually-used tables. **Action**: realign space data_sources and/or skill documentation.

| Genie space | Queries | Registered | Used | Unused regs | Unregistered used | Used not documented | Top used tables |
|---|---:|---:|---:|---:|---:|---:|---|
| `01f13712cf8516878dbc9663f5f73eb7` eToro DDR - dor dev | 3135 | 7 | 12 | 2 | 7 | 6 | main.etoro_kpi.ddr_customer_snapshot_scd_v, main.etoro_kpi.ddr_customer_dailystatus, main.etoro_kpi.ddr_revenue_v, main.etoro_kpi.ddr_mimo_v, main.etoro_kpi.vg_customer_customer_first_dates |
| `01f1003cd92b1430826100f723a359d2` PROD - Registration to FTD | 866 | 1 | 2 | 0 | 1 | 1 | main.etoro_kpi.ftd_funnel_v, main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked |
| `01f137f76a75126fb15b03341732911f` PROD - Compliance Genie | 566 | 8 | 7 | 1 | 0 | 0 | main.etoro_kpi.customer_snapshot_v, main.etoro_kpi.positions_for_compliance_v, main.etoro_kpi.kyc_for_compliance_v, main.etoro_kpi.ddr_mimo_v, main.etoro_kpi.cfd_statusinfo_v |
| `01ee9e3a900a1db1b5db5f4f5e2fd95f` etoro_main | 393 | 4 | 5 | 0 | 1 | 3 | main.data_rooms.vw_cidfirstdates, main.data_rooms.vw_dim_position, main.data_rooms.vw_dim_instrument, main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked, main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities |
| `01f0f77496571e68a9f115149bcc48d9` OPS  - Documents & Verification | 313 | 2 | 4 | 0 | 2 | 3 | main.bi_output_stg.bi_output_operations_documentanalysis, main.etoro_kpi.ftd_funnel_v, main.bi_output_stg.bi_output_operations_ops_ai_doc_verification_checks, main.bi_db.information_schema |
| `01f0c51e5a4a1506bb34d4751918b4d2` eMoney Adoption & Trading | 305 | 7 | 7 | 3 | 3 | 6 | main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie, main.bi_output.vg_promo_card_cashback, main.bi_output.vg_emoneydimaccount_forgenie, main.bi_output.vg_emoneydimtransaction_forgenie, main.bi_output.vg_emoney_card_instance_summary |
| `01f14dd5bc5c18e3a9959219c3cae9ae`  | 303 | 0 | 8 | 0 | 8 | 7 | main.etoro_kpi.crm_case_v, main.crm.silver_crm_user, main.crm.silver_crm_case, main.crm.silver_crm_case_events__c, main.etoro_kpi.crm_csat_survey_per_case_v |
| `01f1118c0f38118a8b9361c02b3f7409` Voice Of The Customer | 181 | 7 | 5 | 2 | 0 | 5 | main.bi_output.bi_output_customer_customer_support_case, main.de_output.de_output_voice_of_the_customer_messagingsession, main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked, main.de_output.de_output_voice_of_the_customer_feeds, main.de_output.de_output_voice_of_the_customer_comments |
| `01f125cd42af12d4bcc267b42f87ab21` Customer AML Compliance Data | 173 | 7 | 5 | 5 | 3 | 1 | main.pii_data_stg.gold_de_aml_snapshot_customer_enriched_v, main.etoro_kpi.ddr_mimo_v, main.etoro_kpi.ddr_aum_v, main.etoro_kpi.positions_for_compliance_v, main.etoro_kpi.ddr_customer_dailystatus |
| `01f1001f16b117bb948db14cb26f8928` PROD - etoro_trading_ai | 160 | 7 | 4 | 3 | 0 | 4 | main.etoro_kpi.vg_dealing_clicks_openclose_breakdown, main.data_rooms.vw_bi_output_dealing_newinstruments, main.trading.bronze_etoro_dictionary_tradinginstrumentgroups, main.trading.bronze_etoro_trade_instrumentgroups |
| `01f0c38d864d10be9b493dfec1f100eb` Breaches Investigation Bot | 145 | 20 | 6 | 16 | 2 | 4 | main.regtech.gold_exposure_business_undertaking, main.dwh.dim_position, main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked, main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts, main.bi_compliance.bi_compliance_bui_tables_compliance_bui_illegal_trades_new |
| `01f14e992c7a13d8baad26551003f878`  | 138 | 0 | 3 | 0 | 3 | 2 | main.etoro_kpi.ddr_customer_dailystatus, main.etoro_kpi.ddr_customer_snapshot_scd_v, main.etoro_kpi.ddr_revenue_v |
| `01f1380bddbf1f39918a6ff73748f082` ABtoro Genie (AB Tests Results) | 125 | 3 | 8 | 0 | 5 | 7 | main.mixpanel.silver, main.product_analytics_stg.bi_output_product_analytics_abtoro_experiment_participants, main.dwh.dim_position, main.product_analytics_stg.bi_output_product_analytics_abtoro_storage_experiments_md, main.product_analytics_stg.bi_output_product_analytics_abtoro_experiment_user_segments_driving_significant_results_view |
| `01f10cbd30f11f78bb53d30de1b08437` Customer Segmentation | 123 | 2 | 4 | 0 | 2 | 2 | main.etoro_kpi.ftd_funnel_v, main.bi_db.bronze_marketperformance_airdrop_customer, main.etoro_kpi.customer_segments_v, main.data_rooms.vw_mixpanel_login_events |
| `01f1418befa310f0a03ec500a2bdb587` Marketing Campaigns Performance | 94 | 1 | 2 | 1 | 2 | 2 | main.etoro_kpi_stg.v_marketing_campaigns_social, main.etoro_kpi_stg.v_marketing_campaigns_google |
| `01f13403b01312c3b6e6e9f42de9a5c1` Test - AML CMP  | 81 | 3 | 2 | 1 | 0 | 0 | main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_cid_level, main.bi_compliance_stg.bi_compliance_cmp_tables_cmp_aml_risk_classification_aggregated_group_level |
| `01f14d19640c195694ad4324d2898818`  | 73 | 0 | 1 | 0 | 1 | 0 | main.etoro_kpi.ftd_funnel_v |
| `01f15837702d1918af14cf43cdea58ae`  | 54 | 0 | 4 | 0 | 4 | 3 | main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked, main.bi_compliance_stg.bi_compliance_validation_tables_validation_update, main.bi_compliance_stg.bi_compliance_validation_tables_fca_focus_cids, main.bi_compliance_stg.bi_compliance_validation_tables_fix_cid |
| `01eeaeed57b41c6ca0f4119606355809` etoro_trading | 53 | 7 | 6 | 1 | 0 | 5 | main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown, main.data_rooms.vw_bi_output_dealing_newinstruments, main.trading.bronze_etoro_trade_instrumentgroups, main.dealing.bi_output_dealing_dealingdashboard_cid, main.trading.bronze_etoro_dictionary_tradinginstrumentgroups |
| `01f15394627a1406bda7e1d8d1983929`  | 49 | 0 | 1 | 0 | 1 | 0 | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e |
| `01f14e91f3871ffba9f2a213665cf76b`  | 47 | 0 | 2 | 0 | 2 | 2 | main.etoro_kpi.v_raf, main.etoro_kpi.v_raf_config |
| `01f13c8fb28d1ea6a614c04b2176a96e` OPS - General Genie | 41 | 16 | 9 | 7 | 0 | 8 | main.bi_output_stg.bi_output_operations_ops_customer_info, main.bi_output_stg.bi_output_operations_ops_deposits, main.bi_output_stg.bi_output_operations_documentanalysis, main.bi_output_stg.bi_output_operations_risk_alert_management_tool, main.bi_output_stg.bi_output_operations_ops_kyc_answers |
| `01f0cf5a8c741eb09f1082f9f8736b82` eToro eMoney - MIMO | 39 | 5 | 4 | 4 | 3 | 4 | main.bi_output.vg_payments_mimo_allplatformddr_genienew, main.bi_output.vg_fullbincodelist, main.bi_output.vg_factbillingdeposit_transactionsandattributes, main.bi_output.vg_factbillingwithdraw_transactionsandattributes |
| `01f0f5e75c2112178fb9639f4212aba1` OPS - Registrations Funnel | 36 | 1 | 1 | 0 | 0 | 1 | main.bi_output_stg.bi_output_operations_registrationfunnel |
| `01f105b421e7187baa5e81595599f7f3` Feed Analytics Genie | 27 | 8 | 2 | 6 | 0 | 2 | main.mixpanel.silver, main.experience.bronze_event_hub_prod_event_streaming_we_streams_post |
| `01f152bcbeb0152b9121706bd11c699f`  | 24 | 0 | 3 | 0 | 3 | 2 | main.mixpanel.silver, main.dwh.dim_position, main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked |
| `01f1489250d313b29c551948016772bf`  | 21 | 0 | 7 | 0 | 7 | 5 | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions, main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser, main.wallet.bronze_walletdb_wallet_walletaddresses, main.bi_output.bi_output_customer_customer_support_agent_user, main.bi_output.bi_output_customer_customer_support_customer_engagement |
| `01f1220ba7721b93881c732cfc2579eb` Customer Support Case Analytics | 19 | 5 | 2 | 4 | 1 | 1 | main.etoro_kpi.crm_case_v, main.etoro_kpi_stg.crm_user_v |
| `01f1071b575c17e28e9fc956ffdb57ea`  | 19 | 0 | 1 | 0 | 1 | 1 | main.money_stg.deposit_stats_mv |
| `01f107201f5e18109cc73243ee2b53a5` OPS - Electronic Verification | 17 | 2 | 3 | 0 | 1 | 2 | main.bi_output_stg.bi_output_operations_electronic_verification_cohort, main.bi_output_stg.bi_output_operations_ops_customer_info, main.etoro_kpi.ftd_funnel_v |
