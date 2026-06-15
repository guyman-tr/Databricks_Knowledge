# Function_MIMO_First_Deposit_All_Platforms

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | MIMO |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 56 (T1: 46, T2: 10) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Single entry point for **first-time deposit (FTD)** attributes per customer across eMoney and trading-platform sources, with **date-routed logic**: before 2025-09-01 uses legacy IBAN/TP union and row-numbering; on/after uses `Dim_Customer` as the spine with joins to refreshed IBAN/TP extracts, C2USD billing, and bad-FTD exclusion. Each row is enriched with `Fact_SnapshotCustomer` as-of the FTD date via `Dim_Range`.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| eMoney_Fact_Transaction_Status | eMoney_dbo |
| FiatTransactions | eMoney_dbo |
| Fact_CustomerAction | DWH_dbo |
| Dim_Customer | DWH_dbo |
| Dim_FTDPlatform | DWH_dbo |
| Fact_BillingDeposit | DWH_dbo |
| BI_DB_DDR_Fact_MIMO_AllPlatforms | BI_DB_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | Routed OLD_BASE vs NEW_BASE; NEW from Dim_Customer; OLD from first-ranked eMoney/TP deposit | T2 |
| 2 | DepositID | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | CASE on FTDPlatformID / joins; IBAN TransactionID, TP DepositID, or neutralized | T2 |
| 3 | FirstDepositDate | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | OLD: earliest across IBAN/TP union; NEW: Dim_Customer.FirstDepositDate | T2 |
| 4 | FirstDepositAmount | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | Same routing as date/amount sources | T2 |
| 5 | FTDPlatform | Dim_FTDPlatform, literals | Dim_FTDPlatform.FTDPlatformName (NEW) or 'eMoney' / 'TradingPlatform' (OLD) | T2 |
| 6 | FTDPlatformID | Dim_Customer, literals | 3 eMoney / 1 TP (OLD) or Dim_Customer.FTDPlatformID (NEW) | T2 |
| 7 | IsCryptoToFiat | eMoney_Fact_Transaction_Status | TxTypeID = 14 flags; COALESCE across IBAN/TP in NEW | T2 |
| 8 | IsIBANTrade | Fact_CustomerAction | ActionTypeID = 44; COALESCE(tp, ib) in NEW | T2 |
| 9 | IsIBANQuickTransfer | Fact_CustomerAction | MoveMoneyReasonID = 6; COALESCE in NEW | T2 |
| 10 | IsC2USD | Fact_BillingDeposit | CAST(0 AS BIT) OLD; NEW: CASE WHEN C2USD match THEN 1 ELSE 0 END | T2 |
| 11 | GCID | Fact_SnapshotCustomer.GCID | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 12 | DemoCID | Fact_SnapshotCustomer.DemoCID | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 13 | CustomerChangeTypeID | Fact_SnapshotCustomer.CustomerChangeTypeID | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 14 | CurentValue | Fact_SnapshotCustomer.CurentValue | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 15 | PreviousValue | Fact_SnapshotCustomer.PreviousValue | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 16 | CountryID | Fact_SnapshotCustomer.CountryID | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 17 | LabelID | Fact_SnapshotCustomer.LabelID | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 18 | LanguageID | Fact_SnapshotCustomer.LanguageID | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 19 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 20 | DocsOK | Fact_SnapshotCustomer.DocsOK | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 21 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 22 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 23 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 24 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 25 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 26 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 27 | Evangelist | Fact_SnapshotCustomer.Evangelist | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 28 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 29 | UpdateDate | Fact_SnapshotCustomer.UpdateDate | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 30 | RegulationID | Fact_SnapshotCustomer.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 31 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 32 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 33 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 34 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 35 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 36 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 37 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 38 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 39 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 40 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 41 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 42 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 43 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 44 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 45 | RegionID | Fact_SnapshotCustomer.RegionID | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 46 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 47 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 48 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 49 | Email | Fact_SnapshotCustomer.Email | Customer email address (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (via Fact_SnapshotCustomer) | T1 |
| 50 | City | Fact_SnapshotCustomer.City | Customer city (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.City (CC). (via Fact_SnapshotCustomer) | T1 |
| 51 | Address | Fact_SnapshotCustomer.Address | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 52 | Zip | Fact_SnapshotCustomer.Zip | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 53 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 54 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 55 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 56 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-06-14 | Guy M | Trade From IBAN (44) & C2F edge case |
| 2025-09-13 | Guy M | Replaced old logic with Dim_Customer; added c2USD; combined old+new with date routing |
| 2025-10-06 | Guy M | FiatTransactions.Created in ROW_NUMBER; options/global FTD notes |
| 2025-10-26 | Guy M | TRY_CONVERT on FTD join keys (options platform strings) |
| 2025-11-23 | Guy M | REMOVE_BAD_FTDS exclusion for wrongly tagged FTDs |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
