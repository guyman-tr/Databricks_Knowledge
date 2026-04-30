# Apex.UserData

> Master record of customer personal, identification, and compliance data collected during the Apex Clearing brokerage account onboarding process, with dynamic data masking on PII fields.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserData is the master customer profile table for the Apex brokerage account onboarding system. It stores all personal information collected from customers during account application: legal name, date of birth, SSN, citizenship, address, phone, email, and regulatory disclosure answers (control person, FINRA affiliation, politically exposed person status). This is the single source of truth for customer identity data within the Apex integration.

This table is essential because every Apex Clearing API call for account creation or update draws its customer data from here. The data must be accurate and complete to satisfy KYC (Know Your Customer), CIP (Customer Identification Program), and AML (Anti-Money Laundering) regulatory requirements. Dynamic data masking is applied to all PII columns (names, DOB, SSN, phone, email, address) to protect customer privacy for unauthorized database users.

Data is written by Apex.SaveUserData (upsert) and Apex.SaveUserDataApproveInfo (sets approver name and date). Read by Apex.GetUserData, GetApexDataAndState, GetUserCid. System versioning (History.UserData) maintains full change history for regulatory audit purposes. Deletion by DeleteUserData for account cleanup.

---

## 2. Business Logic

### 2.1 Regulatory Disclosure Flags

**What**: Three boolean columns capture mandatory regulatory disclosures that affect account processing and compliance monitoring.

**Columns/Parameters Involved**: `IsControlPerson`, `IsAffiliatedExchangeOrFINRA`, `IsPoliticallyExposed`

**Rules**:
- IsControlPerson: Whether the customer is a director, 10% shareholder, or policy-making officer of a publicly traded company. Requires disclosure of company symbols (DisclosureCompanySymbols).
- IsAffiliatedExchangeOrFINRA: Whether the customer is employed by or associated with a FINRA member firm or stock exchange. Requires disclosure of firm name (DisclosureFirmName) and triggers AffiliatedApprovalRequired state (ApexStateID=36).
- IsPoliticallyExposed: Whether the customer is a Politically Exposed Person (PEP). Triggers enhanced due diligence and may require additional documentation (PepAdditionalData).
- All three default to false. True values trigger additional compliance workflows.

### 2.2 Account Approval Workflow

**What**: Manual approval tracking for accounts requiring compliance review.

**Columns/Parameters Involved**: `ApproverName`, `ApprovedByDate`

**Rules**:
- NULL ApproverName/ApprovedByDate indicates no manual approval was needed or it hasn't occurred yet
- Set by SaveUserDataApproveInfo when a compliance officer approves the account
- Required for affiliated persons, PEPs, and certain visa holders

### 2.3 Visa Holder Processing

**What**: US visa holders require additional verification of their visa type and expiration before account approval.

**Columns/Parameters Involved**: `UsVisaHolder`, `VisaType`, `VisaExpirationDate`

**Rules**:
- UsVisaHolder=true triggers visa verification workflow (ApexStateID=46 VisaApprovalRequired)
- VisaType is the visa classification (e.g., H1B, F1, L1)
- VisaExpirationDate determines if the visa is still valid
- NULL values indicate customer is not a visa holder (US citizen or permanent resident)

---

## 3. Data Overview

| GCID | AccountTypeID | CustomerTypeID | PhoneTypeID | PermanentResident | IsControlPerson | IsAffiliated | IsPEP | UsVisaHolder | Meaning |
|------|--------------|---------------|-------------|------------------|----------------|-------------|-------|-------------|---------|
| 19533157 | 2 (MARGIN) | 1 (INDIVIDUAL) | 3 (Mobile) | true | false | false | false | false | Standard individual margin account. US permanent resident with no regulatory disclosures. Most common customer profile. |
| 22055177 | 2 (MARGIN) | 1 (INDIVIDUAL) | 3 (Mobile) | true | false | false | false | false | Same standard profile. MARGIN account type is dominant - most US customers open margin-enabled accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. One user data record per customer. |
| 2 | AccountTypeID | int | NO | - | VERIFIED | Brokerage account type. FK to Dictionary.AccountType: 1=CASH, 2=MARGIN, 3=OPTION. See [Account Type](_glossary.md#account-type). Observed: most customers have MARGIN (2). (Dictionary.AccountType) |
| 3 | CustomerTypeID | int | NO | - | VERIFIED | Account ownership structure. FK to Dictionary.CustomerType: 1=INDIVIDUAL, 2=IRA, 3=JOINT, 4=CUSTODIAN. See [Customer Type](_glossary.md#customer-type). (Dictionary.CustomerType) |
| 4 | FirstName | nvarchar(50) MASKED | NO | - | CODE-BACKED | Customer's first name. Dynamic data masking applied. Uppercase format for Apex API compatibility. |
| 5 | LastName | nvarchar(50) MASKED | NO | - | CODE-BACKED | Customer's last/family name. Dynamic data masking applied. |
| 6 | MiddleName | nvarchar(50) MASKED | NO | - | CODE-BACKED | Customer's middle name. Dynamic data masking applied. May be empty string if no middle name. |
| 7 | DateOfBirth | date MASKED | NO | - | CODE-BACKED | Customer's date of birth. Dynamic data masking applied. Required for CIP verification and FINRA suitability assessment. |
| 8 | NationalPin | varchar(128) MASKED | NO | - | CODE-BACKED | Social Security Number (SSN) or equivalent national identification number. Stored encrypted/hashed (varchar(128)). Dynamic data masking applied. Required for US tax reporting (W-9) and CIP verification. |
| 9 | CitizenshipCountryID | int | NO | - | NAME-INFERRED | Country ID of the customer's citizenship. Integer reference to a country lookup (not in this schema's Dictionary). Determines citizenship-related compliance requirements. |
| 10 | PermanentResident | bit | NO | - | CODE-BACKED | Whether the customer is a US permanent resident (green card holder). True for most US customers. Affects which forms are required and whether visa verification is needed. |
| 11 | PhoneNumber | varchar(30) MASKED | NO | - | CODE-BACKED | Customer's phone number. Dynamic data masking applied. Format includes country code. |
| 12 | PhoneNumberTypeID | int | NO | - | VERIFIED | Type of phone number provided. FK to Dictionary.PhoneType: 1=Home, 2=Work, 3=Mobile, 4=Fax, 5=Other. See [Phone Type](_glossary.md#phone-type). Most customers provide Mobile (3). (Dictionary.PhoneType) |
| 13 | Email | varchar(50) MASKED | NO | - | CODE-BACKED | Customer's email address. Dynamic data masking applied. Used for account communications. |
| 14 | Address | nvarchar(100) MASKED | NO | - | CODE-BACKED | Primary street address line. Dynamic data masking applied. |
| 15 | BuildingNumber | nvarchar(30) MASKED | NO | - | CODE-BACKED | Building/apartment number. Dynamic data masking applied. |
| 16 | City | nvarchar(50) MASKED | NO | - | CODE-BACKED | City name from home address. Dynamic data masking applied. |
| 17 | ProvinceID | int | YES | - | NAME-INFERRED | State/province ID for the home address. Integer reference to a region lookup. NULL for addresses where province is not applicable. |
| 18 | Zip | nvarchar(50) MASKED | NO | - | CODE-BACKED | ZIP/postal code. Dynamic data masking applied. |
| 19 | CountryID | int | NO | - | NAME-INFERRED | Country ID of the customer's home address. Integer reference to a country lookup. |
| 20 | POBCountryID | int | YES | - | NAME-INFERRED | Place of Birth country ID. NULL if not collected. Required for certain compliance checks. |
| 21 | IsControlPerson | bit | YES | - | CODE-BACKED | Whether the customer is a control person (director, 10%+ shareholder, policy-making officer) of a public company. Requires DisclosureCompanySymbols. |
| 22 | DisclosureCompanySymbols | nvarchar(255) | YES | - | CODE-BACKED | Stock ticker symbols of companies where the customer is a control person. Required when IsControlPerson=true. Comma-separated. |
| 23 | IsAffiliatedExchangeOrFINRA | bit | YES | - | CODE-BACKED | Whether the customer is affiliated with a FINRA member firm or stock exchange. Triggers AffiliatedApprovalRequired state and requires pre-trade approval letter. |
| 24 | DisclosureFirmName | nvarchar(255) | YES | - | CODE-BACKED | Name of the FINRA member firm or exchange the customer is affiliated with. Required when IsAffiliatedExchangeOrFINRA=true. |
| 25 | IsPoliticallyExposed | bit | YES | - | CODE-BACKED | Whether the customer is a Politically Exposed Person (PEP). Triggers enhanced due diligence requirements under AML regulations. |
| 26 | PepAdditionalData | nvarchar(255) | YES | - | CODE-BACKED | Additional PEP disclosure information (government position, family relationship to a PEP, etc.). Required when IsPoliticallyExposed=true. |
| 27 | ApproverName | varchar(128) | YES | - | CODE-BACKED | Name of the compliance officer who manually approved this account. NULL for auto-approved accounts. Set by SaveUserDataApproveInfo. |
| 28 | ApprovedByDate | datetime2(7) | YES | - | CODE-BACKED | Timestamp of manual approval. NULL for auto-approved accounts. Set by SaveUserDataApproveInfo. |
| 29 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserData. |
| 30 | EndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |
| 31 | CID | int | YES | - | CODE-BACKED | Platform Customer ID (different from GCID). Links to the user management system. NULL for records created before CID tracking was added. |
| 32 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this user data record was first created. Distinct from BeginTime which tracks the current version's start. |
| 33 | VisaType | nvarchar(10) | YES | - | CODE-BACKED | US visa classification code (e.g., H1B, F1, L1). NULL for US citizens and permanent residents. |
| 34 | VisaExpirationDate | datetime2(7) | YES | - | CODE-BACKED | Expiration date of the customer's US visa. NULL for non-visa holders. Used to determine if the visa is still valid for account operations. |
| 35 | UsVisaHolder | bit | YES | - | CODE-BACKED | Whether the customer holds a US visa (as opposed to being a citizen or permanent resident). True triggers visa verification workflow (ApexStateID=46). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountTypeID | Dictionary.AccountType | FK | Brokerage account type (CASH/MARGIN/OPTION) |
| CustomerTypeID | Dictionary.CustomerType | FK | Account ownership structure (INDIVIDUAL/IRA/JOINT/CUSTODIAN) |
| PhoneNumberTypeID | Dictionary.PhoneType | FK | Phone number classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveUserData | @GCID | Writer | Upserts customer personal data |
| Apex.SaveUserDataApproveInfo | @GCID | Modifier | Sets approval info |
| Apex.GetUserData | @GCID | Reader | Retrieves full user data |
| Apex.GetApexDataAndState | GCID | Reader | JOINs for combined retrieval |
| Apex.GetUserCid | @GCID | Reader | Retrieves CID mapping |
| Apex.DeleteUserData | @GCID | Deleter | Removes user data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.UserData (table)
├── Dictionary.AccountType (table) [FK]
├── Dictionary.CustomerType (table) [FK]
└── Dictionary.PhoneType (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AccountType | Table | FK for AccountTypeID |
| Dictionary.CustomerType | Table | FK for CustomerTypeID |
| Dictionary.PhoneType | Table | FK for PhoneNumberTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveUserData | Stored Procedure | Writer |
| Apex.SaveUserDataApproveInfo | Stored Procedure | Modifier |
| Apex.GetUserData | Stored Procedure | Reader |
| Apex.GetApexDataAndState | Stored Procedure | Reader |
| Apex.GetUserCid | Stored Procedure | Reader |
| Apex.DeleteUserData | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Apex_UserData | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Apex_UserData | PRIMARY KEY | Clustered on GCID |
| FK_AccountType_UserData | FOREIGN KEY | AccountTypeID -> Dictionary.AccountType(AccuntTypeID) |
| FK_CustomerType_UserData | FOREIGN KEY | CustomerTypeID -> Dictionary.CustomerType(CustomerTypeID) |
| FK_PhoneType_UserData | FOREIGN KEY | PhoneNumberTypeID -> Dictionary.PhoneType(PhoneTypeID) |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserData |

---

## 8. Sample Queries

### 8.1 Get customer profile with resolved lookup values

```sql
SELECT ud.GCID, ud.CID, at.Name AS AccountType, ct.Name AS CustomerType,
       pt.Name AS PhoneType, ud.PermanentResident, ud.IsControlPerson,
       ud.IsAffiliatedExchangeOrFINRA, ud.IsPoliticallyExposed, ud.Created
FROM Apex.UserData ud WITH (NOLOCK)
INNER JOIN Dictionary.AccountType at WITH (NOLOCK) ON at.AccuntTypeID = ud.AccountTypeID
INNER JOIN Dictionary.CustomerType ct WITH (NOLOCK) ON ct.CustomerTypeID = ud.CustomerTypeID
INNER JOIN Dictionary.PhoneType pt WITH (NOLOCK) ON pt.PhoneTypeID = ud.PhoneNumberTypeID
WHERE ud.GCID = 19533157;
```

### 8.2 Find accounts with regulatory disclosures

```sql
SELECT GCID, CID, IsControlPerson, DisclosureCompanySymbols,
       IsAffiliatedExchangeOrFINRA, DisclosureFirmName,
       IsPoliticallyExposed, PepAdditionalData
FROM Apex.UserData WITH (NOLOCK)
WHERE IsControlPerson = 1 OR IsAffiliatedExchangeOrFINRA = 1 OR IsPoliticallyExposed = 1;
```

### 8.3 Find visa holders with upcoming expiration

```sql
SELECT GCID, CID, VisaType, VisaExpirationDate,
       DATEDIFF(DAY, GETUTCDATE(), VisaExpirationDate) AS DaysUntilExpiry
FROM Apex.UserData WITH (NOLOCK)
WHERE UsVisaHolder = 1 AND VisaExpirationDate IS NOT NULL
  AND DATEDIFF(DAY, GETUTCDATE(), VisaExpirationDate) < 90
ORDER BY VisaExpirationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 8.9/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserData | Type: Table | Source: USABroker/Apex/Tables/Apex.UserData.sql*
