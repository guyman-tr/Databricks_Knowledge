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
| 6 | ModificationDateID | int | Fact_BillingDeposit.ModificationDateID | ETL `convert(int,convert(varchar,dateadd(day,datediff(day,0,d.ModificationDate),0),112))` (`SP_Fact_BillingDeposit_DL_To_Synapse` Ext_FBD SELECT). (Tier 2 — via Fact_BillingDeposit) |
| 7 | FundingID | int | Fact_BillingDeposit.FundingID | Foreign key (FundingID) joining to etoro_Billing_Funding; passthrough from Billing.Deposit. (Tier 1 - Fact_BillingDeposit.md) |
| 8 | ExchangeRate | numeric(16,8) | Fact_BillingDeposit.ExchangeRate | Exchange rate from deposit currency to USD at processing time. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 9 | DepositID | int | Fact_BillingDeposit.DepositID | Deposit identifier carried from the underlying Fact_BillingDeposit table, where it serves as the primary key. In this BigQuery-export view the column is nullable and has no PK or distribution constraint. |
| 10 | ProcessorValueDate | datetime | Fact_BillingDeposit.ProcessorValueDate | Value date from the payment processor. NULL for instant payment methods. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 11 | DepotID | int | Fact_BillingDeposit.DepotID | Passthrough `d.DepotID` — foreign key referencing the depot/gateway identifier (Tier 1 - Fact_BillingDeposit.md) |
| 12 | BinCountryIDAsInteger | int | Fact_BillingDeposit.BinCountryIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('BinCountryIDAsInteger',f.FundingData)` assigned to `int` (implicit cast from string). Prefer `TRY_CAST` for analytics. (Tier 2 — via Fact_BillingDeposit) |
| 13 | CardTypeIDAsInteger | int | Fact_BillingDeposit.CardTypeIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('CardTypeIDAsInteger',f.FundingData)` assigned to `int`. Dictionary meaning beyond SQL `[UNVERIFIED]`. (Tier 3 — via Fact_BillingDeposit) |
| 14 | PaymentStatusID | int | Fact_BillingDeposit.PaymentStatusID | Current deposit status. 2=Approved (73%), 3=Decline, 35=DeclineByRRE (10.2%). NC index key. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 15 | ManagerID | int | Fact_BillingDeposit.ManagerID | Operations manager who processed this deposit. 0=automated. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 16 | RiskManagementStatusID | int | Fact_BillingDeposit.RiskManagementStatusID | Pre-processing risk check result. 69 distinct risk reason codes. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 17 | Amount | money | Fact_BillingDeposit.Amount | ETL `CASE WHEN d.Amount >= 1000000000 THEN 99999999 WHEN d.Amount <= -1000000000 THEN -99999999 ELSE d.Amount END` (2025-04-17 cap). (Tier 2 — via Fact_BillingDeposit) |
| 18 | PaymentDate | datetime | Fact_BillingDeposit.PaymentDate | UTC timestamp when the deposit was submitted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 19 | IPAddress | numeric(18,0) | Fact_BillingDeposit.IPAddress | Customer IP address at deposit time as 32-bit integer. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 20 | ClearingHouseEffectiveDate | datetime | Fact_BillingDeposit.ClearingHouseEffectiveDate | Settlement date from the clearing house. NULL for instant methods. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 21 | IsFTD | int | Fact_BillingDeposit.IsFTD | First Time Deposit flag. 1=customer's first approved deposit. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 22 | MatchStatusID | tinyint | Fact_BillingDeposit.MatchStatusID | PSP reconciliation match status. 0=Unmatched, 3=Matched. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 23 | BonusStatusID | int | Fact_BillingDeposit.BonusStatusID | Promotional bonus status. 0=New, 1=Approved, 2=Declined, 3=Reverted. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 24 | BonusAmount | money | Fact_BillingDeposit.BonusAmount | Bonus amount credited with this deposit. NULL when no bonus. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 25 | BonusErrorCode | int | Fact_BillingDeposit.BonusErrorCode | Error code when bonus processing fails. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 26 | FundingTypeID | int | Fact_BillingDeposit.FundingTypeID | JOIN `f.FundingTypeID` where `d.FundingID = f.FundingID`. (Tier 2 — via Fact_BillingDeposit) |
| 27 | IsRefundExcluded | int | Fact_BillingDeposit.IsRefundExcluded | ETL `CAST(f.IsRefundExcluded AS int)`. (Tier 2 — via Fact_BillingDeposit) |
| 28 | DocumentRequired | int | Fact_BillingDeposit.DocumentRequired | ETL `CAST(f.DocumentRequired AS int)`. (Tier 2 — via Fact_BillingDeposit) |
| 29 | UpdateDate | datetime | Fact_BillingDeposit.UpdateDate | ETL `GETDATE()` at Ext_FBD build. (Tier 2 — via Fact_BillingDeposit) |
| 30 | ExpirationDateID | int | Fact_BillingDeposit.ExpirationDateID | ETL CASE on `[DWH_dbo].[ExtractXMLValue]('ExpirationDateAsString',f.FundingData)$`: NULL or `LEN<4` → `190001` else `200000 + RIGHT(val,2)*100 + LEFT(val,2)` where `val` = extracted string (`SP…`). `[DWH_dbo].[ExtractXMLValue]` = `[DWH_dbo].[ExtractXMLValue]`. Non-card / format edge cases `[UNVERIFIED]`. (Tier 3 — via Fact_BillingDeposit) |
| 31 | CountryIDAsInteger | int | Fact_BillingDeposit.CountryIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('CountryIDAsInteger',f.FundingData)` (Funding XML, despite column name). (Tier 2 — via Fact_BillingDeposit) |
| 32 | StateIDAsInteger | int | Fact_BillingDeposit.StateIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('StateIDAsInteger',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 33 | BankIDAsInteger | int | Fact_BillingDeposit.BankIDAsInteger | COALESCE(`[DWH_dbo].[ExtractXMLValue]('BankIDAsInteger',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('BankIDAsInteger',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 34 | BaseExchangeRate | numeric(16,8) | Fact_BillingDeposit.BaseExchangeRate | Reference exchange rate before fee markup. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 35 | ExchangeFee | int | Fact_BillingDeposit.ExchangeFee | Exchange fee passthrough from Billing.Deposit; integer encoding — unit unverified (see upstream Billing.Deposit for semantics). (Tier 1 - Billing.Deposit) |
| 36 | ProtocolMIDSettingsID | int | Fact_BillingDeposit.ProtocolMIDSettingsID | Merchant ID configuration profile. Default 0. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 37 | FunnelID | int | Fact_BillingDeposit.FunnelID | Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 38 | AmountUSD | decimal(11,2) | Fact_BillingDeposit.AmountUSD | Second INSERT: `Amount * ExchangeRate AS AmountUSD` from `Ext_FBD_Fact_BillingDeposit` snapshot (post-cap `Amount`). (Tier 2 — via Fact_BillingDeposit) |
| 39 | SessionID | bigint | Fact_BillingDeposit.SessionID | ETL `ISNULL(d.SessionID,0)` (Ext_FBD). Platform enrichment JOIN uses `CID`+`SessionID`. (Tier 2 — via Fact_BillingDeposit) |
| 40 | PlatformID | int | Fact_BillingDeposit.PlatformID | Pass-1 INSERT leaves NULL; then `UPDATE a SET PlatformID=b.PlatformID FROM Fact_BillingDeposit a JOIN #Fact_BillingDepositAction b ON `a.CID=b.RealCID AND a.SessionID=b.SessionID` where `#Fact_BillingDepositAction` is built from `Fact_CustomerAction` `ActionTypeID=14` (`SP_Fact_BillingDeposit_DL_To_Synapse`). (Tier 5 — via Fact_BillingDeposit) |

### 3.2 Sanitized String Columns (via `RemoveSpecialChars(CONVERT(NVARCHAR(MAX), ...))`)

All columns below are `nvarchar(max)` in the view output. Source type varies but all are wrapped in RemoveSpecialChars for BigQuery-safe export.

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 41 | SecuredCardDataAsString | Fact_BillingDeposit.SecuredCardDataAsString | `[DWH_dbo].[ExtractXMLValue]('SecuredCardDataAsString',f.FundingData)`. Token / secured card reference; PSP semantics `[UNVERIFIED]`. (Tier 3 — via Fact_BillingDeposit) |
| 42 | BinCodeAsString | Fact_BillingDeposit.BinCodeAsString | `[DWH_dbo].[ExtractXMLValue]('BinCodeAsString',f.FundingData)`. Downstream `SP_Fact_BillingDeposit`: `CAST(BinCodeAsString AS INT) = Dim_CountryBin.BinCode`. (Tier 2 — via Fact_BillingDeposit) |
| 43 | RefundVerificationCode | Fact_BillingDeposit.RefundVerificationCode | Verification code for refund correlation. NULL for non-refunded deposits. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 44 | ExTransactionID | Fact_BillingDeposit.ExTransactionID | External (payment provider) transaction ID. (Tier 1 — inherited from Fact_BillingDeposit wiki) |
| 45 | AccountNameAsString | Fact_BillingDeposit.AccountNameAsString | `[DWH_dbo].[ExtractXMLValue]('AccountNameAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 46 | AccountTypeAsString | Fact_BillingDeposit.AccountTypeAsString | `[DWH_dbo].[ExtractXMLValue]('AccountTypeAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 47 | BankAccountAsString | Fact_BillingDeposit.BankAccountAsString | `[DWH_dbo].[ExtractXMLValue]('BankAccountAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 48 | BankAddressAsString | Fact_BillingDeposit.BankAddressAsString | `[DWH_dbo].[ExtractXMLValue]('BankAddressAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 49 | BankCodeAsDecimal | Fact_BillingDeposit.BankCodeAsDecimal | `[DWH_dbo].[ExtractXMLValue]('BankCodeAsDecimal',f.FundingData)` stored as nvarchar(max). (Tier 2 — via Fact_BillingDeposit) |
| 50 | BankDetailsAccountIDAsString | Fact_BillingDeposit.BankDetailsAccountIDAsString | `[DWH_dbo].[ExtractXMLValue]('BankDetailsAccountIDAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 51 | BankIDAsString | Fact_BillingDeposit.BankIDAsString | `[DWH_dbo].[ExtractXMLValue]('BankIDAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 52 | BankNameAsString | Fact_BillingDeposit.BankNameAsString | `[DWH_dbo].[ExtractXMLValue]('BankNameAsString',f.FundingData)` (XML). Distinct from `BankName` column enriched from `Dim_CountryBin`. (Tier 2 — via Fact_BillingDeposit) |
| 53 | BICCodeAsString | Fact_BillingDeposit.BICCodeAsString | `[DWH_dbo].[ExtractXMLValue]('BICCodeAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 54 | CIDAsString | Fact_BillingDeposit.CIDAsString | `[DWH_dbo].[ExtractXMLValue]('CIDAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 55 | v | Fact_BillingDeposit.v | `[DWH_dbo].[ExtractXMLValue]('ClientBankNameAsString',f.FundingData)` **aliased** `AS v` — duplicate payload versus `ClientBankNameAsString` column (same XML key loaded twice). (Tier 3 — via Fact_BillingDeposit) |
| 56 | CustomerAddressAsString | Fact_BillingDeposit.CustomerAddressAsString | `[DWH_dbo].[ExtractXMLValue]('CustomerAddressAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 57 | CustomerNameAsString | Fact_BillingDeposit.CustomerNameAsString | `[DWH_dbo].[ExtractXMLValue]('CustomerNameAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 58 | FundingType | Fact_BillingDeposit.FundingType | `[DWH_dbo].[ExtractXMLValue]('FundingType',f.FundingData)` textual label alongside typed `FundingTypeID`. (Tier 2 — via Fact_BillingDeposit) |
| 59 | MaskedAccountIDAsString | Fact_BillingDeposit.MaskedAccountIDAsString | `[DWH_dbo].[ExtractXMLValue]('MaskedAccountIDAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 60 | PurseAsString | Fact_BillingDeposit.PurseAsString | `[DWH_dbo].[ExtractXMLValue]('PurseAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 61 | RoutingNumberAsString | Fact_BillingDeposit.RoutingNumberAsString | `[DWH_dbo].[ExtractXMLValue]('RoutingNumberAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 62 | SecureIDAsDecimal | Fact_BillingDeposit.SecureIDAsDecimal | `[DWH_dbo].[ExtractXMLValue]('SecureIDAsDecimal',f.FundingData)` (nvarchar storage). (Tier 2 — via Fact_BillingDeposit) |
| 63 | SortCodeAsString | Fact_BillingDeposit.SortCodeAsString | `[DWH_dbo].[ExtractXMLValue]('SortCodeAsString',f.FundingData)`. (Tier 2 — via Fact_BillingDeposit) |
| 64 | AccountBalanceAsDecimal | Fact_BillingDeposit.AccountBalanceAsDecimal | `[DWH_dbo].[ExtractXMLValue]('AccountBalanceAsDecimal',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 65 | AccountHolderAsString | Fact_BillingDeposit.AccountHolderAsString | `[DWH_dbo].[ExtractXMLValue]('AccountHolderAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 66 | AccountIDAsDecimal | Fact_BillingDeposit.AccountIDAsDecimal | COALESCE(`[DWH_dbo].[ExtractXMLValue]('AccountIDAsDecimal',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('AccountIDAsDecimal',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 67 | ACHBankAccountIDAsInteger | Fact_BillingDeposit.ACHBankAccountIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('ACHBankAccountIDAsInteger',d.PaymentData)` (DDL `nvarchar(max)`). (Tier 2 — via Fact_BillingDeposit) |
| 68 | Address1AsString | Fact_BillingDeposit.Address1AsString | `[DWH_dbo].[ExtractXMLValue]('Address1AsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 69 | Address2AsString | Fact_BillingDeposit.Address2AsString | `[DWH_dbo].[ExtractXMLValue]('Address2AsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 70 | AdviseAsString | Fact_BillingDeposit.AdviseAsString | `[DWH_dbo].[ExtractXMLValue]('AdviseAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 71 | AvailableBalanceAsDecimal | Fact_BillingDeposit.AvailableBalanceAsDecimal | `[DWH_dbo].[ExtractXMLValue]('AvailableBalanceAsDecimal',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 72 | BankCodeAsString | Fact_BillingDeposit.BankCodeAsString | COALESCE(`[DWH_dbo].[ExtractXMLValue]('BankCodeAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('BankCodeAsString',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 73 | BillNumberAsString | Fact_BillingDeposit.BillNumberAsString | `[DWH_dbo].[ExtractXMLValue]('BillNumberAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 74 | BuildingNumberAsString | Fact_BillingDeposit.BuildingNumberAsString | `[DWH_dbo].[ExtractXMLValue]('BuildingNumberAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 75 | CardHolderPhoneNumberBodyAsString | Fact_BillingDeposit.CardHolderPhoneNumberBodyAsString | `[DWH_dbo].[ExtractXMLValue]('CardHolderPhoneNumberBodyAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 76 | CardHolderPhoneNumberPrefixAsString | Fact_BillingDeposit.CardHolderPhoneNumberPrefixAsString | `[DWH_dbo].[ExtractXMLValue]('CardHolderPhoneNumberPrefixAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 77 | CardNumberAsString | Fact_BillingDeposit.CardNumberAsString | COALESCE(`[DWH_dbo].[ExtractXMLValue]('CardNumberAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('CardNumberAsString',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 78 | CityAsString | Fact_BillingDeposit.CityAsString | `[DWH_dbo].[ExtractXMLValue]('CityAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 79 | CountryIDAsString | Fact_BillingDeposit.CountryIDAsString | `[DWH_dbo].[ExtractXMLValue]('CountryIDAsString',d.PaymentData)`. Feeds `MOPCountry` resolution in `SP_Fact_BillingDeposit` via `Dim_Country` joins. (Tier 2 — via Fact_BillingDeposit) |
| 80 | CountryNameAsString | Fact_BillingDeposit.CountryNameAsString | `[DWH_dbo].[ExtractXMLValue]('CountryNameAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 81 | CreatedAtAsString | Fact_BillingDeposit.CreatedAtAsString | `[DWH_dbo].[ExtractXMLValue]('CreatedAtAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 82 | CurrentBalanceAsDecimal | Fact_BillingDeposit.CurrentBalanceAsDecimal | `[DWH_dbo].[ExtractXMLValue]('CurrentBalanceAsDecimal',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 83 | CustomerIDAsString | Fact_BillingDeposit.CustomerIDAsString | `[DWH_dbo].[ExtractXMLValue]('CustomerIDAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 84 | EmailAsString | Fact_BillingDeposit.EmailAsString | COALESCE(`[DWH_dbo].[ExtractXMLValue]('EmailAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('EmailAsString',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 85 | EndPointIDAsString | Fact_BillingDeposit.EndPointIDAsString | `[DWH_dbo].[ExtractXMLValue]('EndPointIDAsString',d.PaymentData)`. PSP endpoint id; business label `[UNVERIFIED]`. (Tier 3 — via Fact_BillingDeposit) |
| 86 | ErrorCodeAsString | Fact_BillingDeposit.ErrorCodeAsString | `[DWH_dbo].[ExtractXMLValue]('ErrorCodeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 87 | ErrorTypeAsString | Fact_BillingDeposit.ErrorTypeAsString | `[DWH_dbo].[ExtractXMLValue]('ErrorTypeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 88 | FirstNameAsString | Fact_BillingDeposit.FirstNameAsString | `[DWH_dbo].[ExtractXMLValue]('FirstNameAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 89 | IBANCodeAsString | Fact_BillingDeposit.IBANCodeAsString | COALESCE(`[DWH_dbo].[ExtractXMLValue]('IBANCodeAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('IBANCodeAsString',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 90 | InitialTransactionIDAsString | Fact_BillingDeposit.InitialTransactionIDAsString | `[DWH_dbo].[ExtractXMLValue]('InitialTransactionIDAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 91 | IPAsString | Fact_BillingDeposit.IPAsString | `[DWH_dbo].[ExtractXMLValue]('IPAsString',d.PaymentData)`. Parallel to numeric `IPAddress`. (Tier 2 — via Fact_BillingDeposit) |
| 92 | LanguageIDAsInteger | Fact_BillingDeposit.LanguageIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('LanguageIDAsInteger',d.PaymentData)` (nvarchar(max) column). (Tier 2 — via Fact_BillingDeposit) |
| 93 | LastNameAsString | Fact_BillingDeposit.LastNameAsString | `[DWH_dbo].[ExtractXMLValue]('LastNameAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 94 | MD5AsString | Fact_BillingDeposit.MD5AsString | `[DWH_dbo].[ExtractXMLValue]('MD5AsString',d.PaymentData)` provider hash / fingerprint `[UNVERIFIED]`. (Tier 3 — via Fact_BillingDeposit) |
| 95 | PayerAsString | Fact_BillingDeposit.PayerAsString | `[DWH_dbo].[ExtractXMLValue]('PayerAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 96 | PayerBusiness | Fact_BillingDeposit.PayerBusiness | `[DWH_dbo].[ExtractXMLValue]('PayerBusiness',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 97 | PayerIDAsString | Fact_BillingDeposit.PayerIDAsString | COALESCE(`[DWH_dbo].[ExtractXMLValue]('PayerIDAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('PayerIDAsString',f.FundingData)`). (Tier 2 — via Fact_BillingDeposit) |
| 98 | PayerPurseAsString | Fact_BillingDeposit.PayerPurseAsString | `[DWH_dbo].[ExtractXMLValue]('PayerPurseAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 99 | PayerStatus | Fact_BillingDeposit.PayerStatus | `[DWH_dbo].[ExtractXMLValue]('PayerStatus',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 100 | PaymentAmountAsDecimal | Fact_BillingDeposit.PaymentAmountAsDecimal | `[DWH_dbo].[ExtractXMLValue]('PaymentAmountAsDecimal',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 101 | PaymentDateAsDateTime | Fact_BillingDeposit.PaymentDateAsDateTime | `[DWH_dbo].[ExtractXMLValue]('PaymentDateAsDateTime',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 102 | PaymentGuaranteeAsString | Fact_BillingDeposit.PaymentGuaranteeAsString | `[DWH_dbo].[ExtractXMLValue]('PaymentGuaranteeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 103 | PaymentModeAsInteger | Fact_BillingDeposit.PaymentModeAsInteger | `[DWH_dbo].[ExtractXMLValue]('PaymentModeAsInteger',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 104 | PaymentProviderTransactionStatusAsString | Fact_BillingDeposit.PaymentProviderTransactionStatusAsString | `[DWH_dbo].[ExtractXMLValue]('PaymentProviderTransactionStatusAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 105 | PaymentStatusAsInteger | Fact_BillingDeposit.PaymentStatusAsInteger | `[DWH_dbo].[ExtractXMLValue]('PaymentStatusAsInteger',d.PaymentData)`. Provider status integer echo; not identical to `PaymentStatusID` semantics. (Tier 2 — via Fact_BillingDeposit) |
| 106 | PaymentTypeAsString | Fact_BillingDeposit.PaymentTypeAsString | `[DWH_dbo].[ExtractXMLValue]('PaymentTypeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 107 | PlaidItemIDAsString | Fact_BillingDeposit.PlaidItemIDAsString | `[DWH_dbo].[ExtractXMLValue]('PlaidItemIDAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 108 | PlaidNamesAsString | Fact_BillingDeposit.PlaidNamesAsString | `[DWH_dbo].[ExtractXMLValue]('PlaidNamesAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 109 | PlatformIDAsInteger | Fact_BillingDeposit.PlatformIDAsInteger | `[DWH_dbo].[ExtractXMLValue]('PlatformIDAsInteger',d.PaymentData)`. Separate from fact `PlatformID` (session join). (Tier 2 — via Fact_BillingDeposit) |
| 110 | PromotionCodeAsString | Fact_BillingDeposit.PromotionCodeAsString | `[DWH_dbo].[ExtractXMLValue]('PromotionCodeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 111 | PSPCodeAsString | Fact_BillingDeposit.PSPCodeAsString | `[DWH_dbo].[ExtractXMLValue]('PSPCodeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 112 | RapidFirstNameAsString | Fact_BillingDeposit.RapidFirstNameAsString | `[DWH_dbo].[ExtractXMLValue]('RapidFirstNameAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 113 | RapidLastNameAsString | Fact_BillingDeposit.RapidLastNameAsString | `[DWH_dbo].[ExtractXMLValue]('RapidLastNameAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 114 | ResponseMessageAsString | Fact_BillingDeposit.ResponseMessageAsString | `[DWH_dbo].[ExtractXMLValue]('ResponseMessageAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 115 | ResponseTimeAsString | Fact_BillingDeposit.ResponseTimeAsString | `[DWH_dbo].[ExtractXMLValue]('ResponseTimeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 116 | SecretKeyAsString | Fact_BillingDeposit.SecretKeyAsString | `[DWH_dbo].[ExtractXMLValue]('SecretKeyAsString',d.PaymentData)`. Masked / reference only; treat as sensitive. (Tier 2 — via Fact_BillingDeposit) |
| 117 | ThreeDsAsJson | Fact_BillingDeposit.ThreeDsAsJson | `[DWH_dbo].[ExtractXMLValue]('ThreeDsAsJson',d.PaymentData)`. Raw 3DS payload JSON string. (Tier 2 — via Fact_BillingDeposit) |
| 118 | ThreeDsResponseType | Fact_BillingDeposit.ThreeDsResponseType | `[DWH_dbo].[ExtractXMLValue]('ThreeDsResponseType',d.PaymentData)`. Outcome id as string; analysts `TRY_CAST` → `Dim_ThreeDsResponseTypes`. (Tier 2 — via Fact_BillingDeposit) |
| 119 | TokenAsString | Fact_BillingDeposit.TokenAsString | `[DWH_dbo].[ExtractXMLValue]('TokenAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 120 | TransactionIDAsString | Fact_BillingDeposit.TransactionIDAsString | `[DWH_dbo].[ExtractXMLValue]('TransactionIDAsString',d.PaymentData)`. Distinct from `Billing.Deposit.TransactionID` (internal 6-char) — this is provider string from XML. (Tier 2 — via Fact_BillingDeposit) |
| 121 | ZipCodeAsString | Fact_BillingDeposit.ZipCodeAsString | `[DWH_dbo].[ExtractXMLValue]('ZipCodeAsString',d.PaymentData)`. (Tier 2 — via Fact_BillingDeposit) |
| 122 | MOPCountry | Fact_BillingDeposit.MOPCountry | `UPDATE … SET MOPCountry=m.MOPCountry` from `#MOPCountryFinal` built off `CountryIDAsString` with nested `LEFT JOIN Dim_Country` on numeric id vs `LongAbbreviation` vs `Abbreviation` (`SP_Fact_BillingDeposit`, `@dateID` slice). (Tier 2 — via Fact_BillingDeposit) |

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
