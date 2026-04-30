# History.tblaff_User

> SQL Server temporal history table storing all historical versions of affiliate admin user accounts, tracking changes to permissions, roles, and access controls for the affiliate management back-office system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | UserID (int) - identifies the admin user across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.tblaff_User is the system-versioned temporal history table for dbo.tblaff_User. It captures every historical version of affiliate admin user accounts - the internal staff members who manage the affiliate program through the back-office application (AffiliateAdminBack). Each user record defines granular permissions for every feature in the affiliate admin console, from viewing affiliate lists to approving payments.

This table is critical for security audit and compliance. When investigating who had access to what at a specific point in time (e.g., during a disputed payment approval), temporal queries against this table provide the definitive answer. The extensive permission matrix (100+ bit columns) means that any permission change creates a new history version.

Data flows in automatically via SQL Server's temporal mechanism when dbo.tblaff_User is modified. With 367 historical versions, admin user permissions are modified periodically as roles evolve.

---

## 2. Business Logic

### 2.1 Granular Permission Matrix

**What**: Each admin user has 100+ individual boolean permissions controlling access to every feature in the affiliate management system.

**Columns/Parameters Involved**: All `*_ViewAll`, `*_Edit`, `*_AddNew`, `*_Delete`, `*_Import` columns, plus role flags

**Rules**:
- Permissions follow a CRUD pattern per entity: ViewAll, Edit, AddNew, Delete (and sometimes Import)
- Covered entities: AffiliateTypes, Affiliates, Categories, Banners, Sales, Leads, Clicks, Countries, Languages, Brands, AffiliateGroups, Chargebacks, Bonuses, Deposits, Registrations, Pixels, InstrumentTypes
- Reports have individual permission flags (ClicksLeadsSalesSummary, TrendGraphs, PaymentSummary, etc.)
- Tools have individual permission flags (PayAffiliates, EmailBroadcast, ExportPaymentData, eCost, etc.)
- System preferences have individual permission flags (Setup, EmailMessages, AffiliateConsole, etc.)
- Role flags: IsSystemAdministrator, AffiliateManager, ChiefMarketingOfficer, AccountingManager, MarketingManager, OperationsManager, FinanceManager

### 2.2 User Lifecycle States

**What**: Admin users can be active or soft-deleted.

**Columns/Parameters Involved**: `IsDeleted`, `IsSystemAdministrator`, `NeedsResetPassword`, `ChangedPasswordDate`

**Rules**:
- IsDeleted = true means the user account is deactivated (soft delete)
- NeedsResetPassword = true forces a password change on next login
- ChangedPasswordDate tracks when the password was last changed (for password expiration policies)
- EncryptedLoginPassword stores the hashed password

---

## 3. Data Overview

| UserID | Name | LoginName | IsSystemAdministrator | AffiliateManager | IsDeleted | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1174 | gil | gilha | true | true | false | 2025-06-11 12:01:49 | 2026-02-18 18:00:20 | System admin with full permissions - version active for 8 months before being superseded by a permission update |
| 1179 | guy | guysh | true | true | false | 2025-08-25 07:18:00 | 2026-02-09 15:20:15 | Another system admin - both users have etoro.com email addresses indicating internal staff |
| 1180 | moshe | mosheozer | true | true | false | 2025-01-14 13:28:31 | 2025-11-18 18:28:12 | System admin whose permissions were updated after ~10 months |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserID | int | NO | - | CODE-BACKED | Unique identifier for the admin user. Matches dbo.tblaff_User.UserID. |
| 2 | AffiliatesGroups | nvarchar(250) | NO | - | CODE-BACKED | Comma-separated list of affiliate group IDs this admin user can manage. Controls which affiliates are visible to this user. |
| 3 | Name | nvarchar(250) | YES | - | CODE-BACKED | Display name of the admin user (first name or short name). |
| 4 | EmailAddress | nvarchar(250) | YES | - | CODE-BACKED | Email address (MASKED). Typically @etoro.com for internal staff. Used for notifications and password resets. |
| 5 | LoginName | nvarchar(50) | YES | - | CODE-BACKED | Username for authentication (MASKED). |
| 6 | LoginPassword | nvarchar(50) | YES | - | CODE-BACKED | Legacy plain-text password field (MASKED). Superseded by EncryptedLoginPassword. |
| 7 | AffiliateTypes_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all affiliate type configurations. |
| 8 | AffiliateTypes_Edit | bit | NO | - | CODE-BACKED | Permission: can edit affiliate type configurations. |
| 9 | AffiliateTypes_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new affiliate types. |
| 10 | AffiliateTypes_Delete | bit | NO | - | CODE-BACKED | Permission: can delete affiliate types. |
| 11 | Affiliates_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all affiliate accounts. |
| 12 | Affiliates_Edit | bit | NO | - | CODE-BACKED | Permission: can edit affiliate account details. |
| 13 | Affiliates_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new affiliate accounts. |
| 14 | Affiliates_Delete | bit | NO | - | CODE-BACKED | Permission: can delete affiliate accounts. |
| 15 | Affiliates_ViewTiers | bit | NO | - | CODE-BACKED | Permission: can view sub-affiliate tier structures. |
| 16 | Affiliates_Import | bit | NO | - | CODE-BACKED | Permission: can bulk import affiliate accounts. |
| 17 | Categories_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view banner categories. |
| 18 | Categories_Edit | bit | NO | - | CODE-BACKED | Permission: can edit banner categories. |
| 19 | Categories_AddNew | bit | NO | - | CODE-BACKED | Permission: can create banner categories. |
| 20 | Categories_Delete | bit | NO | - | CODE-BACKED | Permission: can delete banner categories. |
| 21 | Banners_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all marketing banners. |
| 22 | Banners_Edit | bit | NO | - | CODE-BACKED | Permission: can edit banners. |
| 23 | Banners_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new banners. |
| 24 | Banners_Delete | bit | NO | - | CODE-BACKED | Permission: can delete banners. |
| 25 | Banners_Import | bit | NO | - | CODE-BACKED | Permission: can bulk import banners. |
| 26 | Sales_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all sales/trade commissions. |
| 27 | Sales_Edit | bit | NO | - | CODE-BACKED | Permission: can edit sales records. |
| 28 | Sales_AddNew | bit | NO | - | CODE-BACKED | Permission: can manually add sales records. |
| 29 | Sales_Delete | bit | NO | - | CODE-BACKED | Permission: can delete sales records. |
| 30 | Sales_Import | bit | NO | - | CODE-BACKED | Permission: can bulk import sales. |
| 31 | RecurringSales_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view recurring sales data. |
| 32 | RecurringSales_AddNew | bit | NO | - | CODE-BACKED | Permission: can add recurring sales entries. |
| 33 | RecurringSales_Delete | bit | NO | - | CODE-BACKED | Permission: can delete recurring sales entries. |
| 34 | Leads_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all leads. |
| 35 | Leads_Edit | bit | NO | - | CODE-BACKED | Permission: can edit lead records. |
| 36 | Leads_AddNew | bit | NO | - | CODE-BACKED | Permission: can manually add leads. |
| 37 | Leads_Delete | bit | NO | - | CODE-BACKED | Permission: can delete leads. |
| 38 | Leads_Import | bit | NO | - | CODE-BACKED | Permission: can bulk import leads. |
| 39 | TrackingCode | bit | NO | - | CODE-BACKED | Permission: can access tracking code management. |
| 40 | AffiliateSignupPage | bit | NO | - | CODE-BACKED | Permission: can configure the affiliate signup page. |
| 41 | SummaryReport | bit | NO | - | CODE-BACKED | Permission: can access the summary report dashboard. |
| 42 | Reports_ClicksLeadsSalesSummary | bit | NO | - | CODE-BACKED | Permission: can view the clicks/leads/sales summary report. |
| 43 | Reports_ClicksLeadsSalesByDay | bit | NO | - | CODE-BACKED | Permission: can view the daily breakdown report. |
| 44 | Reports_TrendGraphs | bit | NO | - | CODE-BACKED | Permission: can view trend graph visualizations. |
| 45 | Reports_PaymentSummary | bit | NO | - | CODE-BACKED | Permission: can view payment summary reports. |
| 46 | Reports_AffiliateList | bit | NO | - | CODE-BACKED | Permission: can view the affiliate list report. |
| 47 | Reports_SalesSummary | bit | NO | - | CODE-BACKED | Permission: can view sales summary reports. |
| 48 | Reports_LeadSummary | bit | NO | - | CODE-BACKED | Permission: can view lead summary reports. |
| 49 | Reports_ClickSummary | bit | NO | - | CODE-BACKED | Permission: can view click summary reports. |
| 50 | Reports_ImpressionsClicks | bit | NO | - | CODE-BACKED | Permission: can view impressions/clicks reports. |
| 51 | Reports_SaleDetail | bit | NO | - | CODE-BACKED | Permission: can view detailed sale reports. |
| 52 | Reports_LeadDetail | bit | NO | - | CODE-BACKED | Permission: can view detailed lead reports. |
| 53 | Reports_ClickDetail | bit | NO | - | CODE-BACKED | Permission: can view detailed click reports. |
| 54 | Reports_InactiveAffiliates | bit | NO | - | CODE-BACKED | Permission: can view the inactive affiliates report. |
| 55 | Reports_Banners | bit | NO | - | CODE-BACKED | Permission: can view banner performance reports. |
| 56 | Tools_PayAffiliates | bit | NO | - | CODE-BACKED | Permission: can initiate affiliate commission payments. |
| 57 | Tools_EmailBroadcast | bit | NO | - | CODE-BACKED | Permission: can send email broadcasts to affiliates. |
| 58 | Tools_SendAcceptanceEmail | bit | NO | - | CODE-BACKED | Permission: can send acceptance emails to affiliates. |
| 59 | Tools_ExportPaymentData | bit | NO | - | CODE-BACKED | Permission: can export payment data (finance operation). |
| 60 | Tools_EmailEarningsSummaries | bit | NO | - | CODE-BACKED | Permission: can email earnings summaries to affiliates. |
| 61 | Tools_EmailLinks | bit | NO | - | CODE-BACKED | Permission: can email tracking links to affiliates. |
| 62 | Preferences_Setup | bit | NO | - | CODE-BACKED | Permission: can modify system-wide setup preferences. |
| 63 | Preferences_EmailMessages | bit | NO | - | CODE-BACKED | Permission: can configure email message templates. |
| 64 | Preferences_AffiliateConsole | bit | NO | - | CODE-BACKED | Permission: can configure affiliate console settings. |
| 65 | Preferences_SpiderIPs | bit | NO | - | CODE-BACKED | Permission: can manage spider/bot IP lists for click filtering. |
| 66 | Preferences_SpiderHeaders | bit | NO | - | CODE-BACKED | Permission: can manage spider/bot header patterns. |
| 67 | Preferences_IPBlocking | bit | NO | - | CODE-BACKED | Permission: can manage IP blocking rules. |
| 68 | Announcements_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view system announcements. |
| 69 | Announcements_Edit | bit | NO | - | CODE-BACKED | Permission: can edit announcements. |
| 70 | Announcements_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new announcements. |
| 71 | Announcements_Delete | bit | NO | - | CODE-BACKED | Permission: can delete announcements. |
| 72 | AffiliateGroups_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all affiliate groups. |
| 73 | AffiliateGroups_Edit | bit | NO | - | CODE-BACKED | Permission: can edit affiliate groups. |
| 74 | AffiliateGroups_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new affiliate groups. |
| 75 | AffiliateGroups_Delete | bit | NO | - | CODE-BACKED | Permission: can delete affiliate groups. |
| 76 | Chargebacks_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all chargeback records. |
| 77 | Bonuses_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all bonus records. |
| 78 | Deposits_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all deposit records. |
| 79 | Registrations_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all registration records. |
| 80 | Reports_DailySummary | bit | NO | - | CODE-BACKED | Permission: can view daily summary reports. |
| 81 | Reports_DailySummaryByAffiliate | bit | NO | - | CODE-BACKED | Permission: can view daily summary broken down by affiliate. |
| 82 | Reports_DownloadsReferrer | bit | NO | - | CODE-BACKED | Permission: can view download referrer reports. |
| 83 | Reports_RegistrationSummary | bit | NO | - | CODE-BACKED | Permission: can view registration summary reports. |
| 84 | Reports_CPASummary | bit | NO | - | CODE-BACKED | Permission: can view CPA (Cost Per Acquisition) summary reports. |
| 85 | Tools_PayAffiliatesApprove | bit | NO | - | CODE-BACKED | Permission: can approve affiliate payments (higher privilege than initiation). |
| 86 | Languages_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all language configurations. |
| 87 | Languages_Edit | bit | NO | - | CODE-BACKED | Permission: can edit language configurations. |
| 88 | Languages_AddNew | bit | NO | - | CODE-BACKED | Permission: can add new languages. |
| 89 | Languages_Delete | bit | NO | - | CODE-BACKED | Permission: can delete languages. |
| 90 | Brands_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all brand configurations. |
| 91 | Brands_Edit | bit | NO | - | CODE-BACKED | Permission: can edit brands. |
| 92 | Brands_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new brands. |
| 93 | Brands_Delete | bit | NO | - | CODE-BACKED | Permission: can delete brands. |
| 94 | Tools_PayAffiliatesReview | bit | NO | - | CODE-BACKED | Permission: can review pending affiliate payments. |
| 95 | AffiliateManager | bit | NO | - | CODE-BACKED | Role flag: user is an affiliate manager with broad affiliate relationship management capabilities. |
| 96 | ChiefMarketingOfficer | bit | NO | - | CODE-BACKED | Role flag: user has CMO-level access to marketing and strategic reports. |
| 97 | AccountingManager | bit | NO | - | CODE-BACKED | Role flag: user has accounting manager access to financial operations. |
| 98 | Tools_eCPL | bit | NO | - | CODE-BACKED | Permission: can access eCPL (effective Cost Per Lead) tools. |
| 99 | Tools_eCPR | bit | NO | - | CODE-BACKED | Permission: can access eCPR (effective Cost Per Registration) tools. |
| 100 | Chargebacks_Delete | bit | NO | - | CODE-BACKED | Permission: can delete chargeback records. |
| 101 | Deposits_Delete | bit | NO | - | CODE-BACKED | Permission: can delete deposit records. |
| 102 | Registrations_Delete | bit | NO | - | CODE-BACKED | Permission: can delete registration records. |
| 103 | Bonuses_Delete | bit | NO | - | CODE-BACKED | Permission: can delete bonus records. |
| 104 | Tools_eCost | bit | NO | - | CODE-BACKED | Permission: can access eCost (marketing cost tracking) tools. |
| 105 | Countries_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all country configurations. |
| 106 | Countries_Edit | bit | NO | - | CODE-BACKED | Permission: can edit country configurations. |
| 107 | Countries_AddNew | bit | NO | - | CODE-BACKED | Permission: can add new countries. |
| 108 | Countries_Delete | bit | NO | - | CODE-BACKED | Permission: can delete countries. |
| 109 | EMailNotifications_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view email notification configurations. |
| 110 | EMailNotifications_Edit | bit | NO | - | CODE-BACKED | Permission: can edit email notification configurations. |
| 111 | GeneratePayment | bit | NO | - | CODE-BACKED | Permission: can generate payment files for processing. |
| 112 | Tools_eCostHistoryView | bit | NO | - | CODE-BACKED | Permission: can view eCost history. |
| 113 | Tools_eCostHistoryEdit | bit | NO | - | CODE-BACKED | Permission: can edit eCost history. |
| 114 | Tools_eCostHistoryDelete | bit | NO | - | CODE-BACKED | Permission: can delete eCost history records. |
| 115 | Pixels_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all tracking pixel configurations. |
| 116 | Pixels_Edit | bit | NO | - | CODE-BACKED | Permission: can edit tracking pixels. |
| 117 | Pixels_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new tracking pixels. |
| 118 | Pixels_Delete | bit | NO | - | CODE-BACKED | Permission: can delete tracking pixels. |
| 119 | PhotoImagePath | varchar(255) | YES | - | CODE-BACKED | File path to the user's profile photo in the admin system. |
| 120 | AffiliateGroups_Edit_UserList | bit | NO | - | CODE-BACKED | Permission: can edit the user list within affiliate groups. |
| 121 | IsSystemAdministrator | bit | YES | - | CODE-BACKED | Whether this user has full system administrator access (superuser). Overrides individual permissions. |
| 122 | CopyTraders_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view all CopyTrader commission data. |
| 123 | CopyTraders_Delete | bit | NO | - | CODE-BACKED | Permission: can delete CopyTrader commission records. |
| 124 | AffiliateGroups_Move | bit | NO | - | CODE-BACKED | Permission: can move affiliates between groups. |
| 125 | Audits_View | bit | NO | - | CODE-BACKED | Permission: can view audit logs (change history). |
| 126 | EncryptedLoginPassword | varbinary(128) | YES | - | CODE-BACKED | Encrypted/hashed password (modern storage). Supersedes the plain-text LoginPassword field. |
| 127 | ChangedPasswordDate | datetime | YES | - | CODE-BACKED | Timestamp when the user last changed their password. Used for password expiration policy enforcement. |
| 128 | Countries_Move | bit | NO | - | CODE-BACKED | Permission: can move countries between groups/regions. |
| 129 | IsDeleted | bit | NO | - | CODE-BACKED | Soft-delete flag: true = user account is deactivated but retained for historical reference. |
| 130 | MarketingManager | bit | NO | - | CODE-BACKED | Role flag: user has marketing manager access to campaign and creative management. |
| 131 | OperationsManager | bit | NO | - | CODE-BACKED | Role flag: user has operations manager access to day-to-day affiliate operations. |
| 132 | FinanceManager | bit | NO | - | CODE-BACKED | Role flag: user has finance manager access to payment and accounting operations. |
| 133 | Pixels_CreateGeneric | bit | NO | - | CODE-BACKED | Permission: can create generic (non-affiliate-specific) tracking pixels. |
| 134 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. Contains HostName, AppName, SUserName, SPID, DBName, ObjectName. |
| 135 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version became active. Set by SQL Server temporal mechanism. |
| 136 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version was superseded. Set by SQL Server temporal mechanism. |
| 137 | InstrumentTypes_ViewAll | bit | NO | - | CODE-BACKED | Permission: can view instrument type configurations. |
| 138 | InstrumentTypes_Edit | bit | NO | - | CODE-BACKED | Permission: can edit instrument type configurations. |
| 139 | InstrumentTypes_AddNew | bit | NO | - | CODE-BACKED | Permission: can create new instrument types. |
| 140 | InstrumentTypes_Delete | bit | NO | - | CODE-BACKED | Permission: can delete instrument types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserID | dbo.tblaff_User | Temporal History | Stores historical versions of the base table |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on dbo.tblaff_User.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.tblaff_User (table)
```

This table has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_User | Table | SYSTEM_VERSIONING - SQL Server automatically moves superseded row versions here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_tblaff_User | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View permission changes for a specific admin user
```sql
SELECT UserID, Name, IsSystemAdministrator, AffiliateManager,
       Tools_PayAffiliates, Tools_PayAffiliatesApprove, GeneratePayment,
       ValidFrom, ValidTo
FROM dbo.tblaff_User FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE UserID = 1174
ORDER BY ValidFrom
```

### 8.2 See who had payment approval access at a specific date
```sql
SELECT UserID, Name, LoginName,
       Tools_PayAffiliates, Tools_PayAffiliatesApprove, GeneratePayment
FROM dbo.tblaff_User FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' WITH (NOLOCK)
WHERE Tools_PayAffiliatesApprove = 1 AND IsDeleted = 0
```

### 8.3 Audit recent permission changes
```sql
SELECT UserID, Name,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       IsDeleted, IsSystemAdministrator,
       ValidFrom, ValidTo
FROM History.tblaff_User WITH (NOLOCK)
WHERE ValidTo > DATEADD(DAY, -90, GETUTCDATE())
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 140 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.tblaff_User | Type: Table | Source: fiktivo/History/Tables/History.tblaff_User.sql*
