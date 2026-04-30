# Customer.ContactUserInfo

> Core user profile table storing contact and geographic data: email, phone, address, country, citizenship, region, and email verification status.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + unique on LowerEmail) |

---

## 1. Business Meaning

Customer.ContactUserInfo is one of the four core user profile tables, storing all contact and geographic information. It holds the user's email (with a computed lowercase version for case-insensitive lookups), phone numbers, physical address, and multiple country references: country of residence (CountryID), country detected by IP (CountryIDByIP), citizenship country (CitizenshipCountryID), and place of birth country (POBCountryID).

This table is central to communication, regulatory routing, and fraud detection. The email is the primary communication channel and login identifier. Country fields drive regulatory assignment, KYC requirements, and geo-compliance. Changes trigger history and sync events (EntityType=2 for ContactInfo).

---

## 2. Business Logic

### 2.1 Multi-Country Tracking

**What**: Four distinct country references per user serving different compliance purposes.

**Columns/Parameters Involved**: `CountryID`, `CountryIDByIP`, `CitizenshipCountryID`, `POBCountryID`

**Rules**:
- CountryID: self-declared country of residence - primary driver for regulation assignment
- CountryIDByIP: IP-detected country at registration - used for fraud detection (mismatch with declared country)
- CitizenshipCountryID: nationality for tax reporting (CRS) and sanctions screening
- POBCountryID: place of birth country for enhanced KYC in some jurisdictions

### 2.2 Email Uniqueness

**What**: Case-insensitive email uniqueness enforced via computed column.

**Columns/Parameters Involved**: `Email`, `LowerEmail`

**Rules**:
- LowerEmail is a PERSISTED computed column: LOWER(Email)
- Unique index on LowerEmail ensures no two users share the same email (case-insensitive)

---

## 3. Data Overview

N/A - transactional table with millions of rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID. |
| 2 | CountryID | int | NO | 0 | CODE-BACKED | Self-declared country of residence. FK to Dictionary.Country. Primary driver for regulation assignment. Default: 0. See [Country](_glossary.md#country). |
| 3 | CountryIDByIP | int | NO | - | CODE-BACKED | Country detected from IP address at registration. Used for fraud detection (IP vs declared country mismatch). |
| 4 | CitizenshipCountryID | int | YES | - | CODE-BACKED | Nationality/citizenship country. FK to Dictionary.Country. Used for CRS tax reporting and sanctions screening. |
| 5 | POBCountryID | int | YES | - | CODE-BACKED | Place of birth country. FK to Dictionary.Country. Required by some regulations for enhanced KYC. |
| 6 | RegionID | int | YES | - | CODE-BACKED | User's declared region within their country. Implicit FK to Dictionary.RegionByIP. |
| 7 | RegionByIP_ID | int | YES | - | CODE-BACKED | IP-detected region. Implicit FK to Dictionary.RegionByIP. |
| 8 | SubRegionID | int | YES | - | CODE-BACKED | Sub-region within the region. FK to Dictionary.SubRegion. |
| 9 | Email | varchar(50) | YES | - | CODE-BACKED | User's email address. Primary communication channel and login identifier. |
| 10 | Address | nvarchar(100) | YES | - | CODE-BACKED | Street address. Unicode support for international addresses. |
| 11 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building/house number component of the address. |
| 12 | City | nvarchar(50) | YES | - | CODE-BACKED | City name. Unicode support. |
| 13 | StateID | int | NO | 0 | CODE-BACKED | State/province. FK to Dictionary.State. Default: 0. |
| 14 | Zip | nvarchar(50) | YES | - | CODE-BACKED | Postal/ZIP code. |
| 15 | Phone | varchar(30) | YES | - | CODE-BACKED | Full phone number (legacy format). |
| 16 | PhonePrefix | nvarchar(6) | YES | - | CODE-BACKED | International dialing prefix (e.g., +44, +1). |
| 17 | PhoneBody | nvarchar(24) | YES | - | CODE-BACKED | Phone number without prefix. |
| 18 | Mobile | varchar(30) | YES | - | CODE-BACKED | Mobile phone number. |
| 19 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax number (legacy field). |
| 20 | IsEmailVerified | bit | YES | - | CODE-BACKED | Whether the user's email has been verified. True after clicking confirmation link or OAuth login. |
| 21 | EmailVerificationProviderID | int | YES | - | CODE-BACKED | FK to Dictionary.EmailVerificationProvider. How email was verified: 1=eToro, 3=Facebook, 5=Google, 6=Apple. See [Email Verification Provider](_glossary.md#email-verification-provider). |
| 22 | LowerEmail | computed (PERSISTED) | - | - | CODE-BACKED | Computed: LOWER(Email). Persisted for unique index - enforces case-insensitive email uniqueness. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Explicit FK | Country of residence |
| CitizenshipCountryID | Dictionary.Country | Explicit FK | Citizenship country |
| POBCountryID | Dictionary.Country | Explicit FK | Place of birth country |
| StateID | Dictionary.State | Explicit FK | State/province |
| SubRegionID | Dictionary.SubRegion | Explicit FK | Sub-region |
| EmailVerificationProviderID | Dictionary.EmailVerificationProvider | Explicit FK | Email verification method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ContactUserInfo | GCID | Trigger-written | Audit trail |
| Sync.PendingEntityEvents | GCID | Trigger-written | Sync queue (EntityType=2) |
| Customer.GetContactUserInfo | GCID | SP reads | Returns contact data |
| Customer.UpdateContactUserInfo | GCID | SP writes | Updates contact data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ContactUserInfo (table)
  +-- Dictionary.Country (table) [done] (3 FKs)
  +-- Dictionary.State (table) [done]
  +-- Dictionary.SubRegion (table) [done]
  +-- Dictionary.EmailVerificationProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: CountryID, CitizenshipCountryID, POBCountryID |
| Dictionary.State | Table | FK: StateID |
| Dictionary.SubRegion | Table | FK: SubRegionID |
| Dictionary.EmailVerificationProvider | Table | FK: EmailVerificationProviderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ContactUserInfo | Table | Trigger writes audit rows |
| Customer.vContactUserInfo | View | Built on this table |
| Customer.GetContactUserInfo | Stored Procedure | Reads from |
| Customer.UpdateContactUserInfo | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ContactUserInfo | CLUSTERED PK | GCID | - | - | Active |
| IX_ContactInfo_LowerEmail | NONCLUSTERED UNIQUE | LowerEmail | GCID + all other columns | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ContactUserInfo_CountryID | DEFAULT | (0) |
| DF_ContactUserInfo_StateID | DEFAULT | (0) |
| FK_ContactUserInfo_CountryID | FOREIGN KEY | CountryID -> Dictionary.Country |
| FK_ContactUserInfo_CitizenshipCountryID | FOREIGN KEY | CitizenshipCountryID -> Dictionary.Country |
| FK_ContactUserInfo_POBCountryID | FOREIGN KEY | POBCountryID -> Dictionary.Country |
| FK_ContactUserInfo_StateID | FOREIGN KEY | StateID -> Dictionary.State |
| FK_ContactUserInfo_SubRegionID | FOREIGN KEY | SubRegionID -> Dictionary.SubRegion |
| FK_ContactUserInfo_EmailVerificationProviderID | FOREIGN KEY | EmailVerificationProviderID -> Dictionary.EmailVerificationProvider |

---

## 8. Sample Queries

### 8.1 Get contact info with country names
```sql
SELECT c.GCID, c.Email, co.Name AS Country, cit.Name AS Citizenship, c.City, c.Phone
FROM Customer.ContactUserInfo c WITH (NOLOCK)
JOIN Dictionary.Country co WITH (NOLOCK) ON c.CountryID = co.CountryID
LEFT JOIN Dictionary.Country cit WITH (NOLOCK) ON c.CitizenshipCountryID = cit.CountryID
WHERE c.GCID = @GCID
```

### 8.2 Find user by email
```sql
SELECT GCID FROM Customer.ContactUserInfo WITH (NOLOCK) WHERE LowerEmail = LOWER(@Email)
```

### 8.3 IP country vs declared country mismatch
```sql
SELECT c.GCID, co1.Name AS DeclaredCountry, co2.Name AS IPCountry
FROM Customer.ContactUserInfo c WITH (NOLOCK)
JOIN Dictionary.Country co1 WITH (NOLOCK) ON c.CountryID = co1.CountryID
JOIN Dictionary.Country co2 WITH (NOLOCK) ON c.CountryIDByIP = co2.CountryID
WHERE c.CountryID <> c.CountryIDByIP
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.ContactUserInfo | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.ContactUserInfo.sql*
