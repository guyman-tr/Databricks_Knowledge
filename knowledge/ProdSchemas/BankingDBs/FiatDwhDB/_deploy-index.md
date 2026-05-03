---

## bronze: FiatDwhDB

db_key: BankingDBs/FiatDwhDB
total_deployable: 65
generated: 0
failed: 21
deployed: 44
last_generated: "2026-04-30"
last_deploy_batch: 2
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountPrograms](Wiki/Dictionary/Tables/Dictionary.AccountPrograms.md) | `main.emoney.bronze_fiatdwhdb_dictionary_accountprograms` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AccountStatuses](Wiki/Dictionary/Tables/Dictionary.AccountStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_accountstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AuthorizationTypes](Wiki/Dictionary/Tables/Dictionary.AuthorizationTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CardStatuses](Wiki/Dictionary/Tables/Dictionary.CardStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_cardstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CurrencyBalanceStatuses](Wiki/Dictionary/Tables/Dictionary.CurrencyBalanceStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_currencybalancestatuses` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.IsoCurrencyInfo](Wiki/Dictionary/Tables/Dictionary.IsoCurrencyInfo.md) | `main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentSchemaType](Wiki/Dictionary/Tables/Dictionary.PaymentSchemaType.md) | `main.emoney.bronze_fiatdwhdb_dictionary_paymentschematype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentSpecificationStatusTypes](Wiki/Dictionary/Tables/Dictionary.PaymentSpecificationStatusTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_paymentspecificationstatustypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentSpecificationTypes](Wiki/Dictionary/Tables/Dictionary.PaymentSpecificationTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_paymentspecificationtypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ProgramTransitionEligibilitySources](Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilitySources.md) | `main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitysources` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ProgramTransitionEligibilityStatuses](Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilityStatuses.md) | `main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Providers](Wiki/Dictionary/Tables/Dictionary.Providers.md) | `main.emoney.bronze_fiatdwhdb_dictionary_providers` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.StatusChangeReasons](Wiki/Dictionary/Tables/Dictionary.StatusChangeReasons.md) | `main.general.bronze_fiatdwhdb_dictionary_statuschangereasons` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.StatusChangeSources](Wiki/Dictionary/Tables/Dictionary.StatusChangeSources.md) | `main.general.bronze_fiatdwhdb_dictionary_statuschangesources` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TransactionCategories](Wiki/Dictionary/Tables/Dictionary.TransactionCategories.md) | `main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TransactionStatuses](Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_transactionstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TransactionTypes](Wiki/Dictionary/Tables/Dictionary.TransactionTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_transactiontypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TribeScriptStatus](Wiki/Dictionary/Tables/Dictionary.TribeScriptStatus.md) | `main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Tribe.AccountsActivities_862157](Wiki/Tribe/Views/Tribe.AccountsActivities_862157.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157` | Deployed (Batch 1) - 2026-05-03 |
| [Tribe.AccountsActivities_AccountActivity-833937](Wiki/Tribe/Tables/Tribe.AccountsActivities_AccountActivity-833937.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountsactivities_account |
| [Tribe.AccountsActivities_RiskActions-322546](Wiki/Tribe/Tables/Tribe.AccountsActivities_RiskActions-322546.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountsactivities_riskact |
| [Tribe.AccountsActivities_SecurityChecks-471048](Wiki/Tribe/Tables/Tribe.AccountsActivities_SecurityChecks-471048.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountsactivities_securit |
| [Tribe.AccountsSnapshots-509416](Wiki/Tribe/Tables/Tribe.AccountsSnapshots-509416.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountssnapshots-509416`  |
| [Tribe.AccountsSnapshots_AccountSnapshot-956050](Wiki/Tribe/Tables/Tribe.AccountsSnapshots_AccountSnapshot-956050.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountssnapshots_accounts |
| [Tribe.AccountsSnapshots_BankAccount-393561](Wiki/Tribe/Tables/Tribe.AccountsSnapshots_BankAccount-393561.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountssnapshots_bankacco |
| [Tribe.AccountsSnapshots_BankAccounts-795870](Wiki/Tribe/Tables/Tribe.AccountsSnapshots_BankAccounts-795870.md) | `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_accountssnapshots_bankacco |
| [Tribe.Authorizes-837045](Wiki/Tribe/Tables/Tribe.Authorizes-837045.md) | `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_authorizes-837045` cannot  |
| [Tribe.Authorizes_Authorize-312243](Wiki/Tribe/Tables/Tribe.Authorizes_Authorize-312243.md) | `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_authorizes_authorize-31224 |
| [Tribe.Authorizes_RiskActions-796100](Wiki/Tribe/Tables/Tribe.Authorizes_RiskActions-796100.md) | `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796 |
| [Tribe.Authorizes_SecurityChecks-30662](Wiki/Tribe/Tables/Tribe.Authorizes_SecurityChecks-30662.md) | `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_authorizes_securitychecks- |
| [Tribe.CardsSnapshots-890718](Wiki/Tribe/Tables/Tribe.CardsSnapshots-890718.md) | `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` can |
| [Tribe.CardsSnapshots_Account-513255](Wiki/Tribe/Tables/Tribe.CardsSnapshots_Account-513255.md) | `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513 |
| [Tribe.CardsSnapshots_Accounts-350640](Wiki/Tribe/Tables/Tribe.CardsSnapshots_Accounts-350640.md) | `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-35 |
| [Tribe.CardsSnapshots_BankAccount-341626](Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccount-341626.md) | `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount |
| [Tribe.CardsSnapshots_BankAccounts-83854](Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccounts-83854.md) | `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount |
| [Tribe.CardsSnapshots_CardSnapshot-140457](Wiki/Tribe/Tables/Tribe.CardsSnapshots_CardSnapshot-140457.md) | `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapsho |
| [Tribe.SettlementsTransactions-333243](Wiki/Tribe/Tables/Tribe.SettlementsTransactions-333243.md) | `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_settlementstransactions-33 |
| [Tribe.SettlementsTransactions_RiskActions-236807](Wiki/Tribe/Tables/Tribe.SettlementsTransactions_RiskActions-236807.md) | `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_settlementstransactions_ri |
| [Tribe.SettlementsTransactions_SecurityChecks-426253](Wiki/Tribe/Tables/Tribe.SettlementsTransactions_SecurityChecks-426253.md) | `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_settlementstransactions_se |
| [Tribe.SettlementsTransactions_SettlementTransaction-637239](Wiki/Tribe/Tables/Tribe.SettlementsTransactions_SettlementTransaction-637239.md) | `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239` | Failed (Batch 2) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`bronze_fiatdwhdb_tribe_settlementstransactions_se |
| [dbo.AccountsProviderHoldersMapping](Wiki/dbo/Tables/dbo.AccountsProviderHoldersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.CardsProvidersMapping](Wiki/dbo/Tables/dbo.CardsProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.CurrencyBalancesProvidersMapping](Wiki/dbo/Tables/dbo.CurrencyBalancesProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.CustomerEODBalance](Wiki/dbo/Tables/dbo.CustomerEODBalance.md) | `main.emoney.bronze_fiatdwhdb_dbo_customereodbalance` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.EligibilityRules](Wiki/dbo/Tables/dbo.EligibilityRules.md) | `main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatAccount](Wiki/dbo/Tables/dbo.FiatAccount.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiataccount` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatAccountStatuses](Wiki/dbo/Tables/dbo.FiatAccountStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatAccountsProperties](Wiki/dbo/Tables/dbo.FiatAccountsProperties.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatBankAccount](Wiki/dbo/Tables/dbo.FiatBankAccount.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatCardInstances](Wiki/dbo/Tables/dbo.FiatCardInstances.md) | `main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatCardStatuses](Wiki/dbo/Tables/dbo.FiatCardStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatCards](Wiki/dbo/Tables/dbo.FiatCards.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcards` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatCurrencyBalances](Wiki/dbo/Tables/dbo.FiatCurrencyBalances.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatCurrencyBalancesStatuses](Wiki/dbo/Tables/dbo.FiatCurrencyBalancesStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatTransactions](Wiki/dbo/Tables/dbo.FiatTransactions.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiattransactions` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.FiatTransactionsStatuses](Wiki/dbo/Tables/dbo.FiatTransactionsStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.PaymentSpecificationDetails](Wiki/dbo/Tables/dbo.PaymentSpecificationDetails.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.PaymentSpecificationDues](Wiki/dbo/Tables/dbo.PaymentSpecificationDues.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.PaymentSpecificationStatuses](Wiki/dbo/Tables/dbo.PaymentSpecificationStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.PaymentSpecifications](Wiki/dbo/Tables/dbo.PaymentSpecifications.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.PaymentSpecificationsProvidersMapping](Wiki/dbo/Tables/dbo.PaymentSpecificationsProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.ProgramTransitionsEligibility](Wiki/dbo/Tables/dbo.ProgramTransitionsEligibility.md) | `main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.ProgramTransitionsEligibilityStatuses](Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md) | `main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.SubPrograms](Wiki/dbo/Tables/dbo.SubPrograms.md) | `main.emoney.bronze_fiatdwhdb_dbo_subprograms` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.TransactionsProvidersMapping](Wiki/dbo/Tables/dbo.TransactionsProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping` | Deployed (Batch 1) - 2026-05-03 |
