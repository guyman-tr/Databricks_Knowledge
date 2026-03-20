# Column Lineage: DWH_dbo.Fact_BillingDeposit

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_BillingDeposit` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Billing.Deposit` (`etoro`) |
| **Secondary Sources** | `Billing.Funding` (JOIN on FundingID), `Billing.RecurringDeposit` (OUTER APPLY), `DWH_dbo.Fact_CustomerAction` (2nd-pass UPDATE) |
| **ETL SP** | `DWH_dbo.SP_Fact_BillingDeposit_DL_To_Synapse` (+ 2nd pass: `SP_Fact_BillingDeposit @Yesterday`) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Billing.Deposit (etoroDB-REAL — core deposit ledger)
  + etoro.Billing.Funding (payment instrument metadata)
  + etoro.Billing.RecurringDeposit (recurring schedule)
  |
  v [Generic Pipeline — daily, 1440 min, Override]
Bronze/etoro/Billing/Deposit/
  |
  v [staging]
DWH_staging.etoro_Billing_Deposit
DWH_staging.etoro_Billing_Funding
DWH_staging.etoro_Billing_RecurringDeposit
  |
  v [SP_Fact_BillingDeposit_DL_To_Synapse — Pass 1]
    1. DELETE Ext_FBD_Fact_BillingDeposit (rolling window by ModificationDateID)
    2. INSERT Ext_FBD from staging (multi-source JOIN + ~91 ExtractXMLValue calls)
    3. DELETE Fact_BillingDeposit (same window)
    4. INSERT Fact_BillingDeposit from Ext_FBD
  |
  v [SP_Fact_BillingDeposit @Yesterday — Pass 2]
    UPDATE PlatformID via Fact_CustomerAction (SessionID JOIN, ActionTypeID=14)
DWH_dbo.Fact_BillingDeposit (73.9M rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |
| **passthrough (capped)** | Column copied with CASE expression cap applied. |
| **ETL-computed** | Derived/calculated by ETL SP. |
| **XML-extracted** | Extracted from XML blob via ExtractXMLValue UDF. |
| **2nd-pass UPDATE** | Set by a second SP execution after main load. |
| **JOIN** | Value fetched from a secondary source table via JOIN. |
| **OUTER APPLY** | Value fetched from a secondary source via OUTER APPLY (NULL if no match). |

### Core Deposit Identifiers & Status (from Billing.Deposit)

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DepositID | Billing.Deposit | DepositID | passthrough | HASH distribution key + CLUSTERED index |
| CID | Billing.Deposit | CID | passthrough | |
| PaymentStatusID | Billing.Deposit | PaymentStatusID | passthrough | NC index key |
| IsFTD | Billing.Deposit | IsFTD | passthrough | DWH stores as int, production as bit |
| PaymentDate | Billing.Deposit | PaymentDate | passthrough | |
| ModificationDate | Billing.Deposit | ModificationDate | passthrough | |
| RiskManagementStatusID | Billing.Deposit | RiskManagementStatusID | passthrough | |
| MatchStatusID | Billing.Deposit | MatchStatusID | passthrough | |

### Amount & Currency (from Billing.Deposit)

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Amount | Billing.Deposit | Amount | passthrough (capped) | CASE cap applied as of 2025-04-17 |
| CurrencyID | Billing.Deposit | CurrencyID | passthrough | |
| ExchangeRate | Billing.Deposit | ExchangeRate | passthrough | |
| BaseExchangeRate | Billing.Deposit | BaseExchangeRate | passthrough | |
| ExchangeFee | Billing.Deposit | ExchangeFee | passthrough | |
| Commission | Billing.Deposit | Commission | passthrough | |
| AmountUSD | — | — | ETL-computed | Amount × ExchangeRate, computed in SP |

### Payment Instrument & Routing (from Billing.Deposit + Billing.Funding)

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| FundingID | Billing.Deposit | FundingID | passthrough | JOIN key to Billing.Funding |
| FundingTypeID | Billing.Funding | FundingTypeID | JOIN | Via FundingID |
| DepotID | Billing.Deposit | DepotID | passthrough | |
| ProtocolMIDSettingsID | Billing.Deposit | ProtocolMIDSettingsID | passthrough | |
| MerchantAccountID | Billing.Deposit | MerchantAccountID | passthrough | |
| RoutingReasonID | Billing.Deposit | RoutingReasonID | passthrough | |
| ProcessRegulationID | Billing.Deposit | ProcessRegulationID | passthrough | |
| FlowID | Billing.Deposit | FlowID | passthrough | |

### Identifiers & Timestamps

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Approved | Billing.Deposit | Approved | passthrough | Legacy flag, mostly NULL |
| ProcessorValueDate | Billing.Deposit | ProcessorValueDate | passthrough | |
| ClearingHouseEffectiveDate | Billing.Deposit | ClearingHouseEffectiveDate | passthrough | |
| ExTransactionID | Billing.Deposit | ExTransactionID | passthrough | |
| RefundVerificationCode | Billing.Deposit | RefundVerificationCode | passthrough | |
| IPAddress | Billing.Deposit | IPAddress | passthrough | |
| SessionID | Billing.Deposit | SessionID | passthrough | Key for 2nd-pass PlatformID enrichment |
| ManagerID | Billing.Deposit | ManagerID | passthrough | |
| FunnelID | Billing.Deposit | FunnelID | passthrough | |
| PaymentGeneration | Billing.Deposit | PaymentGeneration | passthrough | |
| ModificationDateID | Billing.Deposit | ModificationDate | ETL-computed | CONVERT(INT, CONVERT(varchar(8), ModificationDate, 112)) → YYYYMMDD |
| ExpirationDateID | Billing.Deposit | PaymentData (XML) | ETL-computed | Complex formula from ExpirationDateAsString; card expiry as YYYYMMDD |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution |

### Bonus & Campaign (from Billing.Deposit)

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| BonusStatusID | Billing.Deposit | BonusStatusID | passthrough | |
| BonusAmount | Billing.Deposit | BonusAmount | passthrough | |
| BonusErrorCode | Billing.Deposit | BonusErrorCode | passthrough | |

### Platform, Recurring & Billing.Deposit misc (DWH-enriched)

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PlatformID | Fact_CustomerAction | PlatformID | 2nd-pass UPDATE | Match: SessionID + ActionTypeID=14; NULL if no match |
| IsRecurring | Billing.RecurringDeposit | — | OUTER APPLY | 1 if match exists; 0 otherwise |
| IsSetBalanceCompleted | Billing.Deposit | IsSetBalanceCompleted | passthrough | |

### Funding Instrument Metadata (from Billing.Funding)

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| IsRefundExcluded | Billing.Funding | IsRefundExcluded | JOIN | Via FundingID |
| DocumentRequired | Billing.Funding | DocumentRequired | JOIN | Via FundingID |
| IsAftSupportedAsBool | Billing.Funding | IsAftSupported | JOIN | Cast to bit |
| IsAftEligibleAsBool | Billing.Funding | IsAftEligible | JOIN | Cast to bit |
| IsAftProcessedAsBool | Billing.Funding | IsAftProcessed | JOIN | Cast to bit; may also read Billing.Deposit for some records |

### XML-Extracted Payment Data Columns (~91 Columns — from Billing.Deposit.PaymentData / FundingData)

All columns in this group are extracted using `ExtractXMLValue(d.PaymentData, 'AttributeName')` or `ExtractXMLValue(d.FundingData, 'AttributeName')`. Transform = **XML-extracted** for all. Source column = PaymentData or FundingData XML blob.

| DWH Column | XML Attribute | Notes |
|-----------|---------------|-------|
| SecuredCardDataAsString | SecuredCardData | Tokenized card reference |
| BinCodeAsString | BinCode | Card BIN |
| BinCountryIDAsInteger | BinCountryID | int type |
| CardTypeIDAsInteger | CardTypeID | int type |
| CountryIDAsInteger | CountryID | int type |
| StateIDAsInteger | StateID | int type |
| BankIDAsInteger | BankID | int type |
| AccountNameAsString | AccountName | |
| AccountTypeAsString | AccountType | |
| BankAccountAsString | BankAccount | Masked |
| BankAddressAsString | BankAddress | |
| BankCodeAsDecimal | BankCode | Numeric string |
| BankDetailsAccountIDAsString | BankDetailsAccountID | |
| BankIDAsString | BankID | String form |
| BankNameAsString | BankName | |
| BICCodeAsString | BICCode | SWIFT/BIC |
| CIDAsString | CID | XML cross-check |
| v | (unnamed) | Artifact — no descriptive attribute name |
| CustomerAddressAsString | CustomerAddress | |
| CustomerNameAsString | CustomerName | |
| FundingType | FundingType | Label from XML |
| MaskedAccountIDAsString | MaskedAccountID | |
| PurseAsString | Purse | E-wallet purse |
| RoutingNumberAsString | RoutingNumber | US ACH |
| SecureIDAsDecimal | SecureID | Numeric string |
| SortCodeAsString | SortCode | UK sort code |
| AccountBalanceAsDecimal | AccountBalance | |
| AccountHolderAsString | AccountHolder | |
| AccountIDAsDecimal | AccountID | Numeric string |
| ACHBankAccountIDAsInteger | ACHBankAccountID | int type |
| Address1AsString | Address1 | |
| Address2AsString | Address2 | |
| AdviseAsString | Advise | Provider message |
| AvailableBalanceAsDecimal | AvailableBalance | |
| BankCodeAsString | BankCode | String form |
| BillNumberAsString | BillNumber | |
| BuildingNumberAsString | BuildingNumber | |
| CardHolderPhoneNumberBodyAsString | CardHolderPhoneNumberBody | |
| CardHolderPhoneNumberPrefixAsString | CardHolderPhoneNumberPrefix | |
| CardNumberAsString | CardNumber | Masked |
| CityAsString | City | |
| CountryIDAsString | CountryID | String form |
| CountryNameAsString | CountryName | |
| CreatedAtAsString | CreatedAt | |
| CurrentBalanceAsDecimal | CurrentBalance | |
| CustomerIDAsString | CustomerID | |
| EmailAsString | Email | |
| EndPointIDAsString | EndPointID | |
| ErrorCodeAsString | ErrorCode | |
| ErrorTypeAsString | ErrorType | |
| FirstNameAsString | FirstName | |
| IBANCodeAsString | IBANCode | |
| InitialTransactionIDAsString | InitialTransactionID | Recurring |
| IPAsString | IP | |
| LanguageIDAsInteger | LanguageID | int type |
| LastNameAsString | LastName | |
| MD5AsString | MD5 | |
| PayerAsString | Payer | PayPal/e-wallet |
| PayerBusiness | PayerBusiness | |
| PayerIDAsString | PayerID | |
| PayerPurseAsString | PayerPurse | |
| PayerStatus | PayerStatus | |
| PaymentAmountAsDecimal | PaymentAmount | |
| PaymentDateAsDateTime | PaymentDate | nvarchar(max) despite name |
| PaymentGuaranteeAsString | PaymentGuarantee | |
| PaymentModeAsInteger | PaymentMode | int type |
| PaymentProviderTransactionStatusAsString | PaymentProviderTransactionStatus | |
| PaymentStatusAsInteger | PaymentStatus | int type |
| PaymentTypeAsString | PaymentType | |
| PlaidItemIDAsString | PlaidItemID | |
| PlaidNamesAsString | PlaidNames | |
| PlatformIDAsInteger | PlatformID | int type; separate from DWH PlatformID column |
| PromotionCodeAsString | PromotionCode | |
| PSPCodeAsString | PSPCode | |
| RapidFirstNameAsString | RapidFirstName | |
| RapidLastNameAsString | RapidLastName | |
| ResponseMessageAsString | ResponseMessage | |
| ResponseTimeAsString | ResponseTime | |
| SecretKeyAsString | SecretKey | Masked/reference |
| ThreeDsAsJson | ThreeDsAsJson | Raw JSON string |
| ThreeDsResponseType | ThreeDsResponseType | Cast to INT for Dim_ThreeDsResponseTypes JOIN |
| TokenAsString | Token | |
| TransactionIDAsString | TransactionID | |
| ZipCodeAsString | ZipCode | |
| MOPCountry | MOPCountry | Method-of-Payment country |
| SwiftCodeAsString | SwiftCode | |
| ClientBankNameAsString | ClientBankName | |
| BankName | BankName | varchar(100), not nvarchar(max) |
| CardCategory | CardCategory | varchar(50), not nvarchar(max) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough (Billing.Deposit)** | 34 |
| **Passthrough with cap (Billing.Deposit)** | 1 (Amount) |
| **JOIN from Billing.Funding** | 6 |
| **OUTER APPLY from Billing.RecurringDeposit** | 1 |
| **ETL-computed** | 4 (AmountUSD, ModificationDateID, ExpirationDateID, UpdateDate) |
| **2nd-pass UPDATE (Fact_CustomerAction)** | 1 (PlatformID) |
| **XML-extracted (PaymentData / FundingData)** | ~91 |
| **Total** | ~138 |
