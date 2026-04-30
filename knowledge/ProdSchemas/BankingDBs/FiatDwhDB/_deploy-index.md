---

## bronze: FiatDwhDB

db_key: BankingDBs/FiatDwhDB
total_deployable: 43
generated: 43
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountPrograms](Wiki/Dictionary/Tables/Dictionary.AccountPrograms.md) | `main.emoney.bronze_fiatdwhdb_dictionary_accountprograms` | Generated |
| [Dictionary.AccountStatuses](Wiki/Dictionary/Tables/Dictionary.AccountStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_accountstatuses` | Generated |
| [Dictionary.AuthorizationTypes](Wiki/Dictionary/Tables/Dictionary.AuthorizationTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes` | Generated |
| [Dictionary.CardStatuses](Wiki/Dictionary/Tables/Dictionary.CardStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_cardstatuses` | Generated |
| [Dictionary.CurrencyBalanceStatuses](Wiki/Dictionary/Tables/Dictionary.CurrencyBalanceStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_currencybalancestatuses` | Generated |
| [Dictionary.IsoCurrencyInfo](Wiki/Dictionary/Tables/Dictionary.IsoCurrencyInfo.md) | `main.emoney.bronze_fiatdwhdb_dictionary_isocurrencyinfo` | Generated |
| [Dictionary.PaymentSchemaType](Wiki/Dictionary/Tables/Dictionary.PaymentSchemaType.md) | `main.emoney.bronze_fiatdwhdb_dictionary_paymentschematype` | Generated |
| [Dictionary.PaymentSpecificationStatusTypes](Wiki/Dictionary/Tables/Dictionary.PaymentSpecificationStatusTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_paymentspecificationstatustypes` | Generated |
| [Dictionary.PaymentSpecificationTypes](Wiki/Dictionary/Tables/Dictionary.PaymentSpecificationTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_paymentspecificationtypes` | Generated |
| [Dictionary.ProgramTransitionEligibilitySources](Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilitySources.md) | `main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitysources` | Generated |
| [Dictionary.ProgramTransitionEligibilityStatuses](Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilityStatuses.md) | `main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses` | Generated |
| [Dictionary.Providers](Wiki/Dictionary/Tables/Dictionary.Providers.md) | `main.emoney.bronze_fiatdwhdb_dictionary_providers` | Generated |
| [Dictionary.StatusChangeReasons](Wiki/Dictionary/Tables/Dictionary.StatusChangeReasons.md) | `main.general.bronze_fiatdwhdb_dictionary_statuschangereasons` | Generated |
| [Dictionary.StatusChangeSources](Wiki/Dictionary/Tables/Dictionary.StatusChangeSources.md) | `main.general.bronze_fiatdwhdb_dictionary_statuschangesources` | Generated |
| [Dictionary.TransactionCategories](Wiki/Dictionary/Tables/Dictionary.TransactionCategories.md) | `main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories` | Generated |
| [Dictionary.TransactionStatuses](Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md) | `main.emoney.bronze_fiatdwhdb_dictionary_transactionstatuses` | Generated |
| [Dictionary.TransactionTypes](Wiki/Dictionary/Tables/Dictionary.TransactionTypes.md) | `main.emoney.bronze_fiatdwhdb_dictionary_transactiontypes` | Generated |
| [Dictionary.TribeScriptStatus](Wiki/Dictionary/Tables/Dictionary.TribeScriptStatus.md) | `main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus` | Generated |
| [dbo.AccountsProviderHoldersMapping](Wiki/dbo/Tables/dbo.AccountsProviderHoldersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping` | Generated |
| [dbo.CardsProvidersMapping](Wiki/dbo/Tables/dbo.CardsProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping` | Generated |
| [dbo.CurrencyBalancesProvidersMapping](Wiki/dbo/Tables/dbo.CurrencyBalancesProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping` | Generated |
| [dbo.CustomerEODBalance](Wiki/dbo/Tables/dbo.CustomerEODBalance.md) | `main.emoney.bronze_fiatdwhdb_dbo_customereodbalance` | Generated |
| [dbo.EligibilityRules](Wiki/dbo/Tables/dbo.EligibilityRules.md) | `main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules` | Generated |
| [dbo.FiatAccount](Wiki/dbo/Tables/dbo.FiatAccount.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiataccount` | Generated |
| [dbo.FiatAccountStatuses](Wiki/dbo/Tables/dbo.FiatAccountStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses` | Generated |
| [dbo.FiatAccountsProperties](Wiki/dbo/Tables/dbo.FiatAccountsProperties.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties` | Generated |
| [dbo.FiatBankAccount](Wiki/dbo/Tables/dbo.FiatBankAccount.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatbankaccount` | Generated |
| [dbo.FiatCardInstances](Wiki/dbo/Tables/dbo.FiatCardInstances.md) | `main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances` | Generated |
| [dbo.FiatCardStatuses](Wiki/dbo/Tables/dbo.FiatCardStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses` | Generated |
| [dbo.FiatCards](Wiki/dbo/Tables/dbo.FiatCards.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcards` | Generated |
| [dbo.FiatCurrencyBalances](Wiki/dbo/Tables/dbo.FiatCurrencyBalances.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances` | Generated |
| [dbo.FiatCurrencyBalancesStatuses](Wiki/dbo/Tables/dbo.FiatCurrencyBalancesStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses` | Generated |
| [dbo.FiatTransactions](Wiki/dbo/Tables/dbo.FiatTransactions.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiattransactions` | Generated |
| [dbo.FiatTransactionsStatuses](Wiki/dbo/Tables/dbo.FiatTransactionsStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses` | Generated |
| [dbo.PaymentSpecificationDetails](Wiki/dbo/Tables/dbo.PaymentSpecificationDetails.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdetails` | Generated |
| [dbo.PaymentSpecificationDues](Wiki/dbo/Tables/dbo.PaymentSpecificationDues.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationdues` | Generated |
| [dbo.PaymentSpecificationStatuses](Wiki/dbo/Tables/dbo.PaymentSpecificationStatuses.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationstatuses` | Generated |
| [dbo.PaymentSpecifications](Wiki/dbo/Tables/dbo.PaymentSpecifications.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecifications` | Generated |
| [dbo.PaymentSpecificationsProvidersMapping](Wiki/dbo/Tables/dbo.PaymentSpecificationsProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_paymentspecificationsprovidersmapping` | Generated |
| [dbo.ProgramTransitionsEligibility](Wiki/dbo/Tables/dbo.ProgramTransitionsEligibility.md) | `main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility` | Generated |
| [dbo.ProgramTransitionsEligibilityStatuses](Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md) | `main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses` | Generated |
| [dbo.SubPrograms](Wiki/dbo/Tables/dbo.SubPrograms.md) | `main.emoney.bronze_fiatdwhdb_dbo_subprograms` | Generated |
| [dbo.TransactionsProvidersMapping](Wiki/dbo/Tables/dbo.TransactionsProvidersMapping.md) | `main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping` | Generated |
