# Function_Revenue_Commissions

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 62 (T1: 54, T2: 8) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns **trading commission** components by customer action from `Fact_CustomerAction` where the first CTE restricts rows to **ActionTypeID IN (1,2,3,39,4,5,6,28,40)** (open-style vs close-style families). It joins snapshot context and `Dim_Instrument`. **CommissionOnOpen** applies when **ActionTypeID IN (1,2,3,39)**; **CommissionOnClose** / **CommissionCloseAdjustment** apply when **ActionTypeID IN (4,5,6,28,40)** (close adjustment uses `CommissionOnClose - CommissionByUnits`). **TotalCommission** selects open vs close branch by the same groupings. Adds copy and margin flags and **IsSQF** via `Function_Instrument_Snapshot_Enriched(@edateInt)`.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_CustomerAction.RealCID | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) (via Fact_CustomerAction) | T1 |
| 2 | Occurred | Fact_CustomerAction.Occurred | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) (via Fact_CustomerAction) | T1 |
| 3 | ActionTypeID | Fact_CustomerAction.ActionTypeID | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) (via Fact_CustomerAction) | T1 |
| 4 | InstrumentID | Fact_CustomerAction.InstrumentID | FK to `Trade.Instrument`. Financial instrument being traded when row is instrument-bearing. (Tier 1 — Trade.PositionTbl) (via Fact_CustomerAction) | T1 |
| 5 | Leverage | Fact_CustomerAction.Leverage | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement posture. (Tier 1 — Trade.PositionTbl) (via Fact_CustomerAction) | T1 |
| 6 | PositionID | Fact_CustomerAction.PositionID | Position identifier from the source trading system. NOT a primary key of this table — defaults to 0 for non-position events, and the same PositionID appears in both open and close rows. (via Fact_CustomerAction) | T1 |
| 7 | DateID | Fact_CustomerAction.DateID | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) (via Fact_CustomerAction) | T2 |
| 8 | IsSettled | Fact_CustomerAction.IsSettled | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) (via Fact_CustomerAction) | T5 |
| 9 | MirrorID | Fact_CustomerAction.MirrorID | FK to Trade.Mirror (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). (Tier 1 — Trade.PositionTbl) (via Fact_CustomerAction) | T1 |
| 10 | IsAirDrop | Fact_CustomerAction.IsAirDrop | ISNULL(IsAirDrop, 0) | T2 |
| 11 | SettlementTypeID | Fact_CustomerAction.SettlementTypeID | **`Dictionary.SettlementTypes`** modern encoding (`0 CFD`, `1 REAL`, `2 TRS`, `3 CMT`, `4 REAL_FUTURES`, `5 MARGIN_TRADE`). Supersedes naïve `IsSettled` reads. (Tier 1 — Trade.PositionTbl) (via Fact_CustomerAction) | T1 |
| 12 | IsMarginTrade | Fact_CustomerAction.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |
| 13 | GCID | Fact_SnapshotCustomer.GCID | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 14 | CountryID | Fact_SnapshotCustomer.CountryID | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 15 | LabelID | Fact_SnapshotCustomer.LabelID | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 16 | LanguageID | Fact_SnapshotCustomer.LanguageID | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 17 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 18 | DocsOK | Fact_SnapshotCustomer.DocsOK | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 19 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 20 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 21 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 22 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 23 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 24 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 25 | Evangelist | Fact_SnapshotCustomer.Evangelist | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) (via Fact_SnapshotCustomer) | T4 |
| 26 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 27 | RegulationID | Fact_SnapshotCustomer.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 28 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 29 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 30 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 31 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 32 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 33 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 34 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 35 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 36 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 37 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 38 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 39 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 40 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 41 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 42 | RegionID | Fact_SnapshotCustomer.RegionID | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 43 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 44 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 45 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 46 | Email | Fact_SnapshotCustomer.Email | Customer email address (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (via Fact_SnapshotCustomer) | T1 |
| 47 | City | Fact_SnapshotCustomer.City | Customer city (nvarchar(50), nullable). No DDL-level dynamic data masking is defined on this column. GDPR erasure handled in ETL. Source: Ext_FSC_Real_Customer_Customer.City (CC). (via Fact_SnapshotCustomer) | T1 |
| 48 | Address | Fact_SnapshotCustomer.Address | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 49 | Zip | Fact_SnapshotCustomer.Zip | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 50 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 51 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 52 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 53 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 54 | CommissionOnOpen | Fact_CustomerAction.Commission | CASE WHEN ActionTypeID IN (1,2,3,39) THEN Commission ELSE 0 END (prep rows already WHERE ActionTypeID IN (1,2,3,39,4,5,6,28,40)) | T2 |
| 55 | CommissionCloseAdjustment | Fact_CustomerAction.CommissionOnClose, CommissionByUnits | CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionOnClose - CommissionByUnits ELSE 0 END (same prep filter) | T2 |
| 56 | CommissionOnClose | Fact_CustomerAction.CommissionOnClose | CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionOnClose ELSE 0 END (same prep filter) | T2 |
| 57 | IsBuy | Fact_CustomerAction.IsBuy | **`1`** Long **`0`** Short; NULL ⇒ non-trade row sentinel. (Tier 1 — Trade.PositionTbl) (via Fact_CustomerAction) | T1 |
| 58 | IsCopy | Fact_CustomerAction.ActionTypeID | CASE WHEN ActionTypeID IN (2,3,5,6) THEN 1 ELSE 0 END | T2 |
| 59 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 60 | IsFuture | Dim_Instrument.IsFuture | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T2 |
| 61 | TotalCommission | Fact_CustomerAction.Commission, CommissionOnClose, CommissionByUnits | CASE WHEN ActionTypeID IN (1,2,3,39) THEN CommissionOnOpen WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionCloseAdjustment END (same prep filter) | T2 |
| 62 | IsSQF | Function_Instrument_Snapshot_Enriched | CASE WHEN InstrumentID IN (enriched WHERE IsSQF = 1) THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2024-09-25 | Guy M | IsBuy on Fact_CustomerAction; removed Dim_Position join |
| 2024-11-07 | Guy M | Commission on close |
| 2025-03-09 | Guy M | IsFuture |
| 2025-06-23 | Guy M | IsSQF |
| 2025-09-11 | Guy M | SettlementTypeID |
| 2025-10-15 | Guy M | Margin trades |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
