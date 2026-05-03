# Lineage: eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239

## Source Objects

| Source Object | Type | Schema | Database | Relationship |
|---|---|---|---|---|
| FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Table | Tribe | FiatDwhDB (prod-banking) | Primary production source — passthrough via Generic Pipeline #538 |
| FiatDwhDB.Tribe.SettlementsTransactions-333243 | Table | Tribe | FiatDwhDB (prod-banking) | Parent container table (joined by SP_eMoney_Reconciliation_ETLs on @Id) |
| FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | Table | Tribe | FiatDwhDB (prod-banking) | Sibling child table (LEFT JOIN by SP_eMoney_Reconciliation_ETLs on @Id) |
| FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 | Table | Tribe | FiatDwhDB (prod-banking) | Sibling child table (LEFT JOIN by SP_eMoney_Reconciliation_ETLs on @Id) |

## Column Lineage

| Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|
| @Created | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | @Created | Passthrough | Tier 1 |
| @Id | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | @Id | Passthrough | Tier 1 |
| @SettlementsTransactions@Id-333243 | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | @SettlementsTransactions@Id-333243 | Passthrough | Tier 1 |
| FileDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FileDate | Passthrough | Tier 3 |
| WorkDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | WorkDate | Passthrough | Tier 3 |
| @WorkDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | @WorkDate | Passthrough | Tier 3 |
| IssuerIdentificationNumber | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | IssuerIdentificationNumber | Passthrough | Tier 3 |
| ProgramName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ProgramName | Passthrough | Tier 3 |
| ProgramId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ProgramId | Passthrough | Tier 3 |
| ProductName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ProductName | Passthrough | Tier 3 |
| ProductId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ProductId | Passthrough | Tier 3 |
| SubProductId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SubProductId | Passthrough | Tier 3 |
| HolderId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | HolderId | Passthrough | Tier 3 |
| AccountId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | AccountId | Passthrough | Tier 3 |
| BankAccountId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BankAccountId | Passthrough | Tier 3 |
| CardNumber | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardNumber | Passthrough | Tier 3 |
| CardNumberId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardNumberId | Passthrough | Tier 3 |
| CardRequestId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardRequestId | Passthrough | Tier 3 |
| MtiCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MtiCode | Passthrough | Tier 3 |
| MessageReasonCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MessageReasonCode | Passthrough | Tier 3 |
| Bin | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Bin | Passthrough | Tier 3 |
| TransactionCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionCode | Passthrough | Tier 3 |
| TransactionCodeDescription | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionCodeDescription | Passthrough | Tier 3 |
| AuthorizationCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | AuthorizationCode | Passthrough | Tier 3 |
| TransactionDateTime | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionDateTime | Passthrough | Tier 3 |
| TransactionAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionAmount | Passthrough | Tier 3 |
| TransactionCurrencyCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionCurrencyCode | Passthrough | Tier 3 |
| TransactionCurrencyAlpha | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionCurrencyAlpha | Passthrough | Tier 3 |
| TransLink | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransLink | Passthrough | Tier 3 |
| TraceId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TraceId | Passthrough | Tier 3 |
| TransactionCodeIdentifier | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionCodeIdentifier | Passthrough | Tier 3 |
| HolderAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | HolderAmount | Passthrough | Tier 3 |
| HolderCurrencyCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | HolderCurrencyCode | Passthrough | Tier 3 |
| HolderCurrencyAlpha | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | HolderCurrencyAlpha | Passthrough | Tier 3 |
| FxRate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FxRate | Passthrough | Tier 3 |
| FeeGroupId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FeeGroupId | Passthrough | Tier 3 |
| FeeGroupName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FeeGroupName | Passthrough | Tier 3 |
| FxFeeName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FxFeeName | Passthrough | Tier 3 |
| FxFeeCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FxFeeCode | Passthrough | Tier 3 |
| FxFeeAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FxFeeAmount | Passthrough | Tier 3 |
| FxFeeCurrency | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FxFeeCurrency | Passthrough | Tier 3 |
| FxFeeReason | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FxFeeReason | Passthrough | Tier 3 |
| F0FeeName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | F0FeeName | Passthrough | Tier 3 |
| F0FeeCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | F0FeeCode | Passthrough | Tier 3 |
| F0FeeAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | F0FeeAmount | Passthrough | Tier 3 |
| F0FeeCurrency | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | F0FeeCurrency | Passthrough | Tier 3 |
| F0FeeReason | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | F0FeeReason | Passthrough | Tier 3 |
| BillRateAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BillRateAmount | Passthrough | Tier 3 |
| BillingDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BillingDate | Passthrough | Tier 3 |
| BillingAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BillingAmount | Passthrough | Tier 3 |
| BillingCurrencyCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BillingCurrencyCode | Passthrough | Tier 3 |
| BillingCurrencyAlpha | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BillingCurrencyAlpha | Passthrough | Tier 3 |
| ReconciliationDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ReconciliationDate | Passthrough | Tier 3 |
| SettlementDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SettlementDate | Passthrough | Tier 3 |
| SettlementAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SettlementAmount | Passthrough | Tier 3 |
| SettlementCurrencyCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SettlementCurrencyCode | Passthrough | Tier 3 |
| SettlementCurrencyAlpha | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SettlementCurrencyAlpha | Passthrough | Tier 3 |
| SettlementConversionRate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SettlementConversionRate | Passthrough | Tier 3 |
| MerchantNumber | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantNumber | Passthrough | Tier 3 |
| Merchant | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Merchant | Passthrough | Tier 3 |
| MerchantName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantName | Passthrough | Tier 3 |
| MerchantAddress | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantAddress | Passthrough | Tier 3 |
| MerchantCity | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantCity | Passthrough | Tier 3 |
| MerchantPostcode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantPostcode | Passthrough | Tier 3 |
| MerchantCountryCodeAlpha | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantCountryCodeAlpha | Passthrough | Tier 3 |
| MerchantCountryName | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | MerchantCountryName | Passthrough | Tier 3 |
| Mcc | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Mcc | Passthrough | Tier 3 |
| CardPresent | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardPresent | Passthrough | Tier 3 |
| CardInputMode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardInputMode | Passthrough | Tier 3 |
| CardholderAuthenticationMethod | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardholderAuthenticationMethod | Passthrough | Tier 3 |
| PosDataDe22 | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | PosDataDe22 | Passthrough | Tier 3 |
| PosDataDe61 | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | PosDataDe61 | Passthrough | Tier 3 |
| AcquirerId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | AcquirerId | Passthrough | Tier 3 |
| AcquirerReferenceNumber | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | AcquirerReferenceNumber | Passthrough | Tier 3 |
| TransactionId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionId | Passthrough | Tier 3 |
| InterchangeFeeAmount | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | InterchangeFeeAmount | Passthrough | Tier 3 |
| InterchangeFeeCurrency | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | InterchangeFeeCurrency | Passthrough | Tier 3 |
| InterchangeFeeDirection | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | InterchangeFeeDirection | Passthrough | Tier 3 |
| InterchangeRateDesignator | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | InterchangeRateDesignator | Passthrough | Tier 3 |
| CycleNumber | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CycleNumber | Passthrough | Tier 3 |
| CycleFileId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CycleFileId | Passthrough | Tier 3 |
| TransactionClass | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionClass | Passthrough | Tier 3 |
| Action | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Action | Passthrough | Tier 3 |
| Network | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Network | Passthrough | Tier 3 |
| TransactionDescription | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionDescription | Passthrough | Tier 3 |
| EntryModeCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | EntryModeCode | Passthrough | Tier 3 |
| EntryModeCodeDescription | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | EntryModeCodeDescription | Passthrough | Tier 3 |
| ECIIndicator | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ECIIndicator | Passthrough | Tier 3 |
| Suspicious | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Suspicious | Passthrough | Tier 3 |
| RiskRuleCodes | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | RiskRuleCodes | Passthrough | Tier 3 |
| FunctionCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FunctionCode | Passthrough | Tier 3 |
| LoadType | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | LoadType | Passthrough | Tier 3 |
| LoadSource | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | LoadSource | Passthrough | Tier 3 |
| SettlementFlag | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | SettlementFlag | Passthrough | Tier 3 |
| TransactionCodeQualifier | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TransactionCodeQualifier | Passthrough | Tier 3 |
| BusinessFormatCode | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | BusinessFormatCode | Passthrough | Tier 3 |
| CardType | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | CardType | Passthrough | Tier 3 |
| ParentTransactionId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ParentTransactionId | Passthrough | Tier 3 |
| DisputeId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | DisputeId | Passthrough | Tier 3 |
| ExternalDisputeId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ExternalDisputeId | Passthrough | Tier 3 |
| ActualAuthorizationId | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ActualAuthorizationId | Passthrough | Tier 3 |
| FirstAuthorizationDate | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | FirstAuthorizationDate | Passthrough | Tier 3 |
| InterchangeFeeAmountRounded | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | InterchangeFeeAmountRounded | Passthrough | Tier 3 |
| ReferenceNumber | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | ReferenceNumber | Passthrough | Tier 3 |
| etr_y | Generic Pipeline | Created | YEAR extraction | Tier 2 |
| etr_ym | Generic Pipeline | Created | Year-month extraction | Tier 2 |
| etr_ymd | Generic Pipeline | Created | Year-month-day extraction | Tier 2 |
| SynapseUpdateDate | Generic Pipeline | N/A | GETDATE() at ingestion | Tier 2 |
| partition_date | Generic Pipeline | Created | CAST AS DATE | Tier 2 |
| PosDataExtendedDe61 | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | PosDataExtendedDe61 | Passthrough | Tier 3 |
| Created | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | Created | Passthrough | Tier 1 |
| TokenizedRequest | FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239 | TokenizedRequest | Passthrough | Tier 3 |
