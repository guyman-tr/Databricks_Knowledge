# Lineage: eMoney_Tribe.Authorizes_Authorize-312243

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | Authorizes_Authorize-312243 | Table (raw) | Tribe | FiatDwhDB (prod-banking) | Direct Bronze ingest via Generic Pipeline |
| 2 | Authorizes-837045 | Table (raw) | eMoney_Tribe | Synapse | Parent table — INNER JOIN on @Id in SP_eMoney_Reconciliation_ETLs |
| 3 | Authorizes_RiskActions-796100 | Table (raw) | eMoney_Tribe | Synapse | Sibling — LEFT JOIN on @Id for risk action flags |
| 4 | Authorizes_SecurityChecks-30662 | Table (raw) | eMoney_Tribe | Synapse | Sibling — LEFT JOIN on @Id for security check flags |
| 5 | ETL_Authorize | Table (reconciliation) | eMoney_dbo | Synapse | Downstream — receives columns via SP_eMoney_Reconciliation_ETLs |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Created | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | @Created | Passthrough (Generic Pipeline Bronze ingest) | Tier 3 |
| 2 | @Id | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | @Id | Passthrough | Tier 3 |
| 3 | @Authorizes@Id-837045 | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | @Authorizes@Id-837045 | Passthrough — FK to parent Authorizes-837045 | Tier 3 |
| 4 | FileDate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | FileDate | Passthrough | Tier 3 |
| 5 | WorkDate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | WorkDate | Passthrough (varchar representation) | Tier 3 |
| 6 | @WorkDate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | @WorkDate | Passthrough (datetime2 representation) | Tier 3 |
| 7 | IssuerIdentificationNumber | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | IssuerIdentificationNumber | Passthrough | Tier 3 |
| 8 | ProgramName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ProgramName | Passthrough | Tier 3 |
| 9 | ProgramId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ProgramId | Passthrough | Tier 3 |
| 10 | ProductName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ProductName | Passthrough | Tier 3 |
| 11 | ProductId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ProductId | Passthrough | Tier 3 |
| 12 | SubProductId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | SubProductId | Passthrough | Tier 3 |
| 13 | HolderId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | HolderId | Passthrough | Tier 3 |
| 14 | AccountId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | AccountId | Passthrough | Tier 3 |
| 15 | CardLimitsGroupName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CardLimitsGroupName | Passthrough | Tier 3 |
| 16 | CardLimitsGroupId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CardLimitsGroupId | Passthrough | Tier 3 |
| 17 | AccountLimitsGroupName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | AccountLimitsGroupName | Passthrough | Tier 3 |
| 18 | AccountLimitsGroupId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | AccountLimitsGroupId | Passthrough | Tier 3 |
| 19 | HolderLimitsGroupName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | HolderLimitsGroupName | Passthrough | Tier 3 |
| 20 | HolderLimitsGroupId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | HolderLimitsGroupId | Passthrough | Tier 3 |
| 21 | FeeGroupName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | FeeGroupName | Passthrough | Tier 3 |
| 22 | FeeGroupId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | FeeGroupId | Passthrough | Tier 3 |
| 23 | CardNumber | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CardNumber | Passthrough (masked) | Tier 3 |
| 24 | CardNumberId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CardNumberId | Passthrough | Tier 3 |
| 25 | CardRequestId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CardRequestId | Passthrough | Tier 3 |
| 26 | MtiCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | MtiCode | Passthrough | Tier 3 |
| 27 | ResponseCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ResponseCode | Passthrough | Tier 3 |
| 28 | ResponseCodeDescription | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ResponseCodeDescription | Passthrough | Tier 3 |
| 29 | ResponseDeclineDescription | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ResponseDeclineDescription | Passthrough | Tier 3 |
| 30 | TransactionCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionCode | Passthrough | Tier 3 |
| 31 | TransactionCodeDescription | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionCodeDescription | Passthrough | Tier 3 |
| 32 | Bin | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Bin | Passthrough | Tier 3 |
| 33 | AuthorizationCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | AuthorizationCode | Passthrough | Tier 3 |
| 34 | TransactionDateTime | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionDateTime | Passthrough | Tier 3 |
| 35 | TransactionAmount | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionAmount | Passthrough | Tier 3 |
| 36 | TransactionCurrencyCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionCurrencyCode | Passthrough | Tier 3 |
| 37 | TransactionCurrencyAlpha | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionCurrencyAlpha | Passthrough | Tier 3 |
| 38 | TransactionCountryCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransactionCountryCode | Passthrough | Tier 3 |
| 39 | TransLink | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TransLink | Passthrough | Tier 3 |
| 40 | Stan | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Stan | Passthrough | Tier 3 |
| 41 | TribeTransactionReference | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TribeTransactionReference | Passthrough | Tier 3 |
| 42 | FxRate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | FxRate | Passthrough | Tier 3 |
| 43 | CumulativePaddingAmount | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CumulativePaddingAmount | Passthrough | Tier 3 |
| 44 | AppliedPaddingAmount | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | AppliedPaddingAmount | Passthrough | Tier 3 |
| 45 | MccPaddingReason | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | MccPaddingReason | Passthrough | Tier 3 |
| 46 | BillRateAmount | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | BillRateAmount | Passthrough | Tier 3 |
| 47 | BillingDate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | BillingDate | Passthrough | Tier 3 |
| 48 | BillingAmount | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | BillingAmount | Passthrough | Tier 3 |
| 49 | BillingCurrencyCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | BillingCurrencyCode | Passthrough | Tier 3 |
| 50 | BillingCurrencyAlpha | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | BillingCurrencyAlpha | Passthrough | Tier 3 |
| 51 | SettlementAmount | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | SettlementAmount | Passthrough | Tier 3 |
| 52 | SettlementCurrencyCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | SettlementCurrencyCode | Passthrough | Tier 3 |
| 53 | SettlementCurrencyAlpha | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | SettlementCurrencyAlpha | Passthrough | Tier 3 |
| 54 | SettlementConversionRate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | SettlementConversionRate | Passthrough | Tier 3 |
| 55 | MerchantNumber | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | MerchantNumber | Passthrough | Tier 3 |
| 56 | MerchantName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | MerchantName | Passthrough | Tier 3 |
| 57 | MerchantCountryCodeAlpha | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | MerchantCountryCodeAlpha | Passthrough | Tier 3 |
| 58 | MerchantCountryName | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | MerchantCountryName | Passthrough | Tier 3 |
| 59 | Mcc | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Mcc | Passthrough | Tier 3 |
| 60 | CardPresent | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | CardPresent | Passthrough | Tier 3 |
| 61 | PosDataDe22 | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | PosDataDe22 | Passthrough | Tier 3 |
| 62 | PosDatDe61 | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | PosDatDe61 | Passthrough (legacy typo column) | Tier 3 |
| 63 | AcquirerId | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | AcquirerId | Passthrough | Tier 3 |
| 64 | ReferenceNumber | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ReferenceNumber | Passthrough | Tier 3 |
| 65 | TraceNumber | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TraceNumber | Passthrough | Tier 3 |
| 66 | Action | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Action | Passthrough | Tier 3 |
| 67 | Network | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Network | Passthrough | Tier 3 |
| 68 | EntryModeCode | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | EntryModeCode | Passthrough | Tier 3 |
| 69 | EntryModeCodeDescription | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | EntryModeCodeDescription | Passthrough | Tier 3 |
| 70 | ECIIndicator | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | ECIIndicator | Passthrough | Tier 3 |
| 71 | Suspicious | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Suspicious | Passthrough | Tier 3 |
| 72 | RiskRuleCodes | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | RiskRuleCodes | Passthrough | Tier 3 |
| 73 | etr_y | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | etr_y | Passthrough (ETL year partition key) | Tier 3 |
| 74 | etr_ym | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | etr_ym | Passthrough (ETL year-month partition key) | Tier 3 |
| 75 | etr_ymd | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | etr_ymd | Passthrough (ETL year-month-day partition key) | Tier 3 |
| 76 | SynapseUpdateDate | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | SynapseUpdateDate | Passthrough (Generic Pipeline load timestamp) | Tier 3 |
| 77 | partition_date | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | partition_date | Passthrough (Generic Pipeline partition key) | Tier 3 |
| 78 | PosDataExtendedDe61 | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | PosDataExtendedDe61 | Passthrough (added later, replaces PosDatDe61 typo) | Tier 3 |
| 79 | Created | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | Created | Passthrough (datetime2 version of @Created) | Tier 3 |
| 80 | PosDataDe61 | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | PosDataDe61 | Passthrough (corrected column name, added later) | Tier 3 |
| 81 | TokenizedRequest | FiatDwhDB.Tribe.Authorizes_Authorize-312243 | TokenizedRequest | Passthrough | Tier 3 |
