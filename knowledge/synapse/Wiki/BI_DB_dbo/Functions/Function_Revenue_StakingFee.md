# Function_Revenue_StakingFee

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 61 (T1: 50, T2: 11) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Staking reward distribution economics per instrument and customer: rows from `Dealing_Staking_Results` filtered to attributed `DateID` (from `dateadd(MONTH,-1, UpdateDate)`) between `@sdateID` and `@edateID`, excluding bad `StakingMonthID` values (see `BadMonths` CTE). Normalizes month IDs (`left(StakingMonthID,6)`), splits eToro vs client USD using eligibility (`IsEligible`), and joins `Dim_Instrument` and `Fact_SnapshotCustomer` with EOM-aligned `Dim_Range` for customer attributes at month-end.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateID | INT | Start date (YYYYMMDD integer format) |
| @edateID | INT | End date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Instrument | DWH_dbo |
| Dim_Range | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dealing_Staking_Results | Dealing_dbo |
| Dim_Range | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | StakingMonthID | Dealing_Staking_Results | left(StakingMonthID,6) | T2 |
| 2 | Date | Dealing_Staking_Results | dateadd(MONTH,-1,UpdateDate) | T2 |
| 3 | DateID | Dealing_Staking_Results | CAST(FORMAT(CAST(dateadd(MONTH,-1,UpdateDate) AS DATE),'yyyyMMdd') as INT) | T2 |
| 4 | StakingMonth | Dealing_Staking_Results.StakingMonth | Month name (January–December). (Tier 2) (via Dealing_Staking_Results) | T1 |
| 5 | StakingYear | Dealing_Staking_Results.StakingYear | Calendar year. (Tier 2) (via Dealing_Staking_Results) | T1 |
| 6 | InstrumentID | Dealing_Staking_Results.InstrumentID | Crypto instrument. (Tier 2) (via Dealing_Staking_Results) | T1 |
| 7 | Instrument | Dim_Instrument.Name | Display name computed by Trade.GetInstrument as BuyCurrency Abbreviation + '/' + SellCurrency Abbreviation (e.g., EUR/USD for forex, AAPL/USD for stocks). Not a company name; see InstrumentDisplayName for human-readable labels. (via Dim_Instrument) | T1 |
| 8 | CID | Dealing_Staking_Results.CID | Client account ID. (Tier 2) (via Dealing_Staking_Results) | T2 |
| 9 | IsEligible | Dealing_Staking_Results.IsEligible | 1 = meets all eligibility criteria. (Tier 2 — ETL-computed) (via Dealing_Staking_Results) | T2 |
| 10 | NonEligible_PrimaryReason | Dealing_Staking_Results.NonEligible_PrimaryReason | First failing eligibility check when IsEligible=0. NULL when eligible. (Tier 2 — ETL-computed) (via Dealing_Staking_Results) | T2 |
| 11 | IneligibleCustomerRewards | Dealing_Staking_Results.Etoro_Amount | CASE WHEN IsEligible = 0 THEN Etoro_Amount ELSE 0 END WHERE attributed DateID (from dateadd(MONTH,-1,UpdateDate)) BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths (LEN>6 excluded) | T2 |
| 12 | RevShareCommission | Dealing_Staking_Results.Etoro_Amount | CASE WHEN IsEligible = 1 THEN Etoro_Amount ELSE 0 END WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 13 | ClientPercent | Dealing_Staking_Results | Client_Airdrop / nullif((Client_Airdrop + Etoro_Amount),0) ClientPercent | T2 |
| 14 | EtoroPercent | Dealing_Staking_Results | Etoro_Amount / nullif((Client_Airdrop + Etoro_Amount),0) EtoroPercent | T2 |
| 15 | ClientUSDDistributed | Dealing_Staking_Results.USD_Compensation | CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 16 | EtoroUSDDistributed | Dealing_Staking_Results.Etoro_Amount_USD | Etoro_Amount_USD WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 17 | TotalUSDDistributed | Dealing_Staking_Results.USD_Compensation, Etoro_Amount_USD | CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END + Etoro_Amount_USD WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 18 | AirDropDateID | Dealing_Staking_Results | CAST(FORMAT(CAST(AirdropOccurred AS DATE),'yyyyMMdd') as INT) | T2 |
| 19 | ActualCompensationType | Dealing_Staking_Results.ActualCompensationType | Final delivery method. May differ from OriginalCompensationType if override applied. (Tier 2) (via Dealing_Staking_Results) | T1 |
| 20 | ClubCategory | Dealing_Staking_Results.ClubCategory | Client's Club tier (Silver/Gold/Platinum/Diamond & Platinum Plus). Based on ≤40 USD holdings threshold. (Tier 2 — join-enriched from Dealing_Staking_Club) (via Dealing_Staking_Results) | T2 |
| 21 | GCID | Fact_SnapshotCustomer.GCID | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 22 | CountryID | Fact_SnapshotCustomer.CountryID | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 23 | LabelID | Fact_SnapshotCustomer.LabelID | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 24 | LanguageID | Fact_SnapshotCustomer.LanguageID | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 25 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 26 | DocsOK | Fact_SnapshotCustomer.DocsOK | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 27 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 28 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 29 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 30 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 31 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 32 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 33 | Evangelist | Fact_SnapshotCustomer.Evangelist | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 34 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 35 | RegulationID | Fact_SnapshotCustomer.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 36 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 37 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 38 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 39 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 40 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 41 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 42 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 43 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 44 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 45 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 46 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 47 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 48 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 49 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 50 | RegionID | Fact_SnapshotCustomer.RegionID | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 51 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 52 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 53 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 54 | Email | Fact_SnapshotCustomer.Email | Customer email address (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (via Fact_SnapshotCustomer) | T1 |
| 55 | City | Fact_SnapshotCustomer.City | Customer city (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.City (CC). (via Fact_SnapshotCustomer) | T1 |
| 56 | Address | Fact_SnapshotCustomer.Address | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 57 | Zip | Fact_SnapshotCustomer.Zip | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 58 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 59 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 60 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 61 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-05-20 | Guy M | Handle bad StakingMonthID values (e.g. 20250300) by dividing by 10 / excluding long IDs |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
