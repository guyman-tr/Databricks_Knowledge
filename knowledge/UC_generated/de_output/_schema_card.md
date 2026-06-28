---
schema: de_output
catalog: main
display_name: de_output — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-06-18T19:12:47Z"
lineage_lookback_days: 90
in_scope_count: 70
out_of_scope_count: 27
objects:
  - name: __materialization_mat_398f46d3_52a9_4b52_9274_9866d065732f_mv_bronze_public_api_operations_1
    full_name: main.de_output.__materialization_mat_398f46d3_52a9_4b52_9274_9866d065732f_mv_bronze_public_api_operations_1
    type: MANAGED
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bronze_event_hub_public_api_operations_evh_failedpublicapioperation
    full_name: main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_event_hub_public_api_operations_evh_successfulpublicapioperation
    full_name: main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: customer_segments_mail_v
    full_name: main.de_output.customer_segments_mail_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output.bi_output_marketing_sfmc_sfmc_report
    refs_source: view_definition (regex extract)
  - name: de_output_allsuccess
    full_name: main.de_output.de_output_allsuccess
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_appsflyer_silver_reports
    full_name: main.de_output.de_output_appsflyer_silver_reports
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 158389157251646
      lineage_source: system.access.table_lineage
      lineage_event_count: 5497
      additional_producers:
        - entity_type: JOB
          entity_id: 519835334562761
          workspace_id: 5263962954799003
          event_count: 103
          first_event_time: "2026-06-10T04:02:24.167000+00:00"
          last_event_time: "2026-06-18T06:10:40.791000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 169483304118515
          workspace_id: 5263962954799003
          event_count: 63
          first_event_time: "2026-06-16T12:29:24.779000+00:00"
          last_event_time: "2026-06-17T09:31:15.401000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 158389157251633
          workspace_id: 5263962954799003
          event_count: 7
          first_event_time: "2026-06-09T10:25:21.883000+00:00"
          last_event_time: "2026-06-09T10:25:28.420000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 158389157251635
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-06-09T10:24:52.559000+00:00"
          last_event_time: "2026-06-09T10:24:52.559000+00:00"
    in_scope: true
  - name: de_output_auto_kb_confluence_runs
    full_name: main.de_output.de_output_auto_kb_confluence_runs
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_auto_kb_dbschema_runs
    full_name: main.de_output.de_output_auto_kb_dbschema_runs
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_auto_kb_genie_runs
    full_name: main.de_output.de_output_auto_kb_genie_runs
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_auto_kb_uc_object_runs
    full_name: main.de_output.de_output_auto_kb_uc_object_runs
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_databricks_metrics_usage_metrics
    full_name: main.de_output.de_output_databricks_metrics_usage_metrics
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_ddr_fact_revenue_generating_actions
    full_name: main.de_output.de_output_ddr_fact_revenue_generating_actions
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 118324841152015
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: JOB
          entity_id: 471149530839890
          workspace_id: 5263962954799003
          event_count: 2
          first_event_time: "2026-05-01T06:04:31.850000+00:00"
          last_event_time: "2026-05-27T13:01:28.210000+00:00"
    in_scope: true
  - name: de_output_details_edit_position_successfully
    full_name: main.de_output.de_output_details_edit_position_successfully
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_failure_to_edit_position
    full_name: main.de_output.de_output_details_failure_to_edit_position
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_failure_to_open_close_position
    full_name: main.de_output.de_output_details_failure_to_open_close_position
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_justified_failures_for_edit_positions
    full_name: main.de_output.de_output_details_justified_failures_for_edit_positions
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_justified_failures_opened_closed
    full_name: main.de_output.de_output_details_justified_failures_opened_closed
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_overall_edit_position_attempts
    full_name: main.de_output.de_output_details_overall_edit_position_attempts
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_overall_open_close_attempts
    full_name: main.de_output.de_output_details_overall_open_close_attempts
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_details_positions_opened_closed_successfuly
    full_name: main.de_output.de_output_details_positions_opened_closed_successfuly
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_etoro_kpi_customer_360_cte_telemetry
    full_name: main.de_output.de_output_etoro_kpi_customer_360_cte_telemetry
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 3527882307866316
      lineage_source: system.access.table_lineage
      lineage_event_count: 42
    in_scope: true
  - name: de_output_etoro_kpi_customer_360_segmentation_for_analysis
    full_name: main.de_output.de_output_etoro_kpi_customer_360_segmentation_for_analysis
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: af043d3b-2b87-467b-8065-6c3b585ec26e
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 9b27e1cf-749d-4d1c-9699-9a9daadff90c
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-06-16T08:35:21.965000+00:00"
          last_event_time: "2026-06-16T08:35:21.965000+00:00"
    in_scope: true
  - name: de_output_etoro_kpi_dim_dataplatform_uuid
    full_name: main.de_output.de_output_etoro_kpi_dim_dataplatform_uuid
    type: EXTERNAL
    writer:
      kind: JOB
      path: 412649002650433
      lineage_source: system.access.table_lineage
      lineage_event_count: 61
    in_scope: true
  - name: de_output_etoro_kpi_fact_customeraction_w_metrics
    full_name: main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
    type: EXTERNAL
    writer:
      kind: JOB
      path: 712655402982749
      lineage_source: system.access.table_lineage
      lineage_event_count: 186
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 0e24356b-64d2-4af6-9d45-7414ed41b7e5
          workspace_id: 5142916747090026
          event_count: 4
          first_event_time: "2026-04-20T10:57:05.248000+00:00"
          last_event_time: "2026-04-20T10:58:29.701000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 1233bc96-436a-421c-9bcf-30b8c62f602c
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-04-20T10:09:16.251000+00:00"
          last_event_time: "2026-04-20T10:52:48.459000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 68a459bd-5e14-40a1-b197-1a9f26430e2e
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-04-29T07:48:44.004000+00:00"
          last_event_time: "2026-04-29T07:49:17.953000+00:00"
    in_scope: true
  - name: de_output_fireblocks_balances
    full_name: main.de_output.de_output_fireblocks_balances
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 1749232405559492
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
    in_scope: true
  - name: de_output_fireblocks_transactions
    full_name: main.de_output.de_output_fireblocks_transactions
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 1749232405559492
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
    in_scope: true
  - name: de_output_general_datalake_monitoirng_tables_status
    full_name: main.de_output.de_output_general_datalake_monitoirng_tables_status
    type: EXTERNAL
    writer:
      kind: JOB
      path: 449184799719926
      lineage_source: system.access.table_lineage
      lineage_event_count: 3067
    in_scope: true
  - name: de_output_generic_pipeline_portal_request_current
    full_name: main.de_output.de_output_generic_pipeline_portal_request_current
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.DE_OUTPUT_Generic_Pipeline_Portal_request_log
    refs_source: view_definition (regex extract)
  - name: de_output_generic_pipeline_portal_request_log
    full_name: main.de_output.de_output_generic_pipeline_portal_request_log
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: badf3146-55e4-47f5-a5dd-06ae9006ef87
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: de_output_genie_code_skill_feedback
    full_name: main.de_output.de_output_genie_code_skill_feedback
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 3117169246886484
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 3117169246886608
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-06-03T12:32:29.930000+00:00"
          last_event_time: "2026-06-03T12:32:29.930000+00:00"
    in_scope: true
  - name: de_output_gold_dealing_dealingstreaming_dealing_netting_delta_history
    full_name: main.de_output.de_output_gold_dealing_dealingstreaming_dealing_netting_delta_history
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_gold_dealing_dealingstreaming_dealing_netting_rates_delta_history
    full_name: main.de_output.de_output_gold_dealing_dealingstreaming_dealing_netting_rates_delta_history
    type: EXTERNAL
    writer:
      kind: JOB
      path: 604185779355459
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: de_output_instruments_firsttradedate
    full_name: main.de_output.de_output_instruments_firsttradedate
    type: EXTERNAL
    writer:
      kind: JOB
      path: 365296296726561
      lineage_source: system.access.table_lineage
      lineage_event_count: 232
    in_scope: true
  - name: de_output_marshall_wace
    full_name: main.de_output.de_output_marshall_wace
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_monitoring_datalake_ddr_monitoring_table
    full_name: main.de_output.de_output_monitoring_datalake_ddr_monitoring_table
    type: EXTERNAL
    writer:
      kind: JOB
      path: 989558415029599
      lineage_source: system.access.table_lineage
      lineage_event_count: 508
    in_scope: true
  - name: de_output_monitoring_datalake_dwh_rep_comparison_results
    full_name: main.de_output.de_output_monitoring_datalake_dwh_rep_comparison_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 754389755627926
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
    in_scope: true
  - name: de_output_monitoring_datalake_history_gaps
    full_name: main.de_output.de_output_monitoring_datalake_history_gaps
    type: EXTERNAL
    writer:
      kind: JOB
      path: 892407812246128
      lineage_source: system.access.table_lineage
      lineage_event_count: 13
    in_scope: true
  - name: de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_long_duration
    full_name: main.de_output.de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_long_duration
    type: EXTERNAL
    writer:
      kind: JOB
      path: 817016827003716
      lineage_source: system.access.table_lineage
      lineage_event_count: 82
    in_scope: true
  - name: de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_not_ended
    full_name: main.de_output.de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_not_ended
    type: EXTERNAL
    writer:
      kind: JOB
      path: 817016827003716
      lineage_source: system.access.table_lineage
      lineage_event_count: 82
    in_scope: true
  - name: de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_not_started
    full_name: main.de_output.de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_not_started
    type: EXTERNAL
    writer:
      kind: JOB
      path: 817016827003716
      lineage_source: system.access.table_lineage
      lineage_event_count: 82
    in_scope: true
  - name: de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_status
    full_name: main.de_output.de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_status
    type: EXTERNAL
    writer:
      kind: JOB
      path: 817016827003716
      lineage_source: system.access.table_lineage
      lineage_event_count: 82
    in_scope: true
  - name: de_output_monitoring_datalake_log_analytics_to_datalake_results_databricks_batch_jobs_status
    full_name: main.de_output.de_output_monitoring_datalake_log_analytics_to_datalake_results_databricks_batch_jobs_status
    type: EXTERNAL
    writer:
      kind: JOB
      path: 817016827003716
      lineage_source: system.access.table_lineage
      lineage_event_count: 82
    in_scope: true
  - name: de_output_monitoring_datalake_log_analytics_to_datalake_results_test_adf_internal_pipelines_status
    full_name: main.de_output.de_output_monitoring_datalake_log_analytics_to_datalake_results_test_adf_internal_pipelines_status
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_monitoring_datalake_quality_gates_completeness_check_etorodb
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_completeness_check_etorodb
    type: EXTERNAL
    writer:
      kind: JOB
      path: 201290813947770
      lineage_source: system.access.table_lineage
      lineage_event_count: 90
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_completeness_check_generic_pipeline_etorodb
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_completeness_check_generic_pipeline_etorodb
    type: EXTERNAL
    writer:
      kind: JOB
      path: 796679698865421
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_completeness_sumcheck_etorodb
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_completeness_sumcheck_etorodb
    type: EXTERNAL
    writer:
      kind: JOB
      path: 859199655410779
      lineage_source: system.access.table_lineage
      lineage_event_count: 4580
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 2985795542970987
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-03-26T13:10:13.091000+00:00"
          last_event_time: "2026-03-26T13:10:13.091000+00:00"
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_copylaketosynapse_checks_results
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_copylaketosynapse_checks_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 567448773814962
      lineage_source: system.access.table_lineage
      lineage_event_count: 92
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_dwh_daily_checks_results
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_dwh_daily_checks_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 808866227312559
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_dwh_daily_dict_checks_results
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_dwh_daily_dict_checks_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 808866227312559
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_generic_pipeline_checks_results
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_generic_pipeline_checks_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 576508095116194
      lineage_source: system.access.table_lineage
      lineage_event_count: 2158
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_synapse_checks_results
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_synapse_checks_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 689456980704271
      lineage_source: system.access.table_lineage
      lineage_event_count: 90
    in_scope: true
  - name: de_output_monitoring_datalake_quality_gates_synapse_dl_rowcount_results
    full_name: main.de_output.de_output_monitoring_datalake_quality_gates_synapse_dl_rowcount_results
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1043748250965115
      lineage_source: system.access.table_lineage
      lineage_event_count: 61
    in_scope: true
  - name: de_output_monitoring_datalake_record_amounts_append_tables
    full_name: main.de_output.de_output_monitoring_datalake_record_amounts_append_tables
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_monitoring_datalake_record_amounts_override_tables
    full_name: main.de_output.de_output_monitoring_datalake_record_amounts_override_tables
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_monitoring_delta_project_errored_messages
    full_name: main.de_output.de_output_monitoring_delta_project_errored_messages
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_monitoring_genies_views_conversion_agent_genie_view_checks
    full_name: main.de_output.de_output_monitoring_genies_views_conversion_agent_genie_view_checks
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1074369647150068
      lineage_source: system.access.table_lineage
      lineage_event_count: 23
    in_scope: true
  - name: de_output_monitoring_genies_views_raf_genie_views_checks
    full_name: main.de_output.de_output_monitoring_genies_views_raf_genie_views_checks
    type: EXTERNAL
    writer:
      kind: JOB
      path: 762815398970258
      lineage_source: system.access.table_lineage
      lineage_event_count: 22
    in_scope: true
  - name: de_output_onboarding_ev_cohort_enriched
    full_name: main.de_output.de_output_onboarding_ev_cohort_enriched
    type: EXTERNAL
    writer:
      kind: JOB
      path: 445677398446495
      lineage_source: system.access.table_lineage
      lineage_event_count: 630
    in_scope: true
  - name: de_output_position_datafactory_test
    full_name: main.de_output.de_output_position_datafactory_test
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_risk_classification
    full_name: main.de_output.de_output_risk_classification
    type: EXTERNAL
    writer:
      kind: JOB
      path: 367713536523386
      lineage_source: system.access.table_lineage
      lineage_event_count: 342
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 670974923114318
          workspace_id: 5263962954799003
          event_count: 4
          first_event_time: "2026-04-15T11:10:47.138000+00:00"
          last_event_time: "2026-04-15T11:10:47.138000+00:00"
    in_scope: true
  - name: de_output_risk_classification_cysec
    full_name: main.de_output.de_output_risk_classification_cysec
    type: EXTERNAL
    writer:
      kind: JOB
      path: 556141872175535
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
      additional_producers:
        - entity_type: JOB
          entity_id: 368517172397505
          workspace_id: 5263962954799003
          event_count: 3
          first_event_time: "2026-04-27T02:07:23.568000+00:00"
          last_event_time: "2026-04-27T02:09:19.454000+00:00"
        - entity_type: JOB
          entity_id: 819215938447
          workspace_id: 5263962954799003
          event_count: 3
          first_event_time: "2026-03-23T02:17:45.004000+00:00"
          last_event_time: "2026-03-23T02:19:25.665000+00:00"
        - entity_type: JOB
          entity_id: 629670895668878
          workspace_id: 5263962954799003
          event_count: 3
          first_event_time: "2026-03-30T02:15:38.366000+00:00"
          last_event_time: "2026-03-30T02:17:10.886000+00:00"
        - entity_type: JOB
          entity_id: 435374380747109
          workspace_id: 5263962954799003
          event_count: 3
          first_event_time: "2026-04-23T06:17:07.669000+00:00"
          last_event_time: "2026-04-23T06:18:40.813000+00:00"
    in_scope: true
  - name: de_output_risk_classification_history
    full_name: main.de_output.de_output_risk_classification_history
    type: EXTERNAL
    writer:
      kind: JOB
      path: 367713536523386
      lineage_source: system.access.table_lineage
      lineage_event_count: 325
    in_scope: true
  - name: de_output_risk_classification_history_cysec
    full_name: main.de_output.de_output_risk_classification_history_cysec
    type: EXTERNAL
    writer:
      kind: JOB
      path: 556141872175535
      lineage_source: system.access.table_lineage
      lineage_event_count: 6
      additional_producers:
        - entity_type: JOB
          entity_id: 435374380747109
          workspace_id: 5263962954799003
          event_count: 6
          first_event_time: "2026-04-23T06:19:00.010000+00:00"
          last_event_time: "2026-04-23T06:19:39.497000+00:00"
        - entity_type: JOB
          entity_id: 368517172397505
          workspace_id: 5263962954799003
          event_count: 6
          first_event_time: "2026-04-27T02:11:13.016000+00:00"
          last_event_time: "2026-04-27T02:11:51.695000+00:00"
        - entity_type: JOB
          entity_id: 819215938447
          workspace_id: 5263962954799003
          event_count: 6
          first_event_time: "2026-03-23T02:20:59.977000+00:00"
          last_event_time: "2026-03-23T02:21:40.228000+00:00"
        - entity_type: JOB
          entity_id: 629670895668878
          workspace_id: 5263962954799003
          event_count: 6
          first_event_time: "2026-03-30T02:18:46.505000+00:00"
          last_event_time: "2026-03-30T02:19:31.494000+00:00"
    in_scope: true
  - name: de_output_risk_classification_scores
    full_name: main.de_output.de_output_risk_classification_scores
    type: EXTERNAL
    writer:
      kind: JOB
      path: 367713536523386
      lineage_source: system.access.table_lineage
      lineage_event_count: 111
    in_scope: true
  - name: de_output_semantic_column_descriptions_bank
    full_name: main.de_output.de_output_semantic_column_descriptions_bank
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 2912256059591267
      lineage_source: system.access.table_lineage
      lineage_event_count: 52
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 448599523609643
          workspace_id: 5142916747090026
          event_count: 5
          first_event_time: "2026-05-17T12:59:53.200000+00:00"
          last_event_time: "2026-05-17T13:35:23.707000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 2527950559640120
          workspace_id: 5142916747090026
          event_count: 5
          first_event_time: "2026-05-17T09:05:12.121000+00:00"
          last_event_time: "2026-05-17T10:52:51.907000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 2912256059591011
          workspace_id: 5142916747090026
          event_count: 4
          first_event_time: "2026-05-08T08:23:53.453000+00:00"
          last_event_time: "2026-05-10T08:48:31.901000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 3853551604280702
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-05-12T13:50:13.207000+00:00"
          last_event_time: "2026-05-13T08:45:33.503000+00:00"
    in_scope: true
  - name: de_output_semantic_column_descriptions_deploy_log
    full_name: main.de_output.de_output_semantic_column_descriptions_deploy_log
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 2912256059591267
      lineage_source: system.access.table_lineage
      lineage_event_count: 27
    in_scope: true
  - name: de_output_semantic_column_descriptions_purge_log
    full_name: main.de_output.de_output_semantic_column_descriptions_purge_log
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 2912256059591011
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
    in_scope: true
  - name: de_output_semantic_column_descriptions_rollback
    full_name: main.de_output.de_output_semantic_column_descriptions_rollback
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 2912256059591267
      lineage_source: system.access.table_lineage
      lineage_event_count: 4
    in_scope: true
  - name: de_output_semantic_column_descriptions_work_queue
    full_name: main.de_output.de_output_semantic_column_descriptions_work_queue
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 2912256059591267
      lineage_source: system.access.table_lineage
      lineage_event_count: 151
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 448599523609643
          workspace_id: 5142916747090026
          event_count: 5
          first_event_time: "2026-05-17T12:59:55.318000+00:00"
          last_event_time: "2026-05-17T13:35:24.563000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 2527950559640120
          workspace_id: 5142916747090026
          event_count: 3
          first_event_time: "2026-05-17T09:05:18.642000+00:00"
          last_event_time: "2026-05-17T10:48:33.330000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 3853551604280702
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-05-12T13:50:15.281000+00:00"
          last_event_time: "2026-05-13T08:46:08.433000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 2912256059591011
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-08T14:11:29.545000+00:00"
          last_event_time: "2026-05-08T14:11:29.545000+00:00"
    in_scope: true
  - name: de_output_silver_appsflyer_raw_in_app_events
    full_name: main.de_output.de_output_silver_appsflyer_raw_in_app_events
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 169483304118522
      lineage_source: system.access.table_lineage
      lineage_event_count: 4
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 169483304118773
          workspace_id: 5263962954799003
          event_count: 4
          first_event_time: "2026-06-17T09:03:58.318000+00:00"
          last_event_time: "2026-06-17T09:07:22.437000+00:00"
    in_scope: true
  - name: de_output_silver_appsflyer_raw_installs
    full_name: main.de_output.de_output_silver_appsflyer_raw_installs
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 169483304118522
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 169483304118773
          workspace_id: 5263962954799003
          event_count: 4
          first_event_time: "2026-06-17T09:03:35.340000+00:00"
          last_event_time: "2026-06-17T09:06:15.196000+00:00"
    in_scope: true
  - name: de_output_silver_appsflyer_raw_organic_in_app_events
    full_name: main.de_output.de_output_silver_appsflyer_raw_organic_in_app_events
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 169483304118522
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
    in_scope: true
  - name: de_output_silver_appsflyer_raw_organic_installs
    full_name: main.de_output.de_output_silver_appsflyer_raw_organic_installs
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 169483304118773
      lineage_source: system.access.table_lineage
      lineage_event_count: 4
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 169483304118522
          workspace_id: 5263962954799003
          event_count: 3
          first_event_time: "2026-06-17T07:34:53.896000+00:00"
          last_event_time: "2026-06-17T07:43:43.659000+00:00"
    in_scope: true
  - name: de_output_skills_automation_user_suggestions_agent
    full_name: main.de_output.de_output_skills_automation_user_suggestions_agent
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_summary_edit_position_success_rate
    full_name: main.de_output.de_output_summary_edit_position_success_rate
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_summary_open_close_position_success_rate
    full_name: main.de_output.de_output_summary_open_close_position_success_rate
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: de_output_trading_crypto_volume_fee_tier
    full_name: main.de_output.de_output_trading_crypto_volume_fee_tier
    type: EXTERNAL
    writer:
      kind: JOB
      path: 760759824197003
      lineage_source: system.access.table_lineage
      lineage_event_count: 595
      additional_producers:
        - entity_type: JOB
          entity_id: 844382279060709
          workspace_id: 6256398679555083
          event_count: 7
          first_event_time: "2026-03-25T14:29:18.524000+00:00"
          last_event_time: "2026-04-28T13:17:10.068000+00:00"
    in_scope: true
  - name: de_output_trading_crypto_volume_fee_tier_conf
    full_name: main.de_output.de_output_trading_crypto_volume_fee_tier_conf
    type: EXTERNAL
    writer:
      kind: JOB
      path: 844382279060709
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 0796e548-4ecb-4869-a8a2-17fa60b2c6d8
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-04-09T11:31:18.350000+00:00"
          last_event_time: "2026-04-09T11:31:18.350000+00:00"
    in_scope: true
  - name: de_output_trading_crypto_volume_fee_tier_log
    full_name: main.de_output.de_output_trading_crypto_volume_fee_tier_log
    type: EXTERNAL
    writer:
      kind: JOB
      path: 760759824197003
      lineage_source: system.access.table_lineage
      lineage_event_count: 151
      additional_producers:
        - entity_type: JOB
          entity_id: 844382279060709
          workspace_id: 6256398679555083
          event_count: 7
          first_event_time: "2026-03-25T14:29:16.194000+00:00"
          last_event_time: "2026-04-28T13:17:14.520000+00:00"
    in_scope: true
  - name: de_output_user_aquisition_upper_funnel
    full_name: main.de_output.de_output_user_aquisition_upper_funnel
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_v_appsflyer_per_user
      - main.de_output_stg.googleanalytics_acquisitionuserbehaviour
      - main.ml_stg.ml_output_ltv_phase_ltv
      - main.etoro_kpi.ftd_funnel_v
    refs_source: view_definition (regex extract)
  - name: de_output_v_appsflyer_not_registered
    full_name: main.de_output.de_output_v_appsflyer_not_registered
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_appsflyer_silver_reports
    refs_source: view_definition (regex extract)
  - name: de_output_v_appsflyer_per_user
    full_name: main.de_output.de_output_v_appsflyer_per_user
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_appsflyer_silver_reports
    refs_source: view_definition (regex extract)
  - name: de_output_voice_of_the_customer_comments
    full_name: main.de_output.de_output_voice_of_the_customer_comments
    type: EXTERNAL
    writer:
      kind: JOB
      path: 500460526742780
      lineage_source: system.access.table_lineage
      lineage_event_count: 72
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 41025a96-006f-4e6b-ab93-71b5b34155a3
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-04-08T16:09:56.958000+00:00"
          last_event_time: "2026-04-08T16:09:56.958000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: b2419baf-1881-4f58-807a-6264515246fe
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-04-04T19:16:58.562000+00:00"
          last_event_time: "2026-04-04T19:16:58.562000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 86ea55f4-5c14-4c52-8950-eefac916cc22
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-04-29T12:32:16.908000+00:00"
          last_event_time: "2026-04-29T12:32:16.908000+00:00"
    in_scope: true
  - name: de_output_voice_of_the_customer_feeds
    full_name: main.de_output.de_output_voice_of_the_customer_feeds
    type: EXTERNAL
    writer:
      kind: JOB
      path: 306257206850667
      lineage_source: system.access.table_lineage
      lineage_event_count: 363
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 41025a96-006f-4e6b-ab93-71b5b34155a3
          workspace_id: 5263962954799003
          event_count: 2
          first_event_time: "2026-03-21T18:40:12.285000+00:00"
          last_event_time: "2026-03-21T22:00:08.437000+00:00"
    in_scope: true
  - name: de_output_voice_of_the_customer_messagingsession
    full_name: main.de_output.de_output_voice_of_the_customer_messagingsession
    type: EXTERNAL
    writer:
      kind: JOB
      path: 3235178432582
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 41025a96-006f-4e6b-ab93-71b5b34155a3
          workspace_id: 5263962954799003
          event_count: 2
          first_event_time: "2026-03-21T17:31:03.967000+00:00"
          last_event_time: "2026-03-21T20:53:17.329000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 86ea55f4-5c14-4c52-8950-eefac916cc22
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-04-29T12:28:23.946000+00:00"
          last_event_time: "2026-04-29T12:28:23.946000+00:00"
    in_scope: true
  - name: de_output_voice_of_the_customer_torii
    full_name: main.de_output.de_output_voice_of_the_customer_torii
    type: MANAGED
    writer:
      kind: JOB
      path: 741882925486902
      lineage_source: system.access.table_lineage
      lineage_event_count: 37
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 41025a96-006f-4e6b-ab93-71b5b34155a3
          workspace_id: 5263962954799003
          event_count: 2
          first_event_time: "2026-03-23T11:05:28.636000+00:00"
          last_event_time: "2026-03-23T17:09:01.797000+00:00"
    in_scope: true
  - name: de_output_voice_of_the_customer_torii_new
    full_name: main.de_output.de_output_voice_of_the_customer_torii_new
    type: EXTERNAL
    writer:
      kind: JOB
      path: 597812824003564
      lineage_source: system.access.table_lineage
      lineage_event_count: 54
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: f4cae702-da72-43cf-b5e1-7ba6ffa21c64
          workspace_id: 5263962954799003
          event_count: 3
          first_event_time: "2026-04-25T08:56:29.383000+00:00"
          last_event_time: "2026-04-25T13:23:58.669000+00:00"
    in_scope: true
  - name: event_log_398f46d3_52a9_4b52_9274_9866d065732f
    full_name: main.de_output.event_log_398f46d3_52a9_4b52_9274_9866d065732f
    type: MANAGED
    writer:
      kind: PIPELINE
      path: 398f46d3-52a9-4b52-9274-9866d065732f
      lineage_source: system.access.table_lineage
      lineage_event_count: 342
    in_scope: true
  - name: gold_torii_lakebase
    full_name: main.de_output.gold_torii_lakebase
    type: EXTERNAL
    writer:
      kind: JOB
      path: 958670595626717
      lineage_source: system.access.table_lineage
      lineage_event_count: 812
      additional_producers:
        - entity_type: JOB
          entity_id: 821594184953532
          workspace_id: 5263962954799003
          event_count: 132
          first_event_time: "2026-06-11T11:01:05.366000+00:00"
          last_event_time: "2026-06-18T17:01:32.482000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 964064147333151
          workspace_id: 6256398679555083
          event_count: 1
          first_event_time: "2026-06-11T10:33:48.256000+00:00"
          last_event_time: "2026-06-11T10:33:48.256000+00:00"
    in_scope: true
  - name: monitoring_schema_history
    full_name: main.de_output.monitoring_schema_history
    type: EXTERNAL
    writer:
      kind: JOB
      path: 928786759970333
      lineage_source: system.access.table_lineage
      lineage_event_count: 13104
      additional_producers:
        - entity_type: JOB
          entity_id: 973601068713167
          workspace_id: 5263962954799003
          event_count: 13100
          first_event_time: "2026-04-28T03:43:54.699000+00:00"
          last_event_time: "2026-06-18T05:34:13.806000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 28a65a86-3183-47c7-993a-9095c484e4da
          workspace_id: 5142916747090026
          event_count: 2
          first_event_time: "2026-04-15T11:04:19.707000+00:00"
          last_event_time: "2026-04-26T13:31:35.913000+00:00"
    in_scope: true
  - name: mv_bronze_public_api_operations
    full_name: main.de_output.mv_bronze_public_api_operations
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.vw_bronze_failed_public_api_operations_with_errors
      - main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.general.bronze_etoro_dictionary_country
      - main.general.bronze_etoro_dictionary_region
      - main.general.bronze_etoro_dictionary_playerlevel
      - main.dwh.dim_position
    refs_source: view_definition (regex extract)
  - name: riskscore_classification_history_v
    full_name: main.de_output.riskscore_classification_history_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_risk_classification_history
    refs_source: view_definition (regex extract)
  - name: v_de_output_appsflyer_installs
    full_name: main.de_output.v_de_output_appsflyer_installs
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_appsflyer_silver_reports
    refs_source: view_definition (regex extract)
  - name: vw_bronze_failed_public_api_operations_with_errors
    full_name: main.de_output.vw_bronze_failed_public_api_operations_with_errors
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.bronze_event_hub_public_api_operations_evh_failedpublicapioperation
    refs_source: view_definition (regex extract)
  - name: vw_bronze_public_api_operations
    full_name: main.de_output.vw_bronze_public_api_operations
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.vw_bronze_failed_public_api_operations_with_errors
      - main.de_output.bronze_event_hub_public_api_operations_evh_successfulpublicapioperation
    refs_source: view_definition (regex extract)
  - name: vw_risk_classification_history_complete
    full_name: main.de_output.vw_risk_classification_history_complete
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_risk_classification_history
      - main.de_output.de_output_risk_classification
    refs_source: view_definition (regex extract)
  - name: vw_trading_crypto_volume_fee_tier_to_sfmc
    full_name: main.de_output.vw_trading_crypto_volume_fee_tier_to_sfmc
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.de_output.de_output_trading_crypto_volume_fee_tier_log
      - main.de_output.de_output_trading_crypto_volume_fee_tier
    refs_source: view_definition (regex extract)
---

# de_output — Schema Card

> UC-Pipeline scope sheet for `main.de_output`. **70 in-scope** / **27 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `customer_segments_mail_v` | `VIEW` | `view_definition` | `view_definition` |
| `de_output_appsflyer_silver_reports` | `EXTERNAL` | `NOTEBOOK` | `158389157251646` |
| `de_output_ddr_fact_revenue_generating_actions` | `EXTERNAL` | `NOTEBOOK` | `118324841152015` |
| `de_output_etoro_kpi_customer_360_cte_telemetry` | `EXTERNAL` | `NOTEBOOK` | `3527882307866316` |
| `de_output_etoro_kpi_customer_360_segmentation_for_analysis` | `EXTERNAL` | `DBSQL_QUERY` | `af043d3b-2b87-467b-8065-6c3b585ec26e` |
| `de_output_etoro_kpi_dim_dataplatform_uuid` | `EXTERNAL` | `JOB` | `412649002650433` |
| `de_output_etoro_kpi_fact_customeraction_w_metrics` | `EXTERNAL` | `JOB` | `712655402982749` |
| `de_output_fireblocks_balances` | `EXTERNAL` | `NOTEBOOK` | `1749232405559492` |
| `de_output_fireblocks_transactions` | `EXTERNAL` | `NOTEBOOK` | `1749232405559492` |
| `de_output_general_datalake_monitoirng_tables_status` | `EXTERNAL` | `JOB` | `449184799719926` |
| `de_output_generic_pipeline_portal_request_current` | `VIEW` | `view_definition` | `view_definition` |
| `de_output_generic_pipeline_portal_request_log` | `EXTERNAL` | `DBSQL_QUERY` | `badf3146-55e4-47f5-a5dd-06ae9006ef87` |
| `de_output_genie_code_skill_feedback` | `EXTERNAL` | `NOTEBOOK` | `3117169246886484` |
| `de_output_gold_dealing_dealingstreaming_dealing_netting_rates_delta_history` | `EXTERNAL` | `JOB` | `604185779355459` |
| `de_output_instruments_firsttradedate` | `EXTERNAL` | `JOB` | `365296296726561` |
| `de_output_monitoring_datalake_ddr_monitoring_table` | `EXTERNAL` | `JOB` | `989558415029599` |
| `de_output_monitoring_datalake_dwh_rep_comparison_results` | `EXTERNAL` | `JOB` | `754389755627926` |
| `de_output_monitoring_datalake_history_gaps` | `EXTERNAL` | `JOB` | `892407812246128` |
| `de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_long_duration` | `EXTERNAL` | `JOB` | `817016827003716` |
| `de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_not_ended` | `EXTERNAL` | `JOB` | `817016827003716` |
| `de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_not_started` | `EXTERNAL` | `JOB` | `817016827003716` |
| `de_output_monitoring_datalake_log_analytics_to_datalake_results_adf_internal_pipelines_status` | `EXTERNAL` | `JOB` | `817016827003716` |
| `de_output_monitoring_datalake_log_analytics_to_datalake_results_databricks_batch_jobs_status` | `EXTERNAL` | `JOB` | `817016827003716` |
| `de_output_monitoring_datalake_quality_gates_completeness_check_etorodb` | `EXTERNAL` | `JOB` | `201290813947770` |
| `de_output_monitoring_datalake_quality_gates_completeness_check_generic_pipeline_etorodb` | `EXTERNAL` | `JOB` | `796679698865421` |
| `de_output_monitoring_datalake_quality_gates_completeness_sumcheck_etorodb` | `EXTERNAL` | `JOB` | `859199655410779` |
| `de_output_monitoring_datalake_quality_gates_copylaketosynapse_checks_results` | `EXTERNAL` | `JOB` | `567448773814962` |
| `de_output_monitoring_datalake_quality_gates_dwh_daily_checks_results` | `EXTERNAL` | `JOB` | `808866227312559` |
| `de_output_monitoring_datalake_quality_gates_dwh_daily_dict_checks_results` | `EXTERNAL` | `JOB` | `808866227312559` |
| `de_output_monitoring_datalake_quality_gates_generic_pipeline_checks_results` | `EXTERNAL` | `JOB` | `576508095116194` |
| `de_output_monitoring_datalake_quality_gates_synapse_checks_results` | `EXTERNAL` | `JOB` | `689456980704271` |
| `de_output_monitoring_datalake_quality_gates_synapse_dl_rowcount_results` | `EXTERNAL` | `JOB` | `1043748250965115` |
| `de_output_monitoring_genies_views_conversion_agent_genie_view_checks` | `EXTERNAL` | `JOB` | `1074369647150068` |
| `de_output_monitoring_genies_views_raf_genie_views_checks` | `EXTERNAL` | `JOB` | `762815398970258` |
| `de_output_onboarding_ev_cohort_enriched` | `EXTERNAL` | `JOB` | `445677398446495` |
| `de_output_risk_classification` | `EXTERNAL` | `JOB` | `367713536523386` |
| `de_output_risk_classification_cysec` | `EXTERNAL` | `JOB` | `556141872175535` |
| `de_output_risk_classification_history` | `EXTERNAL` | `JOB` | `367713536523386` |
| `de_output_risk_classification_history_cysec` | `EXTERNAL` | `JOB` | `556141872175535` |
| `de_output_risk_classification_scores` | `EXTERNAL` | `JOB` | `367713536523386` |
| `de_output_semantic_column_descriptions_bank` | `EXTERNAL` | `NOTEBOOK` | `2912256059591267` |
| `de_output_semantic_column_descriptions_deploy_log` | `EXTERNAL` | `NOTEBOOK` | `2912256059591267` |
| `de_output_semantic_column_descriptions_purge_log` | `EXTERNAL` | `NOTEBOOK` | `2912256059591011` |
| `de_output_semantic_column_descriptions_rollback` | `EXTERNAL` | `NOTEBOOK` | `2912256059591267` |
| `de_output_semantic_column_descriptions_work_queue` | `EXTERNAL` | `NOTEBOOK` | `2912256059591267` |
| `de_output_silver_appsflyer_raw_in_app_events` | `EXTERNAL` | `NOTEBOOK` | `169483304118522` |
| `de_output_silver_appsflyer_raw_installs` | `EXTERNAL` | `NOTEBOOK` | `169483304118522` |
| `de_output_silver_appsflyer_raw_organic_in_app_events` | `EXTERNAL` | `NOTEBOOK` | `169483304118522` |
| `de_output_silver_appsflyer_raw_organic_installs` | `EXTERNAL` | `NOTEBOOK` | `169483304118773` |
| `de_output_trading_crypto_volume_fee_tier` | `EXTERNAL` | `JOB` | `760759824197003` |
| `de_output_trading_crypto_volume_fee_tier_conf` | `EXTERNAL` | `JOB` | `844382279060709` |
| `de_output_trading_crypto_volume_fee_tier_log` | `EXTERNAL` | `JOB` | `760759824197003` |
| `de_output_user_aquisition_upper_funnel` | `VIEW` | `view_definition` | `view_definition` |
| `de_output_v_appsflyer_not_registered` | `VIEW` | `view_definition` | `view_definition` |
| `de_output_v_appsflyer_per_user` | `VIEW` | `view_definition` | `view_definition` |
| `de_output_voice_of_the_customer_comments` | `EXTERNAL` | `JOB` | `500460526742780` |
| `de_output_voice_of_the_customer_feeds` | `EXTERNAL` | `JOB` | `306257206850667` |
| `de_output_voice_of_the_customer_messagingsession` | `EXTERNAL` | `JOB` | `3235178432582` |
| `de_output_voice_of_the_customer_torii` | `MANAGED` | `JOB` | `741882925486902` |
| `de_output_voice_of_the_customer_torii_new` | `EXTERNAL` | `JOB` | `597812824003564` |
| `event_log_398f46d3_52a9_4b52_9274_9866d065732f` | `MANAGED` | `PIPELINE` | `398f46d3-52a9-4b52-9274-9866d065732f` |
| `gold_torii_lakebase` | `EXTERNAL` | `JOB` | `958670595626717` |
| `monitoring_schema_history` | `EXTERNAL` | `JOB` | `928786759970333` |
| `mv_bronze_public_api_operations` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `riskscore_classification_history_v` | `VIEW` | `view_definition` | `view_definition` |
| `v_de_output_appsflyer_installs` | `VIEW` | `view_definition` | `view_definition` |
| `vw_bronze_failed_public_api_operations_with_errors` | `VIEW` | `view_definition` | `view_definition` |
| `vw_bronze_public_api_operations` | `VIEW` | `view_definition` | `view_definition` |
| `vw_risk_classification_history_complete` | `VIEW` | `view_definition` | `view_definition` |
| `vw_trading_crypto_volume_fee_tier_to_sfmc` | `VIEW` | `view_definition` | `view_definition` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `__materialization_mat_398f46d3_52a9_4b52_9274_9866d065732f_mv_bronze_public_api_operations_1` | `MANAGED` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bronze_event_hub_public_api_operations_evh_failedpublicapioperation` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_event_hub_public_api_operations_evh_successfulpublicapioperation` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `de_output_allsuccess` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_auto_kb_confluence_runs` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_auto_kb_dbschema_runs` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_auto_kb_genie_runs` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_auto_kb_uc_object_runs` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_databricks_metrics_usage_metrics` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_edit_position_successfully` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_failure_to_edit_position` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_failure_to_open_close_position` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_justified_failures_for_edit_positions` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_justified_failures_opened_closed` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_overall_edit_position_attempts` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_overall_open_close_attempts` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_details_positions_opened_closed_successfuly` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_gold_dealing_dealingstreaming_dealing_netting_delta_history` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_marshall_wace` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_monitoring_datalake_log_analytics_to_datalake_results_test_adf_internal_pipelines_status` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_monitoring_datalake_record_amounts_append_tables` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_monitoring_datalake_record_amounts_override_tables` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_monitoring_delta_project_errored_messages` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_position_datafactory_test` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_skills_automation_user_suggestions_agent` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_summary_edit_position_success_rate` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `de_output_summary_open_close_position_success_rate` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
