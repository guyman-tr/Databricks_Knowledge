# Customer.GetManyAggregatedInfo

> The primary batch procedure for retrieving comprehensive aggregated customer profile data - basic info, account info, contact info, risk info, user settings, EV results, and classified document types - for multiple customers in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: full profile + EV results |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyAggregatedInfo is the comprehensive batch customer profile procedure. It aggregates data from 10+ tables to produce a complete customer snapshot including basic demographics, account details, contact information, risk/compliance status, user settings, electronic verification results, and classified document types. This is one of the most heavily used procedures in the Customer schema.

This procedure exists because the application frequently needs a "full profile" view of one or more customers - for admin dashboards, compliance reviews, customer service screens, and aggregated data APIs. Rather than making 6+ separate calls, this single procedure returns everything in two result sets.

The procedure uses temp tables with clustered indexes for performance optimization. It first classifies documents using dbo.CustomerClassifiedDocumentsTable (a table-valued function), then collects data from Real_Customer, Real_BackOfficeCustomer, Customer.CustomerIdentification, Real_ElectronicIdentityCheck, BlockedCustomerOperations, Ev.CustomerResult, General_Settings, Publications, and Dictionary.EvProvider.

---

## 2. Business Logic

### 2.1 Copy Block Detection

**What**: Checks if a customer is blocked from copy trading by looking up BlockedCustomerOperations with OperationTypeID=1.

**Columns/Parameters Involved**: `IsCopyBlocked`, `BlockedCustomerOperations.OperationTypeID`

**Rules**:
- CTE `copyBlock` finds customers with OperationTypeID=1 in BlockedCustomerOperations
- Result: IsCopyBlocked = 1 if blocked, 0 (via ISNULL) if not blocked
- OperationTypeID=1 specifically means "Copy Trading" block

### 2.2 Electronic Verification (EV) Results

**What**: Second result set returns the full EV history sorted by transaction date, with provider type information.

**Columns/Parameters Involved**: `EvStatusId`, `EvProviderId`, `ProviderTypeID`, `TransactionDate`, `TransactionID`, `VerificationType`

**Rules**:
- Joins Ev.CustomerResult with Dictionary.EvProvider for provider type
- Ordered by TransactionDate DESC (most recent first)
- A separate CTE `evResult` in the first result set picks TOP 1 for the inline EvStatusId and EvProviderId columns

### 2.3 Classified Document Types

**What**: Uses dbo.CustomerClassifiedDocumentsTable TVF to produce a comma-separated string of classified document types for each customer.

**Columns/Parameters Involved**: `ClassifiedDocumentTypes` (varchar(500))

**Rules**:
- Stored in #customerDocuments temp table
- CROSS APPLY to the table-valued function per customer
- Result is a flat string of document type codes

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve aggregated info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | RealCID (output) | int | NO | - | CODE-BACKED | CID of the real account. Aliased from CID. |
| 4 | CID (output) | int | NO | - | CODE-BACKED | Customer ID (same as RealCID, included for backward compatibility). |
| 5 | DemoCID (output) | int | YES | - | CODE-BACKED | Demo account CID from Customer.CustomerIdentification. |
| 6 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username. |
| 7 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | User's first name. |
| 8 | LastName (output) | nvarchar | YES | - | CODE-BACKED | User's last name. |
| 9 | MiddleName (output) | nvarchar | YES | - | CODE-BACKED | User's middle name. |
| 10 | Gender (output) | char | YES | - | CODE-BACKED | User's gender. |
| 11 | LanguageID (output) | int | YES | - | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 12 | BirthDate (output) | datetime | YES | - | CODE-BACKED | Date of birth. |
| 13 | PlayerLevelID (output) | int | YES | - | CODE-BACKED | Player level (experience tier). FK to Dictionary.PlayerLevel. |
| 14 | Lei (output) | varchar | YES | - | CODE-BACKED | Legal Entity Identifier. From Real_BackOfficeCustomer. For corporate/institutional accounts. |
| 15 | OriginalCID (output) | int | YES | - | CODE-BACKED | Original CID before migration. |
| 16 | AffiliateID (output) | int | YES | - | CODE-BACKED | Affiliate serial ID. Aliased from SerialID. |
| 17 | WhiteLabelID (output) | int | YES | - | CODE-BACKED | Brand/white label. Aliased from LabelID. |
| 18 | AccountTypeID (output) | int | YES | - | CODE-BACKED | Account type classification. |
| 19 | CreatedOn (output) | datetime | YES | - | CODE-BACKED | Registration date. Aliased from Registered. |
| 20 | TradeLevelID (output) | int | YES | - | CODE-BACKED | Trading authorization level. |
| 21 | CurrencyID (output) | int | YES | - | CODE-BACKED | Account base currency. |
| 22 | PendingClosureStatusID (output) | int | YES | - | CODE-BACKED | Pending closure status. |
| 23 | AccountStatusID (output) | int | YES | - | CODE-BACKED | Account status. |
| 24 | MasterAccountCID (output) | int | YES | - | CODE-BACKED | Master account for sub-accounts. |
| 25 | ManagerID (output) | int | YES | - | CODE-BACKED | Assigned account manager. |
| 26 | SubSerialID (output) | int | YES | - | CODE-BACKED | Sub-affiliate ID. |
| 27 | GuruStatusID (output) | int | YES | - | CODE-BACKED | Popular Investor status. |
| 28 | FunnelFromID (output) | int | YES | - | CODE-BACKED | Registration funnel source. |
| 29 | DownloadID (output) | int | YES | - | CODE-BACKED | Download/install tracking ID. |
| 30 | ReferralID (output) | int | YES | - | CODE-BACKED | Referral program tracking ID. |
| 31 | CountryID (output) | int | YES | - | CODE-BACKED | Registered country. |
| 32 | Email (output) | nvarchar | YES | - | CODE-BACKED | Email address. |
| 33 | Address (output) | nvarchar | YES | - | CODE-BACKED | Street address. |
| 34 | City (output) | nvarchar | YES | - | CODE-BACKED | City. |
| 35 | Zip (output) | varchar | YES | - | CODE-BACKED | Postal/ZIP code. |
| 36 | Phone (output) | varchar | YES | - | CODE-BACKED | Full phone number. |
| 37 | PhonePrefix (output) | varchar | YES | - | CODE-BACKED | Phone country code prefix. |
| 38 | PhoneBody (output) | varchar | YES | - | CODE-BACKED | Phone number without prefix. |
| 39 | Mobile (output) | varchar | YES | - | CODE-BACKED | Mobile phone number. |
| 40 | Fax (output) | varchar | YES | - | CODE-BACKED | Fax number (legacy). |
| 41 | StateID (output) | int | YES | - | CODE-BACKED | State/province. FK to Dictionary.State. |
| 42 | CountryIDByIP (output) | int | YES | - | CODE-BACKED | Country detected from IP address. |
| 43 | CitizenshipCountryID (output) | int | YES | - | CODE-BACKED | Country of citizenship. |
| 44 | POBCountryID (output) | int | YES | - | CODE-BACKED | Country of birth (Place of Birth). |
| 45 | BuildingNumber (output) | nvarchar | YES | - | CODE-BACKED | Building/house number. |
| 46 | RegionID (output) | int | YES | - | CODE-BACKED | Region. |
| 47 | RegionByIP_ID (output) | int | YES | - | CODE-BACKED | Region detected from IP address. |
| 48 | SubRegionID (output) | int | YES | - | CODE-BACKED | Sub-region. FK to Dictionary.SubRegion. |
| 49 | RegulationID (output) | int | YES | - | CODE-BACKED | Primary regulation. FK to Dictionary.Regulation. |
| 50 | DocumentStatusID (output) | int | YES | - | CODE-BACKED | Document verification status. |
| 51 | PhoneVerifiedID (output) | int | YES | - | CODE-BACKED | Phone verification status. |
| 52 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. |
| 53 | VerifiedBy (output) | varchar | YES | - | CODE-BACKED | Who/what verified the customer. |
| 54 | VerifiedByProvider (output) | varchar | YES | - | CODE-BACKED | Verification provider name. |
| 55 | GDCCheckID (output) | int | YES | - | CODE-BACKED | Electronic identity check ID. From Real_ElectronicIdentityCheck. |
| 56 | ClassifiedDocumentTypes (output) | varchar(500) | YES | - | CODE-BACKED | Comma-separated string of classified document type codes from CustomerClassifiedDocumentsTable TVF. |
| 57 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status. FK to Dictionary.PlayerStatus. |
| 58 | PlayerStatusReasonID (output) | int | YES | - | CODE-BACKED | Reason for current player status. FK to Dictionary.PlayerStatusReasons. |
| 59 | SuitabilityTestStatusID (output) | int | YES | - | CODE-BACKED | MiFID suitability test status. |
| 60 | IsCopyBlocked (output) | int | NO | 0 | CODE-BACKED | 1 if customer is blocked from copy trading (OperationTypeID=1 in BlockedCustomerOperations), 0 otherwise. |
| 61 | EvProviderId (output) | int | YES | - | CODE-BACKED | Most recent EV provider ID. |
| 62 | EvResultsStatus (output) | int | YES | - | CODE-BACKED | Most recent EV status. Aliased from EvStatusId. |
| 63 | KycState (output) | int | YES | - | CODE-BACKED | KYC state machine value. |
| 64 | MifidCategorizationID (output) | int | YES | - | CODE-BACKED | MiFID client categorization. FK to Dictionary.MifidCategorization. |
| 65 | AsicClassificationID (output) | int | YES | - | CODE-BACKED | ASIC classification. FK to Dictionary.AsicClassification. |
| 66 | SeychellesCategorizationID (output) | int | YES | - | CODE-BACKED | Seychelles regulation categorization. FK to Dictionary.SeychellesCategorization. |
| 67 | DesignatedRegulationID (output) | int | YES | - | CODE-BACKED | Designated regulation override. FK to Dictionary.Regulation. |
| 68 | TradingRiskStatusID (output) | int | YES | - | CODE-BACKED | Trading risk assessment status. |
| 69 | PlayerStatusSubReasonID (output) | int | YES | - | CODE-BACKED | Sub-reason for player status. FK to Dictionary.PlayerStatusSubReasons. |
| 70 | PlayerStatusSubReasonComment (output) | nvarchar | YES | - | CODE-BACKED | Free-text comment for player status sub-reason. |
| 71 | EIDStatusID (output) | int | YES | - | CODE-BACKED | Electronic ID verification status. |
| 72 | OnboardingRiskClassificationID (output) | int | YES | - | CODE-BACKED | Onboarding risk classification. |
| 73 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version accepted. |
| 74 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Privacy setting: allow public full name display. From General_Settings. |
| 75 | AllowShareFollow (output) | bit | YES | - | CODE-BACKED | Privacy setting: allow sharing and following. From General_Settings. |
| 76 | HomepageId (output) | int | YES | - | CODE-BACKED | User homepage preference. From General_Settings. |
| 77 | OptOutReasonID (output) | int | YES | - | CODE-BACKED | Reason for opting out of communications. |
| 78 | EvMatchStatus (output) | int | YES | - | CODE-BACKED | EV match status from Real_BackOfficeCustomer. |
| 79 | AboutMe (output) | nvarchar | YES | - | CODE-BACKED | User bio. From Publications. |
| 80 | AboutMeShort (output) | nvarchar | YES | - | CODE-BACKED | Short user bio. From Publications. |
| 81 | BioLanguage (output) | varchar | YES | - | CODE-BACKED | Language code for bio. Aliased from LanguageCode in Publications. |
| 82 | StrategyID (output) | int | YES | - | CODE-BACKED | Investment strategy ID. From Publications. |
| 83 | IsEmailVerified (output) | bit | YES | - | CODE-BACKED | Whether email has been verified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Core customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Back-office/risk data |
| GCID | Customer.CustomerIdentification | LEFT JOIN | DemoCID |
| CID | dbo.Real_ElectronicIdentityCheck | LEFT JOIN | GDC check ID |
| CID | dbo.BlockedCustomerOperations | LEFT JOIN | Copy block status |
| GCID | Ev.CustomerResult | LEFT JOIN | Electronic verification results |
| CID | dbo.General_Settings | LEFT JOIN | Privacy and homepage settings |
| CID | dbo.Publications | LEFT JOIN | User bio/about me |
| GCID | dbo.CustomerClassifiedDocumentsTable | CROSS APPLY | Document classification TVF |
| EvProviderId | Dictionary.EvProvider | LEFT JOIN | EV provider type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetManyAggregatedInfo_RAN | - | EXEC | Rate-limiting wrapper calls this SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyAggregatedInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_ElectronicIdentityCheck (table)
+-- dbo.BlockedCustomerOperations (table)
+-- Ev.CustomerResult (table)
+-- dbo.General_Settings (table)
+-- dbo.Publications (table)
+-- dbo.CustomerClassifiedDocumentsTable (function)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | INTO #RealCustomer - core customer data |
| dbo.Real_BackOfficeCustomer | Table | JOIN on CID - risk and account data |
| Customer.CustomerIdentification | Table | LEFT JOIN - DemoCID |
| dbo.Real_ElectronicIdentityCheck | Table | LEFT JOIN - GDC check |
| dbo.BlockedCustomerOperations | Table | CTE copyBlock - copy trading block |
| Ev.CustomerResult | Table | CTE evResult + second result set - EV history |
| dbo.General_Settings | Table | LEFT JOIN - privacy settings |
| dbo.Publications | Table | LEFT JOIN - user bio |
| dbo.CustomerClassifiedDocumentsTable | TVF | CROSS APPLY - document classification |
| Dictionary.EvProvider | Table | LEFT JOIN - EV provider type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetManyAggregatedInfo_RAN | Stored Procedure | EXEC - rate-limiting wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Catches errors and prints server/DB/procedure/error details before re-throwing |

---

## 8. Sample Queries

### 8.1 Get aggregated info for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002), (1003)
EXEC Customer.GetManyAggregatedInfo @ids = @ids
```

### 8.2 Get aggregated info for a single customer
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (50001)
EXEC Customer.GetManyAggregatedInfo @ids = @ids
-- Returns 2 result sets: full profile + EV results
```

### 8.3 Check copy block status directly
```sql
SELECT cc.GCID, 1 AS IsCopyBlocked
FROM dbo.Real_Customer cc WITH (NOLOCK)
JOIN dbo.BlockedCustomerOperations bco WITH (NOLOCK) ON bco.CID = cc.CID
WHERE cc.GCID = @GCID AND bco.OperationTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 83 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyAggregatedInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyAggregatedInfo.sql*
