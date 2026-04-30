# KYP.Affiliate

> Core Know Your Partner (KYP) compliance table storing the verification profile, corporate details, contact/authorized person information, and regulatory status for each affiliate undergoing the KYP onboarding process.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID (INT, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

KYP.Affiliate is the central compliance table for the Know Your Partner verification process. Every affiliate who registers with the platform must go through KYP verification, which collects corporate identity, legal structure, contact person details, authorized representative information, and regulatory declarations (public positions held, illegal activity disclosure). This table tracks both the verification status and the collected compliance data.

Without this table, the platform would have no structured way to store and track affiliate KYP verification progress. Regulatory compliance (anti-money laundering, counter-terrorism financing) requires knowing the identity and business nature of every partner. The KYP process gates commission payments - affiliates cannot receive payouts until verified.

Rows are created by `KYP.CreateAffiliate` when an affiliate enters the KYP flow. The comprehensive `KYP.UpdateAffiliateData` procedure updates all fields using an ISNULL-merge pattern (only non-NULL parameters overwrite existing values). Status transitions are managed by `KYP.UpdateAffiliateKYPStatus`. `KYP.GetAffiliateData` reads this table JOINed with dbo.tblaff_Affiliates to return the full affiliate profile. The table uses SQL Server temporal versioning (SYSTEM_VERSIONING) with history stored in `History.KYPAffiliate`, and dynamic data masking on PII fields (names, addresses, passport numbers, TIN).

---

## 2. Business Logic

### 2.1 KYP Verification Lifecycle

**What**: Tracks the affiliate's progression through the multi-step KYP verification process.

**Columns/Parameters Involved**: `KYPStatusID`, `Progress`, `SubmittedOn`, `CanceledOn`, `PopupDismissed`

**Rules**:
- KYPStatusID maps to Dictionary.KYPStatus: 1=Unavailable, 2=Unverified, 3=In Progress, 4=Submit Pending, 5=Submitted, 6=Cancel Pending, 7=Verified. See [KYP Status](../../_glossary.md#kyp-status).
- Progress is a percentage (0-100) tracking form completion: 25=initial (just created), 45-75=partial, 95=nearly complete (missing docs/terms), 100=fully submitted
- SubmittedOn is set when the affiliate submits their KYP package for review
- CanceledOn is set when a submitted KYP is canceled (returns to editable state)
- PopupDismissed tracks whether the user has dismissed the KYP reminder popup
- UpdateAffiliateKYPStatus and UpdateAffiliateData guard transitions with @AllowedKYPStatusIDs (only allowed status transitions succeed)

**Diagram**:
```
[Unverified (2)] --fill form--> [In Progress (3)] --complete--> [Submit Pending (4)]
                                                                       |
                                                             submit -->|
                                                                       v
                                                                [Submitted (5)]
                                                                   |        |
                                                          approve--|  cancel-|
                                                                   v        v
                                                           [Verified (7)] [Cancel Pending (6)]
                                                                              |
                                                                    return -->|
                                                                              v
                                                                       [In Progress (3)]
```

### 2.2 Three-Person KYP Model

**What**: The KYP form collects details for three distinct roles: the account holder (from tblaff_Affiliates), a contact person, and an authorized person.

**Columns/Parameters Involved**: `ContactPersonSameAsAccount`, `ContactPerson*`, `AuthorizedPersonSameAsAccount`, `AuthorizedPerson*`

**Rules**:
- The account holder's basic info (name, address, phone) is stored in dbo.tblaff_Affiliates (not this table)
- ContactPersonSameAsAccount: when true, the contact person IS the account holder (ContactPerson* fields are unused)
- AuthorizedPersonSameAsAccount: when true, the authorized person IS the account holder
- Each person has: FirstName, LastName, CountryID, City, State, StreetAddress, StreetNumber, PostalCode, Passport
- The authorized person also has: Role, PhoneCountryID, PhoneNumber
- This three-person model supports the regulatory requirement to identify who controls, contacts, and authorizes on behalf of the affiliate entity

### 2.3 Corporate Compliance Declarations

**What**: Regulatory declarations required during KYP onboarding.

**Columns/Parameters Involved**: `FormOfIncorporationID`, `NatureOfBusinessID`, `HeldPublicPositions`, `IllegalActivity`, `TermsAccepted`

**Rules**:
- FormOfIncorporationID: 1=Other, 2=Private, 3=Public (Dictionary.FormOfIncorporation). See [Form Of Incorporation](../../_glossary.md#form-of-incorporation).
- NatureOfBusinessID: 1-8 covering Real Estate, Marketing, Construction, etc. (Dictionary.NatureOfBusiness). See [Nature Of Business](../../_glossary.md#nature-of-business).
- HeldPublicPositions: PEP (Politically Exposed Person) declaration - true if any principal has held public office
- IllegalActivity: declaration of involvement in illegal activities (compliance red flag)
- TermsAccepted: whether the affiliate has accepted the KYP terms and conditions

---

## 3. Data Overview

| AffiliateID | KYPStatusID | Progress | FormOfIncorporationID | NatureOfBusinessID | Meaning |
|---|---|---|---|---|---|
| 61743 | 3 (In Progress) | 25 | NULL | NULL | Newly created KYP record. Affiliate has entered the KYP flow but hasn't started filling in corporate details. Progress 25 is the initial creation value. |
| 60062 | 5 (Submitted) | 100 | 3 (Public) | 6 (Medical) | Fully completed and submitted KYP. Public medical company, all sections filled (100% progress). Awaiting compliance review. Contact person is different from account holder. |
| 60056 | 3 (In Progress) | 95 | 1 (Other) | 4 (Construction) | Nearly complete KYP at 95% - likely missing final document upload or terms acceptance. Construction business with "Other" incorporation form. Contact person same as account holder. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Primary key. References the affiliate in dbo.tblaff_Affiliates. One KYP record per affiliate. |
| 2 | KYPStatusID | int | NO | - | VERIFIED | KYP verification lifecycle state. FK to Dictionary.KYPStatus: 1=Unavailable, 2=Unverified, 3=In Progress, 4=Submit Pending, 5=Submitted, 6=Cancel Pending, 7=Verified. See [KYP Status](../../_glossary.md#kyp-status). Updated by UpdateAffiliateKYPStatus with status transition guards. |
| 3 | Progress | int | NO | - | CODE-BACKED | Form completion percentage (0-100). Initial value 25 (set by CreateAffiliate). Increments as sections are filled. 100 = all required fields completed. |
| 4 | TicketID | nvarchar(50) | YES | - | CODE-BACKED | External compliance ticket identifier (e.g., Jira/ServiceNow ticket). MASKED with default(). Links the KYP submission to the compliance review workflow. |
| 5 | SubmittedOn | datetime | YES | - | CODE-BACKED | Timestamp when the KYP was submitted for compliance review. NULL until submission. Used by UpdateAffiliateData/UpdateAffiliateKYPStatus as a change guard (@AllowWhenNoSignificantChangeAfter). |
| 6 | CanceledOn | datetime | YES | - | CODE-BACKED | Timestamp when a submitted KYP was canceled (returned to editable state). NULL if never canceled. Also used as a change guard. |
| 7 | PopupDismissed | bit | NO | 0 | CODE-BACKED | Whether the affiliate has dismissed the KYP reminder popup in the UI. Default false. Prevents repeated prompting once dismissed. |
| 8 | FormOfIncorporationID | int | YES | - | VERIFIED | Legal structure of the affiliate entity. FK to Dictionary.FormOfIncorporation: 1=Other, 2=Private, 3=Public. See [Form Of Incorporation](../../_glossary.md#form-of-incorporation). NULL until the affiliate fills this section. |
| 9 | FormOfIncorporationOther | nvarchar(50) | YES | - | CODE-BACKED | Free-text description when FormOfIncorporationID=1 (Other). Allows the affiliate to describe their legal structure if not Private or Public. |
| 10 | NatureOfBusinessID | int | YES | - | VERIFIED | Industry sector of the affiliate. FK to Dictionary.NatureOfBusiness: 1=Other, 2=Real Estate, 3=Marketing, 4=Construction, 5=Art, 6=Medical, 7=Education, 8=Design. See [Nature Of Business](../../_glossary.md#nature-of-business). |
| 11 | NatureOfBusinessOther | nvarchar(50) | YES | - | CODE-BACKED | Free-text description when NatureOfBusinessID=1 (Other). |
| 12 | IncorporationCountryID | int | YES | - | CODE-BACKED | Country where the affiliate entity is legally incorporated. FK to dbo.tblaff_Country. |
| 13 | TaxCountryID | int | YES | - | CODE-BACKED | Country where the affiliate entity is tax-resident. May differ from IncorporationCountryID for multinational entities. |
| 14 | Tin | nvarchar(20) | YES | - | CODE-BACKED | Tax Identification Number. MASKED with default(). Country-specific format (e.g., EIN for US, UTR for UK). |
| 15 | OpeningPurpose | nvarchar(80) | YES | - | CODE-BACKED | Stated business purpose for opening an affiliate account. Compliance requirement to understand the affiliate's intended use. |
| 16 | ContactPersonSameAsAccount | bit | YES | - | CODE-BACKED | Whether the contact person is the same as the account holder. When true, ContactPerson* fields are not used - info comes from dbo.tblaff_Affiliates. |
| 17 | ContactPersonFirstName | nvarchar(50) | YES | - | CODE-BACKED | Contact person's first name. MASKED. Only used when ContactPersonSameAsAccount=false. |
| 18 | ContactPersonLastName | nvarchar(50) | YES | - | CODE-BACKED | Contact person's last name. MASKED. |
| 19 | ContactPersonCountryID | int | YES | - | CODE-BACKED | Contact person's country of residence. FK to dbo.tblaff_Country. |
| 20 | ContactPersonCity | nvarchar(100) | YES | - | CODE-BACKED | Contact person's city. MASKED. |
| 21 | ContactPersonState | nvarchar(20) | YES | - | CODE-BACKED | Contact person's state/province. MASKED. |
| 22 | ContactPersonStreetAddress | nvarchar(100) | YES | - | CODE-BACKED | Contact person's street address. MASKED. |
| 23 | ContactPersonStreetNumber | nvarchar(10) | YES | - | CODE-BACKED | Contact person's street number. MASKED. |
| 24 | ContactPersonPostalCode | nvarchar(25) | YES | - | CODE-BACKED | Contact person's postal/ZIP code. MASKED. |
| 25 | ContactPersonPassport | nvarchar(15) | YES | - | CODE-BACKED | Contact person's passport number. MASKED. Used for identity verification. |
| 26 | AuthorizedPersonSameAsAccount | bit | YES | - | CODE-BACKED | Whether the authorized person is the same as the account holder. MASKED. When true, AuthorizedPerson* fields are not used. |
| 27 | AuthorizedPersonFirstName | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's first name. MASKED. The authorized person is legally empowered to act on behalf of the affiliate entity. |
| 28 | AuthorizedPersonLastName | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's last name. MASKED. |
| 29 | AuthorizedPersonRole | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's role/title within the entity (e.g., Director, CEO, Legal Representative). |
| 30 | AuthorizedPersonPhoneCountryID | int | YES | - | CODE-BACKED | Authorized person's phone country code. MASKED. FK to dbo.tblaff_Country. |
| 31 | AuthorizedPersonPhoneNumber | nvarchar(20) | YES | - | CODE-BACKED | Authorized person's phone number. MASKED. |
| 32 | AuthorizedPersonCountryID | int | YES | - | CODE-BACKED | Authorized person's country of residence. FK to dbo.tblaff_Country. |
| 33 | AuthorizedPersonCity | nvarchar(100) | YES | - | CODE-BACKED | Authorized person's city. MASKED. |
| 34 | AuthorizedPersonState | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's state/province. MASKED. |
| 35 | AuthorizedPersonStreetAddress | nvarchar(100) | YES | - | CODE-BACKED | Authorized person's street address. MASKED. |
| 36 | AuthorizedPersonStreetNumber | nvarchar(100) | YES | - | CODE-BACKED | Authorized person's street number. MASKED. |
| 37 | AuthorizedPersonPostalCode | nvarchar(25) | YES | - | CODE-BACKED | Authorized person's postal/ZIP code. MASKED. |
| 38 | AuthorizedPersonPassport | nvarchar(20) | YES | - | CODE-BACKED | Authorized person's passport number. MASKED. |
| 39 | Profession | nvarchar(50) | YES | - | CODE-BACKED | Profession of the primary individual associated with the affiliate. MASKED. Compliance data point. |
| 40 | HeldPublicPositions | bit | YES | - | CODE-BACKED | PEP (Politically Exposed Person) declaration. true = a principal has held public office. MASKED. Triggers enhanced due diligence in the compliance review. |
| 41 | IllegalActivity | bit | YES | - | CODE-BACKED | Declaration of involvement in illegal activities. MASKED. true triggers immediate compliance escalation. Required regulatory disclosure. |
| 42 | TermsAccepted | bit | YES | - | CODE-BACKED | Whether the affiliate has accepted the KYP terms and conditions. Must be true for submission (KYPStatusID transition to 4/5). |
| 43 | IsMigrated | bit | NO | 0 | CODE-BACKED | Whether this KYP record was migrated from a legacy system. Default false. Migrated records may have incomplete fields but are grandfathered. |
| 44 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON containing HostName, AppName, SUserName, SPID, DBName, ObjectName. Auto-generated from system functions. Not persisted. |
| 45 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning start timestamp (GENERATED ALWAYS AS ROW START). Records when this row version became current. |
| 46 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning end timestamp (GENERATED ALWAYS AS ROW END). '9999-12-31' for current rows. Previous versions stored in History.KYPAffiliate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit (shared PK) | References the affiliate's main profile record |
| KYPStatusID | Dictionary.KYPStatus | FK | KYP verification lifecycle status (1-7) |
| FormOfIncorporationID | Dictionary.FormOfIncorporation | FK | Legal structure type (1=Other, 2=Private, 3=Public) |
| NatureOfBusinessID | Dictionary.NatureOfBusiness | FK | Industry sector (1-8) |
| IncorporationCountryID | dbo.tblaff_Country | FK | Country of legal incorporation |
| TaxCountryID | dbo.tblaff_Country | Implicit | Country of tax residency |
| ContactPersonCountryID | dbo.tblaff_Country | Implicit | Contact person's country |
| AuthorizedPersonCountryID | dbo.tblaff_Country | Implicit | Authorized person's country |
| AuthorizedPersonPhoneCountryID | dbo.tblaff_Country | Implicit | Authorized person's phone country code |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.AffiliateCorporateMembers | AffiliateID | FK | Corporate board members/principals |
| KYP.AffiliateCountriesOfOperation | AffiliateID | FK | Countries where affiliate operates |
| KYP.AffiliateKYPDocs | AffiliateID | FK | Uploaded verification documents |
| KYP.AffiliateKYPMarketingMethods | AffiliateID | FK | Marketing methods used by affiliate |
| KYP.CreateAffiliate | - | INSERT (WRITER) | Creates the initial KYP record |
| KYP.GetAffiliateData | - | SELECT (READER) | Reads full KYP profile with JOINs |
| KYP.GetAffiliateKYPStatus | - | SELECT (READER) | Reads status/progress subset |
| KYP.UpdateAffiliateData | - | UPDATE (MODIFIER) | Updates all KYP fields |
| KYP.UpdateAffiliateKYPStatus | - | UPDATE (MODIFIER) | Updates status/progress fields |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no within-schema dependencies (it is the root table).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.KYPStatus | Table (cross-schema) | FK for KYPStatusID |
| Dictionary.FormOfIncorporation | Table (cross-schema) | FK for FormOfIncorporationID |
| Dictionary.NatureOfBusiness | Table (cross-schema) | FK for NatureOfBusinessID |
| dbo.tblaff_Country | Table (cross-schema) | FK for IncorporationCountryID + implicit for 4 other CountryID columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateCorporateMembers | Table | FK on AffiliateID |
| KYP.AffiliateCountriesOfOperation | Table | FK on AffiliateID |
| KYP.AffiliateKYPDocs | Table | FK on AffiliateID |
| KYP.AffiliateKYPMarketingMethods | Table | FK on AffiliateID |
| KYP.CreateAffiliate | SP | INSERT writer |
| KYP.GetAffiliateData | SP | SELECT reader (JOINed with tblaff_Affiliates) |
| KYP.GetAffiliateKYPStatus | SP | SELECT reader (status subset) |
| KYP.UpdateAffiliateData | SP | UPDATE modifier (all fields) |
| KYP.UpdateAffiliateKYPStatus | SP | UPDATE modifier (status fields) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYP_Affiliate | CLUSTERED PK | AffiliateID ASC | - | - | Active |

Data compression: PAGE. Single-index design appropriate for PK-based lookups (all SPs query by AffiliateID).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_KYP_Affiliate | PRIMARY KEY | AffiliateID - one KYP record per affiliate |
| FK_KYP_Affiliate_FormOfIncorporationID | FOREIGN KEY | FormOfIncorporationID -> Dictionary.FormOfIncorporation |
| FK_KYP_Affiliate_IncorporationCountryID | FOREIGN KEY | IncorporationCountryID -> dbo.tblaff_Country |
| FK_KYP_Affiliate_KYPStatusID | FOREIGN KEY | KYPStatusID -> Dictionary.KYPStatus |
| FK_KYP_Affiliate_NatureOfBusinessID | FOREIGN KEY | NatureOfBusinessID -> Dictionary.NatureOfBusiness |
| DF_KYP_Affiliate_PopupDismissed | DEFAULT | 0 for PopupDismissed |
| DF_KYP_Affiliate_IsMigrated | DEFAULT | 0 for IsMigrated |

Temporal: SYSTEM_VERSIONING ON with history table History.KYPAffiliate. PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo).

Dynamic Data Masking: Applied to 20+ PII columns (names, addresses, passport, TIN, phone numbers) using default() mask function.

---

## 8. Sample Queries

### 8.1 Get KYP status summary for an affiliate
```sql
SELECT AffiliateID, KYPStatusID, Progress, SubmittedOn, IsMigrated
FROM KYP.Affiliate WITH (NOLOCK)
WHERE AffiliateID = 60062
```

### 8.2 Find affiliates pending compliance review
```sql
SELECT a.AffiliateID, a.Progress, a.SubmittedOn, a.FormOfIncorporationID, a.NatureOfBusinessID
FROM KYP.Affiliate a WITH (NOLOCK)
INNER JOIN Dictionary.KYPStatus s WITH (NOLOCK) ON a.KYPStatusID = s.KYPStatusID
WHERE s.Name = 'Submitted'
```

### 8.3 View temporal history of KYP status changes
```sql
SELECT AffiliateID, KYPStatusID, Progress, ValidFrom, ValidTo
FROM KYP.Affiliate
FOR SYSTEM_TIME ALL
WHERE AffiliateID = 60062
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 9.6/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 44 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.Affiliate | Type: Table | Source: fiktivo/KYP/Tables/KYP.Affiliate.sql*
