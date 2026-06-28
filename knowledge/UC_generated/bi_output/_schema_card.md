---
schema: bi_output
catalog: main
display_name: bi_output — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-06-19T14:30:28Z"
lineage_lookback_days: 90
in_scope_count: 128
out_of_scope_count: 22
objects:
  - name: australia_tag_ob_june26
    full_name: main.bi_output.australia_tag_ob_june26
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
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
      path: 309351277641590
      lineage_source: system.access.table_lineage
      lineage_event_count: 12
      additional_producers:
        - entity_type: JOB
          entity_id: 833530294335349
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-06-08T04:10:39.183000+00:00"
          last_event_time: "2026-06-08T04:10:39.183000+00:00"
        - entity_type: JOB
          entity_id: 1110022035897935
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-06-16T04:24:43.789000+00:00"
          last_event_time: "2026-06-16T04:24:43.789000+00:00"
        - entity_type: JOB
          entity_id: 835581948584997
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-06-05T04:21:45.020000+00:00"
          last_event_time: "2026-06-05T04:21:45.020000+00:00"
        - entity_type: JOB
          entity_id: 591936365909804
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-06-04T04:20:11.522000+00:00"
          last_event_time: "2026-06-04T04:20:11.522000+00:00"
    in_scope: true
  - name: bi_output_customer_compliance_mas_population
    full_name: main.bi_output.bi_output_customer_compliance_mas_population
    type: EXTERNAL
    writer:
      kind: JOB
      path: 805356250031497
      lineage_source: system.access.table_lineage
      lineage_event_count: 25
      additional_producers:
        - entity_type: JOB
          entity_id: 865384098106911
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-04-13T06:36:27.539000+00:00"
          last_event_time: "2026-04-13T06:36:27.539000+00:00"
        - entity_type: JOB
          entity_id: 87526057583150
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-06-10T10:20:43.232000+00:00"
          last_event_time: "2026-06-10T10:20:43.232000+00:00"
        - entity_type: JOB
          entity_id: 485550692264663
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-04-06T06:13:12.909000+00:00"
          last_event_time: "2026-04-06T06:13:12.909000+00:00"
        - entity_type: JOB
          entity_id: 956270074536764
          workspace_id: 6358342630366312
          event_count: 25
          first_event_time: "2026-04-09T07:13:33.962000+00:00"
          last_event_time: "2026-04-09T07:13:33.962000+00:00"
    in_scope: true
  - name: bi_output_customer_compliance_uk_social_activity_monitoring
    full_name: main.bi_output.bi_output_customer_compliance_uk_social_activity_monitoring
    type: EXTERNAL
    writer:
      kind: JOB
      path: 328065480649847
      lineage_source: system.access.table_lineage
      lineage_event_count: 3
      additional_producers:
        - entity_type: JOB
          entity_id: 467666994190822
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-06-05T05:22:50.425000+00:00"
          last_event_time: "2026-06-05T05:22:50.425000+00:00"
        - entity_type: JOB
          entity_id: 862511519794275
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-03-24T05:02:41.339000+00:00"
          last_event_time: "2026-03-24T05:02:41.339000+00:00"
        - entity_type: JOB
          entity_id: 370885485193870
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-06-12T05:08:47.085000+00:00"
          last_event_time: "2026-06-12T05:08:47.085000+00:00"
        - entity_type: JOB
          entity_id: 799892091715112
          workspace_id: 6358342630366312
          event_count: 3
          first_event_time: "2026-06-02T05:25:26.179000+00:00"
          last_event_time: "2026-06-02T05:25:26.179000+00:00"
    in_scope: true
  - name: bi_output_customer_compliance_uk_social_activity_monitoring_m
    full_name: main.bi_output.bi_output_customer_compliance_uk_social_activity_monitoring_m
    type: EXTERNAL
    writer:
      kind: JOB
      path: 689337997854859
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: JOB
          entity_id: 461720669120700
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-06-10T05:14:54.530000+00:00"
          last_event_time: "2026-06-10T05:14:54.530000+00:00"
        - entity_type: JOB
          entity_id: 601179742075768
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-05-31T04:55:33.126000+00:00"
          last_event_time: "2026-05-31T04:55:33.126000+00:00"
        - entity_type: JOB
          entity_id: 614280227833310
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-06-13T05:13:24.801000+00:00"
          last_event_time: "2026-06-13T05:13:24.801000+00:00"
        - entity_type: JOB
          entity_id: 800200691196089
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-06-02T05:21:40.561000+00:00"
          last_event_time: "2026-06-02T05:21:40.561000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_agent_engagement
    full_name: main.bi_output.bi_output_customer_customer_facing_agent_engagement
    type: EXTERNAL
    writer:
      kind: JOB
      path: 297355623751529
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 466278966866295
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-23T04:58:46.278000+00:00"
          last_event_time: "2026-03-23T04:59:06.957000+00:00"
        - entity_type: JOB
          entity_id: 528269003055618
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-06-09T05:32:31.786000+00:00"
          last_event_time: "2026-06-09T05:33:31.308000+00:00"
        - entity_type: JOB
          entity_id: 706912287692319
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-21T10:37:44.465000+00:00"
          last_event_time: "2026-03-21T10:38:16.066000+00:00"
        - entity_type: JOB
          entity_id: 706881562897745
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-03-24T05:06:10.008000+00:00"
          last_event_time: "2026-03-24T05:06:34.702000+00:00"
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
      path: 827827689353078
      lineage_source: system.access.table_lineage
      lineage_event_count: 9
      additional_producers:
        - entity_type: JOB
          entity_id: 641000047176799
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-04-07T05:43:45.223000+00:00"
          last_event_time: "2026-04-07T05:44:25.243000+00:00"
        - entity_type: JOB
          entity_id: 773586718759264
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-04-08T05:42:48.327000+00:00"
          last_event_time: "2026-04-08T05:43:29.508000+00:00"
        - entity_type: JOB
          entity_id: 401089700247867
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-04-05T05:40:02.734000+00:00"
          last_event_time: "2026-04-05T05:40:47.186000+00:00"
        - entity_type: JOB
          entity_id: 578423421935457
          workspace_id: 6358342630366312
          event_count: 9
          first_event_time: "2026-04-06T05:55:43.468000+00:00"
          last_event_time: "2026-04-06T05:56:18.805000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_club_club_offer_eligibilty
    full_name: main.bi_output.bi_output_customer_customer_facing_club_club_offer_eligibilty
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
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
      path: 700698749963412
      lineage_source: system.access.table_lineage
      lineage_event_count: 6
      additional_producers:
        - entity_type: JOB
          entity_id: 357238997048383
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-06-08T05:02:53.192000+00:00"
          last_event_time: "2026-06-08T05:02:53.192000+00:00"
        - entity_type: JOB
          entity_id: 25215901904242
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-01T04:59:53.588000+00:00"
          last_event_time: "2026-04-01T04:59:53.588000+00:00"
        - entity_type: JOB
          entity_id: 1114675703180798
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-06-17T05:11:04.908000+00:00"
          last_event_time: "2026-06-17T05:11:04.908000+00:00"
        - entity_type: JOB
          entity_id: 288070280167559
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-06-05T05:12:08.244000+00:00"
          last_event_time: "2026-06-05T05:12:08.244000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_survey
    full_name: main.bi_output.bi_output_customer_customer_facing_survey
    type: EXTERNAL
    writer:
      kind: JOB
      path: 348629853631869
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 184982044232794
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-16T10:32:55.004000+00:00"
          last_event_time: "2026-05-16T10:32:55.004000+00:00"
        - entity_type: JOB
          entity_id: 747115244837338
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-08T07:51:13.688000+00:00"
          last_event_time: "2026-04-08T07:51:13.688000+00:00"
        - entity_type: JOB
          entity_id: 262916450261793
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-13T07:50:59.505000+00:00"
          last_event_time: "2026-05-13T07:50:59.505000+00:00"
        - entity_type: JOB
          entity_id: 183237473211861
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-12T07:50:49.226000+00:00"
          last_event_time: "2026-05-12T07:50:49.226000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_survey_taker
    full_name: main.bi_output.bi_output_customer_customer_facing_survey_taker
    type: EXTERNAL
    writer:
      kind: JOB
      path: 363858712091922
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 440390444241455
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-25T09:49:11.198000+00:00"
          last_event_time: "2026-04-25T09:49:11.198000+00:00"
        - entity_type: JOB
          entity_id: 975819301582794
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-21T07:54:01.823000+00:00"
          last_event_time: "2026-05-21T07:54:01.823000+00:00"
        - entity_type: JOB
          entity_id: 716494960125859
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-23T08:45:09.146000+00:00"
          last_event_time: "2026-03-23T08:45:09.146000+00:00"
        - entity_type: JOB
          entity_id: 931160506542812
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-15T09:48:42.516000+00:00"
          last_event_time: "2026-04-15T09:48:42.516000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_triggers
    full_name: main.bi_output.bi_output_customer_customer_facing_triggers
    type: EXTERNAL
    writer:
      kind: JOB
      path: 680627382315032
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 707437118756601
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-29T09:00:56.853000+00:00"
          last_event_time: "2026-05-29T09:00:56.853000+00:00"
        - entity_type: JOB
          entity_id: 299161491092090
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-04T09:00:21.497000+00:00"
          last_event_time: "2026-06-04T09:00:21.497000+00:00"
        - entity_type: JOB
          entity_id: 692883551968715
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-17T09:03:42.652000+00:00"
          last_event_time: "2026-06-17T09:03:42.652000+00:00"
        - entity_type: JOB
          entity_id: 297119285187024
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-20T08:58:07.221000+00:00"
          last_event_time: "2026-05-20T08:58:07.221000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_triggers_filtered
    full_name: main.bi_output.bi_output_customer_customer_facing_triggers_filtered
    type: EXTERNAL
    writer:
      kind: JOB
      path: 337070951076978
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
          entity_id: 443375293390711
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-06-17T09:12:37.146000+00:00"
          last_event_time: "2026-06-17T09:12:37.146000+00:00"
        - entity_type: JOB
          entity_id: 386598941135872
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-06-01T09:15:49.946000+00:00"
          last_event_time: "2026-06-01T09:15:49.946000+00:00"
        - entity_type: JOB
          entity_id: 811193595328160
          workspace_id: 6358342630366312
          event_count: 12
          first_event_time: "2026-05-25T09:10:05.265000+00:00"
          last_event_time: "2026-05-25T09:10:05.265000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_facing_triggers_lead_score
    full_name: main.bi_output.bi_output_customer_customer_facing_triggers_lead_score
    type: EXTERNAL
    writer:
      kind: JOB
      path: 926643534805676
      lineage_source: system.access.table_lineage
      lineage_event_count: 17
      additional_producers:
        - entity_type: JOB
          entity_id: 650615430265178
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-04-17T09:10:11.740000+00:00"
          last_event_time: "2026-04-17T09:11:44.567000+00:00"
        - entity_type: JOB
          entity_id: 269625582921342
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-05-12T09:10:56.021000+00:00"
          last_event_time: "2026-05-12T09:14:29.286000+00:00"
        - entity_type: JOB
          entity_id: 144317451888160
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-23T16:45:39.804000+00:00"
          last_event_time: "2026-03-23T16:46:59.770000+00:00"
        - entity_type: JOB
          entity_id: 432696518149659
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-04-23T09:11:57.325000+00:00"
          last_event_time: "2026-04-23T09:13:29.757000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_agent_user
    full_name: main.bi_output.bi_output_customer_customer_support_agent_user
    type: EXTERNAL
    writer:
      kind: JOB
      path: 418338092021449
      lineage_source: system.access.table_lineage
      lineage_event_count: 83
    in_scope: true
  - name: bi_output_customer_customer_support_aml_handling_days
    full_name: main.bi_output.bi_output_customer_customer_support_aml_handling_days
    type: EXTERNAL
    writer:
      kind: JOB
      path: 173913543458804
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
      additional_producers:
        - entity_type: JOB
          entity_id: 166105248664680
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-14T04:57:53.266000+00:00"
          last_event_time: "2026-05-14T04:57:53.266000+00:00"
        - entity_type: JOB
          entity_id: 661823576040753
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-04-05T04:44:25.635000+00:00"
          last_event_time: "2026-04-05T04:44:25.635000+00:00"
        - entity_type: JOB
          entity_id: 783407768241031
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-04-10T04:42:24.944000+00:00"
          last_event_time: "2026-04-10T04:42:24.944000+00:00"
        - entity_type: JOB
          entity_id: 454605672385462
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-04-12T04:49:26.714000+00:00"
          last_event_time: "2026-04-12T04:49:26.714000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_case
    full_name: main.bi_output.bi_output_customer_customer_support_case
    type: EXTERNAL
    writer:
      kind: JOB
      path: 156505882521332
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 479992992206745
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-11T06:49:48.087000+00:00"
          last_event_time: "2026-05-11T06:50:14.392000+00:00"
        - entity_type: JOB
          entity_id: 808354099648126
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-06-18T05:24:25.685000+00:00"
          last_event_time: "2026-06-18T05:25:09.724000+00:00"
        - entity_type: JOB
          entity_id: 991465691800539
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-17T04:53:04.355000+00:00"
          last_event_time: "2026-05-17T04:53:39.201000+00:00"
        - entity_type: JOB
          entity_id: 855360547477935
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-13T04:21:24.826000+00:00"
          last_event_time: "2026-05-13T04:22:37.871000+00:00"
    in_scope: true
  - name: bi_output_customer_customer_support_case_event
    full_name: main.bi_output.bi_output_customer_customer_support_case_event
    type: EXTERNAL
    writer:
      kind: JOB
      path: 817003416693782
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 956103896720992
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-17T05:29:14.960000+00:00"
          last_event_time: "2026-05-17T05:29:14.960000+00:00"
        - entity_type: JOB
          entity_id: 141666308015503
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-17T05:17:19.344000+00:00"
          last_event_time: "2026-05-17T05:17:19.344000+00:00"
        - entity_type: JOB
          entity_id: 570891631132880
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-12T04:58:05.253000+00:00"
          last_event_time: "2026-05-12T04:58:05.253000+00:00"
        - entity_type: JOB
          entity_id: 963101461662211
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-15T04:45:23.485000+00:00"
          last_event_time: "2026-05-15T04:45:23.485000+00:00"
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
      path: 808715575048090
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 858516535844143
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-20T04:48:14.361000+00:00"
          last_event_time: "2026-04-20T04:48:14.361000+00:00"
        - entity_type: JOB
          entity_id: 971704430367376
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-03-27T10:02:02.656000+00:00"
          last_event_time: "2026-03-27T10:02:02.656000+00:00"
        - entity_type: JOB
          entity_id: 1088546061823942
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-24T04:28:02.712000+00:00"
          last_event_time: "2026-04-24T04:28:02.712000+00:00"
        - entity_type: JOB
          entity_id: 332795066347226
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-18T09:47:28.567000+00:00"
          last_event_time: "2026-04-18T09:47:28.567000+00:00"
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
      path: 927849595684848
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
      additional_producers:
        - entity_type: JOB
          entity_id: 358399099403483
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-07T04:43:38.555000+00:00"
          last_event_time: "2026-05-07T04:43:38.555000+00:00"
        - entity_type: JOB
          entity_id: 651630562857008
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-04T04:29:51.466000+00:00"
          last_event_time: "2026-05-04T04:29:51.466000+00:00"
        - entity_type: JOB
          entity_id: 402345041632305
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-02T04:29:30.970000+00:00"
          last_event_time: "2026-05-02T04:29:30.970000+00:00"
        - entity_type: JOB
          entity_id: 385012607610026
          workspace_id: 6358342630366312
          event_count: 1
          first_event_time: "2026-05-02T04:26:22.656000+00:00"
          last_event_time: "2026-05-02T04:26:22.656000+00:00"
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
      path: 804668736496677
      lineage_source: system.access.table_lineage
      lineage_event_count: 5
      additional_producers:
        - entity_type: JOB
          entity_id: 262851652411206
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-05-07T06:30:33.642000+00:00"
          last_event_time: "2026-05-07T06:30:33.642000+00:00"
        - entity_type: JOB
          entity_id: 281715674431792
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-04-29T05:38:28.205000+00:00"
          last_event_time: "2026-04-29T05:38:28.205000+00:00"
        - entity_type: JOB
          entity_id: 618077673449321
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-05-06T05:37:40.991000+00:00"
          last_event_time: "2026-05-06T05:37:40.991000+00:00"
        - entity_type: JOB
          entity_id: 273312553781832
          workspace_id: 6358342630366312
          event_count: 5
          first_event_time: "2026-05-05T05:55:19.232000+00:00"
          last_event_time: "2026-05-05T05:55:19.232000+00:00"
    in_scope: true
  - name: bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global
    full_name: main.bi_output.bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global
    type: EXTERNAL
    writer:
      kind: JOB
      path: 582827302359479
      lineage_source: system.access.table_lineage
      lineage_event_count: 15
      additional_producers:
        - entity_type: JOB
          entity_id: 754483241423377
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-03-25T07:24:50.321000+00:00"
          last_event_time: "2026-03-25T07:41:52.485000+00:00"
        - entity_type: JOB
          entity_id: 302917138293222
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-05-25T04:19:43.181000+00:00"
          last_event_time: "2026-05-25T04:35:14.209000+00:00"
        - entity_type: JOB
          entity_id: 1066198631386029
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-03-26T04:24:23.124000+00:00"
          last_event_time: "2026-03-26T04:40:30.455000+00:00"
        - entity_type: JOB
          entity_id: 387011138445363
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-03-27T10:07:52.183000+00:00"
          last_event_time: "2026-03-27T10:24:02.597000+00:00"
    in_scope: true
  - name: bi_output_customer_social_social_feed
    full_name: main.bi_output.bi_output_customer_social_social_feed
    type: EXTERNAL
    writer:
      kind: JOB
      path: 623028034157417
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 882045167727627
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-04T04:27:56.129000+00:00"
          last_event_time: "2026-05-04T04:34:58.740000+00:00"
        - entity_type: JOB
          entity_id: 366811495035694
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-25T04:27:28.320000+00:00"
          last_event_time: "2026-05-25T04:30:03.868000+00:00"
        - entity_type: JOB
          entity_id: 1125102807515321
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-01T04:51:11.536000+00:00"
          last_event_time: "2026-05-01T04:58:15.425000+00:00"
        - entity_type: JOB
          entity_id: 174323637168473
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-30T04:31:56.412000+00:00"
          last_event_time: "2026-04-30T04:34:22.997000+00:00"
    in_scope: true
  - name: bi_output_dealing_markit_ca_stockdiv_spinoff_mapping
    full_name: main.bi_output.bi_output_dealing_markit_ca_stockdiv_spinoff_mapping
    type: EXTERNAL
    writer:
      kind: JOB
      path: 371057093384848
      lineage_source: system.access.table_lineage
      lineage_event_count: 84
      additional_producers:
        - entity_type: JOB
          entity_id: 565468663476942
          workspace_id: 5142916747090026
          event_count: 8
          first_event_time: "2026-06-01T07:56:07.925000+00:00"
          last_event_time: "2026-06-04T07:00:50.755000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 4488277568373449
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-18T11:31:41.475000+00:00"
          last_event_time: "2026-05-18T11:31:41.475000+00:00"
    in_scope: true
  - name: bi_output_dealing_markit_ca_stockdiv_spinoff_report
    full_name: main.bi_output.bi_output_dealing_markit_ca_stockdiv_spinoff_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 371057093384848
      lineage_source: system.access.table_lineage
      lineage_event_count: 84
      additional_producers:
        - entity_type: JOB
          entity_id: 565468663476942
          workspace_id: 5142916747090026
          event_count: 8
          first_event_time: "2026-06-01T07:56:04.739000+00:00"
          last_event_time: "2026-06-04T07:00:45.334000+00:00"
        - entity_type: NOTEBOOK
          entity_id: 4488277568373449
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-18T11:31:37.014000+00:00"
          last_event_time: "2026-05-18T11:31:37.014000+00:00"
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
  - name: bi_output_emoney_datapipeline_cardinstancelaststatus
    full_name: main.bi_output.bi_output_emoney_datapipeline_cardinstancelaststatus
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1033598147936602
      lineage_source: system.access.table_lineage
      lineage_event_count: 132
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 265530480782037
          workspace_id: 5142916747090026
          event_count: 110
          first_event_time: "2026-06-01T12:35:32.634000+00:00"
          last_event_time: "2026-06-03T08:01:16.023000+00:00"
    in_scope: true
  - name: bi_output_emoney_datapipeline_cardtokenseventlog
    full_name: main.bi_output.bi_output_emoney_datapipeline_cardtokenseventlog
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1033598147936602
      lineage_source: system.access.table_lineage
      lineage_event_count: 60
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 265530480782037
          workspace_id: 5142916747090026
          event_count: 50
          first_event_time: "2026-06-01T12:29:54.006000+00:00"
          last_event_time: "2026-06-03T07:56:52.156000+00:00"
    in_scope: true
  - name: bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external
    full_name: main.bi_output.bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external
    type: EXTERNAL
    writer:
      kind: JOB
      path: 1103202921978834
      lineage_source: system.access.table_lineage
      lineage_event_count: 16
      additional_producers:
        - entity_type: JOB
          entity_id: 374194556838886
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-05-01T06:56:00.834000+00:00"
          last_event_time: "2026-05-01T06:56:00.834000+00:00"
        - entity_type: JOB
          entity_id: 1090361414081291
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-04-21T07:05:16.312000+00:00"
          last_event_time: "2026-04-21T07:05:16.312000+00:00"
        - entity_type: JOB
          entity_id: 539911118913922
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-04-22T07:06:00.270000+00:00"
          last_event_time: "2026-04-22T07:06:00.270000+00:00"
        - entity_type: JOB
          entity_id: 366335424855208
          workspace_id: 6358342630366312
          event_count: 16
          first_event_time: "2026-04-30T07:02:26.062000+00:00"
          last_event_time: "2026-04-30T07:02:26.062000+00:00"
    in_scope: true
  - name: bi_output_finance_external_table_bi_db_sharelending_reconciliation_external
    full_name: main.bi_output.bi_output_finance_external_table_bi_db_sharelending_reconciliation_external
    type: EXTERNAL
    writer:
      kind: JOB
      path: 684080773031278
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 112647244818706
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-06-16T05:30:30.339000+00:00"
          last_event_time: "2026-06-16T05:30:30.339000+00:00"
        - entity_type: JOB
          entity_id: 500335043750087
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-02T05:33:30.858000+00:00"
          last_event_time: "2026-04-02T05:33:30.858000+00:00"
        - entity_type: JOB
          entity_id: 90144617245260
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-06-01T11:21:20.899000+00:00"
          last_event_time: "2026-06-01T11:21:20.899000+00:00"
        - entity_type: JOB
          entity_id: 342109409921578
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-06-12T06:00:16.630000+00:00"
          last_event_time: "2026-06-12T06:00:16.630000+00:00"
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
      path: 50023759390111
      lineage_source: system.access.table_lineage
      lineage_event_count: 4
      additional_producers:
        - entity_type: JOB
          entity_id: 800786333882341
          workspace_id: 6358342630366312
          event_count: 4
          first_event_time: "2026-06-09T10:30:58.979000+00:00"
          last_event_time: "2026-06-09T10:30:58.979000+00:00"
        - entity_type: JOB
          entity_id: 81825062106454
          workspace_id: 6358342630366312
          event_count: 4
          first_event_time: "2026-06-13T06:42:39.499000+00:00"
          last_event_time: "2026-06-13T06:42:39.499000+00:00"
        - entity_type: JOB
          entity_id: 834705058058875
          workspace_id: 6358342630366312
          event_count: 4
          first_event_time: "2026-06-09T10:47:53.814000+00:00"
          last_event_time: "2026-06-09T10:47:53.814000+00:00"
        - entity_type: JOB
          entity_id: 138804399199340
          workspace_id: 6358342630366312
          event_count: 4
          first_event_time: "2026-06-12T06:47:14.285000+00:00"
          last_event_time: "2026-06-12T06:47:14.285000+00:00"
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
      lineage_event_count: 182
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
      path: 631610118933904
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 1110048568655576
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-08T08:05:08.949000+00:00"
          last_event_time: "2026-05-08T08:06:07.658000+00:00"
        - entity_type: JOB
          entity_id: 473727521819142
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-03-30T11:26:52.529000+00:00"
          last_event_time: "2026-03-30T11:27:37.078000+00:00"
        - entity_type: JOB
          entity_id: 302687397161296
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-02T08:46:04.657000+00:00"
          last_event_time: "2026-06-02T08:46:56.536000+00:00"
        - entity_type: JOB
          entity_id: 729788907740893
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-06T08:31:14.198000+00:00"
          last_event_time: "2026-05-06T08:32:00.526000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_collateraldetailesmain
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_collateraldetailesmain
    type: EXTERNAL
    writer:
      kind: JOB
      path: 467694890974417
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 183620499026206
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-11T08:30:03.907000+00:00"
          last_event_time: "2026-06-11T08:31:29.630000+00:00"
        - entity_type: JOB
          entity_id: 388131355962550
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-04-09T08:29:00.473000+00:00"
          last_event_time: "2026-04-09T08:30:11.862000+00:00"
        - entity_type: JOB
          entity_id: 973559680722200
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-29T08:35:00.734000+00:00"
          last_event_time: "2026-05-29T08:36:34.173000+00:00"
        - entity_type: JOB
          entity_id: 745937675176612
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-17T08:28:41.529000+00:00"
          last_event_time: "2026-06-17T08:30:00.470000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_collateraldetailesuk
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_collateraldetailesuk
    type: EXTERNAL
    writer:
      kind: JOB
      path: 467694890974417
      lineage_source: system.access.table_lineage
      lineage_event_count: 10
      additional_producers:
        - entity_type: JOB
          entity_id: 183620499026206
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-11T08:31:33.958000+00:00"
          last_event_time: "2026-06-11T08:32:26.272000+00:00"
        - entity_type: JOB
          entity_id: 388131355962550
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-04-09T08:30:17.209000+00:00"
          last_event_time: "2026-04-09T08:31:15.128000+00:00"
        - entity_type: JOB
          entity_id: 973559680722200
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-05-29T08:36:38.215000+00:00"
          last_event_time: "2026-05-29T08:37:45.719000+00:00"
        - entity_type: JOB
          entity_id: 745937675176612
          workspace_id: 6358342630366312
          event_count: 10
          first_event_time: "2026-06-17T08:30:04.281000+00:00"
          last_event_time: "2026-06-17T08:30:52.713000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_custodyreconciliation
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation
    type: EXTERNAL
    writer:
      kind: NOTEBOOK
      path: 929841887099956
      lineage_source: system.access.table_lineage
      lineage_event_count: 66
      additional_producers:
        - entity_type: JOB
          entity_id: 580884697948262
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-03-23T11:21:34.864000+00:00"
          last_event_time: "2026-03-23T11:25:17.538000+00:00"
        - entity_type: JOB
          entity_id: 320506974522760
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-04-07T06:45:00.632000+00:00"
          last_event_time: "2026-04-07T06:50:38.742000+00:00"
        - entity_type: JOB
          entity_id: 539911118913922
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-04-22T06:55:48.186000+00:00"
          last_event_time: "2026-04-22T07:00:09.665000+00:00"
        - entity_type: JOB
          entity_id: 374194556838886
          workspace_id: 6358342630366312
          event_count: 17
          first_event_time: "2026-05-01T06:45:47.108000+00:00"
          last_event_time: "2026-05-01T06:52:19.758000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu
    type: EXTERNAL
    writer:
      kind: JOB
      path: 863862100713057
      lineage_source: system.access.table_lineage
      lineage_event_count: 15
      additional_producers:
        - entity_type: JOB
          entity_id: 964880925801670
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-05-04T10:56:30.364000+00:00"
          last_event_time: "2026-05-04T11:18:58.317000+00:00"
        - entity_type: JOB
          entity_id: 790443493174283
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-28T07:56:13.907000+00:00"
          last_event_time: "2026-04-28T08:24:23.045000+00:00"
        - entity_type: JOB
          entity_id: 574810617674878
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-04-14T08:18:42.434000+00:00"
          last_event_time: "2026-04-14T08:42:38.960000+00:00"
        - entity_type: JOB
          entity_id: 690838615381883
          workspace_id: 6358342630366312
          event_count: 15
          first_event_time: "2026-05-12T14:18:29.001000+00:00"
          last_event_time: "2026-05-12T14:44:38.632000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk
    type: EXTERNAL
    writer:
      kind: JOB
      path: 708395722314727
      lineage_source: system.access.table_lineage
      lineage_event_count: 14
      additional_producers:
        - entity_type: JOB
          entity_id: 143998612309105
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-04-06T10:33:33.210000+00:00"
          last_event_time: "2026-04-06T10:42:07.220000+00:00"
        - entity_type: JOB
          entity_id: 509740602067506
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-05-04T09:46:38.711000+00:00"
          last_event_time: "2026-05-04T10:02:05.742000+00:00"
        - entity_type: JOB
          entity_id: 790443493174283
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-04-28T07:55:52.695000+00:00"
          last_event_time: "2026-04-28T08:11:34.619000+00:00"
        - entity_type: JOB
          entity_id: 825485082107418
          workspace_id: 6358342630366312
          event_count: 14
          first_event_time: "2026-05-07T08:09:51.100000+00:00"
          last_event_time: "2026-05-07T08:21:50.896000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu
    type: EXTERNAL
    writer:
      kind: JOB
      path: 570194507367925
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 659571473937788
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-24T08:45:35.630000+00:00"
          last_event_time: "2026-04-24T08:46:31.611000+00:00"
        - entity_type: JOB
          entity_id: 1110048568655576
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-08T08:09:31.767000+00:00"
          last_event_time: "2026-05-08T08:10:26.691000+00:00"
        - entity_type: JOB
          entity_id: 183620499026206
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-06-11T08:37:10.231000+00:00"
          last_event_time: "2026-06-11T08:38:15.839000+00:00"
        - entity_type: JOB
          entity_id: 842652738470732
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-22T08:46:18.075000+00:00"
          last_event_time: "2026-05-22T08:48:26.621000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain
    type: EXTERNAL
    writer:
      kind: JOB
      path: 111578874992303
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 109464070728569
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-15T08:33:55.381000+00:00"
          last_event_time: "2026-05-15T08:36:18.505000+00:00"
        - entity_type: JOB
          entity_id: 313671910134377
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-04T11:28:03.544000+00:00"
          last_event_time: "2026-05-04T11:29:41.498000+00:00"
        - entity_type: JOB
          entity_id: 611419656643180
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-14T08:46:43.764000+00:00"
          last_event_time: "2026-04-14T08:48:59.061000+00:00"
        - entity_type: JOB
          entity_id: 48881563457537
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-12T08:46:21.101000+00:00"
          last_event_time: "2026-05-12T08:48:19.259000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_loansandcollateraluk
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateraluk
    type: EXTERNAL
    writer:
      kind: JOB
      path: 570194507367925
      lineage_source: system.access.table_lineage
      lineage_event_count: 11
      additional_producers:
        - entity_type: JOB
          entity_id: 659571473937788
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-04-24T08:44:31.523000+00:00"
          last_event_time: "2026-04-24T08:45:32.184000+00:00"
        - entity_type: JOB
          entity_id: 944212823380282
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-03-24T09:42:15.276000+00:00"
          last_event_time: "2026-03-24T09:44:13.529000+00:00"
        - entity_type: JOB
          entity_id: 183620499026206
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-06-11T08:35:58.881000+00:00"
          last_event_time: "2026-06-11T08:37:03.891000+00:00"
        - entity_type: JOB
          entity_id: 842652738470732
          workspace_id: 6358342630366312
          event_count: 11
          first_event_time: "2026-05-22T08:44:28.012000+00:00"
          last_event_time: "2026-05-22T08:46:03.335000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_price_estimated
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_price_estimated
    type: EXTERNAL
    writer:
      kind: JOB
      path: 391087506778862
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 147168392664945
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-06T07:45:42.296000+00:00"
          last_event_time: "2026-05-06T07:47:39.699000+00:00"
        - entity_type: JOB
          entity_id: 155981761884823
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-04T07:33:27.814000+00:00"
          last_event_time: "2026-04-04T07:35:22.771000+00:00"
        - entity_type: JOB
          entity_id: 621208269726678
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-04T07:38:00.278000+00:00"
          last_event_time: "2026-05-04T07:40:09.562000+00:00"
        - entity_type: JOB
          entity_id: 19321281211729
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-07T07:45:12.251000+00:00"
          last_event_time: "2026-05-07T07:47:10.745000+00:00"
    in_scope: true
  - name: bi_output_finance_tables_bi_db_sharelending_reconciliation
    full_name: main.bi_output.bi_output_finance_tables_bi_db_sharelending_reconciliation
    type: EXTERNAL
    writer:
      kind: JOB
      path: 472323883251842
      lineage_source: system.access.table_lineage
      lineage_event_count: 7
      additional_producers:
        - entity_type: JOB
          entity_id: 523512784446744
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-07T07:45:43.212000+00:00"
          last_event_time: "2026-05-07T07:45:43.212000+00:00"
        - entity_type: JOB
          entity_id: 624116701835965
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-10T06:01:31.543000+00:00"
          last_event_time: "2026-04-10T06:01:31.543000+00:00"
        - entity_type: JOB
          entity_id: 397807143223489
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-04-28T06:18:06.085000+00:00"
          last_event_time: "2026-04-28T06:18:06.085000+00:00"
        - entity_type: JOB
          entity_id: 748330397000434
          workspace_id: 6358342630366312
          event_count: 7
          first_event_time: "2026-05-08T06:01:45.919000+00:00"
          last_event_time: "2026-05-08T06:01:45.919000+00:00"
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
      path: 228839116876272
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 552422850718667
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-10T04:18:21.841000+00:00"
          last_event_time: "2026-05-10T04:18:30.337000+00:00"
        - entity_type: JOB
          entity_id: 639328211053905
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-03T04:17:08.205000+00:00"
          last_event_time: "2026-05-03T04:17:15.622000+00:00"
        - entity_type: JOB
          entity_id: 905951852569141
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-14T04:20:40.291000+00:00"
          last_event_time: "2026-04-14T04:20:48.243000+00:00"
        - entity_type: JOB
          entity_id: 1086307712037023
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-13T04:18:11.909000+00:00"
          last_event_time: "2026-05-13T04:18:20.084000+00:00"
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
      lineage_event_count: 819
    in_scope: true
  - name: bi_output_marketing_acquisition_liveacquisition
    full_name: main.bi_output.bi_output_marketing_acquisition_liveacquisition
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 78916582-774e-46cc-8195-8a41a333aa6f
      lineage_source: system.access.table_lineage
      lineage_event_count: 5772
    in_scope: true
  - name: bi_output_marketing_affiliate_payments_report_closed_position
    full_name: main.bi_output.bi_output_marketing_affiliate_payments_report_closed_position
    type: EXTERNAL
    writer:
      kind: JOB
      path: 99690901680762
      lineage_source: system.access.table_lineage
      lineage_event_count: 2
      additional_producers:
        - entity_type: JOB
          entity_id: 613058230054879
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-04T04:31:24.618000+00:00"
          last_event_time: "2026-05-04T04:31:24.618000+00:00"
        - entity_type: JOB
          entity_id: 278913061994684
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-08T04:22:48.457000+00:00"
          last_event_time: "2026-04-08T04:22:48.457000+00:00"
        - entity_type: JOB
          entity_id: 411802780068413
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-04-28T04:26:57.849000+00:00"
          last_event_time: "2026-04-28T04:26:57.849000+00:00"
        - entity_type: JOB
          entity_id: 643760786947838
          workspace_id: 6358342630366312
          event_count: 2
          first_event_time: "2026-05-02T04:32:34.602000+00:00"
          last_event_time: "2026-05-02T04:32:34.602000+00:00"
    in_scope: true
  - name: bi_output_marketing_liveacquisitiondashboard
    full_name: main.bi_output.bi_output_marketing_liveacquisitiondashboard
    type: EXTERNAL
    writer:
      kind: JOB
      path: 362438626229151
      lineage_source: system.access.table_lineage
      lineage_event_count: 17676
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
      lineage_event_count: 988
      additional_producers:
        - entity_type: NOTEBOOK
          entity_id: 4212210221780631
          workspace_id: 5142916747090026
          event_count: 33
          first_event_time: "2026-03-30T07:42:46.287000+00:00"
          last_event_time: "2026-05-07T15:51:44.098000+00:00"
    in_scope: true
  - name: bi_output_marketing_sfmc_sfmc_filter
    full_name: main.bi_output.bi_output_marketing_sfmc_sfmc_filter
    type: EXTERNAL
    writer:
      kind: JOB
      path: 691531654438458
      lineage_source: system.access.table_lineage
      lineage_event_count: 6
      additional_producers:
        - entity_type: JOB
          entity_id: 639608189635008
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-30T04:44:22.032000+00:00"
          last_event_time: "2026-04-30T04:44:22.032000+00:00"
        - entity_type: JOB
          entity_id: 635647354324513
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-04-08T04:51:40.986000+00:00"
          last_event_time: "2026-04-08T04:51:40.986000+00:00"
        - entity_type: JOB
          entity_id: 618867936130004
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-05-02T05:24:50.564000+00:00"
          last_event_time: "2026-05-02T05:24:50.564000+00:00"
        - entity_type: JOB
          entity_id: 373562646619705
          workspace_id: 6358342630366312
          event_count: 6
          first_event_time: "2026-05-04T04:43:40.770000+00:00"
          last_event_time: "2026-05-04T04:43:40.770000+00:00"
    in_scope: true
  - name: bi_output_marketing_sfmc_sfmc_report
    full_name: main.bi_output.bi_output_marketing_sfmc_sfmc_report
    type: EXTERNAL
    writer:
      kind: JOB
      path: 784387297730431
      lineage_source: system.access.table_lineage
      lineage_event_count: 8
      additional_producers:
        - entity_type: JOB
          entity_id: 1081811243877959
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-06-19T07:12:41.245000+00:00"
          last_event_time: "2026-06-19T07:27:29.737000+00:00"
        - entity_type: JOB
          entity_id: 759913136635000
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-04-01T06:31:27.529000+00:00"
          last_event_time: "2026-04-01T06:45:48.478000+00:00"
        - entity_type: JOB
          entity_id: 1007463961052223
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-03-31T05:55:09.098000+00:00"
          last_event_time: "2026-03-31T06:10:02.084000+00:00"
        - entity_type: JOB
          entity_id: 422964612662586
          workspace_id: 6358342630366312
          event_count: 8
          first_event_time: "2026-03-31T06:41:09.976000+00:00"
          last_event_time: "2026-03-31T06:53:58.066000+00:00"
    in_scope: true
  - name: bi_output_moneyfarm_customers
    full_name: main.bi_output.bi_output_moneyfarm_customers
    type: EXTERNAL
    writer:
      kind: JOB
      path: 909845381518474
      lineage_source: system.access.table_lineage
      lineage_event_count: 364
    in_scope: true
  - name: bi_output_moneyfarm_fact_portfolio_snapshot
    full_name: main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
    type: EXTERNAL
    writer:
      kind: JOB
      path: 909845381518474
      lineage_source: system.access.table_lineage
      lineage_event_count: 182
    in_scope: true
  - name: bi_output_moneyfarm_fact_transactions
    full_name: main.bi_output.bi_output_moneyfarm_fact_transactions
    type: EXTERNAL
    writer:
      kind: JOB
      path: 909845381518474
      lineage_source: system.access.table_lineage
      lineage_event_count: 176
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
      lineage_event_count: 76
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
      lineage_event_count: 1183
    in_scope: true
  - name: bi_output_urban_notifications_daily_panel_agg
    full_name: main.bi_output.bi_output_urban_notifications_daily_panel_agg
    type: EXTERNAL
    writer:
      kind: DBSQL_QUERY
      path: 259a1f94-441c-43c2-bd95-11b2ed9d69fa
      lineage_source: system.access.table_lineage
      lineage_event_count: 91
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
  - name: bi_output_vg_new_funded_2026_single_asset
    full_name: main.bi_output.bi_output_vg_new_funded_2026_single_asset
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
      - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
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
  - name: vg_promo_card_cashback
    full_name: main.bi_output.vg_promo_card_cashback
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_output.bi_output_marketing_promotion_bi_db_promo_card
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

> UC-Pipeline scope sheet for `main.bi_output`. **128 in-scope** / **22 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `australia_tag_ob_june26` | `VIEW` | `view_definition` | `view_definition` |
| `bi_ouput_v_dim_instrumenttype` | `VIEW` | `view_definition` | `view_definition` |
| `bi_ouput_vg_etoro_emoney` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_compliance_kycscreeninglimitation` | `EXTERNAL` | `DBSQL_QUERY` | `982b26eb-dea3-4ee6-847b-81a6b3aa146d` |
| `bi_output_customer_compliance_mas_daily_client_metrics` | `EXTERNAL` | `JOB` | `309351277641590` |
| `bi_output_customer_compliance_mas_population` | `EXTERNAL` | `JOB` | `805356250031497` |
| `bi_output_customer_compliance_uk_social_activity_monitoring` | `EXTERNAL` | `JOB` | `328065480649847` |
| `bi_output_customer_compliance_uk_social_activity_monitoring_m` | `EXTERNAL` | `JOB` | `689337997854859` |
| `bi_output_customer_customer_facing_agent_engagement` | `EXTERNAL` | `JOB` | `297355623751529` |
| `bi_output_customer_customer_facing_club_club_equity` | `EXTERNAL` | `JOB` | `827827689353078` |
| `bi_output_customer_customer_facing_pageviews_behaviour` | `EXTERNAL` | `JOB` | `700698749963412` |
| `bi_output_customer_customer_facing_survey` | `EXTERNAL` | `JOB` | `348629853631869` |
| `bi_output_customer_customer_facing_survey_taker` | `EXTERNAL` | `JOB` | `363858712091922` |
| `bi_output_customer_customer_facing_triggers` | `EXTERNAL` | `JOB` | `680627382315032` |
| `bi_output_customer_customer_facing_triggers_filtered` | `EXTERNAL` | `JOB` | `337070951076978` |
| `bi_output_customer_customer_facing_triggers_lead_score` | `EXTERNAL` | `JOB` | `926643534805676` |
| `bi_output_customer_customer_support_agent_user` | `EXTERNAL` | `JOB` | `418338092021449` |
| `bi_output_customer_customer_support_aml_handling_days` | `EXTERNAL` | `JOB` | `173913543458804` |
| `bi_output_customer_customer_support_case` | `EXTERNAL` | `JOB` | `156505882521332` |
| `bi_output_customer_customer_support_case_event` | `EXTERNAL` | `JOB` | `817003416693782` |
| `bi_output_customer_customer_support_customer_engagement` | `EXTERNAL` | `JOB` | `808715575048090` |
| `bi_output_customer_customer_support_task` | `EXTERNAL` | `JOB` | `927849595684848` |
| `bi_output_customer_external_table_isa` | `EXTERNAL` | `JOB` | `804668736496677` |
| `bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global` | `EXTERNAL` | `JOB` | `582827302359479` |
| `bi_output_customer_social_social_feed` | `EXTERNAL` | `JOB` | `623028034157417` |
| `bi_output_dealing_markit_ca_stockdiv_spinoff_mapping` | `EXTERNAL` | `JOB` | `371057093384848` |
| `bi_output_dealing_markit_ca_stockdiv_spinoff_report` | `EXTERNAL` | `JOB` | `371057093384848` |
| `bi_output_deltaapp_subscription_view` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_emoney_datapipeline_cardinstancelaststatus` | `EXTERNAL` | `JOB` | `1033598147936602` |
| `bi_output_emoney_datapipeline_cardtokenseventlog` | `EXTERNAL` | `JOB` | `1033598147936602` |
| `bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external` | `EXTERNAL` | `JOB` | `1103202921978834` |
| `bi_output_finance_external_table_bi_db_sharelending_reconciliation_external` | `EXTERNAL` | `JOB` | `684080773031278` |
| `bi_output_finance_tables_bi_db_hedge_nettingbalance` | `EXTERNAL` | `JOB` | `50023759390111` |
| `bi_output_finance_tables_bi_db_positions_closed_to_iban` | `EXTERNAL` | `DBSQL_QUERY` | `88a61c9d-50c8-4516-a27d-ed802ebae419` |
| `bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | `EXTERNAL` | `DBSQL_QUERY` | `88a61c9d-50c8-4516-a27d-ed802ebae419` |
| `bi_output_finance_tables_bi_db_positions_opened_from_iban` | `EXTERNAL` | `DBSQL_QUERY` | `6db2e20c-4cb2-4bbb-86ae-fbb3baeae78c` |
| `bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | `EXTERNAL` | `DBSQL_QUERY` | `6db2e20c-4cb2-4bbb-86ae-fbb3baeae78c` |
| `bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet` | `EXTERNAL` | `DBSQL_QUERY` | `05293a5b-1d3b-4302-9856-f4cbc6942396` |
| `bi_output_finance_tables_bi_db_sharelending_collateraldetaileseu` | `EXTERNAL` | `JOB` | `631610118933904` |
| `bi_output_finance_tables_bi_db_sharelending_collateraldetailesmain` | `EXTERNAL` | `JOB` | `467694890974417` |
| `bi_output_finance_tables_bi_db_sharelending_collateraldetailesuk` | `EXTERNAL` | `JOB` | `467694890974417` |
| `bi_output_finance_tables_bi_db_sharelending_custodyreconciliation` | `EXTERNAL` | `NOTEBOOK` | `929841887099956` |
| `bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu` | `EXTERNAL` | `JOB` | `863862100713057` |
| `bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk` | `EXTERNAL` | `JOB` | `708395722314727` |
| `bi_output_finance_tables_bi_db_sharelending_loansandcollateraleu` | `EXTERNAL` | `JOB` | `570194507367925` |
| `bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain` | `EXTERNAL` | `JOB` | `111578874992303` |
| `bi_output_finance_tables_bi_db_sharelending_loansandcollateraluk` | `EXTERNAL` | `JOB` | `570194507367925` |
| `bi_output_finance_tables_bi_db_sharelending_price_estimated` | `EXTERNAL` | `JOB` | `391087506778862` |
| `bi_output_finance_tables_bi_db_sharelending_reconciliation` | `EXTERNAL` | `JOB` | `472323883251842` |
| `bi_output_finance_tables_ptp_tax` | `EXTERNAL` | `JOB` | `228839116876272` |
| `bi_output_marketing_acquisition_demo` | `EXTERNAL` | `JOB` | `962658155699673` |
| `bi_output_marketing_acquisition_liveacquisition` | `EXTERNAL` | `DBSQL_QUERY` | `78916582-774e-46cc-8195-8a41a333aa6f` |
| `bi_output_marketing_affiliate_payments_report_closed_position` | `EXTERNAL` | `JOB` | `99690901680762` |
| `bi_output_marketing_liveacquisitiondashboard` | `EXTERNAL` | `JOB` | `362438626229151` |
| `bi_output_marketing_marketingcloud_user_behavior_instrument_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_marketing_marketingcloud_user_behavior_pi_v` | `VIEW` | `view_definition` | `view_definition` |
| `bi_output_marketing_promotion_bi_db_promo_card` | `EXTERNAL` | `JOB` | `1044486077439857` |
| `bi_output_marketing_sfmc_sfmc_filter` | `EXTERNAL` | `JOB` | `691531654438458` |
| `bi_output_marketing_sfmc_sfmc_report` | `EXTERNAL` | `JOB` | `784387297730431` |
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
| `bi_output_vg_new_funded_2026_single_asset` | `VIEW` | `view_definition` | `view_definition` |
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
| `vg_promo_card_cashback` | `VIEW` | `view_definition` | `view_definition` |
| `vg_trades` | `VIEW` | `view_definition` | `view_definition` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `bi_ouput_mvg_etoro_emoney` | `METRIC_VIEW` | VIEW has empty view_definition (catalog metadata broken) |
| `bi_output_customer_customer_facing_am_survey` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bi_output_customer_customer_facing_club_club_offer_eligibilty` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
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
