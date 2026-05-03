---

## bronze: etoro

db_key: DB_Schema/etoro
total_deployable: 406
generated: 0
failed: 48
deployed: 358
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [BackOffice.BonusType](Wiki/BackOffice/Tables/BackOffice.BonusType.md) | `main.bi_db.bronze_etoro_backoffice_bonustype` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.CompensationReason](Wiki/BackOffice/Tables/BackOffice.CompensationReason.md) | `main.billing.bronze_etoro_backoffice_compensationreason` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.Customer](Wiki/BackOffice/Tables/BackOffice.Customer.md) | `main.general.bronze_etoro_backoffice_customer` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `AcceptanceStatusID (tinyint)` c |
| [BackOffice.CustomerAllTimeAggregatedData](Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md) | `main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.CustomerDocument](Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md) | `main.billing.bronze_etoro_backoffice_customerdocument` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.CustomerDocumentToDocumentType](Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md) | `main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.CustomerRisk](Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md) | `main.billing.bronze_etoro_backoffice_customerrisk` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.DocumentAuthenticationReasons](Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md) | `main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.DocumentVendors](Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md) | `main.billing.bronze_etoro_backoffice_documentvendors` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.Manager](Wiki/BackOffice/Tables/BackOffice.Manager.md) | `main.billing.bronze_etoro_backoffice_manager` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.ManagerToPermission](Wiki/BackOffice/Tables/BackOffice.ManagerToPermission.md) | `main.bi_db.bronze_etoro_backoffice_managertopermission` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.RedeemApproval](Wiki/BackOffice/Tables/BackOffice.RedeemApproval.md) | `main.billing.bronze_etoro_backoffice_redeemapproval` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`billing`.`bronze_etoro_backoffice_redeemapproval` cannot b |
| [BackOffice.RegulationChangeLog](Wiki/BackOffice/Tables/BackOffice.RegulationChangeLog.md) | `main.finance.bronze_etoro_backoffice_regulationchangelog` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.TncDocument](Wiki/BackOffice/Tables/BackOffice.TncDocument.md) | `main.bi_db.bronze_etoro_backoffice_tncdocument` | Deployed (Batch 1) - 2026-05-03 |
| [BackOffice.WithdrawApproval](Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md) | `main.billing.bronze_etoro_backoffice_withdrawapproval` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.AftRouting](Wiki/Billing/Tables/Billing.AftRouting.md) | `main.billing.bronze_etoro_billing_aftrouting` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.BadBin](Wiki/Billing/Tables/Billing.BadBin.md) | `main.billing.bronze_etoro_billing_badbin` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.CashoutRollbackTracking](Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md) | `main.billing.bronze_etoro_billing_cashoutrollbacktracking` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.ConversionFee](Wiki/Billing/Tables/Billing.ConversionFee.md) | `main.billing.bronze_etoro_billing_conversionfee` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.ConversionFeeOverride](Wiki/Billing/Tables/Billing.ConversionFeeOverride.md) | `main.billing.bronze_etoro_billing_conversionfeeoverride` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.CurrencySettings](Wiki/Billing/Tables/Billing.CurrencySettings.md) | `main.bi_db.bronze_etoro_billing_currencysettings` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.Deposit](Wiki/Billing/Tables/Billing.Deposit.md) | `main.billing.bronze_etoro_billing_deposit` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.DepositAmount](Wiki/Billing/Tables/Billing.DepositAmount.md) | `main.bi_db.bronze_etoro_billing_depositamount` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.DepositRollbackTracking](Wiki/Billing/Tables/Billing.DepositRollbackTracking.md) | `main.billing.bronze_etoro_billing_depositrollbacktracking` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.Depot](Wiki/Billing/Tables/Billing.Depot.md) | `main.billing.bronze_etoro_billing_depot` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.FinancialDiscrepancy](Wiki/Billing/Tables/Billing.FinancialDiscrepancy.md) | `main.finance.bronze_etoro_billing_financialdiscrepancy` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.FundingPaymentDetailsForWithdraw](Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md) | `main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.Funding_DataFactory](Wiki/Billing/Views/Billing.Funding_DataFactory.md) | `main.billing.bronze_etoro_billing_funding_datafactory` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.LimitedBins](Wiki/Billing/Tables/Billing.LimitedBins.md) | `main.billing.bronze_etoro_billing_limitedbins` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.MapMerchantCodeToMid](Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md) | `main.bi_db.bronze_etoro_billing_mapmerchantcodetomid` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.Redeem](Wiki/Billing/Tables/Billing.Redeem.md) | `main.billing.bronze_etoro_billing_redeem` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.Withdraw](Wiki/Billing/Tables/Billing.Withdraw.md) | `main.billing.bronze_etoro_billing_withdraw` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.WithdrawPaymentMethods](Wiki/Billing/Tables/Billing.WithdrawPaymentMethods.md) | `main.bi_db.bronze_etoro_billing_withdrawpaymentmethods` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.WithdrawRejects](Wiki/Billing/Tables/Billing.WithdrawRejects.md) | `main.billing.bronze_etoro_billing_withdrawrejects` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.vWithdrawToFunding](Wiki/Billing/Views/Billing.vWithdrawToFunding.md) | `main.billing.bronze_etoro_billing_vwithdrawtofunding` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.Address](Wiki/Customer/Tables/Customer.Address.md) | `main.pii_data.bronze_etoro_customer_address` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.Address](Wiki/Customer/Tables/Customer.Address.md) | `main.bi_db.bronze_etoro_customer_address_masked` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.BlockedCustomerOperations](Wiki/Customer/Tables/Customer.BlockedCustomerOperations.md) | `main.general.bronze_etoro_customer_blockedcustomeroperations` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.Customer](Wiki/Customer/Views/Customer.Customer.md) | `main.pii_data.bronze_etoro_customer_customer` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.Customer](Wiki/Customer/Views/Customer.Customer.md) | `main.general.bronze_etoro_customer_customer_masked` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.CustomerLatinName](Wiki/Customer/Tables/Customer.CustomerLatinName.md) | `main.pii_data.bronze_etoro_customer_customerlatinname` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.CustomerLatinName](Wiki/Customer/Tables/Customer.CustomerLatinName.md) | `main.general.bronze_etoro_customer_customerlatinname_masked` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.CustomerMoney](Wiki/Customer/Tables/Customer.CustomerMoney.md) | `main.bi_db.bronze_etoro_customer_customermoney` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.CustomerStatic](Wiki/Customer/Tables/Customer.CustomerStatic.md) | `main.pii_data.bronze_etoro_customer_customerstatic` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.CustomerStatic](Wiki/Customer/Tables/Customer.CustomerStatic.md) | `main.general.bronze_etoro_customer_customerstatic_masked` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.RAFGiven](Wiki/Customer/Tables/Customer.RAFGiven.md) | `main.experience.bronze_etoro_customer_rafgiven` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.TrackingId](Wiki/Customer/Tables/Customer.TrackingId.md) | `main.general.bronze_etoro_customer_trackingid` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.TwoFactorVerificationDetails](Wiki/Customer/Tables/Customer.TwoFactorVerificationDetails.md) | `main.general.bronze_etoro_customer_twofactorverificationdetails` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AcceptanceStatus](Wiki/Dictionary/Tables/Dictionary.AcceptanceStatus.md) | `main.general.bronze_etoro_dictionary_acceptancestatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AccountStatus](Wiki/Dictionary/Tables/Dictionary.AccountStatus.md) | `main.general.bronze_etoro_dictionary_accountstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AccountTransactionType](Wiki/Dictionary/Tables/Dictionary.AccountTransactionType.md) | `main.general.bronze_etoro_dictionary_accounttransactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AccountType](Wiki/Dictionary/Tables/Dictionary.AccountType.md) | `main.general.bronze_etoro_dictionary_accounttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AccountUpdateType](Wiki/Dictionary/Tables/Dictionary.AccountUpdateType.md) | `main.general.bronze_etoro_dictionary_accountupdatetype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ActionType](Wiki/Dictionary/Tables/Dictionary.ActionType.md) | `main.general.bronze_etoro_dictionary_actiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AdminPositionState](Wiki/Dictionary/Tables/Dictionary.AdminPositionState.md) | `main.bi_db.bronze_etoro_dictionary_adminpositionstate` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AffiliateStatus](Wiki/Dictionary/Tables/Dictionary.AffiliateStatus.md) | `main.general.bronze_etoro_dictionary_affiliatestatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AllocationType](Wiki/Dictionary/Tables/Dictionary.AllocationType.md) | `main.general.bronze_etoro_dictionary_allocationtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AuditActionType](Wiki/Dictionary/Tables/Dictionary.AuditActionType.md) | `main.general.bronze_etoro_dictionary_auditactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AuthenticationReason](Wiki/Dictionary/Tables/Dictionary.AuthenticationReason.md) | `main.general.bronze_etoro_dictionary_authenticationreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AuthenticationReasonPOI](Wiki/Dictionary/Tables/Dictionary.AuthenticationReasonPOI.md) | `main.general.bronze_etoro_dictionary_authenticationreasonpoi` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.AuthenticationReasonSelfie](Wiki/Dictionary/Tables/Dictionary.AuthenticationReasonSelfie.md) | `main.general.bronze_etoro_dictionary_authenticationreasonselfie` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.BSLMessageTypes](Wiki/Dictionary/Tables/Dictionary.BSLMessageTypes.md) | `main.general.bronze_etoro_dictionary_bslmessagetypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.BSLOperationThreshold](Wiki/Dictionary/Tables/Dictionary.BSLOperationThreshold.md) | `main.general.bronze_etoro_dictionary_bsloperationthreshold` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Bank](Wiki/Dictionary/Tables/Dictionary.Bank.md) | `main.general.bronze_etoro_dictionary_bank` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.BankBin](Wiki/Dictionary/Tables/Dictionary.BankBin.md) | `main.general.bronze_etoro_dictionary_bankbin` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.BlockUnBlockReason](Wiki/Dictionary/Tables/Dictionary.BlockUnBlockReason.md) | `main.general.bronze_etoro_dictionary_blockunblockreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.BlockedDataType](Wiki/Dictionary/Tables/Dictionary.BlockedDataType.md) | `main.general.bronze_etoro_dictionary_blockeddatatype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.BonusStatus](Wiki/Dictionary/Tables/Dictionary.BonusStatus.md) | `main.general.bronze_etoro_dictionary_bonusstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CEPNamedListTypeID](Wiki/Dictionary/Tables/Dictionary.CEPNamedListTypeID.md) | `main.general.bronze_etoro_dictionary_cepnamedlisttypeid` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CandleTimeframes](Wiki/Dictionary/Tables/Dictionary.CandleTimeframes.md) | `main.general.bronze_etoro_dictionary_candletimeframes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CardType](Wiki/Dictionary/Tables/Dictionary.CardType.md) | `main.general.bronze_etoro_dictionary_cardtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CardTypeToBank](Wiki/Dictionary/Tables/Dictionary.CardTypeToBank.md) | `main.general.bronze_etoro_dictionary_cardtypetobank` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutActionStatus](Wiki/Dictionary/Tables/Dictionary.CashoutActionStatus.md) | `main.general.bronze_etoro_dictionary_cashoutactionstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutFeeGroup](Wiki/Dictionary/Tables/Dictionary.CashoutFeeGroup.md) | `main.general.bronze_etoro_dictionary_cashoutfeegroup` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutMode](Wiki/Dictionary/Tables/Dictionary.CashoutMode.md) | `main.general.bronze_etoro_dictionary_cashoutmode` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutReason](Wiki/Dictionary/Tables/Dictionary.CashoutReason.md) | `main.general.bronze_etoro_dictionary_cashoutreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutRejectReason](Wiki/Dictionary/Tables/Dictionary.CashoutRejectReason.md) | `main.general.bronze_etoro_dictionary_cashoutrejectreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutStatus](Wiki/Dictionary/Tables/Dictionary.CashoutStatus.md) | `main.general.bronze_etoro_dictionary_cashoutstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CashoutType](Wiki/Dictionary/Tables/Dictionary.CashoutType.md) | `main.general.bronze_etoro_dictionary_cashouttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ChampionshipPlayerStatus](Wiki/Dictionary/Tables/Dictionary.ChampionshipPlayerStatus.md) | `main.general.bronze_etoro_dictionary_championshipplayerstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ChampionshipType](Wiki/Dictionary/Tables/Dictionary.ChampionshipType.md) | `main.general.bronze_etoro_dictionary_championshiptype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ClientType](Wiki/Dictionary/Tables/Dictionary.ClientType.md) | `main.general.bronze_etoro_dictionary_clienttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ClientWithdrawReason](Wiki/Dictionary/Tables/Dictionary.ClientWithdrawReason.md) | `main.general.bronze_etoro_dictionary_clientwithdrawreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CloseMirrorActionType](Wiki/Dictionary/Tables/Dictionary.CloseMirrorActionType.md) | `main.general.bronze_etoro_dictionary_closemirroractiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ClosePositionActionType](Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md) | `main.general.bronze_etoro_dictionary_closepositionactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ConditionOperators](Wiki/Dictionary/Tables/Dictionary.ConditionOperators.md) | `main.general.bronze_etoro_dictionary_conditionoperators` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ConditionProperties](Wiki/Dictionary/Tables/Dictionary.ConditionProperties.md) | `main.general.bronze_etoro_dictionary_conditionproperties` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ConversationReason](Wiki/Dictionary/Tables/Dictionary.ConversationReason.md) | `main.general.bronze_etoro_dictionary_conversationreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ConversationType](Wiki/Dictionary/Tables/Dictionary.ConversationType.md) | `main.general.bronze_etoro_dictionary_conversationtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CorporateAction](Wiki/Dictionary/Tables/Dictionary.CorporateAction.md) | `main.general.bronze_etoro_dictionary_corporateaction` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Country](Wiki/Dictionary/Tables/Dictionary.Country.md) | `main.general.bronze_etoro_dictionary_country` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CountryBin](Wiki/Dictionary/Views/Dictionary.CountryBin.md) | `main.general.bronze_etoro_dictionary_countrybin` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CountryGroup](Wiki/Dictionary/Tables/Dictionary.CountryGroup.md) | `main.general.bronze_etoro_dictionary_countrygroup` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CountryIP](Wiki/Dictionary/Tables/Dictionary.CountryIP.md) | `main.general.bronze_etoro_dictionary_countryip` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CountryToCountryGroup](Wiki/Dictionary/Tables/Dictionary.CountryToCountryGroup.md) | `main.general.bronze_etoro_dictionary_countrytocountrygroup` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CreditType](Wiki/Dictionary/Tables/Dictionary.CreditType.md) | `main.general.bronze_etoro_dictionary_credittype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Currency](Wiki/Dictionary/Tables/Dictionary.Currency.md) | `main.general.bronze_etoro_dictionary_currency` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.CurrencyType](Wiki/Dictionary/Tables/Dictionary.CurrencyType.md) | `main.general.bronze_etoro_dictionary_currencytype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DepositDRStatus](Wiki/Dictionary/Tables/Dictionary.DepositDRStatus.md) | `main.bi_db.bronze_etoro_dictionary_depositdrstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DepositRollbackType](Wiki/Dictionary/Tables/Dictionary.DepositRollbackType.md) | `main.general.bronze_etoro_dictionary_depositrollbacktype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DepositRollbackTypeReason](Wiki/Dictionary/Tables/Dictionary.DepositRollbackTypeReason.md) | `main.general.bronze_etoro_dictionary_depositrollbacktypereason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DepositStatusReason](Wiki/Dictionary/Tables/Dictionary.DepositStatusReason.md) | `main.bi_db.bronze_etoro_dictionary_depositstatusreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DepositType](Wiki/Dictionary/Tables/Dictionary.DepositType.md) | `main.general.bronze_etoro_dictionary_deposittype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DepotMode](Wiki/Dictionary/Tables/Dictionary.DepotMode.md) | `main.general.bronze_etoro_dictionary_depotmode` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentAutheticationType](Wiki/Dictionary/Tables/Dictionary.DocumentAutheticationType.md) | `main.general.bronze_etoro_dictionary_documentautheticationtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentClassification](Wiki/Dictionary/Tables/Dictionary.DocumentClassification.md) | `main.general.bronze_etoro_dictionary_documentclassification` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentRejectReason](Wiki/Dictionary/Tables/Dictionary.DocumentRejectReason.md) | `main.general.bronze_etoro_dictionary_documentrejectreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentSide](Wiki/Dictionary/Tables/Dictionary.DocumentSide.md) | `main.general.bronze_etoro_dictionary_documentside` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentSizeActionType](Wiki/Dictionary/Tables/Dictionary.DocumentSizeActionType.md) | `main.general.bronze_etoro_dictionary_documentsizeactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentStatus](Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md) | `main.general.bronze_etoro_dictionary_documentstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DocumentType](Wiki/Dictionary/Tables/Dictionary.DocumentType.md) | `main.general.bronze_etoro_dictionary_documenttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Feature](Wiki/Dictionary/Tables/Dictionary.Feature.md) | `main.general.bronze_etoro_dictionary_feature` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FeatureThreshold](Wiki/Dictionary/Tables/Dictionary.FeatureThreshold.md) | `main.general.bronze_etoro_dictionary_featurethreshold` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FeeDefinition](Wiki/Dictionary/Tables/Dictionary.FeeDefinition.md) | `main.bi_db.bronze_etoro_dictionary_feedefinition` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FinancialDiscrepancyType](Wiki/Dictionary/Tables/Dictionary.FinancialDiscrepancyType.md) | `main.finance.bronze_etoro_dictionary_financialdiscrepancytype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Flow](Wiki/Dictionary/Tables/Dictionary.Flow.md) | `main.general.bronze_etoro_dictionary_flow` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FundIntervalType](Wiki/Dictionary/Tables/Dictionary.FundIntervalType.md) | `main.general.bronze_etoro_dictionary_fundintervaltype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FundType](Wiki/Dictionary/Tables/Dictionary.FundType.md) | `main.general.bronze_etoro_dictionary_fundtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FundingDataMigrationStatus](Wiki/Dictionary/Tables/Dictionary.FundingDataMigrationStatus.md) | `main.general.bronze_etoro_dictionary_fundingdatamigrationstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FundingType](Wiki/Dictionary/Tables/Dictionary.FundingType.md) | `main.general.bronze_etoro_dictionary_fundingtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.FundingTypeToXSDUniqueElement](Wiki/Dictionary/Tables/Dictionary.FundingTypeToXSDUniqueElement.md) | `main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Funnel](Wiki/Dictionary/Tables/Dictionary.Funnel.md) | `main.general.bronze_etoro_dictionary_funnel` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.GDCCheck](Wiki/Dictionary/Tables/Dictionary.GDCCheck.md) | `main.general.bronze_etoro_dictionary_gdccheck` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.GameServer](Wiki/Dictionary/Tables/Dictionary.GameServer.md) | `main.general.bronze_etoro_dictionary_gameserver` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.GameSubType](Wiki/Dictionary/Tables/Dictionary.GameSubType.md) | `main.general.bronze_etoro_dictionary_gamesubtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.GameType](Wiki/Dictionary/Tables/Dictionary.GameType.md) | `main.general.bronze_etoro_dictionary_gametype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Groups](Wiki/Dictionary/Tables/Dictionary.Groups.md) | `main.general.bronze_etoro_dictionary_groups` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.GuruStatus](Wiki/Dictionary/Tables/Dictionary.GuruStatus.md) | `main.general.bronze_etoro_dictionary_gurustatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HBCOrderState](Wiki/Dictionary/Tables/Dictionary.HBCOrderState.md) | `main.general.bronze_etoro_dictionary_hbcorderstate` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgeBreakdownType](Wiki/Dictionary/Tables/Dictionary.HedgeBreakdownType.md) | `main.general.bronze_etoro_dictionary_hedgebreakdowntype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgeEventType](Wiki/Dictionary/Tables/Dictionary.HedgeEventType.md) | `main.general.bronze_etoro_dictionary_hedgeeventtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgeManualRequestType](Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md) | `main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgeOrderState](Wiki/Dictionary/Tables/Dictionary.HedgeOrderState.md) | `main.general.bronze_etoro_dictionary_hedgeorderstate` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgePositionFailReason](Wiki/Dictionary/Tables/Dictionary.HedgePositionFailReason.md) | `main.general.bronze_etoro_dictionary_hedgepositionfailreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgePositionFailSeverity](Wiki/Dictionary/Tables/Dictionary.HedgePositionFailSeverity.md) | `main.general.bronze_etoro_dictionary_hedgepositionfailseverity` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgeRecoveryState](Wiki/Dictionary/Tables/Dictionary.HedgeRecoveryState.md) | `main.general.bronze_etoro_dictionary_hedgerecoverystate` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.HedgeStrategyMode](Wiki/Dictionary/Tables/Dictionary.HedgeStrategyMode.md) | `main.general.bronze_etoro_dictionary_hedgestrategymode` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.InstrumentOperationMode](Wiki/Dictionary/Tables/Dictionary.InstrumentOperationMode.md) | `main.dealing.bronze_etoro_dictionary_instrumentoperationmode` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.InterestRate](Wiki/Dictionary/Tables/Dictionary.InterestRate.md) | `main.general.bronze_etoro_dictionary_interestrate` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.InterestRateOverride](Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md) | `main.bi_db.bronze_etoro_dictionary_interestrateoverride` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.JobEnvironmentType](Wiki/Dictionary/Tables/Dictionary.JobEnvironmentType.md) | `main.general.bronze_etoro_dictionary_jobenvironmenttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Justefied](Wiki/Dictionary/Tables/Dictionary.Justefied.md) | `main.general.bronze_etoro_dictionary_justefied` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Label](Wiki/Dictionary/Tables/Dictionary.Label.md) | `main.general.bronze_etoro_dictionary_label` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Language](Wiki/Dictionary/Tables/Dictionary.Language.md) | `main.general.bronze_etoro_dictionary_language` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Leverage](Wiki/Dictionary/Tables/Dictionary.Leverage.md) | `main.general.bronze_etoro_dictionary_leverage` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.LeverageTypes](Wiki/Dictionary/Tables/Dictionary.LeverageTypes.md) | `main.general.bronze_etoro_dictionary_leveragetypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ListenerType](Wiki/Dictionary/Tables/Dictionary.ListenerType.md) | `main.general.bronze_etoro_dictionary_listenertype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.LotCount](Wiki/Dictionary/Tables/Dictionary.LotCount.md) | `main.general.bronze_etoro_dictionary_lotcount` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.LotCountGroup](Wiki/Dictionary/Tables/Dictionary.LotCountGroup.md) | `main.general.bronze_etoro_dictionary_lotcountgroup` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ManagerPermit](Wiki/Dictionary/Tables/Dictionary.ManagerPermit.md) | `main.general.bronze_etoro_dictionary_managerpermit` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MarketingRegion](Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md) | `main.general.bronze_etoro_dictionary_marketingregion` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`general`.`bronze_etoro_dictionary_marketingregion` cannot  |
| [Dictionary.MatchStatus](Wiki/Dictionary/Tables/Dictionary.MatchStatus.md) | `main.general.bronze_etoro_dictionary_matchstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Merchant](Wiki/Dictionary/Tables/Dictionary.Merchant.md) | `main.general.bronze_etoro_dictionary_merchant` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MerchantAccount](Wiki/Dictionary/Tables/Dictionary.MerchantAccount.md) | `main.general.bronze_etoro_dictionary_merchantaccount` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MessageType](Wiki/Dictionary/Tables/Dictionary.MessageType.md) | `main.general.bronze_etoro_dictionary_messagetype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MifidCategorization](Wiki/Dictionary/Tables/Dictionary.MifidCategorization.md) | `main.general.bronze_etoro_dictionary_mifidcategorization` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MirrorOperation](Wiki/Dictionary/Tables/Dictionary.MirrorOperation.md) | `main.general.bronze_etoro_dictionary_mirroroperation` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MirrorType](Wiki/Dictionary/Tables/Dictionary.MirrorType.md) | `main.general.bronze_etoro_dictionary_mirrortype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MoveMoneyReason](Wiki/Dictionary/Tables/Dictionary.MoveMoneyReason.md) | `main.general.bronze_etoro_dictionary_movemoneyreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NoteType](Wiki/Dictionary/Tables/Dictionary.NoteType.md) | `main.general.bronze_etoro_dictionary_notetype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NotificationMessageStatus](Wiki/Dictionary/Tables/Dictionary.NotificationMessageStatus.md) | `main.general.bronze_etoro_dictionary_notificationmessagestatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NotificationStatus](Wiki/Dictionary/Tables/Dictionary.NotificationStatus.md) | `main.general.bronze_etoro_dictionary_notificationstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NotificationTrigger](Wiki/Dictionary/Tables/Dictionary.NotificationTrigger.md) | `main.general.bronze_etoro_dictionary_notificationtrigger` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NotificationType](Wiki/Dictionary/Tables/Dictionary.NotificationType.md) | `main.general.bronze_etoro_dictionary_notificationtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NotificationTypeName](Wiki/Dictionary/Tables/Dictionary.NotificationTypeName.md) | `main.general.bronze_etoro_dictionary_notificationtypename` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Objects](Wiki/Dictionary/Tables/Dictionary.Objects.md) | `main.general.bronze_etoro_dictionary_objects` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OpenPositionActionType](Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md) | `main.bi_db.bronze_etoro_dictionary_openpositionactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OperationTypesForBlocking](Wiki/Dictionary/Tables/Dictionary.OperationTypesForBlocking.md) | `main.general.bronze_etoro_dictionary_operationtypesforblocking` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OptOutReason](Wiki/Dictionary/Tables/Dictionary.OptOutReason.md) | `main.general.bronze_etoro_dictionary_optoutreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OrderType](Wiki/Dictionary/Tables/Dictionary.OrderType.md) | `main.general.bronze_etoro_dictionary_ordertype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OrdersActionType](Wiki/Dictionary/Tables/Dictionary.OrdersActionType.md) | `main.general.bronze_etoro_dictionary_ordersactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OrdersEntryActionType](Wiki/Dictionary/Tables/Dictionary.OrdersEntryActionType.md) | `main.general.bronze_etoro_dictionary_ordersentryactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OrdersExitActionType](Wiki/Dictionary/Tables/Dictionary.OrdersExitActionType.md) | `main.general.bronze_etoro_dictionary_ordersexitactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.OrdersExitCloseActionType](Wiki/Dictionary/Tables/Dictionary.OrdersExitCloseActionType.md) | `main.general.bronze_etoro_dictionary_ordersexitcloseactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PCL_ChangeType](Wiki/Dictionary/Tables/Dictionary.PCL_ChangeType.md) | `main.general.bronze_etoro_dictionary_pcl_changetype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentActionStatus](Wiki/Dictionary/Tables/Dictionary.PaymentActionStatus.md) | `main.general.bronze_etoro_dictionary_paymentactionstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentActionType](Wiki/Dictionary/Tables/Dictionary.PaymentActionType.md) | `main.general.bronze_etoro_dictionary_paymentactiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentDirection](Wiki/Dictionary/Tables/Dictionary.PaymentDirection.md) | `main.general.bronze_etoro_dictionary_paymentdirection` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentServiceStatus](Wiki/Dictionary/Tables/Dictionary.PaymentServiceStatus.md) | `main.general.bronze_etoro_dictionary_paymentservicestatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentStatus](Wiki/Dictionary/Tables/Dictionary.PaymentStatus.md) | `main.general.bronze_etoro_dictionary_paymentstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentStatusNotification](Wiki/Dictionary/Tables/Dictionary.PaymentStatusNotification.md) | `main.general.bronze_etoro_dictionary_paymentstatusnotification` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentStatusStateMachine](Wiki/Dictionary/Tables/Dictionary.PaymentStatusStateMachine.md) | `main.general.bronze_etoro_dictionary_paymentstatusstatemachine` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentType](Wiki/Dictionary/Tables/Dictionary.PaymentType.md) | `main.general.bronze_etoro_dictionary_paymenttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PayoutProcessReason](Wiki/Dictionary/Tables/Dictionary.PayoutProcessReason.md) | `main.general.bronze_etoro_dictionary_payoutprocessreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PendingClosureStatus](Wiki/Dictionary/Tables/Dictionary.PendingClosureStatus.md) | `main.general.bronze_etoro_dictionary_pendingclosurestatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Permission](Wiki/Dictionary/Tables/Dictionary.Permission.md) | `main.general.bronze_etoro_dictionary_permission` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PhoneTypes](Wiki/Dictionary/Tables/Dictionary.PhoneTypes.md) | `main.general.bronze_etoro_dictionary_phonetypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PhoneVerificationListType](Wiki/Dictionary/Tables/Dictionary.PhoneVerificationListType.md) | `main.general.bronze_etoro_dictionary_phoneverificationlisttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PhoneVerificationRiskLevel](Wiki/Dictionary/Tables/Dictionary.PhoneVerificationRiskLevel.md) | `main.general.bronze_etoro_dictionary_phoneverificationrisklevel` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PhoneVerificationTransactionRecommendation](Wiki/Dictionary/Tables/Dictionary.PhoneVerificationTransactionRecommendation.md) | `main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PhoneVerified](Wiki/Dictionary/Tables/Dictionary.PhoneVerified.md) | `main.general.bronze_etoro_dictionary_phoneverified` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Platform](Wiki/Dictionary/Tables/Dictionary.Platform.md) | `main.general.bronze_etoro_dictionary_platform` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PlayerLevel](Wiki/Dictionary/Tables/Dictionary.PlayerLevel.md) | `main.general.bronze_etoro_dictionary_playerlevel` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PlayerStatus](Wiki/Dictionary/Tables/Dictionary.PlayerStatus.md) | `main.general.bronze_etoro_dictionary_playerstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PlayerStatusReasons](Wiki/Dictionary/Tables/Dictionary.PlayerStatusReasons.md) | `main.general.bronze_etoro_dictionary_playerstatusreasons` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PlayerStatusSubReasons](Wiki/Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md) | `main.general.bronze_etoro_dictionary_playerstatussubreasons` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PrivacyEvents](Wiki/Dictionary/Tables/Dictionary.PrivacyEvents.md) | `main.general.bronze_etoro_dictionary_privacyevents` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PrivacyPolicy](Wiki/Dictionary/Tables/Dictionary.PrivacyPolicy.md) | `main.general.bronze_etoro_dictionary_privacypolicy` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PrivacyPolicyDetails](Wiki/Dictionary/Tables/Dictionary.PrivacyPolicyDetails.md) | `main.general.bronze_etoro_dictionary_privacypolicydetails` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PrivacyRecipients](Wiki/Dictionary/Tables/Dictionary.PrivacyRecipients.md) | `main.general.bronze_etoro_dictionary_privacyrecipients` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PrizeType](Wiki/Dictionary/Tables/Dictionary.PrizeType.md) | `main.general.bronze_etoro_dictionary_prizetype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PromotionType](Wiki/Dictionary/Tables/Dictionary.PromotionType.md) | `main.general.bronze_etoro_dictionary_promotiontype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Protocol](Wiki/Dictionary/Tables/Dictionary.Protocol.md) | `main.general.bronze_etoro_dictionary_protocol` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ProtocolDirection](Wiki/Dictionary/Tables/Dictionary.ProtocolDirection.md) | `main.general.bronze_etoro_dictionary_protocoldirection` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ProtocolParameter](Wiki/Dictionary/Tables/Dictionary.ProtocolParameter.md) | `main.general.bronze_etoro_dictionary_protocolparameter` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ProviderPercentageRouting](Wiki/Dictionary/Tables/Dictionary.ProviderPercentageRouting.md) | `main.general.bronze_etoro_dictionary_providerpercentagerouting` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RedeemApprovalReason](Wiki/Dictionary/Tables/Dictionary.RedeemApprovalReason.md) | `main.general.bronze_etoro_dictionary_redeemapprovalreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RedeemReason](Wiki/Dictionary/Tables/Dictionary.RedeemReason.md) | `main.general.bronze_etoro_dictionary_redeemreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RedeemStatus](Wiki/Dictionary/Tables/Dictionary.RedeemStatus.md) | `main.general.bronze_etoro_dictionary_redeemstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Region](Wiki/Dictionary/Tables/Dictionary.Region.md) | `main.general.bronze_etoro_dictionary_region` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RegionByIP](Wiki/Dictionary/Tables/Dictionary.RegionByIP.md) | `main.general.bronze_etoro_dictionary_regionbyip` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RegionName](Wiki/Dictionary/Tables/Dictionary.RegionName.md) | `main.general.bronze_etoro_dictionary_regionname` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Regulation](Wiki/Dictionary/Tables/Dictionary.Regulation.md) | `main.general.bronze_etoro_dictionary_regulation` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Response](Wiki/Dictionary/Tables/Dictionary.Response.md) | `main.general.bronze_etoro_dictionary_response` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskClassification](Wiki/Dictionary/Tables/Dictionary.RiskClassification.md) | `main.general.bronze_etoro_dictionary_riskclassification` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskClassificationParameter](Wiki/Dictionary/Tables/Dictionary.RiskClassificationParameter.md) | `main.bi_db.bronze_etoro_dictionary_riskclassificationparameter` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskClassificationRegulation](Wiki/Dictionary/Tables/Dictionary.RiskClassificationRegulation.md) | `main.bi_db.bronze_etoro_dictionary_riskclassificationregulation` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskCountryPairs](Wiki/Dictionary/Tables/Dictionary.RiskCountryPairs.md) | `main.general.bronze_etoro_dictionary_riskcountrypairs` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskEventStatus](Wiki/Dictionary/Tables/Dictionary.RiskEventStatus.md) | `main.general.bronze_etoro_dictionary_riskeventstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskManagementStatus](Wiki/Dictionary/Tables/Dictionary.RiskManagementStatus.md) | `main.general.bronze_etoro_dictionary_riskmanagementstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.RiskStatus](Wiki/Dictionary/Tables/Dictionary.RiskStatus.md) | `main.general.bronze_etoro_dictionary_riskstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.StockOrderCloseReason](Wiki/Dictionary/Tables/Dictionary.StockOrderCloseReason.md) | `main.general.bronze_etoro_dictionary_stockorderclosereason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.StocksIndustry](Wiki/Dictionary/Tables/Dictionary.StocksIndustry.md) | `main.general.bronze_etoro_dictionary_stocksindustry` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.SubRegion](Wiki/Dictionary/Tables/Dictionary.SubRegion.md) | `main.general.bronze_etoro_dictionary_subregion` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.SuitabilityTestStatus](Wiki/Dictionary/Tables/Dictionary.SuitabilityTestStatus.md) | `main.general.bronze_etoro_dictionary_suitabilityteststatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TaskType](Wiki/Dictionary/Tables/Dictionary.TaskType.md) | `main.general.bronze_etoro_dictionary_tasktype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ThreeDsResponseTypes](Wiki/Dictionary/Tables/Dictionary.ThreeDsResponseTypes.md) | `main.general.bronze_etoro_dictionary_threedsresponsetypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TimeZone](Wiki/Dictionary/Tables/Dictionary.TimeZone.md) | `main.general.bronze_etoro_dictionary_timezone` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TncDocType](Wiki/Dictionary/Tables/Dictionary.TncDocType.md) | `main.general.bronze_etoro_dictionary_tncdoctype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Tracking](Wiki/Dictionary/Tables/Dictionary.Tracking.md) | `main.general.bronze_etoro_dictionary_tracking` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TradeLevel](Wiki/Dictionary/Tables/Dictionary.TradeLevel.md) | `main.general.bronze_etoro_dictionary_tradelevel` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TradingInstrumentGroups](Wiki/Dictionary/Tables/Dictionary.TradingInstrumentGroups.md) | `main.trading.bronze_etoro_dictionary_tradinginstrumentgroups` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TradingRiskStatus](Wiki/Dictionary/Tables/Dictionary.TradingRiskStatus.md) | `main.general.bronze_etoro_dictionary_tradingriskstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.UserGroup](Wiki/Dictionary/Tables/Dictionary.UserGroup.md) | `main.general.bronze_etoro_dictionary_usergroup` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.UserGroupToPermission](Wiki/Dictionary/Tables/Dictionary.UserGroupToPermission.md) | `main.general.bronze_etoro_dictionary_usergrouptopermission` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.VerificationLevel](Wiki/Dictionary/Tables/Dictionary.VerificationLevel.md) | `main.general.bronze_etoro_dictionary_verificationlevel` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WebinarAction](Wiki/Dictionary/Tables/Dictionary.WebinarAction.md) | `main.general.bronze_etoro_dictionary_webinaraction` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WithdrawApprovalReason](Wiki/Dictionary/Tables/Dictionary.WithdrawApprovalReason.md) | `main.general.bronze_etoro_dictionary_withdrawapprovalreason` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WithdrawType](Wiki/Dictionary/Tables/Dictionary.WithdrawType.md) | `main.bi_db.bronze_etoro_dictionary_withdrawtype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WorldCheck](Wiki/Dictionary/Tables/Dictionary.WorldCheck.md) | `main.general.bronze_etoro_dictionary_worldcheck` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.XSDUniqueElement](Wiki/Dictionary/Tables/Dictionary.XSDUniqueElement.md) | `main.general.bronze_etoro_dictionary_xsduniqueelement` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.AccountInstrumentConfiguration](Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md) | `main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.BoundariesConfiguration](Wiki/Hedge/Tables/Hedge.BoundariesConfiguration.md) | `main.trading.bronze_etoro_hedge_boundariesconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.ExecutionFactorConfiguration](Wiki/Hedge/Tables/Hedge.ExecutionFactorConfiguration.md) | `main.dealing.bronze_etoro_hedge_executionfactorconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.ExecutionLog](Wiki/Hedge/Tables/Hedge.ExecutionLog.md) | `main.dealing.bronze_etoro_hedge_executionlog` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.ExposureCircuitBreakerThresholds](Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md) | `main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.HBCAccountConfiguration](Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md) | `main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.HBCExecutionLog](Wiki/Hedge/Tables/Hedge.HBCExecutionLog.md) | `main.dealing.bronze_etoro_hedge_hbcexecutionlog` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.HBCOrderLog](Wiki/Hedge/Tables/Hedge.HBCOrderLog.md) | `main.dealing.bronze_etoro_hedge_hbcorderlog` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.HedgeServerInstrumentConfiguration](Wiki/Hedge/Tables/Hedge.HedgeServerInstrumentConfiguration.md) | `main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.HedgeServerToLiquidityAccount](Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md) | `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.InstrumentBoundaries](Wiki/Hedge/Tables/Hedge.InstrumentBoundaries.md) | `main.dealing.bronze_etoro_hedge_instrumentboundaries` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.InstrumentConfiguration](Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md) | `main.bi_db.bronze_etoro_hedge_instrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.InstrumentGroups](Wiki/Hedge/Tables/Hedge.InstrumentGroups.md) | `main.bi_db.bronze_etoro_hedge_instrumentgroups` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.InstrumentGroupsMapping](Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md) | `main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.KPIInstrumentLog](Wiki/Hedge/Tables/Hedge.KPIInstrumentLog.md) | `main.general.bronze_etoro_hedge_kpiinstrumentlog` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.ManualOrderExecutionLog](Wiki/Hedge/Tables/Hedge.ManualOrderExecutionLog.md) | `main.dealing.bronze_etoro_hedge_manualorderexecutionlog` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.Netting](Wiki/Hedge/Tables/Hedge.Netting.md) | `main.dealing.bronze_etoro_hedge_netting` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.PortfolioConversionConfigurations](Wiki/Hedge/Tables/Hedge.PortfolioConversionConfigurations.md) | `main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.ProviderInstrumentConfiguration](Wiki/Hedge/Tables/Hedge.ProviderInstrumentConfiguration.md) | `main.trading.bronze_etoro_hedge_providerinstrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.ProviderUnitConversionRatio](Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md) | `main.bi_db.bronze_etoro_hedge_providerunitconversionratio` | Deployed (Batch 1) - 2026-05-03 |
| [Hedge.SupportedInstrumentsAccount](Wiki/Hedge/Tables/Hedge.SupportedInstrumentsAccount.md) | `main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount` | Deployed (Batch 1) - 2026-05-03 |
| [History.AuditHistory](Wiki/History/Tables/History.AuditHistory.md) | `main.general.bronze_etoro_history_audithistory` | Deployed (Batch 1) - 2026-05-03 |
| [History.BSLCurrencyPriceSnapShots](Wiki/History/Tables/History.BSLCurrencyPriceSnapShots.md) | `main.general.bronze_etoro_history_bslcurrencypricesnapshots` | Deployed (Batch 1) - 2026-05-03 |
| [History.BSLPositionsInfo](Wiki/History/Tables/History.BSLPositionsInfo.md) | `main.general.bronze_etoro_history_bslpositionsinfo` | Deployed (Batch 1) - 2026-05-03 |
| [History.BackOfficeCustomer](Wiki/History/Tables/History.BackOfficeCustomer.md) | `main.general.bronze_etoro_history_backofficecustomer` | Deployed (Batch 1) - 2026-05-03 |
| [History.BlockedCustomerOperations](Wiki/History/Tables/History.BlockedCustomerOperations.md) | `main.general.bronze_etoro_history_blockedcustomeroperations` | Deployed (Batch 1) - 2026-05-03 |
| [History.CEPListCIDMappings](Wiki/History/Tables/History.CEPListCIDMappings.md) | `main.general.bronze_etoro_history_ceplistcidmappings` | Deployed (Batch 1) - 2026-05-03 |
| [History.CEP_LOG_CompoundProperties](Wiki/History/Tables/History.CEP_LOG_CompoundProperties.md) | `main.general.bronze_etoro_history_cep_log_compoundproperties` | Deployed (Batch 1) - 2026-05-03 |
| [History.CEP_LOG_CompoundPropertyToRule](Wiki/History/Tables/History.CEP_LOG_CompoundPropertyToRule.md) | `main.general.bronze_etoro_history_cep_log_compoundpropertytorule` | Deployed (Batch 1) - 2026-05-03 |
| [History.CEP_LOG_ConditionToCompoundProperty](Wiki/History/Tables/History.CEP_LOG_ConditionToCompoundProperty.md) | `main.general.bronze_etoro_history_cep_log_conditiontocompoundproperty` | Deployed (Batch 1) - 2026-05-03 |
| [History.CEP_LOG_NamedLists](Wiki/History/Tables/History.CEP_LOG_NamedLists.md) | `main.general.bronze_etoro_history_cep_log_namedlists` | Deployed (Batch 1) - 2026-05-03 |
| [History.CEP_LOG_Rules](Wiki/History/Tables/History.CEP_LOG_Rules.md) | `main.general.bronze_etoro_history_cep_log_rules` | Deployed (Batch 1) - 2026-05-03 |
| [History.CES_ReloadExposures](Wiki/History/Tables/History.CES_ReloadExposures.md) | `main.general.bronze_etoro_history_ces_reloadexposures` | Deployed (Batch 1) - 2026-05-03 |
| [History.CompoundProperties](Wiki/History/Tables/History.CompoundProperties.md) | `main.general.bronze_etoro_history_compoundproperties` | Deployed (Batch 1) - 2026-05-03 |
| [History.CompoundPropertyToRule](Wiki/History/Tables/History.CompoundPropertyToRule.md) | `main.general.bronze_etoro_history_compoundpropertytorule` | Deployed (Batch 1) - 2026-05-03 |
| [History.ConditionToCompoundProperty](Wiki/History/Tables/History.ConditionToCompoundProperty.md) | `main.general.bronze_etoro_history_conditiontocompoundproperty` | Deployed (Batch 1) - 2026-05-03 |
| [History.Conditions](Wiki/History/Tables/History.Conditions.md) | `main.general.bronze_etoro_history_conditions` | Deployed (Batch 1) - 2026-05-03 |
| [History.Credit](Wiki/History/Views/History.Credit.md) | `main.general.bronze_etoro_history_credit` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `SubCreditTypeID, PartitionCol,  |
| [History.CurrencyPriceMaxDateWithSplitView](Wiki/History/Tables/History.CurrencyPriceMaxDateWithSplitView.md) | `main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview` | Deployed (Batch 1) - 2026-05-03 |
| [History.Customer](Wiki/History/Tables/History.Customer.md) | `main.pii_data.bronze_etoro_history_customer` | Deployed (Batch 1) - 2026-05-03 |
| [History.Customer](Wiki/History/Tables/History.Customer.md) | `main.general.bronze_etoro_history_customer_masked` | Deployed (Batch 1) - 2026-05-03 |
| [History.CustomerRisk](Wiki/History/Tables/History.CustomerRisk.md) | `main.general.bronze_etoro_history_customerrisk` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `RiskStatusID (see 3)` cannot be |
| [History.DepositAction](Wiki/History/Tables/History.DepositAction.md) | `main.general.bronze_etoro_history_depositaction` | Deployed (Batch 1) - 2026-05-03 |
| [History.Deposit_DataFactory](Wiki/History/Views/History.Deposit_DataFactory.md) | `main.bi_db.bronze_etoro_history_deposit_datafactory` | Deployed (Batch 1) - 2026-05-03 |
| [History.ExecutionFactorConfiguration](Wiki/History/Tables/History.ExecutionFactorConfiguration.md) | `main.dealing.bronze_etoro_history_executionfactorconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [History.ExposureCircuitBreakerThresholds](Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md) | `main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds` | Deployed (Batch 1) - 2026-05-03 |
| [History.FuturesMetaData](Wiki/History/Tables/History.FuturesMetaData.md) | `main.trading.bronze_etoro_history_futuresmetadata` | Deployed (Batch 1) - 2026-05-03 |
| [History.HedgeInstrumentConfiguration](Wiki/History/Tables/History.HedgeInstrumentConfiguration.md) | `main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [History.HedgeServer](Wiki/History/Tables/History.HedgeServer.md) | `main.trading.bronze_etoro_history_hedgeserver` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `HostName (duplicate)` cannot be |
| [History.HedgeServerInstrumentConfiguration](Wiki/History/Tables/History.HedgeServerInstrumentConfiguration.md) | `main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [History.HedgeServerToLiquidityAccount](Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md) | `main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount` | Deployed (Batch 1) - 2026-05-03 |
| [History.InstrumentConfiguration](Wiki/History/Tables/History.InstrumentConfiguration.md) | `main.general.bronze_etoro_history_instrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [History.InstrumentMetaData](Wiki/History/Tables/History.InstrumentMetaData.md) | `main.bi_db.bronze_etoro_history_instrumentmetadata` | Deployed (Batch 1) - 2026-05-03 |
| [History.InstrumentSpread](Wiki/History/Tables/History.InstrumentSpread.md) | `main.dealing.bronze_etoro_history_instrumentspread` | Deployed (Batch 1) - 2026-05-03 |
| [History.InstrumentToFeeConfig](Wiki/History/Tables/History.InstrumentToFeeConfig.md) | `main.general.bronze_etoro_history_instrumenttofeeconfig` | Deployed (Batch 1) - 2026-05-03 |
| [History.InstrumentToFeeConfigV2](Wiki/History/Tables/History.InstrumentToFeeConfigV2.md) | `main.trading.bronze_etoro_history_instrumenttofeeconfigv2` | Deployed (Batch 1) - 2026-05-03 |
| [History.InterestRate](Wiki/History/Tables/History.InterestRate.md) | `main.general.bronze_etoro_history_interestrate` | Deployed (Batch 1) - 2026-05-03 |
| [History.InterestRateOverride](Wiki/History/Tables/History.InterestRateOverride.md) | `main.bi_db.bronze_etoro_history_interestrateoverride` | Deployed (Batch 1) - 2026-05-03 |
| [History.LiquidityProviderContracts](Wiki/History/Tables/History.LiquidityProviderContracts.md) | `main.bi_db.bronze_etoro_history_liquidityprovidercontracts` | Deployed (Batch 1) - 2026-05-03 |
| [History.LiquidityProviderType](Wiki/History/Tables/History.LiquidityProviderType.md) | `main.trading.bronze_etoro_history_liquidityprovidertype` | Deployed (Batch 1) - 2026-05-03 |
| [History.LiquidityProviders](Wiki/History/Tables/History.LiquidityProviders.md) | `main.trading.bronze_etoro_history_liquidityproviders` | Deployed (Batch 1) - 2026-05-03 |
| [History.ListCIDMappings](Wiki/History/Tables/History.ListCIDMappings.md) | `main.general.bronze_etoro_history_listcidmappings` | Deployed (Batch 1) - 2026-05-03 |
| [History.ManageBSL](Wiki/History/Tables/History.ManageBSL.md) | `main.general.bronze_etoro_history_managebsl` | Deployed (Batch 1) - 2026-05-03 |
| [History.Mirror](Wiki/History/Tables/History.Mirror.md) | `main.trading.bronze_etoro_history_mirror` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `(ParentUserName - see #5)` cann |
| [History.NamedLists](Wiki/History/Tables/History.NamedLists.md) | `main.general.bronze_etoro_history_namedlists` | Deployed (Batch 1) - 2026-05-03 |
| [History.Netting_History](Wiki/History/Tables/History.Netting_History.md) | `main.dealing.bronze_etoro_history_netting_history` | Deployed (Batch 1) - 2026-05-03 |
| [History.Orders](Wiki/History/Tables/History.Orders.md) | `main.dealing.bronze_etoro_history_orders` | Deployed (Batch 1) - 2026-05-03 |
| [History.OrdersEntryTbl](Wiki/History/Tables/History.OrdersEntryTbl.md) | `main.general.bronze_etoro_history_ordersentrytbl` | Deployed (Batch 1) - 2026-05-03 |
| [History.OrdersExitTbl](Wiki/History/Tables/History.OrdersExitTbl.md) | `main.general.bronze_etoro_history_ordersexittbl` | Deployed (Batch 1) - 2026-05-03 |
| [History.PortfolioConversionConfigurations](Wiki/History/Tables/History.PortfolioConversionConfigurations.md) | `main.dealing.bronze_etoro_history_portfolioconversionconfigurations` | Deployed (Batch 1) - 2026-05-03 |
| [History.PositionSplit](Wiki/History/Tables/History.PositionSplit.md) | `main.trading.bronze_etoro_history_positionsplit` | Deployed (Batch 1) - 2026-05-03 |
| [History.PriceDetectionDifferenceLog](Wiki/History/Tables/History.PriceDetectionDifferenceLog.md) | `main.general.bronze_etoro_history_pricedetectiondifferencelog` | Deployed (Batch 1) - 2026-05-03 |
| [History.PriceDetectionNotificationLog](Wiki/History/Tables/History.PriceDetectionNotificationLog.md) | `main.dealing.bronze_etoro_history_pricedetectionnotificationlog` | Deployed (Batch 1) - 2026-05-03 |
| [History.ProviderInstrumentConfiguration](Wiki/History/Tables/History.ProviderInstrumentConfiguration.md) | `main.trading.bronze_etoro_history_providerinstrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [History.ProviderInstrumentToLeverage](Wiki/History/Tables/History.ProviderInstrumentToLeverage.md) | `main.bi_db.bronze_etoro_history_providerinstrumenttoleverage` | Deployed (Batch 1) - 2026-05-03 |
| [History.ProviderToInstrument](Wiki/History/Tables/History.ProviderToInstrument.md) | `main.general.bronze_etoro_history_providertoinstrument` | Deployed (Batch 1) - 2026-05-03 |
| [History.Rules](Wiki/History/Tables/History.Rules.md) | `main.general.bronze_etoro_history_rules` | Deployed (Batch 1) - 2026-05-03 |
| [History.TradeProviderToInstrument](Wiki/History/Tables/History.TradeProviderToInstrument.md) | `main.general.bronze_etoro_history_tradeprovidertoinstrument` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `(Additional columns)` cannot be |
| [History.TradonomiToLiquidityProviderContracts](Wiki/History/Tables/History.TradonomiToLiquidityProviderContracts.md) | `main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts` | Deployed (Batch 1) - 2026-05-03 |
| [History.WithdrawAction](Wiki/History/Tables/History.WithdrawAction.md) | `main.billing.bronze_etoro_history_withdrawaction` | Deployed (Batch 1) - 2026-05-03 |
| [History.WithdrawToFundingAction](Wiki/History/Tables/History.WithdrawToFundingAction.md) | `main.general.bronze_etoro_history_withdrawtofundingaction` | Deployed (Batch 1) - 2026-05-03 |
| [History.vWithdrawToFundingAction](Wiki/History/Views/History.vWithdrawToFundingAction.md) | `main.general.bronze_etoro_history_vwithdrawtofundingaction` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`general`.`bronze_etoro_history_vwithdrawtofundingaction` c |
| [Price.AccountRateSource](Wiki/Price/Tables/Price.AccountRateSource.md) | `main.bi_db.bronze_etoro_price_accountratesource` | Deployed (Batch 1) - 2026-05-03 |
| [Price.Exchange](Wiki/Price/Tables/Price.Exchange.md) | `main.bi_db.bronze_etoro_price_exchange` | Deployed (Batch 1) - 2026-05-03 |
| [Price.GetAccountRateSourceMapping](Wiki/Price/Views/Price.GetAccountRateSourceMapping.md) | `main.dealing.bronze_etoro_price_getaccountratesourcemapping` | Deployed (Batch 1) - 2026-05-03 |
| [Price.GetInstrumentRateSources](Wiki/Price/Views/Price.GetInstrumentRateSources.md) | `main.dealing.bronze_etoro_price_getinstrumentratesources` | Deployed (Batch 1) - 2026-05-03 |
| [Price.InstrumentConfiguration](Wiki/Price/Tables/Price.InstrumentConfiguration.md) | `main.dealing.bronze_etoro_price_instrumentconfiguration` | Deployed (Batch 1) - 2026-05-03 |
| [Price.LiquidityAccountToInstrument](Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md) | `main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument` | Deployed (Batch 1) - 2026-05-03 |
| [Price.PCSToLiquidityAccount](Wiki/Price/Tables/Price.PCSToLiquidityAccount.md) | `main.dealing.bronze_etoro_price_pcstoliquidityaccount` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.AdminPositionLog](Wiki/Trade/Tables/Trade.AdminPositionLog.md) | `main.bi_db.bronze_etoro_trade_adminpositionlog` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.CloseExecutionPlan](Wiki/Trade/Tables/Trade.CloseExecutionPlan.md) | `main.trading.bronze_etoro_trade_closeexecutionplan` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.CopyTradeSettlementRestrictions](Wiki/Trade/Tables/Trade.CopyTradeSettlementRestrictions.md) | `main.bi_db.bronze_etoro_trade_copytradesettlementrestrictions` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.CurrencyPrice](Wiki/Trade/Tables/Trade.CurrencyPrice.md) | `main.trading.bronze_etoro_trade_currencyprice` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.ExchangeInstrumentFeeDefinition](Wiki/Trade/Tables/Trade.ExchangeInstrumentFeeDefinition.md) | `main.trading.bronze_etoro_trade_exchangeinstrumentfeedefinition` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.FeatureThresholdValues](Wiki/Trade/Tables/Trade.FeatureThresholdValues.md) | `main.trading.bronze_etoro_trade_featurethresholdvalues` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.Fund](Wiki/Trade/Tables/Trade.Fund.md) | `main.bi_db.bronze_etoro_trade_fund` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.FuturesMetaData](Wiki/Trade/Tables/Trade.FuturesMetaData.md) | `main.trading.bronze_etoro_trade_futuresmetadata` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.GetInstrument](Wiki/Trade/Views/Trade.GetInstrument.md) | `main.trading.bronze_etoro_trade_getinstrument` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.GetLiquidityProviders](Wiki/Trade/Views/Trade.GetLiquidityProviders.md) | `main.bi_db.bronze_etoro_trade_getliquidityproviders` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.HedgeServer](Wiki/Trade/Tables/Trade.HedgeServer.md) | `main.general.bronze_etoro_trade_hedgeserver` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.IndexDividends](Wiki/Trade/Tables/Trade.IndexDividends.md) | `main.trading.bronze_etoro_trade_indexdividends` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.Instrument](Wiki/Trade/Tables/Trade.Instrument.md) | `main.trading.bronze_etoro_trade_instrument` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentCusip](Wiki/Trade/Views/Trade.InstrumentCusip.md) | `main.bi_db.bronze_etoro_trade_instrumentcusip` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentGroups](Wiki/Trade/Tables/Trade.InstrumentGroups.md) | `main.trading.bronze_etoro_trade_instrumentgroups` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentImages](Wiki/Trade/Tables/Trade.InstrumentImages.md) | `main.trading.bronze_etoro_trade_instrumentimages` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentMetaData](Wiki/Trade/Tables/Trade.InstrumentMetaData.md) | `main.trading.bronze_etoro_trade_instrumentmetadata` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentSpread](Wiki/Trade/Tables/Trade.InstrumentSpread.md) | `main.trading.bronze_etoro_trade_instrumentspread` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentToFeeConfig](Wiki/Trade/Tables/Trade.InstrumentToFeeConfig.md) | `main.trading.bronze_etoro_trade_instrumenttofeeconfig` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.InstrumentToFeeConfigV2](Wiki/Trade/Tables/Trade.InstrumentToFeeConfigV2.md) | `main.trading.bronze_etoro_trade_instrumenttofeeconfigv2` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.LiquidityAccounts](Wiki/Trade/Tables/Trade.LiquidityAccounts.md) | `main.trading.bronze_etoro_trade_liquidityaccounts` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.LiquidityProviderContracts](Wiki/Trade/Tables/Trade.LiquidityProviderContracts.md) | `main.general.bronze_etoro_trade_liquidityprovidercontracts` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.LiquidityProviderType](Wiki/Trade/Tables/Trade.LiquidityProviderType.md) | `main.bi_db.bronze_etoro_trade_liquidityprovidertype` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.LiquidityProviders](Wiki/Trade/Tables/Trade.LiquidityProviders.md) | `main.trading.bronze_etoro_trade_liquidityproviders` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.Mirror](Wiki/Trade/Tables/Trade.Mirror.md) | `main.trading.bronze_etoro_trade_mirror` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.Orders](Wiki/Trade/Tables/Trade.Orders.md) | `main.dealing.bronze_etoro_trade_orders` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.OrdersEntryTbl](Wiki/Trade/Tables/Trade.OrdersEntryTbl.md) | `main.trading.bronze_etoro_trade_ordersentrytbl` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.OrdersExitTbl](Wiki/Trade/Tables/Trade.OrdersExitTbl.md) | `main.trading.bronze_etoro_trade_ordersexittbl` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.PositionAirdropLog](Wiki/Trade/Views/Trade.PositionAirdropLog.md) | `main.trading.bronze_etoro_trade_positionairdroplog` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.Position_DataFactory](Wiki/Trade/Views/Trade.Position_DataFactory.md) | `main.trading.bronze_etoro_trade_position_datafactory` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `(Remaining columns)` cannot be  |
| [Trade.PositionsHedgeServerChangeLog](Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeLog.md) | `main.trading.bronze_etoro_trade_positionshedgeserverchangelog` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.PositionsHedgeServerChangeSummaryLog](Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md) | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.PositionsProcessedForIndexDividnds](Wiki/Trade/Tables/Trade.PositionsProcessedForIndexDividnds.md) | `main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.ProviderInstrumentToLeverage](Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md) | `main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.ProviderToInstrument](Wiki/Trade/Tables/Trade.ProviderToInstrument.md) | `main.trading.bronze_etoro_trade_providertoinstrument` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.ProviderToInstrument_Daily](Wiki/Trade/Views/Trade.ProviderToInstrument_Daily.md) | `main.trading.bronze_etoro_trade_providertoinstrument_daily` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `(all other ProviderToInstrument |
| [Trade.Spread](Wiki/Trade/Tables/Trade.Spread.md) | `main.trading.bronze_etoro_trade_spread` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.SpreadToGroup](Wiki/Trade/Tables/Trade.SpreadToGroup.md) | `main.trading.bronze_etoro_trade_spreadtogroup` | Deployed (Batch 1) - 2026-05-03 |
| [Trade.TerminalIDToCorporateAction](Wiki/Trade/Tables/Trade.TerminalIDToCorporateAction.md) | `main.trading.bronze_etoro_trade_terminalidtocorporateaction` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.CustomerToFunding](Wiki/Billing/Tables/Billing.CustomerToFunding.md) | `main.billing.bronze_etoro_billing_customertofunding` | Failed (Batch 1) - alter file not found |
| [Billing.MerchantAccountRouting](Wiki/Billing/Tables/Billing.MerchantAccountRouting.md) | `main.bi_db.bronze_etoro_billing_merchantaccountrouting` | Failed (Batch 1) - alter file not found |
| [Billing.ProtocolMIDSettings](Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md) | `main.billing.bronze_etoro_billing_protocolmidsettings` | Failed (Batch 1) - alter file not found |
| [Billing.ScheduledTaskState](Wiki/Billing/Tables/Billing.ScheduledTaskState.md) | `main.billing.bronze_etoro_billing_scheduledtaskstate` | Failed (Batch 1) - alter file not found |
| [Dictionary.DowntimeCloseStatus](Wiki/Dictionary/Tables/Dictionary.DowntimeCloseStatus.md) | `main.general.bronze_etoro_dictionary_downtimeclosestatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.DowntimeSeverity](Wiki/Dictionary/Tables/Dictionary.DowntimeSeverity.md) | `main.general.bronze_etoro_dictionary_downtimeseverity` | Failed (Batch 1) - alter file not found |
| [Dictionary.DowntimeStatus](Wiki/Dictionary/Tables/Dictionary.DowntimeStatus.md) | `main.general.bronze_etoro_dictionary_downtimestatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.DowntimeSystem](Wiki/Dictionary/Tables/Dictionary.DowntimeSystem.md) | `main.general.bronze_etoro_dictionary_downtimesystem` | Failed (Batch 1) - alter file not found |
| [Dictionary.DowntimeSystemToDowntype](Wiki/Dictionary/Tables/Dictionary.DowntimeSystemToDowntype.md) | `main.general.bronze_etoro_dictionary_downtimesystemtodowntype` | Failed (Batch 1) - alter file not found |
| [Dictionary.Downtype](Wiki/Dictionary/Tables/Dictionary.Downtype.md) | `main.general.bronze_etoro_dictionary_downtype` | Failed (Batch 1) - alter file not found |
| [Dictionary.Duration](Wiki/Dictionary/Tables/Dictionary.Duration.md) | `main.general.bronze_etoro_dictionary_duration` | Failed (Batch 1) - alter file not found |
| [Dictionary.EIDStatus](Wiki/Dictionary/Tables/Dictionary.EIDStatus.md) | `main.general.bronze_etoro_dictionary_eidstatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.ElectronicIdentityCheck](Wiki/Dictionary/Tables/Dictionary.ElectronicIdentityCheck.md) | `main.general.bronze_etoro_dictionary_electronicidentitycheck` | Failed (Batch 1) - alter file not found |
| [Dictionary.ElectronicIdentityProvider](Wiki/Dictionary/Tables/Dictionary.ElectronicIdentityProvider.md) | `main.general.bronze_etoro_dictionary_electronicidentityprovider` | Failed (Batch 1) - alter file not found |
| [Dictionary.ErrorMessage](Wiki/Dictionary/Tables/Dictionary.ErrorMessage.md) | `main.general.bronze_etoro_dictionary_errormessage` | Failed (Batch 1) - alter file not found |
| [Dictionary.EventType](Wiki/Dictionary/Tables/Dictionary.EventType.md) | `main.general.bronze_etoro_dictionary_eventtype` | Failed (Batch 1) - alter file not found |
| [Dictionary.ExchangeInfo](Wiki/Dictionary/Tables/Dictionary.ExchangeInfo.md) | `main.general.bronze_etoro_dictionary_exchangeinfo` | Failed (Batch 1) - alter file not found |
| [Dictionary.ExecuteEntryMethod](Wiki/Dictionary/Tables/Dictionary.ExecuteEntryMethod.md) | `main.general.bronze_etoro_dictionary_executeentrymethod` | Failed (Batch 1) - alter file not found |
| [Dictionary.FailType](Wiki/Dictionary/Tables/Dictionary.FailType.md) | `main.general.bronze_etoro_dictionary_failtype` | Failed (Batch 1) - alter file not found |
| [Dictionary.Roles](Wiki/Dictionary/Tables/Dictionary.Roles.md) | `main.general.bronze_etoro_dictionary_roles` | Failed (Batch 1) - alter file not found |
| [Dictionary.SalesStatus](Wiki/Dictionary/Tables/Dictionary.SalesStatus.md) | `main.general.bronze_etoro_dictionary_salesstatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.ScheduledJobStatus](Wiki/Dictionary/Tables/Dictionary.ScheduledJobStatus.md) | `main.general.bronze_etoro_dictionary_scheduledjobstatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.ScheduledJobType](Wiki/Dictionary/Tables/Dictionary.ScheduledJobType.md) | `main.general.bronze_etoro_dictionary_scheduledjobtype` | Failed (Batch 1) - alter file not found |
| [Dictionary.ScheduledTaskName](Wiki/Dictionary/Tables/Dictionary.ScheduledTaskName.md) | `main.general.bronze_etoro_dictionary_scheduledtaskname` | Failed (Batch 1) - alter file not found |
| [Dictionary.ScheduledTaskState](Wiki/Dictionary/Tables/Dictionary.ScheduledTaskState.md) | `main.general.bronze_etoro_dictionary_scheduledtaskstate` | Failed (Batch 1) - alter file not found |
| [Dictionary.ServerType](Wiki/Dictionary/Tables/Dictionary.ServerType.md) | `main.general.bronze_etoro_dictionary_servertype` | Failed (Batch 1) - alter file not found |
| [Dictionary.SeverityType](Wiki/Dictionary/Tables/Dictionary.SeverityType.md) | `main.general.bronze_etoro_dictionary_severitytype` | Failed (Batch 1) - alter file not found |
| [Dictionary.SpreadType](Wiki/Dictionary/Tables/Dictionary.SpreadType.md) | `main.general.bronze_etoro_dictionary_spreadtype` | Failed (Batch 1) - alter file not found |
| [Dictionary.State](Wiki/Dictionary/Tables/Dictionary.State.md) | `main.general.bronze_etoro_dictionary_state` | Failed (Batch 1) - alter file not found |
| [Dictionary.StockError](Wiki/Dictionary/Tables/Dictionary.StockError.md) | `main.general.bronze_etoro_dictionary_stockerror` | Failed (Batch 1) - alter file not found |
| [Dictionary.StockHedgeSource](Wiki/Dictionary/Tables/Dictionary.StockHedgeSource.md) | `main.general.bronze_etoro_dictionary_stockhedgesource` | Failed (Batch 1) - alter file not found |
| [Hedge.GetHedgeServerAccountMapping](Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md) | `main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping` | Failed (Batch 1) - alter file not found |
| [Hedge.ViewExecutionLog_isnull](Wiki/Hedge/Views/Hedge.ViewExecutionLog_isnull.md) | `main.general.bronze_etoro_hedge_viewexecutionlog_isnull` | Failed (Batch 1) - alter file not found |
| [History.PositionChangeLog](Wiki/History/Views/History.PositionChangeLog.md) | `main.trading.bronze_etoro_history_positionchangelog` | Failed (Batch 1) - alter file not found |
| [History.Position_DataFactory](Wiki/History/Views/History.Position_DataFactory.md) | `main.trading.bronze_etoro_history_position_datafactory` | Failed (Batch 1) - alter file not found |
| [Trade.InstrumentMetaData_Daily](Wiki/Trade/Views/Trade.InstrumentMetaData_Daily.md) | `main.trading.bronze_etoro_trade_instrumentmetadata_daily` | Failed (Batch 1) - alter file not found |
| [Trade.ManageBSL](Wiki/Trade/Tables/Trade.ManageBSL.md) | `main.general.bronze_etoro_trade_managebsl` | Failed (Batch 1) - alter file not found |
