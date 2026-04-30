# History.tblaff_Affiliates

> SQL Server temporal history table storing all historical versions of affiliate account records, tracking every change to affiliate profiles, commission assignments, payment details, and account status over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID (int) - identifies the affiliate across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.tblaff_Affiliates is the system-versioned temporal history table for dbo.tblaff_Affiliates. It captures every historical version of affiliate account records - the core entity in the fiktivo affiliate system. Each affiliate is a partner (individual or company) who drives customer acquisition through marketing activities and earns commissions based on their assigned affiliate type plan. This table records every change to their profile, commission plan assignment, payment configuration, account status, and identity information.

This table is essential for compliance, audit, and dispute resolution. It answers questions like: "What affiliate type was this affiliate on when this commission was calculated?", "When was this affiliate's account status changed?", "What payment details were active at the time of a specific payout?" With 48,649 historical versions, affiliate accounts are frequently updated as plans change, payments are configured, and account details are modified.

Data flows in automatically via SQL Server's temporal mechanism when dbo.tblaff_Affiliates is modified. The table reflects changes from multiple operations including affiliate creation, profile updates, plan reassignment, payment detail changes, and account status transitions.

---

## 2. Business Logic

### 2.1 Affiliate Lifecycle and Plan Assignment

**What**: Tracks the affiliate's lifecycle from creation through plan changes, capturing which commission structure was active at each point in time.

**Columns/Parameters Involved**: `AffiliateID`, `AffiliateTypeID`, `AccountStatus`, `DateCreated`, `AffiliatesGroupsID`

**Rules**:
- AffiliateTypeID links to the commission plan (dbo.tblaff_AffiliateTypes) - when this changes, a new version is created
- AccountStatus tracks the affiliate lifecycle: 1 = Activated. See [Account Status](../../Dictionary/Tables/Dictionary.AccountStatus.md)
- AffiliatesGroupsID controls which admin users can manage this affiliate
- DateCreated is set once at creation and does not change across versions

### 2.2 Payment Configuration

**What**: Each affiliate has up to 3 payment methods, with a default selection.

**Columns/Parameters Involved**: `PaymentDetailsID`, `PaymentDetails2ID`, `PaymentDetails3ID`, `PaymentDetailsDefault`

**Rules**:
- PaymentDetailsID is the primary payment method
- PaymentDetails2ID and PaymentDetails3ID are alternatives
- PaymentDetailsDefault indicates which of the 3 is currently active (1, 2, or 3)
- Changes to payment details create new history versions for audit compliance

### 2.3 Introducing Broker (IB) Configuration

**What**: Affiliates can be configured as Introducing Brokers with special settings.

**Columns/Parameters Involved**: `IBAffiliate`, `IBCountries`, `IBProviderID`, `IBLabelID`, `HideExceptIBCRM`

**Rules**:
- IBAffiliate > 0 indicates this affiliate is an Introducing Broker
- IBCountries limits which countries the IB operates in (stored as delimited string)
- HideExceptIBCRM = true hides the affiliate from standard admin views, visible only in IB CRM

---

## 3. Data Overview

| AffiliateID | CompanyName | AffiliateTypeID | AccountStatus | CountryID | DateCreated | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 61740 | Company99931705071 | 2888 | 1 | 251 | 2026-02-17 21:57:19 | 2026-03-17 10:43:16 | 2026-03-17 10:46:21 | Test affiliate with company name updated (appended "1") - active account on plan 2888 |
| 61740 | Company9993170507 | 2888 | 1 | 251 | 2026-02-17 21:57:19 | 2026-02-18 10:10:07 | 2026-03-17 10:43:16 | Same affiliate after affiliate type was changed from 741 to 2888 - version active for ~1 month |
| 61740 | Company9993170507 | 741 | 1 | 251 | 2026-02-17 21:57:19 | 2026-02-17 21:57:19 | 2026-02-18 10:10:07 | Original version when affiliate was created - initial plan 741, changed next day |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Unique identifier for the affiliate. Matches dbo.tblaff_Affiliates.AffiliateID. Multiple history rows share the same ID for version history. |
| 2 | UserID | int | YES | - | CODE-BACKED | Associated admin user ID. 0 = no linked admin user. References dbo.tblaff_User.UserID. |
| 3 | AffiliatesGroupsID | int | NO | - | CODE-BACKED | Affiliate group membership. Controls which admin users can view and manage this affiliate. |
| 4 | LoginName | nvarchar(50) | YES | - | CODE-BACKED | Affiliate's login username for the affiliate console (MASKED for privacy). |
| 5 | LoginPassword | nvarchar(24) | YES | - | CODE-BACKED | Legacy password field (MASKED). Superseded by encrypted authentication. |
| 6 | Phrase | nvarchar(100) | YES | - | CODE-BACKED | Security phrase for account recovery. |
| 7 | Contact | nvarchar(255) | YES | - | CODE-BACKED | Primary contact name for the affiliate. |
| 8 | Email | nvarchar(255) | YES | - | CODE-BACKED | Contact email address. Used for notifications and commission reports. |
| 9 | TaxID | nvarchar(50) | YES | - | CODE-BACKED | Tax identification number for commission payment reporting. |
| 10 | SocialSecurity | nvarchar(50) | YES | - | CODE-BACKED | Social security number (for US-based affiliates). |
| 11 | CompanyName | nvarchar(255) | YES | - | CODE-BACKED | Registered company name of the affiliate entity (MASKED). |
| 12 | CompanyAddress | nvarchar(255) | YES | - | CODE-BACKED | Registered business address (MASKED). |
| 13 | Country | nvarchar(100) | YES | - | CODE-BACKED | Country name as text (legacy field). CountryID is the preferred reference. |
| 14 | City | nvarchar(100) | YES | - | CODE-BACKED | City of the affiliate's registered address. |
| 15 | State | nvarchar(50) | YES | - | CODE-BACKED | State/province of the affiliate's address. |
| 16 | Zip | nvarchar(25) | YES | - | CODE-BACKED | Postal/ZIP code. |
| 17 | Telephone | nvarchar(50) | YES | - | CODE-BACKED | Primary telephone number. |
| 18 | Fax | nvarchar(50) | YES | - | CODE-BACKED | Fax number (legacy field). |
| 19 | WebSiteURL | nvarchar(255) | YES | - | CODE-BACKED | Primary website URL of the affiliate. |
| 20 | WebSiteTitle | nvarchar(255) | YES | - | CODE-BACKED | Title/description of the affiliate's website. |
| 21 | Comments | nvarchar(max) | YES | - | CODE-BACKED | Free-text internal notes about the affiliate. |
| 22 | AccountStatus | int | YES | - | CODE-BACKED | Affiliate account lifecycle state. See [Account Status](../../Dictionary/Tables/Dictionary.AccountStatus.md): 0=Terminated, 1=Activated, 2=Deactivated, 3=TerminatedRequirements, 4=TerminatedCompliance. |
| 23 | SendEmailNotification | bit | NO | - | CODE-BACKED | Whether the affiliate receives email notifications about commission events. |
| 24 | DateCreated | datetime | YES | - | CODE-BACKED | Timestamp when the affiliate account was originally created. Does not change across versions. |
| 25 | AcceptedAgreement | bit | NO | - | CODE-BACKED | Whether the affiliate has accepted the partnership agreement terms. |
| 26 | AffiliateTypeID | int | YES | - | CODE-BACKED | Commission plan assigned to this affiliate. References dbo.tblaff_AffiliateTypes.AffiliateTypeID. Changes to this field are the most operationally significant, as they alter the affiliate's commission structure. |
| 27 | VATNumber | nvarchar(100) | YES | - | CODE-BACKED | VAT registration number for European affiliates. Used for tax-compliant invoicing. |
| 28 | AffiliateCustom1 | nvarchar(255) | YES | - | CODE-BACKED | Custom data field 1 - configurable per deployment for additional affiliate metadata. |
| 29 | AffiliateCustom2 | nvarchar(255) | YES | - | CODE-BACKED | Custom data field 2. |
| 30 | AffiliateCustom3 | nvarchar(255) | YES | - | CODE-BACKED | Custom data field 3. |
| 31 | AffiliateCustom4 | nvarchar(255) | YES | - | CODE-BACKED | Custom data field 4. |
| 32 | AffiliateCustom5 | nvarchar(255) | YES | - | CODE-BACKED | Custom data field 5. |
| 33 | PaymentDetailsID | bigint | NO | - | CODE-BACKED | Primary payment method configuration ID. |
| 34 | IBAffiliate | bigint | NO | - | CODE-BACKED | Introducing Broker reference. 0 = not an IB. >0 = linked IB affiliate identifier. |
| 35 | Reports_Tiers_Summary | bit | NO | - | CODE-BACKED | Whether the affiliate can see tier summary reports in their console. |
| 36 | Reports_Tiers_Details | bit | NO | - | CODE-BACKED | Whether the affiliate can see detailed tier reports. |
| 37 | IBCountries | nvarchar(max) | YES | - | CODE-BACKED | Delimited list of country IDs for IB operations. Restricts which countries an Introducing Broker can operate in. |
| 38 | ManagerID_Demo | bigint | NO | - | CODE-BACKED | Demo account manager assigned to this affiliate. |
| 39 | ManagerID_Real | bigint | NO | - | CODE-BACKED | Real account manager assigned to this affiliate. |
| 40 | MarketingExpenseID | bigint | NO | - | CODE-BACKED | Reference to the marketing expense budget this affiliate's costs are tracked against. |
| 41 | IBProviderID | bigint | NO | - | CODE-BACKED | Provider associated with this IB affiliate's operations. |
| 42 | IBLabelID | bigint | NO | - | CODE-BACKED | White-label identifier for this IB affiliate's branded portal. |
| 43 | HideExceptIBCRM | bit | NO | - | CODE-BACKED | When true, hides this affiliate from standard admin views. Visible only in the IB CRM interface. |
| 44 | CanShowCashier | bit | NO | - | CODE-BACKED | Whether this affiliate's referred customers see the cashier (deposit) interface. |
| 45 | CommunicationLangID | int | NO | - | CODE-BACKED | Preferred language for communications with this affiliate. |
| 46 | CountImpressions | bit | NO | - | CODE-BACKED | Whether banner impressions are tracked for this affiliate. |
| 47 | CountClicks | bit | NO | - | CODE-BACKED | Whether banner clicks are tracked for this affiliate. |
| 48 | PrefferedCurrencyID | int | YES | - | CODE-BACKED | Preferred currency for commission payouts. See [Currency](../../Dictionary/Tables/Dictionary.Currency.md): 1=USD, 2=EUR, 3=GBP. |
| 49 | PaymentDetails2ID | bigint | YES | - | CODE-BACKED | Secondary payment method configuration ID. |
| 50 | PaymentDetails3ID | bigint | YES | - | CODE-BACKED | Tertiary payment method configuration ID. |
| 51 | PaymentDetailsDefault | int | NO | - | CODE-BACKED | Which payment method is the default: 1 = primary, 2 = secondary, 3 = tertiary. |
| 52 | BirthDayDate | datetime | YES | - | CODE-BACKED | Date of birth (for individual affiliates). Used for identity verification. |
| 53 | CountryID | int | NO | - | CODE-BACKED | Country of the affiliate's registration. Preferred over the legacy Country text field. |
| 54 | IdentificationTypeID | int | YES | - | CODE-BACKED | Type of identity document on file. See [Identification Type](../../Dictionary/Tables/Dictionary.IdentificationType.md): 1=Passport, 2=ID Card, etc. |
| 55 | IdentificationNumber | nvarchar(50) | YES | - | CODE-BACKED | Identity document number. |
| 56 | NeedsResetPassword | bit | YES | - | CODE-BACKED | Whether the affiliate must reset their password on next login. |
| 57 | GCID | int | YES | - | CODE-BACKED | Global Customer ID linking this affiliate to a customer account in the eToro platform. |
| 58 | AccountTypeID | int | YES | - | CODE-BACKED | Account type classification. See [Account Type](../../Dictionary/Tables/Dictionary.AccountType.md): 1=Trading, 2=Options, 3=IBAN, 4=Moneyfarm. |
| 59 | EntityName | nvarchar(510) | YES | - | CODE-BACKED | Legal entity name for corporate affiliates. |
| 60 | IncorporationNumber | nvarchar(100) | YES | - | CODE-BACKED | Company incorporation/registration number. |
| 61 | IncorporationDate | datetime | YES | - | CODE-BACKED | Date of company incorporation. |
| 62 | LeiNumber | nvarchar(100) | YES | - | CODE-BACKED | Legal Entity Identifier (LEI) - global standard for financial entity identification. |
| 63 | ContactPersonFullName | nvarchar(510) | YES | - | CODE-BACKED | Full name of the primary contact person (MASKED). |
| 64 | CreationSourceID | int | YES | - | CODE-BACKED | How the affiliate account was created. See [Creation Source](../../Dictionary/Tables/Dictionary.CreationSource.md): 1=Local, 2=Azure, 3=Test. |
| 65 | AzureObjectId | uniqueidentifier | YES | - | CODE-BACKED | Azure AD object ID for affiliates synced from Azure Active Directory. |
| 66 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. Contains HostName, AppName, SUserName, SPID, DBName, ObjectName. |
| 67 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version became active. Set by SQL Server temporal mechanism. |
| 68 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version was superseded. Set by SQL Server temporal mechanism. |
| 69 | PhoneCountryID | int | YES | - | CODE-BACKED | Country code for the affiliate's phone number. |
| 70 | PhoneNumber | nvarchar(20) | YES | - | CODE-BACKED | Phone number without country code. |
| 71 | StreetNumber | nvarchar(20) | YES | - | CODE-BACKED | Street number of the affiliate's address. |
| 72 | LoginName_LOWER | nvarchar(50) | YES | - | CODE-BACKED | Lowercased version of LoginName for case-insensitive lookups. |
| 73 | CalculateCommission | int | NO | - | CODE-BACKED | Commission calculation mode. Controls how and whether commissions are calculated for this affiliate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | dbo.tblaff_Affiliates | Temporal History | Stores historical versions of the base table |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | Commission plan assigned to this affiliate |
| UserID | dbo.tblaff_User | Implicit FK | Admin user linked to this affiliate |
| AccountStatus | Dictionary.AccountStatus | Implicit FK | Affiliate account lifecycle state |
| AccountTypeID | Dictionary.AccountType | Implicit FK | Account type classification |
| CreationSourceID | Dictionary.CreationSource | Implicit FK | How the account was created |
| PrefferedCurrencyID | Dictionary.Currency | Implicit FK | Preferred payout currency |
| IdentificationTypeID | Dictionary.IdentificationType | Implicit FK | Identity document type |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on dbo.tblaff_Affiliates.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.tblaff_Affiliates (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | SYSTEM_VERSIONING - superseded versions stored here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_tblaff_Affiliates | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View the complete history of an affiliate's plan changes
```sql
SELECT AffiliateID, AffiliateTypeID, AccountStatus,
       CompanyName, Email, ValidFrom, ValidTo
FROM dbo.tblaff_Affiliates FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 61740
ORDER BY ValidFrom
```

### 8.2 Find what plan an affiliate was on at a specific date
```sql
SELECT a.AffiliateID, a.CompanyName, a.AffiliateTypeID,
       at.Description AS PlanName, a.AccountStatus
FROM dbo.tblaff_Affiliates FOR SYSTEM_TIME AS OF '2025-06-01' a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON a.AffiliateTypeID = at.AffiliateTypeID
WHERE a.AffiliateID = 61740
```

### 8.3 Audit recent affiliate profile changes
```sql
SELECT AffiliateID, CompanyName, AffiliateTypeID, AccountStatus,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       ValidFrom, ValidTo
FROM History.tblaff_Affiliates WITH (NOLOCK)
WHERE ValidTo > DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 73 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.tblaff_Affiliates | Type: Table | Source: fiktivo/History/Tables/History.tblaff_Affiliates.sql*
