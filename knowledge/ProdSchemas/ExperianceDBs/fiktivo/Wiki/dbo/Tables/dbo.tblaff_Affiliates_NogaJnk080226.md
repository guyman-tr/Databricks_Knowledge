# dbo.tblaff_Affiliates_NogaJnk080226

> Developer backup/snapshot of tblaff_Affiliates, created on 2026-02-08 by Noga. No indexes, no FKs, no triggers - exists purely as a point-in-time data safety copy.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (backup/junk) |
| **Key Identifier** | None (heap) |
| **Partition** | No |
| **Indexes** | 0 (heap) |

---

## 1. Business Meaning

dbo.tblaff_Affiliates_NogaJnk080226 is a developer backup copy of dbo.tblaff_Affiliates, created on 2026-02-08 as a data safety snapshot. The "NogaJnk" suffix indicates this was created by developer Noga as a temporary working copy during a development or migration task. These tables should be reviewed for potential cleanup.

See [dbo.tblaff_Affiliates](dbo.tblaff_Affiliates.md) for full documentation of the source table's structure, business meaning, and element descriptions. This backup has an identical column structure but no indexes, constraints, triggers, or foreign keys. The source table is system-versioned (temporal) and has two triggers - none of those features are present in this backup copy.

---

## 2. Business Logic

No business logic. This is a static backup copy.

---

## 3. Data Overview

Developer backup - data represents a point-in-time snapshot from 2026-02-08.

---

## 4. Elements

See [dbo.tblaff_Affiliates](dbo.tblaff_Affiliates.md) for complete element descriptions. This table has identical columns (72 columns): AffiliateID, UserID, AffiliatesGroupsID, LoginName, LoginPassword, Phrase, Contact, Email, TaxID, SocialSecurity, CompanyName, CompanyAddress, Country, City, State, Zip, Telephone, Fax, WebSiteURL, WebSiteTitle, Comments, AccountStatus, SendEmailNotification, DateCreated, AcceptedAgreement, AffiliateTypeID, VATNumber, AffiliateCustom1-5, PaymentDetailsID, IBAffiliate, Reports_Tiers_Summary, Reports_Tiers_Details, IBCountries, ManagerID_Demo, ManagerID_Real, MarketingExpenseID, IBProviderID, IBLabelID, HideExceptIBCRM, CanShowCashier, CommunicationLangID, CountImpressions, CountClicks, PrefferedCurrencyID, PaymentDetails2ID, PaymentDetails3ID, PaymentDetailsDefault, BirthDayDate, CountryID, IdentificationTypeID, IdentificationNumber, NeedsResetPassword, GCID, AccountTypeID, EntityName, IncorporationNumber, IncorporationDate, LeiNumber, ContactPersonFullName, CreationSourceID, AzureObjectId, Trace, ValidFrom, ValidTo, PhoneCountryID, PhoneNumber, StreetNumber, LoginName_LOWER, CalculateCommission.

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (backup copy - no FKs).

### 5.2 Referenced By (other objects point to this)

No dependents found. This is an orphaned backup table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if backup has data
```sql
SELECT COUNT(*) AS RowCount FROM dbo.tblaff_Affiliates_NogaJnk080226 WITH (NOLOCK)
```

### 8.2 Compare with current source table
```sql
SELECT 'Current' AS Source, COUNT(*) AS Rows FROM dbo.tblaff_Affiliates WITH (NOLOCK)
UNION ALL
SELECT 'Backup', COUNT(*) FROM dbo.tblaff_Affiliates_NogaJnk080226 WITH (NOLOCK)
```

### 8.3 Sample backup data
```sql
SELECT TOP 5 * FROM dbo.tblaff_Affiliates_NogaJnk080226 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Affiliates_NogaJnk080226 | Type: Table (backup) | Source: fiktivo/dbo/Tables/dbo.tblaff_Affiliates_NogaJnk080226.sql*
