---
schema: billing
catalog: main
display_name: billing — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-18T10:54:39Z"
lineage_lookback_days: 90
in_scope_count: 41
out_of_scope_count: 14
objects:
  - name: bronze_alertservicedb_alert_alert
    full_name: main.billing.bronze_alertservicedb_alert_alert
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_configuration_alertstatus
    full_name: main.billing.bronze_alertservicedb_configuration_alertstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_configuration_alerttemplate
    full_name: main.billing.bronze_alertservicedb_configuration_alerttemplate
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_configuration_reasontoclassification
    full_name: main.billing.bronze_alertservicedb_configuration_reasontoclassification
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_alerttype
    full_name: main.billing.bronze_alertservicedb_dictionary_alerttype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_category
    full_name: main.billing.bronze_alertservicedb_dictionary_category
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_statusclassification
    full_name: main.billing.bronze_alertservicedb_dictionary_statusclassification
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_statusreason
    full_name: main.billing.bronze_alertservicedb_dictionary_statusreason
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_statustype
    full_name: main.billing.bronze_alertservicedb_dictionary_statustype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_triggertype
    full_name: main.billing.bronze_alertservicedb_dictionary_triggertype
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_dictionary_uniquekey
    full_name: main.billing.bronze_alertservicedb_dictionary_uniquekey
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_alertservicedb_history_alert
    full_name: main.billing.bronze_alertservicedb_history_alert
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_customerfinancedb_customer_defaultaccount
    full_name: main.billing.bronze_customerfinancedb_customer_defaultaccount
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_archive_billing_scheduledtaskstate
    full_name: main.billing.bronze_etoro_archive_billing_scheduledtaskstate
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_etoro_backoffice_compensationreason
    full_name: main.billing.bronze_etoro_backoffice_compensationreason
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md
      source_database: etoro
      source_schema: BackOffice
      source_table: CompensationReason
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/CompensationReason
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_customeralltimeaggregateddata
    full_name: main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md
      source_database: etoro
      source_schema: BackOffice
      source_table: CustomerAllTimeAggregatedData
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/CustomerAllTimeAggregatedData
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_customerdocument
    full_name: main.billing.bronze_etoro_backoffice_customerdocument
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md
      source_database: etoro
      source_schema: BackOffice
      source_table: CustomerDocument
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/CustomerDocument
      copy_strategy: Append
    in_scope: true
  - name: bronze_etoro_backoffice_customerdocumenttodocumenttype
    full_name: main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md
      source_database: etoro
      source_schema: BackOffice
      source_table: CustomerDocumentToDocumentType
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/CustomerDocumentToDocumentType
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_customerrisk
    full_name: main.billing.bronze_etoro_backoffice_customerrisk
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md
      source_database: etoro
      source_schema: BackOffice
      source_table: CustomerRisk
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/CustomerRisk
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_documentvendors
    full_name: main.billing.bronze_etoro_backoffice_documentvendors
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md
      source_database: etoro
      source_schema: BackOffice
      source_table: DocumentVendors
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/DocumentVendors
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_manager
    full_name: main.billing.bronze_etoro_backoffice_manager
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md
      source_database: etoro
      source_schema: BackOffice
      source_table: Manager
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/Manager
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_backoffice_withdrawapproval
    full_name: main.billing.bronze_etoro_backoffice_withdrawapproval
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md
      source_database: etoro
      source_schema: BackOffice
      source_table: WithdrawApproval
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/BackOffice/WithdrawApproval
      copy_strategy: Append
    in_scope: true
  - name: bronze_etoro_billing_aftrouting
    full_name: main.billing.bronze_etoro_billing_aftrouting
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md
      source_database: etoro
      source_schema: Billing
      source_table: AftRouting
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/AftRouting
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_badbin
    full_name: main.billing.bronze_etoro_billing_badbin
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md
      source_database: etoro
      source_schema: Billing
      source_table: BadBin
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/BadBin
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_cashoutrollbacktracking
    full_name: main.billing.bronze_etoro_billing_cashoutrollbacktracking
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md
      source_database: etoro
      source_schema: Billing
      source_table: CashoutRollbackTracking
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/CashoutRollbackTracking
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_conversionfee
    full_name: main.billing.bronze_etoro_billing_conversionfee
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md
      source_database: etoro
      source_schema: Billing
      source_table: ConversionFee
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/ConversionFee
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_conversionfeeoverride
    full_name: main.billing.bronze_etoro_billing_conversionfeeoverride
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md
      source_database: etoro
      source_schema: Billing
      source_table: ConversionFeeOverride
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/ConversionFeeOverride
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_customertofunding
    full_name: main.billing.bronze_etoro_billing_customertofunding
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md
      source_database: etoro
      source_schema: Billing
      source_table: CustomerToFunding
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/CustomerToFunding
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_deposit
    full_name: main.billing.bronze_etoro_billing_deposit
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md
      source_database: etoro
      source_schema: Billing
      source_table: Deposit
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/Deposit
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_depositrollbacktracking
    full_name: main.billing.bronze_etoro_billing_depositrollbacktracking
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md
      source_database: etoro
      source_schema: Billing
      source_table: DepositRollbackTracking
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/DepositRollbackTracking
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_depot
    full_name: main.billing.bronze_etoro_billing_depot
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md
      source_database: etoro
      source_schema: Billing
      source_table: Depot
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/Depot
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_funding_datafactory
    full_name: main.billing.bronze_etoro_billing_funding_datafactory
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md
      source_database: etoro
      source_schema: Billing
      source_table: Funding_DataFactory
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/Funding_DataFactory
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_fundingpaymentdetailsforwithdraw
    full_name: main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md
      source_database: etoro
      source_schema: Billing
      source_table: FundingPaymentDetailsForWithdraw
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/FundingPaymentDetailsForWithdraw
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_limitedbins
    full_name: main.billing.bronze_etoro_billing_limitedbins
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md
      source_database: etoro
      source_schema: Billing
      source_table: LimitedBins
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/LimitedBins
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_protocolmidsettings
    full_name: main.billing.bronze_etoro_billing_protocolmidsettings
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md
      source_database: etoro
      source_schema: Billing
      source_table: ProtocolMIDSettings
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/ProtocolMIDSettings
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_redeem
    full_name: main.billing.bronze_etoro_billing_redeem
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md
      source_database: etoro
      source_schema: Billing
      source_table: Redeem
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/Redeem
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_scheduledtaskstate
    full_name: main.billing.bronze_etoro_billing_scheduledtaskstate
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md
      source_database: etoro
      source_schema: Billing
      source_table: ScheduledTaskState
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/ScheduledTaskState
      copy_strategy: Append
    in_scope: true
  - name: bronze_etoro_billing_vwithdrawtofunding
    full_name: main.billing.bronze_etoro_billing_vwithdrawtofunding
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md
      source_database: etoro
      source_schema: Billing
      source_table: vWithdrawToFunding
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/vWithdrawToFunding
      copy_strategy: Merge
    in_scope: true
  - name: bronze_etoro_billing_withdraw
    full_name: main.billing.bronze_etoro_billing_withdraw
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md
      source_database: etoro
      source_schema: Billing
      source_table: Withdraw
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/Withdraw
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_billing_withdrawrejects
    full_name: main.billing.bronze_etoro_billing_withdrawrejects
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md
      source_database: etoro
      source_schema: Billing
      source_table: WithdrawRejects
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/Billing/WithdrawRejects
      copy_strategy: Override
    in_scope: true
  - name: bronze_etoro_history_withdrawaction
    full_name: main.billing.bronze_etoro_history_withdrawaction
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md
      source_database: etoro
      source_schema: History
      source_table: WithdrawAction
      source_repo: DB_Schema
      datalake_path: Bronze/etoro/History/WithdrawAction
      copy_strategy: Append
    in_scope: true
  - name: bronze_moneybusdb_dictionary_transactionstatuses
    full_name: main.billing.bronze_moneybusdb_dictionary_transactionstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md
      source_database: MoneyBusDB
      source_schema: Dictionary
      source_table: TransactionStatuses
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/Dictionary/TransactionStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneybusdb_dictionary_transactionstatusreasons
    full_name: main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md
      source_database: MoneyBusDB
      source_schema: Dictionary
      source_table: TransactionStatusReasons
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/Dictionary/TransactionStatusReasons
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneybusdb_dictionary_withdrawcancellationsources
    full_name: main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawCancellationSources.md
      source_database: MoneyBusDB
      source_schema: Dictionary
      source_table: WithdrawCancellationSources
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/Dictionary/WithdrawCancellationSources
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneybusdb_dictionary_withdrawstatuses
    full_name: main.billing.bronze_moneybusdb_dictionary_withdrawstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatuses.md
      source_database: MoneyBusDB
      source_schema: Dictionary
      source_table: WithdrawStatuses
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/Dictionary/WithdrawStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneybusdb_dictionary_withdrawstatusreasons
    full_name: main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md
      source_database: MoneyBusDB
      source_schema: Dictionary
      source_table: WithdrawStatusReasons
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/Dictionary/WithdrawStatusReasons
      copy_strategy: Override
    in_scope: true
  - name: bronze_moneybusdb_moneybus_transactions
    full_name: main.billing.bronze_moneybusdb_moneybus_transactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md
      source_database: MoneyBusDB
      source_schema: MoneyBus
      source_table: Transactions
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/MoneyBus/Transactions
      copy_strategy: Merge
    in_scope: true
  - name: bronze_moneybusdb_moneybus_transferlimits
    full_name: main.billing.bronze_moneybusdb_moneybus_transferlimits
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md
      source_database: MoneyBusDB
      source_schema: MoneyBus
      source_table: TransferLimits
      source_repo: PaymentsDBs
      datalake_path: Bronze/MoneyBusDB/MoneyBus/TransferLimits
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_dictionary_frequency
    full_name: main.billing.bronze_recurringmanager_dictionary_frequency
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md
      source_database: RecurringManager
      source_schema: Dictionary
      source_table: Frequency
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Dictionary/Frequency
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_dictionary_planstatus
    full_name: main.billing.bronze_recurringmanager_dictionary_planstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md
      source_database: RecurringManager
      source_schema: Dictionary
      source_table: PlanStatus
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Dictionary/PlanStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_recurring_payment
    full_name: main.billing.bronze_recurringmanager_recurring_payment
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md
      source_database: RecurringManager
      source_schema: Recurring
      source_table: Payment
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Recurring/Payment
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_recurring_paymentexecution
    full_name: main.billing.bronze_recurringmanager_recurring_paymentexecution
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md
      source_database: RecurringManager
      source_schema: Recurring
      source_table: PaymentExecution
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Recurring/PaymentExecution
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_recurring_paymentexecutiondepositresult
    full_name: main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md
      source_database: RecurringManager
      source_schema: Recurring
      source_table: PaymentExecutionDepositResult
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Recurring/PaymentExecutionDepositResult
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_scheduler_execution
    full_name: main.billing.bronze_recurringmanager_scheduler_execution
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md
      source_database: RecurringManager
      source_schema: Scheduler
      source_table: Execution
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Scheduler/Execution
      copy_strategy: Override
    in_scope: true
  - name: bronze_recurringmanager_scheduler_plan
    full_name: main.billing.bronze_recurringmanager_scheduler_plan
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md
      source_database: RecurringManager
      source_schema: Scheduler
      source_table: Plan
      source_repo: PaymentsDBs
      datalake_path: Bronze/RecurringManager/Scheduler/Plan
      copy_strategy: Override
    in_scope: true
---

# billing — Schema Card

> UC-Pipeline scope sheet for `main.billing`. **41 in-scope** / **14 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `bronze_etoro_backoffice_compensationreason` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_customeralltimeaggregateddata` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_customerdocument` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_customerdocumenttodocumenttype` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_customerrisk` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_documentvendors` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_manager` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_backoffice_withdrawapproval` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_aftrouting` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_badbin` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_cashoutrollbacktracking` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_conversionfee` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_conversionfeeoverride` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_customertofunding` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_deposit` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_depositrollbacktracking` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_depot` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_funding_datafactory` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_fundingpaymentdetailsforwithdraw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_limitedbins` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_protocolmidsettings` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_redeem` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_scheduledtaskstate` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_vwithdrawtofunding` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_withdraw` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_billing_withdrawrejects` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_etoro_history_withdrawaction` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_dictionary_transactionstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_dictionary_transactionstatusreasons` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_dictionary_withdrawcancellationsources` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_dictionary_withdrawstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_dictionary_withdrawstatusreasons` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_moneybus_transactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_moneybusdb_moneybus_transferlimits` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_dictionary_frequency` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_dictionary_planstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_recurring_payment` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_recurring_paymentexecution` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_recurring_paymentexecutiondepositresult` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_scheduler_execution` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_recurringmanager_scheduler_plan` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `bronze_alertservicedb_alert_alert` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_configuration_alertstatus` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_configuration_alerttemplate` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_configuration_reasontoclassification` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_alerttype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_category` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_statusclassification` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_statusreason` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_statustype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_triggertype` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_dictionary_uniquekey` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_alertservicedb_history_alert` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_customerfinancedb_customer_defaultaccount` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_etoro_archive_billing_scheduledtaskstate` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
