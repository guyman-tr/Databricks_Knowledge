-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DCM_Dashboard
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DCM_Dashboard > 6M-row daily media campaign performance dashboard combining Google Campaign Manager 360 (DCM) Fivetran data with internal back-office registration/FTD counts and first-action product breakdowns - three levels of detail (High Level, DCM Level, First Action) for Media/Content Partnerships/Media Performance/Media CPA affiliate channels, rolling 90-day backfill, refreshed daily via SP_DCM_Dashboard (author: Jan Iablunovskey, 2021-10-18). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | External_Fivetran_double_click_campaign_manager_media_campaign (DCM) + BI_DB_CIDFirstDates (reg/FTD) + BI_DB_First5Actions (product breakdown) via SP_DCM_Dashboard | | **Refresh** | Daily (SB_Daily, Priority 0) - DELETE last 90 days + INSERT via UNION of 3 LOD levels | | **Synapse Distribution** | ROUND_RO'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Date COMMENT 'Campaign reporting date. Range: 2023-08-27 to present, 961 distinct dates. Part of the natural grain. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Country COMMENT 'Country name from Dim_Country, resolved via BI_DB_CountryDCM mapping for DCM data or directly from BI_DB_CIDFirstDates.Country for back-office data. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN AffiliateID COMMENT 'Affiliate partner identifier. Extracted from DCM campaign names (trailing numeric segment) or from BI_DB_CIDFirstDates.SerialID. Filtered to Media/Content Partnerships/Media Performance/Media CPA channels. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Impressions COMMENT 'Total ad impressions from DCM. SUM across activities per group. 0 for First Action LOD. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Clicks COMMENT 'Total ad clicks from DCM. SUM across activities per group. 0 for First Action LOD. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN FTDs COMMENT 'First-time deposit count from back-office (BI_DB_CIDFirstDates). High Level LOD only; 0 for DCM Level and First Action. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Regs COMMENT 'Registration count from back-office (BI_DB_CIDFirstDates). High Level LOD only; 0 for DCM Level and First Action. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 - Propagation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Campaign COMMENT 'Full DCM campaign name from Fivetran. DCM Level LOD only; NULL for High Level and First Action. Contains affiliate ID, country code, and platform info. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN CampaignId COMMENT 'DCM campaign numeric identifier from Fivetran. DCM Level LOD only; NULL for High Level and First Action. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Placement COMMENT 'DCM ad placement name from Fivetran. DCM Level LOD only; NULL for High Level and First Action. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN PlacementId COMMENT 'DCM placement numeric identifier from Fivetran. DCM Level LOD only; NULL for High Level and First Action. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN MediaCost COMMENT 'Media advertising cost from DCM (media_cost). SUM per group. 0 for First Action LOD. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewFTD COMMENT 'View-through FTD conversions from DCM (activity=''FTD'', view_through_conversions). User saw ad and later deposited. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickFTD COMMENT 'Click-through FTD conversions from DCM (activity=''FTD'', click_through_conversions). User clicked ad and deposited. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewAndroidFTD COMMENT 'View-through FTD conversions from Android DCM tracking (activity=''FTD_Android''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickAndroidFTD COMMENT 'Click-through FTD conversions from Android DCM tracking (activity=''FTD_Android''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewRegistration COMMENT 'View-through registration conversions from DCM (activity=''Registration''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickRegistration COMMENT 'Click-through registration conversions from DCM (activity=''Registration''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewAndroidRegistration COMMENT 'View-through registration conversions from Android DCM tracking (activity=''Registration_Android''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickAndroidRegistration COMMENT 'Click-through registration conversions from Android DCM tracking (activity=''Registration_Android''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN LOD COMMENT 'Level of Detail indicator determining which metrics are populated. ''High Level'' = aggregated DCM + back-office. ''DCM Level'' = campaign/placement detail. ''First Action'' = product breakdown. Never aggregate across LOD values. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN CampaignName COMMENT 'Short campaign name extracted from DCM campaign field (LEFT up to first underscore). DCM Level LOD only; NULL for others. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN FTDs1 COMMENT 'Duplicate of FTDs - legacy artifact from 2021-11-16 calculation change. Same value as FTDs at High Level; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Regs1 COMMENT 'Duplicate of Regs - legacy artifact from 2021-11-16 calculation change. Same value as Regs at High Level; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Stocks COMMENT 'Count of FTDs whose first action was Stocks/ETFs. First Action LOD only; 0 otherwise. From BI_DB_First5Actions.FirstAction=''Stocks/ETFs''. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN CFDs COMMENT 'Count of FTDs whose first action was FX/Commodities/Indices (labeled CFDs). First Action LOD only; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Crypto COMMENT 'Count of FTDs whose first action was Crypto. First Action LOD only; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Copy COMMENT 'Count of FTDs whose first action was Copy (CopyTrader). First Action LOD only; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN SmartPortfolio COMMENT 'Count of FTDs whose first action was Copy Fund (Smart Portfolio). First Action LOD only; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN FirstActionNULL COMMENT 'Count of FTDs with no recorded first action. First Action LOD only; 0 otherwise. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewIOSFTD COMMENT 'View-through FTD conversions from iOS DCM tracking (activity=''FTD_IOS''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickIOSFTD COMMENT 'Click-through FTD conversions from iOS DCM tracking (activity=''FTD_IOS''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewIOSRegistration COMMENT 'View-through registration conversions from iOS DCM tracking (activity=''Registration_IOS''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickIOSRegistration COMMENT 'Click-through registration conversions from iOS DCM tracking (activity=''Registration_IOS''). (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Creative COMMENT 'Ad creative name/identifier from DCM. DCM Level LOD only; NULL for others. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN NewMarketingRegion COMMENT 'Marketing region from Dim_Country.MarketingRegionManualName. Named "New" to distinguish from legacy region mapping. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Contact COMMENT 'Affiliate contact person from Dim_Affiliate.Contact. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Channel COMMENT 'Affiliate channel from Dim_Affiliate.Channel. Expected values: ''Media'', ''Content Partnerships'', ''Media Performance'', ''Media CPA''. (Tier 2 - SP_DCM_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN SubChannel COMMENT 'Affiliate sub-channel from Dim_Affiliate.SubChannel. Finer granularity within Channel. (Tier 2 - SP_DCM_Dashboard)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Impressions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Clicks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN FTDs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Regs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Campaign SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN CampaignId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Placement SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN PlacementId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN MediaCost SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewAndroidFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickAndroidFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewRegistration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickRegistration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewAndroidRegistration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickAndroidRegistration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN LOD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN CampaignName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN FTDs1 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Regs1 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN CFDs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Copy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN SmartPortfolio SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN FirstActionNULL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewIOSFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickIOSFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ViewIOSRegistration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN ClickIOSRegistration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Creative SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN NewMarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Contact SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dcm_dashboard ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:37:41 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 82/82 succeeded
-- ====================
