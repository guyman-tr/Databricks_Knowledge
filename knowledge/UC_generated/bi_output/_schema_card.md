---
schema: bi_output
catalog: main
display_name: bi_output — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-18T07:02:44Z"
lineage_lookback_days: 90
in_scope_count: 123
out_of_scope_count: 21
objects:
  - name: bi_ouput_mvg_etoro_emoney
    full_name: main.bi_output.bi_ouput_mvg_etoro_emoney
    type: METRIC_VIEW
    writer:
      kind: UNKNOWN
      reason: VIEW has empty view_definition (catalog metadata broken)
    in_scope: false
    reason: VIEW has empty view_definition (catalog metadata broken)
  - name: bi_ouput_v_dim_instrumenttype
    full_name: main.bi_output.bi_ouput_v_dim_instrumenttype
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_etoro_dictionary_currencytype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: bi_ouput_vg_etoro_emoney
    full_name: main.bi_output.bi_ouput_vg_etoro_emoney
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
      - dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
      - bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
      - bi_db.bronze_moneytransfer_billing_transfers
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: bi_output_compliance_kycscreeninglimitation
    full_name: main.bi_output.bi_output_compliance_kycscreeninglimitation
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 982b26eb-dea3-4ee6-847b-81a6b3aa146d
      lineage_source: system.access.table_lineage
      lineage_event_count: 1157
    in_scope: true
  - name: bi_output_customer_compliance_mas_daily_client_metrics
    full_name: main.bi_output.bi_output_customer_compliance_mas_daily_client_metrics
    type: EXTERNAL
    writer:
      kind: JOB
      path: 623823172493742
      lineage_source: system.access.table_lineage
      lineage_event_count: 12
      additional_producers:
        - entity_type: JOB
          entity_id: 940506278148787
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-05T04:16:32.851000+00:00"
          last_event_time: "2026-05-05T04:16:32.851000+00:00"
        - entity_type: JOB
          entity_id: 888499728849435
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-01T04:17:18.557000+00:00"
          last_event_time: "2026-05-01T04:17:18.557000+00:00"
        - entity_type: JOB
          entity_id: 533867685279299
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-12T04:31:47.234000+00:00"
          last_event_time: "2026-05-12T04:31:47.234000+00:00"
        - entity_type: JOB
          entity_id: 945201763620557
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-07T04:47:56.768000+00:00"
          last_event_time: "2026-05-07T04:47:56.768000+00:00"
    in_scope: true
  - name: bi_output_customer_compliance_mas_population
    full_name: main.bi_output.bi_output_customer_compliance_mas_population
    type: EXTERNAL
    writer:
      kind: JOB
      path: 449767041129740
      lineage_source: system.access.table_lineage
      lineage_event_count: 25
      additional_producers:
        - entity_type: JOB
          entity_id: 736335922052430
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-04-14T06:45:07.614000+00:00"
          last_event_time: "2026-04-14T06:45:07.614000+00:00"
        - entity_type: JOB
          entity_id: 628158787172301
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-05-09T09:25:00.915000+00:00"
          last_event_time: "2026-05-09T09:25:00.915000+00:00"
        - entity_type: JOB
          entity_id: 805356250031497
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-04-05T05:57:25.163000+00:00"
          last_event_time: "2026-04-05T05:57:25.163000+00:00"
        - entity_type: JOB
          entity_id: 865384098106911
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-04-13T06:36:27.539000+00:00"
          last_event_time: "2026-04-13T06:36:27.539000+00:00"
    in_scope: true
  - name: bi_output_customer_compliance_uk_social_activity_monitoring
    full_name: main.bi_output.bi_output_customer_compliance_uk_social_activity_monitoring
    type: EXTERNAL
    writer:
      kind: JOB
      path: 938227598135468
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
      additional_producers:
        - entity_type: JOB
          entity_id: 256653498237148
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-02-28T04:28:23.703000+00:00"
          last_event_time: "2026-02-28T04:28:23.703000+00:00"
        - entity_type: JOB
          entity_id: 193206216692202
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-03-01T04:43:22.203000+00:00"
          last_event_time: "2026-03-01T04:43:22.203000+00:00"
        - entity_type: JOB
          entity_id: 392817602714607
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-02-22T04:40:44.160000+00:00"
          last_event_time: "2026-02-22T04:40:44.160000+00:00"
        - entity_type: JOB
          entity_id: 994672230455684
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-02-27T04:28:10.137000+00:00"
          last_event_time: "2026-02-27T04:28:10.137000+00:00"
    in_scope: true
  - name: bi_output_customer_compliance_uk_social_activity_monitoring_m
    full_name: main.bi_output.bi_output_customer_compliance_uk_social_activity_monitoring_m
    type: EXTERNAL
    writer:
      kind: JOB
      path: 949872433798828
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: JOB
          entity_id: 497762815369327
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-04-25T05:04:10.868000+00:00"
          last_event_time: "2026-04-25T05:04:10.868000+00:00"
        - entity_type: JOB
          entity_id: 791139996560857
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-03-04T04:35:10.072000+00:00"
          last_event_time: "2026-03-04T04:35:10.072000+00:00"
        - entity_type: JOB
          entity_id: 968807785808541
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-04-16T05:07:15.403000+00:00"
          last_event_time: "2026-04-16T05:07:15.403000+00:00"
        - entity_type: JOB
          entity_id: 436710960468868
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-04-17T05:03:05.717000+00:00"
          last_event_time: "2026-04-17T05:03:05.717000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_agent_engagement
    full_name: main.bi_output.bi_output_customer_customer_facing_agent_engagement
    type: EXTERNAL
    writer:
      kind: JOB
      path: 717988584710279
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 900484248914922
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-09T04:51:09.438000+00:00"
          last_event_time: "2026-03-09T04:51:34.140000+00:00"
        - entity_type: JOB
          entity_id: 652763919191275
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-07T05:49:56.465000+00:00"
          last_event_time: "2026-05-07T05:50:24.171000+00:00"
        - entity_type: JOB
          entity_id: 532784961098355
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-13T04:50:22.263000+00:00"
          last_event_time: "2026-03-13T04:50:43.796000+00:00"
        - entity_type: JOB
          entity_id: 335644779362289
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-07T11:14:57.508000+00:00"
          last_event_time: "2026-03-07T11:15:18.591000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_am_survey
    full_name: main.bi_output.bi_output_customer_customer_facing_am_survey
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_facing_club_club_equity
    full_name: main.bi_output.bi_output_customer_customer_facing_club_club_equity
    type: EXTERNAL
    writer:
      kind: JOB
      path: 769316685964205
      lineage_source: system.access.table_lineage
      lineage_event_count: 9
      additional_producers:
        - entity_type: JOB
          entity_id: 742209048604075
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-03-28T05:37:40.650000+00:00"
          last_event_time: "2026-03-28T05:38:24.118000+00:00"
        - entity_type: JOB
          entity_id: 354872834152559
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-03-28T05:36:29.529000+00:00"
          last_event_time: "2026-03-28T05:37:22.171000+00:00"
        - entity_type: JOB
          entity_id: 482926812443836
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-03-28T05:53:59.150000+00:00"
          last_event_time: "2026-03-28T05:54:35.607000+00:00"
        - entity_type: JOB
          entity_id: 26228659937576
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-03-26T05:39:17.213000+00:00"
          last_event_time: "2026-03-26T05:40:00.278000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_club_club_offer_eligibilty
    full_name: main.bi_output.bi_output_customer_customer_facing_club_club_offer_eligibilty
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 1200434159941085
      lineage_source: system.access.table_lineage
      lineage_event_count: 12
      additional_producers:
        - entity_type: JOB
          entity_id: 525624360584016
          workspace_id: 5142916747090026
          event_count: 12
          first_event_time: "2026-03-18T09:41:16.691000+00:00"
          last_event_time: "2026-03-18T09:41:16.691000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_club_inventory_asset
    full_name: main.bi_output.bi_output_customer_customer_facing_club_inventory_asset
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_facing_club_loyalty_offer
    full_name: main.bi_output.bi_output_customer_customer_facing_club_loyalty_offer
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_facing_club_loyalty_offer_request
    full_name: main.bi_output.bi_output_customer_customer_facing_club_loyalty_offer_request
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_facing_pageviews_behaviour
    full_name: main.bi_output.bi_output_customer_customer_facing_pageviews_behaviour
    type: EXTERNAL
    writer:
      kind: JOB
      path: 905616356190643
      lineage_source: system.access.table_lineage
      lineage_event_count: 6
      additional_producers:
        - entity_type: JOB
          entity_id: 684181068945337
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-05-15T04:36:57.803000+00:00"
          last_event_time: "2026-05-15T04:36:57.803000+00:00"
        - entity_type: JOB
          entity_id: 436736205721924
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-16T04:54:01.274000+00:00"
          last_event_time: "2026-04-16T04:54:01.274000+00:00"
        - entity_type: JOB
          entity_id: 786313220276200
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-05-13T04:42:20.877000+00:00"
          last_event_time: "2026-05-13T04:42:20.877000+00:00"
        - entity_type: JOB
          entity_id: 510664889888866
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-05-14T05:04:25.359000+00:00"
          last_event_time: "2026-05-14T05:04:25.359000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_survey
    full_name: main.bi_output.bi_output_customer_customer_facing_survey
    type: EXTERNAL
    writer:
      kind: JOB
      path: 688763458383547
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 914824928659375
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-02-21T04:49:56.667000+00:00"
          last_event_time: "2026-02-21T04:49:56.667000+00:00"
        - entity_type: JOB
          entity_id: 46720532741539
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-03T05:47:10.751000+00:00"
          last_event_time: "2026-04-03T05:47:10.751000+00:00"
        - entity_type: JOB
          entity_id: 128310085598750
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-02-24T12:44:43.269000+00:00"
          last_event_time: "2026-02-24T12:44:43.269000+00:00"
        - entity_type: JOB
          entity_id: 9298462473686
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-02-19T04:40:18.619000+00:00"
          last_event_time: "2026-02-19T04:40:18.619000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_survey_taker
    full_name: main.bi_output.bi_output_customer_customer_facing_survey_taker
    type: EXTERNAL
    writer:
      kind: JOB
      path: 213935658623860
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 833167446274084
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-14T09:30:36.789000+00:00"
          last_event_time: "2026-03-14T09:30:36.789000+00:00"
        - entity_type: JOB
          entity_id: 434010216517611
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-13T06:44:59.362000+00:00"
          last_event_time: "2026-04-13T06:44:59.362000+00:00"
        - entity_type: JOB
          entity_id: 1067804482238566
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-24T05:46:10.494000+00:00"
          last_event_time: "2026-04-24T05:46:10.494000+00:00"
        - entity_type: JOB
          entity_id: 705275531255649
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-20T06:46:34.296000+00:00"
          last_event_time: "2026-04-20T06:46:34.296000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_triggers
    full_name: main.bi_output.bi_output_customer_customer_facing_triggers
    type: EXTERNAL
    writer:
      kind: JOB
      path: 29439054239650
      lineage_source: system.access.table_lineage
      lineage_event_count: 8
      additional_producers:
        - entity_type: JOB
          entity_id: 859218245606552
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-13T08:59:15.530000+00:00"
          last_event_time: "2026-05-13T08:59:15.530000+00:00"
        - entity_type: JOB
          entity_id: 203108797970413
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-15T09:03:54.051000+00:00"
          last_event_time: "2026-05-15T09:03:54.051000+00:00"
        - entity_type: JOB
          entity_id: 1051497401291979
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-12T09:05:39.230000+00:00"
          last_event_time: "2026-05-12T09:05:39.230000+00:00"
        - entity_type: JOB
          entity_id: 49110493072821
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-11T09:03:28.201000+00:00"
          last_event_time: "2026-05-11T09:03:28.201000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_triggers_filtered
    full_name: main.bi_output.bi_output_customer_customer_facing_triggers_filtered
    type: EXTERNAL
    writer:
      kind: JOB
      path: 890492072529400
      lineage_source: system.access.table_lineage
      lineage_event_count: 12
      additional_producers:
        - entity_type: JOB
          entity_id: 941111178793767
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-12T09:16:19.097000+00:00"
          last_event_time: "2026-05-12T09:16:19.097000+00:00"
        - entity_type: JOB
          entity_id: 466715515241455
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-13T09:10:22.612000+00:00"
          last_event_time: "2026-05-13T09:10:22.612000+00:00"
        - entity_type: JOB
          entity_id: 1099205354005653
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-15T09:18:46.011000+00:00"
          last_event_time: "2026-05-15T09:18:46.011000+00:00"
        - entity_type: JOB
          entity_id: 1058731286398906
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-14T09:17:56.374000+00:00"
          last_event_time: "2026-05-14T09:17:56.374000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_triggers_lead_score
    full_name: main.bi_output.bi_output_customer_customer_facing_triggers_lead_score
    type: EXTERNAL
    writer:
      kind: JOB
      path: 986217717349184
      lineage_source: system.access.table_lineage
      lineage_event_count: 17
      additional_producers:
        - entity_type: JOB
          entity_id: 677382500207098
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-09T09:03:58.988000+00:00"
          last_event_time: "2026-03-09T09:05:19.545000+00:00"
        - entity_type: JOB
          entity_id: 420670581755692
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-04-22T09:08:11.669000+00:00"
          last_event_time: "2026-04-22T09:09:56.839000+00:00"
        - entity_type: JOB
          entity_id: 371521080270210
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-16T09:09:24.533000+00:00"
          last_event_time: "2026-03-16T09:10:44.570000+00:00"
        - entity_type: JOB
          entity_id: 246140900910181
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-12T09:03:47.555000+00:00"
          last_event_time: "2026-03-12T09:05:15.679000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_agent_user
    full_name: main.bi_output.bi_output_customer_customer_support_agent_user
    type: EXTERNAL
    writer:
      kind: JOB
      path: 418338092021449
      lineage_source: system.access.table_lineage
      lineage_event_count: 80
    in_scope: true
  - name: bi_output_customer_customer_support_aml_handling_days
    full_name: main.bi_output.bi_output_customer_customer_support_aml_handling_days
    type: EXTERNAL
    writer:
      kind: JOB
      path: 172887083112065
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
      additional_producers:
        - entity_type: JOB
          entity_id: 7464022571998
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-04-25T04:52:54.983000+00:00"
          last_event_time: "2026-04-25T04:52:54.983000+00:00"
        - entity_type: JOB
          entity_id: 555849343656950
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-03-24T04:48:23.985000+00:00"
          last_event_time: "2026-03-24T04:48:23.985000+00:00"
        - entity_type: JOB
          entity_id: 369522992035066
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-03-30T04:46:49.293000+00:00"
          last_event_time: "2026-03-30T04:46:49.293000+00:00"
        - entity_type: JOB
          entity_id: 878489164885696
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-04-15T04:47:55.846000+00:00"
          last_event_time: "2026-04-15T04:47:55.846000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_case
    full_name: main.bi_output.bi_output_customer_customer_support_case
    type: EXTERNAL
    writer:
      kind: JOB
      path: 321086379460094
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 1019491065757336
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-02-24T12:18:22.020000+00:00"
          last_event_time: "2026-02-24T12:19:02.941000+00:00"
        - entity_type: JOB
          entity_id: 846392669211384
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-06T04:21:51.361000+00:00"
          last_event_time: "2026-05-06T04:22:52.973000+00:00"
        - entity_type: JOB
          entity_id: 991465691800539
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-17T04:53:04.355000+00:00"
          last_event_time: "2026-05-17T04:53:39.201000+00:00"
        - entity_type: JOB
          entity_id: 249397539368244
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-02-28T04:17:03.970000+00:00"
          last_event_time: "2026-02-28T04:17:49.892000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_case_event
    full_name: main.bi_output.bi_output_customer_customer_support_case_event
    type: EXTERNAL
    writer:
      kind: JOB
      path: 275066326823389
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 670148663191421
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-10T04:42:56.371000+00:00"
          last_event_time: "2026-05-10T04:42:56.371000+00:00"
        - entity_type: JOB
          entity_id: 519123432798630
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-01T04:59:42.960000+00:00"
          last_event_time: "2026-05-01T04:59:42.960000+00:00"
        - entity_type: JOB
          entity_id: 151890376065647
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-26T04:42:45.537000+00:00"
          last_event_time: "2026-04-26T04:42:45.537000+00:00"
        - entity_type: JOB
          entity_id: 27758263508770
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-02T04:38:02.972000+00:00"
          last_event_time: "2026-05-02T04:38:02.972000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_csat
    full_name: main.bi_output.bi_output_customer_customer_support_csat
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_support_customer_engagement
    full_name: main.bi_output.bi_output_customer_customer_support_customer_engagement
    type: EXTERNAL
    writer:
      kind: JOB
      path: 130009652999855
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 720263335649092
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-21T04:40:06.538000+00:00"
          last_event_time: "2026-04-21T04:40:06.538000+00:00"
        - entity_type: JOB
          entity_id: 858516535844143
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-20T04:48:14.361000+00:00"
          last_event_time: "2026-04-20T04:48:14.361000+00:00"
        - entity_type: JOB
          entity_id: 799379077970348
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-20T04:49:15.549000+00:00"
          last_event_time: "2026-04-20T04:49:15.549000+00:00"
        - entity_type: JOB
          entity_id: 702525644569038
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-22T04:37:13.702000+00:00"
          last_event_time: "2026-04-22T04:37:13.702000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_live_chat_transcript
    full_name: main.bi_output.bi_output_customer_customer_support_live_chat_transcript
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_support_salesforce_reply
    full_name: main.bi_output.bi_output_customer_customer_support_salesforce_reply
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_customer_support_task
    full_name: main.bi_output.bi_output_customer_customer_support_task
    type: EXTERNAL
    writer:
      kind: JOB
      path: 594912967306162
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
      additional_producers:
        - entity_type: JOB
          entity_id: 847858200256618
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-02-20T04:25:37.905000+00:00"
          last_event_time: "2026-02-20T04:25:37.905000+00:00"
        - entity_type: JOB
          entity_id: 330217846958171
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-09T04:35:08.112000+00:00"
          last_event_time: "2026-05-09T04:35:08.112000+00:00"
        - entity_type: JOB
          entity_id: 1115464703203343
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-18T05:21:27.892000+00:00"
          last_event_time: "2026-05-18T05:21:27.892000+00:00"
        - entity_type: JOB
          entity_id: 570886942316559
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-02-19T04:23:23.177000+00:00"
          last_event_time: "2026-02-19T04:23:23.177000+00:00"
    in_scope: true
  - name: bi_output_customer_ddr_revenue_metrics
    full_name: main.bi_output.bi_output_customer_ddr_revenue_metrics
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_external_table_club_equity
    full_name: main.bi_output.bi_output_customer_external_table_club_equity
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_customer_external_table_isa
    full_name: main.bi_output.bi_output_customer_external_table_isa
    type: EXTERNAL
    writer:
      kind: JOB
      path: 405360254380378
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: JOB
          entity_id: 277351509000785
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-03-10T06:17:24.859000+00:00"
          last_event_time: "2026-03-10T06:17:24.859000+00:00"
        - entity_type: JOB
          entity_id: 331483120022520
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-02-27T06:02:04.422000+00:00"
          last_event_time: "2026-02-27T06:02:04.422000+00:00"
        - entity_type: JOB
          entity_id: 911754404643932
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-02-20T06:22:14.899000+00:00"
          last_event_time: "2026-02-20T06:22:14.899000+00:00"
        - entity_type: JOB
          entity_id: 103454990240311
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-03-13T06:27:14.317000+00:00"
          last_event_time: "2026-03-13T06:27:14.317000+00:00"
    in_scope: true
  - name: bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global
    full_name: main.bi_output.bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global
    type: EXTERNAL
    writer:
      kind: JOB
      path: 262147853791452
      lineage_source: system.access.table_lineage
      lineage_event_count: 15
      additional_producers:
        - entity_type: JOB
          entity_id: 780272643408661
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-05-15T04:25:06.068000+00:00"
          last_event_time: "2026-05-15T04:41:46.828000+00:00"
        - entity_type: JOB
          entity_id: 806895664453077
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-30T04:22:52.502000+00:00"
          last_event_time: "2026-04-30T04:38:43.024000+00:00"
        - entity_type: JOB
          entity_id: 736101695675964
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-30T04:39:05.511000+00:00"
          last_event_time: "2026-04-30T04:51:44.902000+00:00"
        - entity_type: JOB
          entity_id: 1079375864545522
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-29T05:27:13.476000+00:00"
          last_event_time: "2026-04-29T05:40:16.989000+00:00"
    in_scope: true
  - name: bi_output_customer_social_social_feed
    full_name: main.bi_output.bi_output_customer_social_social_feed
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1046492620820074
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 505677317422408
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-25T04:48:48.191000+00:00"
          last_event_time: "2026-04-25T04:57:13.250000+00:00"
        - entity_type: JOB
          entity_id: 319567878929891
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-20T04:50:26.732000+00:00"
          last_event_time: "2026-04-20T04:53:05.994000+00:00"
        - entity_type: JOB
          entity_id: 376838888807800
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-24T04:29:38.051000+00:00"
          last_event_time: "2026-04-24T04:34:49.847000+00:00"
        - entity_type: JOB
          entity_id: 411792205397931
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-23T04:28:36.566000+00:00"
          last_event_time: "2026-04-23T04:30:56.596000+00:00"
    in_scope: true
  - name: bi_output_dealing_tables_bi_db_latency_compensation
    full_name: main.bi_output.bi_output_dealing_tables_bi_db_latency_compensation
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_deltaapp_subscription_view
    full_name: main.bi_output.bi_output_deltaapp_subscription_view
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.bronze_deltaapp_bronze_subscriptions
    refs_source: view_definition (regex extract)
  - name: bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external
    full_name: main.bi_output.bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external
    type: EXTERNAL
    writer:
      kind: JOB
      path: 131261705122566
      lineage_source: system.access.table_lineage
      lineage_event_count: 16
      additional_producers:
        - entity_type: JOB
          entity_id: 931695897996839
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-03-26T06:47:30.827000+00:00"
          last_event_time: "2026-03-26T06:47:30.827000+00:00"
        - entity_type: JOB
          entity_id: 226320803687083
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-04-16T06:59:29.827000+00:00"
          last_event_time: "2026-04-16T06:59:29.827000+00:00"
        - entity_type: JOB
          entity_id: 53156131577032
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-02-18T06:43:23.279000+00:00"
          last_event_time: "2026-02-18T06:43:23.279000+00:00"
        - entity_type: JOB
          entity_id: 300949838967607
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-03-30T11:30:47.910000+00:00"
          last_event_time: "2026-03-30T11:30:47.910000+00:00"
    in_scope: true
  - name: bi_output_finance_external_table_bi_db_sharelending_reconciliation_external
    full_name: main.bi_output.bi_output_finance_external_table_bi_db_sharelending_reconciliation_external
    type: EXTERNAL
    writer:
      kind: JOB
      path: 641107617594072
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 735181929745148
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-13T06:31:55.262000+00:00"
          last_event_time: "2026-03-13T06:31:55.262000+00:00"
        - entity_type: JOB
          entity_id: 563691875048770
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-12T06:05:51.358000+00:00"
          last_event_time: "2026-05-12T06:05:51.358000+00:00"
        - entity_type: JOB
          entity_id: 306321581750495
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-06T06:42:05.738000+00:00"
          last_event_time: "2026-05-06T06:42:05.738000+00:00"
        - entity_type: JOB
          entity_id: 236875100166818
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-05T06:36:11.519000+00:00"
          last_event_time: "2026-03-05T06:36:11.519000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_all_trades_pivoted_net_vol
    full_name: main.bi_output.bi_output_finance_tables_all_trades_pivoted_net_vol
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_finance_tables_bi_db_hedge_nettingbalance
    full_name: main.bi_output.bi_output_finance_tables_bi_db_hedge_nettingbalance
    type: EXTERNAL
    writer:
      kind: JOB
      path: 737650008422339
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
      additional_producers:
        - entity_type: JOB
          entity_id: 344696736933469
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-05-16T06:44:39.952000+00:00"
          last_event_time: "2026-05-16T06:44:39.952000+00:00"
        - entity_type: JOB
          entity_id: 936849775220703
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-04-21T06:46:06.832000+00:00"
          last_event_time: "2026-04-21T06:46:06.832000+00:00"
        - entity_type: JOB
          entity_id: 797379036984862
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-04-27T06:39:41.726000+00:00"
          last_event_time: "2026-04-27T06:39:41.726000+00:00"
        - entity_type: JOB
          entity_id: 437602532532775
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-05-02T06:37:27.553000+00:00"
          last_event_time: "2026-05-02T06:37:27.553000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_positions_closed_to_iban
    full_name: main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 88a61c9d-50c8-4516-a27d-ed802ebae419
      lineage_source: system.access.table_lineage
      lineage_event_count: 637
    in_scope: true
  - name: bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet
    full_name: main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 88a61c9d-50c8-4516-a27d-ed802ebae419
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
    in_scope: true
  - name: bi_output_finance_tables_bi_db_positions_opened_from_iban
    full_name: main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 6db2e20c-4cb2-4bbb-86ae-fbb3baeae78c
      lineage_source: system.access.table_lineage
      lineage_event_count: 819
    in_scope: true
  - name: bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
    full_name: main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 6db2e20c-4cb2-4bbb-86ae-fbb3baeae78c
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
    in_scope: true
  - name: bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet
    full_name: main.bi_output.bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 05293a5b-1d3b-4302-9856-f4cbc6942396
      lineage_source: system.access.table_lineage
      lineage_event_count: 124
      additional_producers:
        - entity_type: DBSQL_QUERY
          entity_id: 421b9943-9dae-4f4a-acc0-9272c4f2a70d
          workspace_id: 6358342630366312
          event_count: 56
          first_event_time: "2026-02-17T07:21:18.117000+00:00"
          last_event_time: "2026-03-16T07:26:24.698000+00:00"
        - entity_type: JOB
          entity_id: 844382279060709
          workspace_id: 6256398679555083
          event_count: 2
          first_event_time: "2026-03-17T14:03:26.326000+00:00"
          last_event_time: "2026-03-17T14:03:26.326000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_share_lending_allocation
    full_name: main.bi_output.bi_output_finance_tables_bi_db_share_lending_allocation
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_finance_tables_bi_db_sharelending_collateraldetaileseu
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_collateraldetaileseu
    type: EXTERNAL
    writer:
      kind: JOB
      path: 725538823326366
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 410199529526145
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-06T09:32:37.396000+00:00"
          last_event_time: "2026-03-06T09:33:41.179000+00:00"
        - entity_type: JOB
          entity_id: 138151664061318
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-04-17T08:33:58.616000+00:00"
          last_event_time: "2026-04-17T08:35:01.283000+00:00"
        - entity_type: JOB
          entity_id: 866386262065602
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-13T09:33:28.840000+00:00"
          last_event_time: "2026-03-13T09:34:14.448000+00:00"
        - entity_type: JOB
          entity_id: 788691645559539
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-16T11:27:14.125000+00:00"
          last_event_time: "2026-03-16T11:28:02.963000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_collateraldetailesmain
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_collateraldetailesmain
    type: EXTERNAL
    writer:
      kind: JOB
      path: 872666614904699
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 388131355962550
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-04-09T08:29:00.473000+00:00"
          last_event_time: "2026-04-09T08:30:11.862000+00:00"
        - entity_type: JOB
          entity_id: 433062061351945
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-14T08:29:45.788000+00:00"
          last_event_time: "2026-05-14T08:30:59.802000+00:00"
        - entity_type: JOB
          entity_id: 558863821212423
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-17T09:37:59.863000+00:00"
          last_event_time: "2026-03-17T09:39:17.734000+00:00"
        - entity_type: JOB
          entity_id: 765545700561167
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-04-03T08:05:37.842000+00:00"
          last_event_time: "2026-04-03T08:06:55.361000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_collateraldetailesuk
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_collateraldetailesuk
    type: EXTERNAL
    writer:
      kind: JOB
      path: 47673804099153
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 749377526361799
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-19T09:36:16.999000+00:00"
          last_event_time: "2026-03-19T09:37:03.368000+00:00"
        - entity_type: JOB
          entity_id: 427126323990379
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-01T08:33:05.159000+00:00"
          last_event_time: "2026-05-01T08:34:00.077000+00:00"
        - entity_type: JOB
          entity_id: 688149681306423
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-23T11:25:18.446000+00:00"
          last_event_time: "2026-03-23T11:26:27.108000+00:00"
        - entity_type: JOB
          entity_id: 994244292293140
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-26T09:30:53.513000+00:00"
          last_event_time: "2026-03-26T09:31:55.274000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_custodyreconciliation
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 929841887099956
      lineage_source: system.access.table_lineage
      lineage_event_count: 50
      additional_producers:
        - entity_type: JOB
          entity_id: 774467620119768
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-06T06:40:27.223000+00:00"
          last_event_time: "2026-03-06T06:44:46.045000+00:00"
        - entity_type: JOB
          entity_id: 1102619228266846
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-04-10T06:45:36.331000+00:00"
          last_event_time: "2026-04-10T06:52:54.534000+00:00"
        - entity_type: JOB
          entity_id: 894362430532226
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-05T06:42:10.923000+00:00"
          last_event_time: "2026-03-05T06:45:31.840000+00:00"
        - entity_type: JOB
          entity_id: 255636913522258
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-18T06:38:56.695000+00:00"
          last_event_time: "2026-03-18T06:43:00.040000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu
    type: EXTERNAL
    writer:
      kind: JOB
      path: 886170903386595
      lineage_source: system.access.table_lineage
      lineage_event_count: 15
      additional_producers:
        - entity_type: JOB
          entity_id: 1101713962736244
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-03-11T07:58:04.233000+00:00"
          last_event_time: "2026-03-11T08:25:02.381000+00:00"
        - entity_type: JOB
          entity_id: 32192209799931
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-03-16T10:11:57.040000+00:00"
          last_event_time: "2026-03-16T10:31:04.363000+00:00"
        - entity_type: JOB
          entity_id: 850746051623358
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-20T10:25:11.238000+00:00"
          last_event_time: "2026-04-20T10:46:09.652000+00:00"
        - entity_type: JOB
          entity_id: 1000493838267721
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-20T09:48:04.148000+00:00"
          last_event_time: "2026-04-20T10:16:17.191000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk
    type: EXTERNAL
    writer:
      kind: JOB
      path: 790443493174283
      lineage_source: system.access.table_lineage
      lineage_event_count: 14
      additional_producers:
        - entity_type: JOB
          entity_id: 562622648116058
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-03-23T10:12:39.949000+00:00"
          last_event_time: "2026-03-23T10:23:04.357000+00:00"
        - entity_type: JOB
          entity_id: 863862100713057
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-04-13T11:01:10.465000+00:00"
          last_event_time: "2026-04-13T11:10:52.280000+00:00"
        - entity_type: JOB
          entity_id: 917376253168406
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-04-30T08:17:08.504000+00:00"
          last_event_time: "2026-04-30T08:29:55.556000+00:00"
        - entity_type: JOB
          entity_id: 661894669513370
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-05-06T08:11:44.535000+00:00"
          last_event_time: "2026-05-06T08:25:09.882000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu
    type: EXTERNAL
    writer:
      kind: JOB
      path: 230453999952504
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 61622451211761
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-02-20T09:35:34.799000+00:00"
          last_event_time: "2026-02-20T09:36:10.155000+00:00"
        - entity_type: JOB
          entity_id: 121635663285677
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-05T10:03:40.012000+00:00"
          last_event_time: "2026-05-05T10:04:38.503000+00:00"
        - entity_type: JOB
          entity_id: 626019493956399
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-02T16:17:35.828000+00:00"
          last_event_time: "2026-03-02T16:18:27.045000+00:00"
        - entity_type: JOB
          entity_id: 432697436883087
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-03T09:42:00.121000+00:00"
          last_event_time: "2026-03-03T09:42:30.490000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain
    type: EXTERNAL
    writer:
      kind: JOB
      path: 27544170671570
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 302988174335890
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-04T09:32:34.415000+00:00"
          last_event_time: "2026-03-04T09:34:05.904000+00:00"
        - entity_type: JOB
          entity_id: 558863821212423
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-17T09:40:58.994000+00:00"
          last_event_time: "2026-03-17T09:43:00.929000+00:00"
        - entity_type: JOB
          entity_id: 1099456476947239
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-23T08:38:22.253000+00:00"
          last_event_time: "2026-04-23T08:40:50.058000+00:00"
        - entity_type: JOB
          entity_id: 286906934457272
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-02-23T11:26:57.877000+00:00"
          last_event_time: "2026-02-23T11:28:39.451000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_loansandcollateraluk
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateraluk
    type: EXTERNAL
    writer:
      kind: JOB
      path: 470769329960226
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 453833154901946
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-01T08:39:58.586000+00:00"
          last_event_time: "2026-04-01T08:41:10.712000+00:00"
        - entity_type: JOB
          entity_id: 659571473937788
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-24T08:44:31.523000+00:00"
          last_event_time: "2026-04-24T08:45:32.184000+00:00"
        - entity_type: JOB
          entity_id: 11029355838908
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-31T08:45:05.423000+00:00"
          last_event_time: "2026-03-31T08:46:36.903000+00:00"
        - entity_type: JOB
          entity_id: 473727521819142
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-30T11:29:53.287000+00:00"
          last_event_time: "2026-03-30T11:31:57.377000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_price_estimated
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_price_estimated
    type: EXTERNAL
    writer:
      kind: JOB
      path: 769525096189601
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 1049427011165715
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-17T07:35:44.343000+00:00"
          last_event_time: "2026-03-17T07:37:33.632000+00:00"
        - entity_type: JOB
          entity_id: 832793623099840
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-06T07:35:27.584000+00:00"
          last_event_time: "2026-03-06T07:37:21.665000+00:00"
        - entity_type: JOB
          entity_id: 799335004139539
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-12T07:33:10.147000+00:00"
          last_event_time: "2026-03-12T07:35:07.561000+00:00"
        - entity_type: JOB
          entity_id: 603733010544102
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-16T07:30:51.469000+00:00"
          last_event_time: "2026-03-16T07:32:44.768000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_reconciliation
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_reconciliation
    type: EXTERNAL
    writer:
      kind: JOB
      path: 333631390353161
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 213353132127089
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-21T05:45:17.414000+00:00"
          last_event_time: "2026-04-21T05:45:17.414000+00:00"
        - entity_type: JOB
          entity_id: 994228221968245
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-06T11:23:58.147000+00:00"
          last_event_time: "2026-04-06T11:23:58.147000+00:00"
        - entity_type: JOB
          entity_id: 164863133418087
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-26T06:32:50.611000+00:00"
          last_event_time: "2026-03-26T06:32:50.611000+00:00"
        - entity_type: JOB
          entity_id: 706056708767005
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-22T05:50:23.773000+00:00"
          last_event_time: "2026-04-22T05:50:23.773000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_customer_customer_deceased
    full_name: main.bi_output.bi_output_finance_tables_customer_customer_deceased
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_finance_tables_ptp_tax
    full_name: main.bi_output.bi_output_finance_tables_ptp_tax
    type: EXTERNAL
    writer:
      kind: JOB
      path: 681844067999280
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 248748769988761
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-02-23T04:17:39.973000+00:00"
          last_event_time: "2026-02-23T04:17:48.097000+00:00"
        - entity_type: JOB
          entity_id: 90904867162520
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-14T04:15:47.007000+00:00"
          last_event_time: "2026-03-14T04:15:54.272000+00:00"
        - entity_type: JOB
          entity_id: 1098606014413123
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-12T04:16:17.470000+00:00"
          last_event_time: "2026-03-12T04:16:25.016000+00:00"
        - entity_type: JOB
          entity_id: 184700730709070
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-11T04:14:52.096000+00:00"
          last_event_time: "2026-03-11T04:14:59.375000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_ptp_tax_backup
    full_name: main.bi_output.bi_output_finance_tables_ptp_tax_backup
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_finance_tables_share_lending_aggregate
    full_name: main.bi_output.bi_output_finance_tables_share_lending_aggregate
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_finance_tables_tax_ptp_monitoring
    full_name: main.bi_output.bi_output_finance_tables_tax_ptp_monitoring
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_fullname_apiresults
    full_name: main.bi_output.bi_output_fullname_apiresults
    type: MANAGED
    writer:
      kind: JOB
      path: 384802822442789
      lineage_source: system.access.table_lineage
      lineage_event_count: 69
    in_scope: true
  - name: bi_output_marketing_acquisition_anomaly
    full_name: main.bi_output.bi_output_marketing_acquisition_anomaly
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_marketing_acquisition_demo
    full_name: main.bi_output.bi_output_marketing_acquisition_demo
    type: EXTERNAL
    writer:
      kind: JOB
      path: 962658155699673
      lineage_source: system.access.table_lineage
      lineage_event_count: 810
    in_scope: true
  - name: bi_output_marketing_acquisition_liveacquisition
    full_name: main.bi_output.bi_output_marketing_acquisition_liveacquisition
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 78916582-774e-46cc-8195-8a41a333aa6f
      lineage_source: system.access.table_lineage
      lineage_event_count: 5922
    in_scope: true
  - name: bi_output_marketing_affiliate_payments_report_closed_position
    full_name: main.bi_output.bi_output_marketing_affiliate_payments_report_closed_position
    type: EXTERNAL
    writer:
      kind: JOB
      path: 131117946631349
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 844558387923931
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-19T04:24:42.603000+00:00"
          last_event_time: "2026-03-19T04:24:42.603000+00:00"
        - entity_type: JOB
          entity_id: 649649054957599
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-10T04:22:37.837000+00:00"
          last_event_time: "2026-03-10T04:22:37.837000+00:00"
        - entity_type: JOB
          entity_id: 437146905298849
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-11T04:20:59.225000+00:00"
          last_event_time: "2026-03-11T04:20:59.225000+00:00"
        - entity_type: JOB
          entity_id: 1009570545612839
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-14T04:22:20.864000+00:00"
          last_event_time: "2026-03-14T04:22:20.864000+00:00"
    in_scope: true
  - name: bi_output_marketing_liveacquisitiondashboard
    full_name: main.bi_output.bi_output_marketing_liveacquisitiondashboard
    type: EXTERNAL
    writer:
      kind: JOB
      path: 362438626229151
      lineage_source: system.access.table_lineage
      lineage_event_count: 17955
    in_scope: true
  - name: bi_output_marketing_marketingcloud_user_behavior_instrument
    full_name: main.bi_output.bi_output_marketing_marketingcloud_user_behavior_instrument
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_marketing_marketingcloud_user_behavior_instrument_v
    full_name: main.bi_output.bi_output_marketing_marketingcloud_user_behavior_instrument_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output.bi_output_marketing_marketingcloud_user_behavior_instrument
    refs_source: view_definition (regex extract)
  - name: bi_output_marketing_marketingcloud_user_behavior_pi
    full_name: main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_marketing_marketingcloud_user_behavior_pi_v
    full_name: main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output.bi_output_marketing_marketingcloud_user_behavior_pi
    refs_source: view_definition (regex extract)
  - name: bi_output_marketing_promotion_bi_db_promo_card
    full_name: main.bi_output.bi_output_marketing_promotion_bi_db_promo_card
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1044486077439857
      lineage_source: system.access.table_lineage
      lineage_event_count: 661
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 4212210221780631
          workspace_id: 5142916747090026
          event_count: 45
          first_event_time: "2026-03-17T09:04:21.198000+00:00"
          last_event_time: "2026-05-07T15:51:44.098000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 2650238679543064
          workspace_id: 5142916747090026
          event_count: 36
          first_event_time: "2026-03-15T07:56:03.336000+00:00"
          last_event_time: "2026-03-15T11:35:52.529000+00:00"
    in_scope: true
  - name: bi_output_marketing_sfmc_sfmc_filter
    full_name: main.bi_output.bi_output_marketing_sfmc_sfmc_filter
    type: EXTERNAL
    writer:
      kind: JOB
      path: 618867936130004
      lineage_source: system.access.table_lineage
      lineage_event_count: 6
      additional_producers:
        - entity_type: JOB
          entity_id: 373562646619705
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-05-04T04:43:40.770000+00:00"
          last_event_time: "2026-05-04T04:43:40.770000+00:00"
        - entity_type: JOB
          entity_id: 125090249423859
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-25T05:04:08.104000+00:00"
          last_event_time: "2026-04-25T05:04:08.104000+00:00"
        - entity_type: JOB
          entity_id: 742616361281869
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-26T04:29:35.699000+00:00"
          last_event_time: "2026-04-26T04:29:35.699000+00:00"
        - entity_type: JOB
          entity_id: 24862886087047
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-28T04:37:43.803000+00:00"
          last_event_time: "2026-04-28T04:37:43.803000+00:00"
    in_scope: true
  - name: bi_output_marketing_sfmc_sfmc_report
    full_name: main.bi_output.bi_output_marketing_sfmc_sfmc_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 127029817878171
      lineage_source: system.access.table_lineage
      lineage_event_count: 8
      additional_producers:
        - entity_type: JOB
          entity_id: 892273554309047
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-05T06:38:23.036000+00:00"
          last_event_time: "2026-05-05T06:50:58.628000+00:00"
        - entity_type: JOB
          entity_id: 384522260015343
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-08T06:48:23.480000+00:00"
          last_event_time: "2026-05-08T07:00:43.633000+00:00"
        - entity_type: JOB
          entity_id: 386148503242687
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-05T07:05:45.867000+00:00"
          last_event_time: "2026-05-05T07:19:02.672000+00:00"
        - entity_type: JOB
          entity_id: 567515966787674
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-05-08T07:01:15.092000+00:00"
          last_event_time: "2026-05-08T07:14:25.961000+00:00"
    in_scope: true
  - name: bi_output_moneyfarm_customers
    full_name: main.bi_output.bi_output_moneyfarm_customers
    type: EXTERNAL
    writer:
      kind: JOB
      path: 909845381518474
      lineage_source: system.access.table_lineage
      lineage_event_count: 372
    in_scope: true
  - name: bi_output_moneyfarm_fact_portfolio_snapshot
    full_name: main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
    type: EXTERNAL
    writer:
      kind: JOB
      path: 909845381518474
      lineage_source: system.access.table_lineage
      lineage_event_count: 186
    in_scope: true
  - name: bi_output_moneyfarm_fact_transactions
    full_name: main.bi_output.bi_output_moneyfarm_fact_transactions
    type: EXTERNAL
    writer:
      kind: JOB
      path: 909845381518474
      lineage_source: system.access.table_lineage
      lineage_event_count: 133
    in_scope: true
  - name: bi_output_operations_documentanalysis
    full_name: main.bi_output.bi_output_operations_documentanalysis
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bi_output_regtechops_wash_trading_alerts_daily
    full_name: main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
    type: EXTERNAL
    writer:
      kind: JOB
      path: 832857154712514
      lineage_source: system.access.table_lineage
      lineage_event_count: 30
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 4404603554302505
          workspace_id: 5142916747090026
          event_count: 7
          first_event_time: "2026-05-04T11:57:38.112000+00:00"
          last_event_time: "2026-05-04T12:07:39.427000+00:00"
        - entity_type: DBSQL_QUERY
          entity_id: 79e27f88-3eac-4a54-8339-4d613a5e90da
          workspace_id: 5142916747090026
          event_count: 1
          first_event_time: "2026-05-04T11:10:18.944000+00:00"
          last_event_time: "2026-05-04T11:10:18.944000+00:00"
    in_scope: true
  - name: bi_output_urban_notifications_daily_panel
    full_name: main.bi_output.bi_output_urban_notifications_daily_panel
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 1e56fdd1-177f-4f99-ac29-1aa01e651514
      lineage_source: system.access.table_lineage
      lineage_event_count: 1170
    in_scope: true
  - name: bi_output_urban_notifications_daily_panel_agg
    full_name: main.bi_output.bi_output_urban_notifications_daily_panel_agg
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 259a1f94-441c-43c2-bd95-11b2ed9d69fa
      lineage_source: system.access.table_lineage
      lineage_event_count: 90
    in_scope: true
  - name: bi_output_urban_notifications_monthly_lsd
    full_name: main.bi_output.bi_output_urban_notifications_monthly_lsd
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 97133d78-c951-4751-be0d-a80338fc9d6b
      lineage_source: system.access.table_lineage
      lineage_event_count: 27
    in_scope: true
  - name: bi_output_v_recurring_investment
    full_name: main.bi_output.bi_output_v_recurring_investment
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_recurringinvestment_recurringinvestment_planinstances
      - main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
      - main.general.bronze_recurringinvestment_recurringinvestment_plans
      - main.bi_db.bronze_recurringinvestment_dictionary_planstatus
      - main.experience.bronze_recurringinvestment_dictionary_plantype
      - main.experience.bronze_recurringinvestment_dictionary_copytype
      - main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid
      - main.bi_db.bronze_recurringinvestment_dictionary_planeventcode
      - main.experience.bronze_recurringinvestment_dictionary_positionstatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_aum
    full_name: main.bi_output.bi_output_vg_aum
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
      - main.bi_output.bi_output_vg_date
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
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_case
    full_name: main.bi_output.bi_output_vg_case
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.silver_crm_case
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_case_event
    full_name: main.bi_output.bi_output_vg_case_event
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output.bi_output_customer_customer_support_case_event
      - bi_output.bi_output_customer_customer_support_agent_user
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_cf_crm_contact
    full_name: main.bi_output.bi_output_vg_cf_crm_contact
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output_stg.tf_crm_contact_user
      - main.bi_output.bi_output_vg_crm_user
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_club
    full_name: main.bi_output.bi_output_vg_club
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_club_offers
    full_name: main.bi_output.bi_output_vg_club_offers
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty
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
  - name: bi_output_vg_copy_mimo
    full_name: main.bi_output.bi_output_vg_copy_mimo
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
      - main.bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_crm_user
    full_name: main.bi_output.bi_output_vg_crm_user
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.silver_crm_user
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_customer_assignment
    full_name: main.bi_output.bi_output_vg_customer_assignment
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.crm.gold_crm_accountsmanager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_output.bi_output_vg_crm_user
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_customer_first_dates
    full_name: main.bi_output.bi_output_vg_customer_first_dates
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
      - main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_customer_snapshot
    full_name: main.bi_output.bi_output_vg_customer_snapshot
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.bi_output.bi_output_vg_date
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_customer_snapshot_test
    full_name: main.bi_output.bi_output_vg_customer_snapshot_test
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
  - name: bi_output_vg_customer_snapshot_v2
    full_name: main.bi_output.bi_output_vg_customer_snapshot_v2
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.bi_output.bi_output_vg_date
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_daily_commission
    full_name: main.bi_output.bi_output_vg_daily_commission
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.trading.bronze_etoro_trade_instrumentgroups
      - main.trading.bronze_etoro_trade_instrumentmetadata
      - main.trading.bronze_etoro_trade_providertoinstrument
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_date
    full_name: main.bi_output.bi_output_vg_date
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_ddr_customers_snapshot
    full_name: main.bi_output.bi_output_vg_ddr_customers_snapshot
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
      - main.bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_mimo
    full_name: main.bi_output.bi_output_vg_mimo
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_parentcid
    full_name: main.bi_output.bi_output_vg_parentcid
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy
      - bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_revenue
    full_name: main.bi_output.bi_output_vg_revenue
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_output.bi_output_vg_date
      - main.bi_output.bi_ouput_v_dim_Instrumenttype
      - main.bi_output.bi_output_customer_ddr_revenue_metrics
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
    refs_source: view_definition (regex extract)
  - name: bi_output_vg_volume_amount
    full_name: main.bi_output.bi_output_vg_volume_amount
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
      - main.bi_output.bi_ouput_v_dim_instrumenttype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.bi_output.bi_output_vg_date
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
    refs_source: view_definition (regex extract)
  - name: bi_output_wf_view
    full_name: main.bi_output.bi_output_wf_view
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_db.bronze_wealth_france_wealth_france_users_data
      - bi_db.bronze_sub_accounts_accounts
      - main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit
    refs_source: view_definition (regex extract)
  - name: current
    full_name: main.bi_output.current
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
  - name: current_table
    full_name: main.bi_output.current_table
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
  - name: finance_tables_functions_revenue_sdrt
    full_name: main.bi_output.finance_tables_functions_revenue_sdrt
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: finance_tables_functions_revenue_trading_fees
    full_name: main.bi_output.finance_tables_functions_revenue_trading_fees
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: funded
    full_name: main.bi_output.funded
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata
    refs_source: view_definition (regex extract)
  - name: limitation_to_normal_conversion
    full_name: main.bi_output.limitation_to_normal_conversion
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
    refs_source: view_definition (regex extract)
  - name: negative_nmi
    full_name: main.bi_output.negative_nmi
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_etoro_history_credit
      - main.trading.bronze_etoro_history_position_datafactory
      - main.trading.silver_etoro_trade_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: nmi_by_portfoliopi_new
    full_name: main.bi_output.nmi_by_portfoliopi_new
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.bronze_etoro_dwh_v_historymirrorhourly
      - main.general.bronze_etoro_backoffice_customer
      - main.general.bronze_etoro_customer_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
    refs_source: view_definition (regex extract)
  - name: positionsvolumeandattributes_lc4_source
    full_name: main.bi_output.positionsvolumeandattributes_lc4_source
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet
    refs_source: view_definition (regex extract)
  - name: positive_nmi
    full_name: main.bi_output.positive_nmi
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_etoro_history_credit
      - main.trading.bronze_etoro_history_position_datafactory
      - main.trading.silver_etoro_trade_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: positive_nmi_commodities
    full_name: main.bi_output.positive_nmi_commodities
    type: MATERIALIZED_VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_etoro_history_credit
      - main.trading.bronze_etoro_history_position_datafactory
      - main.trading.silver_etoro_trade_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
    refs_source: view_definition (regex extract)
  - name: snapshot
    full_name: main.bi_output.snapshot
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
  - name: snapshot_table
    full_name: main.bi_output.snapshot_table
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
  - name: v_external_france_wealth_contracts_transactions
    full_name: main.bi_output.v_external_france_wealth_contracts_transactions
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_db.bronze_wealth_france_wealth_france_users_data
    refs_source: view_definition (regex extract)
  - name: vg_acquisitionfunnel_em1
    full_name: main.bi_output.vg_acquisitionfunnel_em1
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
    refs_source: view_definition (regex extract)
  - name: vg_bidb_alldeposits_for_genie
    full_name: main.bi_output.vg_bidb_alldeposits_for_genie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
    refs_source: view_definition (regex extract)
  - name: vg_emoney_card_instance_summary
    full_name: main.bi_output.vg_emoney_card_instance_summary
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
    refs_source: view_definition (regex extract)
  - name: vg_emoney_card_transactions
    full_name: main.bi_output.vg_emoney_card_transactions
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
    refs_source: view_definition (regex extract)
  - name: vg_emoney_openbankingdeposit
    full_name: main.bi_output.vg_emoney_openbankingdeposit
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.bronze_moneytransfer_billing_transfers
    refs_source: view_definition (regex extract)
  - name: vg_emoney_panel_firstdates_em1
    full_name: main.bi_output.vg_emoney_panel_firstdates_em1
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
    refs_source: view_definition (regex extract)
  - name: vg_emoney_potentialclients_attributes
    full_name: main.bi_output.vg_emoney_potentialclients_attributes
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
    refs_source: view_definition (regex extract)
  - name: vg_emoney_txs
    full_name: main.bi_output.vg_emoney_txs
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
    refs_source: view_definition (regex extract)
  - name: vg_emoneydimaccount_forgenie
    full_name: main.bi_output.vg_emoneydimaccount_forgenie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
    refs_source: view_definition (regex extract)
  - name: vg_emoneydimtransaction_forgenie
    full_name: main.bi_output.vg_emoneydimtransaction_forgenie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
    refs_source: view_definition (regex extract)
  - name: vg_fact_billingdeposit_for_genie
    full_name: main.bi_output.vg_fact_billingdeposit_for_genie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
    refs_source: view_definition (regex extract)
  - name: vg_fact_billingdepost_forgenie
    full_name: main.bi_output.vg_fact_billingdepost_forgenie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
      - main.general.bronze_etoro_dictionary_cardtype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
    refs_source: view_definition (regex extract)
  - name: vg_fact_billingdepost_forgenie_new
    full_name: main.bi_output.vg_fact_billingdepost_forgenie_new
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
      - main.general.bronze_etoro_dictionary_cardtype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
    refs_source: view_definition (regex extract)
  - name: vg_fact_billingwithdraw_for_genie
    full_name: main.bi_output.vg_fact_billingwithdraw_for_genie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
      - main.billing.bronze_etoro_billing_depot
      - main.bi_db.bronze_etoro_dictionary_withdrawtype
    refs_source: view_definition (regex extract)
  - name: vg_fact_snapshotcustomer_for_emoney_genie
    full_name: main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
    refs_source: view_definition (regex extract)
  - name: vg_factbillingdeposit_transactionsandattributes
    full_name: main.bi_output.vg_factbillingdeposit_transactionsandattributes
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
      - main.general.bronze_etoro_dictionary_cardtype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
      - main.general.bronze_etoro_dictionary_riskmanagementstatus
      - main.general.bronze_etoro_dictionary_country
      - main.general.bronze_etoro_dictionary_regulation
    refs_source: view_definition (regex extract)
  - name: vg_factbillingwithdraw_transactionsandattributes
    full_name: main.bi_output.vg_factbillingwithdraw_transactionsandattributes
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus
      - main.general.bronze_etoro_dictionary_cashoutreason
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
      - main.general.bronze_etoro_dictionary_cardtype
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
      - main.general.bronze_etoro_dictionary_country
    refs_source: view_definition (regex extract)
  - name: vg_fullbincodelist
    full_name: main.bi_output.vg_fullbincodelist
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.general.bronze_etoro_dictionary_countrybin
      - main.general.bronze_etoro_dictionary_country
      - main.general.bronze_etoro_dictionary_cardtype
      - main.billing.bronze_etoro_billing_badbin
    refs_source: view_definition (regex extract)
  - name: vg_payments_mimo_allplatformddr_genienew
    full_name: main.bi_output.vg_payments_mimo_allplatformddr_genienew
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
      - main.bi_db.bronze_moneytransfer_billing_transfers
    refs_source: view_definition (regex extract)
  - name: vg_payments_mimo_basedonddrallplatfrommimo_for_genie
    full_name: main.bi_output.vg_payments_mimo_basedonddrallplatfrommimo_for_genie
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
      - dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
      - bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
      - bi_db.bronze_moneytransfer_billing_transfers
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
    refs_source: view_definition (regex extract)
  - name: vg_positions_open_closed_iban_tp
    full_name: main.bi_output.vg_positions_open_closed_iban_tp
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
      - main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet
      - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
    refs_source: view_definition (regex extract)
  - name: vg_positionsvolumeandattributes_lc4_source
    full_name: main.bi_output.vg_positionsvolumeandattributes_lc4_source
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
      - main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet
    refs_source: view_definition (regex extract)
  - name: vg_positionsvolumeandattributes_lc4_source_test1
    full_name: main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.dim_position
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
      - main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet
    refs_source: view_definition (regex extract)
  - name: vg_trades
    full_name: main.bi_output.vg_trades
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
      - DWH_dbo.Dim_Position
    refs_source: view_definition (regex extract)
---

# bi_output — Schema Card

> UC-Pipeline scope sheet for `main.bi_output`. **123 in-scope** / **21 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `bi_ouput_v_dim_instrumenttype` | `VIEW` | `view_definition` | `view_definition` |
| `bi_ouput_vg_etoro_emoney` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_compliance_kycscreeninglimitation` | `EXTERNAL` | `DBSQL_QUERY` | `982b26eb-dea3-4ee6-847b-81a6b3aa146d` |
| `bi_output_customer_compliance_mas_daily_client_metrics` | `EXTERNAL` | `JOB` | `623823172493742` |
| `bi_output_customer_compliance_mas_population` | `EXTERNAL` | `JOB` | `449767041129740` |
| `bi_output_customer_compliance_uk_social_activity_monitoring` | `EXTERNAL` | `JOB` | `938227598135468` |
| `bi_output_customer_compliance_uk_social_activity_monitoring_m` | `EXTERNAL` | `JOB` | `949872433798828` |
| `bi_output_customer_customer_facing_agent_engagement` | `EXTERNAL` | `JOB` | `717988584710279` |
| `bi_output_customer_customer_facing_club_club_equity` | `EXTERNAL` | `JOB` | `769316685964205` |
| `bi_output_customer_customer_facing_club_club_offer_eligibilty` | `EXTERNAL` | `NOTEBOOK` | `1200434159941085` |
| `bi_output_customer_customer_facing_pageviews_behaviour` | `EXTERNAL` | `JOB` | `905616356190643` |
| `bi_output_customer_customer_facing_survey` | `EXTERNAL` | `JOB` | `688763458383547` |
| `bi_output_customer_customer_facing_survey_taker` | `EXTERNAL` | `JOB` | `213935658623860` |
| `bi_output_customer_customer_facing_triggers` | `EXTERNAL` | `JOB` | `29439054239650` |
| `bi_output_customer_customer_facing_triggers_filtered` | `EXTERNAL` | `JOB` | `890492072529400` |
| `bi_output_customer_customer_facing_triggers_lead_score` | `EXTERNAL` | `JOB` | `986217717349184` |
| `bi_output_customer_customer_support_agent_user` | `EXTERNAL` | `JOB` | `418338092021449` |
| `bi_output_customer_customer_support_aml_handling_days` | `EXTERNAL` | `JOB` | `172887083112065` |
| `bi_output_customer_customer_support_case` | `EXTERNAL` | `JOB` | `321086379460094` |
| `bi_output_customer_customer_support_case_event` | `EXTERNAL` | `JOB` | `275066326823389` |
| `bi_output_customer_customer_support_customer_engagement` | `EXTERNAL` | `JOB` | `130009652999855` |
| `bi_output_customer_customer_support_task` | `EXTERNAL` | `JOB` | `594912967306162` |
| `bi_output_customer_external_table_isa` | `EXTERNAL` | `JOB` | `405360254380378` |
| `bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global` | `EXTERNAL` | `JOB` | `262147853791452` |
| `bi_output_customer_social_social_feed` | `EXTERNAL` | `JOB` | `1046492620820074` |
| `bi_output_deltaapp_subscription_view` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external` | `EXTERNAL` | `JOB` | `131261705122566` |
| `bi_output_finance_external_table_bi_db_sharelending_reconciliation_external` | `EXTERNAL` | `JOB` | `641107617594072` |
| `bi_output_finance_tables_bi_db_hedge_nettingbalance` | `EXTERNAL` | `JOB` | `737650008422339` |
| `bi_output_finance_tables_bi_db_positions_closed_to_iban` | `EXTERNAL` | `DBSQL_QUERY` | `88a61c9d-50c8-4516-a27d-ed802ebae419` |
| `bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | `EXTERNAL` | `DBSQL_QUERY` | `88a61c9d-50c8-4516-a27d-ed802ebae419` |
| `bi_output_finance_tables_bi_db_positions_opened_from_iban` | `EXTERNAL` | `DBSQL_QUERY` | `6db2e20c-4cb2-4bbb-86ae-fbb3baeae78c` |
| `bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | `EXTERNAL` | `DBSQL_QUERY` | `6db2e20c-4cb2-4bbb-86ae-fbb3baeae78c` |
| `bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet` | `EXTERNAL` | `DBSQL_QUERY` | `05293a5b-1d3b-4302-9856-f4cbc6942396` |
| `bi_output_finance_tables_bi_db_sharelending_collateraldetaileseu` | `EXTERNAL` | `JOB` | `725538823326366` |
| `bi_output_finance_tables_bi_db_sharelending_collateraldetailesmain` | `EXTERNAL` | `JOB` | `872666614904699` |
| `bi_output_finance_tables_bi_db_sharelending_collateraldetailesuk` | `EXTERNAL` | `JOB` | `47673804099153` |
| `bi_output_finance_tables_bi_db_sharelending_custodyreconciliation` | `EXTERNAL` | `NOTEBOOK` | `929841887099956` |
| `bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu` | `EXTERNAL` | `JOB` | `886170903386595` |
| `bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk` | `EXTERNAL` | `JOB` | `790443493174283` |
| `bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu` | `EXTERNAL` | `JOB` | `230453999952504` |
| `bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain` | `EXTERNAL` | `JOB` | `27544170671570` |
| `bi_output_finance_tables_bi_db_sharelending_loansandcollateraluk` | `EXTERNAL` | `JOB` | `470769329960226` |
| `bi_output_finance_tables_bi_db_sharelending_price_estimated` | `EXTERNAL` | `JOB` | `769525096189601` |
| `bi_output_finance_tables_bi_db_sharelending_reconciliation` | `EXTERNAL` | `JOB` | `333631390353161` |
| `bi_output_finance_tables_ptp_tax` | `EXTERNAL` | `JOB` | `681844067999280` |
| `bi_output_fullname_apiresults` | `MANAGED` | `JOB` | `384802822442789` |
| `bi_output_marketing_acquisition_demo` | `EXTERNAL` | `JOB` | `962658155699673` |
| `bi_output_marketing_acquisition_liveacquisition` | `EXTERNAL` | `DBSQL_QUERY` | `78916582-774e-46cc-8195-8a41a333aa6f` |
| `bi_output_marketing_affiliate_payments_report_closed_position` | `EXTERNAL` | `JOB` | `131117946631349` |
| `bi_output_marketing_liveacquisitiondashboard` | `EXTERNAL` | `JOB` | `362438626229151` |
| `bi_output_marketing_marketingcloud_user_behavior_instrument_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_marketing_marketingcloud_user_behavior_pi_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_marketing_promotion_bi_db_promo_card` | `EXTERNAL` | `JOB` | `1044486077439857` |
| `bi_output_marketing_sfmc_sfmc_filter` | `EXTERNAL` | `JOB` | `618867936130004` |
| `bi_output_marketing_sfmc_sfmc_report` | `EXTERNAL` | `JOB` | `127029817878171` |
| `bi_output_moneyfarm_customers` | `EXTERNAL` | `JOB` | `909845381518474` |
| `bi_output_moneyfarm_fact_portfolio_snapshot` | `EXTERNAL` | `JOB` | `909845381518474` |
| `bi_output_moneyfarm_fact_transactions` | `EXTERNAL` | `JOB` | `909845381518474` |
| `bi_output_regtechops_wash_trading_alerts_daily` | `EXTERNAL` | `JOB` | `832857154712514` |
| `bi_output_urban_notifications_daily_panel` | `EXTERNAL` | `DBSQL_QUERY` | `1e56fdd1-177f-4f99-ac29-1aa01e651514` |
| `bi_output_urban_notifications_daily_panel_agg` | `EXTERNAL` | `DBSQL_QUERY` | `259a1f94-441c-43c2-bd95-11b2ed9d69fa` |
| `bi_output_urban_notifications_monthly_lsd` | `EXTERNAL` | `DBSQL_QUERY` | `97133d78-c951-4751-be0d-a80338fc9d6b` |
| `bi_output_v_recurring_investment` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_aum` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_case` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_case_event` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_cf_crm_contact` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_club` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_club_offers` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_copy_mimo` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_crm_user` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_customer_assignment` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_customer_first_dates` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_customer_snapshot` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_customer_snapshot_test` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_customer_snapshot_v2` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_daily_commission` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_date` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_ddr_customers_snapshot` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_mimo` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_parentcid` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_revenue` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_vg_volume_amount` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_wf_view` | `VIEW` | `view_definition` | `view_definition` |
| `current` | `VIEW` | `view_definition` | `view_definition` |
| `current_table` | `VIEW` | `view_definition` | `view_definition` |
| `finance_tables_functions_revenue_sdrt` | `VIEW` | `view_definition` | `view_definition` |
| `finance_tables_functions_revenue_trading_fees` | `VIEW` | `view_definition` | `view_definition` |
| `funded` | `VIEW` | `view_definition` | `view_definition` |
| `limitation_to_normal_conversion` | `VIEW` | `view_definition` | `view_definition` |
| `negative_nmi` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `nmi_by_portfoliopi_new` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `positionsvolumeandattributes_lc4_source` | `VIEW` | `view_definition` | `view_definition` |
| `positive_nmi` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `positive_nmi_commodities` | `MATERIALIZED_VIEW` | `view_definition` | `view_definition` |
| `snapshot` | `VIEW` | `view_definition` | `view_definition` |
| `snapshot_table` | `VIEW` | `view_definition` | `view_definition` |
| `v_external_france_wealth_contracts_transactions` | `VIEW` | `view_definition` | `view_definition` |
| `vg_acquisitionfunnel_em1` | `VIEW` | `view_definition` | `view_definition` |
| `vg_bidb_alldeposits_for_genie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoney_card_instance_summary` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoney_card_transactions` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoney_openbankingdeposit` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoney_panel_firstdates_em1` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoney_potentialclients_attributes` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoney_txs` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoneydimaccount_forgenie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_emoneydimtransaction_forgenie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_fact_billingdeposit_for_genie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_fact_billingdepost_forgenie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_fact_billingdepost_forgenie_new` | `VIEW` | `view_definition` | `view_definition` |
| `vg_fact_billingwithdraw_for_genie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_fact_snapshotcustomer_for_emoney_genie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_factbillingdeposit_transactionsandattributes` | `VIEW` | `view_definition` | `view_definition` |
| `vg_factbillingwithdraw_transactionsandattributes` | `VIEW` | `view_definition` | `view_definition` |
| `vg_fullbincodelist` | `VIEW` | `view_definition` | `view_definition` |
| `vg_payments_mimo_allplatformddr_genienew` | `VIEW` | `view_definition` | `view_definition` |
| `vg_payments_mimo_basedonddrallplatfrommimo_for_genie` | `VIEW` | `view_definition` | `view_definition` |
| `vg_positions_open_closed_iban_tp` | `VIEW` | `view_definition` | `view_definition` |
| `vg_positionsvolumeandattributes_lc4_source` | `VIEW` | `view_definition` | `view_definition` |
| `vg_positionsvolumeandattributes_lc4_source_test1` | `VIEW` | `view_definition` | `view_definition` |
| `vg_trades` | `VIEW` | `view_definition` | `view_definition` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `bi_ouput_mvg_etoro_emoney` | `METRIC_VIEW` | VIEW has empty view_definition (catalog metadata broken) |
| `bi_output_customer_customer_facing_am_survey` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_facing_club_inventory_asset` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_facing_club_loyalty_offer` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_facing_club_loyalty_offer_request` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_support_csat` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_support_live_chat_transcript` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_support_salesforce_reply` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_ddr_revenue_metrics` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_external_table_club_equity` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_dealing_tables_bi_db_latency_compensation` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_finance_tables_all_trades_pivoted_net_vol` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_finance_tables_bi_db_share_lending_allocation` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_finance_tables_customer_customer_deceased` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_finance_tables_ptp_tax_backup` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_finance_tables_share_lending_aggregate` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_finance_tables_tax_ptp_monitoring` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_marketing_acquisition_anomaly` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_marketing_marketingcloud_user_behavior_instrument` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_marketing_marketingcloud_user_behavior_pi` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_operations_documentanalysis` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
