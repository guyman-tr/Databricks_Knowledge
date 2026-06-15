# Usage ↔ Skills Trigger Cross-Reference Report

- Generated: `2026-05-25T15:53:25.306497+00:00`
- Lookback: `7` days
- Client applications: `Databricks SQL Genie Space, Databricks SQL Editor, Databricks SQL MCP`
- Queries pulled: `15037`
- Distinct users: `263`
- Distinct Genie spaces: `40`
- Skills loaded: `51` (10 hubs, 41 sub-skills)
- Min query count for promotion: `5`

**Total gaps: 6531** (A=4867, B=1256, C=370, D=38)

## Class A

**Class A — Hub trigger gap**: Sub-skill owns a heavily-used table, but its hub has no trigger matching the user vocabulary. **Action**: promote phrase to hub triggers.

| Phrase / Table | Queries | Owning skill | Hub | Action |
|---|---:|---|---|---|
| `ftd_funnel_v` | 1211 | position-state-and-grain | domain-trading | PROMOTE phrase 'ftd_funnel_v' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `firsttimedeposit_date` | 830 | customer-action-audit-trail | domain-customer-and-identity | PROMOTE phrase 'firsttimedeposit_date' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `firsttimedeposit_date` | 830 | position-state-and-grain | domain-trading | PROMOTE phrase 'firsttimedeposit_date' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `registration_date` | 766 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'registration_date' to hub 'domain-customer-and-identity' triggers (used on 3 of its owned tables) |
| `ddr_revenue_v` | 526 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'ddr_revenue_v' to hub 'domain-customer-and-identity' triggers (used on 5 of its owned tables) |
| `revenueamount` | 456 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'revenueamount' to hub 'domain-customer-and-identity' triggers (used on 4 of its owned tables) |
| `calendaryearmonth` | 362 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'calendaryearmonth' to hub 'domain-customer-and-identity' triggers (used on 6 of its owned tables) |
| `ftd_count` | 355 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'ftd_count' to hub 'domain-customer-and-identity' triggers (used on 4 of its owned tables) |
| `ftd_count` | 355 | trading-revenue-and-fees | domain-revenue-and-fees | PROMOTE phrase 'ftd_count' to hub 'domain-revenue-and-fees' triggers (used on 1 of its owned tables) |
| `ftd_count` | 355 | hedge-cost-recon | domain-trading | PROMOTE phrase 'ftd_count' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `caseid` | 297 | crm-cases-csat-and-churn | domain-customer-and-identity | PROMOTE phrase 'caseid' to hub 'domain-customer-and-identity' triggers (used on 2 of its owned tables) |
| `caseid` | 297 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'caseid' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `caseid` | 297 | position-state-and-grain | domain-trading | PROMOTE phrase 'caseid' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `isactivetrade` | 284 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'isactivetrade' to hub 'domain-customer-and-identity' triggers (used on 2 of its owned tables) |
| `ddr_mimo_v` | 281 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'ddr_mimo_v' to hub 'domain-customer-and-identity' triggers (used on 6 of its owned tables) |
| `ddr_mimo_v` | 281 | trading-revenue-and-fees | domain-revenue-and-fees | PROMOTE phrase 'ddr_mimo_v' to hub 'domain-revenue-and-fees' triggers (used on 1 of its owned tables) |
| `ddr_mimo_v` | 281 | hedge-cost-recon | domain-trading | PROMOTE phrase 'ddr_mimo_v' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `customer_snapshot_v` | 280 | finance-recon-and-balances | domain-payments | PROMOTE phrase 'customer_snapshot_v' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `customer_snapshot_v` | 280 | instruments-and-asset-classes | domain-trading | PROMOTE phrase 'customer_snapshot_v' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `isexcludeuser` | 272 | customer-action-audit-trail | domain-customer-and-identity | PROMOTE phrase 'isexcludeuser' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `isexcludeuser` | 272 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'isexcludeuser' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `isexcludeuser` | 272 | position-state-and-grain | domain-trading | PROMOTE phrase 'isexcludeuser' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `ispartialclosechild` | 261 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'ispartialclosechild' to hub 'domain-customer-and-identity' triggers (used on 6 of its owned tables) |
| `ispartialclosechild` | 261 | mimo-panel-and-ddr | domain-payments | PROMOTE phrase 'ispartialclosechild' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `ispartialclosechild` | 261 | instruments-and-asset-classes | domain-trading | PROMOTE phrase 'ispartialclosechild' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `clubtier` | 255 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'clubtier' to hub 'domain-customer-and-identity' triggers (used on 6 of its owned tables) |
| `positions_for_compliance_v` | 249 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'positions_for_compliance_v' to hub 'domain-customer-and-identity' triggers (used on 8 of its owned tables) |
| `isdeleted` | 248 | emoney-accounts-and-cards | domain-payments | PROMOTE phrase 'isdeleted' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `date_spine` | 245 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'date_spine' to hub 'domain-customer-and-identity' triggers (used on 4 of its owned tables) |
| `mixpanel` | 237 | customer-models-and-segmentation | domain-customer-and-identity | PROMOTE phrase 'mixpanel' to hub 'domain-customer-and-identity' triggers (used on 2 of its owned tables) |
| `mixpanel` | 237 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'mixpanel' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `mixpanel` | 237 | trading-revenue-and-fees | domain-revenue-and-fees | PROMOTE phrase 'mixpanel' to hub 'domain-revenue-and-fees' triggers (used on 1 of its owned tables) |
| `mixpanel` | 237 | hedge-cost-recon | domain-trading | PROMOTE phrase 'mixpanel' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `origin` | 224 | crm-cases-csat-and-churn | domain-customer-and-identity | PROMOTE phrase 'origin' to hub 'domain-customer-and-identity' triggers (used on 2 of its owned tables) |
| `caseownertitle` | 199 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'caseownertitle' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `mp_event_name` | 195 | identity-jurisdiction-and-regulation | domain-customer-and-identity | PROMOTE phrase 'mp_event_name' to hub 'domain-customer-and-identity' triggers (used on 2 of its owned tables) |
| `crm_case_v` | 193 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'crm_case_v' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `schemaevolutionmode` | 180 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'schemaevolutionmode' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `infercolumntypes` | 180 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'infercolumntypes' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `mergeschema` | 180 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'mergeschema' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `ignoreleadingwhitespace` | 175 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'ignoreleadingwhitespace' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `ignoretrailingwhitespace` | 175 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'ignoretrailingwhitespace' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `__databricks_internal_catalog_genie_files_5142916747090026` | 175 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase '__databricks_internal_catalog_genie_files_5142916747090026' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `silver_crm_case` | 171 | customer-master-record | domain-customer-and-identity | PROMOTE phrase 'silver_crm_case' to hub 'domain-customer-and-identity' triggers (used on 1 of its owned tables) |
| `silver_crm_user` | 168 | emoney-accounts-and-cards | domain-payments | PROMOTE phrase 'silver_crm_user' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `daily_volume` | 159 | instruments-and-asset-classes | domain-trading | PROMOTE phrase 'daily_volume' to hub 'domain-trading' triggers (used on 1 of its owned tables) |
| `calendaryear` | 156 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'calendaryear' to hub 'domain-customer-and-identity' triggers (used on 5 of its owned tables) |
| `rolloverfee` | 153 | compliance-customer-snapshot-and-club | domain-customer-and-identity | PROMOTE phrase 'rolloverfee' to hub 'domain-customer-and-identity' triggers (used on 2 of its owned tables) |
| `rolloverfee` | 153 | deposits-and-withdrawals | domain-payments | PROMOTE phrase 'rolloverfee' to hub 'domain-payments' triggers (used on 1 of its owned tables) |
| `rolloverfee` | 153 | copy-trading-and-mirror | domain-trading | PROMOTE phrase 'rolloverfee' to hub 'domain-trading' triggers (used on 1 of its owned tables) |

_(4817 more rows in `report.csv`)_

## Class B

**Class B — Sub-skill trigger gap**: Skill body mentions the phrase, but the skill triggers don't. **Action**: add phrase to skill triggers.

| Phrase / Table | Queries | Owning skill | Hub | Action |
|---|---:|---|---|---|
| `ftd_funnel_v` | 1211 | customer-master-record |  | ADD phrase 'ftd_funnel_v' to skill 'customer-master-record' triggers (in body + queried on 1 owned tables) |
| `ddr_customer_dailystatus` | 779 | customer-master-record |  | ADD phrase 'ddr_customer_dailystatus' to skill 'customer-master-record' triggers (in body + queried on 1 owned tables) |
| `revenueamount` | 456 | compliance-customer-snapshot-and-club |  | ADD phrase 'revenueamount' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 4 owned tables) |
| `calendaryearmonth` | 362 | compliance-customer-snapshot-and-club |  | ADD phrase 'calendaryearmonth' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 6 owned tables) |
| `caseid` | 297 | crm-cases-csat-and-churn |  | ADD phrase 'caseid' to skill 'crm-cases-csat-and-churn' triggers (in body + queried on 2 owned tables) |
| `caseid` | 297 | customer-action-audit-trail |  | ADD phrase 'caseid' to skill 'customer-action-audit-trail' triggers (in body + queried on 1 owned tables) |
| `caseid` | 297 | domain-customer-and-identity |  | ADD phrase 'caseid' to skill 'domain-customer-and-identity' triggers (in body + queried on 4 owned tables) |
| `customer_snapshot_v` | 280 | recurring-deposit-to-trade |  | ADD phrase 'customer_snapshot_v' to skill 'recurring-deposit-to-trade' triggers (in body + queried on 1 owned tables) |
| `isexcludeuser` | 272 | domain-customer-and-identity |  | ADD phrase 'isexcludeuser' to skill 'domain-customer-and-identity' triggers (in body + queried on 2 owned tables) |
| `isexcludeuser` | 272 | domain-payments |  | ADD phrase 'isexcludeuser' to skill 'domain-payments' triggers (in body + queried on 1 owned tables) |
| `ispartialclosechild` | 261 | compliance-customer-snapshot-and-club |  | ADD phrase 'ispartialclosechild' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 6 owned tables) |
| `clubtier` | 255 | compliance-customer-snapshot-and-club |  | ADD phrase 'clubtier' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 6 owned tables) |
| `clubtier` | 255 | customer-master-record |  | ADD phrase 'clubtier' to skill 'customer-master-record' triggers (in body + queried on 3 owned tables) |
| `clubtier` | 255 | domain-customer-and-identity |  | ADD phrase 'clubtier' to skill 'domain-customer-and-identity' triggers (in body + queried on 2 owned tables) |
| `positions_for_compliance_v` | 249 | domain-customer-and-identity |  | ADD phrase 'positions_for_compliance_v' to skill 'domain-customer-and-identity' triggers (in body + queried on 1 owned tables) |
| `origin` | 224 | uc-naming-conventions |  | ADD phrase 'origin' to skill 'uc-naming-conventions' triggers (in body + queried on 1 owned tables) |
| `origin` | 224 | crm-cases-csat-and-churn |  | ADD phrase 'origin' to skill 'crm-cases-csat-and-churn' triggers (in body + queried on 2 owned tables) |
| `origin` | 224 | identity-jurisdiction-and-regulation |  | ADD phrase 'origin' to skill 'identity-jurisdiction-and-regulation' triggers (in body + queried on 1 owned tables) |
| `origin` | 224 | domain-customer-and-identity |  | ADD phrase 'origin' to skill 'domain-customer-and-identity' triggers (in body + queried on 3 owned tables) |
| `caseownertitle` | 199 | crm-cases-csat-and-churn |  | ADD phrase 'caseownertitle' to skill 'crm-cases-csat-and-churn' triggers (in body + queried on 1 owned tables) |
| `calendaryear` | 156 | compliance-customer-snapshot-and-club |  | ADD phrase 'calendaryear' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 5 owned tables) |
| `rolloverfee` | 153 | fees-misc-dormant-options-interest |  | ADD phrase 'rolloverfee' to skill 'fees-misc-dormant-options-interest' triggers (in body + queried on 1 owned tables) |
| `rolloverfee` | 153 | trading-volumes |  | ADD phrase 'rolloverfee' to skill 'trading-volumes' triggers (in body + queried on 1 owned tables) |
| `casenumber` | 146 | crm-cases-csat-and-churn |  | ADD phrase 'casenumber' to skill 'crm-cases-csat-and-churn' triggers (in body + queried on 2 owned tables) |
| `identity` | 132 | compliance-customer-snapshot-and-club |  | ADD phrase 'identity' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 1 owned tables) |
| `identity` | 132 | instruments-and-asset-classes |  | ADD phrase 'identity' to skill 'instruments-and-asset-classes' triggers (in body + queried on 1 owned tables) |
| `ownerid` | 129 | crm-cases-csat-and-churn |  | ADD phrase 'ownerid' to skill 'crm-cases-csat-and-churn' triggers (in body + queried on 2 owned tables) |
| `metrics` | 126 | customer-master-record |  | ADD phrase 'metrics' to skill 'customer-master-record' triggers (in body + queried on 2 owned tables) |
| `metrics` | 126 | mimo-panel-and-ddr |  | ADD phrase 'metrics' to skill 'mimo-panel-and-ddr' triggers (in body + queried on 1 owned tables) |
| `metrics` | 126 | domain-payments |  | ADD phrase 'metrics' to skill 'domain-payments' triggers (in body + queried on 1 owned tables) |
| `calendarquarter` | 124 | compliance-customer-snapshot-and-club |  | ADD phrase 'calendarquarter' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 5 owned tables) |
| `netprofit` | 117 | compliance-customer-snapshot-and-club |  | ADD phrase 'netprofit' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 3 owned tables) |
| `netprofit` | 117 | customer-action-audit-trail |  | ADD phrase 'netprofit' to skill 'customer-action-audit-trail' triggers (in body + queried on 2 owned tables) |
| `netprofit` | 117 | domain-revenue-and-fees |  | ADD phrase 'netprofit' to skill 'domain-revenue-and-fees' triggers (in body + queried on 1 owned tables) |
| `netprofit` | 117 | trading-revenue-and-fees |  | ADD phrase 'netprofit' to skill 'trading-revenue-and-fees' triggers (in body + queried on 1 owned tables) |
| `netprofit` | 117 | position-state-and-grain |  | ADD phrase 'netprofit' to skill 'position-state-and-grain' triggers (in body + queried on 3 owned tables) |
| `netprofit` | 117 | domain-trading |  | ADD phrase 'netprofit' to skill 'domain-trading' triggers (in body + queried on 1 owned tables) |
| `sequence` | 116 | recurring-deposit-to-trade |  | ADD phrase 'sequence' to skill 'recurring-deposit-to-trade' triggers (in body + queried on 2 owned tables) |
| `sequence` | 116 | position-state-and-grain |  | ADD phrase 'sequence' to skill 'position-state-and-grain' triggers (in body + queried on 1 owned tables) |
| `closeddate` | 114 | crm-cases-csat-and-churn |  | ADD phrase 'closeddate' to skill 'crm-cases-csat-and-churn' triggers (in body + queried on 1 owned tables) |
| `bi_output_dealing_bestexecution_report` | 105 | best-execution |  | ADD phrase 'bi_output_dealing_bestexecution_report' to skill 'best-execution' triggers (in body + queried on 1 owned tables) |
| `success` | 102 | best-execution |  | ADD phrase 'success' to skill 'best-execution' triggers (in body + queried on 1 owned tables) |
| `success` | 102 | dealing-investigation-and-execution |  | ADD phrase 'success' to skill 'dealing-investigation-and-execution' triggers (in body + queried on 1 owned tables) |
| `yearmonth` | 101 | compliance-customer-snapshot-and-club |  | ADD phrase 'yearmonth' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 3 owned tables) |
| `symbolfull` | 99 | instruments |  | ADD phrase 'symbolfull' to skill 'instruments' triggers (in body + queried on 1 owned tables) |
| `reportmonthtext` | 98 | aml-risk-scoring |  | ADD phrase 'reportmonthtext' to skill 'aml-risk-scoring' triggers (in body + queried on 7 owned tables) |
| `totalrevenue` | 89 | compliance-customer-snapshot-and-club |  | ADD phrase 'totalrevenue' to skill 'compliance-customer-snapshot-and-club' triggers (in body + queried on 3 owned tables) |
| `totalrevenue` | 89 | hedge-cost-recon |  | ADD phrase 'totalrevenue' to skill 'hedge-cost-recon' triggers (in body + queried on 1 owned tables) |
| `variant` | 85 | identity-jurisdiction-and-regulation |  | ADD phrase 'variant' to skill 'identity-jurisdiction-and-regulation' triggers (in body + queried on 1 owned tables) |
| `variant` | 85 | instruments-and-asset-classes |  | ADD phrase 'variant' to skill 'instruments-and-asset-classes' triggers (in body + queried on 1 owned tables) |

_(1206 more rows in `report.csv`)_

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

_(320 more rows in `report.csv`)_

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
| `01f1118c0f38118a8b9361c02b3f7409` Voice Of The Customer | 181 | 7 | 5 | 2 | 0 | 5 | main.bi_output.bi_output_customer_customer_support_case, main.de_output.de_output_voice_of_the_customer_messagingsession, main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked, main.de_output.de_output_voice_of_the_customer_comments, main.de_output.de_output_voice_of_the_customer_feeds |
| `01f125cd42af12d4bcc267b42f87ab21` Customer AML Compliance Data | 173 | 7 | 5 | 5 | 3 | 1 | main.pii_data_stg.gold_de_aml_snapshot_customer_enriched_v, main.etoro_kpi.ddr_mimo_v, main.etoro_kpi.ddr_aum_v, main.etoro_kpi.positions_for_compliance_v, main.etoro_kpi.ddr_customer_dailystatus |
| `01f1001f16b117bb948db14cb26f8928` PROD - etoro_trading_ai | 160 | 7 | 4 | 3 | 0 | 4 | main.etoro_kpi.vg_dealing_clicks_openclose_breakdown, main.data_rooms.vw_bi_output_dealing_newinstruments, main.trading.bronze_etoro_dictionary_tradinginstrumentgroups, main.trading.bronze_etoro_trade_instrumentgroups |
| `01f0c38d864d10be9b493dfec1f100eb` Breaches Investigation Bot | 145 | 20 | 6 | 16 | 2 | 4 | main.regtech.gold_exposure_business_undertaking, main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked, main.dwh.dim_position, main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts, main.bi_compliance.bi_compliance_bui_tables_compliance_bui_illegal_trades_new |
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
| `01f1489250d313b29c551948016772bf`  | 21 | 0 | 7 | 0 | 7 | 5 | main.bi_output.bi_output_customer_customer_support_agent_user, main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity, main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions, main.wallet.bronze_walletdb_wallet_walletaddresses, main.bi_output.bi_output_customer_customer_facing_agent_engagement |
| `01f1220ba7721b93881c732cfc2579eb` Customer Support Case Analytics | 19 | 5 | 2 | 4 | 1 | 1 | main.etoro_kpi.crm_case_v, main.etoro_kpi_stg.crm_user_v |
| `01f1071b575c17e28e9fc956ffdb57ea`  | 19 | 0 | 1 | 0 | 1 | 1 | main.money_stg.deposit_stats_mv |
| `01f107201f5e18109cc73243ee2b53a5` OPS - Electronic Verification | 17 | 2 | 3 | 0 | 1 | 2 | main.bi_output_stg.bi_output_operations_electronic_verification_cohort, main.bi_output_stg.bi_output_operations_ops_customer_info, main.etoro_kpi.ftd_funnel_v |
