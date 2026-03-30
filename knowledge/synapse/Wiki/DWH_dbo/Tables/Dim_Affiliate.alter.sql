-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Affiliate
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked
-- Resolved via: information_schema bulk query
-- Classification: PII Masked
-- Secondary UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate  (PII unmasked)
-- Masked Columns: Email,City
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked SET TBLPROPERTIES (
    'comment' = '`Dim_Affiliate` is the master dimension for eToro''s affiliate marketing partners. Each row represents one affiliate partner (identified by `AffiliateID`), combining: - **Profile data** from the AffWizz affiliate management system (contact, company, website, login credentials) - **Channel classification** (SubChannel, Channel) from the unified channel mapping - **Trading account linkage** - resolving up to 4 username variants to find the affiliate''s own eToro trading account - **Performance aggregates** - Registration, FTD (First Time Deposit), and FTDe (First Time Deposit equivalent) counts across 7 time windows each (Yesterday, ThisMonth, LastMonth, ThisQuarter, LastQuarter, ThisYear, LastYear, Lifetime) - **Contract classification** - affiliate payment model derived from ContractName keywords The table answers: "Who is this affiliate, how are they classified, what contract do they have, and what are their referral performance metrics?" ### Key Business Concepts - **FTD vs FTDe**: FTD = First Time Deposit...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (AffiliateID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN AffiliateID COMMENT 'Unique affiliate partner identifier from AffWizz system. Primary key. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN DateCreated COMMENT 'Date the affiliate was created/registered in AffWizz. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN SubChannelID COMMENT 'Marketing sub-channel identifier. JOINs to Dim_Channel.SubChannelID. Values: 1=Affiliate Partners, 2=SEM, 3=SEO, etc. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Contact COMMENT 'Primary contact information for the affiliate partner. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN ContractName COMMENT 'Free-text name of the affiliate''s contract/payment agreement. Used as input for the ContractType classification logic. E.g., "Rev Share + CPA", "CPL Standard". (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN ContractType COMMENT 'Computed affiliate payment model: 0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR. Derived from ContractName via CASE expression. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN AffiliatesGroupsName COMMENT 'Marketing group the affiliate belongs to. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN AccountActivated COMMENT 'Whether the affiliate account is active. 1=Active, 0/NULL=Inactive. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN LoginName COMMENT 'Affiliate''s login name in the AffWizz system. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN TradingAccount_RealCID COMMENT 'Affiliate''s own eToro real-money CID, resolved via COALESCE across 4 username lookups against Ext_Dim_Affiliate_Customer. NULL if no match. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN TradingAccount_UserName COMMENT 'eToro username that matched for the affiliate''s trading account. First non-NULL from 4 UserName variants. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Email COMMENT 'Affiliate''s email address. **MASKED** with default() - requires UNMASK permission. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN CompanyAddress COMMENT 'Affiliate''s company street address. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN City COMMENT 'Affiliate''s city. **MASKED** with default() - requires UNMASK permission. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN CountryID COMMENT 'Affiliate''s country. JOINs to Dim_Country.CountryID. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN WebSiteURL COMMENT 'Affiliate''s website URL used for referral traffic. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationFirstDate COMMENT 'Date of the affiliate''s first referred registration. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastDate COMMENT 'Date of the affiliate''s most recent referred registration. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLifeTime COMMENT 'Total registrations referred by this affiliate, all time. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationYesterday COMMENT 'Registrations referred yesterday. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastMonth COMMENT 'Registrations referred last calendar month. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastQuarter COMMENT 'Registrations referred last calendar quarter. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastYear COMMENT 'Registrations referred last calendar year. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDFirstDate COMMENT 'Date of the affiliate''s first referred FTD (First Time Deposit). (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastDate COMMENT 'Date of the most recent referred FTD. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLifeTime COMMENT 'Total FTDs referred by this affiliate, all time. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDYesterday COMMENT 'FTDs referred yesterday. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastMonth COMMENT 'FTDs referred last calendar month. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastQuarter COMMENT 'FTDs referred last calendar quarter. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastYear COMMENT 'FTDs referred last calendar year. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeFirstDate COMMENT 'Date of the affiliate''s first referred FTDe (FTD equivalent - includes qualifying non-deposit events). (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastDate COMMENT 'Date of the most recent referred FTDe. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLifeTime COMMENT 'Total FTDe events referred all time. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeYesterday COMMENT 'FTDe events referred yesterday. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastMonth COMMENT 'FTDe events referred last calendar month. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastQuarter COMMENT 'FTDe events referred last calendar quarter. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastYear COMMENT 'FTDe events referred last calendar year. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN MasterAffiliateID COMMENT 'Parent/master affiliate in the hierarchy. NULL if this is a standalone or top-level affiliate. JOINs to Dim_Affiliate.AffiliateID (self-reference). (Tier 2 - Ext_Dim_Affiliate_MasterAffiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE() during SP_Dim_Affiliate execution. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationThisMonth COMMENT 'Registrations referred current calendar month to date. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationThisQuarter COMMENT 'Registrations referred current calendar quarter to date. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationThisYear COMMENT 'Registrations referred current calendar year to date. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeThisMonth COMMENT 'FTDe events referred current calendar month to date. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeThisQuarter COMMENT 'FTDe events referred current calendar quarter to date. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeThisYear COMMENT 'FTDe events referred current calendar year to date. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDThisMonth COMMENT 'FTDs referred current calendar month to date. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDThisQuarter COMMENT 'FTDs referred current calendar quarter to date. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDThisYear COMMENT 'FTDs referred current calendar year to date. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN LanguageName COMMENT 'Affiliate''s preferred language. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN WebSiteTitle COMMENT 'Title/name of the affiliate''s website. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN GCID COMMENT 'Global Customer ID linking the affiliate to the eToro customer graph. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN EntityName COMMENT 'Legal entity name for the affiliate company. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN ContactPersonFullName COMMENT 'Full name of the affiliate''s primary contact person. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Telephone COMMENT 'Affiliate contact phone number. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN SubChannel COMMENT 'Marketing sub-channel name (e.g., "Affiliate Partners", "SEM Brand"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Channel COMMENT 'Top-level marketing channel (e.g., "Paid", "Organic", "Affiliate"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN DateCreated SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN SubChannelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Contact SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN ContractName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN ContractType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN AffiliatesGroupsName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN AccountActivated SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN LoginName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN TradingAccount_RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN TradingAccount_UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Email SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN CompanyAddress SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN City SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN WebSiteURL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationFirstDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLifeTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationYesterday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationLastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDFirstDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLifeTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDYesterday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDLastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeFirstDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLifeTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeYesterday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeLastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN MasterAffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationThisMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationThisQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN RegistrationThisYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeThisMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeThisQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDeThisYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDThisMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDThisQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN FTDThisYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN LanguageName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN WebSiteTitle SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN EntityName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN ContactPersonFullName SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Telephone SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked ALTER COLUMN Channel SET TAGS ('pii' = 'none');

-- === Secondary UC Target (PII unmasked) ===
-- UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate
-- Masked Columns: Email,City
-- Column comments are identical - meaning is the same regardless of masking.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate SET TBLPROPERTIES (
    'comment' = '`Dim_Affiliate` is the master dimension for eToro''s affiliate marketing partners. Each row represents one affiliate partner (identified by `AffiliateID`), combining: - **Profile data** from the AffWizz affiliate management system (contact, company, website, login credentials) - **Channel classification** (SubChannel, Channel) from the unified channel mapping - **Trading account linkage** - resolving up to 4 username variants to find the affiliate''s own eToro trading account - **Performance aggregates** - Registration, FTD (First Time Deposit), and FTDe (First Time Deposit equivalent) counts across 7 time windows each (Yesterday, ThisMonth, LastMonth, ThisQuarter, LastQuarter, ThisYear, LastYear, Lifetime) - **Contract classification** - affiliate payment model derived from ContractName keywords The table answers: "Who is this affiliate, how are they classified, what contract do they have, and what are their referral performance metrics?" ### Key Business Concepts - **FTD vs FTDe**: FTD = First Time Deposit...'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (AffiliateID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN AffiliateID COMMENT 'Unique affiliate partner identifier from AffWizz system. Primary key. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN DateCreated COMMENT 'Date the affiliate was created/registered in AffWizz. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN SubChannelID COMMENT 'Marketing sub-channel identifier. JOINs to Dim_Channel.SubChannelID. Values: 1=Affiliate Partners, 2=SEM, 3=SEO, etc. Sourced from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Contact COMMENT 'Primary contact information for the affiliate partner. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN ContractName COMMENT 'Free-text name of the affiliate''s contract/payment agreement. Used as input for the ContractType classification logic. E.g., "Rev Share + CPA", "CPL Standard". (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN ContractType COMMENT 'Computed affiliate payment model: 0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR. Derived from ContractName via CASE expression. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN AffiliatesGroupsName COMMENT 'Marketing group the affiliate belongs to. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN AccountActivated COMMENT 'Whether the affiliate account is active. 1=Active, 0/NULL=Inactive. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN LoginName COMMENT 'Affiliate''s login name in the AffWizz system. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN TradingAccount_RealCID COMMENT 'Affiliate''s own eToro real-money CID, resolved via COALESCE across 4 username lookups against Ext_Dim_Affiliate_Customer. NULL if no match. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN TradingAccount_UserName COMMENT 'eToro username that matched for the affiliate''s trading account. First non-NULL from 4 UserName variants. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Email COMMENT 'Affiliate''s email address. **MASKED** with default() - requires UNMASK permission. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN CompanyAddress COMMENT 'Affiliate''s company street address. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN City COMMENT 'Affiliate''s city. **MASKED** with default() - requires UNMASK permission. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN CountryID COMMENT 'Affiliate''s country. JOINs to Dim_Country.CountryID. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN WebSiteURL COMMENT 'Affiliate''s website URL used for referral traffic. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationFirstDate COMMENT 'Date of the affiliate''s first referred registration. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastDate COMMENT 'Date of the affiliate''s most recent referred registration. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLifeTime COMMENT 'Total registrations referred by this affiliate, all time. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationYesterday COMMENT 'Registrations referred yesterday. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastMonth COMMENT 'Registrations referred last calendar month. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastQuarter COMMENT 'Registrations referred last calendar quarter. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastYear COMMENT 'Registrations referred last calendar year. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDFirstDate COMMENT 'Date of the affiliate''s first referred FTD (First Time Deposit). (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastDate COMMENT 'Date of the most recent referred FTD. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLifeTime COMMENT 'Total FTDs referred by this affiliate, all time. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDYesterday COMMENT 'FTDs referred yesterday. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastMonth COMMENT 'FTDs referred last calendar month. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastQuarter COMMENT 'FTDs referred last calendar quarter. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastYear COMMENT 'FTDs referred last calendar year. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeFirstDate COMMENT 'Date of the affiliate''s first referred FTDe (FTD equivalent - includes qualifying non-deposit events). (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastDate COMMENT 'Date of the most recent referred FTDe. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLifeTime COMMENT 'Total FTDe events referred all time. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeYesterday COMMENT 'FTDe events referred yesterday. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastMonth COMMENT 'FTDe events referred last calendar month. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastQuarter COMMENT 'FTDe events referred last calendar quarter. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastYear COMMENT 'FTDe events referred last calendar year. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN MasterAffiliateID COMMENT 'Parent/master affiliate in the hierarchy. NULL if this is a standalone or top-level affiliate. JOINs to Dim_Affiliate.AffiliateID (self-reference). (Tier 2 - Ext_Dim_Affiliate_MasterAffiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE() during SP_Dim_Affiliate execution. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationThisMonth COMMENT 'Registrations referred current calendar month to date. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationThisQuarter COMMENT 'Registrations referred current calendar quarter to date. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationThisYear COMMENT 'Registrations referred current calendar year to date. (Tier 2 - Ext_Dim_Affiliate_Registrations)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeThisMonth COMMENT 'FTDe events referred current calendar month to date. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeThisQuarter COMMENT 'FTDe events referred current calendar quarter to date. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeThisYear COMMENT 'FTDe events referred current calendar year to date. (Tier 2 - Ext_Dim_Affiliate_FTDe)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDThisMonth COMMENT 'FTDs referred current calendar month to date. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDThisQuarter COMMENT 'FTDs referred current calendar quarter to date. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDThisYear COMMENT 'FTDs referred current calendar year to date. (Tier 2 - Ext_Dim_Affiliate_FTD)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN LanguageName COMMENT 'Affiliate''s preferred language. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN WebSiteTitle COMMENT 'Title/name of the affiliate''s website. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN GCID COMMENT 'Global Customer ID linking the affiliate to the eToro customer graph. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN EntityName COMMENT 'Legal entity name for the affiliate company. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN ContactPersonFullName COMMENT 'Full name of the affiliate''s primary contact person. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Telephone COMMENT 'Affiliate contact phone number. (Tier 2 - Ext_Dim_Channel_Affiliate_UnifyCode)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN SubChannel COMMENT 'Marketing sub-channel name (e.g., "Affiliate Partners", "SEM Brand"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Channel COMMENT 'Top-level marketing channel (e.g., "Paid", "Organic", "Affiliate"). Inherited from Ext_Dim_SubChannel_UnifyCode. (Tier 2 - SP_Dim_Affiliate)';

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN DateCreated SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN SubChannelID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Contact SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN ContractName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN ContractType SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN AffiliatesGroupsName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN AccountActivated SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN LoginName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN TradingAccount_RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN TradingAccount_UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Email SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN CompanyAddress SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN City SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN WebSiteURL SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationFirstDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLifeTime SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationYesterday SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationLastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDFirstDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLifeTime SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDYesterday SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDLastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeFirstDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLifeTime SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeYesterday SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeLastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN MasterAffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationThisMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationThisQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN RegistrationThisYear SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeThisMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeThisQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDeThisYear SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDThisMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDThisQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN FTDThisYear SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN LanguageName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN WebSiteTitle SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN EntityName SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN ContactPersonFullName SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Telephone SET TAGS ('pii' = 'direct');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate ALTER COLUMN Channel SET TAGS ('pii' = 'none');
