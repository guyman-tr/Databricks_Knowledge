# Column Lineage: main.bi_output.vg_fact_billingdeposit_for_genie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_billingdeposit_for_genie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_fact_billingdeposit_for_genie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_fact_billingdeposit_for_genie.json` (rows: 1, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit   ←── primary upstream
        │
        ▼
main.bi_output.vg_fact_billingdeposit_for_genie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `CurrencyID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `Commission` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `Approved` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `ModificationDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `ModificationDateID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `FundingID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `ExchangeRate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `DepositID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `ProcessorValueDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `DepotID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `SecuredCardDataAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `BinCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `BinCountryIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `CardTypeIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 16 | `PaymentStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 17 | `ManagerID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 18 | `RiskManagementStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 19 | `Amount` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 20 | `PaymentDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 21 | `IPAddress` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 22 | `ClearingHouseEffectiveDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 23 | `IsFTD` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 24 | `RefundVerificationCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 25 | `MatchStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 26 | `BonusStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 27 | `BonusAmount` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 28 | `BonusErrorCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 29 | `ExTransactionID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 30 | `FundingTypeID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 31 | `IsRefundExcluded` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 32 | `DocumentRequired` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 33 | `UpdateDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 34 | `ExpirationDateID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 35 | `CountryIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 36 | `StateIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 37 | `BankIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 38 | `AccountNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 39 | `AccountTypeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 40 | `BankAccountAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 41 | `BankAddressAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 42 | `BankCodeAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 43 | `BankDetailsAccountIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 44 | `BankIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 45 | `BankNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 46 | `BICCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 47 | `CIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 48 | `v` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 49 | `CustomerAddressAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 50 | `CustomerNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 51 | `FundingType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 52 | `MaskedAccountIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 53 | `PurseAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 54 | `RoutingNumberAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 55 | `SecureIDAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 56 | `SortCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 57 | `AccountBalanceAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 58 | `AccountHolderAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 59 | `AccountIDAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 60 | `ACHBankAccountIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 61 | `Address1AsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 62 | `Address2AsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 63 | `AdviseAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 64 | `AvailableBalanceAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 65 | `BankCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 66 | `BillNumberAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 67 | `BuildingNumberAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 68 | `CardHolderPhoneNumberBodyAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 69 | `CardHolderPhoneNumberPrefixAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 70 | `CardNumberAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 71 | `CityAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 72 | `CountryIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 73 | `CountryNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 74 | `CreatedAtAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 75 | `CurrentBalanceAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 76 | `CustomerIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 77 | `EmailAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 78 | `EndPointIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 79 | `ErrorCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 80 | `ErrorTypeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 81 | `FirstNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 82 | `IBANCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 83 | `InitialTransactionIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 84 | `IPAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 85 | `LanguageIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 86 | `LastNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 87 | `MD5AsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 88 | `PayerAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 89 | `PayerBusiness` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 90 | `PayerIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 91 | `PayerPurseAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 92 | `PayerStatus` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 93 | `PaymentAmountAsDecimal` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 94 | `PaymentDateAsDateTime` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 95 | `PaymentGuaranteeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 96 | `PaymentModeAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 97 | `PaymentProviderTransactionStatusAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 98 | `PaymentStatusAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 99 | `PaymentTypeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 100 | `PlaidItemIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 101 | `PlaidNamesAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 102 | `PlatformIDAsInteger` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 103 | `PromotionCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 104 | `PSPCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 105 | `RapidFirstNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 106 | `RapidLastNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 107 | `ResponseMessageAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 108 | `ResponseTimeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 109 | `SecretKeyAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 110 | `ThreeDsAsJson` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 111 | `ThreeDsResponseType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 112 | `TokenAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 113 | `TransactionIDAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 114 | `ZipCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 115 | `BaseExchangeRate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 116 | `ExchangeFee` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 117 | `ProtocolMIDSettingsID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 118 | `FunnelID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 119 | `AmountUSD` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 120 | `SessionID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 121 | `PlatformID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 122 | `MOPCountry` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 123 | `SwiftCodeAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 124 | `ClientBankNameAsString` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 125 | `BankName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 126 | `CardCategory` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 127 | `PaymentGeneration` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 128 | `ProcessRegulationID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 129 | `MerchantAccountID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 130 | `IsSetBalanceCompleted` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 131 | `RoutingReasonID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 132 | `IsRecurring` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 133 | `FlowID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 134 | `IsAftSupportedAsBool` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 135 | `IsAftEligibleAsBool` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 136 | `IsAftProcessedAsBool` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 137 | `etr_y` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 138 | `etr_ym` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 139 | `etr_ymd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |

## Cross-check vs system.access.column_lineage

- Total target columns: **1**
- OK: **1**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
