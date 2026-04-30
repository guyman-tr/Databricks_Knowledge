# dbo.tblaff_User

> Back-office admin users for the affiliate management platform (AffWiz), with granular CRUD permission flags controlling access to every functional area.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | UserID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 nonclustered) |

---

## 1. Business Meaning

This table stores the internal admin users who operate the AffWiz affiliate management back-office. Each row represents a staff member (affiliate manager, finance officer, marketing lead, etc.) who can log in to the admin portal and manage affiliates, banners, payments, reports, and system configuration.

Without this table, there would be no access control for the affiliate platform's administrative functions. Every action in the back-office - approving payments, editing affiliate types, managing banners, running reports - is gated by the permission flags stored here.

Rows are created when new admin users are onboarded. The `AffiliatesGroups` column controls which affiliate groups the user can see/manage. Role flags (AffiliateManager, FinanceManager, etc.) define high-level roles, while ~100 granular BIT permission flags control CRUD access to specific areas. The table is system-versioned with temporal history in `History.tblaff_User` for audit tracking. Password management is handled by dedicated procedures in the `fiktivo` schema (CheckPassword, ChangePassword, IsPasswordExpired).

---

## 2. Business Logic

### 2.1 Role-Based Access Control (RBAC)

**What**: Admin users are assigned one or more high-level roles plus granular per-area CRUD permissions.

**Columns/Parameters Involved**: `IsSystemAdministrator`, `AffiliateManager`, `ChiefMarketingOfficer`, `AccountingManager`, `MarketingManager`, `OperationsManager`, `FinanceManager`, all `*_ViewAll`, `*_Edit`, `*_AddNew`, `*_Delete` flags

**Rules**:
- Each functional area (Affiliates, Categories, Banners, Sales, Leads, etc.) has up to 5 permission flags: ViewAll, Edit, AddNew, Delete, Import
- High-level role flags (AffiliateManager, FinanceManager, etc.) grant broad access patterns
- IsSystemAdministrator grants full access to all areas
- A user can hold multiple roles simultaneously (e.g., AffiliateManager + FinanceManager)

**Diagram**:
```
User Role Hierarchy:
  IsSystemAdministrator (full access)
    |
    +-- AffiliateManager (affiliate CRUD + reports)
    +-- ChiefMarketingOfficer (marketing oversight)
    +-- AccountingManager (payment processing)
    +-- MarketingManager (campaigns + banners)
    +-- OperationsManager (day-to-day operations)
    +-- FinanceManager (financial approvals)
    |
    +-- Per-Area Granular Permissions:
        Affiliates_ViewAll/Edit/AddNew/Delete/Import
        Categories_ViewAll/Edit/AddNew/Delete
        Banners_ViewAll/Edit/AddNew/Delete/Import
        Sales_ViewAll/Edit/AddNew/Delete/Import
        ... (all areas)
```

### 2.2 Payment Approval Workflow

**What**: Payment processing requires multi-level approval controlled by separate permission flags.

**Columns/Parameters Involved**: `Tools_PayAffiliates`, `Tools_PayAffiliatesApprove`, `Tools_PayAffiliatesReview`, `GeneratePayment`

**Rules**:
- `Tools_PayAffiliates` grants access to the payment tool
- `Tools_PayAffiliatesReview` allows reviewing pending payments
- `Tools_PayAffiliatesApprove` allows approving reviewed payments
- `GeneratePayment` allows generating payment batches
- Separation of duties: review and approval can be assigned to different users

### 2.3 Affiliate Group Visibility

**What**: Users are scoped to specific affiliate groups via a comma-separated list.

**Columns/Parameters Involved**: `AffiliatesGroups`

**Rules**:
- Contains comma-separated AffiliatesGroupsID values the user can manage
- Empty or whitespace means access to all groups (system admin pattern)
- Controls which affiliates appear in the user's views and reports

---

## 3. Data Overview

| UserID | Name | AffiliatesGroups | IsSystemAdministrator | Key Roles | Meaning |
|--------|------|-----------------|----------------------|-----------|---------|
| 1 | David Virtser | (all) | Yes | SysAdmin | Original system administrator with full unrestricted access to all platform functions |
| 6 | Maya Aharoni | 1 | No | AffiliateManager | Affiliate manager scoped to group 1 - manages affiliate onboarding, rates, and relationships |
| 11 | Gili Sahar | 1 | No | FinanceManager | Finance manager handling payment approvals and financial reporting for group 1 |
| 13 | Gil Ariel | (all) | No | AffiliateManager | Affiliate manager with access to all groups - senior affiliate management role |
| 16 | Oana | 1 | No | (basic) | Standard back-office user with limited permissions scoped to group 1 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing identifier for each admin user. Referenced by tblaff_AffiliatesGroups.ManagerUserID, tblaff_PaymentDetails.VerifiedBy, and tblaff_Affiliates.UserID. |
| 2 | AffiliatesGroups | nvarchar(250) | NO | '1' | CODE-BACKED | Comma-separated list of AffiliatesGroupsID values this user can manage. Controls group-level visibility. Empty/whitespace = access to all groups. |
| 3 | Name | nvarchar(250) | YES | - | CODE-BACKED | Full display name of the admin user. |
| 4 | EmailAddress | nvarchar(250) | YES | - | CODE-BACKED | Corporate email address. MASKED (dynamic data masking). Used for login, notifications, and as group manager email in tblaff_AffiliatesGroups trigger. |
| 5 | LoginName | nvarchar(50) | YES | - | CODE-BACKED | Username for admin portal login. MASKED. |
| 6 | LoginPassword | nvarchar(50) | YES | - | CODE-BACKED | Legacy plaintext password field. MASKED. Being replaced by EncryptedLoginPassword. Managed by fiktivo.ChangePassword and fiktivo.CheckPassword. |
| 7 | AffiliateTypes_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view all affiliate type definitions. |
| 8 | AffiliateTypes_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit existing affiliate type configurations. |
| 9 | AffiliateTypes_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new affiliate type definitions. |
| 10 | AffiliateTypes_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete affiliate types. |
| 11 | Affiliates_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view all affiliate records in assigned groups. |
| 12 | Affiliates_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit affiliate profiles, rates, and settings. |
| 13 | Affiliates_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can onboard new affiliates. |
| 14 | Affiliates_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove affiliate records. |
| 15 | Affiliates_ViewTiers | bit | NO | 0 | CODE-BACKED | Permission: can view multi-tier affiliate hierarchies and sub-affiliate structures. |
| 16 | Affiliates_Import | bit | NO | 0 | CODE-BACKED | Permission: can bulk-import affiliate data. |
| 17 | Categories_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view banner/media categories. |
| 18 | Categories_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit category definitions. |
| 19 | Categories_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new categories. |
| 20 | Categories_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete categories. |
| 21 | Banners_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view marketing banner assets. |
| 22 | Banners_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit banner content, URLs, and targeting. |
| 23 | Banners_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new banner assets. |
| 24 | Banners_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove banners. |
| 25 | Banners_Import | bit | NO | 0 | CODE-BACKED | Permission: can bulk-import banner data. |
| 26 | Sales_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view sale/deposit commission event records. |
| 27 | Sales_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit sale event records. |
| 28 | Sales_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can manually create sale events. |
| 29 | Sales_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete sale event records. |
| 30 | Sales_Import | bit | NO | 0 | CODE-BACKED | Permission: can bulk-import sale data. |
| 31 | RecurringSales_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view recurring commission records. |
| 32 | RecurringSales_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create recurring commission entries. |
| 33 | RecurringSales_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove recurring commissions. |
| 34 | Leads_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view lead (download/signup) records. |
| 35 | Leads_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit lead records. |
| 36 | Leads_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can manually add lead records. |
| 37 | Leads_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete lead records. |
| 38 | Leads_Import | bit | NO | 0 | CODE-BACKED | Permission: can bulk-import leads. |
| 39 | TrackingCode | bit | NO | 0 | CODE-BACKED | Permission: can access and manage affiliate tracking code generation. |
| 40 | AffiliateSignupPage | bit | NO | 0 | CODE-BACKED | Permission: can configure the affiliate self-registration page settings. |
| 41 | SummaryReport | bit | NO | 0 | CODE-BACKED | Permission: can view the top-level dashboard summary report. |
| 42 | Reports_ClicksLeadsSalesSummary | bit | NO | 0 | CODE-BACKED | Permission: can run the combined clicks/leads/sales summary report. |
| 43 | Reports_ClicksLeadsSalesByDay | bit | NO | 0 | CODE-BACKED | Permission: can run the daily breakdown clicks/leads/sales report. |
| 44 | Reports_TrendGraphs | bit | NO | 0 | CODE-BACKED | Permission: can view trend graph visualizations. |
| 45 | Reports_PaymentSummary | bit | NO | 0 | CODE-BACKED | Permission: can view payment summary reports. |
| 46 | Reports_AffiliateList | bit | NO | 0 | CODE-BACKED | Permission: can view the affiliate listing report. |
| 47 | Reports_SalesSummary | bit | NO | 0 | CODE-BACKED | Permission: can view sales summary reports. |
| 48 | Reports_LeadSummary | bit | NO | 0 | CODE-BACKED | Permission: can view lead summary reports. |
| 49 | Reports_ClickSummary | bit | NO | 0 | CODE-BACKED | Permission: can view click summary reports. |
| 50 | Reports_ImpressionsClicks | bit | NO | 0 | CODE-BACKED | Permission: can view impressions and clicks analytics. |
| 51 | Reports_SaleDetail | bit | NO | 0 | CODE-BACKED | Permission: can view individual sale detail records. |
| 52 | Reports_LeadDetail | bit | NO | 0 | CODE-BACKED | Permission: can view individual lead detail records. |
| 53 | Reports_ClickDetail | bit | NO | 0 | CODE-BACKED | Permission: can view individual click detail records. |
| 54 | Reports_InactiveAffiliates | bit | NO | 0 | CODE-BACKED | Permission: can view the inactive affiliates report. |
| 55 | Reports_Banners | bit | NO | 0 | CODE-BACKED | Permission: can view banner performance reports. |
| 56 | Tools_PayAffiliates | bit | NO | 0 | CODE-BACKED | Permission: can access the affiliate payment tool to initiate payment runs. |
| 57 | Tools_EmailBroadcast | bit | NO | 0 | CODE-BACKED | Permission: can send mass email broadcasts to affiliates. |
| 58 | Tools_SendAcceptanceEmail | bit | NO | 0 | CODE-BACKED | Permission: can send affiliate acceptance/welcome emails. |
| 59 | Tools_ExportPaymentData | bit | NO | 0 | CODE-BACKED | Permission: can export payment data to external files. |
| 60 | Tools_EmailEarningsSummaries | bit | NO | 0 | CODE-BACKED | Permission: can trigger affiliate earnings summary email sends. |
| 61 | Tools_EmailLinks | bit | NO | 0 | CODE-BACKED | Permission: can manage email link tracking. |
| 62 | Preferences_Setup | bit | NO | 0 | CODE-BACKED | Permission: can modify system-level setup preferences. |
| 63 | Preferences_EmailMessages | bit | NO | 0 | CODE-BACKED | Permission: can edit system email message templates. |
| 64 | Preferences_AffiliateConsole | bit | NO | 0 | CODE-BACKED | Permission: can configure the affiliate-facing console settings. |
| 65 | Preferences_SpiderIPs | bit | NO | 0 | CODE-BACKED | Permission: can manage the spider/bot IP whitelist for traffic filtering. |
| 66 | Preferences_SpiderHeaders | bit | NO | 0 | CODE-BACKED | Permission: can manage spider/bot detection header patterns. |
| 67 | Preferences_IPBlocking | bit | NO | 0 | CODE-BACKED | Permission: can manage IP blocking rules for fraud prevention. |
| 68 | Announcements_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view system announcements to affiliates. |
| 69 | Announcements_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit announcement content. |
| 70 | Announcements_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new announcements. |
| 71 | Announcements_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove announcements. |
| 72 | AffiliateGroups_ViewAll | bit | NO | 1 | CODE-BACKED | Permission: can view affiliate group definitions. Default ON - all users can see groups. |
| 73 | AffiliateGroups_Edit | bit | NO | 1 | CODE-BACKED | Permission: can edit affiliate group settings and manager assignment. Default ON. |
| 74 | AffiliateGroups_AddNew | bit | NO | 1 | CODE-BACKED | Permission: can create new affiliate groups. Default ON. |
| 75 | AffiliateGroups_Delete | bit | NO | 1 | CODE-BACKED | Permission: can delete affiliate groups. Default ON. |
| 76 | Chargebacks_ViewAll | bit | NO | 1 | CODE-BACKED | Permission: can view chargeback event records. Default ON. |
| 77 | Bonuses_ViewAll | bit | NO | 1 | CODE-BACKED | Permission: can view bonus event records. Default ON. |
| 78 | Deposits_ViewAll | bit | NO | 1 | CODE-BACKED | Permission: can view deposit event records. Default ON. |
| 79 | Registrations_ViewAll | bit | NO | 1 | CODE-BACKED | Permission: can view registration event records. Default ON. |
| 80 | Reports_DailySummary | bit | NO | 1 | CODE-BACKED | Permission: can view the daily summary report. Default ON. |
| 81 | Reports_DailySummaryByAffiliate | bit | NO | 1 | CODE-BACKED | Permission: can view daily summary broken down by affiliate. Default ON. |
| 82 | Reports_DownloadsReferrer | bit | NO | 1 | CODE-BACKED | Permission: can view download referrer analytics. Default ON. |
| 83 | Reports_RegistrationSummary | bit | NO | 1 | CODE-BACKED | Permission: can view registration summary reports. Default ON. |
| 84 | Reports_CPASummary | bit | NO | 1 | CODE-BACKED | Permission: can view CPA (cost-per-acquisition) summary reports. Default ON. |
| 85 | Tools_PayAffiliatesApprove | bit | NO | 1 | CODE-BACKED | Permission: can approve affiliate payments after review. Part of multi-step payment approval workflow. Default ON. |
| 86 | Languages_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view language configurations. |
| 87 | Languages_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit language settings. |
| 88 | Languages_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can add new language support. |
| 89 | Languages_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove language configurations. |
| 90 | Brands_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view brand definitions. |
| 91 | Brands_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit brand settings. |
| 92 | Brands_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new brands. |
| 93 | Brands_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove brands. |
| 94 | Tools_PayAffiliatesReview | bit | NO | 0 | CODE-BACKED | Permission: can review pending affiliate payments before approval. Part of multi-step payment workflow. |
| 95 | AffiliateManager | bit | NO | 0 | CODE-BACKED | High-level role flag: user is an Affiliate Manager responsible for onboarding, managing, and supporting affiliates. |
| 96 | ChiefMarketingOfficer | bit | NO | 0 | CODE-BACKED | High-level role flag: user is the CMO with oversight of all marketing operations and affiliate strategy. |
| 97 | AccountingManager | bit | NO | 0 | CODE-BACKED | High-level role flag: user is an Accounting Manager responsible for financial reconciliation and payment processing. |
| 98 | Tools_eCPL | bit | NO | 0 | CODE-BACKED | Permission: can access the eCPL (effective cost per lead) tool for lead cost analysis. |
| 99 | Tools_eCPR | bit | NO | 0 | CODE-BACKED | Permission: can access the eCPR (effective cost per registration) tool for registration cost analysis. |
| 100 | Chargebacks_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete chargeback event records. |
| 101 | Deposits_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete deposit event records. |
| 102 | Registrations_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete registration event records. |
| 103 | Bonuses_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete bonus event records. |
| 104 | Tools_eCost | bit | NO | 0 | CODE-BACKED | Permission: can access the eCost (effective cost) reporting and management tool. |
| 105 | Countries_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view country configuration and assignment. |
| 106 | Countries_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit country settings (group/type assignments). |
| 107 | Countries_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can add new country entries. |
| 108 | Countries_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove country entries. |
| 109 | EMailNotifications_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view email notification templates and settings. |
| 110 | EMailNotifications_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit email notification templates. |
| 111 | GeneratePayment | bit | NO | 0 | CODE-BACKED | Permission: can generate payment batches for affiliate payouts. Part of multi-step payment workflow. |
| 112 | Tools_eCostHistoryView | bit | NO | 0 | CODE-BACKED | Permission: can view historical eCost records. |
| 113 | Tools_eCostHistoryEdit | bit | NO | 0 | CODE-BACKED | Permission: can edit historical eCost records. |
| 114 | Tools_eCostHistoryDelete | bit | NO | 0 | CODE-BACKED | Permission: can delete historical eCost records. |
| 115 | Pixels_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view conversion tracking pixel configurations. |
| 116 | Pixels_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit pixel tracking settings. |
| 117 | Pixels_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new tracking pixels. |
| 118 | Pixels_Delete | bit | NO | 0 | CODE-BACKED | Permission: can remove tracking pixels. |
| 119 | PhotoImagePath | varchar(255) | YES | - | NAME-INFERRED | File path to the user's profile photo/avatar image. |
| 120 | AffiliateGroups_Edit_UserList | bit | NO | 0 | CODE-BACKED | Permission: can edit the list of users assigned to an affiliate group (viewer assignment). |
| 121 | IsSystemAdministrator | bit | YES | 0 | CODE-BACKED | Master role flag: grants full unrestricted access to all platform functions. NULL treated as false. 21 of 110 users have this flag. |
| 122 | CopyTraders_ViewAll | bit | NO | 1 | CODE-BACKED | Permission: can view copy trader commission event records. Default ON. |
| 123 | CopyTraders_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete copy trader event records. |
| 124 | AffiliateGroups_Move | bit | NO | 1 | CODE-BACKED | Permission: can move affiliates between groups. Default ON. |
| 125 | Audits_View | bit | NO | 0 | CODE-BACKED | Permission: can view audit log records (dbo.AuditLog/ChangesLog). |
| 126 | EncryptedLoginPassword | varbinary(128) | YES | - | CODE-BACKED | Encrypted version of login password. Replaces the legacy plaintext LoginPassword column. Used by fiktivo.CheckPassword. |
| 127 | ChangedPasswordDate | datetime | YES | - | CODE-BACKED | Timestamp of last password change. Used by fiktivo.IsPasswordExpired to enforce password rotation policy. |
| 128 | Countries_Move | bit | NO | 0 | CODE-BACKED | Permission: can reassign countries between affiliate groups/types. |
| 129 | IsDeleted | bit | NO | 0 | CODE-BACKED | Soft-delete flag. 1 = user account is deactivated. Currently all 110 users are active (IsDeleted=0). |
| 130 | MarketingManager | bit | NO | 0 | CODE-BACKED | High-level role flag: user is a Marketing Manager responsible for campaigns and affiliate marketing operations. |
| 131 | OperationsManager | bit | NO | 0 | CODE-BACKED | High-level role flag: user is an Operations Manager responsible for day-to-day platform operations. |
| 132 | FinanceManager | bit | NO | 0 | CODE-BACKED | High-level role flag: user is a Finance Manager responsible for payment approvals and financial oversight. 19 of 110 users have this flag. |
| 133 | Pixels_CreateGeneric | bit | NO | 0 | CODE-BACKED | Permission: can create generic (non-affiliate-specific) tracking pixels. |
| 134 | Trace | computed | NO | - | CODE-BACKED | Computed audit column. JSON string capturing session metadata: HostName, AppName, SUserName, SPID, DBName, ObjectName. Auto-populated on every operation. |
| 135 | ValidFrom | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning period start. Hidden column. Row validity start timestamp for temporal queries. |
| 136 | ValidTo | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | System-versioning period end. Hidden column. Row validity end timestamp for temporal queries. |
| 137 | InstrumentTypes_ViewAll | bit | NO | 0 | CODE-BACKED | Permission: can view instrument type definitions. |
| 138 | InstrumentTypes_Edit | bit | NO | 0 | CODE-BACKED | Permission: can edit instrument type settings. |
| 139 | InstrumentTypes_AddNew | bit | NO | 0 | CODE-BACKED | Permission: can create new instrument types. |
| 140 | InstrumentTypes_Delete | bit | NO | 0 | CODE-BACKED | Permission: can delete instrument types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no explicit FKs).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_AffiliatesGroups | ManagerUserID | Implicit FK | The admin user assigned as manager of the affiliate group. Used in trigger to sync Dynamics CRM data. |
| dbo.tblaff_PaymentDetails | VerifiedBy | Explicit FK | The admin user who verified/approved the affiliate's payment details. |
| dbo.tblaff_Affiliates | UserID | Implicit FK | Links an affiliate record to the admin user who manages it. |
| dbo.AuditLog | (trigger ref) | Implicit | Audit log entries reference user actions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliatesGroups | Table | ManagerUserID references UserID; trigger reads User email for Dynamics sync |
| dbo.tblaff_PaymentDetails | Table | VerifiedBy FK references UserID |
| dbo.tblaff_Affiliates | Table | UserID column references this table |
| dbo.UpdateInsertAffiliateGroup | Stored Procedure | READER - reads user data for group management |
| dbo.ReadECostHistoryRecords | Stored Procedure | READER - joins to user for eCost history display |
| dbo.GetPayments | Stored Procedure | READER - reads user for payment processing context |
| fiktivo.CheckPassword | Stored Procedure | READER - validates user credentials |
| fiktivo.ChangePassword | Stored Procedure | MODIFIER - updates EncryptedLoginPassword and ChangedPasswordDate |
| fiktivo.IsPasswordExpired | Stored Procedure | READER - checks ChangedPasswordDate for password rotation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_User | CLUSTERED PK | UserID | - | - | Active |
| Idx_tblaff_User_EmailAddress_LoginName_LoginPassword | NONCLUSTERED | EmailAddress, LoginName, LoginPassword | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_User_AffiliatesGroups | DEFAULT | AffiliatesGroups = '1' (new users default to group 1) |
| DF_tblaff_User_IsDeleted | DEFAULT | IsDeleted = 0 (new users are active) |
| DF_tblaff_User_IsSystemAdministrator | DEFAULT | IsSystemAdministrator = 0 (new users are not admins) |
| ~100 DEFAULT constraints | DEFAULT | All permission BIT flags default to 0 (no access) except AffiliateGroups_*, Chargebacks_ViewAll, Bonuses_ViewAll, Deposits_ViewAll, Registrations_ViewAll, Reports_Daily*, Reports_Downloads*, Reports_RegistrationSummary, Reports_CPASummary, Tools_PayAffiliatesApprove, CopyTraders_ViewAll, AffiliateGroups_Move which default to 1 (granted by default) |
| SYSTEM_VERSIONING | Temporal | History table: History.tblaff_User. Tracks all changes with ValidFrom/ValidTo period. |

---

## 8. Sample Queries

### 8.1 Find all active system administrators
```sql
SELECT UserID, Name, EmailAddress
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsSystemAdministrator = 1
  AND IsDeleted = 0
ORDER BY Name
```

### 8.2 Find users with payment approval authority
```sql
SELECT UserID, Name,
       Tools_PayAffiliates AS CanPay,
       Tools_PayAffiliatesReview AS CanReview,
       Tools_PayAffiliatesApprove AS CanApprove,
       GeneratePayment AS CanGenerate
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsDeleted = 0
  AND (Tools_PayAffiliates = 1
       OR Tools_PayAffiliatesApprove = 1
       OR GeneratePayment = 1)
ORDER BY Name
```

### 8.3 View user permission changes over time (temporal query)
```sql
SELECT UserID, Name, IsSystemAdministrator, AffiliateManager, FinanceManager,
       ValidFrom, ValidTo
FROM dbo.tblaff_User
FOR SYSTEM_TIME ALL
WHERE UserID = 6
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search returned no results for "tblaff_User" in the TRAD space. Jira search was unavailable (410 Gone).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.1/10 (Elements: 9.9/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 139 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_User | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_User.sql*
