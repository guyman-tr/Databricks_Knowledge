-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_tblaff_user  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN UserID COMMENT 'Primary key. Auto-incrementing identifier for each admin user. Referenced by tblaff_AffiliatesGroups.ManagerUserID, tblaff_PaymentDetails.VerifiedBy, and tblaff_Affiliates.UserID.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliatesGroups COMMENT 'Comma-separated list of AffiliatesGroupsID values this user can manage. Controls group-level visibility. Empty/whitespace = access to all groups.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Name COMMENT 'Full display name of the admin user.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EmailAddress COMMENT 'Corporate email address. MASKED (dynamic data masking). Used for login, notifications, and as group manager email in tblaff_AffiliatesGroups trigger.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN LoginName COMMENT 'Username for admin portal login. MASKED.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN LoginPassword COMMENT 'Legacy plaintext password field. MASKED. Being replaced by EncryptedLoginPassword. Managed by fiktivo.ChangePassword and fiktivo.CheckPassword.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_ViewAll COMMENT 'Permission: can view all affiliate type definitions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_Edit COMMENT 'Permission: can edit existing affiliate type configurations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_AddNew COMMENT 'Permission: can create new affiliate type definitions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_Delete COMMENT 'Permission: can delete affiliate types.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_ViewAll COMMENT 'Permission: can view all affiliate records in assigned groups.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_Edit COMMENT 'Permission: can edit affiliate profiles, rates, and settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_AddNew COMMENT 'Permission: can onboard new affiliates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_Delete COMMENT 'Permission: can remove affiliate records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_ViewTiers COMMENT 'Permission: can view multi-tier affiliate hierarchies and sub-affiliate structures.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_Import COMMENT 'Permission: can bulk-import affiliate data.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_ViewAll COMMENT 'Permission: can view banner/media categories.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_Edit COMMENT 'Permission: can edit category definitions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_AddNew COMMENT 'Permission: can create new categories.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_Delete COMMENT 'Permission: can delete categories.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_ViewAll COMMENT 'Permission: can view marketing banner assets.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_Edit COMMENT 'Permission: can edit banner content, URLs, and targeting.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_AddNew COMMENT 'Permission: can create new banner assets.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_Delete COMMENT 'Permission: can remove banners.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_Import COMMENT 'Permission: can bulk-import banner data.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_ViewAll COMMENT 'Permission: can view sale/deposit commission event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_Edit COMMENT 'Permission: can edit sale event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_AddNew COMMENT 'Permission: can manually create sale events.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_Delete COMMENT 'Permission: can delete sale event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_Import COMMENT 'Permission: can bulk-import sale data.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN RecurringSales_ViewAll COMMENT 'Permission: can view recurring commission records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN RecurringSales_AddNew COMMENT 'Permission: can create recurring commission entries.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN RecurringSales_Delete COMMENT 'Permission: can remove recurring commissions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_ViewAll COMMENT 'Permission: can view lead (download/signup) records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_Edit COMMENT 'Permission: can edit lead records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_AddNew COMMENT 'Permission: can manually add lead records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_Delete COMMENT 'Permission: can delete lead records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_Import COMMENT 'Permission: can bulk-import leads.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN TrackingCode COMMENT 'Permission: can access and manage affiliate tracking code generation.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateSignupPage COMMENT 'Permission: can configure the affiliate self-registration page settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN SummaryReport COMMENT 'Permission: can view the top-level dashboard summary report.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClicksLeadsSalesSummary COMMENT 'Permission: can run the combined clicks/leads/sales summary report.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClicksLeadsSalesByDay COMMENT 'Permission: can run the daily breakdown clicks/leads/sales report.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_TrendGraphs COMMENT 'Permission: can view trend graph visualizations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_PaymentSummary COMMENT 'Permission: can view payment summary reports.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_AffiliateList COMMENT 'Permission: can view the affiliate listing report.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_SalesSummary COMMENT 'Permission: can view sales summary reports.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_LeadSummary COMMENT 'Permission: can view lead summary reports.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClickSummary COMMENT 'Permission: can view click summary reports.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ImpressionsClicks COMMENT 'Permission: can view impressions and clicks analytics.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_SaleDetail COMMENT 'Permission: can view individual sale detail records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_LeadDetail COMMENT 'Permission: can view individual lead detail records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClickDetail COMMENT 'Permission: can view individual click detail records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_InactiveAffiliates COMMENT 'Permission: can view the inactive affiliates report.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_Banners COMMENT 'Permission: can view banner performance reports.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_PayAffiliates COMMENT 'Permission: can access the affiliate payment tool to initiate payment runs.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_EmailBroadcast COMMENT 'Permission: can send mass email broadcasts to affiliates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_SendAcceptanceEmail COMMENT 'Permission: can send affiliate acceptance/welcome emails.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_ExportPaymentData COMMENT 'Permission: can export payment data to external files.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_EmailEarningsSummaries COMMENT 'Permission: can trigger affiliate earnings summary email sends.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_EmailLinks COMMENT 'Permission: can manage email link tracking.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_Setup COMMENT 'Permission: can modify system-level setup preferences.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_EmailMessages COMMENT 'Permission: can edit system email message templates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_AffiliateConsole COMMENT 'Permission: can configure the affiliate-facing console settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_SpiderIPs COMMENT 'Permission: can manage the spider/bot IP whitelist for traffic filtering.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_SpiderHeaders COMMENT 'Permission: can manage spider/bot detection header patterns.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_IPBlocking COMMENT 'Permission: can manage IP blocking rules for fraud prevention.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_ViewAll COMMENT 'Permission: can view system announcements to affiliates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_Edit COMMENT 'Permission: can edit announcement content.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_AddNew COMMENT 'Permission: can create new announcements.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_Delete COMMENT 'Permission: can remove announcements.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_ViewAll COMMENT 'Permission: can view affiliate group definitions. Default ON - all users can see groups.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Edit COMMENT 'Permission: can edit affiliate group settings and manager assignment. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_AddNew COMMENT 'Permission: can create new affiliate groups. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Delete COMMENT 'Permission: can delete affiliate groups. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Chargebacks_ViewAll COMMENT 'Permission: can view chargeback event records. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Bonuses_ViewAll COMMENT 'Permission: can view bonus event records. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Deposits_ViewAll COMMENT 'Permission: can view deposit event records. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Registrations_ViewAll COMMENT 'Permission: can view registration event records. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_DailySummary COMMENT 'Permission: can view the daily summary report. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_DailySummaryByAffiliate COMMENT 'Permission: can view daily summary broken down by affiliate. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_DownloadsReferrer COMMENT 'Permission: can view download referrer analytics. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_RegistrationSummary COMMENT 'Permission: can view registration summary reports. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_CPASummary COMMENT 'Permission: can view CPA (cost-per-acquisition) summary reports. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_PayAffiliatesApprove COMMENT 'Permission: can approve affiliate payments after review. Part of multi-step payment approval workflow. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_ViewAll COMMENT 'Permission: can view language configurations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_Edit COMMENT 'Permission: can edit language settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_AddNew COMMENT 'Permission: can add new language support.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_Delete COMMENT 'Permission: can remove language configurations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_ViewAll COMMENT 'Permission: can view brand definitions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_Edit COMMENT 'Permission: can edit brand settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_AddNew COMMENT 'Permission: can create new brands.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_Delete COMMENT 'Permission: can remove brands.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_PayAffiliatesReview COMMENT 'Permission: can review pending affiliate payments before approval. Part of multi-step payment workflow.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateManager COMMENT 'High-level role flag: user is an Affiliate Manager responsible for onboarding, managing, and supporting affiliates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN ChiefMarketingOfficer COMMENT 'High-level role flag: user is the CMO with oversight of all marketing operations and affiliate strategy.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AccountingManager COMMENT 'High-level role flag: user is an Accounting Manager responsible for financial reconciliation and payment processing.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCPL COMMENT 'Permission: can access the eCPL (effective cost per lead) tool for lead cost analysis.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCPR COMMENT 'Permission: can access the eCPR (effective cost per registration) tool for registration cost analysis.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Chargebacks_Delete COMMENT 'Permission: can delete chargeback event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Deposits_Delete COMMENT 'Permission: can delete deposit event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Registrations_Delete COMMENT 'Permission: can delete registration event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Bonuses_Delete COMMENT 'Permission: can delete bonus event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCost COMMENT 'Permission: can access the eCost (effective cost) reporting and management tool.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_ViewAll COMMENT 'Permission: can view country configuration and assignment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_Edit COMMENT 'Permission: can edit country settings (group/type assignments).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_AddNew COMMENT 'Permission: can add new country entries.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_Delete COMMENT 'Permission: can remove country entries.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EMailNotifications_ViewAll COMMENT 'Permission: can view email notification templates and settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EMailNotifications_Edit COMMENT 'Permission: can edit email notification templates.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN GeneratePayment COMMENT 'Permission: can generate payment batches for affiliate payouts. Part of multi-step payment workflow.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCostHistoryView COMMENT 'Permission: can view historical eCost records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCostHistoryEdit COMMENT 'Permission: can edit historical eCost records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCostHistoryDelete COMMENT 'Permission: can delete historical eCost records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_ViewAll COMMENT 'Permission: can view conversion tracking pixel configurations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_Edit COMMENT 'Permission: can edit pixel tracking settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_AddNew COMMENT 'Permission: can create new tracking pixels.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_Delete COMMENT 'Permission: can remove tracking pixels.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN PhotoImagePath COMMENT 'File path to the user''s profile photo/avatar image.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Edit_UserList COMMENT 'Permission: can edit the list of users assigned to an affiliate group (viewer assignment).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN IsSystemAdministrator COMMENT 'Master role flag: grants full unrestricted access to all platform functions. NULL treated as false. 21 of 110 users have this flag.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN CopyTraders_ViewAll COMMENT 'Permission: can view copy trader commission event records. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN CopyTraders_Delete COMMENT 'Permission: can delete copy trader event records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Move COMMENT 'Permission: can move affiliates between groups. Default ON.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Audits_View COMMENT 'Permission: can view audit log records (dbo.AuditLog/ChangesLog).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EncryptedLoginPassword COMMENT 'Encrypted version of login password. Replaces the legacy plaintext LoginPassword column. Used by fiktivo.CheckPassword.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN ChangedPasswordDate COMMENT 'Timestamp of last password change. Used by fiktivo.IsPasswordExpired to enforce password rotation policy.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_Move COMMENT 'Permission: can reassign countries between affiliate groups/types.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN IsDeleted COMMENT 'Soft-delete flag. 1 = user account is deactivated. Currently all 110 users are active (IsDeleted=0).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN MarketingManager COMMENT 'High-level role flag: user is a Marketing Manager responsible for campaigns and affiliate marketing operations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN OperationsManager COMMENT 'High-level role flag: user is an Operations Manager responsible for day-to-day platform operations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN FinanceManager COMMENT 'High-level role flag: user is a Finance Manager responsible for payment approvals and financial oversight. 19 of 110 users have this flag.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_CreateGeneric COMMENT 'Permission: can create generic (non-affiliate-specific) tracking pixels.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_ViewAll COMMENT 'Permission: can view instrument type definitions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_Edit COMMENT 'Permission: can edit instrument type settings.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_AddNew COMMENT 'Permission: can create new instrument types.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_Delete COMMENT 'Permission: can delete instrument types.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:55:30 UTC
-- Statements: 137/137 succeeded
-- ====================
