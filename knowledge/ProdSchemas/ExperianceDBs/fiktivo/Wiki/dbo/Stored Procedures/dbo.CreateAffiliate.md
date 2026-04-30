# dbo.CreateAffiliate

> The core affiliate onboarding procedure. Creates a new affiliate account by inserting 3 payment detail placeholder records, inserting the affiliate master record, and inserting any supplied website URLs parsed from a pipe-delimited list. Returns the new AffiliateID.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Authors** | Ran Ovadia (2020-01-21), Noga (PART-2028, 2023-09-11), Gil Haba (PART-3422, 2024-10-14) |
| **Created** | 2020-01-21 |
| **Last Modified** | 2024-10-14 |

---

## 1. Business Meaning

This is the single authoritative procedure for creating a new affiliate account in the fiktivo platform. Every affiliate - whether self-registered, admin-created, or provisioned via Azure AD - is ultimately inserted through this procedure. It performs three coordinated INSERT operations within what should be treated as an atomic unit of work: (1) three payment detail placeholder rows are created in tblaff_PaymentDetails, (2) the affiliate master record is created in tblaff_Affiliates with all profile, compliance, and configuration fields, and (3) if the caller supplies website URLs in the pipe-delimited @WebSiteURL parameter, each URL is split and inserted into Affiliate.tblaff_AffiliateURLs.

The procedure supports the full affiliate profile: individual and corporate KYP/compliance fields (LEI number, incorporation date, entity name), Azure AD identity linkage (@AzureObjectId), communication preferences, IB flags, custom fields, phone number with country code, and address components. It returns the new AffiliateID so the caller can immediately associate additional records.

The procedure has been extended twice since its 2020 creation: PART-2028 (2023) added corporate entity and compliance fields, and PART-3422 (2024) added additional structured address and contact fields.

---

## 2. Business Logic

### 2.1 Payment Detail Pre-creation

**What**: Three blank payment detail rows are inserted before the affiliate row to satisfy the FK references in tblaff_Affiliates.

**Columns/Parameters Involved**: `tblaff_PaymentDetails`, `PaymentDetailsID`, `PaymentDetails2ID`, `PaymentDetails3ID`

**Rules**:
- Three INSERT statements create three placeholder rows in tblaff_PaymentDetails
- The IDENTITY values from these three inserts are captured and assigned to PaymentDetailsID, PaymentDetails2ID, and PaymentDetails3ID in the tblaff_Affiliates insert
- This pattern ensures the FK columns in tblaff_Affiliates are never NULL at creation time

### 2.2 Affiliate Record Creation

**What**: The main affiliate row is inserted into tblaff_Affiliates with all supplied profile and configuration fields.

**Columns/Parameters Involved**: All 32 input parameters

**Rules**:
- @LoginName and @Email are the primary identity fields; @Email uniqueness should be pre-validated by calling dbo.CheckEmailExists
- @AzureObjectId, when supplied, links the affiliate to an Azure AD principal for SSO; must be unique across the table
- @IBAffiliate flag designates the account as an Introducing Broker
- @AccountStatus is supplied by the caller; typically 0 (Pending) for self-registered affiliates and 1 (Active) for admin-created accounts
- @PreferredCurrencyId sets the payment currency; references Dictionary.Currency
- Corporate compliance fields (@EntityName, @IncorporationNumber, @IncorporationDate, @LeiNumber, @ContactPersonFullName) are populated when @AccountTypeId = 2

### 2.3 Website URL Parsing

**What**: @WebSiteURL may contain one or more pipe-delimited URLs; each is inserted as a separate row in Affiliate.tblaff_AffiliateURLs.

**Columns/Parameters Involved**: `@WebSiteURL`

**Rules**:
- STRING_SPLIT(@WebSiteURL, '|') is used to parse the pipe-delimited list
- Each non-empty token is inserted as one row into Affiliate.tblaff_AffiliateURLs linked to the new AffiliateID
- If @WebSiteURL is NULL or results in no tokens, the INSERT into tblaff_AffiliateURLs is skipped (conditional on @IdTable having rows or equivalent check)
- URLs are stored as submitted; no validation or normalization is applied

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @LoginName | IN | nvarchar(50) | (required) | Affiliate portal login username. Must be unique across tblaff_Affiliates. |
| 2 | @Email | IN | nvarchar(255) | (required) | Affiliate email address. Should be pre-validated for uniqueness via dbo.CheckEmailExists. Has NC index on tblaff_Affiliates. |
| 3 | @AffiliatesGroupsId | IN | int | (required) | Organizational group for the affiliate. References dbo.tblaff_AffiliatesGroups. Default 2 is the standard group. |
| 4 | @CountryId | IN | int | (required) | Country of the affiliate. References dbo.tblaff_Country.CountryID. |
| 5 | @AccountStatus | IN | int | (required) | Initial account status: 0=Pending, 1=Active, 2=Suspended. Controls portal access and commission eligibility. |
| 6 | @AffiliateTypeId | IN | int | (required) | Commission plan type. References dbo.tblaff_AffiliateTypes. Determines commission rates and payment terms. |
| 7 | @IBAffiliate | IN | bit | (required) | Introducing Broker flag: 1=this affiliate operates as an IB, 0=standard affiliate. |
| 8 | @CommunicationLangID | IN | int | (required) | Preferred communication language for notifications and emails. References a language lookup. |
| 9 | @AccountTypeId | IN | int | (required) | Entity classification: 1=Individual, 2=Corporate. Determines required compliance fields. |
| 10 | @AzureObjectId | IN | uniqueidentifier | (required) | Azure Active Directory object ID for SSO-provisioned affiliates. NULL for locally-created accounts. |
| 11 | @Contact | IN | nvarchar(255) | (required) | Primary contact person name. For corporate affiliates, this is the business contact. |
| 12 | @AffiliateCustom1 | IN | nvarchar(255) | (required) | Configurable custom field 1 (sometimes used for last name or additional contact info). |
| 13 | @AffiliateCustom2 | IN | nvarchar(255) | (required) | Configurable custom field 2. |
| 14 | @BirthDayDate | IN | datetime | (required) | Date of birth for individual affiliates. Required for KYC compliance in some jurisdictions. |
| 15 | @IncorporationDate | IN | datetime | (required) | Date of company incorporation for corporate affiliates (AccountTypeId=2). |
| 16 | @CompanyAddress | IN | nvarchar(255) | (required) | Business address of the affiliate. Used for payment processing and compliance. |
| 17 | @City | IN | nvarchar(100) | (required) | City component of the affiliate's business address. |
| 18 | @State | IN | nvarchar(50) | (required) | State or province component of the affiliate's business address. |
| 19 | @Zip | IN | nvarchar(25) | (required) | Postal or ZIP code of the affiliate's business address. |
| 20 | @Telephone | IN | nvarchar(50) | (required) | Legacy telephone field. Structured phone data is stored via @PhoneCountryID and @PhoneNumber. |
| 21 | @WebSiteURL | IN | nvarchar(255) | (required) | Pipe-delimited list of website URLs for the affiliate. Each token is split and inserted into Affiliate.tblaff_AffiliateURLs. |
| 22 | @Comments | IN | nvarchar(max) | (required) | Free-text internal notes about the affiliate. Stored in tblaff_Affiliates.Comments. |
| 23 | @PreferredCurrencyId | IN | int | (required) | Preferred payment currency. References Dictionary.Currency (1=USD, 2=EUR, 3=GBP, etc.). |
| 24 | @GCId | IN | int | (required) | Global Customer ID linking this affiliate to the main trading platform's customer system. |
| 25 | @EntityName | IN | nvarchar(510) | (required) | Registered legal entity name for corporate affiliates. Part of KYP documentation. Added by PART-2028. |
| 26 | @IncorporationNumber | IN | nvarchar(100) | (required) | Company registration number for corporate affiliates. Required for KYP compliance. Added by PART-2028. |
| 27 | @LeiNumber | IN | nvarchar(100) | (required) | Legal Entity Identifier (20-char alphanumeric) required for corporate entities under MiFID II. Added by PART-2028. |
| 28 | @ContactPersonFullName | IN | nvarchar(510) | (required) | Full name of the authorized contact person for corporate affiliates. Added by PART-2028. |
| 29 | @eToroUserName | IN | nvarchar(255) | (required) | The affiliate's username on the eToro trading platform, if applicable. Added by PART-3422. |
| 30 | @PhoneCountryID | IN | int | (required) | International dialing country code for the affiliate's phone. Paired with @PhoneNumber. Added by PART-3422. |
| 31 | @PhoneNumber | IN | nvarchar(20) | (required) | Affiliate's phone number without country prefix. Paired with @PhoneCountryID. Added by PART-3422. |
| 32 | @StreetNumber | IN | nvarchar(20) | (required) | Street or building number component of the affiliate's address. Added by PART-3422. |

### Output / Return Value

| Parameter / Column | Direction | Type | Description |
|-------------------|-----------|------|-------------|
| AffiliateId | OUT (result set) | int | The IDENTITY value of the newly created affiliate row in tblaff_Affiliates. Returned as a single-column SELECT result. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_PaymentDetails | INSERT (x3) | Three placeholder payment detail rows created before the affiliate row to satisfy FK constraints |
| dbo.tblaff_Affiliates | INSERT | The main affiliate master record with all profile, compliance, and configuration fields |
| Affiliate.tblaff_AffiliateURLs | INSERT | One row per URL parsed from the pipe-delimited @WebSiteURL parameter; skipped if no URLs supplied |

### 5.2 Tables Read

None directly; SCOPE_IDENTITY() is used to capture the identity values from the INSERT operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CreateAffiliate (stored procedure)
+-- dbo.tblaff_PaymentDetails (table) [INSERT x3]
+-- dbo.tblaff_Affiliates (table) [INSERT]
|   +-- dbo.tblaff_Country (table) [implicit FK via CountryId]
|   +-- dbo.tblaff_AffiliatesGroups (table) [implicit FK via AffiliatesGroupsId]
|   +-- dbo.tblaff_AffiliateTypes (table) [implicit FK via AffiliateTypeId]
|   +-- Dictionary.Currency (table) [implicit FK via PreferredCurrencyId]
+-- Affiliate.tblaff_AffiliateURLs (table) [INSERT, conditional]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentDetails | Table | Receives 3 pre-created payment detail rows whose IDs are assigned to the affiliate |
| dbo.tblaff_Affiliates | Table | Receives the new affiliate master record |
| Affiliate.tblaff_AffiliateURLs | Table | Receives one row per parsed website URL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.CheckEmailExists | Stored Procedure | Typically called by the caller before invoking CreateAffiliate |
| Affiliate registration portal | Application | Primary caller for self-registration flow |
| Admin affiliate creation UI | Application | Called when admins create affiliates manually |
| Azure AD provisioning pipeline | Application | Called when Azure-synced affiliates are provisioned |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- STRING_SPLIT is used for @WebSiteURL parsing; requires SQL Server 2016+ compatibility level
- SCOPE_IDENTITY() is used after each INSERT to capture generated IDENTITY values
- The three payment detail pre-insertions establish placeholder records; the payment detail content is populated separately after affiliate creation
- With 32 input parameters, this is the most complex procedure in the affiliate onboarding surface; parameter validation should be performed by the calling application layer
- PART-2028 (2023): Added corporate compliance fields (@EntityName, @IncorporationNumber, @LeiNumber, @ContactPersonFullName, @IncorporationDate)
- PART-3422 (2024): Added @eToroUserName, @PhoneCountryID, @PhoneNumber, @StreetNumber

---

## 8. Sample Queries

### 8.1 Create a standard individual affiliate

```sql
DECLARE @NewAffiliateID int;

EXEC dbo.CreateAffiliate
    @LoginName             = N'jsmith2024',
    @Email                 = N'j.smith@example.com',
    @AffiliatesGroupsId    = 2,
    @CountryId             = 101,
    @AccountStatus         = 0,
    @AffiliateTypeId       = 3,
    @IBAffiliate           = 0,
    @CommunicationLangID   = 1,
    @AccountTypeId         = 1,
    @AzureObjectId         = NULL,
    @Contact               = N'John Smith',
    @AffiliateCustom1      = N'Smith',
    @AffiliateCustom2      = NULL,
    @BirthDayDate          = '1985-06-15',
    @IncorporationDate     = NULL,
    @CompanyAddress        = N'123 Main St',
    @City                  = N'London',
    @State                 = NULL,
    @Zip                   = N'EC1A 1BB',
    @Telephone             = NULL,
    @WebSiteURL            = N'https://jsmith-trading.com|https://jsmith-blog.com',
    @Comments              = N'Referred by existing affiliate 1001',
    @PreferredCurrencyId   = 2,
    @GCId                  = NULL,
    @EntityName            = NULL,
    @IncorporationNumber   = NULL,
    @LeiNumber             = NULL,
    @ContactPersonFullName = NULL,
    @eToroUserName         = N'jsmith_etoro',
    @PhoneCountryID        = 44,
    @PhoneNumber           = N'7700900000',
    @StreetNumber          = N'123';
-- Result set returns: AffiliateId = <new ID>
```

### 8.2 Create a corporate affiliate

```sql
EXEC dbo.CreateAffiliate
    @LoginName             = N'acme_corp',
    @Email                 = N'admin@acme-trading.com',
    @AffiliatesGroupsId    = 2,
    @CountryId             = 55,
    @AccountStatus         = 1,
    @AffiliateTypeId       = 5,
    @IBAffiliate           = 1,
    @CommunicationLangID   = 1,
    @AccountTypeId         = 2,
    @AzureObjectId         = NULL,
    @Contact               = N'Jane Doe',
    @AffiliateCustom1      = N'Doe',
    @AffiliateCustom2      = NULL,
    @BirthDayDate          = NULL,
    @IncorporationDate     = '2005-03-01',
    @CompanyAddress        = N'1 Finance Square',
    @City                  = N'Dublin',
    @State                 = NULL,
    @Zip                   = N'D02 R290',
    @Telephone             = NULL,
    @WebSiteURL            = N'https://acme-trading.com',
    @Comments              = N'Corporate IB partner',
    @PreferredCurrencyId   = 1,
    @GCId                  = NULL,
    @EntityName            = N'ACME Trading Ltd',
    @IncorporationNumber   = N'IE123456',
    @LeiNumber             = N'5493001KJTIIGC8Y1R12',
    @ContactPersonFullName = N'Jane Doe',
    @eToroUserName         = NULL,
    @PhoneCountryID        = 353,
    @PhoneNumber           = N'16000000',
    @StreetNumber          = N'1';
```

### 8.3 Verify the created affiliate

```sql
SELECT a.AffiliateID, a.LoginName, a.Email, a.AccountStatus,
       a.AccountTypeId, a.DateCreated,
       a.PaymentDetailsID, a.PaymentDetails2ID, a.PaymentDetails3ID
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
WHERE a.LoginName = N'jsmith2024';
```

---

## 9. Atlassian Knowledge Sources

### Jira Issues

| Key | Summary | Relevance |
|-----|---------|-----------|
| PART-3422 | Affiliate creation: add eToro username, structured phone, street number | Added @eToroUserName, @PhoneCountryID, @PhoneNumber, @StreetNumber (2024-10-14, Gil Haba) |
| PART-2028 | Affiliate creation: corporate KYP compliance fields | Added @EntityName, @IncorporationNumber, @LeiNumber, @ContactPersonFullName, @IncorporationDate (2023-09-11, Noga) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10*
*Object: dbo.CreateAffiliate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CreateAffiliate.sql*
