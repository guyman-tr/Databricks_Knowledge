# Function_Revenue_ConversionFee_WithPositionData

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 67 (T1: 62, T2: 5) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Same grain as `Function_Revenue_ConversionFee`: **ConversionFee** = **PIPsCalculation** with **DateID BETWEEN @sdateInt AND @edateInt** (plus snapshot `Dim_Range` join). Adds **position-level attributes** for IBAN-linked flows via **BI_DB_Positions_Opened_From_IBAN** / **BI_DB_Positions_Closed_To_IBAN**, then **Dim_Position** / **Dim_Instrument**, and **ExecutionIBANTradeSuccess** when IBAN trade rows lack a resolved position.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_DepositWithdrawFee | BI_DB_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Fact_BillingDeposit | DWH_dbo |
| Fact_BillingWithdraw | DWH_dbo |
| BI_DB_Positions_Opened_From_IBAN | BI_DB_dbo |
| BI_DB_Positions_Closed_To_IBAN | BI_DB_dbo |
| Dim_Position | DWH_dbo |
| Dim_Instrument | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | BI_DB_DepositWithdrawFee.CID | Internal customer id (**RealCID**) from deposit or cashout state. (Tier 2 -SP_DepositWithdrawFee, Fact_Deposit_State.CID / Fact_Cashout_State.CID) (via BI_DB_DepositWithdrawFee) | T2 |
| 2 | ConversionFee | BI_DB_DepositWithdrawFee.PIPsCalculation | PIPsCalculation AS ConversionFee WHERE DateID BETWEEN @sdateInt AND @edateInt (and snapshot DateRange join) | T2 |
| 3 | TransactionType | BI_DB_DepositWithdrawFee.TransactionType | Type string from state (**Deposit**, **Withdraw**, chargebacks, refunds, rollbacks, etc.). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.TransactionType) (via BI_DB_DepositWithdrawFee) | T2 |
| 4 | IsIBANTrade | BI_DB_DepositWithdrawFee.IsIBANTrade | **1** when deposit **FlowID** = 1 or withdraw **FlowID** = 2 on billing fact. (Tier 2 -SP_DepositWithdrawFee, Fact_BillingDeposit.FlowID / Fact_BillingWithdraw.FlowID) (via BI_DB_DepositWithdrawFee) | T2 |
| 5 | DateID | BI_DB_DepositWithdrawFee.DateID | Business date as **YYYYMMDD** for the load (**@StartDateID**). (Tier 2 -SP_DepositWithdrawFee, @StartDateID) (via BI_DB_DepositWithdrawFee) | T2 |
| 6 | TransactionID | BI_DB_DepositWithdrawFee.TransactionID | CAST(LEFT(TransactionID, LEN(TransactionID) - 1) AS INT) | T2 |
| 7 | PaymentMethod | BI_DB_DepositWithdrawFee.PaymentMethod | Funding type name (**Dim_FundingType.Name**). (Tier 2 -SP_DepositWithdrawFee, Dim_FundingType.Name) (via BI_DB_DepositWithdrawFee) | T2 |
| 8 | Amount | BI_DB_DepositWithdrawFee.Amount | Transaction amount in original currency; **ABS** at insert then signed via **#amountDirections** (and edge-case **UPDATE**). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.Amount) (via BI_DB_DepositWithdrawFee) | T2 |
| 9 | Currency | BI_DB_DepositWithdrawFee.Currency | Currency code (**Dim_Currency.Abbreviation**). (Tier 2 -SP_DepositWithdrawFee, Dim_Currency.Abbreviation) (via BI_DB_DepositWithdrawFee) | T2 |
| 10 | AmountUSD | BI_DB_DepositWithdrawFee.AmountUSD | USD amount; **ABS** at insert then signed like **Amount**. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.AmountInUSD) (via BI_DB_DepositWithdrawFee) | T2 |
| 11 | ExchangeRate | BI_DB_DepositWithdrawFee.ExchangeRate | FX rate on the state row. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.ExchangeRate) (via BI_DB_DepositWithdrawFee) | T2 |
| 12 | BaseExchangeRate | BI_DB_DepositWithdrawFee.BaseExchangeRate | Base FX rate from state. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.BaseExchangeRate) (via BI_DB_DepositWithdrawFee) | T2 |
| 13 | Depot | BI_DB_DepositWithdrawFee.Depot | Billing depot name (**Dim_BillingDepot**). (Tier 2 -SP_DepositWithdrawFee, Dim_BillingDepot.Name) (via BI_DB_DepositWithdrawFee) | T2 |
| 14 | MIDValue | BI_DB_DepositWithdrawFee.MIDValue | Merchant id value on the state row (**MID**). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.MID) (via BI_DB_DepositWithdrawFee) | T2 |
| 15 | IsRecurring | Fact_BillingDeposit.IsRecurring | Direct (LEFT JOIN on DepositID when TransactionType = 'Deposit') | T2 |
| 16 | GCID | Fact_SnapshotCustomer.GCID | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 17 | CountryID | Fact_SnapshotCustomer.CountryID | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 18 | LabelID | Fact_SnapshotCustomer.LabelID | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 19 | LanguageID | Fact_SnapshotCustomer.LanguageID | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 20 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 21 | DocsOK | Fact_SnapshotCustomer.DocsOK | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 22 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 23 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 24 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 25 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 26 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 27 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 28 | Evangelist | Fact_SnapshotCustomer.Evangelist | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 29 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 30 | UpdateDate | Fact_SnapshotCustomer.UpdateDate | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 31 | RegulationID | Fact_SnapshotCustomer.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 32 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 33 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 34 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 35 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 36 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 37 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 38 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 39 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 40 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 41 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 42 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 43 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 44 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 45 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 46 | RegionID | Fact_SnapshotCustomer.RegionID | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 47 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 48 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 49 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 50 | Email | Fact_SnapshotCustomer.Email | Customer email address (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (via Fact_SnapshotCustomer) | T1 |
| 51 | City | Fact_SnapshotCustomer.City | Customer city (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.City (CC). (via Fact_SnapshotCustomer) | T1 |
| 52 | Address | Fact_SnapshotCustomer.Address | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 53 | Zip | Fact_SnapshotCustomer.Zip | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 54 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 55 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 56 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 57 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 58 | PositionID | BI_DB_Positions_Closed_To_IBAN.PositionID, BI_DB_Positions_Opened_From_IBAN.PositionID | COALESCE(bdpcti.PositionID, bdpofi.PositionID) | T2 |
| 59 | IsSettled | Dim_Position.IsSettled | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) (via Dim_Position) | T5 |
| 60 | IsBuy | Dim_Position.IsBuy | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 61 | Leverage | Dim_Position.Leverage | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) (via Dim_Position) | T1 |
| 62 | IsAirDrop | Dim_Position.IsAirDrop | 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) (via Dim_Position) | T2 |
| 63 | ExecutionIBANTradeSuccess | BI_DB_DepositWithdrawFee.IsIBANTrade, BI_DB_Positions_Closed_To_IBAN, BI_DB_Positions_Opened_From_IBAN | CASE WHEN COALESCE(bdpcti.PositionID, bdpofi.PositionID) IS NULL AND IsIBANTrade = 1 THEN 0 ELSE 1 END | T2 |
| 64 | InstrumentID | Dim_Instrument.InstrumentID | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 65 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 66 | InstrumentType | Dim_Instrument.InstrumentType | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T2 |
| 67 | IsCopy | Dim_Position.MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-03-10 | Guy M | Join to Fact_BillingDeposit for IsRecurring; extra columns |
| 2025-09-08 | Guy M | Position data for IBAN trades (less efficient; for specific reports) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
