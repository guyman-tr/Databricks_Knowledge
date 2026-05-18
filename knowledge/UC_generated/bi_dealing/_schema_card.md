---
schema: bi_dealing
catalog: main
display_name: bi_dealing — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-18T07:23:32Z"
lineage_lookback_days: 90
in_scope_count: 117
out_of_scope_count: 26
objects:
  - name: bi_output_dealing_015min_alltrades
    full_name: main.bi_dealing.bi_output_dealing_015min_alltrades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 779425168824714
      lineage_source: system.access.table_lineage
      lineage_event_count: 34608
    in_scope: true
  - name: bi_output_dealing_2023_check_values
    full_name: main.bi_dealing.bi_output_dealing_2023_check_values
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_2023_euro_check_value
    full_name: main.bi_dealing.bi_output_dealing_2023_euro_check_value
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_245_sessions
    full_name: main.bi_dealing.bi_output_dealing_245_sessions
    type: EXTERNAL
    writer:
      kind: JOB
      path: 379903601145478
      lineage_source: system.access.table_lineage
      lineage_event_count: 1212
    in_scope: true
  - name: bi_output_dealing_abuse_alert_log
    full_name: main.bi_dealing.bi_output_dealing_abuse_alert_log
    type: EXTERNAL
    writer:
      kind: JOB
      path: 844382279060709
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: bi_output_dealing_abuse_signal_output
    full_name: main.bi_dealing.bi_output_dealing_abuse_signal_output
    type: EXTERNAL
    writer:
      kind: JOB
      path: 844382279060709
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: bi_output_dealing_alpha_contacts
    full_name: main.bi_dealing.bi_output_dealing_alpha_contacts
    type: EXTERNAL
    writer:
      kind: JOB
      path: 996129058529134
      lineage_source: system.access.table_lineage
      lineage_event_count: 316
    in_scope: true
  - name: bi_output_dealing_alpha_customer_actions
    full_name: main.bi_dealing.bi_output_dealing_alpha_customer_actions
    type: EXTERNAL
    writer:
      kind: JOB
      path: 996129058529134
      lineage_source: system.access.table_lineage
      lineage_event_count: 770
    in_scope: true
  - name: bi_output_dealing_alpha_detailed_data
    full_name: main.bi_dealing.bi_output_dealing_alpha_detailed_data
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_alpha_detailed_data_fifo
    full_name: main.bi_dealing.bi_output_dealing_alpha_detailed_data_fifo
    type: EXTERNAL
    writer:
      kind: JOB
      path: 996129058529134
      lineage_source: system.access.table_lineage
      lineage_event_count: 847
    in_scope: true
  - name: bi_output_dealing_alpha_final_points
    full_name: main.bi_dealing.bi_output_dealing_alpha_final_points
    type: EXTERNAL
    writer:
      kind: JOB
      path: 996129058529134
      lineage_source: system.access.table_lineage
      lineage_event_count: 847
    in_scope: true
  - name: bi_output_dealing_apex_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_apex_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 260621278292538
      lineage_source: system.access.table_lineage
      lineage_event_count: 348
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 4404603554225332
          workspace_id: 5142916747090026
          event_count: 4
          first_event_time: "2026-04-30T06:57:56.471000+00:00"
          last_event_time: "2026-04-30T06:57:56.471000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 695083017622210
          workspace_id: 5142916747090026
          event_count: 3
          first_event_time: "2026-03-03T13:38:54.092000+00:00"
          last_event_time: "2026-03-05T13:33:47.979000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: fed14316-68d9-4f49-8bfe-e4e432d5340a
          workspace_id: 5142916747090026
          event_count: 3
          first_event_time: "2026-04-19T07:51:10.597000+00:00"
          last_event_time: "2026-04-19T08:13:10.676000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 30f11136-56e3-420c-9208-fbeae3babde5
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-03-03T13:29:10.968000+00:00"
          last_event_time: "2026-03-04T19:15:13.048000+00:00"
    in_scope: true
  - name: bi_output_dealing_apex_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_apex_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 260621278292538
      lineage_source: system.access.table_lineage
      lineage_event_count: 224
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 611b3e0c-effb-4918-9ddb-90d702ed3fd8
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-03-12T11:43:09.855000+00:00"
          last_event_time: "2026-03-12T11:43:09.855000+00:00"
    in_scope: true
  - name: bi_output_dealing_bi_db_h_nonpi_highaum
    full_name: main.bi_dealing.bi_output_dealing_bi_db_h_nonpi_highaum
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_bloomberg_holdings_pct_of_mktcap
    full_name: main.bi_dealing.bi_output_dealing_bloomberg_holdings_pct_of_mktcap
    type: EXTERNAL
    writer:
      kind: JOB
      path: 877304087329371
      lineage_source: system.access.table_lineage
      lineage_event_count: 1008
    in_scope: true
  - name: bi_output_dealing_bloomberg_holdings_pct_of_mktcap_cids
    full_name: main.bi_dealing.bi_output_dealing_bloomberg_holdings_pct_of_mktcap_cids
    type: EXTERNAL
    writer:
      kind: JOB
      path: 877304087329371
      lineage_source: system.access.table_lineage
      lineage_event_count: 980
    in_scope: true
  - name: bi_output_dealing_bmll_nbbo_rates_slippage
    full_name: main.bi_dealing.bi_output_dealing_bmll_nbbo_rates_slippage
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1119288627500033
      lineage_source: system.access.table_lineage
      lineage_event_count: 248
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 4468635177170706
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-02-22T11:34:06.168000+00:00"
          last_event_time: "2026-02-22T11:53:21.094000+00:00"
    in_scope: true
  - name: bi_output_dealing_bny_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_bny_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1073017698300732
      lineage_source: system.access.table_lineage
      lineage_event_count: 1017
      additional_producers:
        - entity_type: JOB
          entity_id: 844382279060709
          workspace_id: 6256398679555083
          event_count: 1
          first_event_time: "2026-04-28T10:26:12.417000+00:00"
          last_event_time: "2026-04-28T10:26:12.417000+00:00"
    in_scope: true
  - name: bi_output_dealing_bny_recon_eod_detailed
    full_name: main.bi_dealing.bi_output_dealing_bny_recon_eod_detailed
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1073017698300732
      lineage_source: system.access.table_lineage
      lineage_event_count: 699
    in_scope: true
  - name: bi_output_dealing_bny_virtu_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_bny_virtu_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1073017698300732
      lineage_source: system.access.table_lineage
      lineage_event_count: 2440
      additional_producers:
        - entity_type: JOB
          entity_id: 844382279060709
          workspace_id: 6256398679555083
          event_count: 1
          first_event_time: "2026-04-28T10:26:17.088000+00:00"
          last_event_time: "2026-04-28T10:26:17.088000+00:00"
    in_scope: true
  - name: bi_output_dealing_bny_virtu_recon_trades_detailed
    full_name: main.bi_dealing.bi_output_dealing_bny_virtu_recon_trades_detailed
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1073017698300732
      lineage_source: system.access.table_lineage
      lineage_event_count: 1864
    in_scope: true
  - name: bi_output_dealing_cash_recon
    full_name: main.bi_dealing.bi_output_dealing_cash_recon
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 03c644c9-4472-4429-b6f1-d4a0f6b70f92
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: bi_output_dealing_cfd_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_cfd_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1046813050681297
      lineage_source: system.access.table_lineage
      lineage_event_count: 1060
    in_scope: true
  - name: bi_output_dealing_cidage_data
    full_name: main.bi_dealing.bi_output_dealing_cidage_data
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1117593627031179
      lineage_source: system.access.table_lineage
      lineage_event_count: 90
    in_scope: true
  - name: bi_output_dealing_client_abuse_news_events_calendar
    full_name: main.bi_dealing.bi_output_dealing_client_abuse_news_events_calendar
    type: EXTERNAL
    writer:
      kind: JOB
      path: 844382279060709
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: bi_output_dealing_crypto_pricing
    full_name: main.bi_dealing.bi_output_dealing_crypto_pricing
    type: EXTERNAL
    writer:
      kind: JOB
      path: 863519614150361
      lineage_source: system.access.table_lineage
      lineage_event_count: 450
    in_scope: true
  - name: bi_output_dealing_crypto_volume_live
    full_name: main.bi_dealing.bi_output_dealing_crypto_volume_live
    type: EXTERNAL
    writer:
      kind: JOB
      path: 755063691363415
      lineage_source: system.access.table_lineage
      lineage_event_count: 32363
    in_scope: true
  - name: bi_output_dealing_cryptovolume
    full_name: main.bi_dealing.bi_output_dealing_cryptovolume
    type: EXTERNAL
    writer:
      kind: JOB
      path: 459736547958571
      lineage_source: system.access.table_lineage
      lineage_event_count: 21268
    in_scope: true
  - name: bi_output_dealing_daily_bmll_slippage_latency_compensation
    full_name: main.bi_dealing.bi_output_dealing_daily_bmll_slippage_latency_compensation
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: ae226d85-8b7a-457d-9303-38223c4f721e
      lineage_source: system.access.table_lineage
      lineage_event_count: 126
    in_scope: true
  - name: bi_output_dealing_daily_bmll_tca_ng_oil_final
    full_name: main.bi_dealing.bi_output_dealing_daily_bmll_tca_ng_oil_final
    type: EXTERNAL
    writer:
      kind: JOB
      path: 453106205505337
      lineage_source: system.access.table_lineage
      lineage_event_count: 246
    in_scope: true
  - name: bi_output_dealing_dailyspreadsaggregated
    full_name: main.bi_dealing.bi_output_dealing_dailyspreadsaggregated
    type: EXTERNAL
    writer:
      kind: JOB
      path: 674748125962988
      lineage_source: system.access.table_lineage
      lineage_event_count: 546
    in_scope: true
  - name: bi_output_dealing_dealing_regime_flags
    full_name: main.bi_dealing.bi_output_dealing_dealing_regime_flags
    type: EXTERNAL
    writer:
      kind: JOB
      path: 164081535369475
      lineage_source: system.access.table_lineage
      lineage_event_count: 361
    in_scope: true
  - name: bi_output_dealing_diffusion_nop
    full_name: main.bi_dealing.bi_output_dealing_diffusion_nop
    type: EXTERNAL
    writer:
      kind: JOB
      path: 408480035940269
      lineage_source: system.access.table_lineage
      lineage_event_count: 455
    in_scope: true
  - name: bi_output_dealing_duco_eod
    full_name: main.bi_dealing.bi_output_dealing_duco_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 377435624789100
      lineage_source: system.access.table_lineage
      lineage_event_count: 693
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 1e6ab6a9-5601-47d7-9846-ccdb50719445
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-04T18:48:29.426000+00:00"
          last_event_time: "2026-05-04T18:48:29.426000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: a7018a40-cda9-4582-beb9-cb946b57eaaf
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-04T18:36:14+00:00"
          last_event_time: "2026-05-04T18:36:14+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: cac21f9d-72c7-4714-ae2a-8ca7e92b7e9d
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-15T08:49:15.370000+00:00"
          last_event_time: "2026-04-15T08:49:15.370000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 825d3157-44f7-4dac-a021-cc2ddb4e4efb
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-16T13:37:50.489000+00:00"
          last_event_time: "2026-04-16T13:37:50.489000+00:00"
    in_scope: true
  - name: bi_output_dealing_duco_trades
    full_name: main.bi_dealing.bi_output_dealing_duco_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 377435624789100
      lineage_source: system.access.table_lineage
      lineage_event_count: 616
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 21343df5-e8ba-41fa-a0f0-312d179d4adc
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-15T08:46:40.694000+00:00"
          last_event_time: "2026-04-15T08:46:40.694000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: d0e2890f-c790-4f84-a11e-9a5a396152c8
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-16T13:43:40.598000+00:00"
          last_event_time: "2026-04-16T13:43:40.598000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 882615bb-f45b-4ee3-bd6b-b165479c4593
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-04T18:37:56.499000+00:00"
          last_event_time: "2026-05-04T18:37:56.499000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 1e6ab6a9-5601-47d7-9846-ccdb50719445
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-04T18:52:16.935000+00:00"
          last_event_time: "2026-05-04T18:52:16.935000+00:00"
    in_scope: true
  - name: bi_output_dealing_employee_accountpnl
    full_name: main.bi_dealing.bi_output_dealing_employee_accountpnl
    type: EXTERNAL
    writer:
      kind: JOB
      path: 709482236388754
      lineage_source: system.access.table_lineage
      lineage_event_count: 645
    in_scope: true
  - name: bi_output_dealing_employees_info
    full_name: main.bi_dealing.bi_output_dealing_employees_info
    type: EXTERNAL
    writer:
      kind: JOB
      path: 640700677404306
      lineage_source: system.access.table_lineage
      lineage_event_count: 728
    in_scope: true
  - name: bi_output_dealing_employees_performance
    full_name: main.bi_dealing.bi_output_dealing_employees_performance
    type: EXTERNAL
    writer:
      kind: JOB
      path: 915959240471122
      lineage_source: system.access.table_lineage
      lineage_event_count: 730
    in_scope: true
  - name: bi_output_dealing_esmanetloss_final
    full_name: main.bi_dealing.bi_output_dealing_esmanetloss_final
    type: EXTERNAL
    writer:
      kind: JOB
      path: 686361548289639
      lineage_source: system.access.table_lineage
      lineage_event_count: 99
    in_scope: true
  - name: bi_output_dealing_flowanalysis
    full_name: main.bi_dealing.bi_output_dealing_flowanalysis
    type: EXTERNAL
    writer:
      kind: JOB
      path: 525675434480547
      lineage_source: system.access.table_lineage
      lineage_event_count: 1122
    in_scope: true
  - name: bi_output_dealing_gs_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_gs_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 130370228044191
      lineage_source: system.access.table_lineage
      lineage_event_count: 141
    in_scope: true
  - name: bi_output_dealing_gs_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_gs_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 130370228044191
      lineage_source: system.access.table_lineage
      lineage_event_count: 141
    in_scope: true
  - name: bi_output_dealing_h_abookexposure
    full_name: main.bi_dealing.bi_output_dealing_h_abookexposure
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_h_currentdayzero
    full_name: main.bi_dealing.bi_output_dealing_h_currentdayzero
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_ib_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_ib_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1088343917751476
      lineage_source: system.access.table_lineage
      lineage_event_count: 88
    in_scope: true
  - name: bi_output_dealing_ib_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_ib_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1088343917751476
      lineage_source: system.access.table_lineage
      lineage_event_count: 8
    in_scope: true
  - name: bi_output_dealing_ig_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_ig_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 195291034938394
      lineage_source: system.access.table_lineage
      lineage_event_count: 120
    in_scope: true
  - name: bi_output_dealing_ig_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_ig_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 195291034938394
      lineage_source: system.access.table_lineage
      lineage_event_count: 120
    in_scope: true
  - name: bi_output_dealing_jp_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_jp_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 31974637527720
      lineage_source: system.access.table_lineage
      lineage_event_count: 72
    in_scope: true
  - name: bi_output_dealing_jp_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_jp_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 31974637527720
      lineage_source: system.access.table_lineage
      lineage_event_count: 120
    in_scope: true
  - name: bi_output_dealing_lp_fees_saxo
    full_name: main.bi_dealing.bi_output_dealing_lp_fees_saxo
    type: EXTERNAL
    writer:
      kind: JOB
      path: 85559052527245
      lineage_source: system.access.table_lineage
      lineage_event_count: 1274
    in_scope: true
  - name: bi_output_dealing_lp_fees_saxo_real_by_exchange
    full_name: main.bi_dealing.bi_output_dealing_lp_fees_saxo_real_by_exchange
    type: EXTERNAL
    writer:
      kind: JOB
      path: 85559052527245
      lineage_source: system.access.table_lineage
      lineage_event_count: 364
    in_scope: true
  - name: bi_output_dealing_lp_fees_saxo_stamp_duty
    full_name: main.bi_dealing.bi_output_dealing_lp_fees_saxo_stamp_duty
    type: EXTERNAL
    writer:
      kind: JOB
      path: 85559052527245
      lineage_source: system.access.table_lineage
      lineage_event_count: 182
    in_scope: true
  - name: bi_output_dealing_lp_fees_virtu_real_by_exchange
    full_name: main.bi_dealing.bi_output_dealing_lp_fees_virtu_real_by_exchange
    type: EXTERNAL
    writer:
      kind: JOB
      path: 85559052527245
      lineage_source: system.access.table_lineage
      lineage_event_count: 546
    in_scope: true
  - name: bi_output_dealing_lp_fees_virtu_stamp_duty
    full_name: main.bi_dealing.bi_output_dealing_lp_fees_virtu_stamp_duty
    type: EXTERNAL
    writer:
      kind: JOB
      path: 85559052527245
      lineage_source: system.access.table_lineage
      lineage_event_count: 604
    in_scope: true
  - name: bi_output_dealing_lukka_internal_aggregated
    full_name: main.bi_dealing.bi_output_dealing_lukka_internal_aggregated
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1120995915349000
      lineage_source: system.access.table_lineage
      lineage_event_count: 1301
    in_scope: true
  - name: bi_output_dealing_manipulation_report_real_stocks
    full_name: main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks
    type: EXTERNAL
    writer:
      kind: JOB
      path: 890035936646942
      lineage_source: system.access.table_lineage
      lineage_event_count: 273
    in_scope: true
  - name: bi_output_dealing_manipulation_report_real_stocks_cid
    full_name: main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid
    type: EXTERNAL
    writer:
      kind: JOB
      path: 890035936646942
      lineage_source: system.access.table_lineage
      lineage_event_count: 13
    in_scope: true
  - name: bi_output_dealing_marex_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_marex_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 586693656542297
      lineage_source: system.access.table_lineage
      lineage_event_count: 160
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 40133143330575
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-13T11:49:15.822000+00:00"
          last_event_time: "2026-05-13T11:49:15.822000+00:00"
    in_scope: true
  - name: bi_output_dealing_marex_recon_eod_futures
    full_name: main.bi_dealing.bi_output_dealing_marex_recon_eod_futures
    type: EXTERNAL
    writer:
      kind: JOB
      path: 586693656542297
      lineage_source: system.access.table_lineage
      lineage_event_count: 126
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 40133143330575
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-13T11:49:33.453000+00:00"
          last_event_time: "2026-05-13T11:49:33.453000+00:00"
    in_scope: true
  - name: bi_output_dealing_marex_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_marex_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 586693656542297
      lineage_source: system.access.table_lineage
      lineage_event_count: 126
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 40133143330575
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-13T11:49:30.514000+00:00"
          last_event_time: "2026-05-13T11:49:30.514000+00:00"
    in_scope: true
  - name: bi_output_dealing_marex_recon_trades_futures
    full_name: main.bi_dealing.bi_output_dealing_marex_recon_trades_futures
    type: EXTERNAL
    writer:
      kind: JOB
      path: 586693656542297
      lineage_source: system.access.table_lineage
      lineage_event_count: 140
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 40133143330575
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-13T11:49:47.672000+00:00"
          last_event_time: "2026-05-13T11:49:47.672000+00:00"
    in_scope: true
  - name: bi_output_dealing_maxnop_report
    full_name: main.bi_dealing.bi_output_dealing_maxnop_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 541548373598410
      lineage_source: system.access.table_lineage
      lineage_event_count: 360
    in_scope: true
  - name: bi_output_dealing_mm_topofbook
    full_name: main.bi_dealing.bi_output_dealing_mm_topofbook
    type: EXTERNAL
    writer:
      kind: JOB
      path: 869276191161776
      lineage_source: system.access.table_lineage
      lineage_event_count: 631
    in_scope: true
  - name: bi_output_dealing_negativebalances
    full_name: main.bi_dealing.bi_output_dealing_negativebalances
    type: EXTERNAL
    writer:
      kind: JOB
      path: 919983786356022
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
    in_scope: true
  - name: bi_output_dealing_nhd_dashboard
    full_name: main.bi_dealing.bi_output_dealing_nhd_dashboard
    type: EXTERNAL
    writer:
      kind: JOB
      path: 960051081323166
      lineage_source: system.access.table_lineage
      lineage_event_count: 1155
      additional_producers:
        - entity_type: JOB
          entity_id: 950337154720822
          workspace_id: 6358342630366312
          event_count: 1110
          first_event_time: "2026-02-17T06:01:06.567000+00:00"
          last_event_time: "2026-05-18T06:07:01.558000+00:00"
        - entity_type: JOB
          entity_id: 1003481349953041
          workspace_id: 6358342630366312
          event_count: 1081
          first_event_time: "2026-02-17T01:10:28.987000+00:00"
          last_event_time: "2026-05-18T01:17:19.821000+00:00"
        - entity_type: JOB
          entity_id: 1028192576722845
          workspace_id: 6358342630366312
          event_count: 1080
          first_event_time: "2026-02-17T23:11:12.811000+00:00"
          last_event_time: "2026-05-17T23:16:14.938000+00:00"
        - entity_type: JOB
          entity_id: 1001761468586193
          workspace_id: 6358342630366312
          event_count: 1070
          first_event_time: "2026-02-17T00:10:25.392000+00:00"
          last_event_time: "2026-05-18T01:37:34.077000+00:00"
    in_scope: true
  - name: bi_output_dealing_nixar_beta_betaconstituencystatus
    full_name: main.bi_dealing.bi_output_dealing_nixar_beta_betaconstituencystatus
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_nixar_beta_dailybetaprod
    full_name: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_nixar_beta_dailybetaprod_v
    full_name: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.bi_output_dealing_nixar_beta_DailyBetaProd
    refs_source: view_definition (regex extract)
  - name: bi_output_dealing_nixar_beta_dailybetatarget
    full_name: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_nixar_beta_dailybetatarget_v
    full_name: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.bi_output_dealing_nixar_beta_DailyBetaTarget
    refs_source: view_definition (regex extract)
  - name: bi_output_dealing_nixar_beta_earningscalendar
    full_name: main.bi_dealing.bi_output_dealing_nixar_beta_earningscalendar
    type: EXTERNAL
    writer:
      kind: JOB
      path: 507885409047840
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
    in_scope: true
  - name: bi_output_dealing_nixar_delta_diffusionanalysis
    full_name: main.bi_dealing.bi_output_dealing_nixar_delta_diffusionanalysis
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_nixar_delta_diffusionanalysis_v
    full_name: main.bi_dealing.bi_output_dealing_nixar_delta_diffusionanalysis_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.bi_output_dealing_nixar_Delta_DiffusionAnalysis
    refs_source: view_definition (regex extract)
  - name: bi_output_dealing_nixar_delta_diffusionvolatility
    full_name: main.bi_dealing.bi_output_dealing_nixar_delta_diffusionvolatility
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_nop_report
    full_name: main.bi_dealing.bi_output_dealing_nop_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 729868208506264
      lineage_source: system.access.table_lineage
      lineage_event_count: 1200
    in_scope: true
  - name: bi_output_dealing_oms_execution_per_type
    full_name: main.bi_dealing.bi_output_dealing_oms_execution_per_type
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_oms_order_per_type
    full_name: main.bi_dealing.bi_output_dealing_oms_order_per_type
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_oms_volume_ratio
    full_name: main.bi_dealing.bi_output_dealing_oms_volume_ratio
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_omsinternalmarketsettings
    full_name: main.bi_dealing.bi_output_dealing_omsinternalmarketsettings
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_pi_tradinglimitations_clicksize
    full_name: main.bi_dealing.bi_output_dealing_pi_tradinglimitations_clicksize
    type: EXTERNAL
    writer:
      kind: JOB
      path: 346494508027063
      lineage_source: system.access.table_lineage
      lineage_event_count: 728
    in_scope: true
  - name: bi_output_dealing_premier_clients_2026_positions_report
    full_name: main.bi_dealing.bi_output_dealing_premier_clients_2026_positions_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 738479020331210
      lineage_source: system.access.table_lineage
      lineage_event_count: 1640
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 3613685500402297
          workspace_id: 6358342630366312
          event_count: 1043
          first_event_time: "2026-03-09T13:25:30.611000+00:00"
          last_event_time: "2026-03-18T10:07:30.245000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 227497734484650
          workspace_id: 6358342630366312
          event_count: 24
          first_event_time: "2026-03-12T14:13:59.608000+00:00"
          last_event_time: "2026-03-12T15:01:35.822000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 1473927744120150
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-04-09T11:59:42.687000+00:00"
          last_event_time: "2026-04-09T12:07:23.115000+00:00"
        - entity_type: JOB
          entity_id: 5085992112078
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-04-09T16:21:28.993000+00:00"
          last_event_time: "2026-04-09T16:26:29.910000+00:00"
    in_scope: true
  - name: bi_output_dealing_premier_clients_report
    full_name: main.bi_dealing.bi_output_dealing_premier_clients_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 276911169105228
      lineage_source: system.access.table_lineage
      lineage_event_count: 1603
    in_scope: true
  - name: bi_output_dealing_premier_clinet_info
    full_name: main.bi_dealing.bi_output_dealing_premier_clinet_info
    type: EXTERNAL
    writer:
      kind: JOB
      path: 195242211459611
      lineage_source: system.access.table_lineage
      lineage_event_count: 1080
    in_scope: true
  - name: bi_output_dealing_premier_customer
    full_name: main.bi_dealing.bi_output_dealing_premier_customer
    type: EXTERNAL
    writer:
      kind: JOB
      path: 57159445514501
      lineage_source: system.access.table_lineage
      lineage_event_count: 6
    in_scope: true
  - name: bi_output_dealing_premier_customer_2026
    full_name: main.bi_dealing.bi_output_dealing_premier_customer_2026
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1058822233960557
      lineage_source: system.access.table_lineage
      lineage_event_count: 137
      additional_producers:
        - entity_type: JOB
          entity_id: 738479020331210
          workspace_id: 6358342630366312
          event_count: 51
          first_event_time: "2026-03-05T08:53:14.898000+00:00"
          last_event_time: "2026-03-15T10:50:27.845000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 3046013432662029
          workspace_id: 6358342630366312
          event_count: 20
          first_event_time: "2026-04-20T19:54:31.847000+00:00"
          last_event_time: "2026-04-20T19:57:37.811000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 3613685500402297
          workspace_id: 6358342630366312
          event_count: 19
          first_event_time: "2026-03-08T14:08:07.340000+00:00"
          last_event_time: "2026-03-18T09:51:51.054000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 227497734484650
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-03-12T14:12:27.921000+00:00"
          last_event_time: "2026-03-15T10:40:23.617000+00:00"
    in_scope: true
  - name: bi_output_dealing_premier_customer_2026_info
    full_name: main.bi_dealing.bi_output_dealing_premier_customer_2026_info
    type: EXTERNAL
    writer:
      kind: JOB
      path: 738479020331210
      lineage_source: system.access.table_lineage
      lineage_event_count: 2053
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 3613685500402297
          workspace_id: 6358342630366312
          event_count: 1800
          first_event_time: "2026-03-09T13:38:43.415000+00:00"
          last_event_time: "2026-03-18T10:22:23.424000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 1651184793673588
          workspace_id: 6358342630366312
          event_count: 60
          first_event_time: "2026-04-06T11:20:33.230000+00:00"
          last_event_time: "2026-04-06T11:25:08.960000+00:00"
        - entity_type: JOB
          entity_id: 977513096326758
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-03-15T11:21:54.639000+00:00"
          last_event_time: "2026-03-15T11:24:23.718000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 4303963729699742
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-09T07:35:13.168000+00:00"
          last_event_time: "2026-03-09T07:35:13.168000+00:00"
    in_scope: true
  - name: bi_output_dealing_prices_stockschangedashboard
    full_name: main.bi_dealing.bi_output_dealing_prices_stockschangedashboard
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_prices_stockschangedashboard_firststep
    full_name: main.bi_dealing.bi_output_dealing_prices_stockschangedashboard_firststep
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_pricespreus_open
    full_name: main.bi_dealing.bi_output_dealing_pricespreus_open
    type: EXTERNAL
    writer:
      kind: JOB
      path: 191497761331299
      lineage_source: system.access.table_lineage
      lineage_event_count: 1835
    in_scope: true
  - name: bi_output_dealing_saxo_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_saxo_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 674979673626499
      lineage_source: system.access.table_lineage
      lineage_event_count: 132
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: a562f215-b020-4168-9d0d-80e4b78f1d81
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-05-05T15:49:28.109000+00:00"
          last_event_time: "2026-05-05T15:58:02.762000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 1597429388951543
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-26T12:28:42.151000+00:00"
          last_event_time: "2026-04-26T12:28:42.151000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 687ae84e-c75f-44f4-b9a4-fcc0b9aadd29
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-24T18:38:34.033000+00:00"
          last_event_time: "2026-04-24T18:38:34.033000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 46ea0a8a-ca16-4e19-9c08-8aa0c42021aa
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-03-11T20:08:50.860000+00:00"
          last_event_time: "2026-03-11T20:08:50.860000+00:00"
    in_scope: true
  - name: bi_output_dealing_saxo_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_saxo_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 674979673626499
      lineage_source: system.access.table_lineage
      lineage_event_count: 160
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 882615bb-f45b-4ee3-bd6b-b165479c4593
          workspace_id: 5142916747090026
          event_count: 4
          first_event_time: "2026-05-05T17:16:18.143000+00:00"
          last_event_time: "2026-05-05T17:32:35.236000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 63d0279a-a4fe-4176-91da-e6a451ea49df
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-04-24T18:40:13.628000+00:00"
          last_event_time: "2026-04-24T18:40:13.628000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: a562f215-b020-4168-9d0d-80e4b78f1d81
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-05T15:50:39.007000+00:00"
          last_event_time: "2026-05-05T15:50:39.007000+00:00"
    in_scope: true
  - name: bi_output_dealing_slippage
    full_name: main.bi_dealing.bi_output_dealing_slippage
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1120154298329634
      lineage_source: system.access.table_lineage
      lineage_event_count: 2588
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 3883677945330819
          workspace_id: 6358342630366312
          event_count: 18
          first_event_time: "2026-02-23T10:52:53.357000+00:00"
          last_event_time: "2026-02-23T10:54:34.820000+00:00"
    in_scope: true
  - name: bi_output_dealing_stocklending_balance_and_transactions_check
    full_name: main.bi_dealing.bi_output_dealing_stocklending_balance_and_transactions_check
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1048
    in_scope: true
  - name: bi_output_dealing_stocklending_datalend_data
    full_name: main.bi_dealing.bi_output_dealing_stocklending_datalend_data
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 786
    in_scope: true
  - name: bi_output_dealing_stocklending_open_loans_recon
    full_name: main.bi_dealing.bi_output_dealing_stocklending_open_loans_recon
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1310
    in_scope: true
  - name: bi_output_dealing_stocklending_open_loans_recon_old
    full_name: main.bi_dealing.bi_output_dealing_stocklending_open_loans_recon_old
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_stocklending_optin_optout_bny_holdings
    full_name: main.bi_dealing.bi_output_dealing_stocklending_optin_optout_bny_holdings
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 780
    in_scope: true
  - name: bi_output_dealing_stocklending_optin_optout_nop
    full_name: main.bi_dealing.bi_output_dealing_stocklending_optin_optout_nop
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1572
    in_scope: true
  - name: bi_output_dealing_stocklending_optin_optout_percid
    full_name: main.bi_dealing.bi_output_dealing_stocklending_optin_optout_percid
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1820
    in_scope: true
  - name: bi_output_dealing_stocklending_optin_optout_percid_isus
    full_name: main.bi_dealing.bi_output_dealing_stocklending_optin_optout_percid_isus
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1820
    in_scope: true
  - name: bi_output_dealing_stocklending_optin_report_per_cid
    full_name: main.bi_dealing.bi_output_dealing_stocklending_optin_report_per_cid
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1572
    in_scope: true
  - name: bi_output_dealing_stocklending_revenue
    full_name: main.bi_dealing.bi_output_dealing_stocklending_revenue
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1300
    in_scope: true
  - name: bi_output_dealing_stocklending_revenue_per_regulation
    full_name: main.bi_dealing.bi_output_dealing_stocklending_revenue_per_regulation
    type: EXTERNAL
    writer:
      kind: JOB
      path: 498315245794462
      lineage_source: system.access.table_lineage
      lineage_event_count: 1300
    in_scope: true
  - name: bi_output_dealing_tables_bi_db_h_nonpi_highaum
    full_name: main.bi_dealing.bi_output_dealing_tables_bi_db_h_nonpi_highaum
    type: EXTERNAL
    writer:
      kind: JOB
      path: 792028385571594
      lineage_source: system.access.table_lineage
      lineage_event_count: 21550
    in_scope: true
  - name: bi_output_dealing_tables_dealing_capitalguarantee
    full_name: main.bi_dealing.bi_output_dealing_tables_dealing_capitalguarantee
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_tables_h_currentdayzero
    full_name: main.bi_dealing.bi_output_dealing_tables_h_currentdayzero
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_tables_h_market_manipulation_hourly
    full_name: main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_tables_h_market_manipulation_hourly_report_v
    full_name: main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly_report_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly
    refs_source: view_definition (regex extract)
  - name: bi_output_dealing_tables_h_pricelocks_hourly
    full_name: main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly
    type: EXTERNAL
    writer:
      kind: JOB
      path: 574133612426560
      lineage_source: system.access.table_lineage
      lineage_event_count: 17103
    in_scope: true
  - name: bi_output_dealing_tables_h_pricelocks_hourly_report_v
    full_name: main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly
    refs_source: view_definition (regex extract)
  - name: bi_output_dealing_test_20250306_stocklending_balance_and_transactions_check
    full_name: main.bi_dealing.bi_output_dealing_test_20250306_stocklending_balance_and_transactions_check
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_dealing_ubs_saxo_recon_eodholdings
    full_name: main.bi_dealing.bi_output_dealing_ubs_saxo_recon_eodholdings
    type: EXTERNAL
    writer:
      kind: JOB
      path: 166451544565030
      lineage_source: system.access.table_lineage
      lineage_event_count: 701
    in_scope: true
  - name: bi_output_dealing_vision_recon_eod
    full_name: main.bi_dealing.bi_output_dealing_vision_recon_eod
    type: EXTERNAL
    writer:
      kind: JOB
      path: 286367739951792
      lineage_source: system.access.table_lineage
      lineage_event_count: 56
    in_scope: true
  - name: bi_output_dealing_vision_recon_trades
    full_name: main.bi_dealing.bi_output_dealing_vision_recon_trades
    type: EXTERNAL
    writer:
      kind: JOB
      path: 286367739951792
      lineage_source: system.access.table_lineage
      lineage_event_count: 42
    in_scope: true
  - name: bi_output_dealing_volatility_bucket
    full_name: main.bi_dealing.bi_output_dealing_volatility_bucket
    type: EXTERNAL
    writer:
      kind: JOB
      path: 284833408776571
      lineage_source: system.access.table_lineage
      lineage_event_count: 14
    in_scope: true
  - name: de_output_allfailure
    full_name: main.bi_dealing.de_output_allfailure
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_dealing_delta_diffusionanalysis
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysis
    type: EXTERNAL
    writer:
      kind: JOB
      path: 729784718724350
      lineage_source: system.access.table_lineage
      lineage_event_count: 2136
    in_scope: true
  - name: gold_dealing_delta_diffusionanalysis_adhoc
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_dealing_delta_diffusionanalysis_adhoc_v
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.gold_dealing_Delta_DiffusionAnalysis_adhoc
    refs_source: view_definition (regex extract)
  - name: gold_dealing_delta_diffusionanalysis_v
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysis_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.gold_dealing_Delta_DiffusionAnalysis
    refs_source: view_definition (regex extract)
  - name: gold_dealing_delta_diffusionanalysisfx
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysisfx
    type: EXTERNAL
    writer:
      kind: JOB
      path: 729784718724350
      lineage_source: system.access.table_lineage
      lineage_event_count: 2136
    in_scope: true
  - name: gold_dealing_delta_diffusionanalysisfx_adhoc
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysisfx_adhoc
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_dealing_delta_diffusionanalysisfx_v
    full_name: main.bi_dealing.gold_dealing_delta_diffusionanalysisfx_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.gold_dealing_Delta_DiffusionAnalysisFX
    refs_source: view_definition (regex extract)
  - name: gold_dealing_delta_diffusionvolatility
    full_name: main.bi_dealing.gold_dealing_delta_diffusionvolatility
    type: EXTERNAL
    writer:
      kind: JOB
      path: 527900172329274
      lineage_source: system.access.table_lineage
      lineage_event_count: 167
    in_scope: true
  - name: gold_dealing_delta_oms_diffusionanalysis
    full_name: main.bi_dealing.gold_dealing_delta_oms_diffusionanalysis
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_dealing_delta_oms_models_v
    full_name: main.bi_dealing.gold_dealing_delta_oms_models_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_dealing.gold_dealing_delta_oms_diffusion
    refs_source: view_definition (regex extract)
  - name: gold_dealing_libra_hscl
    full_name: main.bi_dealing.gold_dealing_libra_hscl
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 90
    in_scope: true
  - name: gold_dealing_libra_issettled
    full_name: main.bi_dealing.gold_dealing_libra_issettled
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 21
    in_scope: true
  - name: gold_dealing_libra_limitrate
    full_name: main.bi_dealing.gold_dealing_libra_limitrate
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 21
    in_scope: true
  - name: gold_dealing_libra_opcl
    full_name: main.bi_dealing.gold_dealing_libra_opcl
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 69
    in_scope: true
  - name: gold_dealing_libra_parentpositionid
    full_name: main.bi_dealing.gold_dealing_libra_parentpositionid
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 21
    in_scope: true
  - name: gold_dealing_libra_stoprate
    full_name: main.bi_dealing.gold_dealing_libra_stoprate
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 21
    in_scope: true
  - name: gold_dealing_libra_treeid
    full_name: main.bi_dealing.gold_dealing_libra_treeid
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 21
    in_scope: true
  - name: gold_dealing_libra_units
    full_name: main.bi_dealing.gold_dealing_libra_units
    type: EXTERNAL
    writer:
      kind: JOB
      path: 475617116052460
      lineage_source: system.access.table_lineage
      lineage_event_count: 21
    in_scope: true
  - name: gold_dealing_oms_delta_diffusionanalysis_v
    full_name: main.bi_dealing.gold_dealing_oms_delta_diffusionanalysis_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_dealing.gold_dealing_delta_diffusionanalysis
    refs_source: view_definition (regex extract)
  - name: gold_dealing_oms_internalmarket_imdynamicbookfutures_v
    full_name: main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_dealing.gold_dealing_oms_internalmarket_parameters
      - main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: gold_dealing_oms_internalmarket_multipliers
    full_name: main.bi_dealing.gold_dealing_oms_internalmarket_multipliers
    type: EXTERNAL
    writer:
      kind: JOB
      path: 940047629092362
      lineage_source: system.access.table_lineage
      lineage_event_count: 4
      additional_producers:
        - entity_type: JOB
          entity_id: 280567630183
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-04-26T11:16:56.217000+00:00"
          last_event_time: "2026-04-26T11:17:31.670000+00:00"
    in_scope: true
  - name: gold_dealing_oms_internalmarket_multipliershistory
    full_name: main.bi_dealing.gold_dealing_oms_internalmarket_multipliershistory
    type: EXTERNAL
    writer:
      kind: JOB
      path: 940047629092362
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
      additional_producers:
        - entity_type: JOB
          entity_id: 280567630183
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-26T11:16:56.941000+00:00"
          last_event_time: "2026-04-26T11:17:16.349000+00:00"
    in_scope: true
  - name: gold_dealing_oms_internalmarket_parameters
    full_name: main.bi_dealing.gold_dealing_oms_internalmarket_parameters
    type: EXTERNAL
    writer:
      kind: JOB
      path: 280567630183
      lineage_source: system.access.table_lineage
      lineage_event_count: 13
      additional_producers:
        - entity_type: JOB
          entity_id: 844382279060709
          workspace_id: 6256398679555083
          event_count: 1
          first_event_time: "2026-04-26T10:16:22.607000+00:00"
          last_event_time: "2026-04-26T10:16:22.607000+00:00"
    in_scope: true
  - name: gold_dealing_oms_internalmarket_parametershistory
    full_name: main.bi_dealing.gold_dealing_oms_internalmarket_parametershistory
    type: EXTERNAL
    writer:
      kind: JOB
      path: 280567630183
      lineage_source: system.access.table_lineage
      lineage_event_count: 9
    in_scope: true
  - name: newhedgedash_email_csv
    full_name: main.bi_dealing.newhedgedash_email_csv
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_dealing.bi_output_dealing_nhd_dashboard
    refs_source: view_definition (regex extract)
  - name: v_hschangesummarylog_yesterday_email_csv
    full_name: main.bi_dealing.v_hschangesummarylog_yesterday_email_csv
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog
    refs_source: view_definition (regex extract)
---

# bi_dealing — Schema Card

> UC-Pipeline scope sheet for `main.bi_dealing`. **117 in-scope** / **26 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `bi_output_dealing_015min_alltrades` | `EXTERNAL` | `JOB` | `779425168824714` |
| `bi_output_dealing_245_sessions` | `EXTERNAL` | `JOB` | `379903601145478` |
| `bi_output_dealing_abuse_alert_log` | `EXTERNAL` | `JOB` | `844382279060709` |
| `bi_output_dealing_abuse_signal_output` | `EXTERNAL` | `JOB` | `844382279060709` |
| `bi_output_dealing_alpha_contacts` | `EXTERNAL` | `JOB` | `996129058529134` |
| `bi_output_dealing_alpha_customer_actions` | `EXTERNAL` | `JOB` | `996129058529134` |
| `bi_output_dealing_alpha_detailed_data_fifo` | `EXTERNAL` | `JOB` | `996129058529134` |
| `bi_output_dealing_alpha_final_points` | `EXTERNAL` | `JOB` | `996129058529134` |
| `bi_output_dealing_apex_recon_eod` | `EXTERNAL` | `JOB` | `260621278292538` |
| `bi_output_dealing_apex_recon_trades` | `EXTERNAL` | `JOB` | `260621278292538` |
| `bi_output_dealing_bloomberg_holdings_pct_of_mktcap` | `EXTERNAL` | `JOB` | `877304087329371` |
| `bi_output_dealing_bloomberg_holdings_pct_of_mktcap_cids` | `EXTERNAL` | `JOB` | `877304087329371` |
| `bi_output_dealing_bmll_nbbo_rates_slippage` | `EXTERNAL` | `JOB` | `1119288627500033` |
| `bi_output_dealing_bny_recon_eod` | `EXTERNAL` | `JOB` | `1073017698300732` |
| `bi_output_dealing_bny_recon_eod_detailed` | `EXTERNAL` | `JOB` | `1073017698300732` |
| `bi_output_dealing_bny_virtu_recon_trades` | `EXTERNAL` | `JOB` | `1073017698300732` |
| `bi_output_dealing_bny_virtu_recon_trades_detailed` | `EXTERNAL` | `JOB` | `1073017698300732` |
| `bi_output_dealing_cash_recon` | `EXTERNAL` | `DBSQL_QUERY` | `03c644c9-4472-4429-b6f1-d4a0f6b70f92` |
| `bi_output_dealing_cfd_recon_eod` | `EXTERNAL` | `JOB` | `1046813050681297` |
| `bi_output_dealing_cidage_data` | `EXTERNAL` | `JOB` | `1117593627031179` |
| `bi_output_dealing_client_abuse_news_events_calendar` | `EXTERNAL` | `JOB` | `844382279060709` |
| `bi_output_dealing_crypto_pricing` | `EXTERNAL` | `JOB` | `863519614150361` |
| `bi_output_dealing_crypto_volume_live` | `EXTERNAL` | `JOB` | `755063691363415` |
| `bi_output_dealing_cryptovolume` | `EXTERNAL` | `JOB` | `459736547958571` |
| `bi_output_dealing_daily_bmll_slippage_latency_compensation` | `EXTERNAL` | `DBSQL_QUERY` | `ae226d85-8b7a-457d-9303-38223c4f721e` |
| `bi_output_dealing_daily_bmll_tca_ng_oil_final` | `EXTERNAL` | `JOB` | `453106205505337` |
| `bi_output_dealing_dailyspreadsaggregated` | `EXTERNAL` | `JOB` | `674748125962988` |
| `bi_output_dealing_dealing_regime_flags` | `EXTERNAL` | `JOB` | `164081535369475` |
| `bi_output_dealing_diffusion_nop` | `EXTERNAL` | `JOB` | `408480035940269` |
| `bi_output_dealing_duco_eod` | `EXTERNAL` | `JOB` | `377435624789100` |
| `bi_output_dealing_duco_trades` | `EXTERNAL` | `JOB` | `377435624789100` |
| `bi_output_dealing_employee_accountpnl` | `EXTERNAL` | `JOB` | `709482236388754` |
| `bi_output_dealing_employees_info` | `EXTERNAL` | `JOB` | `640700677404306` |
| `bi_output_dealing_employees_performance` | `EXTERNAL` | `JOB` | `915959240471122` |
| `bi_output_dealing_esmanetloss_final` | `EXTERNAL` | `JOB` | `686361548289639` |
| `bi_output_dealing_flowanalysis` | `EXTERNAL` | `JOB` | `525675434480547` |
| `bi_output_dealing_gs_recon_eod` | `EXTERNAL` | `JOB` | `130370228044191` |
| `bi_output_dealing_gs_recon_trades` | `EXTERNAL` | `JOB` | `130370228044191` |
| `bi_output_dealing_ib_recon_eod` | `EXTERNAL` | `JOB` | `1088343917751476` |
| `bi_output_dealing_ib_recon_trades` | `EXTERNAL` | `JOB` | `1088343917751476` |
| `bi_output_dealing_ig_recon_eod` | `EXTERNAL` | `JOB` | `195291034938394` |
| `bi_output_dealing_ig_recon_trades` | `EXTERNAL` | `JOB` | `195291034938394` |
| `bi_output_dealing_jp_recon_eod` | `EXTERNAL` | `JOB` | `31974637527720` |
| `bi_output_dealing_jp_recon_trades` | `EXTERNAL` | `JOB` | `31974637527720` |
| `bi_output_dealing_lp_fees_saxo` | `EXTERNAL` | `JOB` | `85559052527245` |
| `bi_output_dealing_lp_fees_saxo_real_by_exchange` | `EXTERNAL` | `JOB` | `85559052527245` |
| `bi_output_dealing_lp_fees_saxo_stamp_duty` | `EXTERNAL` | `JOB` | `85559052527245` |
| `bi_output_dealing_lp_fees_virtu_real_by_exchange` | `EXTERNAL` | `JOB` | `85559052527245` |
| `bi_output_dealing_lp_fees_virtu_stamp_duty` | `EXTERNAL` | `JOB` | `85559052527245` |
| `bi_output_dealing_lukka_internal_aggregated` | `EXTERNAL` | `JOB` | `1120995915349000` |
| `bi_output_dealing_manipulation_report_real_stocks` | `EXTERNAL` | `JOB` | `890035936646942` |
| `bi_output_dealing_manipulation_report_real_stocks_cid` | `EXTERNAL` | `JOB` | `890035936646942` |
| `bi_output_dealing_marex_recon_eod` | `EXTERNAL` | `JOB` | `586693656542297` |
| `bi_output_dealing_marex_recon_eod_futures` | `EXTERNAL` | `JOB` | `586693656542297` |
| `bi_output_dealing_marex_recon_trades` | `EXTERNAL` | `JOB` | `586693656542297` |
| `bi_output_dealing_marex_recon_trades_futures` | `EXTERNAL` | `JOB` | `586693656542297` |
| `bi_output_dealing_maxnop_report` | `EXTERNAL` | `JOB` | `541548373598410` |
| `bi_output_dealing_mm_topofbook` | `EXTERNAL` | `JOB` | `869276191161776` |
| `bi_output_dealing_negativebalances` | `EXTERNAL` | `JOB` | `919983786356022` |
| `bi_output_dealing_nhd_dashboard` | `EXTERNAL` | `JOB` | `960051081323166` |
| `bi_output_dealing_nixar_beta_dailybetaprod_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_dealing_nixar_beta_dailybetatarget_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_dealing_nixar_beta_earningscalendar` | `EXTERNAL` | `JOB` | `507885409047840` |
| `bi_output_dealing_nixar_delta_diffusionanalysis_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_dealing_nop_report` | `EXTERNAL` | `JOB` | `729868208506264` |
| `bi_output_dealing_pi_tradinglimitations_clicksize` | `EXTERNAL` | `JOB` | `346494508027063` |
| `bi_output_dealing_premier_clients_2026_positions_report` | `EXTERNAL` | `JOB` | `738479020331210` |
| `bi_output_dealing_premier_clients_report` | `EXTERNAL` | `JOB` | `276911169105228` |
| `bi_output_dealing_premier_clinet_info` | `EXTERNAL` | `JOB` | `195242211459611` |
| `bi_output_dealing_premier_customer` | `EXTERNAL` | `JOB` | `57159445514501` |
| `bi_output_dealing_premier_customer_2026` | `EXTERNAL` | `JOB` | `1058822233960557` |
| `bi_output_dealing_premier_customer_2026_info` | `EXTERNAL` | `JOB` | `738479020331210` |
| `bi_output_dealing_pricespreus_open` | `EXTERNAL` | `JOB` | `191497761331299` |
| `bi_output_dealing_saxo_recon_eod` | `EXTERNAL` | `JOB` | `674979673626499` |
| `bi_output_dealing_saxo_recon_trades` | `EXTERNAL` | `JOB` | `674979673626499` |
| `bi_output_dealing_slippage` | `EXTERNAL` | `JOB` | `1120154298329634` |
| `bi_output_dealing_stocklending_balance_and_transactions_check` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_datalend_data` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_open_loans_recon` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_optin_optout_bny_holdings` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_optin_optout_nop` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_optin_optout_percid` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_optin_optout_percid_isus` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_optin_report_per_cid` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_revenue` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_stocklending_revenue_per_regulation` | `EXTERNAL` | `JOB` | `498315245794462` |
| `bi_output_dealing_tables_bi_db_h_nonpi_highaum` | `EXTERNAL` | `JOB` | `792028385571594` |
| `bi_output_dealing_tables_h_market_manipulation_hourly_report_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_dealing_tables_h_pricelocks_hourly` | `EXTERNAL` | `JOB` | `574133612426560` |
| `bi_output_dealing_tables_h_pricelocks_hourly_report_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_dealing_ubs_saxo_recon_eodholdings` | `EXTERNAL` | `JOB` | `166451544565030` |
| `bi_output_dealing_vision_recon_eod` | `EXTERNAL` | `JOB` | `286367739951792` |
| `bi_output_dealing_vision_recon_trades` | `EXTERNAL` | `JOB` | `286367739951792` |
| `bi_output_dealing_volatility_bucket` | `EXTERNAL` | `JOB` | `284833408776571` |
| `gold_dealing_delta_diffusionanalysis` | `EXTERNAL` | `JOB` | `729784718724350` |
| `gold_dealing_delta_diffusionanalysis_adhoc_v` | `VIEW` | `view_definition` | `view_definition` |
| `gold_dealing_delta_diffusionanalysis_v` | `VIEW` | `view_definition` | `view_definition` |
| `gold_dealing_delta_diffusionanalysisfx` | `EXTERNAL` | `JOB` | `729784718724350` |
| `gold_dealing_delta_diffusionanalysisfx_v` | `VIEW` | `view_definition` | `view_definition` |
| `gold_dealing_delta_diffusionvolatility` | `EXTERNAL` | `JOB` | `527900172329274` |
| `gold_dealing_delta_oms_models_v` | `VIEW` | `view_definition` | `view_definition` |
| `gold_dealing_libra_hscl` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_issettled` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_limitrate` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_opcl` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_parentpositionid` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_stoprate` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_treeid` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_libra_units` | `EXTERNAL` | `JOB` | `475617116052460` |
| `gold_dealing_oms_delta_diffusionanalysis_v` | `VIEW` | `view_definition` | `view_definition` |
| `gold_dealing_oms_internalmarket_imdynamicbookfutures_v` | `VIEW` | `view_definition` | `view_definition` |
| `gold_dealing_oms_internalmarket_multipliers` | `EXTERNAL` | `JOB` | `940047629092362` |
| `gold_dealing_oms_internalmarket_multipliershistory` | `EXTERNAL` | `JOB` | `940047629092362` |
| `gold_dealing_oms_internalmarket_parameters` | `EXTERNAL` | `JOB` | `280567630183` |
| `gold_dealing_oms_internalmarket_parametershistory` | `EXTERNAL` | `JOB` | `280567630183` |
| `newhedgedash_email_csv` | `VIEW` | `view_definition` | `view_definition` |
| `v_hschangesummarylog_yesterday_email_csv` | `VIEW` | `view_definition` | `view_definition` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `bi_output_dealing_2023_check_values` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_2023_euro_check_value` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_alpha_detailed_data` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_bi_db_h_nonpi_highaum` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_h_abookexposure` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_h_currentdayzero` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_nixar_beta_betaconstituencystatus` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_nixar_beta_dailybetaprod` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_nixar_beta_dailybetatarget` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_nixar_delta_diffusionanalysis` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_nixar_delta_diffusionvolatility` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_oms_execution_per_type` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_oms_order_per_type` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_oms_volume_ratio` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_omsinternalmarketsettings` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_prices_stockschangedashboard` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_prices_stockschangedashboard_firststep` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_stocklending_open_loans_recon_old` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_tables_dealing_capitalguarantee` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_tables_h_currentdayzero` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_tables_h_market_manipulation_hourly` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_test_20250306_stocklending_balance_and_transactions_check` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_allfailure` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `gold_dealing_delta_diffusionanalysis_adhoc` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `gold_dealing_delta_diffusionanalysisfx_adhoc` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `gold_dealing_delta_oms_diffusionanalysis` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
