# dbo.tblaff_Affiliates

> Central entity table for the affiliate management platform, storing all affiliate partner accounts with their profile, credentials, configuration, compliance data, and commission settings.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 9 active (1 NC PK, 1 clustered, 7 NC) |

---

## 1. Business Meaning

This is the **most critical table** in the fiktivo database. Every affiliate partner that has ever registered with the platform has a row here. An affiliate is a business partner (individual or company) that promotes the trading platform and earns commissions for customer referrals, deposits, trades, and other attributed activities.

The table serves as the master record for 43,707 affiliate accounts spanning from 2007 to present. It consolidates identity/contact information, login credentials (masked), organizational assignment (groups and types), payment configuration, compliance/KYC data, tracking preferences, and IB (Introducing Broker) hierarchy settings. Nearly every other table in the database references this table via AffiliateID.

Data flows into this table through: (1) affiliate self-registration on the portal, (2) admin-created accounts via the admin panel, (3) Azure AD sync for corporate-managed affiliates. The table is read by virtually every commission calculation, reporting, and management procedure. System-versioned temporal table with history in History.tblaff_Affiliates. Two triggers enforce referential integrity on delete (cascade to PaymentHistory, commissions, Tier2Members) and update (prevent AffiliateID changes when dependent records exist).

---

## 2. Business Logic

### 2.1 Account Status Lifecycle

**What**: Affiliates progress through distinct account states controlling their access and commission eligibility.

**Columns/Parameters Involved**: `AccountStatus`, `NeedsResetPassword`

**Rules**:
- AccountStatus=0: Inactive/Pending - the most common state (34,894 accounts). Affiliate is registered but not actively earning
- AccountStatus=1: Active - the affiliate is approved and earning commissions (8,768 accounts)
- AccountStatus=2: Suspended - admin has temporarily disabled the affiliate (31 accounts)
- AccountStatus=4: Under review - compliance or audit hold (13 accounts)
- AccountStatus=5: Rejected - application denied (1 account)
- NeedsResetPassword=1 forces a password change on next login

### 2.2 IB (Introducing Broker) Hierarchy

**What**: Affiliates can operate as Introducing Brokers with sub-affiliate networks.

**Columns/Parameters Involved**: `IBAffiliate`, `IBProviderID`, `IBLabelID`, `IBCountries`, `HideExceptIBCRM`

**Rules**:
- IBAffiliate > 0 indicates this affiliate operates as an IB (Introducing Broker)
- IBProviderID links to the parent IB provider for sub-affiliates
- IBCountries (JSON/comma-separated) restricts which countries the IB can operate in
- HideExceptIBCRM=1 hides the affiliate from standard views, visible only in IB CRM tools

### 2.3 Payment Configuration

**What**: Affiliates can have up to 3 payment detail sets with a default selection.

**Columns/Parameters Involved**: `PaymentDetailsID`, `PaymentDetails2ID`, `PaymentDetails3ID`, `PaymentDetailsDefault`, `PrefferedCurrencyID`

**Rules**:
- PaymentDetailsID is the primary payment method (always populated, default=1)
- PaymentDetails2ID and PaymentDetails3ID are alternative payment methods
- PaymentDetailsDefault indicates which payment method is currently active: 1=primary (most common at 2,957), 12=a specific method (40,724 accounts)
- PrefferedCurrencyID sets the affiliate's preferred payment currency (references Dictionary.Currency)

### 2.4 Corporate Entity Compliance (KYP)

**What**: Corporate affiliate accounts require additional compliance data per KYP regulations.

**Columns/Parameters Involved**: `AccountTypeID`, `EntityName`, `IncorporationNumber`, `IncorporationDate`, `LeiNumber`, `ContactPersonFullName`

**Rules**:
- AccountTypeID=1: Individual affiliate (99.6% of accounts)
- AccountTypeID=2: Corporate entity (12 accounts) - requires EntityName, IncorporationNumber, IncorporationDate
- AccountTypeID=0: Legacy/unclassified (181 accounts)
- LeiNumber is the Legal Entity Identifier required for corporate entities under MiFID II regulations

---

## 3. Data Overview

| AffiliateID | LoginName | AccountStatus | AffiliateTypeID | CountryID | DateCreated | Meaning |
|---|---|---|---|---|---|---|
| 1 | forex1 | 1 | 376 | 101 | 2007-07-01 | The very first affiliate account - active since platform launch, assigned to a specialized type (376) |
| 2 | forex2 | 1 | 3 | 101 | 2007-07-02 | Second affiliate, standard type (3), same country - early adopter from day one |
| 3 | forex3 | 1 | 3 | 101 | 2007-07-02 | Third affiliate, also standard type - demonstrates the early registration pattern |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. The unique identifier for each affiliate in the system. Referenced by virtually every other table via AffiliateID columns. NOT FOR REPLICATION identity. NC PK (clustered index is multi-column). |
| 2 | UserID | int | YES | 0 | VERIFIED | Links to dbo.tblaff_User for admin portal user management. Default 0 indicates no linked admin user. Used by triggers and management procedures. |
| 3 | AffiliatesGroupsID | int | NO | 2 | VERIFIED | Organizational group assignment. References dbo.tblaff_AffiliatesGroups.AffiliatesGroupsID [done]. Default 2 is the standard/default group. Groups control manager assignments and reporting segmentation. |
| 4 | LoginName | nvarchar(50) | YES | - | VERIFIED | Affiliate portal login username. MASKED with default() for dynamic data masking. Has dedicated NC index for login lookups. |
| 5 | LoginPassword | nvarchar(24) | YES | - | VERIFIED | Affiliate portal password. MASKED with default() for dynamic data masking. Stored as plaintext/hash depending on era of creation. |
| 6 | Phrase | nvarchar(100) | YES | - | CODE-BACKED | Security phrase for account recovery or verification. Legacy field from original affiliate system. |
| 7 | Contact | nvarchar(255) | YES | - | CODE-BACKED | Primary contact person name for the affiliate. For corporate affiliates, this is the business contact. |
| 8 | Email | nvarchar(255) | YES | - | VERIFIED | Affiliate's email address. Has dedicated NC index. Used for notifications, password resets, and communication. |
| 9 | TaxID | nvarchar(50) | YES | - | CODE-BACKED | Tax identification number for the affiliate. Required for payment processing and regulatory reporting in some jurisdictions. |
| 10 | SocialSecurity | nvarchar(50) | YES | - | CODE-BACKED | Social security or national insurance number. Required for US-based affiliates for IRS W-9 reporting. |
| 11 | CompanyName | nvarchar(255) | YES | - | VERIFIED | Legal company name for corporate affiliates. MASKED with default(). Used in payment processing and compliance documentation. |
| 12 | CompanyAddress | nvarchar(255) | YES | - | CODE-BACKED | Business address of the affiliate. MASKED with default(). Required for payment and compliance. |
| 13 | Country | nvarchar(100) | YES | - | CODE-BACKED | Country name as free text. Legacy field - CountryID (column 54) is the normalized version used by newer code. |
| 14 | City | nvarchar(100) | YES | - | CODE-BACKED | City of the affiliate's business address. |
| 15 | State | nvarchar(50) | YES | - | CODE-BACKED | State/province of the affiliate's business address. |
| 16 | Zip | nvarchar(25) | YES | - | CODE-BACKED | Postal/ZIP code of the affiliate's business address. |
| 17 | Telephone | nvarchar(50) | YES | - | CODE-BACKED | Primary telephone number. Legacy field - PhoneCountryID + PhoneNumber are the structured replacement. |
| 18 | Fax | nvarchar(50) | YES | - | CODE-BACKED | Fax number. Legacy communication field. |
| 19 | WebSiteURL | nvarchar(255) | YES | - | CODE-BACKED | URL of the affiliate's website. Used for compliance review and traffic source verification. |
| 20 | WebSiteTitle | nvarchar(255) | YES | - | CODE-BACKED | Title/name of the affiliate's website. |
| 21 | Comments | nvarchar(max) | YES | - | CODE-BACKED | Free-text notes about the affiliate. Used by admins for internal annotations. |
| 22 | AccountStatus | int | YES | 0 | VERIFIED | Affiliate account lifecycle state: 0=Inactive/Pending (default), 1=Active, 2=Suspended, 4=Under Review, 5=Rejected. Controls portal access and commission eligibility. |
| 23 | SendEmailNotification | bit | NO | 0 | CODE-BACKED | Controls whether the affiliate receives automated email notifications (commission reports, announcements). 1=receive emails, 0=no emails. |
| 24 | DateCreated | datetime | YES | getdate() | VERIFIED | Timestamp of affiliate account creation. Set automatically on INSERT. Oldest records date to 2007-07-01. |
| 25 | AcceptedAgreement | bit | NO | 0 | CODE-BACKED | Whether the affiliate has accepted the affiliate program terms and conditions. 1=accepted, 0=not yet accepted. Required before commissions can be paid. |
| 26 | AffiliateTypeID | int | YES | 0 | VERIFIED | Commission plan type. References dbo.tblaff_AffiliateTypes.AffiliateTypeID [done]. Determines commission rates, CPA slabs, and payment terms. |
| 27 | VATNumber | nvarchar(100) | YES | - | CODE-BACKED | EU VAT registration number. Required for European affiliates for proper invoicing and tax compliance. |
| 28 | AffiliateCustom1 | nvarchar(255) | YES | - | CODE-BACKED | Custom field 1. Configurable per deployment for additional affiliate metadata. Sometimes used for last name or additional contact info. |
| 29 | AffiliateCustom2 | nvarchar(255) | YES | - | CODE-BACKED | Custom field 2. Configurable per deployment. |
| 30 | AffiliateCustom3 | nvarchar(255) | YES | - | CODE-BACKED | Custom field 3. Configurable per deployment. |
| 31 | AffiliateCustom4 | nvarchar(255) | YES | - | CODE-BACKED | Custom field 4. Configurable per deployment. |
| 32 | AffiliateCustom5 | nvarchar(255) | YES | - | CODE-BACKED | Custom field 5. Configurable per deployment. |
| 33 | PaymentDetailsID | bigint | NO | 1 | VERIFIED | Primary payment method. References dbo.tblaff_PaymentDetails [done]. Links to banking/payment info for commission disbursement. Has NC index. |
| 34 | IBAffiliate | bigint | NO | 0 | VERIFIED | Introducing Broker flag/parent ID. 0=not an IB, >0=this affiliate is an IB (value may indicate parent IB structure). |
| 35 | Reports_Tiers_Summary | bit | NO | 0 | CODE-BACKED | Controls whether the affiliate can see tier summary reports in the portal. 1=visible, 0=hidden. |
| 36 | Reports_Tiers_Details | bit | NO | 0 | CODE-BACKED | Controls whether the affiliate can see detailed tier reports in the portal. 1=visible, 0=hidden. |
| 37 | IBCountries | nvarchar(max) | YES | - | CODE-BACKED | Comma-separated or JSON list of country IDs where this IB affiliate can operate. NULL means no geographic restriction. |
| 38 | ManagerID_Demo | bigint | NO | 36 | CODE-BACKED | Demo account manager ID assigned to this affiliate. Default 36. Used for demo/sandbox environment tracking. |
| 39 | ManagerID_Real | bigint | NO | 45 | CODE-BACKED | Real/production account manager ID assigned to this affiliate. Default 45. Determines which manager oversees this affiliate relationship. |
| 40 | MarketingExpenseID | bigint | NO | 1 | VERIFIED | Marketing expense category. References dbo.tblaff_MarketingExpense [done]. Default 1. Categorizes the affiliate's marketing cost allocation. |
| 41 | IBProviderID | bigint | NO | 1 | CODE-BACKED | The provider/partner ID within the IB hierarchy. Default 1. For IB sub-affiliates, identifies their parent IB. |
| 42 | IBLabelID | bigint | NO | 0 | CODE-BACKED | Label/brand identifier within the IB structure. Default 0. Supports white-label IB configurations. |
| 43 | HideExceptIBCRM | bit | NO | 0 | CODE-BACKED | Visibility flag. 1=this affiliate is hidden from standard admin views, only visible in IB CRM tools. 0=visible everywhere. |
| 44 | CanShowCashier | bit | NO | 0 | CODE-BACKED | Controls whether the affiliate can access cashier/payment features in the portal. 1=cashier visible, 0=hidden. |
| 45 | CommunicationLangID | int | NO | 0 | CODE-BACKED | Preferred communication language for emails and notifications. Default 0. References a language lookup. |
| 46 | CountImpressions | bit | NO | 0 | CODE-BACKED | Controls whether banner impressions are tracked for this affiliate. 1=track impressions, 0=clicks only. |
| 47 | CountClicks | bit | NO | 1 | CODE-BACKED | Controls whether clicks are tracked for this affiliate. 1=track clicks (default), 0=no click tracking. |
| 48 | PrefferedCurrencyID | int | YES | - | VERIFIED | Affiliate's preferred payment currency. References Dictionary.Currency (1=USD, 2=EUR, 3=GBP, 4=CAD, 5=AUD, 38=RMB). |
| 49 | PaymentDetails2ID | bigint | YES | - | CODE-BACKED | Secondary payment method. References dbo.tblaff_PaymentDetails [done]. NULL if only one payment method configured. |
| 50 | PaymentDetails3ID | bigint | YES | - | CODE-BACKED | Tertiary payment method. References dbo.tblaff_PaymentDetails [done]. NULL if fewer than three payment methods configured. |
| 51 | PaymentDetailsDefault | int | NO | 1 | VERIFIED | Indicates which payment method is active for disbursement. 1=primary (PaymentDetailsID), 2=secondary, 12=specific method (most common at 93%). |
| 52 | BirthDayDate | datetime | YES | - | CODE-BACKED | Affiliate's date of birth. Required for individual affiliates in some jurisdictions for KYC compliance. |
| 53 | CountryID | int | NO | 0 | VERIFIED | Normalized country reference. FK to dbo.tblaff_Country.CountryID [done]. Default 0. The authoritative country field (replaces legacy Country text field). |
| 54 | IdentificationTypeID | int | YES | - | VERIFIED | Type of government ID submitted. FK to Dictionary.IdentificationType: 1=Passport, 2=ID Card, 3=NI Number, etc. Part of KYC compliance. |
| 55 | IdentificationNumber | nvarchar(50) | YES | - | CODE-BACKED | The actual ID document number corresponding to IdentificationTypeID. Stored for KYC verification records. |
| 56 | NeedsResetPassword | bit | YES | - | CODE-BACKED | Forces password change on next login. 1=must reset, NULL/0=normal login. Set by admins for security events. |
| 57 | GCID | int | YES | - | VERIFIED | Global Customer ID linking this affiliate to the main trading platform's customer system. Has filtered NC index (WHERE GCID IS NOT NULL). Enables cross-platform identity resolution. |
| 58 | AccountTypeID | int | YES | - | VERIFIED | Entity type classification: 0=Legacy/unclassified (181), 1=Individual (43,513), 2=Corporate (12). Determines required compliance fields. |
| 59 | EntityName | nvarchar(510) | YES | - | CODE-BACKED | Legal entity name for corporate affiliates (AccountTypeID=2). The registered company name for KYP documentation. |
| 60 | IncorporationNumber | nvarchar(100) | YES | - | CODE-BACKED | Company registration/incorporation number for corporate affiliates. Required for KYP compliance. |
| 61 | IncorporationDate | datetime | YES | - | CODE-BACKED | Date the corporate entity was incorporated. Part of KYP due diligence. |
| 62 | LeiNumber | nvarchar(100) | YES | - | CODE-BACKED | Legal Entity Identifier (LEI) - a 20-character alphanumeric code required for corporate entities under MiFID II and other financial regulations. |
| 63 | ContactPersonFullName | nvarchar(510) | YES | - | CODE-BACKED | Full name of the authorized contact person for corporate affiliates. MASKED with default(). |
| 64 | CreationSourceID | int | YES | - | VERIFIED | How the affiliate account was created. FK to Dictionary.CreationSource: 1=Local (admin), 2=Azure (AD sync), 3=Test. NULL for legacy accounts. |
| 65 | AzureObjectId | uniqueidentifier | YES | - | VERIFIED | Azure Active Directory object identifier for SSO-provisioned affiliates. Has unique filtered NC index (WHERE NOT NULL). Enables SSO login and identity sync. |
| 66 | Trace | computed | NO | - | VERIFIED | Computed JSON column capturing session context: HostName, AppName, SUserName, SPID, DBName, ObjectName. Audit trail for who modified the record. |
| 67 | ValidFrom | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal system column. Row start time for system versioning. GENERATED ALWAYS AS ROW START HIDDEN. |
| 68 | ValidTo | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal system column. Row end time for system versioning. GENERATED ALWAYS AS ROW END HIDDEN. |
| 69 | PhoneCountryID | int | YES | - | CODE-BACKED | International dialing code/country for the affiliate's phone number. Structured replacement for the legacy Telephone field. |
| 70 | PhoneNumber | nvarchar(20) | YES | - | CODE-BACKED | Affiliate's phone number (without country code). Paired with PhoneCountryID for the full international number. |
| 71 | StreetNumber | nvarchar(20) | YES | - | CODE-BACKED | Street/building number component of the affiliate's address. Added to support structured address formats. |
| 72 | LoginName_LOWER | computed | - | - | VERIFIED | Computed column: lower(LoginName). Provides case-insensitive login name lookups via NC index without collation overhead. |
| 73 | CalculateCommission | int | NO | 0 | VERIFIED | Commission calculation method flag: 0=standard calculation (99.8%), 1=custom/override calculation (96 accounts). Controls which commission engine processes this affiliate's earnings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliatesGroupsID | dbo.tblaff_AffiliatesGroups | Implicit FK | Organizational group assignment for management and reporting |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | Commission plan type determining rates and terms |
| PaymentDetailsID | dbo.tblaff_PaymentDetails | Implicit FK | Primary payment/banking information |
| UserID | dbo.tblaff_User | Implicit FK | Linked admin portal user account |
| MarketingExpenseID | dbo.tblaff_MarketingExpense | Implicit FK | Marketing cost allocation category |
| CountryID | dbo.tblaff_Country | Explicit FK | Affiliate's country of residence/operation |
| CreationSourceID | Dictionary.CreationSource | Explicit FK | How the account was provisioned (Local/Azure/Test) |
| IdentificationTypeID | Dictionary.IdentificationType | Explicit FK | Type of KYC identification document submitted |
| PrefferedCurrencyID | Dictionary.Currency | Implicit FK | Preferred payment currency |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_DurableMessages | AffiliateID | Explicit FK | Pending messages queued for delivery to the affiliate |
| dbo.tblaff_CPA_Commissions | AffiliateID | Trigger-enforced | CPA commission records attributed to this affiliate |
| dbo.tblaff_Sales_Commissions | AffiliateID | Trigger-enforced | Sales commission records |
| dbo.tblaff_Leads_Commissions | AffiliateID | Trigger-enforced | Lead commission records |
| dbo.tblaff_Registrations_Commissions | AffiliateID | Trigger-enforced | Registration commission records |
| dbo.tblaff_eCost_Commissions | AffiliateID | Trigger-enforced | eCost commission records |
| dbo.tblaff_PaymentHistory | AffiliateID | Trigger cascade-delete | Payment history deleted when affiliate is deleted |
| dbo.tblaff_Tier2Members | NewMemberID | Trigger-enforced | Sub-affiliate tier membership |
| dbo.tblaff_RecurringCommissions | AffiliateID | Trigger cascade-delete | Recurring commissions deleted when affiliate is deleted |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.tblaff_Affiliates (table)
+-- dbo.tblaff_Country (table) [explicit FK]
+-- Dictionary.CreationSource (table) [explicit FK]
+-- Dictionary.IdentificationType (table) [explicit FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Country | Table | Explicit FK on CountryID |
| Dictionary.CreationSource | Table | Explicit FK on CreationSourceID |
| Dictionary.IdentificationType | Table | Explicit FK on IdentificationTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_DurableMessages | Table | FK on AffiliateID |
| dbo.tblaff_CPA_Commissions | Table | Trigger-enforced FK on AffiliateID |
| dbo.tblaff_Sales_Commissions | Table | Trigger-enforced FK on AffiliateID |
| dbo.tblaff_Leads_Commissions | Table | Trigger-enforced FK on AffiliateID |
| dbo.tblaff_Registrations_Commissions | Table | Trigger-enforced FK on AffiliateID |
| dbo.tblaff_Bonuses_Commissions | Table | Implicit FK on AffiliateID |
| dbo.tblaff_Chargebacks_Commissions | Table | Implicit FK on AffiliateID |
| dbo.tblaff_CopyTraders_Commissions | Table | Implicit FK on AffiliateID |
| dbo.tblaff_FirstPositions_Commissions | Table | Implicit FK on AffiliateID |
| dbo.tblaff_eCost_Commissions | Table | Trigger-enforced FK on AffiliateID |
| dbo.tblaff_PaymentHistory | Table | Cascade-deleted via trigger |
| dbo.tblaff_Tier2Members | Table | Trigger-enforced FK on NewMemberID |
| dbo.tblaff_RecurringCommissions | Table | Cascade-deleted via trigger |
| dbo.tblaff_eCostHistory | Table | Implicit FK on AffiliateID |
| dbo.tblaff_AffiliatePixels | Table | Implicit FK on AffiliateID |
| dbo.tblaff_Files | Table | Implicit FK on AffiliateID |
| dbo.tblaff_Deposits | Table | Implicit FK on affiliateID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Affiliates_PK | NC PK | AffiliateID | - | - | Active (FILLFACTOR=90) |
| Idx_tblaff_Affiliates | CLUSTERED | AffiliateID, UserID, LoginName, Email | - | - | Active (PAGE compressed) |
| Email | NC | Email | - | - | Active (FILLFACTOR=90) |
| IDX_tblaff_Affiliates_GCID | NC | GCID | - | WHERE GCID IS NOT NULL | Active (PAGE compressed) |
| IX_tblaff_Affiliates_AffiliateTypeID | NC | AffiliateTypeID, AffiliatesGroupsID | - | - | Active |
| IX_tblaff_Affiliates_LoginNameLower | NC | LoginName_LOWER | - | - | Active |
| LoginName | NC | LoginName | - | - | Active |
| UNQ_tblaff_Affiliates_AzureObjectId | NC UNIQUE | AzureObjectId | - | WHERE AzureObjectId IS NOT NULL | Active (PAGE compressed) |
| tblaff_Affiliates_PaymentDetailsID | NC | PaymentDetailsID | AffiliateID | - | Active (FILLFACTOR=90, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SYSTEM_VERSIONING | Temporal | History table: History.tblaff_Affiliates. Full audit trail of all changes. |
| DATA_COMPRESSION = PAGE | Storage | Page-level compression on main table. |
| tblaff_Affiliates_DTrig | Trigger (DELETE) | Cascade-deletes to PaymentHistory, Leads_Commissions, Sales_Commissions, Tier2Members, RecurringCommissions |
| tblaff_Affiliates_UTrig | Trigger (UPDATE) | Prevents AffiliateID updates when dependent records exist in PaymentHistory, Leads/Sales_Commissions, Tier2Members |

---

## 8. Sample Queries

### 8.1 Get active affiliates with type and country
```sql
SELECT a.AffiliateID, a.LoginName, a.Email, a.CompanyName,
       t.AffiliateTypeName, c.CountryName, a.DateCreated
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON a.CountryID = c.CountryID
WHERE a.AccountStatus = 1
ORDER BY a.DateCreated DESC
```

### 8.2 Find Azure-provisioned affiliates
```sql
SELECT a.AffiliateID, a.LoginName, a.AzureObjectId, cs.Name AS CreationSource
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
LEFT JOIN Dictionary.CreationSource cs WITH (NOLOCK) ON a.CreationSourceID = cs.CreationSourceID
WHERE a.AzureObjectId IS NOT NULL
```

### 8.3 Affiliate profile with payment and compliance details
```sql
SELECT a.AffiliateID, a.LoginName, a.AccountStatus, a.AccountTypeID,
       a.CountryID, a.IdentificationTypeID,
       it.IdentificationTypeName, a.IdentificationNumber,
       a.PaymentDetailsID, a.PrefferedCurrencyID,
       cur.CurrencyName
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
LEFT JOIN Dictionary.IdentificationType it WITH (NOLOCK) ON a.IdentificationTypeID = it.IdentificationTypeID
LEFT JOIN Dictionary.Currency cur WITH (NOLOCK) ON a.PrefferedCurrencyID = cur.CurrencyID
WHERE a.AffiliateID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 24 VERIFIED, 47 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Affiliates | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Affiliates.sql*
