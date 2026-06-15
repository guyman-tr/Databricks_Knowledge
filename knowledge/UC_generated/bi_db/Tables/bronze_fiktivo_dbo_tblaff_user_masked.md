---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 138
row_count: null
generated_at: '2026-05-19T12:12:59Z'
upstreams:
- fiktivo.dbo.tblaff_User
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_User
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_User_masked
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 138
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_user_masked

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_User`). 138 of 138 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 138 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 01 08:30:05 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_User` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_User_masked`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_User`
- 138 of 138 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | UserID | INT | YES | Primary key. Auto-incrementing identifier for each admin user. Referenced by tblaff_AffiliatesGroups.ManagerUserID, tblaff_PaymentDetails.VerifiedBy, and tblaff_Affiliates.UserID (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 1 | AffiliatesGroups | STRING | YES | Comma-separated list of AffiliatesGroupsID values this user can manage. Controls group-level visibility. Empty/whitespace = access to all groups (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 2 | Name | STRING | YES | Full display name of the admin user (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 3 | EmailAddress | STRING | YES | Corporate email address. MASKED (dynamic data masking). Used for login, notifications, and as group manager email in tblaff_AffiliatesGroups trigger (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 4 | LoginName | STRING | YES | Username for admin portal login. MASKED (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 5 | LoginPassword | STRING | YES | Legacy plaintext password field. MASKED. Being replaced by EncryptedLoginPassword. Managed by fiktivo.ChangePassword and fiktivo.CheckPassword (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 6 | AffiliateTypes_ViewAll | BOOLEAN | YES | Permission: can view all affiliate type definitions (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 7 | AffiliateTypes_Edit | BOOLEAN | YES | Permission: can edit existing affiliate type configurations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 8 | AffiliateTypes_AddNew | BOOLEAN | YES | Permission: can create new affiliate type definitions (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 9 | AffiliateTypes_Delete | BOOLEAN | YES | Permission: can delete affiliate types (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 10 | Affiliates_ViewAll | BOOLEAN | YES | Permission: can view all affiliate records in assigned groups (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 11 | Affiliates_Edit | BOOLEAN | YES | Permission: can edit affiliate profiles, rates, and settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 12 | Affiliates_AddNew | BOOLEAN | YES | Permission: can onboard new affiliates (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 13 | Affiliates_Delete | BOOLEAN | YES | Permission: can remove affiliate records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 14 | Affiliates_ViewTiers | BOOLEAN | YES | Permission: can view multi-tier affiliate hierarchies and sub-affiliate structures (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 15 | Affiliates_Import | BOOLEAN | YES | Permission: can bulk-import affiliate data (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 16 | Categories_ViewAll | BOOLEAN | YES | Permission: can view banner/media categories (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 17 | Categories_Edit | BOOLEAN | YES | Permission: can edit category definitions (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 18 | Categories_AddNew | BOOLEAN | YES | Permission: can create new categories (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 19 | Categories_Delete | BOOLEAN | YES | Permission: can delete categories (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 20 | Banners_ViewAll | BOOLEAN | YES | Permission: can view marketing banner assets (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 21 | Banners_Edit | BOOLEAN | YES | Permission: can edit banner content, URLs, and targeting (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 22 | Banners_AddNew | BOOLEAN | YES | Permission: can create new banner assets (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 23 | Banners_Delete | BOOLEAN | YES | Permission: can remove banners (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 24 | Banners_Import | BOOLEAN | YES | Permission: can bulk-import banner data (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 25 | Sales_ViewAll | BOOLEAN | YES | Permission: can view sale/deposit commission event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 26 | Sales_Edit | BOOLEAN | YES | Permission: can edit sale event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 27 | Sales_AddNew | BOOLEAN | YES | Permission: can manually create sale events (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 28 | Sales_Delete | BOOLEAN | YES | Permission: can delete sale event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 29 | Sales_Import | BOOLEAN | YES | Permission: can bulk-import sale data (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 30 | RecurringSales_ViewAll | BOOLEAN | YES | Permission: can view recurring commission records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 31 | RecurringSales_AddNew | BOOLEAN | YES | Permission: can create recurring commission entries (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 32 | RecurringSales_Delete | BOOLEAN | YES | Permission: can remove recurring commissions (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 33 | Leads_ViewAll | BOOLEAN | YES | Permission: can view lead (download/signup) records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 34 | Leads_Edit | BOOLEAN | YES | Permission: can edit lead records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 35 | Leads_AddNew | BOOLEAN | YES | Permission: can manually add lead records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 36 | Leads_Delete | BOOLEAN | YES | Permission: can delete lead records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 37 | Leads_Import | BOOLEAN | YES | Permission: can bulk-import leads (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 38 | TrackingCode | BOOLEAN | YES | Permission: can access and manage affiliate tracking code generation (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 39 | AffiliateSignupPage | BOOLEAN | YES | Permission: can configure the affiliate self-registration page settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 40 | SummaryReport | BOOLEAN | YES | Permission: can view the top-level dashboard summary report (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 41 | Reports_ClicksLeadsSalesSummary | BOOLEAN | YES | Permission: can run the combined clicks/leads/sales summary report (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 42 | Reports_ClicksLeadsSalesByDay | BOOLEAN | YES | Permission: can run the daily breakdown clicks/leads/sales report (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 43 | Reports_TrendGraphs | BOOLEAN | YES | Permission: can view trend graph visualizations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 44 | Reports_PaymentSummary | BOOLEAN | YES | Permission: can view payment summary reports (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 45 | Reports_AffiliateList | BOOLEAN | YES | Permission: can view the affiliate listing report (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 46 | Reports_SalesSummary | BOOLEAN | YES | Permission: can view sales summary reports (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 47 | Reports_LeadSummary | BOOLEAN | YES | Permission: can view lead summary reports (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 48 | Reports_ClickSummary | BOOLEAN | YES | Permission: can view click summary reports (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 49 | Reports_ImpressionsClicks | BOOLEAN | YES | Permission: can view impressions and clicks analytics (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 50 | Reports_SaleDetail | BOOLEAN | YES | Permission: can view individual sale detail records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 51 | Reports_LeadDetail | BOOLEAN | YES | Permission: can view individual lead detail records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 52 | Reports_ClickDetail | BOOLEAN | YES | Permission: can view individual click detail records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 53 | Reports_InactiveAffiliates | BOOLEAN | YES | Permission: can view the inactive affiliates report (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 54 | Reports_Banners | BOOLEAN | YES | Permission: can view banner performance reports (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 55 | Tools_PayAffiliates | BOOLEAN | YES | Permission: can access the affiliate payment tool to initiate payment runs (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 56 | Tools_EmailBroadcast | BOOLEAN | YES | Permission: can send mass email broadcasts to affiliates (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 57 | Tools_SendAcceptanceEmail | BOOLEAN | YES | Permission: can send affiliate acceptance/welcome emails (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 58 | Tools_ExportPaymentData | BOOLEAN | YES | Permission: can export payment data to external files (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 59 | Tools_EmailEarningsSummaries | BOOLEAN | YES | Permission: can trigger affiliate earnings summary email sends (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 60 | Tools_EmailLinks | BOOLEAN | YES | Permission: can manage email link tracking (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 61 | Preferences_Setup | BOOLEAN | YES | Permission: can modify system-level setup preferences (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 62 | Preferences_EmailMessages | BOOLEAN | YES | Permission: can edit system email message templates (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 63 | Preferences_AffiliateConsole | BOOLEAN | YES | Permission: can configure the affiliate-facing console settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 64 | Preferences_SpiderIPs | BOOLEAN | YES | Permission: can manage the spider/bot IP whitelist for traffic filtering (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 65 | Preferences_SpiderHeaders | BOOLEAN | YES | Permission: can manage spider/bot detection header patterns (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 66 | Preferences_IPBlocking | BOOLEAN | YES | Permission: can manage IP blocking rules for fraud prevention (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 67 | Announcements_ViewAll | BOOLEAN | YES | Permission: can view system announcements to affiliates (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 68 | Announcements_Edit | BOOLEAN | YES | Permission: can edit announcement content (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 69 | Announcements_AddNew | BOOLEAN | YES | Permission: can create new announcements (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 70 | Announcements_Delete | BOOLEAN | YES | Permission: can remove announcements (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 71 | AffiliateGroups_ViewAll | BOOLEAN | YES | Permission: can view affiliate group definitions. Default ON - all users can see groups (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 72 | AffiliateGroups_Edit | BOOLEAN | YES | Permission: can edit affiliate group settings and manager assignment. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 73 | AffiliateGroups_AddNew | BOOLEAN | YES | Permission: can create new affiliate groups. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 74 | AffiliateGroups_Delete | BOOLEAN | YES | Permission: can delete affiliate groups. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 75 | Chargebacks_ViewAll | BOOLEAN | YES | Permission: can view chargeback event records. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 76 | Bonuses_ViewAll | BOOLEAN | YES | Permission: can view bonus event records. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 77 | Deposits_ViewAll | BOOLEAN | YES | Permission: can view deposit event records. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 78 | Registrations_ViewAll | BOOLEAN | YES | Permission: can view registration event records. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 79 | Reports_DailySummary | BOOLEAN | YES | Permission: can view the daily summary report. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 80 | Reports_DailySummaryByAffiliate | BOOLEAN | YES | Permission: can view daily summary broken down by affiliate. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 81 | Reports_DownloadsReferrer | BOOLEAN | YES | Permission: can view download referrer analytics. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 82 | Reports_RegistrationSummary | BOOLEAN | YES | Permission: can view registration summary reports. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 83 | Reports_CPASummary | BOOLEAN | YES | Permission: can view CPA (cost-per-acquisition) summary reports. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 84 | Tools_PayAffiliatesApprove | BOOLEAN | YES | Permission: can approve affiliate payments after review. Part of multi-step payment approval workflow. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 85 | Languages_ViewAll | BOOLEAN | YES | Permission: can view language configurations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 86 | Languages_Edit | BOOLEAN | YES | Permission: can edit language settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 87 | Languages_AddNew | BOOLEAN | YES | Permission: can add new language support (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 88 | Languages_Delete | BOOLEAN | YES | Permission: can remove language configurations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 89 | Brands_ViewAll | BOOLEAN | YES | Permission: can view brand definitions (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 90 | Brands_Edit | BOOLEAN | YES | Permission: can edit brand settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 91 | Brands_AddNew | BOOLEAN | YES | Permission: can create new brands (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 92 | Brands_Delete | BOOLEAN | YES | Permission: can remove brands (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 93 | Tools_PayAffiliatesReview | BOOLEAN | YES | Permission: can review pending affiliate payments before approval. Part of multi-step payment workflow (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 94 | AffiliateManager | BOOLEAN | YES | High-level role flag: user is an Affiliate Manager responsible for onboarding, managing, and supporting affiliates (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 95 | ChiefMarketingOfficer | BOOLEAN | YES | High-level role flag: user is the CMO with oversight of all marketing operations and affiliate strategy (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 96 | AccountingManager | BOOLEAN | YES | High-level role flag: user is an Accounting Manager responsible for financial reconciliation and payment processing (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 97 | Tools_eCPL | BOOLEAN | YES | Permission: can access the eCPL (effective cost per lead) tool for lead cost analysis (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 98 | Tools_eCPR | BOOLEAN | YES | Permission: can access the eCPR (effective cost per registration) tool for registration cost analysis (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 99 | Chargebacks_Delete | BOOLEAN | YES | Permission: can delete chargeback event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 100 | Deposits_Delete | BOOLEAN | YES | Permission: can delete deposit event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 101 | Registrations_Delete | BOOLEAN | YES | Permission: can delete registration event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 102 | Bonuses_Delete | BOOLEAN | YES | Permission: can delete bonus event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 103 | Tools_eCost | BOOLEAN | YES | Permission: can access the eCost (effective cost) reporting and management tool (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 104 | Countries_ViewAll | BOOLEAN | YES | Permission: can view country configuration and assignment (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 105 | Countries_Edit | BOOLEAN | YES | Permission: can edit country settings (group/type assignments) (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 106 | Countries_AddNew | BOOLEAN | YES | Permission: can add new country entries (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 107 | Countries_Delete | BOOLEAN | YES | Permission: can remove country entries (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 108 | EMailNotifications_ViewAll | BOOLEAN | YES | Permission: can view email notification templates and settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 109 | EMailNotifications_Edit | BOOLEAN | YES | Permission: can edit email notification templates (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 110 | GeneratePayment | BOOLEAN | YES | Permission: can generate payment batches for affiliate payouts. Part of multi-step payment workflow (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 111 | Tools_eCostHistoryView | BOOLEAN | YES | Permission: can view historical eCost records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 112 | Tools_eCostHistoryEdit | BOOLEAN | YES | Permission: can edit historical eCost records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 113 | Tools_eCostHistoryDelete | BOOLEAN | YES | Permission: can delete historical eCost records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 114 | Pixels_ViewAll | BOOLEAN | YES | Permission: can view conversion tracking pixel configurations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 115 | Pixels_Edit | BOOLEAN | YES | Permission: can edit pixel tracking settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 116 | Pixels_AddNew | BOOLEAN | YES | Permission: can create new tracking pixels (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 117 | Pixels_Delete | BOOLEAN | YES | Permission: can remove tracking pixels (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 118 | PhotoImagePath | STRING | YES | File path to the user's profile photo/avatar image (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 119 | AffiliateGroups_Edit_UserList | BOOLEAN | YES | Permission: can edit the list of users assigned to an affiliate group (viewer assignment) (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 120 | IsSystemAdministrator | BOOLEAN | YES | Master role flag: grants full unrestricted access to all platform functions. NULL treated as false. 21 of 110 users have this flag (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 121 | CopyTraders_ViewAll | BOOLEAN | YES | Permission: can view copy trader commission event records. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 122 | CopyTraders_Delete | BOOLEAN | YES | Permission: can delete copy trader event records (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 123 | AffiliateGroups_Move | BOOLEAN | YES | Permission: can move affiliates between groups. Default ON (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 124 | Audits_View | BOOLEAN | YES | Permission: can view audit log records (dbo.AuditLog/ChangesLog) (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 125 | EncryptedLoginPassword | BINARY | YES | Encrypted version of login password. Replaces the legacy plaintext LoginPassword column. Used by fiktivo.CheckPassword (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 126 | ChangedPasswordDate | TIMESTAMP | YES | Timestamp of last password change. Used by fiktivo.IsPasswordExpired to enforce password rotation policy (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 127 | Countries_Move | BOOLEAN | YES | Permission: can reassign countries between affiliate groups/types (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 128 | IsDeleted | BOOLEAN | YES | Soft-delete flag. 1 = user account is deactivated. Currently all 110 users are active (IsDeleted=0) (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 129 | MarketingManager | BOOLEAN | YES | High-level role flag: user is a Marketing Manager responsible for campaigns and affiliate marketing operations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 130 | OperationsManager | BOOLEAN | YES | High-level role flag: user is an Operations Manager responsible for day-to-day platform operations (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 131 | FinanceManager | BOOLEAN | YES | High-level role flag: user is a Finance Manager responsible for payment approvals and financial oversight. 19 of 110 users have this flag (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 132 | Pixels_CreateGeneric | BOOLEAN | YES | Permission: can create generic (non-affiliate-specific) tracking pixels (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 133 | Trace | STRING | YES | Computed audit column. JSON string capturing session metadata: HostName, AppName, SUserName, SPID, DBName, ObjectName. Auto-populated on every operation (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 134 | InstrumentTypes_ViewAll | BOOLEAN | YES | Permission: can view instrument type definitions (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 135 | InstrumentTypes_Edit | BOOLEAN | YES | Permission: can edit instrument type settings (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 136 | InstrumentTypes_AddNew | BOOLEAN | YES | Permission: can create new instrument types (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |
| 137 | InstrumentTypes_Delete | BOOLEAN | YES | Permission: can delete instrument types (Tier 1 — inherited from fiktivo.dbo.tblaff_User). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_User` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_User
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| UserID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliatesGroups | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Name | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| EmailAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| LoginName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| LoginPassword | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateTypes_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateTypes_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateTypes_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateTypes_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Affiliates_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Affiliates_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Affiliates_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Affiliates_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Affiliates_ViewTiers | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Affiliates_Import | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Categories_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Categories_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Categories_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Categories_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Banners_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Banners_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Banners_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Banners_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Banners_Import | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Sales_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Sales_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Sales_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Sales_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Sales_Import | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| RecurringSales_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| RecurringSales_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| RecurringSales_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Leads_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Leads_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Leads_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Leads_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Leads_Import | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| TrackingCode | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateSignupPage | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| SummaryReport | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_ClicksLeadsSalesSummary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_ClicksLeadsSalesByDay | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_TrendGraphs | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_PaymentSummary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_AffiliateList | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_SalesSummary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_LeadSummary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_ClickSummary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_ImpressionsClicks | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_SaleDetail | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_LeadDetail | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_ClickDetail | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_InactiveAffiliates | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_Banners | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Tools_PayAffiliates | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Tools_EmailBroadcast | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Tools_SendAcceptanceEmail | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Tools_ExportPaymentData | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Tools_EmailEarningsSummaries | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Tools_EmailLinks | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Preferences_Setup | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Preferences_EmailMessages | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Preferences_AffiliateConsole | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Preferences_SpiderIPs | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Preferences_SpiderHeaders | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Preferences_IPBlocking | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Announcements_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Announcements_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Announcements_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Announcements_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateGroups_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateGroups_Edit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateGroups_AddNew | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| AffiliateGroups_Delete | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Chargebacks_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Bonuses_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Deposits_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Registrations_ViewAll | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| Reports_DailySummary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_User) |
| ... +58 more rows | ... | ... | ... |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 138 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 138/138 | Source: bronze_tier1_inheritance*
