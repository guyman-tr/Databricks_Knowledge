# Customer.CustomerSafty

> Security-safe customer view: identical to Customer.Customer except Password is replaced with an empty string and 8 additional sensitive/internal columns are omitted. Used wherever the password hash must not be exposed.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CustomerSafty (note: name misspells "Safety" as "Safty") is the password-masked variant of Customer.Customer. It reads directly from Customer.Customer (WITH (NOLOCK)) and returns the full customer profile with two security changes: the Password column is replaced with `'' AS Password` (empty string), and 8 columns present in Customer.Customer are omitted entirely.

The view is used by consumers that need customer data but must not receive the password hash - typically read-only reporting, BackOffice display, and external integrations. The SCHEMABINDING is declared, locking the Customer.Customer schema.

**Columns present in Customer.Customer but NOT in Customer.CustomerSafty:**
- IsHedged - internal broker-side hedge flag
- LowerEmail - computed email lowercase (computed in CustomerStatic)
- PhonePrefix - structured phone prefix field
- PhoneBody - structured phone body field
- RegionID - geographic region
- RegionByIP_ID - IP-detected region
- PlatformID - platform/product ID
- DltID - DLT/blockchain integration ID

The exact reason for omitting these 8 columns is not documented in the DDL. They may have been added to Customer.Customer after CustomerSafty was created and not yet backported, or may be intentionally excluded for downstream compatibility reasons.

---

## 2. Business Logic

### 2.1 Password Masking

**What**: The Password column is deliberately replaced with an empty string to prevent accidental exposure of password hashes.

**Columns/Parameters Involved**: `Password`

**Rules**:
- `'' as Password` - always returns empty string, regardless of the actual hashed value in CustomerStatic
- The column position (element #22) and name are preserved so existing consumers expecting the Password column by position or name still work
- Password is varchar(20) in CustomerStatic - empty string is compatible

---

## 3. Data Overview

Data is identical to Customer.Customer (see that view) except Password is always '' and 8 columns are absent.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.Customer. |
| 2 | OriginalProviderID | int | NO | - | CODE-BACKED | Original provider ID. From Customer.Customer. |
| 3 | OriginalCID | int | NO | - | CODE-BACKED | Original CID before migration. From Customer.Customer. |
| 4 | ProviderID | int | NO | - | VERIFIED | Trading provider ID. From Customer.Customer. |
| 5 | RealProviderID | int | YES | - | CODE-BACKED | Real/underlying provider ID. From Customer.Customer. |
| 6 | CountryID | int | NO | - | VERIFIED | Country of residence. From Customer.Customer. |
| 7 | CountryIDByIP | int | NO | - | CODE-BACKED | Country from IP at registration. From Customer.Customer. |
| 8 | CitizenshipCountryID | int | YES | - | VERIFIED | Country of citizenship. From Customer.Customer. |
| 9 | StateID | int | NO | - | VERIFIED | US state (or 0). From Customer.Customer. |
| 10 | LanguageID | int | NO | - | VERIFIED | Platform language. From Customer.Customer. |
| 11 | CommunicationLanguageID | int | NO | - | CODE-BACKED | Communication language. From Customer.Customer. |
| 12 | CurrencyID | int | NO | - | VERIFIED | Account base currency. From Customer.Customer. |
| 13 | TimeZoneID | int | NO | - | VERIFIED | Time zone preference. From Customer.Customer. |
| 14 | PlayerStatusID | int | NO | - | VERIFIED | Compliance status. From Customer.Customer. |
| 15 | CampaignID | int | YES | - | VERIFIED | Marketing campaign. From Customer.Customer. |
| 16 | PlayerLevelID | int | NO | - | VERIFIED | Customer tier. From Customer.Customer. |
| 17 | TradeLevelID | int | NO | - | VERIFIED | Trading knowledge level. From Customer.Customer. |
| 18 | SpreadGroupID | int | NO | - | VERIFIED | Pricing group. From Customer.Customer. |
| 19 | LabelID | int | NO | - | VERIFIED | Segment label. From Customer.Customer. |
| 20 | FunnelID | int | YES | - | VERIFIED | Acquisition funnel. From Customer.Customer. |
| 21 | UserName | varchar(20) | NO | - | VERIFIED | Login username. From Customer.Customer. |
| 22 | Password | varchar | NO | - | VERIFIED | Always empty string (''). Masked for security - never returns the actual password hash. Original in CustomerStatic is a hashed varchar(20). |
| 23 | Registered | datetime | NO | - | VERIFIED | Registration date. From Customer.Customer. |
| 24 | IsReal | bit | NO | - | VERIFIED | Real (1) or demo (0). From Customer.Customer. |
| 25 | IP | varchar(15) | NO | - | VERIFIED | Registration IP (Dynamic Data Masking applies). From Customer.Customer. |
| 26 | Credit | money | YES | - | VERIFIED | Available trading balance. From Customer.Customer (LEFT JOIN from CustomerMoney - may be NULL). |
| 27 | BirthDate | datetime | YES | - | VERIFIED | Date of birth (Dynamic Data Masking). From Customer.Customer. |
| 28 | Gender | char(1) | YES | - | VERIFIED | Gender: 'M', 'F', 'U'. From Customer.Customer. |
| 29 | FirstName | nvarchar(50) | YES | - | VERIFIED | First name (Dynamic Data Masking). From Customer.Customer. |
| 30 | LastName | nvarchar(50) | YES | - | VERIFIED | Last name (Dynamic Data Masking). From Customer.Customer. |
| 31 | MiddleName | nvarchar(50) | YES | - | VERIFIED | Middle name (Dynamic Data Masking). From Customer.Customer. |
| 32 | Address | nvarchar(100) | YES | - | VERIFIED | Address (Dynamic Data Masking). From Customer.Customer. |
| 33 | City | nvarchar(50) | YES | - | CODE-BACKED | City. From Customer.Customer. |
| 34 | Zip | nvarchar(50) | YES | - | VERIFIED | Postal code (Dynamic Data Masking). From Customer.Customer. |
| 35 | SerialID | int | YES | - | VERIFIED | Affiliate ID. From Customer.Customer. |
| 36 | ReferralID | int | YES | - | CODE-BACKED | Referral CID. From Customer.Customer. |
| 37 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-affiliate string. From Customer.Customer. |
| 38 | Email | varchar(50) | YES | - | VERIFIED | Email (Dynamic Data Masking). From Customer.Customer. |
| 39 | IsEmailVerified | bit | YES | - | CODE-BACKED | Email verified flag. From Customer.Customer. |
| 40 | Phone | varchar(30) | YES | - | VERIFIED | Phone (Dynamic Data Masking). From Customer.Customer. |
| 41 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax number. From Customer.Customer. |
| 42 | Mobile | varchar(30) | YES | - | VERIFIED | Mobile (Dynamic Data Masking). From Customer.Customer. |
| 43 | Comments | varchar(8000) | YES | - | CODE-BACKED | Operator notes. From Customer.Customer. |
| 44 | DownloadID | int | YES | - | CODE-BACKED | Download source ID. From Customer.Customer. |
| 45 | BannerID | int | YES | - | CODE-BACKED | Banner acquisition ID. From Customer.Customer. |
| 46 | ClientVersion | varchar(20) | YES | - | CODE-BACKED | Client version. From Customer.Customer. |
| 47 | PersonID | varchar(50) | YES | - | CODE-BACKED | External person ID. From Customer.Customer. |
| 48 | BonusCredit | money | YES | - | VERIFIED | Bonus credit. From Customer.Customer. |
| 49 | DownloadCounter | int | YES | - | CODE-BACKED | Download count. From Customer.Customer. |
| 50 | AccountExpirationDate | datetime | YES | - | CODE-BACKED | Demo expiry. From Customer.Customer. |
| 51 | HelpDeskType | smallint | YES | - | CODE-BACKED | Support tier. From Customer.Customer. |
| 52 | LotCountGroupID | int | NO | - | VERIFIED | Lot group. From Customer.Customer. |
| 53 | PrivacyPolicyID | int | YES | - | VERIFIED | Privacy policy version. From Customer.Customer. |
| 54 | GCID | int | YES | - | VERIFIED | Group Customer ID. From Customer.Customer. |
| 55 | WeekendFeePrecentage | tinyint | YES | - | CODE-BACKED | Weekend fee %. From Customer.Customer. |
| 56 | IsEmailActivated | tinyint | YES | - | CODE-BACKED | Email activation status. From Customer.Customer. |
| 57 | UserName_LOWER | computed | YES | - | CODE-BACKED | lower(UserName). From Customer.Customer. |
| 58 | RealizedEquity | money | YES | - | VERIFIED | Realized account value. From Customer.Customer. |
| 59 | AccountStatusID | tinyint | YES | - | VERIFIED | Account status. From Customer.Customer. |
| 60 | PendingClosureStatusID | tinyint | YES | - | CODE-BACKED | Pending closure status. From Customer.Customer. |
| 61 | ClientTypeID | tinyint | YES | - | VERIFIED | Client type (MiFID2). From Customer.Customer. |
| 62 | IsRequestedCall | bit | YES | - | CODE-BACKED | Callback requested. From Customer.Customer. |
| 63 | FunnelFromID | int | YES | - | CODE-BACKED | Funnel source. From Customer.Customer. |
| 64 | LeverageType | int | YES | - | CODE-BACKED | Leverage scheme. From Customer.Customer. |
| 65 | TotalCash | money | YES | - | VERIFIED | Total cash balance. From Customer.Customer. |
| 66 | ID | uniqueidentifier | NO | - | VERIFIED | System GUID. From Customer.Customer. |
| 67 | VerificationTitle | nvarchar(50) | NO | - | CODE-BACKED | KYC verification title. From Customer.Customer. |
| 68 | VerificationTitleVersion | uniqueidentifier | NO | - | CODE-BACKED | Verification version GUID. From Customer.Customer. |
| 69 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building number. From Customer.Customer. |
| 70 | ExternalID | decimal(38,0) | YES | - | VERIFIED | APEX external ID. From Customer.Customer. |
| 71 | BSLRealFunds | money | YES | - | VERIFIED | Balance Stop Loss threshold. From Customer.Customer. |
| 72 | OptOutReasonID | smallint | YES | - | CODE-BACKED | GDPR opt-out reason. From Customer.Customer. |
| 73 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | PlayerStatus reason code. From Customer.Customer. |
| 74 | PlayerStatusSubReasonID | int | YES | - | VERIFIED | PlayerStatus sub-reason code. From Customer.Customer. |
| 75 | PlayerStatusSubReasonComment | varchar(64) | YES | - | CODE-BACKED | Sub-reason comment. From Customer.Customer. |
| 76 | POBCountryID | int | YES | - | VERIFIED | Place of birth country. From Customer.Customer. |
| 77 | SubRegionID | int | YES | - | VERIFIED | Sub-region. From Customer.Customer. |
| 78 | EmailVerificationProviderID | int | YES | - | VERIFIED | Email verification provider. From Customer.Customer. |

*Note: 8 columns from Customer.Customer are absent: IsHedged, LowerEmail, PhonePrefix, PhoneBody, RegionID, RegionByIP_ID, PlatformID, DltID.*

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (base view) | All data sourced from Customer.Customer WITH (NOLOCK) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerSafty (view)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - all 78 output columns |

### 6.2 Objects That Depend On This

No dependents found via search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH SCHEMABINDING | Schema lock | Prevents DROP/ALTER of Customer.Customer while this view exists |

---

## 8. Sample Queries

### 8.1 Get customer profile without password (safe for display)
```sql
SELECT CID, GCID, UserName, Email, FirstName, LastName, CountryID, PlayerStatusID, Credit
FROM Customer.CustomerSafty
WHERE CID = 12345;
```

### 8.2 Find customers by username (case-insensitive)
```sql
SELECT CID, GCID, UserName, Email, IsReal, PlayerStatusID, Registered
FROM Customer.CustomerSafty
WHERE UserName_LOWER = lower('someusername');
```

### 8.3 Active real customers with balance (for reporting)
```sql
SELECT CID, GCID, CountryID, PlayerLevelID, Credit, RealizedEquity, Registered
FROM Customer.CustomerSafty
WHERE IsReal = 1
  AND PlayerStatusID = 1
  AND AccountStatusID = 1
  AND Credit > 0
ORDER BY Credit DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9.8/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 26 VERIFIED, 52 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.CustomerSafty | Type: View | Source: etoro/etoro/Customer/Views/Customer.CustomerSafty.sql*
