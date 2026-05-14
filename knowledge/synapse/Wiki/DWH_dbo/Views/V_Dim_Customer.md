# DWH_dbo.V_Dim_Customer

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Dim_Customer]` |
| **Type** | View |
| **Base Tables** | `Dim_Customer`, `Dim_Country`, `Dim_Affiliate`, `Dim_Language`, `Dim_VerificationLevel`, `Dim_PlayerStatus`, `Dim_PlayerLevel`, `Dim_Regulation` |
| **Purpose** | Denormalized customer dimension view that resolves 7 FK ID columns to human-readable names. Provides a consumer-friendly flattened customer profile. |

## 2. Business Context

`Dim_Customer` stores raw IDs for country, affiliate, language, verification level, player status, player level, and regulation. This view **resolves those IDs to display names** via INNER JOINs to the respective dimension tables:

| FK Column | Dimension Table | Output Column |
|-----------|----------------|---------------|
| `CountryID` | `Dim_Country` | `Country` (Name) |
| `AffiliateID` | `Dim_Affiliate` | `Affiliate` (AffiliatesGroupsName) |
| `LanguageID` | `Dim_Language` | `Language` (Name) |
| `VerificationLevelID` | `Dim_VerificationLevel` | `VerificationLevel` (Name) |
| `PlayerStatusID` | `Dim_PlayerStatus` | `PlayerStatus` (Name) |
| `PlayerLevelID` | `Dim_PlayerLevel` | `PlayerLevel` (Name) |
| `RegulationID` | `Dim_Regulation` | `Regulation` (Name) |

### Type Conversions
Several columns are explicitly cast for export compatibility:
- `BirthDate`, `RegisteredReal`, `RegisteredDemo`, dates → `VARCHAR(50)` via `CONVERT(..., 121)` (ODBC canonical format)
- Boolean flags (`DocsOK`, `Bankruptcy`, `EmployeeAccount`, etc.) → `VARCHAR(1)` or `VARCHAR(10)`
- `FirstDepositAmount` → `DECIMAL(19,4)`

### Excluded Columns
The view explicitly comments out `ReferralID`, `UserName_Lower`, and `2FA` — these are available in the base table but not surfaced in this view.

## 3. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | GCID | int | Dim_Customer.GCID | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — inherited from Dim_Customer wiki) |
| 2 | RealCID | int | Dim_Customer.RealCID | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Universal customer identifier across all DWH tables. (Tier 1 — inherited from Dim_Customer wiki) |
| 3 | DemoCID | int | Dim_Customer.DemoCID | Demo account CID associated with this customer. From UserApiDB_Customer_CustomerIdentification. (Tier 1 — inherited from Dim_Customer wiki) |
| 4 | OriginalCID | int | Dim_Customer.OriginalCID | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 5 | UserName | varchar(20) | Dim_Customer.UserName | Customer login username. Unique (case-insensitive). PII — masked in UC masked copy. (Tier 1 — inherited from Dim_Customer wiki) |
| 6 | FirstName | nvarchar(50) | Dim_Customer.FirstName | Legal first name in Unicode. nvarchar supports non-Latin scripts. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 7 | LastName | nvarchar(50) | Dim_Customer.LastName | Legal last name in Unicode. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 8 | Gender | char(1) | Dim_Customer.Gender | Gender: M, F, or U (Unknown). PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 9 | BirthDate | varchar(50) | Dim_Customer.BirthDate | Customer date of birth. CONVERT to varchar(50) style 121 (ODBC canonical). PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 10 | Country | nvarchar | Dim_Country.Name | Country of residence name. Resolved from Dim_Country via DC.CountryID INNER JOIN. (Tier 2 — view DDL dimension lookup) |
| 11 | IP | varchar(15) | Dim_Customer.IP | Registration IP address. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 12 | Affiliate | nvarchar | Dim_Affiliate.AffiliatesGroupsName | Affiliate/partner group name. Resolved from Dim_Affiliate via DC.AffiliateID INNER JOIN. (Tier 2 — view DDL dimension lookup) |
| 13 | CampaignID | int | Dim_Customer.CampaignID | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organic acquisitions. (Tier 1 — inherited from Dim_Customer wiki) |
| 14 | SubChannelID | int | Dim_Customer.SubChannelID | Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 15 | LabelID | int | Dim_Customer.LabelID | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer. Default=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 16 | Language | nvarchar | Dim_Language.Name | Platform language name. Resolved from Dim_Language via DC.LanguageID INNER JOIN. (Tier 2 — view DDL dimension lookup) |
| 17 | Email | varchar(50) | Dim_Customer.Email | Customer email address. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 18 | Phone | varchar(30) | Dim_Customer.Phone | Phone number from production Customer.CustomerStatic. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 19 | Zip | nvarchar(50) | Dim_Customer.Zip | Postal code. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 20 | City | nvarchar(50) | Dim_Customer.City | City in Unicode. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 21 | Address | nvarchar(100) | Dim_Customer.Address | Street address in Unicode. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 22 | AccountExpirationDate | varchar(50) | Dim_Customer.AccountExpirationDate | Expiration date for demo or time-limited accounts. CONVERT to varchar(50) style 121. NULL for standard real-money accounts. (Tier 1 — inherited from Dim_Customer wiki) |
| 23 | SocialConnectID | int | Dim_Customer.SocialConnectID | Social media connection type. DEFAULT=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 24 | VerificationLevel | nvarchar | Dim_VerificationLevel.Name | KYC verification level name. Resolved from Dim_VerificationLevel via DC.VerificationLevelID INNER JOIN. Values: unverified, partial, intermediate, fully verified. (Tier 2 — view DDL dimension lookup) |
| 25 | DocsOK | varchar(10) | Dim_Customer.DocsOK | Whether required documents are verified. CAST to varchar(10). (Tier 1 — inherited from Dim_Customer wiki) |
| 26 | PlayerStatus | nvarchar | Dim_PlayerStatus.Name | Player/account status name. Resolved from Dim_PlayerStatus via DC.PlayerStatusID INNER JOIN. 1=Normal (97.5%). (Tier 2 — view DDL dimension lookup) |
| 27 | Bankruptcy | varchar(10) | Dim_Customer.Bankruptcy | Bankruptcy flag. CAST to varchar(10). (Tier 1 — inherited from Dim_Customer wiki) |
| 28 | FunnelID | int | Dim_Customer.FunnelID | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey the customer came through. NULL when not tracked. (Tier 1 — inherited from Dim_Customer wiki) |
| 29 | DownloadID | int | Dim_Customer.DownloadID | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 — inherited from Dim_Customer wiki) |
| 30 | RegisteredReal | varchar(50) | Dim_Customer.RegisteredReal | Account registration date (renamed from Registered). CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 31 | RegisteredDemo | varchar(50) | Dim_Customer.RegisteredDemo | Demo account registration date. CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 32 | FunnelFromID | int | Dim_Customer.FunnelFromID | Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 — inherited from Dim_Customer wiki) |
| 33 | RiskStatusID | int | Dim_Customer.RiskStatusID | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk. (Tier 1 — inherited from Dim_Customer wiki) |
| 34 | RiskClassificationID | int | Dim_Customer.RiskClassificationID | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. (Tier 1 — inherited from Dim_Customer wiki) |
| 35 | EmployeeAccount | varchar(10) | Dim_Customer.EmployeeAccount | 1 if eToro employee personal trading account (renamed from isEmployeeAccount). CAST to varchar(10). (Tier 1 — inherited from Dim_Customer wiki) |
| 36 | CommunicationLanguageID | int | Dim_Customer.CommunicationLanguageID | Language for customer communications (emails, notifications). May differ from LanguageID. (Tier 1 — inherited from Dim_Customer wiki) |
| 37 | BannerID | int | Dim_Customer.BannerID | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — inherited from Dim_Customer wiki) |
| 38 | PremiumAccount | varchar(10) | Dim_Customer.PremiumAccount | Whether this is a premium account. CAST to varchar(10). (Tier 1 — inherited from Dim_Customer wiki) |
| 39 | Evangelist | varchar(10) | Dim_Customer.Evangelist | Whether this customer is an evangelist/ambassador. CAST to varchar(10). (Tier 1 — inherited from Dim_Customer wiki) |
| 40 | GuruStatusID | varchar(10) | Dim_Customer.GuruStatusID | eToro Popular Investor/Guru program status. FK to Dictionary.GuruStatus. CAST to varchar(10). (Tier 1 — inherited from Dim_Customer wiki) |
| 41 | NumOfGurus | int | Dim_Customer.NumOfGurus | Number of Popular Investors this customer is copying. (Tier 1 — inherited from Dim_Customer wiki) |
| 42 | NumOfCopiers | int | Dim_Customer.NumOfCopiers | Number of customers copying this customer's trades. (Tier 1 — inherited from Dim_Customer wiki) |
| 43 | NumOfRAF | int | Dim_Customer.NumOfRAF | Number of successful Refer-A-Friend referrals. (Tier 1 — inherited from Dim_Customer wiki) |
| 44 | AccountTypeID | int | Dim_Customer.AccountTypeID | Customer account classification. Default=1 (real retail account). (Tier 1 — inherited from Dim_Customer wiki) |
| 45 | Regulation | nvarchar | Dim_Regulation.Name | Regulatory entity name. Resolved from Dim_Regulation via DC.RegulationID INNER JOIN. Top: CySEC, BVI, FCA. (Tier 2 — view DDL dimension lookup) |
| 46 | PlayerLevel | nvarchar | Dim_PlayerLevel.Name | Customer experience/permission level name. Resolved from Dim_PlayerLevel via DC.PlayerLevelID INNER JOIN. 1=Bronze (94%), 4=Internal, 7=Diamond. (Tier 2 — view DDL dimension lookup) |
| 47 | AccountStatusID | int | Dim_Customer.AccountStatusID | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — inherited from Dim_Customer wiki) |
| 48 | AccountManagerID | int | Dim_Customer.AccountManagerID | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — inherited from Dim_Customer wiki) |
| 49 | HasAvatar | varchar(10) | Dim_Customer.HasAvatar | Whether customer has uploaded a custom avatar. CAST to varchar(10). Updated post-load from Avatars staging. (Tier 1 — inherited from Dim_Customer wiki) |
| 50 | AvatarUploadDate | varchar(50) | Dim_Customer.AvatarUploadDate | When the avatar was uploaded. CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 51 | UpdateDate | varchar(50) | Dim_Customer.UpdateDate | ETL load/update timestamp (GETDATE()). CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 52 | IsDepositor | varchar(1) | Dim_Customer.IsDepositor | Whether the customer has ever deposited. CAST to varchar(1). DEFAULT=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 53 | FirstDepositDate | varchar(50) | Dim_Customer.FirstDepositDate | Date of first deposit. CONVERT to varchar(50) style 121. DEFAULT='19000101'. (Tier 1 — inherited from Dim_Customer wiki) |
| 54 | ID | uniqueidentifier | Dim_Customer.ID | System GUID for REST API identity. Default=newsequentialid(). (Tier 1 — inherited from Dim_Customer wiki) |
| 55 | ExternalID | decimal(38,0) | Dim_Customer.ExternalID | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — inherited from Dim_Customer wiki) |
| 56 | PlayerStatusReasonID | int | Dim_Customer.PlayerStatusReasonID | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — inherited from Dim_Customer wiki) |
| 57 | PendingClosureStatusID | varchar(10) | Dim_Customer.PendingClosureStatusID | Status in the pending closure workflow. CAST to varchar(10). Default=1 (no pending closure). (Tier 1 — inherited from Dim_Customer wiki) |
| 58 | CountryIDByIP | int | Dim_Customer.CountryIDByIP | Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison. (Tier 1 — inherited from Dim_Customer wiki) |
| 59 | SubSerialID | varchar(1024) | Dim_Customer.SubSerialID | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — inherited from Dim_Customer wiki) |
| 60 | EvMatchStatus | int | Dim_Customer.EvMatchStatus | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — inherited from Dim_Customer wiki) |
| 61 | DocumentStatusID | int | Dim_Customer.DocumentStatusID | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — inherited from Dim_Customer wiki) |
| 62 | RegulationChangeDate | varchar(50) | Dim_Customer.RegulationChangeDate | Timestamp when RegulationID was last changed. CONVERT to varchar(50) style 121. NULL if never changed. (Tier 1 — inherited from Dim_Customer wiki) |
| 63 | IsCopyBlocked | varchar(1) | Dim_Customer.IsCopyBlocked | 1 if the customer is blocked from copy trading. CAST to varchar(1). Currently 0 in all rows. (Tier 1 — inherited from Dim_Customer wiki) |
| 64 | WorldCheckID | int | Dim_Customer.WorldCheckID | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 65 | IsEDD | varchar(1) | Dim_Customer.IsEDD | Enhanced Due Diligence required flag. CAST to varchar(1). 1 = deeper AML/KYC investigation required. (Tier 1 — inherited from Dim_Customer wiki) |
| 66 | SuitabilityTestStatusID | int | Dim_Customer.SuitabilityTestStatusID | MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 — inherited from Dim_Customer wiki) |
| 67 | FirstDepositAmount | decimal(19,4) | Dim_Customer.FirstDepositAmount | Amount of first deposit (in USD). CAST to decimal(19,4). Updated from FTDAmountInUsd. (Tier 1 — inherited from Dim_Customer wiki) |
| 68 | PrivacyPolicyID | int | Dim_Customer.PrivacyPolicyID | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 — inherited from Dim_Customer wiki) |
| 69 | MifidCategorizationID | int | Dim_Customer.MifidCategorizationID | MiFID II investor classification. FK to Dictionary.MifidCategorization. 1=Retail (97.3%), 4=Retail Pending, 5=Pending. (Tier 1 — inherited from Dim_Customer wiki) |
| 70 | IsEmailVerified | int | Dim_Customer.IsEmailVerified | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts. (Tier 1 — inherited from Dim_Customer wiki) |
| 71 | IsValidCustomer | int | Dim_Customer.IsValidCustomer | DWH-computed: 1 when PlayerLevelID≠4, LabelID NOT IN (30,26), CountryID≠250. Filters non-standard customers from reporting. (Tier 1 — inherited from Dim_Customer wiki) |
| 72 | DesignatedRegulationID | int | Dim_Customer.DesignatedRegulationID | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — inherited from Dim_Customer wiki) |
| 73 | RegionByIP_ID | int | Dim_Customer.RegionByIP_ID | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 — inherited from Dim_Customer wiki) |
| 74 | ScreeningStatusID | int | Dim_Customer.ScreeningStatusID | Compliance screening status. Updated from ScreeningService. (Tier 1 — inherited from Dim_Customer wiki) |
| 75 | RegionID | int | Dim_Customer.RegionID | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 — inherited from Dim_Customer wiki) |
| 76 | WorldCheckResultsUpdated | varchar(50) | Dim_Customer.WorldCheckResultsUpdated | When World-Check results were last updated. CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 77 | HasWallet | int | Dim_Customer.HasWallet | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — inherited from Dim_Customer wiki) |
| 78 | IsAddressProof | int | Dim_Customer.IsAddressProof | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 1 — inherited from Dim_Customer wiki) |
| 79 | IsAddressProofExpiryDate | varchar(50) | Dim_Customer.IsAddressProofExpiryDate | Expiry date of address proof document. CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 80 | IsIDProof | int | Dim_Customer.IsIDProof | Whether ID proof document is on file (1/0). (Tier 1 — inherited from Dim_Customer wiki) |
| 81 | IsIDProofExpiryDate | varchar(50) | Dim_Customer.IsIDProofExpiryDate | Expiry date of ID proof document. CONVERT to varchar(50) style 121. (Tier 1 — inherited from Dim_Customer wiki) |
| 82 | PhoneVerifiedID | int | Dim_Customer.PhoneVerifiedID | Result code of phone number verification process. NULL if not yet attempted. (Tier 1 — inherited from Dim_Customer wiki) |
| 83 | CitizenshipCountryID | int | Dim_Customer.CitizenshipCountryID | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — inherited from Dim_Customer wiki) |
| 84 | PlayerStatusSubReasonID | int | Dim_Customer.PlayerStatusSubReasonID | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022. (Tier 1 — inherited from Dim_Customer wiki) |
| 85 | IsCreditReportValidCB | int | Dim_Customer.IsCreditReportValidCB | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 1 — inherited from Dim_Customer wiki) |
| 86 | CashoutFeeGroupID | int | Dim_Customer.CashoutFeeGroupID | Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 — inherited from Dim_Customer wiki) |
| 87 | MiddleName | nvarchar(50) | Dim_Customer.MiddleName | Middle name in Unicode. PII — masked. Added 2018. (Tier 1 — inherited from Dim_Customer wiki) |
| 88 | BuildingNumber | nvarchar(30) | Dim_Customer.BuildingNumber | Building/apartment number. Separate from Address for structured address storage. PII — masked. (Tier 1 — inherited from Dim_Customer wiki) |
| 89 | SalesForceAccountID | nvarchar(18) | Dim_Customer.SalesForceAccountID | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 — inherited from Dim_Customer wiki) |
| 90 | POBCountryID | int | Dim_Customer.POBCountryID | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 — inherited from Dim_Customer wiki) |
| 91 | ApexID | varchar(8) | Dim_Customer.ApexID | APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 — inherited from Dim_Customer wiki) |

## 4. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| INNER JOINs may filter | Medium | Uses INNER JOIN for all 7 lookups — customers missing dimension entries will be excluded |
| String-cast dates | Low | Date columns cast to VARCHAR(50) — consumers cannot directly filter/sort as dates |

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Column expansion: 91 cols documented individually (84 Tier 1 from Dim_Customer wiki + 7 dimension lookups)*
*Tiers: 84 T1, 7 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10*
*Object: DWH_dbo.V_Dim_Customer | Type: View | Base: Dim_Customer + 7 dimension JOINs (Country, Affiliate, Language, VerificationLevel, PlayerStatus, PlayerLevel, Regulation)*
