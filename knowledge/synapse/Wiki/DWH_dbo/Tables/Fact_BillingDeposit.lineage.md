# Column Lineage: DWH_dbo.Fact_BillingDeposit

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_BillingDeposit` |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **Primary Source** | `Billing.Deposit` (`etoro`) via `DWH_staging.etoro_Billing_Deposit` |
| **Secondary Sources** | `Billing.Funding` (`etoro_Billing_Funding`), `Billing.RecurringDeposit`, `Fact_CustomerAction`, `Dim_Country`, `Dim_CountryBin` |
| **Loader SP** | `DWH_dbo.SP_Fact_BillingDeposit_DL_To_Synapse` + `DWH_dbo.SP_Fact_BillingDeposit` |
| **Generated** | 2026-05-14 |

## Lineage Chain

```
etoro.Billing.Deposit (+ Funding + RecurringDeposit)
  → Bronze / ADF Generic Pipeline → DWH_staging (Deposit, Funding, RecurringDeposit slices)
  → SP_Fact_BillingDeposit_DL_To_Synapse
        • Ext_FBD_Fact_BillingDeposit INSERT (XML shred + joins)
        • Fact_BillingDeposit DELETE/INSERT
        • PlatformID UPDATE (Fact_CustomerAction ActionTypeID=14 temp table)
        • EXEC SP_Fact_BillingDeposit (@Yesterday)
               • MOPCountry UPDATE via Dim_Country
               • BankName / CardCategory UPDATE via Dim_CountryBin
  → UC Gold mirror (Unity Catalog external table pipeline)
```

## Column Lineage (mechanical mapping)

Legend: **XML-f** / **XML-d** = `ExtractXMLValue(attribute, FundingData|PaymentData)`; staging passthrough reads `d.<col>` from `etoro_Billing_Deposit`.

| # | DWH Column | Source | Source detail | Transform |
|---|------------|--------|---------------|-----------|
| 1 | `CID` | `Billing.Deposit (via staging d)` | `CID` | passthrough |
| 2 | `CurrencyID` | `Billing.Deposit (via staging d)` | `CurrencyID` | passthrough |
| 3 | `Commission` | `Billing.Deposit (via staging d)` | `Commission` | passthrough |
| 4 | `Approved` | `Billing.Deposit (via staging d)` | `Approved` | passthrough |
| 5 | `ModificationDate` | `Billing.Deposit (via staging d)` | `ModificationDate` | passthrough |
| 6 | `ModificationDateID` | `Billing.Deposit.ModificationDate` | `CONVERT(int, CONVERT(varchar, dateadd(...)))` | ETL-computed |
| 7 | `FundingID` | `Billing.Deposit (via staging d)` | `FundingID` | passthrough |
| 8 | `ExchangeRate` | `Billing.Deposit (via staging d)` | `ExchangeRate` | passthrough |
| 9 | `DepositID` | `Billing.Deposit (via staging d)` | `DepositID` | passthrough |
| 10 | `ProcessorValueDate` | `Billing.Deposit (via staging d)` | `ProcessorValueDate` | passthrough |
| 11 | `DepotID` | `Billing.Deposit (via staging d)` | `DepotID` | passthrough |
| 12 | `SecuredCardDataAsString` | `Billing.Funding.FundingData` | `SecuredCardDataAsString` | XML-extracted |
| 13 | `BinCodeAsString` | `Billing.Funding.FundingData` | `BinCodeAsString` | XML-extracted |
| 14 | `BinCountryIDAsInteger` | `Billing.Funding.FundingData` | `BinCountryIDAsInteger` | XML-extracted |
| 15 | `CardTypeIDAsInteger` | `Billing.Funding.FundingData` | `CardTypeIDAsInteger` | XML-extracted |
| 16 | `PaymentStatusID` | `Billing.Deposit (via staging d)` | `PaymentStatusID` | passthrough |
| 17 | `ManagerID` | `Billing.Deposit (via staging d)` | `ManagerID` | passthrough |
| 18 | `RiskManagementStatusID` | `Billing.Deposit (via staging d)` | `RiskManagementStatusID` | passthrough |
| 19 | `Amount` | `Billing.Deposit.Amount` | `Amount` | CASE cap |
| 20 | `PaymentDate` | `Billing.Deposit (via staging d)` | `PaymentDate` | passthrough |
| 21 | `IPAddress` | `Billing.Deposit (via staging d)` | `IPAddress` | passthrough |
| 22 | `ClearingHouseEffectiveDate` | `Billing.Deposit (via staging d)` | `ClearingHouseEffectiveDate` | passthrough |
| 23 | `IsFTD` | `Billing.Deposit.IsFTD` | `IsFTD` | CAST+ISNULL |
| 24 | `RefundVerificationCode` | `Billing.Deposit (via staging d)` | `RefundVerificationCode` | passthrough |
| 25 | `MatchStatusID` | `Billing.Deposit (via staging d)` | `MatchStatusID` | passthrough |
| 26 | `BonusStatusID` | `Billing.Deposit (via staging d)` | `BonusStatusID` | passthrough |
| 27 | `BonusAmount` | `Billing.Deposit (via staging d)` | `BonusAmount` | passthrough |
| 28 | `BonusErrorCode` | `Billing.Deposit (via staging d)` | `BonusErrorCode` | passthrough |
| 29 | `ExTransactionID` | `?` | `?` | see wiki |
| 30 | `FundingTypeID` | `Billing.Funding` | `FundingTypeID` | JOIN |
| 31 | `IsRefundExcluded` | `Billing.Funding` | `IsRefundExcluded` | CAST(int) |
| 32 | `DocumentRequired` | `Billing.Funding` | `DocumentRequired` | CAST(int) |
| 33 | `UpdateDate` | `—` | `GETDATE()` | ETL-synthetic |
| 34 | `ExpirationDateID` | `Billing.Funding.FundingData` | `ExpirationDateAsString` | XML+CASE |
| 35 | `CountryIDAsInteger` | `Billing.Funding.FundingData` | `CountryIDAsInteger` | XML-extracted |
| 36 | `StateIDAsInteger` | `Billing.Deposit.PaymentData` | `StateIDAsInteger` | XML-extracted |
| 37 | `BankIDAsInteger` | `Billing.Funding.FundingData` | `BankIDAsInteger` | XML-extracted |
| 38 | `AccountNameAsString` | `Billing.Funding.FundingData` | `AccountNameAsString` | XML-extracted |
| 39 | `AccountTypeAsString` | `Billing.Funding.FundingData` | `AccountTypeAsString` | XML-extracted |
| 40 | `BankAccountAsString` | `Billing.Funding.FundingData` | `BankAccountAsString` | XML-extracted |
| 41 | `BankAddressAsString` | `Billing.Funding.FundingData` | `BankAddressAsString` | XML-extracted |
| 42 | `BankCodeAsDecimal` | `Billing.Funding.FundingData` | `BankCodeAsDecimal` | XML-extracted |
| 43 | `BankDetailsAccountIDAsString` | `Billing.Funding.FundingData` | `BankDetailsAccountIDAsString` | XML-extracted |
| 44 | `BankIDAsString` | `Billing.Funding.FundingData` | `BankIDAsString` | XML-extracted |
| 45 | `BankNameAsString` | `Billing.Funding.FundingData` | `BankNameAsString` | XML-extracted |
| 46 | `BICCodeAsString` | `Billing.Funding.FundingData` | `BICCodeAsString` | XML-extracted |
| 47 | `CIDAsString` | `Billing.Funding.FundingData` | `CIDAsString` | XML-extracted |
| 48 | `v` | `Billing.Funding.FundingData` | `ClientBankNameAsString` | XML-extracted |
| 49 | `CustomerAddressAsString` | `Billing.Funding.FundingData` | `CustomerAddressAsString` | XML-extracted |
| 50 | `CustomerNameAsString` | `Billing.Funding.FundingData` | `CustomerNameAsString` | XML-extracted |
| 51 | `FundingType` | `Billing.Funding.FundingData` | `FundingType` | XML-extracted |
| 52 | `MaskedAccountIDAsString` | `Billing.Funding.FundingData` | `MaskedAccountIDAsString` | XML-extracted |
| 53 | `PurseAsString` | `Billing.Funding.FundingData` | `PurseAsString` | XML-extracted |
| 54 | `RoutingNumberAsString` | `Billing.Funding.FundingData` | `RoutingNumberAsString` | XML-extracted |
| 55 | `SecureIDAsDecimal` | `Billing.Funding.FundingData` | `SecureIDAsDecimal` | XML-extracted |
| 56 | `SortCodeAsString` | `Billing.Funding.FundingData` | `SortCodeAsString` | XML-extracted |
| 57 | `AccountBalanceAsDecimal` | `Billing.Deposit.PaymentData` | `AccountBalanceAsDecimal` | XML-extracted |
| 58 | `AccountHolderAsString` | `Billing.Deposit.PaymentData` | `AccountHolderAsString` | XML-extracted |
| 59 | `AccountIDAsDecimal` | `Billing.Funding.FundingData` | `AccountIDAsDecimal` | XML-extracted |
| 60 | `ACHBankAccountIDAsInteger` | `Billing.Deposit.PaymentData` | `ACHBankAccountIDAsInteger` | XML-extracted |
| 61 | `Address1AsString` | `Billing.Deposit.PaymentData` | `Address1AsString` | XML-extracted |
| 62 | `Address2AsString` | `Billing.Deposit.PaymentData` | `Address2AsString` | XML-extracted |
| 63 | `AdviseAsString` | `Billing.Deposit.PaymentData` | `AdviseAsString` | XML-extracted |
| 64 | `AvailableBalanceAsDecimal` | `Billing.Deposit.PaymentData` | `AvailableBalanceAsDecimal` | XML-extracted |
| 65 | `BankCodeAsString` | `Billing.Funding.FundingData` | `BankCodeAsString` | XML-extracted |
| 66 | `BillNumberAsString` | `Billing.Deposit.PaymentData` | `BillNumberAsString` | XML-extracted |
| 67 | `BuildingNumberAsString` | `Billing.Deposit.PaymentData` | `BuildingNumberAsString` | XML-extracted |
| 68 | `CardHolderPhoneNumberBodyAsString` | `Billing.Deposit.PaymentData` | `CardHolderPhoneNumberBodyAsString` | XML-extracted |
| 69 | `CardHolderPhoneNumberPrefixAsString` | `Billing.Deposit.PaymentData` | `CardHolderPhoneNumberPrefixAsString` | XML-extracted |
| 70 | `CardNumberAsString` | `Billing.Funding.FundingData` | `CardNumberAsString` | XML-extracted |
| 71 | `CityAsString` | `Billing.Deposit.PaymentData` | `CityAsString` | XML-extracted |
| 72 | `CountryIDAsString` | `Billing.Deposit.PaymentData` | `CountryIDAsString` | XML-extracted |
| 73 | `CountryNameAsString` | `Billing.Deposit.PaymentData` | `CountryNameAsString` | XML-extracted |
| 74 | `CreatedAtAsString` | `Billing.Deposit.PaymentData` | `CreatedAtAsString` | XML-extracted |
| 75 | `CurrentBalanceAsDecimal` | `Billing.Deposit.PaymentData` | `CurrentBalanceAsDecimal` | XML-extracted |
| 76 | `CustomerIDAsString` | `Billing.Deposit.PaymentData` | `CustomerIDAsString` | XML-extracted |
| 77 | `EmailAsString` | `Billing.Funding.FundingData` | `EmailAsString` | XML-extracted |
| 78 | `EndPointIDAsString` | `Billing.Deposit.PaymentData` | `EndPointIDAsString` | XML-extracted |
| 79 | `ErrorCodeAsString` | `Billing.Deposit.PaymentData` | `ErrorCodeAsString` | XML-extracted |
| 80 | `ErrorTypeAsString` | `Billing.Deposit.PaymentData` | `ErrorTypeAsString` | XML-extracted |
| 81 | `FirstNameAsString` | `Billing.Deposit.PaymentData` | `FirstNameAsString` | XML-extracted |
| 82 | `IBANCodeAsString` | `Billing.Funding.FundingData` | `IBANCodeAsString` | XML-extracted |
| 83 | `InitialTransactionIDAsString` | `Billing.Deposit.PaymentData` | `InitialTransactionIDAsString` | XML-extracted |
| 84 | `IPAsString` | `Billing.Deposit.PaymentData` | `IPAsString` | XML-extracted |
| 85 | `LanguageIDAsInteger` | `Billing.Deposit.PaymentData` | `LanguageIDAsInteger` | XML-extracted |
| 86 | `LastNameAsString` | `Billing.Deposit.PaymentData` | `LastNameAsString` | XML-extracted |
| 87 | `MD5AsString` | `Billing.Deposit.PaymentData` | `MD5AsString` | XML-extracted |
| 88 | `PayerAsString` | `Billing.Deposit.PaymentData` | `PayerAsString` | XML-extracted |
| 89 | `PayerBusiness` | `Billing.Deposit.PaymentData` | `PayerBusiness` | XML-extracted |
| 90 | `PayerIDAsString` | `Billing.Funding.FundingData` | `PayerIDAsString` | XML-extracted |
| 91 | `PayerPurseAsString` | `Billing.Deposit.PaymentData` | `PayerPurseAsString` | XML-extracted |
| 92 | `PayerStatus` | `Billing.Deposit.PaymentData` | `PayerStatus` | XML-extracted |
| 93 | `PaymentAmountAsDecimal` | `Billing.Deposit.PaymentData` | `PaymentAmountAsDecimal` | XML-extracted |
| 94 | `PaymentDateAsDateTime` | `Billing.Deposit.PaymentData` | `PaymentDateAsDateTime` | XML-extracted |
| 95 | `PaymentGuaranteeAsString` | `Billing.Deposit.PaymentData` | `PaymentGuaranteeAsString` | XML-extracted |
| 96 | `PaymentModeAsInteger` | `Billing.Deposit.PaymentData` | `PaymentModeAsInteger` | XML-extracted |
| 97 | `PaymentProviderTransactionStatusAsString` | `Billing.Deposit.PaymentData` | `PaymentProviderTransactionStatusAsString` | XML-extracted |
| 98 | `PaymentStatusAsInteger` | `Billing.Deposit.PaymentData` | `PaymentStatusAsInteger` | XML-extracted |
| 99 | `PaymentTypeAsString` | `Billing.Deposit.PaymentData` | `PaymentTypeAsString` | XML-extracted |
| 100 | `PlaidItemIDAsString` | `Billing.Deposit.PaymentData` | `PlaidItemIDAsString` | XML-extracted |
| 101 | `PlaidNamesAsString` | `Billing.Deposit.PaymentData` | `PlaidNamesAsString` | XML-extracted |
| 102 | `PlatformIDAsInteger` | `Billing.Deposit.PaymentData` | `PlatformIDAsInteger` | XML-extracted |
| 103 | `PromotionCodeAsString` | `Billing.Deposit.PaymentData` | `PromotionCodeAsString` | XML-extracted |
| 104 | `PSPCodeAsString` | `Billing.Deposit.PaymentData` | `PSPCodeAsString` | XML-extracted |
| 105 | `RapidFirstNameAsString` | `Billing.Deposit.PaymentData` | `RapidFirstNameAsString` | XML-extracted |
| 106 | `RapidLastNameAsString` | `Billing.Deposit.PaymentData` | `RapidLastNameAsString` | XML-extracted |
| 107 | `ResponseMessageAsString` | `Billing.Deposit.PaymentData` | `ResponseMessageAsString` | XML-extracted |
| 108 | `ResponseTimeAsString` | `Billing.Deposit.PaymentData` | `ResponseTimeAsString` | XML-extracted |
| 109 | `SecretKeyAsString` | `Billing.Deposit.PaymentData` | `SecretKeyAsString` | XML-extracted |
| 110 | `ThreeDsAsJson` | `Billing.Deposit.PaymentData` | `ThreeDsAsJson` | XML-extracted |
| 111 | `ThreeDsResponseType` | `Billing.Deposit.PaymentData` | `ThreeDsResponseType` | XML-extracted |
| 112 | `TokenAsString` | `Billing.Deposit.PaymentData` | `TokenAsString` | XML-extracted |
| 113 | `TransactionIDAsString` | `Billing.Deposit.PaymentData` | `TransactionIDAsString` | XML-extracted |
| 114 | `ZipCodeAsString` | `Billing.Deposit.PaymentData` | `ZipCodeAsString` | XML-extracted |
| 115 | `BaseExchangeRate` | `Billing.Deposit (via staging d)` | `BaseExchangeRate` | passthrough |
| 116 | `ExchangeFee` | `Billing.Deposit (via staging d)` | `ExchangeFee` | passthrough |
| 117 | `ProtocolMIDSettingsID` | `Billing.Deposit (via staging d)` | `ProtocolMIDSettingsID` | passthrough |
| 118 | `FunnelID` | `Billing.Deposit (via staging d)` | `FunnelID` | passthrough |
| 119 | `AmountUSD` | `Billing.Deposit` | `Amount * ExchangeRate` | ETL-computed |
| 120 | `SessionID` | `Billing.Deposit.SessionID` | `SessionID` | ISNULL→0 |
| 121 | `PlatformID` | `Fact_CustomerAction` | `PlatformID` | UPDATE JOIN |
| 122 | `MOPCountry` | `Dim_Country` | `Name` | derived from CountryIDAsString |
| 123 | `SwiftCodeAsString` | `Billing.Funding.FundingData` | `SwiftCodeAsString` | XML-extracted |
| 124 | `ClientBankNameAsString` | `Billing.Funding.FundingData` | `ClientBankNameAsString` | XML-extracted |
| 125 | `BankName` | `Dim_CountryBin` | `BankName` | UPDATE JOIN BIN |
| 126 | `CardCategory` | `Dim_CountryBin` | `CardCategory` | UPDATE JOIN BIN |
| 127 | `PaymentGeneration` | `Billing.Deposit (via staging d)` | `PaymentGeneration` | passthrough |
| 128 | `ProcessRegulationID` | `Billing.Deposit (via staging d)` | `ProcessRegulationID` | passthrough |
| 129 | `MerchantAccountID` | `Billing.Deposit (via staging d)` | `MerchantAccountID` | passthrough |
| 130 | `IsSetBalanceCompleted` | `?` | `?` | see wiki |
| 131 | `RoutingReasonID` | `Billing.Deposit (via staging d)` | `RoutingReasonID` | passthrough |
| 132 | `IsRecurring` | `Billing.RecurringDeposit` | `DepositID` | OUTER APPLY |
| 133 | `FlowID` | `Billing.Deposit (via staging d)` | `FlowID` | passthrough |
| 134 | `IsAftSupportedAsBool` | `Billing.Deposit.PaymentData` | `IsAftSupportedAsBool` | XML-extracted |
| 135 | `IsAftEligibleAsBool` | `Billing.Deposit.PaymentData` | `IsAftEligibleAsBool` | XML-extracted |
| 136 | `IsAftProcessedAsBool` | `Billing.Deposit.PaymentData` | `IsAftProcessedAsBool` | XML-extracted |


## Checkpoint

PHASE 10B CHECKPOINT: PASS — mechanical trace from SSDT loader SPs dated 2025-07..2025 additions (IsAft*, Amount CASE).
