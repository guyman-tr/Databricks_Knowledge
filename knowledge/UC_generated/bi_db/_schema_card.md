---
schema: bi_db
catalog: main
display_name: bi_db — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-19T12:11:09Z"
lineage_lookback_days: 90
in_scope_count: 148
out_of_scope_count: 466
objects:
  - name: bi_output_compliance_illegal_trades_alerts_test
    full_name: main.bi_db.bi_output_compliance_illegal_trades_alerts_test
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: bronze_assignment_assignment_managerteam
    full_name: main.bi_db.bronze_assignment_assignment_managerteam
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_assignment_assignment_taskaudit
    full_name: main.bi_db.bronze_assignment_assignment_taskaudit
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_assignment_assignment_teams
    full_name: main.bi_db.bronze_assignment_assignment_teams
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_assignment_assignment_v_tasks
    full_name: main.bi_db.bronze_assignment_assignment_v_tasks
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_bigquery_affwiz
    full_name: main.bi_db.bronze_bigquery_affwiz
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_history_candles_v_history_t_pricecandle10min
    full_name: main.bi_db.bronze_candles_history_candles_v_history_t_pricecandle10min
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_history_candles_v_history_t_pricecandle15min
    full_name: main.bi_db.bronze_candles_history_candles_v_history_t_pricecandle15min
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_history_candles_v_history_t_pricecandle1min
    full_name: main.bi_db.bronze_candles_history_candles_v_history_t_pricecandle1min
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_history_candles_v_history_t_pricecandle30min
    full_name: main.bi_db.bronze_candles_history_candles_v_history_t_pricecandle30min
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_history_candles_v_history_t_pricecandle5min
    full_name: main.bi_db.bronze_candles_history_candles_v_history_t_pricecandle5min
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_history_candles_v_history_t_pricecandle60min
    full_name: main.bi_db.bronze_candles_history_candles_v_history_t_pricecandle60min
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_trade_providertoinstrument
    full_name: main.bi_db.bronze_candles_trade_providertoinstrument
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_trade_spread
    full_name: main.bi_db.bronze_candles_trade_spread
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_candles_trade_spreadtogroup
    full_name: main.bi_db.bronze_candles_trade_spreadtogroup
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_clubservice_clubs_downgraderisk
    full_name: main.bi_db.bronze_clubservice_clubs_downgraderisk
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_clubservice_clubs_userbalances
    full_name: main.bi_db.bronze_clubservice_clubs_userbalances
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_clubservice_dictionary_balancesourcetypes
    full_name: main.bi_db.bronze_clubservice_dictionary_balancesourcetypes
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_customerconsentdocuments
    full_name: main.bi_db.bronze_compliancestatedb_compliance_customerconsentdocuments
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_customerconsentplans
    full_name: main.bi_db.bronze_compliancestatedb_compliance_customerconsentplans
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_customerconsents
    full_name: main.bi_db.bronze_compliancestatedb_compliance_customerconsents
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_customerrequirementsoverviewstatus
    full_name: main.bi_db.bronze_compliancestatedb_compliance_customerrequirementsoverviewstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_customerrequirmentshistoryviewforw8ben
    full_name: main.bi_db.bronze_compliancestatedb_compliance_customerrequirmentshistoryviewforw8ben
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_customerrequirmentsview
    full_name: main.bi_db.bronze_compliancestatedb_compliance_customerrequirmentsview
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_kycflowevaluator
    full_name: main.bi_db.bronze_compliancestatedb_compliance_kycflowevaluator
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_usercryptotradingdata
    full_name: main.bi_db.bronze_compliancestatedb_compliance_usercryptotradingdata
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_userpositions
    full_name: main.bi_db.bronze_compliancestatedb_compliance_userpositions
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_compliance_verificationlevel3evaluation
    full_name: main.bi_db.bronze_compliancestatedb_compliance_verificationlevel3evaluation
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_history_autosigntncjobdetails
    full_name: main.bi_db.bronze_compliancestatedb_history_autosigntncjobdetails
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_history_customerrequirementsoverviewstatus
    full_name: main.bi_db.bronze_compliancestatedb_history_customerrequirementsoverviewstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_history_customerrestrictions
    full_name: main.bi_db.bronze_compliancestatedb_history_customerrestrictions
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_compliancestatedb_history_customertargetregulation
    full_name: main.bi_db.bronze_compliancestatedb_history_customertargetregulation
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_contactverification_phone_customer_masked
    full_name: main.bi_db.bronze_contactverification_phone_customer_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_customerfinancedb_customer_accountftds
    full_name: main.bi_db.bronze_customerfinancedb_customer_accountftds
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_customerfinancedb_customer_cutoffdateconfiguration
    full_name: main.bi_db.bronze_customerfinancedb_customer_cutoffdateconfiguration
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_customerfinancedb_customer_firsttimedeposits
    full_name: main.bi_db.bronze_customerfinancedb_customer_firsttimedeposits
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_customerfinancedb_customer_globalftds
    full_name: main.bi_db.bronze_customerfinancedb_customer_globalftds
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_databricks_postgres_public_chat_history
    full_name: main.bi_db.bronze_databricks_postgres_public_chat_history
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_databricks_postgres_public_eilon_test
    full_name: main.bi_db.bronze_databricks_postgres_public_eilon_test
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_closeexecutionplan
    full_name: main.bi_db.bronze_db_logs_history_closeexecutionplan
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_executedcloseorders
    full_name: main.bi_db.bronze_db_logs_history_executedcloseorders
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_orderforclose
    full_name: main.bi_db.bronze_db_logs_history_orderforclose
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_orderforopen
    full_name: main.bi_db.bronze_db_logs_history_orderforopen
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_orderforopen_old
    full_name: main.bi_db.bronze_db_logs_history_orderforopen_old
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_ordersfail
    full_name: main.bi_db.bronze_db_logs_history_ordersfail
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_db_logs_history_ordersmarketfail
    full_name: main.bi_db.bronze_db_logs_history_ordersmarketfail
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_dealinglogs_dictionary_instrumenteventtype
    full_name: main.bi_db.bronze_dealinglogs_dictionary_instrumenteventtype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_deltaapp_bronze_subscriptions
    full_name: main.bi_db.bronze_deltaapp_bronze_subscriptions
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_edocsdb_translation_translationrequests
    full_name: main.bi_db.bronze_edocsdb_translation_translationrequests
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_edocsdb_translation_translations
    full_name: main.bi_db.bronze_edocsdb_translation_translations
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_edocsdb_verification_checks
    full_name: main.bi_db.bronze_edocsdb_verification_checks
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_backoffice_bonustype
    full_name: main.bi_db.bronze_etoro_backoffice_bonustype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md
      source_database: etoro
      source_schema: BackOffice
      source_table: BonusType
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/BonusType
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_documentauthenticationreasons
    full_name: main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md
      source_database: etoro
      source_schema: BackOffice
      source_table: DocumentAuthenticationReasons
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/DocumentAuthenticationReasons
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_managertopermission
    full_name: main.bi_db.bronze_etoro_backoffice_managertopermission
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.ManagerToPermission.md
      source_database: etoro
      source_schema: BackOffice
      source_table: ManagerToPermission
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/ManagerToPermission
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_tncdocument
    full_name: main.bi_db.bronze_etoro_backoffice_tncdocument
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md
      source_database: etoro
      source_schema: BackOffice
      source_table: TncDocument
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/TncDocument
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_currencysettings
    full_name: main.bi_db.bronze_etoro_billing_currencysettings
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md
      source_database: etoro
      source_schema: Billing
      source_table: CurrencySettings
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/CurrencySettings
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_depositamount
    full_name: main.bi_db.bronze_etoro_billing_depositamount
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md
      source_database: etoro
      source_schema: Billing
      source_table: DepositAmount
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/DepositAmount
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_mapmerchantcodetomid
    full_name: main.bi_db.bronze_etoro_billing_mapmerchantcodetomid
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md
      source_database: etoro
      source_schema: Billing
      source_table: MapMerchantCodeToMid
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/MapMerchantCodeToMid
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_merchantaccountrouting
    full_name: main.bi_db.bronze_etoro_billing_merchantaccountrouting
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md
      source_database: etoro
      source_schema: Billing
      source_table: MerchantAccountRouting
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/MerchantAccountRouting
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_withdrawpaymentmethods
    full_name: main.bi_db.bronze_etoro_billing_withdrawpaymentmethods
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawPaymentMethods.md
      source_database: etoro
      source_schema: Billing
      source_table: WithdrawPaymentMethods
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/WithdrawPaymentMethods
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_cryptoliquidity_cryptotrade
    full_name: main.bi_db.bronze_etoro_cryptoliquidity_cryptotrade
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_cryptoliquidity_cryptowallets
    full_name: main.bi_db.bronze_etoro_cryptoliquidity_cryptowallets
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_customer_address_masked
    full_name: main.bi_db.bronze_etoro_customer_address_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md
      source_database: etoro
      source_schema: Customer
      source_table: Address
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Customer/Address_masked
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_customer_customermoney
    full_name: main.bi_db.bronze_etoro_customer_customermoney
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md
      source_database: etoro
      source_schema: Customer
      source_table: CustomerMoney
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Customer/CustomerMoney
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dbo_syn_etorogeneral_dwh_customersettings
    full_name: main.bi_db.bronze_etoro_dbo_syn_etorogeneral_dwh_customersettings
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dictionary_adminpositionstate
    full_name: main.bi_db.bronze_etoro_dictionary_adminpositionstate
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AdminPositionState.md
      source_database: etoro
      source_schema: Dictionary
      source_table: AdminPositionState
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/AdminPositionState
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_depositdrstatus
    full_name: main.bi_db.bronze_etoro_dictionary_depositdrstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositDRStatus.md
      source_database: etoro
      source_schema: Dictionary
      source_table: DepositDRStatus
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/DepositDRStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_depositstatusreason
    full_name: main.bi_db.bronze_etoro_dictionary_depositstatusreason
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositStatusReason.md
      source_database: etoro
      source_schema: Dictionary
      source_table: DepositStatusReason
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/DepositStatusReason
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_feedefinition
    full_name: main.bi_db.bronze_etoro_dictionary_feedefinition
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md
      source_database: etoro
      source_schema: Dictionary
      source_table: FeeDefinition
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/FeeDefinition
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_hedgemanualrequesttype
    full_name: main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md
      source_database: etoro
      source_schema: Dictionary
      source_table: HedgeManualRequestType
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/HedgeManualRequestType
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_interestrateoverride
    full_name: main.bi_db.bronze_etoro_dictionary_interestrateoverride
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md
      source_database: etoro
      source_schema: Dictionary
      source_table: InterestRateOverride
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/InterestRateOverride
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_openpositionactiontype
    full_name: main.bi_db.bronze_etoro_dictionary_openpositionactiontype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md
      source_database: etoro
      source_schema: Dictionary
      source_table: OpenPositionActionType
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/OpenPositionActionType
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_riskclassificationparameter
    full_name: main.bi_db.bronze_etoro_dictionary_riskclassificationparameter
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassificationParameter.md
      source_database: etoro
      source_schema: Dictionary
      source_table: RiskClassificationParameter
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/RiskClassificationParameter
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_riskclassificationregulation
    full_name: main.bi_db.bronze_etoro_dictionary_riskclassificationregulation
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassificationRegulation.md
      source_database: etoro
      source_schema: Dictionary
      source_table: RiskClassificationRegulation
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/RiskClassificationRegulation
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dictionary_withdrawtype
    full_name: main.bi_db.bronze_etoro_dictionary_withdrawtype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md
      source_database: etoro
      source_schema: Dictionary
      source_table: WithdrawType
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Dictionary/WithdrawType
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_dwh_builddwh_riskmatrix_adhoc
    full_name: main.bi_db.bronze_etoro_dwh_builddwh_riskmatrix_adhoc
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_builddwh_riskmatrix_history_delta
    full_name: main.bi_db.bronze_etoro_dwh_builddwh_riskmatrix_history_delta
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_builddwh_riskmatrix_v8
    full_name: main.bi_db.bronze_etoro_dwh_builddwh_riskmatrix_v8
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_hedgenetting
    full_name: main.bi_db.bronze_etoro_dwh_hedgenetting
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_historybackofficecustomer
    full_name: main.bi_db.bronze_etoro_dwh_historybackofficecustomer
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_v_backofficecustomerhourly
    full_name: main.bi_db.bronze_etoro_dwh_v_backofficecustomerhourly
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_v_etorogeneralcustomersettings
    full_name: main.bi_db.bronze_etoro_dwh_v_etorogeneralcustomersettings
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_dwh_v_historymirrorhourly
    full_name: main.bi_db.bronze_etoro_dwh_v_historymirrorhourly
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_hedge_accountinstrumentconfiguration
    full_name: main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md
      source_database: etoro
      source_schema: Hedge
      source_table: AccountInstrumentConfiguration
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/AccountInstrumentConfiguration
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_exposurecircuitbreakerthresholds
    full_name: main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md
      source_database: etoro
      source_schema: Hedge
      source_table: ExposureCircuitBreakerThresholds
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/ExposureCircuitBreakerThresholds
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_gethedgeserveraccountmapping
    full_name: main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md
      source_database: etoro
      source_schema: Hedge
      source_table: GetHedgeServerAccountMapping
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/GetHedgeServerAccountMapping
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_hbcaccountconfiguration
    full_name: main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md
      source_database: etoro
      source_schema: Hedge
      source_table: HBCAccountConfiguration
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/HBCAccountConfiguration
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_hedgeservertoliquidityaccount
    full_name: main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md
      source_database: etoro
      source_schema: Hedge
      source_table: HedgeServerToLiquidityAccount
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/HedgeServerToLiquidityAccount
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_instrumentconfiguration
    full_name: main.bi_db.bronze_etoro_hedge_instrumentconfiguration
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md
      source_database: etoro
      source_schema: Hedge
      source_table: InstrumentConfiguration
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/InstrumentConfiguration
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_instrumentgroups
    full_name: main.bi_db.bronze_etoro_hedge_instrumentgroups
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md
      source_database: etoro
      source_schema: Hedge
      source_table: InstrumentGroups
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/InstrumentGroups
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_instrumentgroupsmapping
    full_name: main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md
      source_database: etoro
      source_schema: Hedge
      source_table: InstrumentGroupsMapping
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/InstrumentGroupsMapping
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_hedge_providerunitconversionratio
    full_name: main.bi_db.bronze_etoro_hedge_providerunitconversionratio
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md
      source_database: etoro
      source_schema: Hedge
      source_table: ProviderUnitConversionRatio
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Hedge/ProviderUnitConversionRatio
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_closepositionendofday
    full_name: main.bi_db.bronze_etoro_history_closepositionendofday
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_history_currencypricemaxdatewithsplitview
    full_name: main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CurrencyPriceMaxDateWithSplitView.md
      source_database: etoro
      source_schema: History
      source_table: CurrencyPriceMaxDateWithSplitView
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/CurrencyPriceMaxDateWithSplitView
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_deposit_datafactory
    full_name: main.bi_db.bronze_etoro_history_deposit_datafactory
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md
      source_database: etoro
      source_schema: History
      source_table: Deposit_DataFactory
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/Deposit_DataFactory
      copy_strategy: Append
    in_scope: true
  - name: bronze_etoro_history_exposurecircuitbreakerthresholds
    full_name: main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md
      source_database: etoro
      source_schema: History
      source_table: ExposureCircuitBreakerThresholds
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/ExposureCircuitBreakerThresholds
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_hedgeinstrumentconfiguration
    full_name: main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md
      source_database: etoro
      source_schema: History
      source_table: HedgeInstrumentConfiguration
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/HedgeInstrumentConfiguration
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_hedgeservertoliquidityaccount
    full_name: main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md
      source_database: etoro
      source_schema: History
      source_table: HedgeServerToLiquidityAccount
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/HedgeServerToLiquidityAccount
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_instrumentmetadata
    full_name: main.bi_db.bronze_etoro_history_instrumentmetadata
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md
      source_database: etoro
      source_schema: History
      source_table: InstrumentMetaData
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/InstrumentMetaData
      copy_strategy: Append
    in_scope: true
  - name: bronze_etoro_history_interestrateoverride
    full_name: main.bi_db.bronze_etoro_history_interestrateoverride
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md
      source_database: etoro
      source_schema: History
      source_table: InterestRateOverride
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/InterestRateOverride
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_liquidityprovidercontracts
    full_name: main.bi_db.bronze_etoro_history_liquidityprovidercontracts
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md
      source_database: etoro
      source_schema: History
      source_table: LiquidityProviderContracts
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/LiquidityProviderContracts
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_providerinstrumenttoleverage
    full_name: main.bi_db.bronze_etoro_history_providerinstrumenttoleverage
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md
      source_database: etoro
      source_schema: History
      source_table: ProviderInstrumentToLeverage
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/ProviderInstrumentToLeverage
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_price_accountratesource
    full_name: main.bi_db.bronze_etoro_price_accountratesource
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md
      source_database: etoro
      source_schema: Price
      source_table: AccountRateSource
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Price/AccountRateSource
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_price_exchange
    full_name: main.bi_db.bronze_etoro_price_exchange
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md
      source_database: etoro
      source_schema: Price
      source_table: Exchange
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Price/Exchange
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_price_liquidityaccounttoinstrument
    full_name: main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md
      source_database: etoro
      source_schema: Price
      source_table: LiquidityAccountToInstrument
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Price/LiquidityAccountToInstrument
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_riskcalculation_scorestemporary
    full_name: main.bi_db.bronze_etoro_riskcalculation_scorestemporary
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_trade_adminpositionlog
    full_name: main.bi_db.bronze_etoro_trade_adminpositionlog
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md
      source_database: etoro
      source_schema: Trade
      source_table: AdminPositionLog
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/AdminPositionLog
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_trade_copytradesettlementrestrictions
    full_name: main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CopyTradeSettlementRestrictions.md
      source_database: etoro
      source_schema: Trade
      source_table: CopyTradeSettlementRestrictions
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/CopyTradeSettlementRestrictions
      copy_strategy: Snapshot
    in_scope: true
  - name: bronze_etoro_trade_fund
    full_name: main.bi_db.bronze_etoro_trade_fund
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md
      source_database: etoro
      source_schema: Trade
      source_table: Fund
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/Fund
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_trade_getliquidityproviders
    full_name: main.bi_db.bronze_etoro_trade_getliquidityproviders
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetLiquidityProviders.md
      source_database: etoro
      source_schema: Trade
      source_table: GetLiquidityProviders
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/GetLiquidityProviders
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_trade_instrumentcusip
    full_name: main.bi_db.bronze_etoro_trade_instrumentcusip
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.InstrumentCusip.md
      source_database: etoro
      source_schema: Trade
      source_table: InstrumentCusip
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/InstrumentCusip
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_trade_liquidityprovidertype
    full_name: main.bi_db.bronze_etoro_trade_liquidityprovidertype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md
      source_database: etoro
      source_schema: Trade
      source_table: LiquidityProviderType
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/LiquidityProviderType
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_trade_openpositionendofday
    full_name: main.bi_db.bronze_etoro_trade_openpositionendofday
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_trade_positionforexternaluse
    full_name: main.bi_db.bronze_etoro_trade_positionforexternaluse
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_trade_providerinstrumenttoleverage
    full_name: main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md
      source_database: etoro
      source_schema: Trade
      source_table: ProviderInstrumentToLeverage
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Trade/ProviderInstrumentToLeverage
      copy_strategy: Override
    in_scope: true
  - name: bronze_etorogeneral_customer_settings
    full_name: main.bi_db.bronze_etorogeneral_customer_settings
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etorogeneral_dbo_copiers_data
    full_name: main.bi_db.bronze_etorogeneral_dbo_copiers_data
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etorologs_real_hedge_emsordersstatus
    full_name: main.bi_db.bronze_etorologs_real_hedge_emsordersstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fiatdwhdb_dbo_eligibilityrules
    full_name: main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md
      source_database: FiatDwhDB
      source_schema: dbo
      source_table: EligibilityRules
      source_repo: BankingDBs
      datalake_path: Bronze/FiatDwhDB/dbo/EligibilityRules
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiatdwhdb_dbo_fiatcardinstances
    full_name: main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md
      source_database: FiatDwhDB
      source_schema: dbo
      source_table: FiatCardInstances
      source_repo: BankingDBs
      datalake_path: Bronze/FiatDwhDB/dbo/FiatCardInstances
      copy_strategy: Append
    in_scope: true
  - name: bronze_fiatdwhdb_dbo_programtransitionseligibility
    full_name: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibility.md
      source_database: FiatDwhDB
      source_schema: dbo
      source_table: ProgramTransitionsEligibility
      source_repo: BankingDBs
      datalake_path: Bronze/FiatDwhDB/dbo/ProgramTransitionsEligibility
      copy_strategy: Append
    in_scope: true
  - name: bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses
    full_name: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md
      source_database: FiatDwhDB
      source_schema: dbo
      source_table: ProgramTransitionsEligibilityStatuses
      source_repo: BankingDBs
      datalake_path: Bronze/FiatDwhDB/dbo/ProgramTransitionsEligibilityStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_fiatdwhdb_dictionary_programtransitioneligibilitysources
    full_name: main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitysources
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilitySources.md
      source_database: FiatDwhDB
      source_schema: Dictionary
      source_table: ProgramTransitionEligibilitySources
      source_repo: BankingDBs
      datalake_path: Bronze/FiatDwhDB/Dictionary/ProgramTransitionEligibilitySources
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses
    full_name: main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilityStatuses.md
      source_database: FiatDwhDB
      source_schema: Dictionary
      source_table: ProgramTransitionEligibilityStatuses
      source_repo: BankingDBs
      datalake_path: Bronze/FiatDwhDB/Dictionary/ProgramTransitionEligibilityStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
    full_name: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md
      source_database: fiktivo
      source_schema: AffiliateCommission
      source_table: ClosedPositionCommissionVW
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateCommission/ClosedPositionCommissionVW
      copy_strategy: Merge
    in_scope: true
  - name: bronze_fiktivo_affiliatecommission_closedpositionvw
    full_name: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md
      source_database: fiktivo
      source_schema: AffiliateCommission
      source_table: ClosedPositionVW
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateCommission/ClosedPositionVW
      copy_strategy: Merge
    in_scope: true
  - name: bronze_fiktivo_affiliatecommission_creditcommissionvw
    full_name: main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md
      source_database: fiktivo
      source_schema: AffiliateCommission
      source_table: CreditCommissionVW
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateCommission/CreditCommissionVW
      copy_strategy: Merge
    in_scope: true
  - name: bronze_fiktivo_affiliatecommission_creditvw
    full_name: main.bi_db.bronze_fiktivo_affiliatecommission_creditvw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md
      source_database: fiktivo
      source_schema: AffiliateCommission
      source_table: CreditVW
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateCommission/CreditVW
      copy_strategy: Merge
    in_scope: true
  - name: bronze_fiktivo_affiliatecommission_registrationcommissionvw
    full_name: main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.md
      source_database: fiktivo
      source_schema: AffiliateCommission
      source_table: RegistrationCommissionVW
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateCommission/RegistrationCommissionVW
      copy_strategy: Merge
    in_scope: true
  - name: bronze_fiktivo_affiliatecommission_registrationvw
    full_name: main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md
      source_database: fiktivo
      source_schema: AffiliateCommission
      source_table: RegistrationVW
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateCommission/RegistrationVW
      copy_strategy: Merge
    in_scope: true
  - name: bronze_fiktivo_affiliateconfiguration_traderfirstassetposition
    full_name: main.bi_db.bronze_fiktivo_affiliateconfiguration_traderfirstassetposition
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateConfiguration/Tables/AffiliateConfiguration.TraderFirstAssetPosition.md
      source_database: fiktivo
      source_schema: AffiliateConfiguration
      source_table: TraderFirstAssetPosition
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/AffiliateConfiguration/TraderFirstAssetPosition
      copy_strategy: Append
    in_scope: true
  - name: bronze_fiktivo_dbo_channels
    full_name: main.bi_db.bronze_fiktivo_dbo_channels
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md
      source_database: fiktivo
      source_schema: dbo
      source_table: Channels
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/Channels
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_mediatag
    full_name: main.bi_db.bronze_fiktivo_dbo_mediatag
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md
      source_database: fiktivo
      source_schema: dbo
      source_table: MediaTag
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/MediaTag
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_mediatagbanner
    full_name: main.bi_db.bronze_fiktivo_dbo_mediatagbanner
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTagBanner.md
      source_database: fiktivo
      source_schema: dbo
      source_table: MediaTagBanner
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/MediaTagBanner
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_affiliates
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Affiliates
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Affiliates
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_affiliates_masked
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Affiliates
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Affiliates_masked
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_affiliatesgroups
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_AffiliatesGroups
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_AffiliatesGroups
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_AffiliatesGroups
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_AffiliatesGroups_masked
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_banners
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_banners
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Banners
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Banners
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_bannertypes
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_BannerTypes.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_BannerTypes
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_BannerTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_country
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_country
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Country.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Country
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Country
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_ecost
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_eCost
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_eCost
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_ecost_commissions
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost_Commissions.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_eCost_Commissions
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_eCost_Commissions
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_firstpositions
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_FirstPositions
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_FirstPositions
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_firstpositions_commissions
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions_Commissions.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_FirstPositions_Commissions
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_FirstPositions_Commissions
      copy_strategy: Append
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_languages
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_languages
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Languages
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Languages
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_leads
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_leads
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Leads
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Leads
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_leads_commissions
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_Leads_Commissions
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_Leads_Commissions
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_marketingexpense
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_MarketingExpense.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_MarketingExpense
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_MarketingExpense
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_paymentdetails
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_PaymentDetails
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_PaymentDetails
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_paymentdetails_masked
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_PaymentDetails
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_PaymentDetails_masked
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_paymenthistory
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_PaymentHistory
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_PaymentHistory
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_user
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_user
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_User
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_User
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dbo_tblaff_user_masked
    full_name: main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md
      source_database: fiktivo
      source_schema: dbo
      source_table: tblaff_User
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/dbo/tblaff_User_masked
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dictionary_paymentmethods
    full_name: main.bi_db.bronze_fiktivo_dictionary_paymentmethods
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PaymentMethods.md
      source_database: fiktivo
      source_schema: Dictionary
      source_table: PaymentMethods
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/Dictionary/PaymentMethods
      copy_strategy: Override
    in_scope: true
  - name: bronze_fiktivo_dictionary_positionassettype
    full_name: main.bi_db.bronze_fiktivo_dictionary_positionassettype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md
      source_database: fiktivo
      source_schema: Dictionary
      source_table: PositionAssetType
      source_repo: ExperianceDBs
      datalake_path: Bronze/fiktivo/Dictionary/PositionAssetType
      copy_strategy: Override
    in_scope: true
  - name: bronze_financereports_history_request
    full_name: main.bi_db.bronze_financereports_history_request
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_financereports_reports_report
    full_name: main.bi_db.bronze_financereports_reports_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_financereports_reports_reportconfiguration
    full_name: main.bi_db.bronze_financereports_reports_reportconfiguration
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_ad_conv_new_api_v_conv_ad_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_ad_conv_new_api_v_conv_ad_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_ad_perf_new_api_v_perf_ad_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_ad_perf_new_api_v_perf_ad_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_adgroup_perf_new_api_v_conv_adgroup_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_adgroup_perf_new_api_v_conv_adgroup_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_adgroup_perf_new_api_v_perf_adgroup_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_adgroup_perf_new_api_v_perf_adgroup_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_assets_google_assets_perf
    full_name: main.bi_db.bronze_fivetran_adwords_assets_google_assets_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_campaign_perf_v_perf_campaign_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_campaign_perf_v_perf_campaign_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_geo_conv_new_api_v_conv_geo_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_geo_conv_new_api_v_conv_geo_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_geo_perf_new_api_v_perf_geo_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_geo_perf_new_api_v_perf_geo_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_geo_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_geo_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_keywords_conv_new_api_v_conv_keywords_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_keywords_conv_new_api_v_conv_keywords_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_keywords_perf_new_api_v_perf_keywords_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_keywords_perf_new_api_v_perf_keywords_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_new_api_v_campaign_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_new_api_v_campaign_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_new_api_v_conversion_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_new_api_v_conversion_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_adwords_search_conv_new_api_v_conv_search_query_performance_report
    full_name: main.bi_db.bronze_fivetran_adwords_search_conv_new_api_v_conv_search_query_performance_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_bingads_ad_group_history
    full_name: main.bi_db.bronze_fivetran_bingads_ad_group_history
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_bingads_campaign_history
    full_name: main.bi_db.bronze_fivetran_bingads_campaign_history
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_bingads_goals_and_funnels_daily_report
    full_name: main.bi_db.bronze_fivetran_bingads_goals_and_funnels_daily_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_bingads_keyword_performance_daily_report
    full_name: main.bi_db.bronze_fivetran_bingads_keyword_performance_daily_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_compliance_leverage_settings_data
    full_name: main.bi_db.bronze_fivetran_compliance_leverage_settings_data
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_active_hs_mappings
    full_name: main.bi_db.bronze_fivetran_dealing_active_hs_mappings
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_admin_fee_per_group
    full_name: main.bi_db.bronze_fivetran_dealing_admin_fee_per_group
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_gs_and_saxo_commodities_mapping
    full_name: main.bi_db.bronze_fivetran_dealing_gs_and_saxo_commodities_mapping
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_instruments_groups
    full_name: main.bi_db.bronze_fivetran_dealing_instruments_groups
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_instrumentsmapping_dailyspreadsaggregated
    full_name: main.bi_db.bronze_fivetran_dealing_instrumentsmapping_dailyspreadsaggregated
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_overnight_fees
    full_name: main.bi_db.bronze_fivetran_dealing_overnight_fees
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_dealing_units_per_contract
    full_name: main.bi_db.bronze_fivetran_dealing_units_per_contract
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_double_click_campaign_manager_dv_360_daily
    full_name: main.bi_db.bronze_fivetran_double_click_campaign_manager_dv_360_daily
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_double_click_campaign_manager_dv_360_daily_conversions
    full_name: main.bi_db.bronze_fivetran_double_click_campaign_manager_dv_360_daily_conversions
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_double_click_campaign_manager_v_media_campaign
    full_name: main.bi_db.bronze_fivetran_double_click_campaign_manager_v_media_campaign
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_facebook_cvr_facebook_conversion_actions
    full_name: main.bi_db.bronze_fivetran_facebook_cvr_facebook_conversion_actions
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_facebook_facebook_preformance_new
    full_name: main.bi_db.bronze_fivetran_facebook_facebook_preformance_new
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_ad_conv
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_ad_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_ad_perf
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_ad_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_adgroup_conv
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_adgroup_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_adgroup_perf
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_adgroup_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_campaign_conv
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_campaign_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_campaign_perf
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_campaign_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_geo_conv
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_geo_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_geo_perf
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_geo_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_kw_conv
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_kw_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_kw_perf
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_kw_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_sqr_conv
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_sqr_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_new_agg_v_google_sqr_perf
    full_name: main.bi_db.bronze_fivetran_google_new_agg_v_google_sqr_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheet_clubbenefits
    full_name: main.bi_db.bronze_fivetran_google_sheet_clubbenefits
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheet_emoney_customer_risk_assessment_manual_override_table
    full_name: main.bi_db.bronze_fivetran_google_sheet_emoney_customer_risk_assessment_manual_override_table
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_account_manager_target_500_cids
    full_name: main.bi_db.bronze_fivetran_google_sheets_account_manager_target_500_cids
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_account_manager_targets_2024
    full_name: main.bi_db.bronze_fivetran_google_sheets_account_manager_targets_2024
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_adj
    full_name: main.bi_db.bronze_fivetran_google_sheets_adj
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_aml_users_list
    full_name: main.bi_db.bronze_fivetran_google_sheets_aml_users_list
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_at_nm_setup_compliance
    full_name: main.bi_db.bronze_fivetran_google_sheets_at_nm_setup_compliance
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_attend
    full_name: main.bi_db.bronze_fivetran_google_sheets_attend
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_asic_additional_major
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_asic_additional_major
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_cfd_leverages
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_cfd_leverages
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_cross_border
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_cross_border
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_crypto_listing
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_crypto_listing
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_major_currencies
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_major_currencies
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_major_indices
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_major_indices
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_bui_test_users
    full_name: main.bi_db.bronze_fivetran_google_sheets_bui_test_users
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_capital_guarantee_alpha
    full_name: main.bi_db.bronze_fivetran_google_sheets_capital_guarantee_alpha
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_capital_guarantee_manually_approved
    full_name: main.bi_db.bronze_fivetran_google_sheets_capital_guarantee_manually_approved
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_cashback
    full_name: main.bi_db.bronze_fivetran_google_sheets_cashback
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_cashback_merchant_list_2025
    full_name: main.bi_db.bronze_fivetran_google_sheets_cashback_merchant_list_2025
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_cfd_eligible_users
    full_name: main.bi_db.bronze_fivetran_google_sheets_cfd_eligible_users
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_compliance_cryptolisting
    full_name: main.bi_db.bronze_fivetran_google_sheets_compliance_cryptolisting
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_compliance_help_table
    full_name: main.bi_db.bronze_fivetran_google_sheets_compliance_help_table
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_compliance_help_tables
    full_name: main.bi_db.bronze_fivetran_google_sheets_compliance_help_tables
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_compliance_snapshot_report_instrumentids
    full_name: main.bi_db.bronze_fivetran_google_sheets_compliance_snapshot_report_instrumentids
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_conversion_fee_discounts
    full_name: main.bi_db.bronze_fivetran_google_sheets_conversion_fee_discounts
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_cracountryriskmapping
    full_name: main.bi_db.bronze_fivetran_google_sheets_cracountryriskmapping
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_div_1099_int
    full_name: main.bi_db.bronze_fivetran_google_sheets_div_1099_int
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_eligibility_monthly_rewards
    full_name: main.bi_db.bronze_fivetran_google_sheets_eligibility_monthly_rewards
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_emoney_bank_payments_manual_entries
    full_name: main.bi_db.bronze_fivetran_google_sheets_emoney_bank_payments_manual_entries
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_emoney_customer_risk_assessment_classification_table
    full_name: main.bi_db.bronze_fivetran_google_sheets_emoney_customer_risk_assessment_classification_table
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_employee_program_cid_list
    full_name: main.bi_db.bronze_fivetran_google_sheets_employee_program_cid_list
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_equities_with_sustainability_stamp
    full_name: main.bi_db.bronze_fivetran_google_sheets_equities_with_sustainability_stamp
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_etc_fee_data_blockchain
    full_name: main.bi_db.bronze_fivetran_google_sheets_etc_fee_data_blockchain
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_excluded_cid_tin_gap_project
    full_name: main.bi_db.bronze_fivetran_google_sheets_excluded_cid_tin_gap_project
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_exw_aml_limited_accounts_new
    full_name: main.bi_db.bronze_fivetran_google_sheets_exw_aml_limited_accounts_new
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_fatca_cids
    full_name: main.bi_db.bronze_fivetran_google_sheets_fatca_cids
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_fivetran_1042_tax
    full_name: main.bi_db.bronze_fivetran_google_sheets_fivetran_1042_tax
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_fivetran_options_high_yield_interest_program_enrollee
    full_name: main.bi_db.bronze_fivetran_google_sheets_fivetran_options_high_yield_interest_program_enrollee
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_forbiddentrading
    full_name: main.bi_db.bronze_fivetran_google_sheets_forbiddentrading
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_forced_closure_list_br
    full_name: main.bi_db.bronze_fivetran_google_sheets_forced_closure_list_br
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_instruments_review_tracker
    full_name: main.bi_db.bronze_fivetran_google_sheets_instruments_review_tracker
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_investment_office_kpi_criteria
    full_name: main.bi_db.bronze_fivetran_google_sheets_investment_office_kpi_criteria
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_kyt
    full_name: main.bi_db.bronze_fivetran_google_sheets_kyt
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_kyt_alerts
    full_name: main.bi_db.bronze_fivetran_google_sheets_kyt_alerts
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_lps_for_registrations_dashboard
    full_name: main.bi_db.bronze_fivetran_google_sheets_lps_for_registrations_dashboard
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_luna_cids_jan_2023
    full_name: main.bi_db.bronze_fivetran_google_sheets_luna_cids_jan_2023
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_manually_approved
    full_name: main.bi_db.bronze_fivetran_google_sheets_manually_approved
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_manually_approved_cg
    full_name: main.bi_db.bronze_fivetran_google_sheets_manually_approved_cg
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_manually_approved_tactical_edge
    full_name: main.bi_db.bronze_fivetran_google_sheets_manually_approved_tactical_edge
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_marex_mapping_table
    full_name: main.bi_db.bronze_fivetran_google_sheets_marex_mapping_table
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_marex_mapping_table_2
    full_name: main.bi_db.bronze_fivetran_google_sheets_marex_mapping_table_2
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_marketing_subchannel_level_data
    full_name: main.bi_db.bronze_fivetran_google_sheets_marketing_subchannel_level_data
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_migration_request_form_template
    full_name: main.bi_db.bronze_fivetran_google_sheets_migration_request_form_template
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_migration_request_mt_to_fr
    full_name: main.bi_db.bronze_fivetran_google_sheets_migration_request_mt_to_fr
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_multiregulationaffiliatecompliance
    full_name: main.bi_db.bronze_fivetran_google_sheets_multiregulationaffiliatecompliance
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_pis_lists_country_level
    full_name: main.bi_db.bronze_fivetran_google_sheets_pis_lists_country_level
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_pis_lists_region_level
    full_name: main.bi_db.bronze_fivetran_google_sheets_pis_lists_region_level
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_pis_restrictions_dictionary
    full_name: main.bi_db.bronze_fivetran_google_sheets_pis_restrictions_dictionary
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_ptp_apex
    full_name: main.bi_db.bronze_fivetran_google_sheets_ptp_apex
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_ptp_ib
    full_name: main.bi_db.bronze_fivetran_google_sheets_ptp_ib
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_qmmf_totalvalue
    full_name: main.bi_db.bronze_fivetran_google_sheets_qmmf_totalvalue
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_reg_official_finra_symbols
    full_name: main.bi_db.bronze_fivetran_google_sheets_reg_official_finra_symbols
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_regionkpi
    full_name: main.bi_db.bronze_fivetran_google_sheets_regionkpi
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_registration_froad
    full_name: main.bi_db.bronze_fivetran_google_sheets_registration_froad
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_risk_score_country
    full_name: main.bi_db.bronze_fivetran_google_sheets_risk_score_country
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_rm_kpi_target
    full_name: main.bi_db.bronze_fivetran_google_sheets_rm_kpi_target
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_target_region
    full_name: main.bi_db.bronze_fivetran_google_sheets_target_region
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_tin_gep_temp_pop
    full_name: main.bi_db.bronze_fivetran_google_sheets_tin_gep_temp_pop
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_trustpilot_2026
    full_name: main.bi_db.bronze_fivetran_google_sheets_trustpilot_2026
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_trustpilot_currentdate
    full_name: main.bi_db.bronze_fivetran_google_sheets_trustpilot_currentdate
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_trustpilot_history
    full_name: main.bi_db.bronze_fivetran_google_sheets_trustpilot_history
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_vp_monthly_mi
    full_name: main.bi_db.bronze_fivetran_google_sheets_vp_monthly_mi
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_wallet_closureandreimbursementseea
    full_name: main.bi_db.bronze_fivetran_google_sheets_wallet_closureandreimbursementseea
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_wallet_closureandreimbursementseea_cysec_2025
    full_name: main.bi_db.bronze_fivetran_google_sheets_wallet_closureandreimbursementseea_cysec_2025
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_google_sheets_weekly_reportingcid_list
    full_name: main.bi_db.bronze_fivetran_google_sheets_weekly_reportingcid_list
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_regtech_euro_nat_gas
    full_name: main.bi_db.bronze_fivetran_regtech_euro_nat_gas
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_regtech_si_reporting_configurations
    full_name: main.bi_db.bronze_fivetran_regtech_si_reporting_configurations
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_additionalaffiliatesurl
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_additionalaffiliatesurl
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_blockedcountries
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_blockedcountries
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_disclaimers
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_disclaimers
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_marketableproductcountry
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_marketableproductcountry
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_regulationcountries
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_regulationcountries
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_regulationdomain
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_regulationdomain
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_sedric_etoro_mapping_sedric_regulationlanguage
    full_name: main.bi_db.bronze_fivetran_sedric_etoro_mapping_sedric_regulationlanguage
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_twitter_ads_account_history
    full_name: main.bi_db.bronze_fivetran_twitter_ads_account_history
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_twitter_ads_campaign_history
    full_name: main.bi_db.bronze_fivetran_twitter_ads_campaign_history
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_fivetran_twitter_ads_campaign_locations_report
    full_name: main.bi_db.bronze_fivetran_twitter_ads_campaign_locations_report
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_funnel_social_acqiuisition_social
    full_name: main.bi_db.bronze_funnel_social_acqiuisition_social
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_interest_history_interestconsent
    full_name: main.bi_db.bronze_interest_history_interestconsent
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_interest_trade_interestconsent
    full_name: main.bi_db.bronze_interest_trade_interestconsent
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_interest_trade_interestdaily
    full_name: main.bi_db.bronze_interest_trade_interestdaily
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_interest_trade_interestmonthly
    full_name: main.bi_db.bronze_interest_trade_interestmonthly
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_analyzer_instrumentopentime
    full_name: main.bi_db.bronze_kycanalyzer_analyzer_instrumentopentime
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_analyzer_instrumentoperationdata
    full_name: main.bi_db.bronze_kycanalyzer_analyzer_instrumentoperationdata
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_analyzer_instrumentstatus
    full_name: main.bi_db.bronze_kycanalyzer_analyzer_instrumentstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_analyzer_suitability
    full_name: main.bi_db.bronze_kycanalyzer_analyzer_suitability
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_analyzer_suitabilityrevolvingdoorquestion
    full_name: main.bi_db.bronze_kycanalyzer_analyzer_suitabilityrevolvingdoorquestion
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_analyzer_userassessmentsubreasons
    full_name: main.bi_db.bronze_kycanalyzer_analyzer_userassessmentsubreasons
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_assessmentstatuses
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_assessmentstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_clientrisklevel
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_clientrisklevel
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_instrumenttypes
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_instrumenttypes
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_question
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_question
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_recalculationreason
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_recalculationreason
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_suitabilityblock
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_suitabilityblock
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_suitabilitycalculationdetaillevel
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_suitabilitycalculationdetaillevel
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_dictionary_userassessmentfailreasons
    full_name: main.bi_db.bronze_kycanalyzer_dictionary_userassessmentfailreasons
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_history_suitability
    full_name: main.bi_db.bronze_kycanalyzer_history_suitability
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_kycanalyzer_history_suitabilitycalculationdetail
    full_name: main.bi_db.bronze_kycanalyzer_history_suitabilitycalculationdetail
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketmaker_dbo_hbchedgetrades
    full_name: main.bi_db.bronze_marketmaker_dbo_hbchedgetrades
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketmaker_dbo_v_hbchedgetrades
    full_name: main.bi_db.bronze_marketmaker_dbo_v_hbchedgetrades
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_articlemovementtype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_articlemovementtype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_articletype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_articletype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_countries
    full_name: main.bi_db.bronze_marketnotifications_dictionary_countries
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_dividendfrequencytype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_dividendfrequencytype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_exchangeinfo
    full_name: main.bi_db.bronze_marketnotifications_dictionary_exchangeinfo
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_experimentstatus
    full_name: main.bi_db.bronze_marketnotifications_dictionary_experimentstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_instrumentreferencetype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_instrumentreferencetype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_marketeventstatustype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_marketeventstatustype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_marketeventtype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_marketeventtype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_notificationstatus
    full_name: main.bi_db.bronze_marketnotifications_dictionary_notificationstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_ratechangeinterval
    full_name: main.bi_db.bronze_marketnotifications_dictionary_ratechangeinterval
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_ratechangesize
    full_name: main.bi_db.bronze_marketnotifications_dictionary_ratechangesize
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_ratechangetype
    full_name: main.bi_db.bronze_marketnotifications_dictionary_ratechangetype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_regulations
    full_name: main.bi_db.bronze_marketnotifications_dictionary_regulations
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_dictionary_streakinterval
    full_name: main.bi_db.bronze_marketnotifications_dictionary_streakinterval
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_articleevents
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_articleevents
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_currencies
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_currencies
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_dividendevents
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_dividendevents
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_earningreportevents
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_earningreportevents
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_earningreporttemplates
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_earningreporttemplates
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_instruments
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_instruments
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_ratechangetemplates
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_ratechangetemplates
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_ratechangetriggerconfigurations
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_ratechangetriggerconfigurations
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_sendallconfigurations
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_sendallconfigurations
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_streakevents
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_streakevents
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_streaktemplates
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_streaktemplates
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_streaktriggerconfigurations
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_streaktriggerconfigurations
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketnotifications_marketnotifications_templates
    full_name: main.bi_db.bronze_marketnotifications_marketnotifications_templates
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketperformance_airdrop_customer
    full_name: main.bi_db.bronze_marketperformance_airdrop_customer
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketperformance_tracking_customer
    full_name: main.bi_db.bronze_marketperformance_tracking_customer
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_applications_applications
    full_name: main.bi_db.bronze_marketplace_applications_applications
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dbo_applications
    full_name: main.bi_db.bronze_marketplace_dbo_applications
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dbo_connectedusers
    full_name: main.bi_db.bronze_marketplace_dbo_connectedusers
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dbo_publishedapplications
    full_name: main.bi_db.bronze_marketplace_dbo_publishedapplications
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dictionary_accesslevel
    full_name: main.bi_db.bronze_marketplace_dictionary_accesslevel
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dictionary_applicationstate
    full_name: main.bi_db.bronze_marketplace_dictionary_applicationstate
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dictionary_category
    full_name: main.bi_db.bronze_marketplace_dictionary_category
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dictionary_publicationstate
    full_name: main.bi_db.bronze_marketplace_dictionary_publicationstate
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketplace_dictionary_tradingmode
    full_name: main.bi_db.bronze_marketplace_dictionary_tradingmode
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_moneybusdb_dictionary_accounttypes
    full_name: main.bi_db.bronze_moneybusdb_dictionary_accounttypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md
      source_database: MoneyBusDB
      source_schema: Dictionary
      source_table: AccountTypes
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/Dictionary/AccountTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneytransfer_billing_posttransferactions
    full_name: main.bi_db.bronze_moneytransfer_billing_posttransferactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md
      source_database: MoneyTransfer
      source_schema: Billing
      source_table: PostTransferActions
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyTransfer/Billing/PostTransferActions
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneytransfer_billing_transfers
    full_name: main.bi_db.bronze_moneytransfer_billing_transfers
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md
      source_database: MoneyTransfer
      source_schema: Billing
      source_table: Transfers
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyTransfer/Billing/Transfers
      copy_strategy: Override
    in_scope: true
  - name: bronze_navigation_navigation
    full_name: main.bi_db.bronze_navigation_navigation
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_navigationservice_ns_stephistory
    full_name: main.bi_db.bronze_navigationservice_ns_stephistory
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_navigationservice_ns_userflows
    full_name: main.bi_db.bronze_navigationservice_ns_userflows
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_notificationdb_dictionary_category
    full_name: main.bi_db.bronze_notificationdb_dictionary_category
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_notificationdb_dictionary_channeltype
    full_name: main.bi_db.bronze_notificationdb_dictionary_channeltype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_notificationdb_dictionary_subcategory
    full_name: main.bi_db.bronze_notificationdb_dictionary_subcategory
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_notificationdb_notifications_notificationsettings
    full_name: main.bi_db.bronze_notificationdb_notifications_notificationsettings
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_opsdb_dbo_datalaketablestatus
    full_name: main.bi_db.bronze_opsdb_dbo_datalaketablestatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_opsdb_dbo_objectsstatus
    full_name: main.bi_db.bronze_opsdb_dbo_objectsstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_opsdb_dbo_proceduredependencies
    full_name: main.bi_db.bronze_opsdb_dbo_proceduredependencies
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_periodicrankings_ranking_periodicgain
    full_name: main.bi_db.bronze_periodicrankings_ranking_periodicgain
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_price_trade_instrumentclosingpricesourcedata
    full_name: main.bi_db.bronze_price_trade_instrumentclosingpricesourcedata
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_provedb_prove_userstate
    full_name: main.bi_db.bronze_provedb_prove_userstate
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_dictionary_marketchangetype
    full_name: main.bi_db.bronze_rankings_dictionary_marketchangetype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_dictionary_marketeventassettypes
    full_name: main.bi_db.bronze_rankings_dictionary_marketeventassettypes
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_dictionary_marketeventinterval
    full_name: main.bi_db.bronze_rankings_dictionary_marketeventinterval
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_dictionary_notificationtype
    full_name: main.bi_db.bronze_rankings_dictionary_notificationtype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_dictionary_ratechangetype
    full_name: main.bi_db.bronze_rankings_dictionary_ratechangetype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_history_monthlygainanon
    full_name: main.bi_db.bronze_rankings_history_monthlygainanon
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_marketevents_activecustomers
    full_name: main.bi_db.bronze_rankings_marketevents_activecustomers
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_marketevents_alltimeeventcustomers
    full_name: main.bi_db.bronze_rankings_marketevents_alltimeeventcustomers
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_marketevents_dwh_eventcustomers_part
    full_name: main.bi_db.bronze_rankings_marketevents_dwh_eventcustomers_part
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_marketevents_mlcustomersanalysis
    full_name: main.bi_db.bronze_rankings_marketevents_mlcustomersanalysis
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rankings_ranking_execution
    full_name: main.bi_db.bronze_rankings_ranking_execution
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_recurringinvestment_dictionary_instancestatusid
    full_name: main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md
      source_database: RecurringInvestment
      source_schema: Dictionary
      source_table: InstanceStatusID
      source_repo: ExperianceDBs
      datalake_path: Bronze/RecurringInvestment/Dictionary/InstanceStatusID
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringinvestment_dictionary_planeventcode
    full_name: main.bi_db.bronze_recurringinvestment_dictionary_planeventcode
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md
      source_database: RecurringInvestment
      source_schema: Dictionary
      source_table: PlanEventCode
      source_repo: ExperianceDBs
      datalake_path: Bronze/RecurringInvestment/Dictionary/PlanEventCode
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringinvestment_dictionary_planstatus
    full_name: main.bi_db.bronze_recurringinvestment_dictionary_planstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md
      source_database: RecurringInvestment
      source_schema: Dictionary
      source_table: PlanStatus
      source_repo: ExperianceDBs
      datalake_path: Bronze/RecurringInvestment/Dictionary/PlanStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringinvestment_history_recurringinvestmentplans
    full_name: main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md
      source_database: RecurringInvestment
      source_schema: History
      source_table: RecurringInvestmentPlans
      source_repo: ExperianceDBs
      datalake_path: Bronze/RecurringInvestment/History/RecurringInvestmentPlans
      copy_strategy: Append
    in_scope: true
  - name: bronze_riskclassification_dbo_v_riskclassificationdatalake
    full_name: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md
      source_database: RiskClassification
      source_schema: dbo
      source_table: V_RiskClassificationDataLake
      source_repo: ComplianceDBs
      datalake_path: Bronze/RiskClassification/dbo/V_RiskClassificationDataLake
      copy_strategy: Override
    in_scope: true
  - name: bronze_riskclassification_dictionary_cysecriskclassificationparameter
    full_name: main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md
      source_database: RiskClassification
      source_schema: Dictionary
      source_table: CySecRiskClassificationParameter
      source_repo: ComplianceDBs
      datalake_path: Bronze/RiskClassification/Dictionary/CySecRiskClassificationParameter
      copy_strategy: Override
    in_scope: true
  - name: bronze_riskclassification_riskclassification_customeronboardingriskclassification
    full_name: main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md
      source_database: RiskClassification
      source_schema: RiskClassification
      source_table: CustomerOnboardingRiskClassification
      source_repo: ComplianceDBs
      datalake_path: Bronze/RiskClassification/RiskClassification/CustomerOnboardingRiskClassification
      copy_strategy: Override
    in_scope: true
  - name: bronze_riskclassification_riskclassification_cysecriskclassificationparameter
    full_name: main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md
      source_database: RiskClassification
      source_schema: RiskClassification
      source_table: CySecRiskClassificationParameter
      source_repo: ComplianceDBs
      datalake_path: Bronze/RiskClassification/RiskClassification/CySecRiskClassificationParameter
      copy_strategy: Override
    in_scope: true
  - name: bronze_rivery_bing_bing_kw_conv
    full_name: main.bi_db.bronze_rivery_bing_bing_kw_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_bing_bing_kw_perf
    full_name: main.bi_db.bronze_rivery_bing_bing_kw_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_dv_dcm_dv360_creatives_daily
    full_name: main.bi_db.bronze_rivery_dv_dcm_dv360_creatives_daily
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_ad_conv
    full_name: main.bi_db.bronze_rivery_google_ad_google_ad_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_ad_perf
    full_name: main.bi_db.bronze_rivery_google_ad_google_ad_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_adgroup_conv
    full_name: main.bi_db.bronze_rivery_google_ad_google_adgroup_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_adgroup_perf
    full_name: main.bi_db.bronze_rivery_google_ad_google_adgroup_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_asset_perf
    full_name: main.bi_db.bronze_rivery_google_ad_google_asset_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_campaign_conv
    full_name: main.bi_db.bronze_rivery_google_ad_google_campaign_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_campaign_perf
    full_name: main.bi_db.bronze_rivery_google_ad_google_campaign_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_geo_conv
    full_name: main.bi_db.bronze_rivery_google_ad_google_geo_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_geo_perf
    full_name: main.bi_db.bronze_rivery_google_ad_google_geo_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_kw_conv
    full_name: main.bi_db.bronze_rivery_google_ad_google_kw_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_kw_perf
    full_name: main.bi_db.bronze_rivery_google_ad_google_kw_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_google_sqr_conv
    full_name: main.bi_db.bronze_rivery_google_ad_google_sqr_conv
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_rivery_google_ad_perf_copy_google_ad_perf
    full_name: main.bi_db.bronze_rivery_google_ad_perf_copy_google_ad_perf
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_dictionary_providers
    full_name: main.bi_db.bronze_screeningservice_dictionary_providers
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_dictionary_providerstatus
    full_name: main.bi_db.bronze_screeningservice_dictionary_providerstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_dictionary_screeningprocess
    full_name: main.bi_db.bronze_screeningservice_dictionary_screeningprocess
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_dictionary_screeningstatus
    full_name: main.bi_db.bronze_screeningservice_dictionary_screeningstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_dictionary_screeningupdatedby
    full_name: main.bi_db.bronze_screeningservice_dictionary_screeningupdatedby
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_history_providerscreening
    full_name: main.bi_db.bronze_screeningservice_history_providerscreening
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_screening_extendedhitsdata
    full_name: main.bi_db.bronze_screeningservice_screening_extendedhitsdata
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_screening_hitmetadata
    full_name: main.bi_db.bronze_screeningservice_screening_hitmetadata
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_screening_hits
    full_name: main.bi_db.bronze_screeningservice_screening_hits
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_screening_managerresolvedcasesaudit
    full_name: main.bi_db.bronze_screeningservice_screening_managerresolvedcasesaudit
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_screening_providerscreening
    full_name: main.bi_db.bronze_screeningservice_screening_providerscreening
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_screeningservice_screening_userscreening
    full_name: main.bi_db.bronze_screeningservice_screening_userscreening
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_settingsdb_dwh_v_customerdatawallet
    full_name: main.bi_db.bronze_settingsdb_dwh_v_customerdatawallet
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation
    full_name: main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md
      source_database: Sodreconciliation
      source_schema: apex
      source_table: EXT1034_NewAccountFinancialInformation
      source_repo: DB_Schema
      datalake_path: Bronze/Sodreconciliation/apex/EXT1034_NewAccountFinancialInformation
      copy_strategy: Override
    in_scope: true
  - name: bronze_sodreconciliation_apex_ext538_closedaccounts
    full_name: main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md
      source_database: Sodreconciliation
      source_schema: apex
      source_table: EXT538_ClosedAccounts
      source_repo: DB_Schema
      datalake_path: Bronze/Sodreconciliation/apex/EXT538_ClosedAccounts
      copy_strategy: Override
    in_scope: true
  - name: bronze_streampolls_poll_options
    full_name: main.bi_db.bronze_streampolls_poll_options
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_streampolls_poll_polls
    full_name: main.bi_db.bronze_streampolls_poll_polls
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_streampolls_poll_votes
    full_name: main.bi_db.bronze_streampolls_poll_votes
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_sub_accounts_accounts
    full_name: main.bi_db.bronze_sub_accounts_accounts
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_sub_accounts_stg_accounts
    full_name: main.bi_db.bronze_sub_accounts_stg_accounts
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_test_test_rivery
    full_name: main.bi_db.bronze_test_test_rivery
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tradonomi_customer_customermoney
    full_name: main.bi_db.bronze_tradonomi_customer_customermoney
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tradonomi_history_mirror
    full_name: main.bi_db.bronze_tradonomi_history_mirror
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tradonomi_history_position_datafactory
    full_name: main.bi_db.bronze_tradonomi_history_position_datafactory
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tradonomi_trade_getinstrument
    full_name: main.bi_db.bronze_tradonomi_trade_getinstrument
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tradonomi_trade_mirror
    full_name: main.bi_db.bronze_tradonomi_trade_mirror
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tradonomi_trade_position_datafactory
    full_name: main.bi_db.bronze_tradonomi_trade_position_datafactory
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_travelruledb_travelruletransactions
    full_name: main.bi_db.bronze_travelruledb_travelruletransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_tribereportdb_tribe_accountsactivities_862157
    full_name: main.bi_db.bronze_tribereportdb_tribe_accountsactivities_862157
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_usabroker_apex_optionsreasoningform
    full_name: main.bi_db.bronze_usabroker_apex_optionsreasoningform
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningForm.md
      source_database: USABroker
      source_schema: apex
      source_table: OptionsReasoningForm
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/apex/OptionsReasoningForm
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_apex_optionsreasoningformquestionsanswers
    full_name: main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md
      source_database: USABroker
      source_schema: apex
      source_table: OptionsReasoningFormQuestionsAnswers
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/apex/OptionsReasoningFormQuestionsAnswers
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_apex_sketchinvestigationdonotappealreason
    full_name: main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md
      source_database: USABroker
      source_schema: apex
      source_table: SketchInvestigationDoNotAppealReason
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/apex/SketchInvestigationDoNotAppealReason
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_dictionary_appropriatenessproduct
    full_name: main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AppropriatenessProduct.md
      source_database: USABroker
      source_schema: Dictionary
      source_table: AppropriatenessProduct
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/Dictionary/AppropriatenessProduct
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_dictionary_appropriatenesstestresult
    full_name: main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AppropriatenessTestResult.md
      source_database: USABroker
      source_schema: Dictionary
      source_table: AppropriatenessTestResult
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/Dictionary/AppropriatenessTestResult
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_dictionary_eligibilitystatus
    full_name: main.bi_db.bronze_usabroker_dictionary_eligibilitystatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md
      source_database: USABroker
      source_schema: Dictionary
      source_table: EligibilityStatus
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/Dictionary/EligibilityStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_dictionary_optionsstatus
    full_name: main.bi_db.bronze_usabroker_dictionary_optionsstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.OptionsStatus.md
      source_database: USABroker
      source_schema: Dictionary
      source_table: OptionsStatus
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/Dictionary/OptionsStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_usabroker_dictionary_reasoningstatus
    full_name: main.bi_db.bronze_usabroker_dictionary_reasoningstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ReasoningStatus.md
      source_database: USABroker
      source_schema: Dictionary
      source_table: ReasoningStatus
      source_repo: ComplianceDBs
      datalake_path: Bronze/USABroker/Dictionary/ReasoningStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_asic_customeranswers
    full_name: main.bi_db.bronze_userapidb_asic_customeranswers
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.CustomerAnswers.md
      source_database: UserApiDB
      source_schema: ASIC
      source_table: CustomerAnswers
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/ASIC/CustomerAnswers
      copy_strategy: Append
    in_scope: true
  - name: bronze_userapidb_asic_testresults
    full_name: main.bi_db.bronze_userapidb_asic_testresults
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/ASIC/Tables/ASIC.TestResults.md
      source_database: UserApiDB
      source_schema: ASIC
      source_table: TestResults
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/ASIC/TestResults
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_customer_additionalcitizenship
    full_name: main.bi_db.bronze_userapidb_customer_additionalcitizenship
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.AdditionalCitizenship.md
      source_database: UserApiDB
      source_schema: Customer
      source_table: AdditionalCitizenship
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/Customer/AdditionalCitizenship
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_customer_extendeduserfield_history_masked
    full_name: main.bi_db.bronze_userapidb_customer_extendeduserfield_history_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_userapidb_customer_extendeduserfieldvalidation
    full_name: main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md
      source_database: UserApiDB
      source_schema: Customer
      source_table: ExtendedUserFieldValidation
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/Customer/ExtendedUserFieldValidation
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_dbo_publications
    full_name: main.bi_db.bronze_userapidb_dbo_publications
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md
      source_database: UserApiDB
      source_schema: dbo
      source_table: Publications
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/dbo/Publications
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_dbo_v_customeranswers
    full_name: main.bi_db.bronze_userapidb_dbo_v_customeranswers
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md
      source_database: UserApiDB
      source_schema: dbo
      source_table: V_CustomerAnswers
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/dbo/V_CustomerAnswers
      copy_strategy: Merge
    in_scope: true
  - name: bronze_userapidb_dbo_v_customeranswers_masked
    full_name: main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Views/dbo.V_CustomerAnswers.md
      source_database: UserApiDB
      source_schema: dbo
      source_table: V_CustomerAnswers
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/dbo/V_CustomerAnswers_masked
      copy_strategy: Merge
    in_scope: true
  - name: bronze_userapidb_dictionary_evstatus
    full_name: main.bi_db.bronze_userapidb_dictionary_evstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.EvStatus.md
      source_database: UserApiDB
      source_schema: Dictionary
      source_table: EvStatus
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/Dictionary/EvStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype
    full_name: main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.NationalPinValueTypeToReportType.md
      source_database: UserApiDB
      source_schema: Dictionary
      source_table: NationalPinValueTypeToReportType
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/Dictionary/NationalPinValueTypeToReportType
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_dictionary_tanganystatus
    full_name: main.bi_db.bronze_userapidb_dictionary_tanganystatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.TanganyStatus.md
      source_database: UserApiDB
      source_schema: Dictionary
      source_table: TanganyStatus
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/Dictionary/TanganyStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_dwh_questions_answers_v
    full_name: main.bi_db.bronze_userapidb_dwh_questions_answers_v
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DWH/Views/DWH.Questions_Answers_V.md
      source_database: UserApiDB
      source_schema: DWH
      source_table: Questions_Answers_V
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/DWH/Questions_Answers_V
      copy_strategy: Override
    in_scope: true
  - name: bronze_userapidb_kyc_cryptoassessmentanswers
    full_name: main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md
      source_database: UserApiDB
      source_schema: KYC
      source_table: CryptoAssessmentAnswers
      source_repo: DB_Schema
      datalake_path: Bronze/UserApiDB/KYC/CryptoAssessmentAnswers
      copy_strategy: Override
    in_scope: true
  - name: bronze_verificationdata_ev_pilot_verification_result
    full_name: main.bi_db.bronze_verificationdata_ev_pilot_verification_result
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_walletconversiondb_c2f_conversions
    full_name: main.bi_db.bronze_walletconversiondb_c2f_conversions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md
      source_database: WalletConversionDB
      source_schema: C2F
      source_table: Conversions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/C2F/Conversions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletconversiondb_c2f_conversionstatuses
    full_name: main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.ConversionStatuses.md
      source_database: WalletConversionDB
      source_schema: C2F
      source_table: ConversionStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/C2F/ConversionStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletconversiondb_c2f_cryptotransactions
    full_name: main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md
      source_database: WalletConversionDB
      source_schema: C2F
      source_table: CryptoTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/C2F/CryptoTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletconversiondb_c2f_estimatedfiattransactions
    full_name: main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md
      source_database: WalletConversionDB
      source_schema: C2F
      source_table: EstimatedFiatTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/C2F/EstimatedFiatTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletconversiondb_c2f_fiattransactions
    full_name: main.bi_db.bronze_walletconversiondb_c2f_fiattransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.FiatTransactions.md
      source_database: WalletConversionDB
      source_schema: C2F
      source_table: FiatTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/C2F/FiatTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletconversiondb_dictionary_conversiontofiatstatuses
    full_name: main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/Dictionary/Tables/Dictionary.ConversionToFiatStatuses.md
      source_database: WalletConversionDB
      source_schema: Dictionary
      source_table: ConversionToFiatStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/Dictionary/ConversionToFiatStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletconversiondb_dictionary_fiatconversiontargets
    full_name: main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/Dictionary/Tables/Dictionary.FiatConversionTargets.md
      source_database: WalletConversionDB
      source_schema: Dictionary
      source_table: FiatConversionTargets
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletConversionDB/Dictionary/FiatConversionTargets
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_addressownershipproofoption
    full_name: main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.AddressOwnershipProofOption.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: AddressOwnershipProofOption
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/AddressOwnershipProofOption
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_addressownershipprooftype
    full_name: main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.AddressOwnershipProofType.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: AddressOwnershipProofType
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/AddressOwnershipProofType
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_correlatedrequeststypes
    full_name: main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CorrelatedRequestsTypes.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: CorrelatedRequestsTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/CorrelatedRequestsTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_customervalueeligibilitychangingsource
    full_name: main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CustomerValueEligibilityChangingSource.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: CustomerValueEligibilityChangingSource
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/CustomerValueEligibilityChangingSource
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_eligibilitystatuses
    full_name: main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.EligibilityStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: EligibilityStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/EligibilityStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_etorolegalentities
    full_name: main.bi_db.bronze_walletdb_dictionary_etorolegalentities
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.EtoroLegalEntities.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: EtoroLegalEntities
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/EtoroLegalEntities
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_travelruleaddresstype
    full_name: main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleAddressType.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: TravelRuleAddressType
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/TravelRuleAddressType
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_travelrulecomplianceoptions
    full_name: main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleComplianceOptions.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: TravelRuleComplianceOptions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/TravelRuleComplianceOptions
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_travelrulestatuses
    full_name: main.bi_db.bronze_walletdb_dictionary_travelrulestatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: TravelRuleStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/TravelRuleStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_eligibility_statusmap
    full_name: main.bi_db.bronze_walletdb_eligibility_statusmap
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md
      source_database: WalletDB
      source_schema: Eligibility
      source_table: StatusMap
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Eligibility/StatusMap
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_eligibility_travelrulewhitelistedaddresses
    full_name: main.bi_db.bronze_walletdb_eligibility_travelrulewhitelistedaddresses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md
      source_database: WalletDB
      source_schema: Eligibility
      source_table: TravelRuleWhitelistedAddresses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Eligibility/TravelRuleWhitelistedAddresses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_correlatedrequests
    full_name: main.bi_db.bronze_walletdb_wallet_correlatedrequests
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: CorrelatedRequests
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/CorrelatedRequests
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_customertermsandconditions
    full_name: main.bi_db.bronze_walletdb_wallet_customertermsandconditions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CustomerTermsAndConditions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: CustomerTermsAndConditions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/CustomerTermsAndConditions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_termsandconditions
    full_name: main.bi_db.bronze_walletdb_wallet_termsandconditions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: TermsAndConditions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/TermsAndConditions
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_transactiontravelruleinformation
    full_name: main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: TransactionTravelRuleInformation
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/TransactionTravelRuleInformation
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_transactiontravelrulestatuses
    full_name: main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: TransactionTravelRuleStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/TransactionTravelRuleStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_walletpoolattributes
    full_name: main.bi_db.bronze_walletdb_wallet_walletpoolattributes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: WalletPoolAttributes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/WalletPoolAttributes
      copy_strategy: Override
    in_scope: true
  - name: bronze_wealth_france_wealth_france_users_data
    full_name: main.bi_db.bronze_wealth_france_wealth_france_users_data
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: gold_bi_db_bi_db_positionpnl
    full_name: main.bi_db.gold_bi_db_bi_db_positionpnl
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_fivetran_google_sheets_aml_exluded_players
    full_name: main.bi_db.gold_fivetran_google_sheets_aml_exluded_players
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_fivetran_google_sheets_real_future_fees
    full_name: main.bi_db.gold_fivetran_google_sheets_real_future_fees
    type: EXTERNAL
    writer:
      kind: JOB
      path: 801797183440303
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
      additional_producers:
        - entity_type: JOB
          entity_id: 170541494252665
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-02-26T08:18:44.595000+00:00"
          last_event_time: "2026-02-26T08:18:44.595000+00:00"
        - entity_type: JOB
          entity_id: 358446929533817
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-03-22T08:19:09.085000+00:00"
          last_event_time: "2026-03-22T08:19:09.085000+00:00"
        - entity_type: JOB
          entity_id: 729188853938901
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-02-18T08:18:17.595000+00:00"
          last_event_time: "2026-02-18T08:18:17.595000+00:00"
        - entity_type: JOB
          entity_id: 366484835319959
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-03-04T08:19:29.472000+00:00"
          last_event_time: "2026-03-04T08:19:29.472000+00:00"
    in_scope: true
  - name: gold_opsdb_dbo_sedricfilelog
    full_name: main.bi_db.gold_opsdb_dbo_sedricfilelog
    type: EXTERNAL
    writer:
      kind: JOB
      path: 757333527043023
      lineage_source: system.access.table_lineage
      lineage_event_count: 1
      additional_producers:
        - entity_type: JOB
          entity_id: 286024368042578
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-02-23T07:49:33.503000+00:00"
          last_event_time: "2026-02-23T07:49:33.503000+00:00"
        - entity_type: JOB
          entity_id: 858888575747311
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-03-16T09:19:37.743000+00:00"
          last_event_time: "2026-03-16T09:19:37.743000+00:00"
        - entity_type: JOB
          entity_id: 335674750955689
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-02-18T07:26:06.637000+00:00"
          last_event_time: "2026-02-18T07:26:06.637000+00:00"
        - entity_type: JOB
          entity_id: 436184977194481
          workspace_id: 5263962954799003
          event_count: 1
          first_event_time: "2026-03-02T10:54:29.735000+00:00"
          last_event_time: "2026-03-02T10:54:29.735000+00:00"
    in_scope: true
  - name: gold_prarsed_data
    full_name: main.bi_db.gold_prarsed_data
    type: EXTERNAL
    writer:
      kind: JOB
      path: 708073752273798
      lineage_source: system.access.table_lineage
      lineage_event_count: 373
    in_scope: true
  - name: gold_rnd_experience_fivetran_google_sheets_ltv_by_leadscore_combinations
    full_name: main.bi_db.gold_rnd_experience_fivetran_google_sheets_ltv_by_leadscore_combinations
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_test
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_test
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status_backup
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status_backup
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_bck
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_bck
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v
    type: VIEW
    writer:
      kind: view_definition
    in_scope: true
    upstreams_hint:
      - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily
    refs_source: view_definition (regex extract)
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_sfmc_report_archive
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_sfmc_report_archive
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_from_synapse_emoneyclientbalance_to_generic_20260216
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_from_synapse_emoneyclientbalance_to_generic_20260216
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_migration_v_riskclassification
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_migration_v_riskclassification
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_bi_db_python_bi_db_jira_data
    full_name: main.bi_db.gold_sql_dp_prod_we_bi_db_python_bi_db_jira_data
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients
    full_name: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
    full_name: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report
    full_name: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg
    full_name: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
    full_name: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_dwh_dbo_dim_product
    full_name: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_fiataccount
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary
    full_name: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_dimuser
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_reimbursementfollowup
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_reimbursementfollowup
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_walletentity
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_exw_walletinventory
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_wallet_exw_price
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: gold_sql_dp_prod_we_exw_wallet_exw_pricedaily
    full_name: main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
  - name: metricviewpoc
    full_name: main.bi_db.metricviewpoc
    type: METRIC_VIEW
    writer:
      kind: UNKNOWN
      reason: VIEW has empty view_definition (catalog metadata broken)
    in_scope: false
    reason: VIEW has empty view_definition (catalog metadata broken)
  - name: tmp_it_services_ftd_gcids
    full_name: main.bi_db.tmp_it_services_ftd_gcids
    type: MANAGED
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
  - name: untrustedwe_blob_tableauevents_events
    full_name: main.bi_db.untrustedwe_blob_tableauevents_events
    type: EXTERNAL
    writer:
      kind: UNKNOWN
      reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
    in_scope: false
    reason: no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)
---

# bi_db — Schema Card

> UC-Pipeline scope sheet for `main.bi_db`. **148 in-scope** / **466 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `bronze_etoro_backoffice_bonustype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_documentauthenticationreasons` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_managertopermission` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_tncdocument` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_currencysettings` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_depositamount` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_mapmerchantcodetomid` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_merchantaccountrouting` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_withdrawpaymentmethods` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_customer_address_masked` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_customer_customermoney` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_adminpositionstate` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_depositdrstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_depositstatusreason` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_feedefinition` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_hedgemanualrequesttype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_interestrateoverride` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_openpositionactiontype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_riskclassificationparameter` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_riskclassificationregulation` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_dictionary_withdrawtype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_accountinstrumentconfiguration` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_exposurecircuitbreakerthresholds` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_gethedgeserveraccountmapping` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_hbcaccountconfiguration` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_hedgeservertoliquidityaccount` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_instrumentconfiguration` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_instrumentgroups` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_instrumentgroupsmapping` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_hedge_providerunitconversionratio` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_currencypricemaxdatewithsplitview` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_deposit_datafactory` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_exposurecircuitbreakerthresholds` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_hedgeinstrumentconfiguration` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_hedgeservertoliquidityaccount` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_instrumentmetadata` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_interestrateoverride` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_liquidityprovidercontracts` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_providerinstrumenttoleverage` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_price_accountratesource` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_price_exchange` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_price_liquidityaccounttoinstrument` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_adminpositionlog` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_copytradesettlementrestrictions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_fund` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_getliquidityproviders` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_instrumentcusip` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_liquidityprovidertype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_trade_providerinstrumenttoleverage` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiatdwhdb_dbo_eligibilityrules` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiatdwhdb_dbo_fiatcardinstances` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiatdwhdb_dbo_programtransitionseligibility` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiatdwhdb_dictionary_programtransitioneligibilitysources` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliatecommission_closedpositioncommissionvw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliatecommission_closedpositionvw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliatecommission_creditcommissionvw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliatecommission_creditvw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliatecommission_registrationcommissionvw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliatecommission_registrationvw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_affiliateconfiguration_traderfirstassetposition` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_channels` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_mediatag` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_mediatagbanner` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_affiliates` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_affiliates_masked` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_affiliatesgroups` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_banners` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_bannertypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_country` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_ecost` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_ecost_commissions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_firstpositions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_firstpositions_commissions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_languages` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_leads` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_leads_commissions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_marketingexpense` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_paymentdetails` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_paymentdetails_masked` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_paymenthistory` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_user` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dbo_tblaff_user_masked` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dictionary_paymentmethods` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_fiktivo_dictionary_positionassettype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_dictionary_accounttypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneytransfer_billing_posttransferactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneytransfer_billing_transfers` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringinvestment_dictionary_instancestatusid` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringinvestment_dictionary_planeventcode` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringinvestment_dictionary_planstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringinvestment_history_recurringinvestmentplans` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_riskclassification_dbo_v_riskclassificationdatalake` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_riskclassification_dictionary_cysecriskclassificationparameter` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_riskclassification_riskclassification_customeronboardingriskclassification` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_riskclassification_riskclassification_cysecriskclassificationparameter` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_sodreconciliation_apex_ext538_closedaccounts` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_apex_optionsreasoningform` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_apex_optionsreasoningformquestionsanswers` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_apex_sketchinvestigationdonotappealreason` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_dictionary_appropriatenessproduct` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_dictionary_appropriatenesstestresult` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_dictionary_eligibilitystatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_dictionary_optionsstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_usabroker_dictionary_reasoningstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_asic_customeranswers` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_asic_testresults` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_customer_additionalcitizenship` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_customer_extendeduserfieldvalidation` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dbo_publications` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dbo_v_customeranswers` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dbo_v_customeranswers_masked` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dictionary_evstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dictionary_tanganystatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_dwh_questions_answers_v` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_userapidb_kyc_cryptoassessmentanswers` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_c2f_conversions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_c2f_conversionstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_c2f_cryptotransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_c2f_estimatedfiattransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_c2f_fiattransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_dictionary_conversiontofiatstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletconversiondb_dictionary_fiatconversiontargets` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_addressownershipproofoption` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_addressownershipprooftype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_correlatedrequeststypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_customervalueeligibilitychangingsource` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_eligibilitystatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_etorolegalentities` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_travelruleaddresstype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_travelrulecomplianceoptions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_travelrulestatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_eligibility_statusmap` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_eligibility_travelrulewhitelistedaddresses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_correlatedrequests` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_customertermsandconditions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_termsandconditions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_transactiontravelruleinformation` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_transactiontravelrulestatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_walletpoolattributes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `gold_fivetran_google_sheets_real_future_fees` | `EXTERNAL` | `JOB` | `801797183440303` |
| `gold_opsdb_dbo_sedricfilelog` | `EXTERNAL` | `JOB` | `757333527043023` |
| `gold_prarsed_data` | `EXTERNAL` | `JOB` | `708073752273798` |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v` | `VIEW` | `view_definition` | `view_definition` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `bi_output_compliance_illegal_trades_alerts_test` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `bronze_assignment_assignment_managerteam` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_assignment_assignment_taskaudit` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_assignment_assignment_teams` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_assignment_assignment_v_tasks` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_bigquery_affwiz` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_history_candles_v_history_t_pricecandle10min` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_history_candles_v_history_t_pricecandle15min` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_history_candles_v_history_t_pricecandle1min` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_history_candles_v_history_t_pricecandle30min` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_history_candles_v_history_t_pricecandle5min` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_history_candles_v_history_t_pricecandle60min` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_trade_providertoinstrument` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_trade_spread` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_candles_trade_spreadtogroup` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_clubservice_clubs_downgraderisk` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_clubservice_clubs_userbalances` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_clubservice_dictionary_balancesourcetypes` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_customerconsentdocuments` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_customerconsentplans` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_customerconsents` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_customerrequirementsoverviewstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_customerrequirmentshistoryviewforw8ben` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_customerrequirmentsview` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_kycflowevaluator` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_usercryptotradingdata` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_userpositions` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_compliance_verificationlevel3evaluation` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_history_autosigntncjobdetails` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_history_customerrequirementsoverviewstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_history_customerrestrictions` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_compliancestatedb_history_customertargetregulation` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_contactverification_phone_customer_masked` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_customerfinancedb_customer_accountftds` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_customerfinancedb_customer_cutoffdateconfiguration` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_customerfinancedb_customer_firsttimedeposits` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_customerfinancedb_customer_globalftds` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_databricks_postgres_public_chat_history` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_databricks_postgres_public_eilon_test` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_closeexecutionplan` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_executedcloseorders` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_orderforclose` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_orderforopen` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_orderforopen_old` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_ordersfail` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_db_logs_history_ordersmarketfail` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_dealinglogs_dictionary_instrumenteventtype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_deltaapp_bronze_subscriptions` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_edocsdb_translation_translationrequests` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_edocsdb_translation_translations` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_edocsdb_verification_checks` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_cryptoliquidity_cryptotrade` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_cryptoliquidity_cryptowallets` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dbo_syn_etorogeneral_dwh_customersettings` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_builddwh_riskmatrix_adhoc` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_builddwh_riskmatrix_history_delta` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_builddwh_riskmatrix_v8` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_hedgenetting` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_historybackofficecustomer` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_v_backofficecustomerhourly` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_v_etorogeneralcustomersettings` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_dwh_v_historymirrorhourly` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_history_closepositionendofday` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_riskcalculation_scorestemporary` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_trade_openpositionendofday` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_trade_positionforexternaluse` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etorogeneral_customer_settings` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etorogeneral_dbo_copiers_data` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etorologs_real_hedge_emsordersstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_financereports_history_request` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_financereports_reports_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_financereports_reports_reportconfiguration` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_ad_conv_new_api_v_conv_ad_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_ad_perf_new_api_v_perf_ad_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_adgroup_perf_new_api_v_conv_adgroup_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_adgroup_perf_new_api_v_perf_adgroup_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_assets_google_assets_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_campaign_perf_v_perf_campaign_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_geo_conv_new_api_v_conv_geo_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_geo_perf_new_api_v_perf_geo_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_geo_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_keywords_conv_new_api_v_conv_keywords_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_keywords_perf_new_api_v_perf_keywords_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_new_api_v_campaign_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_new_api_v_conversion_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_adwords_search_conv_new_api_v_conv_search_query_performance_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_bingads_ad_group_history` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_bingads_campaign_history` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_bingads_goals_and_funnels_daily_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_bingads_keyword_performance_daily_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_compliance_leverage_settings_data` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_active_hs_mappings` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_admin_fee_per_group` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_gs_and_saxo_commodities_mapping` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_instruments_groups` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_instrumentsmapping_dailyspreadsaggregated` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_overnight_fees` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_dealing_units_per_contract` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_double_click_campaign_manager_dv_360_daily` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_double_click_campaign_manager_dv_360_daily_conversions` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_double_click_campaign_manager_v_media_campaign` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_facebook_cvr_facebook_conversion_actions` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_facebook_facebook_preformance_new` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_ad_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_ad_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_adgroup_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_adgroup_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_campaign_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_campaign_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_geo_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_geo_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_kw_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_kw_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_sqr_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_new_agg_v_google_sqr_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheet_clubbenefits` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheet_emoney_customer_risk_assessment_manual_override_table` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_account_manager_target_500_cids` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_account_manager_targets_2024` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_adj` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_aml_users_list` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_at_nm_setup_compliance` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_attend` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_asic_additional_major` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_cfd_leverages` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_cross_border` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_crypto_listing` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_major_currencies` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_major_indices` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_bui_test_users` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_capital_guarantee_alpha` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_capital_guarantee_manually_approved` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_cashback` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_cashback_merchant_list_2025` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_cfd_eligible_users` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_compliance_cryptolisting` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_compliance_help_table` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_compliance_help_tables` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_compliance_snapshot_report_instrumentids` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_conversion_fee_discounts` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_cracountryriskmapping` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_div_1099_int` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_eligibility_monthly_rewards` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_emoney_bank_payments_manual_entries` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_emoney_customer_risk_assessment_classification_table` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_employee_program_cid_list` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_equities_with_sustainability_stamp` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_etc_fee_data_blockchain` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_excluded_cid_tin_gap_project` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_exw_aml_limited_accounts_new` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_fatca_cids` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_fivetran_1042_tax` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_fivetran_options_high_yield_interest_program_enrollee` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_forbiddentrading` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_forced_closure_list_br` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_instruments_review_tracker` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_investment_office_kpi_criteria` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_kyt` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_kyt_alerts` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_lps_for_registrations_dashboard` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_luna_cids_jan_2023` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_manually_approved` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_manually_approved_cg` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_manually_approved_tactical_edge` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_marex_mapping_table` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_marex_mapping_table_2` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_marketing_subchannel_level_data` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_migration_request_form_template` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_migration_request_mt_to_fr` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_multiregulationaffiliatecompliance` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_pis_lists_country_level` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_pis_lists_region_level` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_pis_restrictions_dictionary` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_ptp_apex` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_ptp_ib` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_qmmf_totalvalue` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_reg_official_finra_symbols` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_regionkpi` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_registration_froad` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_risk_score_country` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_rm_kpi_target` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_target_region` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_tin_gep_temp_pop` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_trustpilot_2026` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_trustpilot_currentdate` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_trustpilot_history` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_vp_monthly_mi` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_wallet_closureandreimbursementseea` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_wallet_closureandreimbursementseea_cysec_2025` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_google_sheets_weekly_reportingcid_list` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_regtech_euro_nat_gas` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_regtech_si_reporting_configurations` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_additionalaffiliatesurl` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_blockedcountries` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_disclaimers` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_marketableproductcountry` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_regulationcountries` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_regulationdomain` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_sedric_etoro_mapping_sedric_regulationlanguage` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_twitter_ads_account_history` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_twitter_ads_campaign_history` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_fivetran_twitter_ads_campaign_locations_report` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_funnel_social_acqiuisition_social` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_interest_history_interestconsent` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_interest_trade_interestconsent` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_interest_trade_interestdaily` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_interest_trade_interestmonthly` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_analyzer_instrumentopentime` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_analyzer_instrumentoperationdata` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_analyzer_instrumentstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_analyzer_suitability` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_analyzer_suitabilityrevolvingdoorquestion` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_analyzer_userassessmentsubreasons` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_assessmentstatuses` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_clientrisklevel` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_instrumenttypes` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_question` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_recalculationreason` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_suitabilityblock` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_suitabilitycalculationdetaillevel` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_dictionary_userassessmentfailreasons` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_history_suitability` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_kycanalyzer_history_suitabilitycalculationdetail` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketmaker_dbo_hbchedgetrades` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketmaker_dbo_v_hbchedgetrades` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_articlemovementtype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_articletype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_countries` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_dividendfrequencytype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_exchangeinfo` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_experimentstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_instrumentreferencetype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_marketeventstatustype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_marketeventtype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_notificationstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_ratechangeinterval` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_ratechangesize` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_ratechangetype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_regulations` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_dictionary_streakinterval` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_articleevents` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_currencies` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_dividendevents` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_earningreportevents` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_earningreporttemplates` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_instruments` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_ratechangetemplates` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_ratechangetriggerconfigurations` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_sendallconfigurations` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_streakevents` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_streaktemplates` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_streaktriggerconfigurations` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketnotifications_marketnotifications_templates` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketperformance_airdrop_customer` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketperformance_tracking_customer` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_applications_applications` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dbo_applications` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dbo_connectedusers` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dbo_publishedapplications` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dictionary_accesslevel` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dictionary_applicationstate` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dictionary_category` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dictionary_publicationstate` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketplace_dictionary_tradingmode` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_navigation_navigation` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_navigationservice_ns_stephistory` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_navigationservice_ns_userflows` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_notificationdb_dictionary_category` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_notificationdb_dictionary_channeltype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_notificationdb_dictionary_subcategory` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_notificationdb_notifications_notificationsettings` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_opsdb_dbo_datalaketablestatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_opsdb_dbo_objectsstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_opsdb_dbo_proceduredependencies` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_periodicrankings_ranking_periodicgain` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_price_trade_instrumentclosingpricesourcedata` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_provedb_prove_userstate` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_dictionary_marketchangetype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_dictionary_marketeventassettypes` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_dictionary_marketeventinterval` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_dictionary_notificationtype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_dictionary_ratechangetype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_history_monthlygainanon` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_marketevents_activecustomers` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_marketevents_alltimeeventcustomers` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_marketevents_dwh_eventcustomers_part` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_marketevents_mlcustomersanalysis` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rankings_ranking_execution` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_bing_bing_kw_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_bing_bing_kw_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_dv_dcm_dv360_creatives_daily` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_ad_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_ad_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_adgroup_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_adgroup_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_asset_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_campaign_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_campaign_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_geo_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_geo_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_kw_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_kw_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_google_sqr_conv` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_rivery_google_ad_perf_copy_google_ad_perf` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_dictionary_providers` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_dictionary_providerstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_dictionary_screeningprocess` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_dictionary_screeningstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_dictionary_screeningupdatedby` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_history_providerscreening` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_screening_extendedhitsdata` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_screening_hitmetadata` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_screening_hits` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_screening_managerresolvedcasesaudit` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_screening_providerscreening` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_screeningservice_screening_userscreening` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_settingsdb_dwh_v_customerdatawallet` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_streampolls_poll_options` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_streampolls_poll_polls` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_streampolls_poll_votes` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_sub_accounts_accounts` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_sub_accounts_stg_accounts` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_test_test_rivery` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tradonomi_customer_customermoney` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tradonomi_history_mirror` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tradonomi_history_position_datafactory` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tradonomi_trade_getinstrument` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tradonomi_trade_mirror` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tradonomi_trade_position_datafactory` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_travelruledb_travelruletransactions` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_tribereportdb_tribe_accountsactivities_862157` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_userapidb_customer_extendeduserfield_history_masked` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_verificationdata_ev_pilot_verification_result` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_wealth_france_wealth_france_users_data` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `gold_bi_db_bi_db_positionpnl` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `gold_fivetran_google_sheets_aml_exluded_players` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `gold_rnd_experience_fivetran_google_sheets_ltv_by_leadscore_combinations` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_daily_nwa` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidlevel_settlement_report` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_test` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status_backup` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_bck` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_verificationpipeline_overlevel2` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_sfmc_report_archive` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_from_synapse_emoneyclientbalance_to_generic_20260216` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_migration_v_riskclassification` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_bi_db_python_bi_db_jira_data` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_dwh_dbo_dim_product` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_fiataccount` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_dimuser` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_reimbursementfollowup` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_walletentity` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_exw_walletinventory` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_wallet_exw_price` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `gold_sql_dp_prod_we_exw_wallet_exw_pricedaily` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |
| `metricviewpoc` | `METRIC_VIEW` | VIEW has empty view_definition (catalog metadata broken) |
| `tmp_it_services_ftd_gcids` | `MANAGED` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |
| `untrustedwe_blob_tableauevents_events` | `EXTERNAL` | no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale) |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
