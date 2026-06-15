---
schema: etoro_kpi
catalog: main
display_name: etoro_kpi — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-19T12:48:45Z"
lineage_lookback_days: 90
in_scope_count: 40
out_of_scope_count: 1
objects:
  - name: cfd_statusinfo_v
    full_name: main.etoro_kpi.cfd_statusinfo_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
    refs_source: view_definition (regex extract)
  - name: cidfirstdates_v
    full_name: main.etoro_kpi.cidfirstdates_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
      - main.general.bronze_etoro_dictionary_regulation
    refs_source: view_definition (regex extract)
  - name: crm_case_v
    full_name: main.etoro_kpi.crm_case_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.gold_crm_case_tiny
      - main.crm.gold_crm_web_chat_sessions
      - main.crm.gold_crm_bot_eligible_chats
      - main.crm.gold_crm_case_deescalation
      - main.bi_output.bi_output_vg_case_event
      - main.crm.silver_crm_case
    refs_source: view_definition (regex extract)
  - name: crm_csat_survey_per_case_v
    full_name: main.etoro_kpi.crm_csat_survey_per_case_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.silver_crm_csat_survey_entry__c
    refs_source: view_definition (regex extract)
  - name: crm_quality_assessment_per_case_v
    full_name: main.etoro_kpi.crm_quality_assessment_per_case_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.silver_crm_surveytaker__c
    refs_source: view_definition (regex extract)
  - name: crm_user_v
    full_name: main.etoro_kpi.crm_user_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.silver_crm_user
    refs_source: view_definition (regex extract)
  - name: customer_exclude_list
    full_name: main.etoro_kpi.customer_exclude_list
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_etoro_customer_customer_masked
    refs_source: view_definition (regex extract)
  - name: customer_segments_mail_v
    full_name: main.etoro_kpi.customer_segments_mail_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output.bi_output_marketing_sfmc_sfmc_report
      - main.mixpanel.login_events
    refs_source: view_definition (regex extract)
  - name: customer_segments_v
    full_name: main.etoro_kpi.customer_segments_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
      - bi_dealing.bi_output_dealing_cidage_data
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition
      - main.etoro_kpi.ddr_aum_v
    refs_source: view_definition (regex extract)
  - name: customer_snapshot_v
    full_name: main.etoro_kpi.customer_snapshot_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
    refs_source: view_definition (regex extract)
  - name: ddr_aum_v
    full_name: main.etoro_kpi.ddr_aum_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
      - main.bi_output.bi_output_vg_date
    refs_source: view_definition (regex extract)
  - name: ddr_customer_current_flags
    full_name: main.etoro_kpi.ddr_customer_current_flags
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
    refs_source: view_definition (regex extract)
  - name: ddr_customer_dailystatus
    full_name: main.etoro_kpi.ddr_customer_dailystatus
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
    refs_source: view_definition (regex extract)
  - name: ddr_customer_snapshot_scd_v
    full_name: main.etoro_kpi.ddr_customer_snapshot_scd_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
    refs_source: view_definition (regex extract)
  - name: ddr_mimo_v
    full_name: main.etoro_kpi.ddr_mimo_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
      - main.bi_output.bi_output_vg_date
    refs_source: view_definition (regex extract)
  - name: ddr_pnl_v
    full_name: main.etoro_kpi.ddr_pnl_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
      - main.bi_output.bi_output_vg_date
      - main.bi_output.bi_ouput_v_dim_instrumenttype
    refs_source: view_definition (regex extract)
  - name: ddr_revenue_v
    full_name: main.etoro_kpi.ddr_revenue_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
      - main.bi_output.bi_output_vg_date
      - main.bi_output.bi_ouput_v_dim_instrumenttype
      - main.bi_output.bi_output_customer_ddr_revenue_metrics
    refs_source: view_definition (regex extract)
  - name: ddr_trading_volumes_and_amounts_v
    full_name: main.etoro_kpi.ddr_trading_volumes_and_amounts_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
      - main.bi_output.bi_output_vg_date
      - main.bi_output.bi_ouput_v_dim_instrumenttype
    refs_source: view_definition (regex extract)
  - name: de_output_ftd_click
    full_name: main.etoro_kpi.de_output_ftd_click
    type: EXTERNAL
    writer:
      kind: JOB
      path: 348031231946635
      lineage_source: system.access.table_lineage
      lineage_event_count: 276
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 786294243361603
          workspace_id: 5263962954799003
          event_count: 9
          first_event_time: "2026-02-19T08:52:52.064000+00:00"
          last_event_time: "2026-02-19T12:04:52.279000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 7e054aab-6ac6-4c42-a395-91939d0516a5
          workspace_id: 5142916747090026
          event_count: 4
          first_event_time: "2026-04-06T12:08:10.730000+00:00"
          last_event_time: "2026-04-06T18:03:51.964000+00:00"
    in_scope: true
  - name: de_output_mixpanel_gcid_ftd_flow_steps
    full_name: main.etoro_kpi.de_output_mixpanel_gcid_ftd_flow_steps
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: ftd_click_v
    full_name: main.etoro_kpi.ftd_click_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi.de_output_ftd_click
    refs_source: view_definition (regex extract)
  - name: ftd_click_v_testing_dup_cancle
    full_name: main.etoro_kpi.ftd_click_v_testing_dup_cancle
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi.de_output_ftd_click
    refs_source: view_definition (regex extract)
  - name: ftd_funnel_kyc
    full_name: main.etoro_kpi.ftd_funnel_kyc
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.compliance.bronze_userapidb_kyc_customeranswers
    refs_source: view_definition (regex extract)
  - name: ftd_funnel_v
    full_name: main.etoro_kpi.ftd_funnel_v
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.general.bronze_etoro_customer_customer_masked
      - main.general.bronze_etoro_dictionary_platform
      - main.general.bronze_etoro_dictionary_country
      - bi_dealing.bi_output_dealing_cidage_data
      - main.general.bronze_etoro_dictionary_playerstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
      - main.etoro_kpi.ftd_funnel_kyc
      - main.etoro_kpi.customer_exclude_list
      - main.etoro_kpi.ftd_click_v
    refs_source: view_definition (regex extract)
  - name: ftd_funnel_v_dev
    full_name: main.etoro_kpi.ftd_funnel_v_dev
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.general.bronze_etoro_customer_customer_masked
      - main.general.bronze_etoro_dictionary_platform
      - main.general.bronze_etoro_dictionary_country
      - bi_dealing.bi_output_dealing_cidage_data
      - main.general.bronze_etoro_dictionary_playerstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
      - main.etoro_kpi.ftd_funnel_kyc
      - main.etoro_kpi.customer_exclude_list
    refs_source: view_definition (regex extract)
  - name: kyc_for_compliance_v
    full_name: main.etoro_kpi.kyc_for_compliance_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.compliance.bronze_userapidb_kyc_customeranswers
      - main.compliance.bronze_userapidb_history_customeranswers
      - compliance.bronze_userapidb_kyc_questions
      - compliance.bronze_userapidb_kyc_answers
      - main.general.bronze_etoro_customer_customer_masked
    refs_source: view_definition (regex extract)
  - name: positions_for_compliance_v
    full_name: main.etoro_kpi.positions_for_compliance_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
    refs_source: view_definition (regex extract)
  - name: v_ddr_non_revenue_actions
    full_name: main.etoro_kpi.v_ddr_non_revenue_actions
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
    refs_source: view_definition (regex extract)
  - name: v_raf
    full_name: main.etoro_kpi.v_raf
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.experience.bronze_rafcompensations_customer_raftrackingprocessed
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.general.bronze_etoro_dictionary_playerlevel
      - main.general.bronze_etoro_dictionary_gurustatus
      - main.general.bronze_etoro_dictionary_country
      - main.general.bronze_etoro_dictionary_regulation
      - main.bi_db.bronze_etoro_customer_customermoney
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities
    refs_source: view_definition (regex extract)
  - name: v_raf_config
    full_name: main.etoro_kpi.v_raf_config
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.experience.bronze_rafcompensations_config_viewconfig
      - main.general.bronze_etoro_dictionary_regulation
    refs_source: view_definition (regex extract)
  - name: v_spaceship_aum
    full_name: main.etoro_kpi.v_spaceship_aum
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.spaceship.bronze_spaceship_metabase_user_beta
      - main.spaceship.bronze_spaceship_metabase_super_user_balances
      - main.spaceship.spaceship_metabase_voyager_user_balances
      - main.spaceship.bronze_spaceship_metabase_nova_user_balances
      - main.bi_db.bronze_sub_accounts_accounts
      - main.spaceship.bronze_spaceship_metabase_contact
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    refs_source: view_definition (regex extract)
  - name: v_spaceship_fees
    full_name: main.etoro_kpi.v_spaceship_fees
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.spaceship.bronze_spaceship_metabase_user_beta
      - main.spaceship.bronze_spaceship_metabase_super_transactions
      - main.spaceship.bronze_spaceship_metabase_voyager_account_fees
      - main.spaceship.bronze_spaceship_metabase_voyager_management_fees
      - main.spaceship.spaceship_metabase_voyager_product_balances
      - main.spaceship.bronze_spaceship_metabase_nova_fees
      - main.spaceship.bronze_spaceship_metabase_nova_transactions
      - main.bi_db.bronze_sub_accounts_accounts
      - main.spaceship.bronze_spaceship_metabase_contact
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    refs_source: view_definition (regex extract)
  - name: v_spaceship_mimo
    full_name: main.etoro_kpi.v_spaceship_mimo
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi_prep.v_spaceship_mimo
    refs_source: view_definition (regex extract)
  - name: vg_crm_case
    full_name: main.etoro_kpi.vg_crm_case
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.gold_crm_case_tiny_for_genie
      - main.crm.gold_crm_web_chat_sessions
      - main.crm.gold_crm_bot_eligible_chats
      - main.crm.gold_crm_case_deescalation
      - main.bi_output.bi_output_vg_case_event
      - main.crm.silver_crm_case
    refs_source: view_definition (regex extract)
  - name: vg_customer_customer_first_dates
    full_name: main.etoro_kpi.vg_customer_customer_first_dates
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_db.bronze_moneybusdb_dictionary_accounttypes
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct
    refs_source: view_definition (regex extract)
  - name: vg_customer_daily_snapshot
    full_name: main.etoro_kpi.vg_customer_daily_snapshot
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
    refs_source: view_definition (regex extract)
  - name: vg_customer_monthly_snapshot
    full_name: main.etoro_kpi.vg_customer_monthly_snapshot
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
    refs_source: view_definition (regex extract)
  - name: vg_ddr_revenue
    full_name: main.etoro_kpi.vg_ddr_revenue
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
      - main.bi_output.bi_ouput_v_dim_instrumenttype
    refs_source: view_definition (regex extract)
  - name: vg_dealing_clicks_openclose_breakdown
    full_name: main.etoro_kpi.vg_dealing_clicks_openclose_breakdown
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
    refs_source: view_definition (regex extract)
  - name: vg_dealing_dealingdashboard_cid
    full_name: main.etoro_kpi.vg_dealing_dealingdashboard_cid
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dealing.bi_output_dealing_dealingdashboard_cid
    refs_source: view_definition (regex extract)
  - name: winback_daily_segments
    full_name: main.etoro_kpi.winback_daily_segments
    type: MANAGED
    writer:
      kind: NOTEBOOK
      path: 2168358810410994
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
    in_scope: true
---

# etoro_kpi — Schema Card

> UC-Pipeline scope sheet for `main.etoro_kpi`. **40 in-scope** / **1 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `cfd_statusinfo_v` | `VIEW` | `view_definition` | `view_definition` |
| `cidfirstdates_v` | `VIEW` | `view_definition` | `view_definition` |
| `crm_case_v` | `VIEW` | `view_definition` | `view_definition` |
| `crm_csat_survey_per_case_v` | `VIEW` | `view_definition` | `view_definition` |
| `crm_quality_assessment_per_case_v` | `VIEW` | `view_definition` | `view_definition` |
| `crm_user_v` | `VIEW` | `view_definition` | `view_definition` |
| `customer_exclude_list` | `VIEW` | `view_definition` | `view_definition` |
| `customer_segments_mail_v` | `VIEW` | `view_definition` | `view_definition` |
| `customer_segments_v` | `VIEW` | `view_definition` | `view_definition` |
| `customer_snapshot_v` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_aum_v` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_customer_current_flags` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_customer_dailystatus` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_customer_snapshot_scd_v` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_mimo_v` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_pnl_v` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_revenue_v` | `VIEW` | `view_definition` | `view_definition` |
| `ddr_trading_volumes_and_amounts_v` | `VIEW` | `view_definition` | `view_definition` |
| `de_output_ftd_click` | `EXTERNAL` | `JOB` | `348031231946635` |
| `ftd_click_v` | `VIEW` | `view_definition` | `view_definition` |
| `ftd_click_v_testing_dup_cancle` | `VIEW` | `view_definition` | `view_definition` |
| `ftd_funnel_kyc` | `VIEW` | `view_definition` | `view_definition` |
| `ftd_funnel_v` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `ftd_funnel_v_dev` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `kyc_for_compliance_v` | `VIEW` | `view_definition` | `view_definition` |
| `positions_for_compliance_v` | `VIEW` | `view_definition` | `view_definition` |
| `v_ddr_non_revenue_actions` | `VIEW` | `view_definition` | `view_definition` |
| `v_raf` | `VIEW` | `view_definition` | `view_definition` |
| `v_raf_config` | `VIEW` | `view_definition` | `view_definition` |
| `v_spaceship_aum` | `VIEW` | `view_definition` | `view_definition` |
| `v_spaceship_fees` | `VIEW` | `view_definition` | `view_definition` |
| `v_spaceship_mimo` | `VIEW` | `view_definition` | `view_definition` |
| `vg_crm_case` | `VIEW` | `view_definition` | `view_definition` |
| `vg_customer_customer_first_dates` | `VIEW` | `view_definition` | `view_definition` |
| `vg_customer_daily_snapshot` | `VIEW` | `view_definition` | `view_definition` |
| `vg_customer_monthly_snapshot` | `VIEW` | `view_definition` | `view_definition` |
| `vg_ddr_revenue` | `VIEW` | `view_definition` | `view_definition` |
| `vg_dealing_clicks_openclose_breakdown` | `VIEW` | `view_definition` | `view_definition` |
| `vg_dealing_dealingdashboard_cid` | `VIEW` | `view_definition` | `view_definition` |
| `winback_daily_segments` | `MANAGED` | `NOTEBOOK` | `2168358810410994` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `de_output_mixpanel_gcid_ftd_flow_steps` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
