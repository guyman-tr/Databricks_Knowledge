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

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | `GCID` | int | Global Customer ID. (Tier 2) |
| 2 | `RealCID` | int | Real account CID. (Tier 2) |
| 3 | `DemoCID` | int | Demo account CID. (Tier 2) |
| 4 | `OriginalCID` | int | Original CID before account changes. (Tier 2) |
| 5 | `UserName` | nvarchar | Customer username. (Tier 2) |
| 6 | `FirstName` | nvarchar | First name. (Tier 2) |
| 7 | `LastName` | nvarchar | Last name. (Tier 2) |
| 8 | `Gender` | nvarchar | Gender. (Tier 2) |
| 9 | `BirthDate` | varchar(50) | Birth date as string (YYYY-MM-DD HH:MM:SS.mmm). (Tier 2) |
| 10 | `Country` | nvarchar | **Resolved** from Dim_Country.Name via CountryID. (Tier 1) |
| 11 | `IP` | nvarchar | Registration IP address. (Tier 2) |
| 12 | `Affiliate` | nvarchar | **Resolved** from Dim_Affiliate.AffiliatesGroupsName via AffiliateID. (Tier 1) |
| 13 | `CampaignID` | int | Marketing campaign FK. (Tier 2) |
| 14 | `SubChannelID` | int | Marketing sub-channel. (Tier 2) |
| 15 | `LabelID` | int | White-label ID. (Tier 2) |
| 16 | `Language` | nvarchar | **Resolved** from Dim_Language.Name via LanguageID. (Tier 1) |
| 17 | `Email` | nvarchar | Customer email. (Tier 2) |
| 18 | `Phone` | nvarchar | Phone number. (Tier 2) |
| 19 | `Zip` | nvarchar | Postal code. (Tier 2) |
| 20 | `City` | nvarchar | City. (Tier 2) |
| 21 | `Address` | nvarchar | Street address. (Tier 2) |
| 22 | `AccountExpirationDate` | varchar(50) | Account expiration as string. (Tier 2) |
| 23 | `SocialConnectID` | int | Social network connection. (Tier 2) |
| 24 | `VerificationLevel` | nvarchar | **Resolved** from Dim_VerificationLevel.Name. (Tier 1) |
| 25 | `DocsOK` | varchar(10) | Document verification flag. (Tier 2) |
| 26 | `PlayerStatus` | nvarchar | **Resolved** from Dim_PlayerStatus.Name. (Tier 1) |
| 27 | `Bankruptcy` | varchar(10) | Bankruptcy flag. (Tier 2) |
| 28 | `FunnelID` | int | Registration funnel. (Tier 2) |
| 29 | `DownloadID` | int | App download tracking. (Tier 2) |
| 30 | `RegisteredReal` | varchar(50) | Real account registration date as string. (Tier 2) |
| 31 | `RegisteredDemo` | varchar(50) | Demo account registration date as string. (Tier 2) |
| 32 | `FunnelFromID` | int | Source funnel. (Tier 2) |
| 33 | `RiskStatusID` | int | Risk assessment status. (Tier 2) |
| 34 | `RiskClassificationID` | int | Risk classification level. (Tier 2) |
| 35 | `EmployeeAccount` | varchar(10) | Employee flag. (Tier 2) |
| 36 | `CommunicationLanguageID` | int | Preferred communication language. (Tier 2) |
| 37 | `BannerID` | int | Marketing banner. (Tier 2) |
| 38 | `PremiumAccount` | varchar(10) | Premium status flag. (Tier 2) |
| 39 | `Evangelist` | varchar(10) | Evangelist/ambassador flag. (Tier 2) |
| 40 | `GuruStatusID` | varchar(10) | Popular Investor status. (Tier 2) |
| 41 | `NumOfGurus` | int | Number of gurus copied. (Tier 2) |
| 42 | `NumOfCopiers` | int | Number of copiers. (Tier 2) |
| 43 | `NumOfRAF` | int | Refer-a-friend count. (Tier 2) |
| 44 | `AccountTypeID` | int | Account type FK. (Tier 2) |
| 45 | `Regulation` | nvarchar | **Resolved** from Dim_Regulation.Name. (Tier 1) |
| 46 | `PlayerLevel` | nvarchar | **Resolved** from Dim_PlayerLevel.Name. (Tier 1) |
| 47 | `AccountStatusID` | int | Account status FK. (Tier 2) |
| 48 | `AccountManagerID` | int | Assigned account manager. (Tier 2) |
| 49 | `HasAvatar` | varchar(10) | Avatar upload flag. (Tier 2) |
| 50 | `AvatarUploadDate` | varchar(50) | Avatar upload timestamp as string. (Tier 2) |
| 51 | `UpdateDate` | varchar(50) | Last update timestamp as string. (Tier 2) |
| 52 | `IsDepositor` | varchar(1) | Has deposited flag. (Tier 2) |
| 53 | `FirstDepositDate` | varchar(50) | First deposit timestamp as string. (Tier 2) |
| 54 | `ID` | bigint | Dim_Customer surrogate key. (Tier 2) |
| 55 | `ExternalID` | nvarchar | External system ID. (Tier 2) |
| 56 | `PlayerStatusReasonID` | int | Status change reason FK. (Tier 2) |
| 57 | `PendingClosureStatusID` | varchar(10) | Pending closure status. (Tier 2) |
| 58 | `CountryIDByIP` | int | Country from IP geolocation. (Tier 2) |
| 59 | `SubSerialID` | int | Sub-serial ID. (Tier 2) |
| 60 | `EvMatchStatus` | int | Electronic verification match. (Tier 2) |
| 61 | `DocumentStatusID` | int | Document status FK. (Tier 2) |
| 62 | `RegulationChangeDate` | varchar(50) | Regulation transfer date as string. (Tier 2) |
| 63 | `IsCopyBlocked` | varchar(1) | Copy blocked flag. (Tier 2) |
| 64 | `WorldCheckID` | int | AML world check ID. (Tier 2) |
| 65 | `IsEDD` | varchar(1) | Enhanced Due Diligence flag. (Tier 2) |
| 66 | `SuitabilityTestStatusID` | int | MiFID suitability test. (Tier 2) |
| 67 | `FirstDepositAmount` | decimal(19,4) | First deposit amount. (Tier 2) |
| 68 | `PrivacyPolicyID` | int | Privacy policy version. (Tier 2) |
| 69 | `MifidCategorizationID` | int | MiFID categorization FK. (Tier 2) |
| 70 | `IsEmailVerified` | bit | Email verified flag. (Tier 2) |
| 71 | `IsValidCustomer` | bit | Valid customer flag. (Tier 2) |
| 72 | `DesignatedRegulationID` | int | Designated regulation FK. (Tier 2) |
| 73 | `RegionByIP_ID` | int | Region from IP. (Tier 2) |
| 74 | `ScreeningStatusID` | int | AML screening status. (Tier 2) |
| 75 | `RegionID` | int | Customer region FK. (Tier 2) |
| 76 | `WorldCheckResultsUpdated` | varchar(50) | AML results update timestamp as string. (Tier 2) |
| 77 | `HasWallet` | bit | Crypto wallet flag. (Tier 2) |
| 78 | `IsAddressProof` | bit | Address proof submitted. (Tier 2) |
| 79 | `IsAddressProofExpiryDate` | varchar(50) | Address proof expiry as string. (Tier 2) |
| 80 | `IsIDProof` | bit | ID proof submitted. (Tier 2) |
| 81 | `IsIDProofExpiryDate` | varchar(50) | ID proof expiry as string. (Tier 2) |
| 82 | `PhoneVerifiedID` | int | Phone verification status. (Tier 2) |
| 83 | `CitizenshipCountryID` | int | Citizenship country FK. (Tier 2) |
| 84 | `PlayerStatusSubReasonID` | int | Detailed status reason. (Tier 2) |
| 85 | `IsCreditReportValidCB` | bit | Credit bureau validity. (Tier 2) |
| 86 | `CashoutFeeGroupID` | int | Cashout fee group FK. (Tier 2) |
| 87 | `MiddleName` | nvarchar | Middle name. (Tier 2) |
| 88 | `BuildingNumber` | nvarchar | Building number. (Tier 2) |
| 89 | `SalesForceAccountID` | nvarchar | Salesforce CRM ID. (Tier 2) |
| 90 | `POBCountryID` | int | Place of birth country. (Tier 2) |
| 91 | `ApexID` | nvarchar | Apex clearing ID. (Tier 2) |

## 4. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| INNER JOINs may filter | Medium | Uses INNER JOIN for all 7 lookups — customers missing dimension entries will be excluded |
| String-cast dates | Low | Date columns cast to VARCHAR(50) — consumers cannot directly filter/sort as dates |

---
*Generated: 2026-03-19 | Quality: 8/10 | Denormalized 91-column customer dimension view*
