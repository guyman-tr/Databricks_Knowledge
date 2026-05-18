---
schema: etoro_kpi_prep
catalog: main
display_name: etoro_kpi_prep — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-18T08:03:13Z"
lineage_lookback_days: 90
in_scope_count: 53
out_of_scope_count: 2
objects:
  - name: __materialization_mat_5117375b_0b8d_434e_a2d1_fd7665b17686_mv_revenue_trading_1
    full_name: main.etoro_kpi_prep.__materialization_mat_5117375b_0b8d_434e_a2d1_fd7665b17686_mv_revenue_trading_1
    type: MANAGED
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: event_log_5117375b_0b8d_434e_a2d1_fd7665b17686
    full_name: main.etoro_kpi_prep.event_log_5117375b_0b8d_434e_a2d1_fd7665b17686
    type: MANAGED
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_de_user_dim_ddr_customer_dailystatus_scd
    full_name: main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
    type: EXTERNAL
    writer:
      kind: JOB
      path: 854926722635349
      lineage_source: system.access.table_lineage
      lineage_event_count: 143
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 8db1c9f8-9947-4ea7-a680-c56e2d199aa6
          workspace_id: 5142916747090026
          event_count: 32
          first_event_time: "2026-05-14T08:45:24.128000+00:00"
          last_event_time: "2026-05-14T09:18:18.849000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 4433076032980144
          workspace_id: 5263962954799003
          event_count: 12
          first_event_time: "2026-03-22T08:16:45.542000+00:00"
          last_event_time: "2026-03-22T08:24:56.394000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 9b4db745-1c6f-401a-bc41-cd7e00d1290a
          workspace_id: 5263962954799003
          event_count: 9
          first_event_time: "2026-03-25T16:42:55.728000+00:00"
          last_event_time: "2026-03-25T16:46:24.269000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: be48072e-bdb3-4043-885f-5095eb49862c
          workspace_id: 5142916747090026
          event_count: 8
          first_event_time: "2026-05-17T08:02:06.319000+00:00"
          last_event_time: "2026-05-17T12:44:49.715000+00:00"
    in_scope: true
  - name: mv_revenue_trading
    full_name: main.etoro_kpi_prep.mv_revenue_trading
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi_prep.v_revenue_fullcommission
      - main.etoro_kpi_prep.v_revenue_commission
      - main.etoro_kpi_prep.v_revenue_ticketfee_fixed
      - main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
      - main.etoro_kpi_prep.v_revenue_rollover
      - main.etoro_kpi_prep.v_revenue_dividend
      - main.etoro_kpi_prep.v_revenue_adminfee
      - main.etoro_kpi_prep.v_revenue_spotadjustfee
      - main.dwh.dim_Position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
      - main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
    refs_source: view_definition (regex extract)
  - name: v_copyfund_positions
    full_name: main.etoro_kpi_prep.v_copyfund_positions
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.dwh.dim_position
    refs_source: view_definition (regex extract)
  - name: v_ddr_revenues
    full_name: main.etoro_kpi_prep.v_ddr_revenues
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi_prep.v_fact_customeraction_w_metrics
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype
      - main.etoro_kpi_prep.v_revenue_optionsplatform
      - main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
      - main.etoro_kpi_prep.v_revenue_interestfee
      - main.etoro_kpi_prep.v_revenue_stakingfee
    refs_source: view_definition (regex extract)
  - name: v_dim_dataplatform_uuid
    full_name: main.etoro_kpi_prep.v_dim_dataplatform_uuid
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_db.bronze_sub_accounts_accounts
      - main.etoro_kpi.v_spaceship_aum
    refs_source: view_definition (regex extract)
  - name: v_dim_ftdplatform
    full_name: main.etoro_kpi_prep.v_dim_ftdplatform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.bronze_moneybusdb_dictionary_accounttypes
    refs_source: view_definition (regex extract)
  - name: v_dim_instrument_enriched
    full_name: main.etoro_kpi_prep.v_dim_instrument_enriched
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.trading.bronze_etoro_trade_instrumentmetadata_daily
      - main.trading.bronze_etoro_trade_providertoinstrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.trading.bronze_etoro_trade_instrumentgroups
    refs_source: view_definition (regex extract)
  - name: v_fact_customeraction
    full_name: main.etoro_kpi_prep.v_fact_customeraction
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.trading.bronze_etoro_history_positionchangelog
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.dim_position
    refs_source: view_definition (regex extract)
  - name: v_fact_customeraction_enriched
    full_name: main.etoro_kpi_prep.v_fact_customeraction_enriched
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.dim_position
    refs_source: view_definition (regex extract)
  - name: v_fact_customeraction_w_metrics
    full_name: main.etoro_kpi_prep.v_fact_customeraction_w_metrics
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_recurringinvestment_recurringinvestment_planinstances
      - main.dwh.dim_position
      - main.etoro_kpi_prep.v_fact_customeraction_enriched
      - main.etoro_kpi_prep.v_dim_instrument_enriched
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
      - main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
      - main.bi_db.bronze_etoro_trade_adminpositionlog
    refs_source: view_definition (regex extract)
  - name: v_globalftdplatform
    full_name: main.etoro_kpi_prep.v_globalftdplatform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.bronze_moneybusdb_dictionary_accounttypes
    refs_source: view_definition (regex extract)
  - name: v_instrument_conversion_rates_dwh
    full_name: main.etoro_kpi_prep.v_instrument_conversion_rates_dwh
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: v_mimo_allplatforms
    full_name: main.etoro_kpi_prep.v_mimo_allplatforms
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
      - main.etoro_kpi_prep.v_mimo_tradingplatform
      - main.etoro_kpi_prep.v_mimo_emoneyplatform
      - main.etoro_kpi_prep.v_mimo_optionsplatform
    refs_source: view_definition (regex extract)
  - name: v_mimo_emoneyplatform
    full_name: main.etoro_kpi_prep.v_mimo_emoneyplatform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
    refs_source: view_definition (regex extract)
  - name: v_mimo_first_deposit_all_platforms
    full_name: main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
      - main.emoney.bronze_fiatdwhdb_dbo_fiattransactions
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_mimo_options_platform
    full_name: main.etoro_kpi_prep.v_mimo_options_platform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
      - main.general.bronze_usabroker_apex_options
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_mimo_optionsplatform
    full_name: main.etoro_kpi_prep.v_mimo_optionsplatform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
      - main.general.bronze_usabroker_apex_options
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_mimo_tradingplatform
    full_name: main.etoro_kpi_prep.v_mimo_tradingplatform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
    refs_source: view_definition (regex extract)
  - name: v_moneyfarm_aum
    full_name: main.etoro_kpi_prep.v_moneyfarm_aum
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.money_farm.silver_moneyfarm_etoro_mf_aum
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    refs_source: view_definition (regex extract)
  - name: v_moneyfarm_fees
    full_name: main.etoro_kpi_prep.v_moneyfarm_fees
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
  - name: v_moneyfarm_mimo
    full_name: main.etoro_kpi_prep.v_moneyfarm_mimo
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    refs_source: view_definition (regex extract)
  - name: v_options_aum
    full_name: main.etoro_kpi_prep.v_options_aum
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
      - main.general.bronze_usabroker_apex_options
    refs_source: view_definition (regex extract)
  - name: v_population_active_traders
    full_name: main.etoro_kpi_prep.v_population_active_traders
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.etoro_kpi_prep.v_revenue_optionsplatform
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_population_active_traders_lite
    full_name: main.etoro_kpi_prep.v_population_active_traders_lite
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.etoro_kpi_prep.v_revenue_optionsplatform
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_population_balance_only_accounts
    full_name: main.etoro_kpi_prep.v_population_balance_only_accounts
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
      - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
      - main.general.bronze_usabroker_apex_options
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.etoro_kpi_prep.v_population_active_traders
      - main.etoro_kpi_prep.v_population_portfolio_only
    refs_source: view_definition (regex extract)
  - name: v_population_first_time_funded
    full_name: main.etoro_kpi_prep.v_population_first_time_funded
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.etoro_kpi_prep.v_mimo_allplatforms
      - main.etoro_kpi_prep.v_globalftdplatform
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.dim_position
      - main.etoro_kpi_prep.v_revenue_optionsplatform
    refs_source: view_definition (regex extract)
  - name: v_population_first_trading_action
    full_name: main.etoro_kpi_prep.v_population_first_trading_action
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_population_funded
    full_name: main.etoro_kpi_prep.v_population_funded
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
      - main.etoro_kpi_prep.v_options_aum
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.etoro_kpi_prep.v_population_first_time_funded
    refs_source: view_definition (regex extract)
  - name: v_population_otd_daterange
    full_name: main.etoro_kpi_prep.v_population_otd_daterange
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
    refs_source: view_definition (regex extract)
  - name: v_population_portfolio_only
    full_name: main.etoro_kpi_prep.v_population_portfolio_only
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
      - main.general.bronze_usabroker_apex_options
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.etoro_kpi_prep.v_population_active_traders
    refs_source: view_definition (regex extract)
  - name: v_revenue_adminfee
    full_name: main.etoro_kpi_prep.v_revenue_adminfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
    refs_source: view_definition (regex extract)
  - name: v_revenue_cashoutfee_excluderedeem
    full_name: main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_cashoutfee_incredeem
    full_name: main.etoro_kpi_prep.v_revenue_cashoutfee_incredeem
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_commission
    full_name: main.etoro_kpi_prep.v_revenue_commission
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    refs_source: view_definition (regex extract)
  - name: v_revenue_conversionfee
    full_name: main.etoro_kpi_prep.v_revenue_conversionfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
    refs_source: view_definition (regex extract)
  - name: v_revenue_conversionfee_withpositiondata
    full_name: main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: v_revenue_cryptotofiat_c2f
    full_name: main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_dividend
    full_name: main.etoro_kpi_prep.v_revenue_dividend
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    refs_source: view_definition (regex extract)
  - name: v_revenue_dormantfee
    full_name: main.etoro_kpi_prep.v_revenue_dormantfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_fullcommission
    full_name: main.etoro_kpi_prep.v_revenue_fullcommission
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    refs_source: view_definition (regex extract)
  - name: v_revenue_interestfee
    full_name: main.etoro_kpi_prep.v_revenue_interestfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_optionsplatform
    full_name: main.etoro_kpi_prep.v_revenue_optionsplatform
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
      - main.general.bronze_usabroker_apex_options
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: v_revenue_rollover
    full_name: main.etoro_kpi_prep.v_revenue_rollover
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    refs_source: view_definition (regex extract)
  - name: v_revenue_sdrt
    full_name: main.etoro_kpi_prep.v_revenue_sdrt
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: v_revenue_share_lending
    full_name: main.etoro_kpi_prep.v_revenue_share_lending
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_spotadjustfee
    full_name: main.etoro_kpi_prep.v_revenue_spotadjustfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
    refs_source: view_definition (regex extract)
  - name: v_revenue_stakingfee
    full_name: main.etoro_kpi_prep.v_revenue_stakingfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_revenue_ticketfee_bypercent
    full_name: main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_historycosts_history_costs
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: v_revenue_ticketfee_fixed
    full_name: main.etoro_kpi_prep.v_revenue_ticketfee_fixed
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
      - main.general.bronze_historycosts_history_costs
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: v_revenue_transfercoinfee
    full_name: main.etoro_kpi_prep.v_revenue_transfercoinfee
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: v_spaceship_mimo
    full_name: main.etoro_kpi_prep.v_spaceship_mimo
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.spaceship.bronze_spaceship_metabase_user_beta
      - main.spaceship.bronze_spaceship_metabase_contact
      - main.spaceship.bronze_spaceship_metabase_super_transactions
      - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
      - main.spaceship.spaceship_metabase_voyager_user_balances
      - main.spaceship.bronze_spaceship_metabase_nova_transactions
      - main.bi_db.bronze_sub_accounts_accounts
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    refs_source: view_definition (regex extract)
  - name: v_trading_volume_and_amount
    full_name: main.etoro_kpi_prep.v_trading_volume_and_amount
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
      - main.etoro_kpi_prep.v_dim_instrument_enriched
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.etoro_kpi_prep.v_copyfund_positions
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
    refs_source: view_definition (regex extract)
  - name: v_trading_volume_positionlevel
    full_name: main.etoro_kpi_prep.v_trading_volume_positionlevel
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
      - main.etoro_kpi_prep.v_dim_instrument_enriched
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.etoro_kpi_prep.v_copyfund_positions
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
    refs_source: view_definition (regex extract)
---

# etoro_kpi_prep — Schema Card

> UC-Pipeline scope sheet for `main.etoro_kpi_prep`. **53 in-scope** / **2 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `gold_de_user_dim_ddr_customer_dailystatus_scd` | `EXTERNAL` | `JOB` | `854926722635349` |
| `mv_revenue_trading` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `v_copyfund_positions` | `VIEW` | `view_definition` | `view_definition` |
| `v_ddr_revenues` | `VIEW` | `view_definition` | `view_definition` |
| `v_dim_dataplatform_uuid` | `VIEW` | `view_definition` | `view_definition` |
| `v_dim_ftdplatform` | `VIEW` | `view_definition` | `view_definition` |
| `v_dim_instrument_enriched` | `VIEW` | `view_definition` | `view_definition` |
| `v_fact_customeraction` | `VIEW` | `view_definition` | `view_definition` |
| `v_fact_customeraction_enriched` | `VIEW` | `view_definition` | `view_definition` |
| `v_fact_customeraction_w_metrics` | `VIEW` | `view_definition` | `view_definition` |
| `v_globalftdplatform` | `VIEW` | `view_definition` | `view_definition` |
| `v_instrument_conversion_rates_dwh` | `VIEW` | `view_definition` | `view_definition` |
| `v_mimo_allplatforms` | `VIEW` | `view_definition` | `view_definition` |
| `v_mimo_emoneyplatform` | `VIEW` | `view_definition` | `view_definition` |
| `v_mimo_first_deposit_all_platforms` | `VIEW` | `view_definition` | `view_definition` |
| `v_mimo_options_platform` | `VIEW` | `view_definition` | `view_definition` |
| `v_mimo_optionsplatform` | `VIEW` | `view_definition` | `view_definition` |
| `v_mimo_tradingplatform` | `VIEW` | `view_definition` | `view_definition` |
| `v_moneyfarm_aum` | `VIEW` | `view_definition` | `view_definition` |
| `v_moneyfarm_fees` | `VIEW` | `view_definition` | `view_definition` |
| `v_moneyfarm_mimo` | `VIEW` | `view_definition` | `view_definition` |
| `v_options_aum` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_active_traders` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_active_traders_lite` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_balance_only_accounts` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_first_time_funded` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_first_trading_action` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_funded` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_otd_daterange` | `VIEW` | `view_definition` | `view_definition` |
| `v_population_portfolio_only` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_adminfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_cashoutfee_excluderedeem` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_cashoutfee_incredeem` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_commission` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_conversionfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_conversionfee_withpositiondata` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_cryptotofiat_c2f` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_dividend` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_dormantfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_fullcommission` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_interestfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_optionsplatform` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_rollover` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_sdrt` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_share_lending` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_spotadjustfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_stakingfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_ticketfee_bypercent` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_ticketfee_fixed` | `VIEW` | `view_definition` | `view_definition` |
| `v_revenue_transfercoinfee` | `VIEW` | `view_definition` | `view_definition` |
| `v_spaceship_mimo` | `VIEW` | `view_definition` | `view_definition` |
| `v_trading_volume_and_amount` | `VIEW` | `view_definition` | `view_definition` |
| `v_trading_volume_positionlevel` | `VIEW` | `view_definition` | `view_definition` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `__materialization_mat_5117375b_0b8d_434e_a2d1_fd7665b17686_mv_revenue_trading_1` | `MANAGED` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `event_log_5117375b_0b8d_434e_a2d1_fd7665b17686` | `MANAGED` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
