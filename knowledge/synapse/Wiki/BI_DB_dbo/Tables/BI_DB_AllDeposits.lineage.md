# BI_DB_dbo.BI_DB_AllDeposits — Column Lineage

> Source trace for all 126 columns. Primary source: DWH_dbo.Fact_BillingDeposit (passthrough of etoro.Billing.Deposit XML-extracted + core fields). Dim-resolved text columns derived by SP_AllDeposits via 15 DWH dimension JOINs.

| Column | Source Table | Source Column | Transform |
|--------|-------------|---------------|-----------|
| CID | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CID | Passthrough |
| DepositID | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | DepositID | Passthrough |
| FundingType | DWH_dbo.Dim_FundingType | Name | JOIN on Fact_BillingDeposit.FundingTypeID |
| Amount In Orig Curr | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | Amount | Passthrough (money → money) |
| Amount in $ | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | Amount × ExchangeRate | Computed: Amount * ExchangeRate |
| Currency | DWH_dbo.Dim_Currency | Abbreviation | JOIN on Fact_BillingDeposit.CurrencyID |
| ModificationDate | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ModificationDate | Passthrough |
| Deposit Time | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentDate | Alias rename |
| Month | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ModificationDate | MONTH(ModificationDate) |
| Day | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ModificationDate | DAY(ModificationDate) |
| Year | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ModificationDate | YEAR(ModificationDate) |
| PaymentStatus | DWH_dbo.Dim_PaymentStatus | Name | INNER JOIN on Fact_BillingDeposit.PaymentStatusID |
| Country (customer) | DWH_dbo.Dim_Country | Name | LEFT JOIN on Dim_Customer.CountryID |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | LEFT JOIN on Deposit.CID = CC.RealCID |
| Funnel | DWH_dbo.Dim_Funnel | Name | LEFT JOIN on Fact_BillingDeposit.FunnelID |
| FunnelFrom | DWH_dbo.Dim_Funnel | Name | LEFT JOIN on Dim_Customer.FunnelFromID |
| BINCountry | DWH_dbo.Dim_Country | Name | LEFT JOIN on BinCountryIDAsInteger |
| Provider | DWH_dbo.Dim_BillingDepot | Name | LEFT JOIN on Fact_BillingDeposit.DepotID |
| CardType | DWH_dbo.Dim_CardType | CarTypeName | LEFT JOIN on CardTypeIDAsInteger |
| CardSubType | DWH_dbo.Dim_CountryBin | CardSubType | LEFT JOIN on BinCodeAsString |
| IsFTD | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | IsFTD | Passthrough (CAST to INT) |
| Country By Reg IP | DWH_dbo.Dim_Country | Name | LEFT JOIN on Dim_Customer.CountryIDByIP |
| Deposit Risk Status | DWH_dbo.Dim_RiskManagementStatus | Name | LEFT JOIN on Fact_BillingDeposit.RiskManagementStatusID |
| RiskStatus | DWH_dbo.Dim_RiskStatus | Name | LEFT JOIN on Dim_Customer.RiskStatusID |
| External Transaction ID | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ExTransactionID | Alias rename |
| Region | BI_DB_dbo.External_etoro_Dictionary_MarketingRegion | Name | LEFT JOIN on Dim_Country.MarketingRegionID |
| Affiliate ID | DWH_dbo.Dim_Customer | AffiliateID | LEFT JOIN on Deposit.CID |
| Account Manager | DWH_dbo.Dim_Manager | FirstName + LastName | LEFT JOIN on Dim_Customer.AccountManagerID; computed: FirstName + ' ' + LastName |
| BinCode | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BinCodeAsString | Implicit cast to bigint |
| Bank name by Bincode | DWH_dbo.Dim_CountryBin | IssuingBank | LEFT JOIN on BinCodeAsString |
| Regulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN on Dim_Customer.RegulationID |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN on Dim_Customer.DesignatedRegulationID |
| Category | Computed — SP logic | — | CASE: IsFTD=1→'FTD'; FirstDepositDate IS NOT NULL→'REDEPOSIT'; ELSE→'LEAD' |
| MID | BI_DB_dbo.External_etoro_Billing_ProtocolMIDSettings | Value | LEFT JOIN on Fact_BillingDeposit.ProtocolMIDSettingsID |
| UpdateDate | SP_AllDeposits | — | GETDATE() at SP execution |
| Response | BI_DB_dbo.External_etoro_Dictionary_Response | ResponseName | Via Synapse_Table_etoro_History_DepositAction → #deposit_action → #etoro_Dictionary_Response JOIN on ResponseID |
| ModificationDateID | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ModificationDate | CONVERT(VARCHAR(10), ModificationDate, 112) cast to int |
| BankCode | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankCodeAsString | Alias (renamed passthrough) |
| PSPCode | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PSPCodeAsString | Alias (renamed passthrough) |
| FundingID | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | FundingID | Passthrough (int→bigint) |
| AccountBalanceAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | AccountBalanceAsDecimal | Passthrough (XML-extracted field) |
| AccountHolderAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | AccountHolderAsString | Passthrough (XML-extracted field) |
| AccountIDAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | AccountIDAsDecimal | Passthrough (XML-extracted field) |
| ACHBankAccountIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ACHBankAccountIDAsInteger | Passthrough (XML-extracted field) |
| Address1AsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | Address1AsString | Passthrough (XML-extracted field) |
| Address2AsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | Address2AsString | Passthrough (XML-extracted field) |
| AdviseAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | AdviseAsString | Passthrough (XML-extracted field) |
| AvailableBalanceAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | AvailableBalanceAsDecimal | Passthrough (XML-extracted field) |
| BankCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankCodeAsString | Passthrough (XML-extracted field) |
| BankIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankIDAsInteger | Passthrough (XML-extracted field) |
| BillNumberAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BillNumberAsString | Passthrough (XML-extracted field) |
| BuildingNumberAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BuildingNumberAsString | Passthrough (XML-extracted field) |
| CardHolderPhoneNumberBodyAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CardHolderPhoneNumberBodyAsString | Passthrough (XML-extracted field) |
| CardHolderPhoneNumberPrefixAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CardHolderPhoneNumberPrefixAsString | Passthrough (XML-extracted field) |
| CardNumberAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CardNumberAsString | Passthrough (XML-extracted field) |
| CityAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CityAsString | Passthrough (XML-extracted field) |
| CountryIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CountryIDAsString | Passthrough (XML-extracted field) |
| CountryNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CountryNameAsString | Passthrough (XML-extracted field) |
| CreatedAtAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CreatedAtAsString | Passthrough (XML-extracted field) |
| CurrentBalanceAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CurrentBalanceAsDecimal | Passthrough (XML-extracted field) |
| CustomerIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CustomerIDAsString | Passthrough (XML-extracted field) |
| EmailAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | EmailAsString | Passthrough (XML-extracted field) |
| EndPointIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | EndPointIDAsString | Passthrough (XML-extracted field) |
| ErrorCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ErrorCodeAsString | Passthrough (XML-extracted field) |
| ErrorTypeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ErrorTypeAsString | Passthrough (XML-extracted field) |
| FirstNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | FirstNameAsString | Passthrough (XML-extracted field) |
| IBANCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | IBANCodeAsString | Passthrough (XML-extracted field) |
| InitialTransactionIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | InitialTransactionIDAsString | Passthrough (XML-extracted field) |
| IPAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | IPAsString | Passthrough (XML-extracted field) |
| LanguageIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | LanguageIDAsInteger | Passthrough (XML-extracted field) |
| LastNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | LastNameAsString | Passthrough (XML-extracted field) |
| MD5AsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | MD5AsString | Passthrough (XML-extracted field) |
| PayerAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PayerAsString | Passthrough (XML-extracted field) |
| PayerBusiness | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PayerBusiness | Passthrough (XML-extracted field) |
| PayerIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PayerIDAsString | Passthrough (XML-extracted field) |
| PayerPurseAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PayerPurseAsString | Passthrough (XML-extracted field) |
| PayerStatus | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PayerStatus | Passthrough (XML-extracted field) |
| PaymentAmountAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentAmountAsDecimal | Passthrough (XML-extracted field) |
| PaymentDateAsDateTime | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentDateAsDateTime | Passthrough (XML-extracted field) |
| PaymentGuaranteeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentGuaranteeAsString | Passthrough (XML-extracted field) |
| PaymentModeAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentModeAsInteger | Passthrough (XML-extracted field) |
| PaymentProviderTransactionStatusAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentProviderTransactionStatusAsString | Passthrough (XML-extracted field) |
| PaymentStatusAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentStatusAsInteger | Passthrough (XML-extracted field) |
| PaymentTypeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PaymentTypeAsString | Passthrough (XML-extracted field) |
| PlaidItemIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PlaidItemIDAsString | Passthrough (XML-extracted field) |
| PlaidNamesAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PlaidNamesAsString | Passthrough (XML-extracted field) |
| PlatformIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PlatformIDAsInteger | Passthrough (XML-extracted field) |
| PromotionCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PromotionCodeAsString | Passthrough (XML-extracted field) |
| PSPCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PSPCodeAsString | Passthrough — duplicate of PSPCode above (kept for API compatibility) |
| RapidFirstNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | RapidFirstNameAsString | Passthrough (XML-extracted field) |
| RapidLastNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | RapidLastNameAsString | Passthrough (XML-extracted field) |
| ResponseMessageAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ResponseMessageAsString | Passthrough (XML-extracted field) |
| ResponseTimeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ResponseTimeAsString | Passthrough (XML-extracted field) |
| SecretKeyAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | SecretKeyAsString | Passthrough (XML-extracted field) |
| ThreeDsAsJson | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ThreeDsAsJson | cast(ThreeDsAsJson AS VARCHAR(100)) — truncated to 100 chars |
| ThreeDsResponseType | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ThreeDsResponseType | Passthrough (XML-extracted field) |
| TokenAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | TokenAsString | Passthrough (XML-extracted field) |
| TransactionIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | TransactionIDAsString | Passthrough (XML-extracted field) |
| ZipCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ZipCodeAsString | Passthrough (XML-extracted field) |
| AccountIDAsString | SP_AllDeposits | — | Hardcoded NULL — always NULL |
| AccountTypeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | AccountTypeAsString | Passthrough (XML-extracted field) |
| BankAccountAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankAccountAsString | Passthrough (XML-extracted field) |
| BankAddressAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankAddressAsString | Passthrough (XML-extracted field) |
| BankCodeAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankCodeAsDecimal | Passthrough (XML-extracted field) |
| BankDetailsAccountIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankDetailsAccountIDAsString | Passthrough (XML-extracted field) |
| BankIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankIDAsString | Passthrough (XML-extracted field) |
| BankNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BankNameAsString | Passthrough (XML-extracted field) |
| BICCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BICCodeAsString | Passthrough (XML-extracted field) |
| BinCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BinCodeAsString | Passthrough — duplicate of BinCode (kept for API compatibility) |
| BinCountryIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BinCountryIDAsInteger | Passthrough (XML-extracted field) — integer ID of BIN card country |
| CardTypeIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CardTypeIDAsInteger | Passthrough (XML-extracted field) — integer ID for CardType resolution |
| CIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CIDAsString | Passthrough (XML-extracted field) |
| ClientBankNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ClientBankNameAsString | Passthrough (XML-extracted field) |
| CountryIDAsInteger | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CountryIDAsInteger | Passthrough (XML-extracted field) |
| CustomerAddressAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CustomerAddressAsString | Passthrough (XML-extracted field) |
| CustomerNameAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | CustomerNameAsString | Passthrough (XML-extracted field) |
| ExpirationDateAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | ExpirationDateAsString | Passthrough (XML-extracted field) — card expiry as raw string |
| MaskedAccountIDAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | MaskedAccountIDAsString | Passthrough (XML-extracted field) |
| PurseAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | PurseAsString | Passthrough (XML-extracted field) |
| RoutingNumberAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | RoutingNumberAsString | Passthrough (XML-extracted field) |
| SecuredCardDataAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | SecuredCardDataAsString | Passthrough (XML-extracted field) |
| SecureIDAsDecimal | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | SecureIDAsDecimal | Passthrough (XML-extracted field) |
| SortCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | SortCodeAsString | Passthrough (XML-extracted field) |
| SwiftCodeAsString | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | SwiftCodeAsString | Passthrough (XML-extracted field) |
| BaseExchangeRate | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | BaseExchangeRate | Passthrough |
| DepotID | DWH_dbo.Fact_BillingDeposit (#BillingDeposit) | DepotID | Passthrough |

## Upstream Chain

```
etoro.Billing.Deposit (production)
  |
  v [Generic Pipeline — daily]
DWH_staging.etoro_Billing_Deposit
  |
  v [SP_Fact_BillingDeposit_DL_To_Synapse — XML extraction + multi-source JOIN]
DWH_dbo.Fact_BillingDeposit (73.9M rows)
  |
  v [SP_AllDeposits @date — daily slice, 15 Dim JOINs, Category computation, PI filter]
BI_DB_dbo.BI_DB_AllDeposits
```

## Secondary Staging Chain (Response column only)

```
etoro.History.DepositAction (production)
  |
  v [SP_Create_Synapse_Table_etoro_History_DepositAction @date]
BI_DB_dbo.Synapse_Table_etoro_History_DepositAction (daily window staging)
  |
  v [SP_AllDeposits — #deposit_action dedup + #etoro_Dictionary_Response JOIN]
BI_DB_AllDeposits.Response (ResponseName for latest action per DepositID)
```

## T1 Verbatim Copy Verification Log

| Column | Upstream Wiki | Source Description (verbatim) |
|--------|--------------|-------------------------------|
| CID | DWH_dbo.Fact_BillingDeposit §4.1 | "Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer." |
| DepositID | DWH_dbo.Fact_BillingDeposit §4.1 | "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY)." |
| Amount In Orig Curr | DWH_dbo.Fact_BillingDeposit §4.2 | "Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations." |
| ModificationDate | DWH_dbo.Fact_BillingDeposit §4.1 | "UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection." |
| Deposit Time | DWH_dbo.Fact_BillingDeposit §4.1 | "UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time." |
| IsFTD | DWH_dbo.Fact_BillingDeposit §4.1 | "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type." |
| External Transaction ID | DWH_dbo.Fact_BillingDeposit §4.4 | "External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution." |
| FundingID | DWH_dbo.Fact_BillingDeposit §4.3 | "Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding." |
| BaseExchangeRate | DWH_dbo.Fact_BillingDeposit §4.2 | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019)." |
| DepotID | DWH_dbo.Fact_BillingDeposit §4.3 | "Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production." |
| [PSP payload: 83 columns] | DWH_dbo.Fact_BillingDeposit §4.8 | Passthrough of XML-extracted columns; descriptions verified against §4.8 individual entries |

*T1 count: ≥10 named columns + 83 PSP payload columns = ≥93 T1 assignments*
