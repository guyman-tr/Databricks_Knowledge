# Customer.GetAggregatedInfoByGCID

> Retrieves the complete aggregated user profile for a single user by GCID - joining all four core Customer tables plus UserSettings, Publications, and EV verification results in two result sets.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (single user lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAggregatedInfoByGCID is the primary single-user comprehensive profile retrieval procedure. It returns the full user profile by joining all four core Customer tables (BasicUserInfo, AccountUserInfo, ContactUserInfo, RiskUserInfo) plus CustomerIdentification, UserSettings, Publications, and electronic verification (EV) results.

This procedure is a central data access point for any service needing the complete picture of a user - from basic identity to risk/compliance status to verification history. It serves admin tools, customer support dashboards, and internal services that need the full user context.

The procedure returns two result sets: (1) the full aggregated profile with ~60+ columns covering basic info, account config, contact data, risk/compliance data, user settings, and publications, (2) the user's electronic verification history from Ev.CustomerResult joined with Dictionary.EvProvider for provider type classification.

---

## 2. Business Logic

### 2.1 Latest EV Result Selection (CTE)

**What**: The most recent electronic verification result is selected for inclusion in the main result set.

**Columns/Parameters Involved**: `GCID`, `EvStatusId`, `EvProviderId`

**Rules**:
- A CTE (evResult) selects the TOP 1 row from Ev.CustomerResult ordered by CustomerEvResultId DESC
- This gives the most recent verification attempt
- The latest EvStatusId and EvProviderId are included in the main result set
- The full verification history is returned in result set 2

### 2.2 Dual Result Set Pattern

**What**: Returns both the aggregated profile and the full EV history.

**Rules**:
- Result Set 1: Single row with complete user profile (all core tables JOINed by GCID)
- Result Set 2: All Ev.CustomerResult rows for the GCID, ordered by TransactionDate DESC, with EvProvider type details

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID of the user to retrieve. Used to join all Customer tables and query EV results. |

**Result Set 1 - Aggregated Profile (key columns):**

| # | Element | Source Table | Confidence | Description |
|---|---------|-------------|------------|-------------|
| 1 | GCID | CustomerIdentification | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | CustomerIdentification.CID | CODE-BACKED | Legacy Customer ID. |
| 3 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 4 | UserName | BasicUserInfo | CODE-BACKED | Platform username. |
| 5 | FirstName | BasicUserInfo | CODE-BACKED | First name. |
| 6 | LastName | BasicUserInfo | CODE-BACKED | Last name. |
| 7 | MiddleName | BasicUserInfo | CODE-BACKED | Middle name. |
| 8 | Gender | BasicUserInfo | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 9 | LanguageID | BasicUserInfo | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 10 | BirthDate | BasicUserInfo | CODE-BACKED | Date of birth. |
| 11 | PlayerLevelID | BasicUserInfo | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 12 | OriginalCID | AccountUserInfo | CODE-BACKED | Original legacy CID. |
| 13 | AffiliateID | AccountUserInfo.SerialID | CODE-BACKED | Affiliate partner ID (aliased from SerialID). |
| 14 | WhiteLabelID | AccountUserInfo.LabelID | CODE-BACKED | Brand label. FK to Dictionary.Label. |
| 15 | AccountTypeID | AccountUserInfo | CODE-BACKED | Account type (real/demo/sub). |
| 16 | CreatedOn | BasicUserInfo.Registered | CODE-BACKED | Registration date (aliased from Registered). |
| 17 | TradeLevelID | AccountUserInfo | CODE-BACKED | Trading UI level. FK to Dictionary.TradeLevel. |
| 18 | CurrencyID | AccountUserInfo | CODE-BACKED | Account base currency. |
| 19 | PendingClosureStatusID | AccountUserInfo | CODE-BACKED | Pending closure status. |
| 20 | AccountStatusID | AccountUserInfo | CODE-BACKED | Account operational status. |
| 21 | MasterAccountCID | AccountUserInfo | CODE-BACKED | Parent account for sub-accounts. |
| 22 | ManagerID | AccountUserInfo | CODE-BACKED | Account manager CID. |
| 23 | SubSerialID | AccountUserInfo | CODE-BACKED | Sub-affiliate tracking. |
| 24 | GuruStatusID | AccountUserInfo | CODE-BACKED | Popular Investor tier. FK to Dictionary.GuruStatus. |
| 25 | FunnelFromID | AccountUserInfo | CODE-BACKED | Registration funnel source. |
| 26 | KycState | AccountUserInfo | CODE-BACKED | KYC workflow state. |
| 27 | CountryID | ContactUserInfo | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 28 | Email | ContactUserInfo | CODE-BACKED | Email address. |
| 29 | Address | ContactUserInfo | CODE-BACKED | Street address. |
| 30 | City | ContactUserInfo | CODE-BACKED | City. |
| 31 | Zip | ContactUserInfo | CODE-BACKED | Postal/zip code. |
| 32 | Phone | ContactUserInfo | CODE-BACKED | Phone number. |
| 33 | PhonePrefix | ContactUserInfo | CODE-BACKED | Phone country prefix. |
| 34 | PhoneBody | ContactUserInfo | CODE-BACKED | Phone number body. |
| 35 | Mobile | ContactUserInfo | CODE-BACKED | Mobile number. |
| 36 | Fax | ContactUserInfo | CODE-BACKED | Fax number. |
| 37 | StateID | ContactUserInfo | CODE-BACKED | State/province. FK to Dictionary.State. |
| 38 | CountryIDByIP | ContactUserInfo | CODE-BACKED | IP-detected country. |
| 39 | CitizenshipCountryID | ContactUserInfo | CODE-BACKED | Citizenship country. |
| 40 | POBCountryID | ContactUserInfo | CODE-BACKED | Place of birth country. |
| 41 | BuildingNumber | ContactUserInfo | CODE-BACKED | Building/house number. |
| 42 | RegionID | ContactUserInfo | CODE-BACKED | Geographic region. |
| 43 | RegionByIP_ID | ContactUserInfo | CODE-BACKED | IP-detected region. |
| 44 | SubRegionID | ContactUserInfo | CODE-BACKED | Sub-region. FK to Dictionary.SubRegion. |
| 45 | IsEmailVerified | ContactUserInfo | CODE-BACKED | Email verification status. |
| 46 | EmailVerificationProviderID | ContactUserInfo | CODE-BACKED | Email verification provider. |
| 47 | RegulationID | RiskUserInfo | CODE-BACKED | Regulating entity. FK to Dictionary.Regulation. |
| 48 | DocumentStatusID | RiskUserInfo | CODE-BACKED | Document verification status. |
| 49 | PhoneVerifiedID | RiskUserInfo | CODE-BACKED | Phone verification status. |
| 50 | VerificationLevelID | RiskUserInfo | CODE-BACKED | Verification tier (0-3). FK to Dictionary.VerificationLevel. |
| 51 | VerifiedBy | RiskUserInfo | CODE-BACKED | Who verified the user. |
| 52 | VerifiedByProvider | RiskUserInfo | CODE-BACKED | Verification provider. |
| 53 | PlayerStatusID | RiskUserInfo | CODE-BACKED | Account status. FK to Dictionary.PlayerStatus. |
| 54 | PlayerStatusReasonID | RiskUserInfo | CODE-BACKED | Status reason. FK to Dictionary.PlayerStatusReasons. |
| 55 | SuitabilityTestStatusID | RiskUserInfo | CODE-BACKED | Copy-trading suitability status. |
| 56 | EvProviderId | evResult CTE | CODE-BACKED | Latest EV provider. |
| 57 | EvResultsStatus | evResult CTE | CODE-BACKED | Latest EV verification status (aliased from EvStatusId). |
| 58 | MifidCategorizationID | RiskUserInfo | CODE-BACKED | MiFID client categorization. FK to Dictionary.MifidCategorization. |
| 59 | AsicClassificationID | RiskUserInfo | CODE-BACKED | ASIC client classification. FK to Dictionary.AsicClassification. |
| 60 | DesignatedRegulationID | RiskUserInfo | CODE-BACKED | Designated regulation. |
| 61 | PlayerStatusSubReasonID | RiskUserInfo | CODE-BACKED | Status sub-reason. FK to Dictionary.PlayerStatusSubReasons. |
| 62 | PlayerStatusSubReasonComment | RiskUserInfo | CODE-BACKED | Free-text comment for status sub-reason. |
| 63 | EvMatchStatus | RiskUserInfo | CODE-BACKED | Electronic verification match status. |
| 64 | SeychellesCategorizationID | RiskUserInfo | CODE-BACKED | Seychelles regulation categorization. FK to Dictionary.SeychellesCategorization. |
| 65 | TradingRiskStatusID | RiskUserInfo | CODE-BACKED | Trading risk status. |
| 66 | PrivacyPolicyID | UserSettings | CODE-BACKED | Accepted privacy policy version. |
| 67 | OptOutReasonID | UserSettings | CODE-BACKED | Opt-out reason. |
| 68 | AllowDisplayFullName | UserSettings | CODE-BACKED | Allow public display of full name. |
| 69 | AllowShareFollow | UserSettings | CODE-BACKED | Allow social sharing/following. |
| 70 | HomepageId | UserSettings | CODE-BACKED | Homepage preference. |
| 71 | AboutMe | Publications | CODE-BACKED | User bio text. |
| 72 | AboutMeShort | Publications | CODE-BACKED | Shortened bio text. |
| 73 | BioLanguage | Publications.LanguageCode | CODE-BACKED | Bio language code. |
| 74 | StrategyID | Publications | CODE-BACKED | Trading strategy identifier. |

**Result Set 2 - EV Verification History:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | EvStatusId | Ev.CustomerResult | CODE-BACKED | Verification status for this attempt. |
| 2 | EvProviderId | Ev.CustomerResult | CODE-BACKED | Verification provider. |
| 3 | TransactionDate | Ev.CustomerResult | CODE-BACKED | When the verification was performed. |
| 4 | GCID | Ev.CustomerResult | CODE-BACKED | User identifier. |
| 5 | TransactionID | Ev.CustomerResult | CODE-BACKED | External verification transaction reference. |
| 6 | VerificationType | Ev.CustomerResult | CODE-BACKED | Type of verification performed. |
| 7 | EvProviderTypeId | Dictionary.EvProvider | CODE-BACKED | Provider type classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.CustomerIdentification | JOIN (READER) | GCID/CID/DemoCID resolution |
| (body) | Customer.BasicUserInfo | JOIN (READER) | Name, DOB, gender, language, player level |
| (body) | Customer.AccountUserInfo | JOIN (READER) | Label, trade level, guru status, account type |
| (body) | Customer.ContactUserInfo | JOIN (READER) | Email, phone, address, country, region |
| (body) | Customer.RiskUserInfo | JOIN (READER) | Regulation, verification, player status |
| (body) | Customer.UserSettings | LEFT JOIN (READER) | Privacy, display preferences |
| (body) | Ev.CustomerResult | CTE + SELECT | Electronic verification results |
| (body) | dbo.Publications | LEFT JOIN (READER) | User bio and strategy |
| (body) | Dictionary.EvProvider | JOIN (READER) | EV provider type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by admin tools, support dashboards, internal services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAggregatedInfoByGCID (procedure)
+-- Customer.CustomerIdentification (table)
+-- Customer.BasicUserInfo (table)
+-- Customer.AccountUserInfo (table)
+-- Customer.ContactUserInfo (table)
+-- Customer.RiskUserInfo (table)
+-- Customer.UserSettings (table)
+-- Ev.CustomerResult (table)
+-- dbo.Publications (table/synonym)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN - GCID/CID/DemoCID resolution |
| Customer.BasicUserInfo | Table | JOIN - identity data |
| Customer.AccountUserInfo | Table | JOIN - account configuration |
| Customer.ContactUserInfo | Table | JOIN - contact data |
| Customer.RiskUserInfo | Table | JOIN - risk/compliance data |
| Customer.UserSettings | Table | LEFT JOIN - user preferences |
| Ev.CustomerResult | Table | CTE + SELECT - EV verification history |
| dbo.Publications | Table/Synonym | LEFT JOIN - bio/strategy data |
| Dictionary.EvProvider | Table | JOIN - EV provider classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| TRY/CATCH | Error handling | Logs detailed error info and re-throws |

---

## 8. Sample Queries

### 8.1 Get full profile for a user
```sql
EXEC Customer.GetAggregatedInfoByGCID @GCID = 12345
-- Returns 2 result sets: profile + EV history
```

### 8.2 Equivalent manual query for profile data
```sql
SELECT bi.UserName, bi.FirstName, bi.LastName, ai.GuruStatusID, ri.PlayerStatusID, ri.RegulationID
FROM Customer.CustomerIdentification ui WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ui.GCID
JOIN Customer.AccountUserInfo ai WITH (NOLOCK) ON ai.GCID = ui.GCID
JOIN Customer.RiskUserInfo ri WITH (NOLOCK) ON ri.GCID = ui.GCID
WHERE ui.GCID = 12345
```

### 8.3 Check EV verification history
```sql
SELECT EvStatusId, EvProviderId, TransactionDate, VerificationType
FROM Ev.CustomerResult WITH (NOLOCK)
WHERE GCID = 12345
ORDER BY TransactionDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 82 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetAggregatedInfoByGCID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAggregatedInfoByGCID.sql*
