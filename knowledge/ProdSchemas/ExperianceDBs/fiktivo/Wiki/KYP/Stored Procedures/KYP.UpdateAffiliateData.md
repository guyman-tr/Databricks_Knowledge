# KYP.UpdateAffiliateData

> Master update procedure for the full KYP affiliate profile - updates KYP.Affiliate, dbo.tblaff_Affiliates, payment details, website URLs, and synchronizes all four child tables (countries, marketing methods, corporate members, documents) via MERGE operations, all within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID (target), returns refreshed profile via EXEC GetAffiliateData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYP.UpdateAffiliateData is the most complex procedure in the KYP schema. It handles the complete save operation when an affiliate submits or updates their KYP verification form. In a single transaction, it updates up to 8 different tables: the KYP profile, the base affiliate record, payment details, website URLs, and conditionally synchronizes four child collections via MERGE statements.

This procedure is the backbone of the KYP form's save functionality. Every time an affiliate clicks "Save" on the KYP form, this procedure executes. It uses the ISNULL-merge pattern (only non-NULL parameters update) to support partial saves - the affiliate can fill in one section at a time without losing data in other sections. The same status transition guards from UpdateAffiliateKYPStatus are applied here.

After the transaction commits, the procedure calls `KYP.GetAffiliateData` to return the refreshed complete profile (read-after-write pattern). If the update fails the guard check (0 rows affected), it THROWs error 51000.

Created by Ran Ovadia (11/08/2020). Updated (07/10/2021) for payment details. Updated (11/09/2023, PART-2028) by Noga for AffiliateURLs table migration.

---

## 2. Business Logic

### 2.1 Multi-Table Transactional Update

**What**: Orchestrates updates across 8 tables in a single atomic transaction.

**Columns/Parameters Involved**: 80+ parameters covering all KYP form fields

**Rules**:
- Step 1: UPDATE KYP.Affiliate - all KYP compliance fields with ISNULL-merge pattern and status/concurrency guards
- Step 2: If @@ROWCOUNT = 0, THROW 51000 (guard check failed)
- Step 3: UPDATE dbo.tblaff_Affiliates - basic info fields (name, company, address, etc.) with change detection WHERE clause (only updates if actual values changed)
- Step 4: If @WebSiteURL is not NULL, DELETE and re-INSERT into Affiliate.tblaff_AffiliateURLs (pipe-delimited STRING_SPLIT)
- Step 5: UPDATE dbo.tblaff_PaymentDetails - payment method and banking details
- Step 6: If @UpdateCountriesOfOperation=1, MERGE KYP.AffiliateCountriesOfOperation
- Step 7: If @UpdateMarketingMethods=1, MERGE KYP.AffiliateKYPMarketingMethods
- Step 8: If @UpdateCorporateMembers=1, MERGE KYP.AffiliateCorporateMembers
- Step 9: If @UpdateDocs=1, MERGE KYP.AffiliateKYPDocs
- Step 10: EXEC KYP.GetAffiliateData (return refreshed state)

### 2.2 Conditional Child Collection Updates

**What**: Four boolean flags control which child collections are synchronized.

**Columns/Parameters Involved**: `@UpdateCountriesOfOperation`, `@UpdateMarketingMethods`, `@UpdateCorporateMembers`, `@UpdateDocs`

**Rules**:
- Each flag defaults to 0 (no update). Set to 1 to trigger the MERGE for that collection.
- MERGE pattern: NOT MATCHED BY TARGET = INSERT new items, NOT MATCHED BY SOURCE (for same AffiliateID) = DELETE removed items, MATCHED = UPDATE (for corporate members and docs that have updatable fields)
- This allows the application to update only changed sections, avoiding unnecessary MERGE operations
- Table-valued parameters (TVPs): @CountriesOfOperationIDs (IDTableType), @MarketingMethodIDs (IDTableType), @CorporateMembers (KypCorporateMembersTableType), @Docs (KypDocsTableType)

### 2.3 Change Detection for tblaff_Affiliates

**What**: The UPDATE to dbo.tblaff_Affiliates only executes if at least one field actually changed.

**Rules**:
- The WHERE clause includes both `AffiliateID = @AffiliateID` AND a series of OR conditions checking each column for actual change
- This prevents unnecessary temporal history entries in tables with SYSTEM_VERSIONING
- Each column is checked: `[Column] <> IsNull(@Param, [Column])` - only triggers if the new value differs from current

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Target affiliate to update. Used across all UPDATE/MERGE operations. |
| 2 | @StatusID | int (IN) | YES | NULL | CODE-BACKED | New KYPStatusID. NULL = keep current. |
| 3 | @Progress | int (IN) | YES | NULL | CODE-BACKED | New progress percentage. NULL = keep current. |
| 4 | @TicketID | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Compliance ticket ID. |
| 5 | @SubmittedOn | datetime (IN) | YES | NULL | CODE-BACKED | Submission timestamp. |
| 6 | @CanceledOn | datetime (IN) | YES | NULL | CODE-BACKED | Cancellation timestamp. |
| 7 | @PopupDismissed | bit (IN) | YES | NULL | CODE-BACKED | Popup dismissal flag. |
| 8 | @FirstName | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Affiliate's first name. Maps to tblaff_Affiliates.Contact. |
| 9 | @LastName | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Affiliate's last name. Maps to tblaff_Affiliates.AffiliateCustom1. |
| 10 | @Birthday | datetime (IN) | YES | NULL | CODE-BACKED | Affiliate's date of birth. Maps to tblaff_Affiliates.BirthDayDate. |
| 11 | @CompanyName | nvarchar(100) (IN) | YES | NULL | CODE-BACKED | Company/entity name. Maps to tblaff_Affiliates.EntityName. |
| 12 | @PhoneCountryID | int (IN) | YES | NULL | CODE-BACKED | Phone country code. |
| 13 | @PhoneNumber | nvarchar(20) (IN) | YES | NULL | CODE-BACKED | Phone number. |
| 14 | @Telephone | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Alternative telephone number. |
| 15 | @CountryID | int (IN) | YES | NULL | CODE-BACKED | Affiliate's country. |
| 16 | @City | nvarchar(100) (IN) | YES | NULL | CODE-BACKED | City. |
| 17 | @State | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | State/province. |
| 18 | @StreetAddress | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Street address. Maps to tblaff_Affiliates.CompanyAddress. |
| 19 | @StreetNumber | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Street number. |
| 20 | @Zip | nvarchar(25) (IN) | YES | NULL | CODE-BACKED | Postal/ZIP code. |
| 21 | @WebSiteURL | nvarchar(3000) (IN) | YES | NULL | CODE-BACKED | Pipe-delimited website URLs. Split and stored in Affiliate.tblaff_AffiliateURLs. NULL = no change. |
| 22 | @SkypeName | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Skype username. Maps to tblaff_Affiliates.AffiliateCustom2. |
| 23 | @FormOfIncorporationID | int (IN) | YES | NULL | CODE-BACKED | Legal structure. FK to Dictionary.FormOfIncorporation. |
| 24 | @FormOfIncorporationOther | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Free-text when FormOfIncorporationID=1 (Other). |
| 25 | @NatureOfBusinessID | int (IN) | YES | NULL | CODE-BACKED | Industry sector. FK to Dictionary.NatureOfBusiness. |
| 26 | @NatureOfBusinessOther | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Free-text when NatureOfBusinessID=1 (Other). |
| 27 | @LeiNumber | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Legal Entity Identifier (LEI) - global corporate identifier. |
| 28 | @IncorporationNumber | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Company incorporation/registration number. |
| 29 | @IncorporationDate | datetime (IN) | YES | NULL | CODE-BACKED | Date of incorporation. |
| 30 | @IncorporationCountryID | int (IN) | YES | NULL | CODE-BACKED | Country of incorporation. |
| 31 | @TaxCountryID | int (IN) | YES | NULL | CODE-BACKED | Country of tax residency. |
| 32 | @Tin | nvarchar(20) (IN) | YES | NULL | CODE-BACKED | Tax Identification Number. |
| 33 | @OpeningPurpose | nvarchar(80) (IN) | YES | NULL | CODE-BACKED | Purpose for opening the affiliate account. |
| 34 | @ContactPersonSameAsAccount | bit (IN) | YES | NULL | CODE-BACKED | Contact person = account holder flag. |
| 35-44 | @ContactPerson* | various (IN) | YES | NULL | CODE-BACKED | Contact person address/identity fields (FirstName, LastName, CountryID, City, State, StreetAddress, StreetNumber, PostalCode, Passport). 10 parameters. |
| 45 | @AuthorizedPersonSameAsAccount | bit (IN) | YES | NULL | CODE-BACKED | Authorized person = account holder flag. |
| 46-57 | @AuthorizedPerson* | various (IN) | YES | NULL | CODE-BACKED | Authorized person fields (FirstName, LastName, Role, PhoneCountryID, PhoneNumber, CountryID, City, State, StreetAddress, StreetNumber, PostalCode, Passport). 12 parameters. |
| 58 | @Profession | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Primary individual's profession. |
| 59 | @HeldPublicPositions | bit (IN) | YES | NULL | CODE-BACKED | PEP declaration. |
| 60 | @IllegalActivity | bit (IN) | YES | NULL | CODE-BACKED | Illegal activity declaration. |
| 61 | @Comments | nvarchar(255) (IN) | YES | NULL | CODE-BACKED | Additional comments. |
| 62 | @TermsAccepted | bit (IN) | YES | NULL | CODE-BACKED | Terms acceptance flag. |
| 63 | @UpdateCountriesOfOperation | bit (IN) | YES | 0 | CODE-BACKED | Flag to trigger MERGE on AffiliateCountriesOfOperation. |
| 64 | @CountriesOfOperationIDs | IDTableType (IN, READONLY) | - | - | CODE-BACKED | TVP with country IDs for MERGE. |
| 65 | @UpdateMarketingMethods | bit (IN) | YES | 0 | CODE-BACKED | Flag to trigger MERGE on AffiliateKYPMarketingMethods. |
| 66 | @MarketingMethodIDs | IDTableType (IN, READONLY) | - | - | CODE-BACKED | TVP with marketing method IDs for MERGE. |
| 67 | @UpdateCorporateMembers | bit (IN) | YES | 0 | CODE-BACKED | Flag to trigger MERGE on AffiliateCorporateMembers. |
| 68 | @CorporateMembers | KypCorporateMembersTableType (IN, READONLY) | - | - | CODE-BACKED | TVP with corporate member data (Index, FullName, Position). |
| 69 | @UpdateDocs | bit (IN) | YES | 0 | CODE-BACKED | Flag to trigger MERGE on AffiliateKYPDocs. |
| 70 | @Docs | KypDocsTableType (IN, READONLY) | - | - | CODE-BACKED | TVP with document data (DocID, DocName, DocTypeID). |
| 71 | @AllowedKYPStatusIDs | IDTableType (IN, READONLY) | - | - | CODE-BACKED | Status transition guard. Same as UpdateAffiliateKYPStatus. |
| 72 | @AllowWhenNoSignificantChangeAfter | datetime (IN) | YES | NULL | CODE-BACKED | Optimistic concurrency guard. Same as UpdateAffiliateKYPStatus. |
| 73 | @PrefferedCurrencyID | int (IN) | YES | NULL | CODE-BACKED | Preferred commission payment currency. |
| 74-84 | @Payment* | various (IN) | YES | NULL | CODE-BACKED | Payment details: PaymentMethodID, WireBeneficiary, WireBankName, WireBankCountryID, WireAccountNumber, WireSwiftCode, WireSortCode, WireRoutingNumber, WireIban, IntermediaryBankName, IntermediaryAccountNumber, IntermediarySwiftCode, NetellerAccount, NetellerEmail, PaymentDetailsDefault. 15 parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYP.Affiliate | UPDATE (MODIFIER) | Updates all KYP compliance fields |
| - | dbo.tblaff_Affiliates | UPDATE (MODIFIER) | Updates basic affiliate info with change detection |
| - | dbo.tblaff_PaymentDetails | UPDATE (MODIFIER) | Updates payment method and banking details |
| - | Affiliate.tblaff_AffiliateURLs | DELETE + INSERT | Replaces website URLs when changed |
| - | KYP.AffiliateCountriesOfOperation | MERGE (WRITER) | Synchronizes countries of operation |
| - | KYP.AffiliateKYPMarketingMethods | MERGE (WRITER) | Synchronizes marketing methods |
| - | KYP.AffiliateCorporateMembers | MERGE (WRITER) | Synchronizes corporate members |
| - | KYP.AffiliateKYPDocs | MERGE (WRITER) | Synchronizes document metadata |
| - | KYP.GetAffiliateData | EXEC call | Returns refreshed profile after update |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.UpdateAffiliateData (procedure)
├── KYP.Affiliate (table)
├── KYP.AffiliateCountriesOfOperation (table)
├── KYP.AffiliateKYPMarketingMethods (table)
├── KYP.AffiliateCorporateMembers (table)
├── KYP.AffiliateKYPDocs (table)
├── dbo.tblaff_Affiliates (table, cross-schema)
├── dbo.tblaff_PaymentDetails (table, cross-schema)
├── Affiliate.tblaff_AffiliateURLs (table, cross-schema)
└── KYP.GetAffiliateData (procedure)
      ├── KYP.Affiliate (table)
      ├── KYP.AffiliateCountriesOfOperation (table)
      ├── KYP.AffiliateKYPMarketingMethods (table)
      ├── KYP.AffiliateCorporateMembers (table)
      ├── KYP.AffiliateKYPDocs (table)
      ├── dbo.tblaff_Affiliates (table, cross-schema)
      ├── dbo.tblaff_PaymentDetails (table, cross-schema)
      └── Affiliate.tblaff_AffiliateURLs (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | UPDATE with guards |
| KYP.AffiliateCountriesOfOperation | Table | MERGE (conditional) |
| KYP.AffiliateKYPMarketingMethods | Table | MERGE (conditional) |
| KYP.AffiliateCorporateMembers | Table | MERGE (conditional) |
| KYP.AffiliateKYPDocs | Table | MERGE (conditional) |
| dbo.tblaff_Affiliates | Table (cross-schema) | UPDATE with change detection |
| dbo.tblaff_PaymentDetails | Table (cross-schema) | UPDATE payment info |
| Affiliate.tblaff_AffiliateURLs | Table (cross-schema) | DELETE + INSERT for URLs |
| KYP.GetAffiliateData | SP | EXEC for read-after-write |
| IDTableType | UDT (dbo) | TVP for IDs |
| KypCorporateMembersTableType | UDT (dbo) | TVP for corporate members |
| KypDocsTableType | UDT (dbo) | TVP for documents |

### 6.2 Objects That Depend On This

No dependents found in the KYP schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update basic KYP info and progress
```sql
DECLARE @Allowed IDTableType
INSERT @Allowed VALUES (2), (3) -- Allow from Unverified or In Progress
EXEC KYP.UpdateAffiliateData
    @AffiliateID = 60062, @StatusID = 3, @Progress = 50,
    @FormOfIncorporationID = 2, @NatureOfBusinessID = 3,
    @AllowedKYPStatusIDs = @Allowed
```

### 8.2 Update with corporate members
```sql
DECLARE @Allowed IDTableType; INSERT @Allowed VALUES (3)
DECLARE @Members KypCorporateMembersTableType
INSERT @Members VALUES (0, 'John Smith', 'CEO'), (1, 'Jane Doe', 'CFO')
EXEC KYP.UpdateAffiliateData
    @AffiliateID = 60062, @UpdateCorporateMembers = 1,
    @CorporateMembers = @Members, @AllowedKYPStatusIDs = @Allowed
```

### 8.3 Check current state before update
```sql
EXEC KYP.GetAffiliateData @AffiliateID = 60062
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 9.5/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 84 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.UpdateAffiliateData | Type: Stored Procedure | Source: fiktivo/KYP/Stored Procedures/KYP.UpdateAffiliateData.sql*
