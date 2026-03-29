# DWH_dbo.VU_FactBilling_ForBigQuery

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[VU_FactBilling_ForBigQuery]` |
| **Type** | View |
| **Base Tables** | `Fact_BillingDeposit` |
| **Purpose** | Export-ready view of `Fact_BillingDeposit` that sanitizes string columns through `DWH_dbo.RemoveSpecialChars()` for safe ingestion into Google BigQuery. |

## 2. Business Context

This view prepares billing deposit data for export to **Google BigQuery**. The "VU_" prefix suggests it is part of a data unload/export pipeline.

### Sanitization Pattern
All string/detail columns are processed through a two-step transformation:
1. `CONVERT(NVARCHAR(MAX), ...)` — ensures consistent string type
2. `DWH_dbo.RemoveSpecialChars(...)` — strips characters that could break CSV/JSON export or BigQuery ingestion (likely special characters, control characters, or delimiters)

Approximately **70+ columns** receive this sanitization treatment. Numeric and date columns pass through without transformation.

### Column Groups

| Group | Count | Treatment |
|-------|-------|-----------|
| Core billing | ~20 | Direct passthrough (CID, Amount, dates, IDs) |
| Card/payment detail strings | ~70 | `RemoveSpecialChars(CONVERT(NVARCHAR(MAX), ...))` |
| Exchange/fee | ~5 | Direct passthrough |

### Notable String Columns
The view exposes extensive payment processor detail columns (card data, bank details, payer information, 3DS data, Plaid integration fields) that come from the raw billing system. Many have suffixed type hints (e.g., `AsString`, `AsDecimal`, `AsInteger`) indicating they were originally typed fields serialized as strings.

## 3. Elements

All 122 columns are passthrough from `Fact_BillingDeposit`. String columns are wrapped in `RemoveSpecialChars(CONVERT(NVARCHAR(MAX), ...))` for safe BigQuery ingestion. Numeric/date columns pass through unchanged.

### 3.1 Core Billing Columns (Direct Passthrough)

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | CID | int | Fact_BillingDeposit.CID | Customer ID. Identifies the eToro customer who made this deposit. References Dim_Customer. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 2 | CurrencyID | int | Fact_BillingDeposit.CurrencyID | Currency of the deposit amount. References Dim_Currency. 1=USD, 2=EUR, 3=GBP. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 3 | Commission | money | Fact_BillingDeposit.Commission | Commission charged on this deposit. Default 0. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 4 | Approved | bit | Fact_BillingDeposit.Approved | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 5 | ModificationDate | datetime | Fact_BillingDeposit.ModificationDate | UTC timestamp of the most recent modification. Used by ETL for incremental detection. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 6 | ModificationDateID | int | Fact_BillingDeposit.ModificationDateID | Integer YYYYMMDD derived from ModificationDate. Used for rolling-window DELETE+INSERT. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 7 | FundingID | int | Fact_BillingDeposit.FundingID | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 8 | ExchangeRate | numeric(16,8) | Fact_BillingDeposit.ExchangeRate | Exchange rate from deposit currency to USD at processing time. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 9 | DepositID | int | Fact_BillingDeposit.DepositID | PK. Uniquely identifies each deposit attempt. HASH distribution key. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 10 | ProcessorValueDate | datetime | Fact_BillingDeposit.ProcessorValueDate | Value date from the payment processor. NULL for instant payment methods. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 11 | DepotID | int | Fact_BillingDeposit.DepotID | Acquirer/gateway configuration used for this deposit. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 12 | BinCountryIDAsInteger | int | Fact_BillingDeposit.BinCountryIDAsInteger | Country of card BIN. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 13 | CardTypeIDAsInteger | int | Fact_BillingDeposit.CardTypeIDAsInteger | Card type ID (Visa, MC, etc.). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 14 | PaymentStatusID | int | Fact_BillingDeposit.PaymentStatusID | Current deposit status. 2=Approved (73%), 3=Decline, 35=DeclineByRRE (10.2%). NC index key. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 15 | ManagerID | int | Fact_BillingDeposit.ManagerID | Operations manager who processed this deposit. 0=automated. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 16 | RiskManagementStatusID | int | Fact_BillingDeposit.RiskManagementStatusID | Pre-processing risk check result. 69 distinct risk reason codes. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 17 | Amount | money | Fact_BillingDeposit.Amount | Deposit amount in deposit currency. Capped via CASE since 2025-04-17. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 18 | PaymentDate | datetime | Fact_BillingDeposit.PaymentDate | UTC timestamp when the deposit was submitted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 19 | IPAddress | numeric(18,0) | Fact_BillingDeposit.IPAddress | Customer IP address at deposit time as 32-bit integer. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 20 | ClearingHouseEffectiveDate | datetime | Fact_BillingDeposit.ClearingHouseEffectiveDate | Settlement date from the clearing house. NULL for instant methods. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 21 | IsFTD | int | Fact_BillingDeposit.IsFTD | First Time Deposit flag. 1=customer's first approved deposit. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 22 | MatchStatusID | tinyint | Fact_BillingDeposit.MatchStatusID | PSP reconciliation match status. 0=Unmatched, 3=Matched. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 23 | BonusStatusID | int | Fact_BillingDeposit.BonusStatusID | Promotional bonus status. 0=New, 1=Approved, 2=Declined, 3=Reverted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 24 | BonusAmount | money | Fact_BillingDeposit.BonusAmount | Bonus amount credited with this deposit. NULL when no bonus. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 25 | BonusErrorCode | int | Fact_BillingDeposit.BonusErrorCode | Error code when bonus processing fails. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 26 | FundingTypeID | int | Fact_BillingDeposit.FundingTypeID | Payment instrument type from Billing.Funding. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 27 | IsRefundExcluded | int | Fact_BillingDeposit.IsRefundExcluded | Whether deposit is excluded from refund eligibility. From Billing.Funding. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 28 | DocumentRequired | int | Fact_BillingDeposit.DocumentRequired | Whether documentation was required. From Billing.Funding. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 29 | UpdateDate | datetime | Fact_BillingDeposit.UpdateDate | ETL load timestamp (GETDATE()). (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 30 | ExpirationDateID | int | Fact_BillingDeposit.ExpirationDateID | Card expiration date as YYYYMMDD integer. NC index key. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 31 | CountryIDAsInteger | int | Fact_BillingDeposit.CountryIDAsInteger | Customer country from payment data. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 32 | StateIDAsInteger | int | Fact_BillingDeposit.StateIDAsInteger | Customer state/province from payment data. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 33 | BankIDAsInteger | int | Fact_BillingDeposit.BankIDAsInteger | Bank identifier integer. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 34 | BaseExchangeRate | numeric(16,8) | Fact_BillingDeposit.BaseExchangeRate | Reference exchange rate before fee markup. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 35 | ExchangeFee | int | Fact_BillingDeposit.ExchangeFee | Exchange fee in basis points. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 36 | ProtocolMIDSettingsID | int | Fact_BillingDeposit.ProtocolMIDSettingsID | Merchant ID configuration profile. Default 0. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 37 | FunnelID | int | Fact_BillingDeposit.FunnelID | Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 38 | AmountUSD | decimal(11,2) | Fact_BillingDeposit.AmountUSD | Deposit amount converted to USD. DWH-computed: Amount × ExchangeRate. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 39 | SessionID | bigint | Fact_BillingDeposit.SessionID | Application session ID. Used for PlatformID enrichment. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 40 | PlatformID | int | Fact_BillingDeposit.PlatformID | Device/platform from second ETL pass via Fact_CustomerAction. NULL if no session match. (Tier 1 — inherited from Fact_BillingDeposit wiki) |

### 3.2 Sanitized String Columns (via `RemoveSpecialChars(CONVERT(NVARCHAR(MAX), ...))`)

All columns below are `nvarchar(max)` in the view output. Source type varies but all are wrapped in RemoveSpecialChars for BigQuery-safe export.

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 41 | SecuredCardDataAsString | Fact_BillingDeposit.SecuredCardDataAsString | Tokenized card data reference. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 42 | BinCodeAsString | Fact_BillingDeposit.BinCodeAsString | Card BIN (first 6-8 digits). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 43 | RefundVerificationCode | Fact_BillingDeposit.RefundVerificationCode | Verification code for refund correlation. NULL for non-refunded deposits. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 44 | ExTransactionID | Fact_BillingDeposit.ExTransactionID | External (payment provider) transaction ID. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 45 | AccountNameAsString | Fact_BillingDeposit.AccountNameAsString | Bank account holder name. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 46 | AccountTypeAsString | Fact_BillingDeposit.AccountTypeAsString | Bank account type (checking, savings). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 47 | BankAccountAsString | Fact_BillingDeposit.BankAccountAsString | Bank account number (masked). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 48 | BankAddressAsString | Fact_BillingDeposit.BankAddressAsString | Bank address. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 49 | BankCodeAsDecimal | Fact_BillingDeposit.BankCodeAsDecimal | Bank code (numeric string). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 50 | BankDetailsAccountIDAsString | Fact_BillingDeposit.BankDetailsAccountIDAsString | Bank details account identifier. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 51 | BankIDAsString | Fact_BillingDeposit.BankIDAsString | Bank identifier string. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 52 | BankNameAsString | Fact_BillingDeposit.BankNameAsString | Name of the bank. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 53 | BICCodeAsString | Fact_BillingDeposit.BICCodeAsString | SWIFT/BIC code for wire transfers. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 54 | CIDAsString | Fact_BillingDeposit.CIDAsString | Customer ID as string (XML cross-check). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 55 | v | Fact_BillingDeposit.v | XML-extracted field with no descriptive name (artifact). Contents require domain review. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 56 | CustomerAddressAsString | Fact_BillingDeposit.CustomerAddressAsString | Customer's billing address. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 57 | CustomerNameAsString | Fact_BillingDeposit.CustomerNameAsString | Customer name from payment instrument. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 58 | FundingType | Fact_BillingDeposit.FundingType | Funding type label from XML. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 59 | MaskedAccountIDAsString | Fact_BillingDeposit.MaskedAccountIDAsString | Masked account/card identifier for display. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 60 | PurseAsString | Fact_BillingDeposit.PurseAsString | E-wallet purse/account ID. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 61 | RoutingNumberAsString | Fact_BillingDeposit.RoutingNumberAsString | US ACH routing number. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 62 | SecureIDAsDecimal | Fact_BillingDeposit.SecureIDAsDecimal | Secure transaction ID (numeric string). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 63 | SortCodeAsString | Fact_BillingDeposit.SortCodeAsString | UK bank sort code. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 64 | AccountBalanceAsDecimal | Fact_BillingDeposit.AccountBalanceAsDecimal | Account balance from payment provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 65 | AccountHolderAsString | Fact_BillingDeposit.AccountHolderAsString | Account holder name. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 66 | AccountIDAsDecimal | Fact_BillingDeposit.AccountIDAsDecimal | Account identifier (numeric string). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 67 | ACHBankAccountIDAsInteger | Fact_BillingDeposit.ACHBankAccountIDAsInteger | ACH bank account reference ID. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 68 | Address1AsString | Fact_BillingDeposit.Address1AsString | Billing address line 1. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 69 | Address2AsString | Fact_BillingDeposit.Address2AsString | Billing address line 2. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 70 | AdviseAsString | Fact_BillingDeposit.AdviseAsString | Payment provider advisory message. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 71 | AvailableBalanceAsDecimal | Fact_BillingDeposit.AvailableBalanceAsDecimal | Available balance from provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 72 | BankCodeAsString | Fact_BillingDeposit.BankCodeAsString | Bank code (string form). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 73 | BillNumberAsString | Fact_BillingDeposit.BillNumberAsString | Bill/invoice number. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 74 | BuildingNumberAsString | Fact_BillingDeposit.BuildingNumberAsString | Building number in address. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 75 | CardHolderPhoneNumberBodyAsString | Fact_BillingDeposit.CardHolderPhoneNumberBodyAsString | Cardholder phone number body. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 76 | CardHolderPhoneNumberPrefixAsString | Fact_BillingDeposit.CardHolderPhoneNumberPrefixAsString | Cardholder phone number prefix. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 77 | CardNumberAsString | Fact_BillingDeposit.CardNumberAsString | Card number (masked). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 78 | CityAsString | Fact_BillingDeposit.CityAsString | Billing city. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 79 | CountryIDAsString | Fact_BillingDeposit.CountryIDAsString | Country identifier string. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 80 | CountryNameAsString | Fact_BillingDeposit.CountryNameAsString | Country name from payment XML. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 81 | CreatedAtAsString | Fact_BillingDeposit.CreatedAtAsString | Payment instrument creation timestamp. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 82 | CurrentBalanceAsDecimal | Fact_BillingDeposit.CurrentBalanceAsDecimal | Current balance from provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 83 | CustomerIDAsString | Fact_BillingDeposit.CustomerIDAsString | Customer ID string from payment data. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 84 | EmailAsString | Fact_BillingDeposit.EmailAsString | Customer email from payment instrument. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 85 | EndPointIDAsString | Fact_BillingDeposit.EndPointIDAsString | Payment provider endpoint identifier. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 86 | ErrorCodeAsString | Fact_BillingDeposit.ErrorCodeAsString | Provider error code on decline. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 87 | ErrorTypeAsString | Fact_BillingDeposit.ErrorTypeAsString | Provider error type classification. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 88 | FirstNameAsString | Fact_BillingDeposit.FirstNameAsString | Cardholder/account holder first name. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 89 | IBANCodeAsString | Fact_BillingDeposit.IBANCodeAsString | IBAN for wire/SEPA transfers. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 90 | InitialTransactionIDAsString | Fact_BillingDeposit.InitialTransactionIDAsString | Initial transaction ID for recurring. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 91 | IPAsString | Fact_BillingDeposit.IPAsString | Customer IP as string. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 92 | LanguageIDAsInteger | Fact_BillingDeposit.LanguageIDAsInteger | Language ID from payment data. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 93 | LastNameAsString | Fact_BillingDeposit.LastNameAsString | Cardholder/account holder last name. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 94 | MD5AsString | Fact_BillingDeposit.MD5AsString | MD5 hash from payment provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 95 | PayerAsString | Fact_BillingDeposit.PayerAsString | Payer name (PayPal/e-wallet). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 96 | PayerBusiness | Fact_BillingDeposit.PayerBusiness | Payer business name (PayPal). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 97 | PayerIDAsString | Fact_BillingDeposit.PayerIDAsString | Payer identifier string. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 98 | PayerPurseAsString | Fact_BillingDeposit.PayerPurseAsString | Payer purse/wallet ID. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 99 | PayerStatus | Fact_BillingDeposit.PayerStatus | Payer verification status. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 100 | PaymentAmountAsDecimal | Fact_BillingDeposit.PaymentAmountAsDecimal | Amount from payment XML. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 101 | PaymentDateAsDateTime | Fact_BillingDeposit.PaymentDateAsDateTime | Payment date from XML. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 102 | PaymentGuaranteeAsString | Fact_BillingDeposit.PaymentGuaranteeAsString | Payment guarantee code. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 103 | PaymentModeAsInteger | Fact_BillingDeposit.PaymentModeAsInteger | Payment processing mode. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 104 | PaymentProviderTransactionStatusAsString | Fact_BillingDeposit.PaymentProviderTransactionStatusAsString | Status string from provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 105 | PaymentStatusAsInteger | Fact_BillingDeposit.PaymentStatusAsInteger | Status integer from provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 106 | PaymentTypeAsString | Fact_BillingDeposit.PaymentTypeAsString | Payment type label from provider. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 107 | PlaidItemIDAsString | Fact_BillingDeposit.PlaidItemIDAsString | Plaid (ACH) item identifier. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 108 | PlaidNamesAsString | Fact_BillingDeposit.PlaidNamesAsString | Plaid account holder names. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 109 | PlatformIDAsInteger | Fact_BillingDeposit.PlatformIDAsInteger | Platform from payment XML (separate from PlatformID). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 110 | PromotionCodeAsString | Fact_BillingDeposit.PromotionCodeAsString | Promotion/voucher code used. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 111 | PSPCodeAsString | Fact_BillingDeposit.PSPCodeAsString | Payment service provider code. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 112 | RapidFirstNameAsString | Fact_BillingDeposit.RapidFirstNameAsString | Rapid (payout) first name. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 113 | RapidLastNameAsString | Fact_BillingDeposit.RapidLastNameAsString | Rapid (payout) last name. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 114 | ResponseMessageAsString | Fact_BillingDeposit.ResponseMessageAsString | Provider response message. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 115 | ResponseTimeAsString | Fact_BillingDeposit.ResponseTimeAsString | Provider response time. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 116 | SecretKeyAsString | Fact_BillingDeposit.SecretKeyAsString | Provider secret key (masked/reference). XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 117 | ThreeDsAsJson | Fact_BillingDeposit.ThreeDsAsJson | Raw 3DS authentication data as JSON string. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 118 | ThreeDsResponseType | Fact_BillingDeposit.ThreeDsResponseType | 3DS outcome ID as string. Cast to INT to JOIN Dim_ThreeDsResponseTypes. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 119 | TokenAsString | Fact_BillingDeposit.TokenAsString | Payment token from tokenization service. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 120 | TransactionIDAsString | Fact_BillingDeposit.TransactionIDAsString | Provider transaction ID string. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 121 | ZipCodeAsString | Fact_BillingDeposit.ZipCodeAsString | Billing postal/ZIP code. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 122 | MOPCountry | Fact_BillingDeposit.MOPCountry | Method-of-Payment country code. XML-extracted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |

## 4. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| NOLOCK hint | Medium | Uses `WITH (NOLOCK)` — may read uncommitted billing records |
| RemoveSpecialChars UDF | Low | Scalar UDF may impact performance on large exports — consider inline TVF if performance is an issue |
| Column `v` | Low | Ambiguous single-letter column name — appears to be a billing detail field processed through RemoveSpecialChars |
| Commented-out JSON | Info | `FOR JSON PATH, WITHOUT_ARRAY_WRAPPER` is commented out — view was possibly designed for JSON export originally |

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | Documents Fact Billing Deposit grain (CID, deposit time, modification date) and usage notes |
| [DWH User Guide](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11604167900) | DWH diagrams include fact-billing deposit/withdraw pipelines |
| [Mimo Terms Explanations - Deposit / Withdraw](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11478827085) | Billing service / withdraw status terminology aligned with deposit fact detail fields |

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Column expansion: 122 cols documented individually (all Tier 1 from Fact_BillingDeposit wiki)*
*Tiers: 122 T1, 0 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.VU_FactBilling_ForBigQuery | Type: View | Base: Fact_BillingDeposit WITH(NOLOCK) | 82 cols sanitized via RemoveSpecialChars*
