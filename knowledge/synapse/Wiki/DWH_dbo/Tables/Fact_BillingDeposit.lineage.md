# Column Lineage: DWH_dbo.Fact_BillingDeposit

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_BillingDeposit` |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **Primary Source** | `Billing.Deposit` (etoro) |
| **ETL SP** | `SP_Fact_BillingDeposit_DL_To_Synapse` |
| **Post-Processing SP** | `SP_Fact_BillingDeposit` |
| **Secondary Sources** | `Billing.Funding` (via staging), `Fact_CustomerAction`, `Dim_Country`, `Dim_CountryBin`, `Billing.RecurringDeposit` |
| **Generic Pipeline** | `main.billing.bronze_etoro_billing_deposit` (CopyStrategy: parquet, Freq: Done/daily) |
| **Generated** | 2026-03-15 |

## Lineage Chain

```
Production                    Generic Pipeline           Synapse DWH
───────────────────────       ──────────────────         ──────────────────
Billing.Deposit          ──►  DWH_staging.               SP_Fact_BillingDeposit_
Billing.Funding               etoro_Billing_        ──►  DL_To_Synapse     ──►  Ext_FBD_Fact_
                              Deposit                    (main ETL SP)          BillingDeposit
                              etoro_Billing_                                          │
                              Funding                                                 ▼
                                                                              Fact_BillingDeposit
                                                         SP_Fact_             ──►  (final table)
                                                         BillingDeposit
                                                         (post-processing:
                                                          MOPCountry, BankName,
                                                          CardCategory, PlatformID)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. Same name, same value. |
| **rename** | Column copied as-is but with a different name in DWH. |
| **cast/convert** | Type conversion only (e.g., datetime→int). |
| **ETL-computed** | Value derived or calculated by the ETL SP. Not in any single source. |
| **join-enriched** | Value joined from a secondary source table during ETL. |
| **SP-adjusted** | Value starts as passthrough but is modified by a post-load SP. |
| **XML-extracted** | Value extracted from XML blob column via ExtractXMLValue function. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | Billing.Deposit | CID | passthrough | Customer ID |
| CurrencyID | Billing.Deposit | CurrencyID | passthrough | |
| Commission | Billing.Deposit | Commission | passthrough | |
| Approved | Billing.Deposit | Approved | passthrough | Legacy, 99.99% NULL |
| ModificationDate | Billing.Deposit | ModificationDate | passthrough | Primary date filter |
| ModificationDateID | — | — | ETL-computed | CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112)) |
| FundingID | Billing.Deposit | FundingID | passthrough | |
| ExchangeRate | Billing.Deposit | ExchangeRate | passthrough | |
| DepositID | Billing.Deposit | DepositID | passthrough | PK + distribution key |
| ProcessorValueDate | Billing.Deposit | ProcessorValueDate | passthrough | |
| DepotID | Billing.Deposit | DepotID | passthrough | |
| SecuredCardDataAsString | Billing.Funding | FundingData XML | XML-extracted | ExtractXMLValue('SecuredCardDataAsString', FundingData) |
| BinCodeAsString | Billing.Funding | FundingData XML | XML-extracted | ExtractXMLValue('BinCodeAsString', FundingData) |
| BinCountryIDAsInteger | Billing.Funding | FundingData XML | XML-extracted | CAST(ExtractXMLValue('BinCountryIDAsInteger', FundingData) AS INT) |
| CardTypeIDAsInteger | Billing.Funding | FundingData XML | XML-extracted | CAST(ExtractXMLValue('CardTypeIDAsInteger', FundingData) AS INT) |
| PaymentStatusID | Billing.Deposit | PaymentStatusID | passthrough | |
| ManagerID | Billing.Deposit | ManagerID | passthrough | |
| RiskManagementStatusID | Billing.Deposit | RiskManagementStatusID | passthrough | |
| Amount | Billing.Deposit | Amount | SP-adjusted | Capped at +/-99999999 in ETL (IIF ABS > 99999999) |
| PaymentDate | Billing.Deposit | PaymentDate | passthrough | |
| IPAddress | Billing.Deposit | IPAddress | passthrough | |
| ClearingHouseEffectiveDate | Billing.Deposit | ClearingHouseEffectiveDate | passthrough | |
| IsFTD | Billing.Deposit | IsFTD | passthrough | |
| RefundVerificationCode | Billing.Deposit | RefundVerificationCode | passthrough | |
| MatchStatusID | Billing.Deposit | MatchStatusID | passthrough | |
| BonusStatusID | Billing.Deposit | BonusStatusID | passthrough | |
| BonusAmount | Billing.Deposit | BonusAmount | passthrough | |
| BonusErrorCode | Billing.Deposit | BonusErrorCode | passthrough | |
| ExTransactionID | Billing.Deposit | ExTransactionID | passthrough | |
| FundingTypeID | Billing.Deposit | FundingTypeID | passthrough | |
| IsRefundExcluded | Billing.Deposit | IsRefundExcluded | passthrough | |
| DocumentRequired | Billing.Deposit | DocumentRequired | passthrough | |
| UpdateDate | — | — | ETL-computed | GETUTCDATE() at ETL run time |
| ExpirationDateID | — | — | ETL-computed | Derived from ExpirationDateAsString XML. TRY_CONVERT logic |
| CountryIDAsInteger | Billing.Funding | FundingData XML | XML-extracted | CAST(ExtractXMLValue('CountryIDAsInteger', FundingData) AS INT) |
| StateIDAsInteger | Billing.Deposit | PaymentData XML | XML-extracted | CAST(ExtractXMLValue('StateIDAsInteger', PaymentData) AS INT) |
| BankIDAsInteger | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE from PaymentData then FundingData |
| AccountNameAsString | Billing.Funding | FundingData XML | XML-extracted | |
| AccountTypeAsString | Billing.Funding | FundingData XML | XML-extracted | |
| BankAccountAsString | Billing.Funding | FundingData XML | XML-extracted | |
| BankAddressAsString | Billing.Funding | FundingData XML | XML-extracted | |
| BankCodeAsDecimal | Billing.Funding | FundingData XML | XML-extracted | |
| BankDetailsAccountIDAsString | Billing.Funding | FundingData XML | XML-extracted | |
| BankIDAsString | Billing.Funding | FundingData XML | XML-extracted | |
| BankNameAsString | Billing.Funding | FundingData XML | XML-extracted | Raw value — different from BankName |
| BICCodeAsString | Billing.Funding | FundingData XML | XML-extracted | |
| v | Billing.Funding | FundingData XML | XML-extracted | TRUNCATED ALIAS BUG: ExtractXMLValue('ClientBankNameAsString', FundingData) AS v |
| CustomerAddressAsString | Billing.Funding | FundingData XML | XML-extracted | |
| CustomerNameAsString | Billing.Funding | FundingData XML | XML-extracted | |
| FundingType | Billing.Funding | FundingData XML | XML-extracted | String version of FundingTypeID |
| MaskedAccountIDAsString | Billing.Funding | FundingData XML | XML-extracted | |
| PurseAsString | Billing.Funding | FundingData XML | XML-extracted | |
| RoutingNumberAsString | Billing.Funding | FundingData XML | XML-extracted | |
| SecureIDAsDecimal | Billing.Funding | FundingData XML | XML-extracted | |
| SortCodeAsString | Billing.Funding | FundingData XML | XML-extracted | |
| AccountBalanceAsDecimal | Billing.Deposit | PaymentData XML | XML-extracted | |
| AccountHolderAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| AccountIDAsDecimal | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE |
| ACHBankAccountIDAsInteger | Billing.Deposit | PaymentData XML | XML-extracted | |
| Address1AsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| Address2AsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| AdviseAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| AvailableBalanceAsDecimal | Billing.Deposit | PaymentData XML | XML-extracted | |
| BankCodeAsString | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE |
| BillNumberAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| BuildingNumberAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| CardHolderPhoneNumberBodyAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| CardHolderPhoneNumberPrefixAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| CardNumberAsString | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE |
| CityAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| CountryIDAsString | Billing.Deposit | PaymentData XML | XML-extracted | Used to derive MOPCountry |
| CountryNameAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| CreatedAtAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| CurrentBalanceAsDecimal | Billing.Deposit | PaymentData XML | XML-extracted | |
| CustomerIDAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| EmailAsString | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE |
| EndPointIDAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| ErrorCodeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| ErrorTypeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| FirstNameAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| IBANCodeAsString | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE |
| InitialTransactionIDAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| IPAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| LanguageIDAsInteger | Billing.Deposit | PaymentData XML | XML-extracted | |
| LastNameAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| MD5AsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PayerAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PayerBusiness | Billing.Deposit | PaymentData XML | XML-extracted | |
| PayerIDAsString | Billing.Deposit + Funding | PaymentData/FundingData XML | XML-extracted | COALESCE |
| PayerPurseAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PayerStatus | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentAmountAsDecimal | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentDateAsDateTime | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentGuaranteeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentModeAsInteger | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentProviderTransactionStatusAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentStatusAsInteger | Billing.Deposit | PaymentData XML | XML-extracted | |
| PaymentTypeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PlaidItemIDAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PlaidNamesAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PlatformIDAsInteger | Billing.Deposit | PaymentData XML | XML-extracted | Different from PlatformID |
| PromotionCodeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| PSPCodeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| RapidFirstNameAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| RapidLastNameAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| ResponseMessageAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| ResponseTimeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| SecretKeyAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| ThreeDsAsJson | Billing.Deposit | PaymentData XML | XML-extracted | |
| ThreeDsResponseType | Billing.Deposit | PaymentData XML | XML-extracted | |
| TokenAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| TransactionIDAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| ZipCodeAsString | Billing.Deposit | PaymentData XML | XML-extracted | |
| BaseExchangeRate | Billing.Deposit | BaseExchangeRate | passthrough | |
| ExchangeFee | Billing.Deposit | ExchangeFee | passthrough | |
| ProtocolMIDSettingsID | Billing.Deposit | ProtocolMIDSettingsID | passthrough | |
| FunnelID | Billing.Deposit | FunnelID | passthrough | |
| AmountUSD | — | — | ETL-computed | Amount * ExchangeRate |
| SessionID | Billing.Deposit | SessionID | passthrough | |
| PlatformID | Fact_CustomerAction | PlatformID | join-enriched | Joined via CID+SessionID WHERE ActionTypeID=14. Post-processing SP |
| MOPCountry | Dim_Country | Country | join-enriched | Derived from CountryIDAsString via Dim_Country JOIN. Post-processing SP |
| SwiftCodeAsString | Billing.Funding | FundingData XML | XML-extracted | |
| ClientBankNameAsString | Billing.Funding | FundingData XML | XML-extracted | |
| BankName | Dim_CountryBin | BankName | join-enriched | Joined via BinCodeAsString. Post-processing SP |
| CardCategory | Dim_CountryBin | CardCategory | join-enriched | Joined via BinCodeAsString. Post-processing SP. Note: STANDART typo |
| PaymentGeneration | Billing.Deposit | PaymentGeneration | passthrough | |
| ProcessRegulationID | Billing.Deposit | ProcessRegulationID | passthrough | |
| MerchantAccountID | Billing.Deposit | MerchantAccountID | passthrough | |
| IsSetBalanceCompleted | Billing.Deposit | IsSetBalanceCompleted | passthrough | |
| RoutingReasonID | Billing.Deposit | RoutingReasonID | passthrough | |
| IsRecurring | Billing.RecurringDeposit | — | join-enriched | LEFT JOIN on DepositID. Post-processing SP |
| FlowID | Billing.Deposit | FlowID | passthrough | |
| IsAftSupportedAsBool | Billing.Deposit | IsAftSupportedAsBool | passthrough | Added 2025-03-02 |
| IsAftEligibleAsBool | Billing.Deposit | IsAftEligibleAsBool | passthrough | Added 2025-03-02 |
| IsAftProcessedAsBool | Billing.Deposit | IsAftProcessedAsBool | passthrough | Added 2025-03-02 |
| etr_y | — | — | ETL-computed | UC partition column. Year from ETL load date |
| etr_ym | — | — | ETL-computed | UC partition column. Year-month |
| etr_ymd | — | — | ETL-computed | UC partition column. Year-month-day |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 37 |
| **XML-extracted** | 79 |
| **ETL-computed** | 7 |
| **Join-Enriched** | 5 |
| **SP-adjusted** | 1 |
| **Total** | 129 + 10 (COALESCE XML cols counted once) = 139 |
