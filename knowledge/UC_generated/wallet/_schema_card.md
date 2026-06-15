---
schema: wallet
catalog: main
display_name: wallet — UC-Pipeline scope sheet
framework: uc-pipeline-doc
generated_at: "2026-05-19T12:07:34Z"
lineage_lookback_days: 90
in_scope_count: 58
out_of_scope_count: 9
objects:
  - name: bronze_marketratesdb_currency_currencies
    full_name: main.wallet.bronze_marketratesdb_currency_currencies
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketratesdb_currency_currencyrateprovidercontracts
    full_name: main.wallet.bronze_marketratesdb_currency_currencyrateprovidercontracts
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketratesdb_currency_currencyrateproviders
    full_name: main.wallet.bronze_marketratesdb_currency_currencyrateproviders
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketratesdb_currency_instrumentrates
    full_name: main.wallet.bronze_marketratesdb_currency_instrumentrates
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_marketratesdb_currency_instruments
    full_name: main.wallet.bronze_marketratesdb_currency_instruments
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_settingsdb_dictionary_countrygroup
    full_name: main.wallet.bronze_settingsdb_dictionary_countrygroup
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_settingsdb_dictionary_countrytocountrygroup
    full_name: main.wallet.bronze_settingsdb_dictionary_countrytocountrygroup
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_settingsdb_dictionary_dynamicgroup
    full_name: main.wallet.bronze_settingsdb_dictionary_dynamicgroup
    type: EXTERNAL
    writer:
      kind: BRONZE_INGEST
      reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
    in_scope: false
    reason: bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index
  - name: bronze_walletbalancesreportdb_wallet_financereportrecords
    full_name: main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md
      source_database: WalletBalancesReportDB
      source_schema: Wallet
      source_table: FinanceReportRecords
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReportRecords
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletbalancesreportdb_wallet_financereportruns
    full_name: main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md
      source_database: WalletBalancesReportDB
      source_schema: Wallet
      source_table: FinanceReportRuns
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReportRuns
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletbalancesreportdb_wallet_financereports
    full_name: main.wallet.bronze_walletbalancesreportdb_wallet_financereports
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReports.md
      source_database: WalletBalancesReportDB
      source_schema: Wallet
      source_table: FinanceReports
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReports
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletbalancesreportdb_wallet_financereportsbalances
    full_name: main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md
      source_database: WalletBalancesReportDB
      source_schema: Wallet
      source_table: FinanceReportsBalances
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReportsBalances
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_dictionary_checksumtypes
    full_name: main.wallet.bronze_walletdb_dictionary_checksumtypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ChecksumTypes.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: ChecksumTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/ChecksumTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_conversionstatuses
    full_name: main.wallet.bronze_walletdb_dictionary_conversionstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: ConversionStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/ConversionStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_cryptocoinproviders
    full_name: main.wallet.bronze_walletdb_dictionary_cryptocoinproviders
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CryptoCoinProviders.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: CryptoCoinProviders
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/CryptoCoinProviders
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_manualapprovetransactionstatus
    full_name: main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ManualApproveTransactionStatus.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: ManualApproveTransactionStatus
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/ManualApproveTransactionStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_paymentstatuses
    full_name: main.wallet.bronze_walletdb_dictionary_paymentstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.PaymentStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: PaymentStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/PaymentStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_receivedtransactiontypes
    full_name: main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ReceivedTransactionTypes.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: ReceivedTransactionTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/ReceivedTransactionTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_requeststatuses
    full_name: main.wallet.bronze_walletdb_dictionary_requeststatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.RequestStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: RequestStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/RequestStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_requesttypes
    full_name: main.wallet.bronze_walletdb_dictionary_requesttypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.RequestTypes.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: RequestTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/RequestTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_stakingstatuses
    full_name: main.wallet.bronze_walletdb_dictionary_stakingstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.StakingStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: StakingStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/StakingStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_transactionstatus
    full_name: main.wallet.bronze_walletdb_dictionary_transactionstatus
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatus.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: TransactionStatus
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/TransactionStatus
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_transactiontypes
    full_name: main.wallet.bronze_walletdb_dictionary_transactiontypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TransactionTypes.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: TransactionTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/TransactionTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_walletpoolstatuses
    full_name: main.wallet.bronze_walletdb_dictionary_walletpoolstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletPoolStatuses.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: WalletPoolStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/WalletPoolStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_walletprovider
    full_name: main.wallet.bronze_walletdb_dictionary_walletprovider
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletProvider.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: WalletProvider
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/WalletProvider
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_dictionary_wallettypes
    full_name: main.wallet.bronze_walletdb_dictionary_wallettypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletTypes.md
      source_database: WalletDB
      source_schema: Dictionary
      source_table: WalletTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Dictionary/WalletTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_staking_staking
    full_name: main.wallet.bronze_walletdb_staking_staking
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.Staking.md
      source_database: WalletDB
      source_schema: Staking
      source_table: Staking
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Staking/Staking
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_staking_stakingexternaladdress
    full_name: main.wallet.bronze_walletdb_staking_stakingexternaladdress
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md
      source_database: WalletDB
      source_schema: Staking
      source_table: StakingExternalAddress
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Staking/StakingExternalAddress
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_staking_stakingrewards
    full_name: main.wallet.bronze_walletdb_staking_stakingrewards
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md
      source_database: WalletDB
      source_schema: Staking
      source_table: StakingRewards
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Staking/StakingRewards
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_staking_stakingstatuses
    full_name: main.wallet.bronze_walletdb_staking_stakingstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md
      source_database: WalletDB
      source_schema: Staking
      source_table: StakingStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Staking/StakingStatuses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_staking_stakingtransactions
    full_name: main.wallet.bronze_walletdb_staking_stakingtransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md
      source_database: WalletDB
      source_schema: Staking
      source_table: StakingTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Staking/StakingTransactions
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_amlproviderusers
    full_name: main.wallet.bronze_walletdb_wallet_amlproviderusers
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlProviderUsers.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: AmlProviderUsers
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/AmlProviderUsers
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_amlvalidations
    full_name: main.wallet.bronze_walletdb_wallet_amlvalidations
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: AmlValidations
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/AmlValidations
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_blockchaincryptoproviders
    full_name: main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: BlockchainCryptoProviders
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/BlockchainCryptoProviders
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_blockchaincryptos
    full_name: main.wallet.bronze_walletdb_wallet_blockchaincryptos
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: BlockchainCryptos
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/BlockchainCryptos
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_conversions
    full_name: main.wallet.bronze_walletdb_wallet_conversions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: Conversions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/Conversions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_conversionstatuses
    full_name: main.wallet.bronze_walletdb_wallet_conversionstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: ConversionStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/ConversionStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_conversiontransactions
    full_name: main.wallet.bronze_walletdb_wallet_conversiontransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionTransactions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: ConversionTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/ConversionTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_cryptomarketratesmappings
    full_name: main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoMarketRatesMappings.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: CryptoMarketRatesMappings
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/CryptoMarketRatesMappings
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_cryptotypes
    full_name: main.wallet.bronze_walletdb_wallet_cryptotypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: CryptoTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/CryptoTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_customerwalletsview
    full_name: main.wallet.bronze_walletdb_wallet_customerwalletsview
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: CustomerWalletsView
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/CustomerWalletsView
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_fiatmarketratesmappings
    full_name: main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatMarketRatesMappings.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: FiatMarketRatesMappings
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/FiatMarketRatesMappings
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_fiattypes
    full_name: main.wallet.bronze_walletdb_wallet_fiattypes
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: FiatTypes
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/FiatTypes
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_limitationsdefinitions
    full_name: main.wallet.bronze_walletdb_wallet_limitationsdefinitions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: LimitationsDefinitions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/LimitationsDefinitions
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_payments
    full_name: main.wallet.bronze_walletdb_wallet_payments
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: Payments
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/Payments
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_paymentstatuses
    full_name: main.wallet.bronze_walletdb_wallet_paymentstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: PaymentStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/PaymentStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_paymenttransactions
    full_name: main.wallet.bronze_walletdb_wallet_paymenttransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: PaymentTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/PaymentTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_receivedtransactions
    full_name: main.wallet.bronze_walletdb_wallet_receivedtransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: ReceivedTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/ReceivedTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_receivedtransactionstatuses
    full_name: main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: ReceivedTransactionStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/ReceivedTransactionStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_redemptions
    full_name: main.wallet.bronze_walletdb_wallet_redemptions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: Redemptions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/Redemptions
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_requests
    full_name: main.wallet.bronze_walletdb_wallet_requests
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Requests.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: Requests
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/Requests
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_requeststatuses
    full_name: main.wallet.bronze_walletdb_wallet_requeststatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: RequestStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/RequestStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_senttransactionoutputs
    full_name: main.wallet.bronze_walletdb_wallet_senttransactionoutputs
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: SentTransactionOutputs
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/SentTransactionOutputs
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_senttransactionreplaces
    full_name: main.wallet.bronze_walletdb_wallet_senttransactionreplaces
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionReplaces.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: SentTransactionReplaces
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/SentTransactionReplaces
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_senttransactions
    full_name: main.wallet.bronze_walletdb_wallet_senttransactions
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactions.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: SentTransactions
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/SentTransactions
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_senttransactionstatuses
    full_name: main.wallet.bronze_walletdb_wallet_senttransactionstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: SentTransactionStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/SentTransactionStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_transactionsview
    full_name: main.wallet.bronze_walletdb_wallet_transactionsview
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: TransactionsView
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/TransactionsView
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_travelruleaddresses
    full_name: main.wallet.bronze_walletdb_wallet_travelruleaddresses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: TravelRuleAddresses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/TravelRuleAddresses
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_travelrulesends
    full_name: main.wallet.bronze_walletdb_wallet_travelrulesends
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleSends.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: TravelRuleSends
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/TravelRuleSends
      copy_strategy: Override
    in_scope: true
  - name: bronze_walletdb_wallet_vw_walletbalanaces
    full_name: main.wallet.bronze_walletdb_wallet_vw_walletbalanaces
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.vw_WalletBalanaces.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: vw_WalletBalanaces
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/vw_WalletBalanaces
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_walletaddresses
    full_name: main.wallet.bronze_walletdb_wallet_walletaddresses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletAddresses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: WalletAddresses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/WalletAddresses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_walletassets
    full_name: main.wallet.bronze_walletdb_wallet_walletassets
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletAssets.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: WalletAssets
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/WalletAssets
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_walletbalances
    full_name: main.wallet.bronze_walletdb_wallet_walletbalances
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletBalances.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: WalletBalances
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/WalletBalances
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_walletpool
    full_name: main.wallet.bronze_walletdb_wallet_walletpool
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: WalletPool
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/WalletPool
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_walletpoolstatuses
    full_name: main.wallet.bronze_walletdb_wallet_walletpoolstatuses
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolStatuses.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: WalletPoolStatuses
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/WalletPoolStatuses
      copy_strategy: Append
    in_scope: true
  - name: bronze_walletdb_wallet_wallets
    full_name: main.wallet.bronze_walletdb_wallet_wallets
    type: EXTERNAL
    writer:
      kind: BRONZE_TIER1_INHERITANCE
      upstream_wiki_path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md
      source_database: WalletDB
      source_schema: Wallet
      source_table: Wallets
      source_repo: CryptoDBs
      datalake_path: Bronze/WalletDB/Wallet/Wallets
      copy_strategy: Override
    in_scope: true
  - name: gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
    full_name: main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
    type: EXTERNAL
    writer:
      kind: GENERIC_PIPELINE
      reason: synapse gold mirror — documented by dwh-semantic-doc
    in_scope: false
    reason: synapse gold mirror — documented by dwh-semantic-doc
---

# wallet — Schema Card

> UC-Pipeline scope sheet for `main.wallet`. **58 in-scope** / **9 out-of-scope** objects (lookback `90` days).

## What this schema is

_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._

## In-scope objects

| Object | Type | Writer | Producer |
|--------|------|--------|----------|
| `bronze_walletbalancesreportdb_wallet_financereportrecords` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletbalancesreportdb_wallet_financereportruns` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletbalancesreportdb_wallet_financereports` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletbalancesreportdb_wallet_financereportsbalances` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_checksumtypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_conversionstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_cryptocoinproviders` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_manualapprovetransactionstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_paymentstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_receivedtransactiontypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_requeststatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_requesttypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_stakingstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_transactionstatus` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_transactiontypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_walletpoolstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_walletprovider` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_dictionary_wallettypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_staking_staking` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_staking_stakingexternaladdress` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_staking_stakingrewards` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_staking_stakingstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_staking_stakingtransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_amlproviderusers` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_amlvalidations` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_blockchaincryptoproviders` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_blockchaincryptos` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_conversions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_conversionstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_conversiontransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_cryptomarketratesmappings` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_cryptotypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_customerwalletsview` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_fiatmarketratesmappings` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_fiattypes` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_limitationsdefinitions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_payments` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_paymentstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_paymenttransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_receivedtransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_receivedtransactionstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_redemptions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_requests` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_requeststatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_senttransactionoutputs` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_senttransactionreplaces` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_senttransactions` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_senttransactionstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_transactionsview` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_travelruleaddresses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_travelrulesends` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_vw_walletbalanaces` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_walletaddresses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_walletassets` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_walletbalances` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_walletpool` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_walletpoolstatuses` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |
| `bronze_walletdb_wallet_wallets` | `EXTERNAL` | `BRONZE_TIER1_INHERITANCE` | `BRONZE_TIER1_INHERITANCE` |

## Out-of-scope objects

| Object | Type | Reason |
|--------|------|--------|
| `bronze_marketratesdb_currency_currencies` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketratesdb_currency_currencyrateprovidercontracts` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketratesdb_currency_currencyrateproviders` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketratesdb_currency_instrumentrates` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_marketratesdb_currency_instruments` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_settingsdb_dictionary_countrygroup` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_settingsdb_dictionary_countrytocountrygroup` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `bronze_settingsdb_dictionary_dynamicgroup` | `EXTERNAL` | bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index |
| `gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation` | `EXTERNAL` | synapse gold mirror — documented by dwh-semantic-doc |

## Authoring policy

Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** (`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns inherit their description **byte-for-byte** from the upstream wiki, preserving the upstream's `(Tier N — origin)` tag — see `GATE-lineage-contract.mdc` for the transitivity rule.
