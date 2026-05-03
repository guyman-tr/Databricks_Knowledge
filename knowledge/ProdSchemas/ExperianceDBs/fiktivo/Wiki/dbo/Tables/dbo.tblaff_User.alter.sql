-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_User
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_dbo_tblaff_user
--   main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_user (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user SET TBLPROPERTIES (
    'comment' = 'Back-office admin users for the affiliate management platform (AffWiz), with granular CRUD permission flags controlling access to every functional area. Source: fiktivo.dbo.tblaff_User on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_User',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN UserID COMMENT 'Primary key. Auto-incrementing identifier for each admin user. Referenced by tblaff_AffiliatesGroups.ManagerUserID, tblaff_PaymentDetails.VerifiedBy, and tblaff_Affiliates.UserID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliatesGroups COMMENT 'Comma-separated list of AffiliatesGroupsID values this user can manage. Controls group-level visibility. Empty/whitespace = access to all groups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Name COMMENT 'Full display name of the admin user. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EmailAddress COMMENT 'Corporate email address. MASKED (dynamic data masking). Used for login, notifications, and as group manager email in tblaff_AffiliatesGroups trigger. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN LoginName COMMENT 'Username for admin portal login. MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN LoginPassword COMMENT 'Legacy plaintext password field. MASKED. Being replaced by EncryptedLoginPassword. Managed by fiktivo.ChangePassword and fiktivo.CheckPassword. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_ViewAll COMMENT 'Permission: can view all affiliate type definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_Edit COMMENT 'Permission: can edit existing affiliate type configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_AddNew COMMENT 'Permission: can create new affiliate type definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateTypes_Delete COMMENT 'Permission: can delete affiliate types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_ViewAll COMMENT 'Permission: can view all affiliate records in assigned groups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_Edit COMMENT 'Permission: can edit affiliate profiles, rates, and settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_AddNew COMMENT 'Permission: can onboard new affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_Delete COMMENT 'Permission: can remove affiliate records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_ViewTiers COMMENT 'Permission: can view multi-tier affiliate hierarchies and sub-affiliate structures. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Affiliates_Import COMMENT 'Permission: can bulk-import affiliate data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_ViewAll COMMENT 'Permission: can view banner/media categories. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_Edit COMMENT 'Permission: can edit category definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_AddNew COMMENT 'Permission: can create new categories. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Categories_Delete COMMENT 'Permission: can delete categories. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_ViewAll COMMENT 'Permission: can view marketing banner assets. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_Edit COMMENT 'Permission: can edit banner content, URLs, and targeting. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_AddNew COMMENT 'Permission: can create new banner assets. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_Delete COMMENT 'Permission: can remove banners. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Banners_Import COMMENT 'Permission: can bulk-import banner data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_ViewAll COMMENT 'Permission: can view sale/deposit commission event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_Edit COMMENT 'Permission: can edit sale event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_AddNew COMMENT 'Permission: can manually create sale events. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_Delete COMMENT 'Permission: can delete sale event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Sales_Import COMMENT 'Permission: can bulk-import sale data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN RecurringSales_ViewAll COMMENT 'Permission: can view recurring commission records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN RecurringSales_AddNew COMMENT 'Permission: can create recurring commission entries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN RecurringSales_Delete COMMENT 'Permission: can remove recurring commissions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_ViewAll COMMENT 'Permission: can view lead (download/signup) records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_Edit COMMENT 'Permission: can edit lead records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_AddNew COMMENT 'Permission: can manually add lead records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_Delete COMMENT 'Permission: can delete lead records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Leads_Import COMMENT 'Permission: can bulk-import leads. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN TrackingCode COMMENT 'Permission: can access and manage affiliate tracking code generation. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateSignupPage COMMENT 'Permission: can configure the affiliate self-registration page settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN SummaryReport COMMENT 'Permission: can view the top-level dashboard summary report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClicksLeadsSalesSummary COMMENT 'Permission: can run the combined clicks/leads/sales summary report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClicksLeadsSalesByDay COMMENT 'Permission: can run the daily breakdown clicks/leads/sales report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_TrendGraphs COMMENT 'Permission: can view trend graph visualizations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_PaymentSummary COMMENT 'Permission: can view payment summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_AffiliateList COMMENT 'Permission: can view the affiliate listing report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_SalesSummary COMMENT 'Permission: can view sales summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_LeadSummary COMMENT 'Permission: can view lead summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClickSummary COMMENT 'Permission: can view click summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ImpressionsClicks COMMENT 'Permission: can view impressions and clicks analytics. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_SaleDetail COMMENT 'Permission: can view individual sale detail records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_LeadDetail COMMENT 'Permission: can view individual lead detail records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_ClickDetail COMMENT 'Permission: can view individual click detail records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_InactiveAffiliates COMMENT 'Permission: can view the inactive affiliates report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_Banners COMMENT 'Permission: can view banner performance reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_PayAffiliates COMMENT 'Permission: can access the affiliate payment tool to initiate payment runs. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_EmailBroadcast COMMENT 'Permission: can send mass email broadcasts to affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_SendAcceptanceEmail COMMENT 'Permission: can send affiliate acceptance/welcome emails. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_ExportPaymentData COMMENT 'Permission: can export payment data to external files. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_EmailEarningsSummaries COMMENT 'Permission: can trigger affiliate earnings summary email sends. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_EmailLinks COMMENT 'Permission: can manage email link tracking. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_Setup COMMENT 'Permission: can modify system-level setup preferences. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_EmailMessages COMMENT 'Permission: can edit system email message templates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_AffiliateConsole COMMENT 'Permission: can configure the affiliate-facing console settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_SpiderIPs COMMENT 'Permission: can manage the spider/bot IP whitelist for traffic filtering. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_SpiderHeaders COMMENT 'Permission: can manage spider/bot detection header patterns. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Preferences_IPBlocking COMMENT 'Permission: can manage IP blocking rules for fraud prevention. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_ViewAll COMMENT 'Permission: can view system announcements to affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_Edit COMMENT 'Permission: can edit announcement content. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_AddNew COMMENT 'Permission: can create new announcements. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Announcements_Delete COMMENT 'Permission: can remove announcements. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_ViewAll COMMENT 'Permission: can view affiliate group definitions. Default ON - all users can see groups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Edit COMMENT 'Permission: can edit affiliate group settings and manager assignment. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_AddNew COMMENT 'Permission: can create new affiliate groups. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Delete COMMENT 'Permission: can delete affiliate groups. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Chargebacks_ViewAll COMMENT 'Permission: can view chargeback event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Bonuses_ViewAll COMMENT 'Permission: can view bonus event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Deposits_ViewAll COMMENT 'Permission: can view deposit event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Registrations_ViewAll COMMENT 'Permission: can view registration event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_DailySummary COMMENT 'Permission: can view the daily summary report. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_DailySummaryByAffiliate COMMENT 'Permission: can view daily summary broken down by affiliate. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_DownloadsReferrer COMMENT 'Permission: can view download referrer analytics. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_RegistrationSummary COMMENT 'Permission: can view registration summary reports. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Reports_CPASummary COMMENT 'Permission: can view CPA (cost-per-acquisition) summary reports. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_PayAffiliatesApprove COMMENT 'Permission: can approve affiliate payments after review. Part of multi-step payment approval workflow. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_ViewAll COMMENT 'Permission: can view language configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_Edit COMMENT 'Permission: can edit language settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_AddNew COMMENT 'Permission: can add new language support. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Languages_Delete COMMENT 'Permission: can remove language configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_ViewAll COMMENT 'Permission: can view brand definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_Edit COMMENT 'Permission: can edit brand settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_AddNew COMMENT 'Permission: can create new brands. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Brands_Delete COMMENT 'Permission: can remove brands. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_PayAffiliatesReview COMMENT 'Permission: can review pending affiliate payments before approval. Part of multi-step payment workflow. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateManager COMMENT 'High-level role flag: user is an Affiliate Manager responsible for onboarding, managing, and supporting affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN ChiefMarketingOfficer COMMENT 'High-level role flag: user is the CMO with oversight of all marketing operations and affiliate strategy. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AccountingManager COMMENT 'High-level role flag: user is an Accounting Manager responsible for financial reconciliation and payment processing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCPL COMMENT 'Permission: can access the eCPL (effective cost per lead) tool for lead cost analysis. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCPR COMMENT 'Permission: can access the eCPR (effective cost per registration) tool for registration cost analysis. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Chargebacks_Delete COMMENT 'Permission: can delete chargeback event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Deposits_Delete COMMENT 'Permission: can delete deposit event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Registrations_Delete COMMENT 'Permission: can delete registration event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Bonuses_Delete COMMENT 'Permission: can delete bonus event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCost COMMENT 'Permission: can access the eCost (effective cost) reporting and management tool. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_ViewAll COMMENT 'Permission: can view country configuration and assignment. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_Edit COMMENT 'Permission: can edit country settings (group/type assignments). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_AddNew COMMENT 'Permission: can add new country entries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_Delete COMMENT 'Permission: can remove country entries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EMailNotifications_ViewAll COMMENT 'Permission: can view email notification templates and settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EMailNotifications_Edit COMMENT 'Permission: can edit email notification templates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN GeneratePayment COMMENT 'Permission: can generate payment batches for affiliate payouts. Part of multi-step payment workflow. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCostHistoryView COMMENT 'Permission: can view historical eCost records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCostHistoryEdit COMMENT 'Permission: can edit historical eCost records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Tools_eCostHistoryDelete COMMENT 'Permission: can delete historical eCost records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_ViewAll COMMENT 'Permission: can view conversion tracking pixel configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_Edit COMMENT 'Permission: can edit pixel tracking settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_AddNew COMMENT 'Permission: can create new tracking pixels. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_Delete COMMENT 'Permission: can remove tracking pixels. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN PhotoImagePath COMMENT 'File path to the user''s profile photo/avatar image. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Edit_UserList COMMENT 'Permission: can edit the list of users assigned to an affiliate group (viewer assignment). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN IsSystemAdministrator COMMENT 'Master role flag: grants full unrestricted access to all platform functions. NULL treated as false. 21 of 110 users have this flag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN CopyTraders_ViewAll COMMENT 'Permission: can view copy trader commission event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN CopyTraders_Delete COMMENT 'Permission: can delete copy trader event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN AffiliateGroups_Move COMMENT 'Permission: can move affiliates between groups. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Audits_View COMMENT 'Permission: can view audit log records (dbo.AuditLog/ChangesLog). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN EncryptedLoginPassword COMMENT 'Encrypted version of login password. Replaces the legacy plaintext LoginPassword column. Used by fiktivo.CheckPassword. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN ChangedPasswordDate COMMENT 'Timestamp of last password change. Used by fiktivo.IsPasswordExpired to enforce password rotation policy. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Countries_Move COMMENT 'Permission: can reassign countries between affiliate groups/types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN IsDeleted COMMENT 'Soft-delete flag. 1 = user account is deactivated. Currently all 110 users are active (IsDeleted=0). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN MarketingManager COMMENT 'High-level role flag: user is a Marketing Manager responsible for campaigns and affiliate marketing operations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN OperationsManager COMMENT 'High-level role flag: user is an Operations Manager responsible for day-to-day platform operations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN FinanceManager COMMENT 'High-level role flag: user is a Finance Manager responsible for payment approvals and financial oversight. 19 of 110 users have this flag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Pixels_CreateGeneric COMMENT 'Permission: can create generic (non-affiliate-specific) tracking pixels. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN Trace COMMENT 'Computed audit column. JSON string capturing session metadata: HostName, AppName, SUserName, SPID, DBName, ObjectName. Auto-populated on every operation. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN ValidFrom COMMENT 'System-versioning period start. Hidden column. Row validity start timestamp for temporal queries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN ValidTo COMMENT 'System-versioning period end. Hidden column. Row validity end timestamp for temporal queries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_ViewAll COMMENT 'Permission: can view instrument type definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_Edit COMMENT 'Permission: can edit instrument type settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_AddNew COMMENT 'Permission: can create new instrument types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user ALTER COLUMN InstrumentTypes_Delete COMMENT 'Permission: can delete instrument types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked SET TBLPROPERTIES (
    'comment' = 'Back-office admin users for the affiliate management platform (AffWiz), with granular CRUD permission flags controlling access to every functional area. Source: fiktivo.dbo.tblaff_User on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_User.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_User',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN UserID COMMENT 'Primary key. Auto-incrementing identifier for each admin user. Referenced by tblaff_AffiliatesGroups.ManagerUserID, tblaff_PaymentDetails.VerifiedBy, and tblaff_Affiliates.UserID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliatesGroups COMMENT 'Comma-separated list of AffiliatesGroupsID values this user can manage. Controls group-level visibility. Empty/whitespace = access to all groups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Name COMMENT 'Full display name of the admin user. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN EmailAddress COMMENT 'Corporate email address. MASKED (dynamic data masking). Used for login, notifications, and as group manager email in tblaff_AffiliatesGroups trigger. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN LoginName COMMENT 'Username for admin portal login. MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN LoginPassword COMMENT 'Legacy plaintext password field. MASKED. Being replaced by EncryptedLoginPassword. Managed by fiktivo.ChangePassword and fiktivo.CheckPassword. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateTypes_ViewAll COMMENT 'Permission: can view all affiliate type definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateTypes_Edit COMMENT 'Permission: can edit existing affiliate type configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateTypes_AddNew COMMENT 'Permission: can create new affiliate type definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateTypes_Delete COMMENT 'Permission: can delete affiliate types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Affiliates_ViewAll COMMENT 'Permission: can view all affiliate records in assigned groups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Affiliates_Edit COMMENT 'Permission: can edit affiliate profiles, rates, and settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Affiliates_AddNew COMMENT 'Permission: can onboard new affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Affiliates_Delete COMMENT 'Permission: can remove affiliate records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Affiliates_ViewTiers COMMENT 'Permission: can view multi-tier affiliate hierarchies and sub-affiliate structures. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Affiliates_Import COMMENT 'Permission: can bulk-import affiliate data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Categories_ViewAll COMMENT 'Permission: can view banner/media categories. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Categories_Edit COMMENT 'Permission: can edit category definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Categories_AddNew COMMENT 'Permission: can create new categories. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Categories_Delete COMMENT 'Permission: can delete categories. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Banners_ViewAll COMMENT 'Permission: can view marketing banner assets. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Banners_Edit COMMENT 'Permission: can edit banner content, URLs, and targeting. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Banners_AddNew COMMENT 'Permission: can create new banner assets. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Banners_Delete COMMENT 'Permission: can remove banners. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Banners_Import COMMENT 'Permission: can bulk-import banner data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Sales_ViewAll COMMENT 'Permission: can view sale/deposit commission event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Sales_Edit COMMENT 'Permission: can edit sale event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Sales_AddNew COMMENT 'Permission: can manually create sale events. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Sales_Delete COMMENT 'Permission: can delete sale event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Sales_Import COMMENT 'Permission: can bulk-import sale data. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN RecurringSales_ViewAll COMMENT 'Permission: can view recurring commission records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN RecurringSales_AddNew COMMENT 'Permission: can create recurring commission entries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN RecurringSales_Delete COMMENT 'Permission: can remove recurring commissions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Leads_ViewAll COMMENT 'Permission: can view lead (download/signup) records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Leads_Edit COMMENT 'Permission: can edit lead records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Leads_AddNew COMMENT 'Permission: can manually add lead records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Leads_Delete COMMENT 'Permission: can delete lead records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Leads_Import COMMENT 'Permission: can bulk-import leads. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN TrackingCode COMMENT 'Permission: can access and manage affiliate tracking code generation. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateSignupPage COMMENT 'Permission: can configure the affiliate self-registration page settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN SummaryReport COMMENT 'Permission: can view the top-level dashboard summary report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_ClicksLeadsSalesSummary COMMENT 'Permission: can run the combined clicks/leads/sales summary report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_ClicksLeadsSalesByDay COMMENT 'Permission: can run the daily breakdown clicks/leads/sales report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_TrendGraphs COMMENT 'Permission: can view trend graph visualizations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_PaymentSummary COMMENT 'Permission: can view payment summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_AffiliateList COMMENT 'Permission: can view the affiliate listing report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_SalesSummary COMMENT 'Permission: can view sales summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_LeadSummary COMMENT 'Permission: can view lead summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_ClickSummary COMMENT 'Permission: can view click summary reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_ImpressionsClicks COMMENT 'Permission: can view impressions and clicks analytics. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_SaleDetail COMMENT 'Permission: can view individual sale detail records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_LeadDetail COMMENT 'Permission: can view individual lead detail records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_ClickDetail COMMENT 'Permission: can view individual click detail records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_InactiveAffiliates COMMENT 'Permission: can view the inactive affiliates report. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_Banners COMMENT 'Permission: can view banner performance reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_PayAffiliates COMMENT 'Permission: can access the affiliate payment tool to initiate payment runs. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_EmailBroadcast COMMENT 'Permission: can send mass email broadcasts to affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_SendAcceptanceEmail COMMENT 'Permission: can send affiliate acceptance/welcome emails. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_ExportPaymentData COMMENT 'Permission: can export payment data to external files. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_EmailEarningsSummaries COMMENT 'Permission: can trigger affiliate earnings summary email sends. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_EmailLinks COMMENT 'Permission: can manage email link tracking. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Preferences_Setup COMMENT 'Permission: can modify system-level setup preferences. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Preferences_EmailMessages COMMENT 'Permission: can edit system email message templates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Preferences_AffiliateConsole COMMENT 'Permission: can configure the affiliate-facing console settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Preferences_SpiderIPs COMMENT 'Permission: can manage the spider/bot IP whitelist for traffic filtering. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Preferences_SpiderHeaders COMMENT 'Permission: can manage spider/bot detection header patterns. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Preferences_IPBlocking COMMENT 'Permission: can manage IP blocking rules for fraud prevention. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Announcements_ViewAll COMMENT 'Permission: can view system announcements to affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Announcements_Edit COMMENT 'Permission: can edit announcement content. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Announcements_AddNew COMMENT 'Permission: can create new announcements. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Announcements_Delete COMMENT 'Permission: can remove announcements. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateGroups_ViewAll COMMENT 'Permission: can view affiliate group definitions. Default ON - all users can see groups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateGroups_Edit COMMENT 'Permission: can edit affiliate group settings and manager assignment. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateGroups_AddNew COMMENT 'Permission: can create new affiliate groups. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateGroups_Delete COMMENT 'Permission: can delete affiliate groups. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Chargebacks_ViewAll COMMENT 'Permission: can view chargeback event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Bonuses_ViewAll COMMENT 'Permission: can view bonus event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Deposits_ViewAll COMMENT 'Permission: can view deposit event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Registrations_ViewAll COMMENT 'Permission: can view registration event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_DailySummary COMMENT 'Permission: can view the daily summary report. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_DailySummaryByAffiliate COMMENT 'Permission: can view daily summary broken down by affiliate. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_DownloadsReferrer COMMENT 'Permission: can view download referrer analytics. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_RegistrationSummary COMMENT 'Permission: can view registration summary reports. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Reports_CPASummary COMMENT 'Permission: can view CPA (cost-per-acquisition) summary reports. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_PayAffiliatesApprove COMMENT 'Permission: can approve affiliate payments after review. Part of multi-step payment approval workflow. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Languages_ViewAll COMMENT 'Permission: can view language configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Languages_Edit COMMENT 'Permission: can edit language settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Languages_AddNew COMMENT 'Permission: can add new language support. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Languages_Delete COMMENT 'Permission: can remove language configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Brands_ViewAll COMMENT 'Permission: can view brand definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Brands_Edit COMMENT 'Permission: can edit brand settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Brands_AddNew COMMENT 'Permission: can create new brands. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Brands_Delete COMMENT 'Permission: can remove brands. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_PayAffiliatesReview COMMENT 'Permission: can review pending affiliate payments before approval. Part of multi-step payment workflow. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateManager COMMENT 'High-level role flag: user is an Affiliate Manager responsible for onboarding, managing, and supporting affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN ChiefMarketingOfficer COMMENT 'High-level role flag: user is the CMO with oversight of all marketing operations and affiliate strategy. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AccountingManager COMMENT 'High-level role flag: user is an Accounting Manager responsible for financial reconciliation and payment processing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_eCPL COMMENT 'Permission: can access the eCPL (effective cost per lead) tool for lead cost analysis. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_eCPR COMMENT 'Permission: can access the eCPR (effective cost per registration) tool for registration cost analysis. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Chargebacks_Delete COMMENT 'Permission: can delete chargeback event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Deposits_Delete COMMENT 'Permission: can delete deposit event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Registrations_Delete COMMENT 'Permission: can delete registration event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Bonuses_Delete COMMENT 'Permission: can delete bonus event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_eCost COMMENT 'Permission: can access the eCost (effective cost) reporting and management tool. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Countries_ViewAll COMMENT 'Permission: can view country configuration and assignment. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Countries_Edit COMMENT 'Permission: can edit country settings (group/type assignments). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Countries_AddNew COMMENT 'Permission: can add new country entries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Countries_Delete COMMENT 'Permission: can remove country entries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN EMailNotifications_ViewAll COMMENT 'Permission: can view email notification templates and settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN EMailNotifications_Edit COMMENT 'Permission: can edit email notification templates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN GeneratePayment COMMENT 'Permission: can generate payment batches for affiliate payouts. Part of multi-step payment workflow. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_eCostHistoryView COMMENT 'Permission: can view historical eCost records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_eCostHistoryEdit COMMENT 'Permission: can edit historical eCost records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Tools_eCostHistoryDelete COMMENT 'Permission: can delete historical eCost records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Pixels_ViewAll COMMENT 'Permission: can view conversion tracking pixel configurations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Pixels_Edit COMMENT 'Permission: can edit pixel tracking settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Pixels_AddNew COMMENT 'Permission: can create new tracking pixels. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Pixels_Delete COMMENT 'Permission: can remove tracking pixels. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN PhotoImagePath COMMENT 'File path to the user''s profile photo/avatar image. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateGroups_Edit_UserList COMMENT 'Permission: can edit the list of users assigned to an affiliate group (viewer assignment). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN IsSystemAdministrator COMMENT 'Master role flag: grants full unrestricted access to all platform functions. NULL treated as false. 21 of 110 users have this flag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN CopyTraders_ViewAll COMMENT 'Permission: can view copy trader commission event records. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN CopyTraders_Delete COMMENT 'Permission: can delete copy trader event records. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN AffiliateGroups_Move COMMENT 'Permission: can move affiliates between groups. Default ON. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Audits_View COMMENT 'Permission: can view audit log records (dbo.AuditLog/ChangesLog). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN EncryptedLoginPassword COMMENT 'Encrypted version of login password. Replaces the legacy plaintext LoginPassword column. Used by fiktivo.CheckPassword. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN ChangedPasswordDate COMMENT 'Timestamp of last password change. Used by fiktivo.IsPasswordExpired to enforce password rotation policy. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Countries_Move COMMENT 'Permission: can reassign countries between affiliate groups/types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN IsDeleted COMMENT 'Soft-delete flag. 1 = user account is deactivated. Currently all 110 users are active (IsDeleted=0). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN MarketingManager COMMENT 'High-level role flag: user is a Marketing Manager responsible for campaigns and affiliate marketing operations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN OperationsManager COMMENT 'High-level role flag: user is an Operations Manager responsible for day-to-day platform operations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN FinanceManager COMMENT 'High-level role flag: user is a Finance Manager responsible for payment approvals and financial oversight. 19 of 110 users have this flag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Pixels_CreateGeneric COMMENT 'Permission: can create generic (non-affiliate-specific) tracking pixels. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN Trace COMMENT 'Computed audit column. JSON string capturing session metadata: HostName, AppName, SUserName, SPID, DBName, ObjectName. Auto-populated on every operation. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN ValidFrom COMMENT 'System-versioning period start. Hidden column. Row validity start timestamp for temporal queries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN ValidTo COMMENT 'System-versioning period end. Hidden column. Row validity end timestamp for temporal queries. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN InstrumentTypes_ViewAll COMMENT 'Permission: can view instrument type definitions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN InstrumentTypes_Edit COMMENT 'Permission: can edit instrument type settings. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN InstrumentTypes_AddNew COMMENT 'Permission: can create new instrument types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked ALTER COLUMN InstrumentTypes_Delete COMMENT 'Permission: can delete instrument types. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_User)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
