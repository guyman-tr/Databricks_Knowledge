# Lineage: eMoney_Tribe.AccountsActivities_AccountActivity-833937

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Evidence |
|---|---|---|---|---|---|---|
| 1 | eMoney Platform (GPS/Modulr) AccountActivity API | External Platform | N/A | FiatDwhDB | Raw data source | Parquet files in Azure Data Lake, loaded by SP_eMoney_FiatDwhETL |
| 2 | AccountsActivities_AccountActivity-833937_tmp | Staging Table | eMoney_Tribe_tmp | Synapse | COPY INTO target | SP_eMoney_FiatDwhETL loads Parquet → _tmp → main table |
| 3 | AccountsActivities_862157 | Parent Table | eMoney_Tribe | Synapse | INNER JOIN on @Id | SP_eMoney_Reconciliation_ETLs joins parent-child |
| 4 | AccountsActivities_RiskActions-322546 | Sibling Table | eMoney_Tribe | Synapse | LEFT JOIN on @Id | SP_eMoney_Reconciliation_ETLs joins risk actions |
| 5 | AccountsActivities_SecurityChecks-471048 | Sibling Table | eMoney_Tribe | Synapse | LEFT JOIN on @Id | SP_eMoney_Reconciliation_ETLs joins security checks |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Created | eMoney Platform | @Created | None (Parquet passthrough) | Tier 3 |
| 2 | @Id | eMoney Platform | @Id | None (Parquet passthrough) | Tier 3 |
| 3 | @AccountsActivities@Id-862157 | eMoney Platform | @AccountsActivities@Id-862157 | None (Parquet passthrough) | Tier 3 |
| 4 | FileDate | eMoney Platform | FileDate | None (Parquet passthrough) | Tier 3 |
| 5 | WorkDate | eMoney Platform | WorkDate | None (Parquet passthrough) | Tier 3 |
| 6 | @WorkDate | eMoney Platform | @WorkDate | None (Parquet passthrough) | Tier 3 |
| 7 | IssuerIdentificationNumber | eMoney Platform | IssuerIdentificationNumber | None (Parquet passthrough) | Tier 3 |
| 8 | ProgramName | eMoney Platform | ProgramName | None (Parquet passthrough) | Tier 3 |
| 9 | ProgramId | eMoney Platform | ProgramId | None (Parquet passthrough) | Tier 3 |
| 10 | ProductName | eMoney Platform | ProductName | None (Parquet passthrough) | Tier 3 |
| 11 | ProductId | eMoney Platform | ProductId | None (Parquet passthrough) | Tier 3 |
| 12 | SubProductId | eMoney Platform | SubProductId | None (Parquet passthrough) | Tier 3 |
| 13 | HolderId | eMoney Platform | HolderId | None (Parquet passthrough) | Tier 3 |
| 14 | AccountId | eMoney Platform | AccountId | None (Parquet passthrough) | Tier 3 |
| 15 | BankAccountId | eMoney Platform | BankAccountId | None (Parquet passthrough) | Tier 3 |
| 16 | ExternalBankAccountId | eMoney Platform | ExternalBankAccountId | None (Parquet passthrough) | Tier 3 |
| 17 | BankAccountNumber | eMoney Platform | BankAccountNumber | None (Parquet passthrough) | Tier 3 |
| 18 | BankAccountSortCode | eMoney Platform | BankAccountSortCode | None (Parquet passthrough) | Tier 3 |
| 19 | BankAccountIban | eMoney Platform | BankAccountIban | None (Parquet passthrough) | Tier 3 |
| 20 | BankAccountBic | eMoney Platform | BankAccountBic | None (Parquet passthrough) | Tier 3 |
| 21 | CardNumber | eMoney Platform | CardNumber | None (Parquet passthrough) | Tier 3 |
| 22 | CardNumberId | eMoney Platform | CardNumberId | None (Parquet passthrough) | Tier 3 |
| 23 | CardRequestId | eMoney Platform | CardRequestId | None (Parquet passthrough) | Tier 3 |
| 24 | Bin | eMoney Platform | Bin | None (Parquet passthrough) | Tier 3 |
| 25 | TransactionCode | eMoney Platform | TransactionCode | None (Parquet passthrough) | Tier 3 |
| 26 | TransactionCodeDescription | eMoney Platform | TransactionCodeDescription | None (Parquet passthrough) | Tier 3 |
| 27 | TransactionDateTime | eMoney Platform | TransactionDateTime | None (Parquet passthrough) | Tier 3 |
| 28 | TransactionAmount | eMoney Platform | TransactionAmount | None (Parquet passthrough) | Tier 3 |
| 29 | TransactionCurrencyCode | eMoney Platform | TransactionCurrencyCode | None (Parquet passthrough) | Tier 3 |
| 30 | TransactionCurrencyAlpha | eMoney Platform | TransactionCurrencyAlpha | None (Parquet passthrough) | Tier 3 |
| 31 | TransLink | eMoney Platform | TransLink | None (Parquet passthrough) | Tier 3 |
| 32 | TraceId | eMoney Platform | TraceId | None (Parquet passthrough) | Tier 3 |
| 33 | TransactionCodeIdentifier | eMoney Platform | TransactionCodeIdentifier | None (Parquet passthrough) | Tier 3 |
| 34 | HolderAmount | eMoney Platform | HolderAmount | None (Parquet passthrough) | Tier 3 |
| 35 | HolderCurrencyCode | eMoney Platform | HolderCurrencyCode | None (Parquet passthrough) | Tier 3 |
| 36 | HolderCurrencyAlpha | eMoney Platform | HolderCurrencyAlpha | None (Parquet passthrough) | Tier 3 |
| 37 | FxRate | eMoney Platform | FxRate | None (Parquet passthrough) | Tier 3 |
| 38 | FeeGroupId | eMoney Platform | FeeGroupId | None (Parquet passthrough) | Tier 3 |
| 39 | FeeGroupName | eMoney Platform | FeeGroupName | None (Parquet passthrough) | Tier 3 |
| 40 | FxFeeName | eMoney Platform | FxFeeName | None (Parquet passthrough) | Tier 3 |
| 41 | FxFeeAmount | eMoney Platform | FxFeeAmount | None (Parquet passthrough) | Tier 3 |
| 42 | FxFeeCurrency | eMoney Platform | FxFeeCurrency | None (Parquet passthrough) | Tier 3 |
| 43 | FxFeeReason | eMoney Platform | FxFeeReason | None (Parquet passthrough) | Tier 3 |
| 44 | F0FeeName | eMoney Platform | F0FeeName | None (Parquet passthrough) | Tier 3 |
| 45 | F0FeeAmount | eMoney Platform | F0FeeAmount | None (Parquet passthrough) | Tier 3 |
| 46 | F0FeeCurrency | eMoney Platform | F0FeeCurrency | None (Parquet passthrough) | Tier 3 |
| 47 | F0FeeReason | eMoney Platform | F0FeeReason | None (Parquet passthrough) | Tier 3 |
| 48 | BillRateAmount | eMoney Platform | BillRateAmount | None (Parquet passthrough) | Tier 3 |
| 49 | BillingDate | eMoney Platform | BillingDate | None (Parquet passthrough) | Tier 3 |
| 50 | BillingAmount | eMoney Platform | BillingAmount | None (Parquet passthrough) | Tier 3 |
| 51 | BillingCurrencyCode | eMoney Platform | BillingCurrencyCode | None (Parquet passthrough) | Tier 3 |
| 52 | BillingCurrencyAlpha | eMoney Platform | BillingCurrencyAlpha | None (Parquet passthrough) | Tier 3 |
| 53 | SettlementAmount | eMoney Platform | SettlementAmount | None (Parquet passthrough) | Tier 3 |
| 54 | SettlementCurrencyCode | eMoney Platform | SettlementCurrencyCode | None (Parquet passthrough) | Tier 3 |
| 55 | SettlementCurrencyAlpha | eMoney Platform | SettlementCurrencyAlpha | None (Parquet passthrough) | Tier 3 |
| 56 | SettlementConversionRate | eMoney Platform | SettlementConversionRate | None (Parquet passthrough) | Tier 3 |
| 57 | CardPresent | eMoney Platform | CardPresent | None (Parquet passthrough) | Tier 3 |
| 58 | TransactionId | eMoney Platform | TransactionId | None (Parquet passthrough) | Tier 3 |
| 59 | TransactionClass | eMoney Platform | TransactionClass | None (Parquet passthrough) | Tier 3 |
| 60 | Action | eMoney Platform | Action | None (Parquet passthrough) | Tier 3 |
| 61 | Network | eMoney Platform | Network | None (Parquet passthrough) | Tier 3 |
| 62 | TransactionDescription | eMoney Platform | TransactionDescription | None (Parquet passthrough) | Tier 3 |
| 63 | EntryModeCode | eMoney Platform | EntryModeCode | None (Parquet passthrough) | Tier 3 |
| 64 | EntryModeCodeDescription | eMoney Platform | EntryModeCodeDescription | None (Parquet passthrough) | Tier 3 |
| 65 | ReferenceNumber | eMoney Platform | ReferenceNumber | None (Parquet passthrough) | Tier 3 |
| 66 | CountryIson | eMoney Platform | CountryIson | None (Parquet passthrough) | Tier 3 |
| 67 | LoadType | eMoney Platform | LoadType | None (Parquet passthrough) | Tier 3 |
| 68 | LoadSource | eMoney Platform | LoadSource | None (Parquet passthrough) | Tier 3 |
| 69 | EpmMethodId | eMoney Platform | EpmMethodId | None (Parquet passthrough) | Tier 3 |
| 70 | EpmTransactionId | eMoney Platform | EpmTransactionId | None (Parquet passthrough) | Tier 3 |
| 71 | ExternalEpmTransactionId | eMoney Platform | ExternalEpmTransactionId | None (Parquet passthrough) | Tier 3 |
| 72 | EpmTransactionType | eMoney Platform | EpmTransactionType | None (Parquet passthrough) | Tier 3 |
| 73 | EpmTransactionStatusCode | eMoney Platform | EpmTransactionStatusCode | None (Parquet passthrough) | Tier 3 |
| 74 | EpmMandateId | eMoney Platform | EpmMandateId | None (Parquet passthrough) | Tier 3 |
| 75 | Reference | eMoney Platform | Reference | None (Parquet passthrough) | Tier 3 |
| 76 | TransactionIdentifier | eMoney Platform | TransactionIdentifier | None (Parquet passthrough) | Tier 3 |
| 77 | EndToEndIdentifier | eMoney Platform | EndToEndIdentifier | None (Parquet passthrough) | Tier 3 |
| 78 | Suspicious | eMoney Platform | Suspicious | None (Parquet passthrough) | Tier 3 |
| 79 | RiskRuleCodes | eMoney Platform | RiskRuleCodes | None (Parquet passthrough) | Tier 3 |
| 80 | BalanceAdjustmentType | eMoney Platform | BalanceAdjustmentType | None (Parquet passthrough) | Tier 3 |
| 81 | EpmTransactionStatus | eMoney Platform | EpmTransactionStatus | None (Parquet passthrough) | Tier 3 |
| 82 | EpmTransactionReasonDescription | eMoney Platform | EpmTransactionReasonDescription | None (Parquet passthrough) | Tier 3 |
| 83 | EpmTransactionBankProviderReasonCode | eMoney Platform | EpmTransactionBankProviderReasonCode | None (Parquet passthrough) | Tier 3 |
| 84 | ParentTransactionId | eMoney Platform | ParentTransactionId | None (Parquet passthrough) | Tier 3 |
| 85 | DisputeId | eMoney Platform | DisputeId | None (Parquet passthrough) | Tier 3 |
| 86 | ExternalDisputeId | eMoney Platform | ExternalDisputeId | None (Parquet passthrough) | Tier 3 |
| 87 | ExternalPaymentScheme | eMoney Platform | ExternalPaymentScheme | None (Parquet passthrough) | Tier 3 |
| 88 | ExternalIbanCountry | eMoney Platform | ExternalIbanCountry | None (Parquet passthrough) | Tier 3 |
| 89 | InternalIbanCountry | eMoney Platform | InternalIbanCountry | None (Parquet passthrough) | Tier 3 |
| 90 | ExternalIban | eMoney Platform | ExternalIban | None (Parquet passthrough) | Tier 3 |
| 91 | ExternalBban | eMoney Platform | ExternalBban | None (Parquet passthrough) | Tier 3 |
| 92 | ExternalAccountName | eMoney Platform | ExternalAccountName | None (Parquet passthrough) | Tier 3 |
| 93 | ExternalAccountNumber | eMoney Platform | ExternalAccountNumber | None (Parquet passthrough) | Tier 3 |
| 94 | ExternalSortCode | eMoney Platform | ExternalSortCode | None (Parquet passthrough) | Tier 3 |
| 95 | ExternalBIC | eMoney Platform | ExternalBIC | None (Parquet passthrough) | Tier 3 |
| 96 | OriginatorId | eMoney Platform | OriginatorId | None (Parquet passthrough) | Tier 3 |
| 97 | OriginatorName | eMoney Platform | OriginatorName | None (Parquet passthrough) | Tier 3 |
| 98 | OriginatorServiceUserNumber | eMoney Platform | OriginatorServiceUserNumber | None (Parquet passthrough) | Tier 3 |
| 99 | TransactionReferenceNumber | eMoney Platform | TransactionReferenceNumber | None (Parquet passthrough) | Tier 3 |
| 100 | ActualEndToEndIdentifier | eMoney Platform | ActualEndToEndIdentifier | None (Parquet passthrough) | Tier 3 |
| 101 | etr_y | Data Lake Export | etr_y | Partition year from data lake bronze export | Tier 3 |
| 102 | etr_ym | Data Lake Export | etr_ym | Partition year-month from data lake bronze export | Tier 3 |
| 103 | etr_ymd | Data Lake Export | etr_ymd | Partition year-month-day from data lake bronze export | Tier 3 |
| 104 | SynapseUpdateDate | ETL Pipeline | SynapseUpdateDate | Synapse load timestamp | Tier 3 |
| 105 | partition_date | ETL Pipeline | partition_date | Synapse partition date for incremental loading | Tier 3 |
| 106 | Created | eMoney Platform | Created | None (Parquet passthrough) | Tier 3 |
| 107 | ProductCode | eMoney Platform | ProductCode | None (Parquet passthrough) | Tier 3 |
| 108 | MasterAccountId | eMoney Platform | MasterAccountId | None (Parquet passthrough) | Tier 3 |
| 109 | MasterAccountName | eMoney Platform | MasterAccountName | None (Parquet passthrough) | Tier 3 |
| 110 | MasterAccountIban | eMoney Platform | MasterAccountIban | None (Parquet passthrough) | Tier 3 |
| 111 | RequestReferenceId | eMoney Platform | RequestReferenceId | None (Parquet passthrough) | Tier 3 |
| 112 | ExternalEndToEndIdentifier | eMoney Platform | ExternalEndToEndIdentifier | None (Parquet passthrough) | Tier 3 |
| 113 | BankAccountBankStateBranch | eMoney Platform | BankAccountBankStateBranch | None (Parquet passthrough) | Tier 3 |
| 114 | ExternalBankStateBranch | eMoney Platform | ExternalBankStateBranch | None (Parquet passthrough) | Tier 3 |
| 115 | BankAccountBankBranchCode | eMoney Platform | BankAccountBankBranchCode | None (Parquet passthrough) | Tier 3 |
| 116 | ExternalBankBranchCode | eMoney Platform | ExternalBankBranchCode | None (Parquet passthrough) | Tier 3 |
