-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily > Rolling 90-day live acquisition dashboard tracking customer registrations and first-time deposits across affiliate, channel, country, and funnel dimensions (17 cols, ~1.47M rows, refreshed daily). Written by `SP_LiveAcquisitionDashboard_Daily` from `DWH_dbo.Dim_Customer` via UNION ALL of FTD and Registration events. Supports acquisition monitoring and affiliate performance reporting with two KPI types per customer event. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `DWH_dbo.Dim_Customer` ← Customer.CustomerStatic + CustomerFinanceDB.FirstTimeDeposits via SP_LiveAcquisitionDashboard_Daily | | **Refresh** | Daily SB_Daily (rolling 90-day DELETE + INSERT) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (CID ASC) | | **UC Target** |'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN AffiliatesGroupsName COMMENT 'Affiliate group/network name from `DWH_dbo.Dim_Affiliate.AffiliatesGroupsName` (AffWizz affiliate management system). Groups individual affiliates into their parent network (e.g., "Adtraction", "Google"). (Tier 2 - Dim_Affiliate via SP_LiveAcquisitionDashboard_Daily)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Contact COMMENT 'Affiliate contact/campaign identifier from `DWH_dbo.Dim_Affiliate.Contact`. Typically a campaign tag or affiliate contact string used for sub-campaign attribution. (Tier 2 - Dim_Affiliate via SP_LiveAcquisitionDashboard_Daily)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Channel COMMENT 'Marketing acquisition channel from `DWH_dbo.Dim_Channel.Channel` (e.g., SEM, Direct, Affiliate, Social). Standardized marketing taxonomy. (Tier 2 - Dim_Channel via SP_LiveAcquisitionDashboard_Daily)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN SubChannel COMMENT 'Marketing sub-channel from `DWH_dbo.Dim_Channel.SubChannel` (e.g., Google Brand, FB, Taboola, Organic). More granular channel split. (Tier 2 - Dim_Channel via SP_LiveAcquisitionDashboard_Daily)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN CID COMMENT 'Customer identifier (RealCID from Dim_Customer). Platform-internal primary key assigned at registration. (Tier 2 - Dim_Customer.RealCID via SP_LiveAcquisitionDashboard_Daily)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Date COMMENT 'Event date. Meaning depends on KPI: for KPI=''FTDs'' -> FirstDepositDate; for KPI=''Registration'' -> RegisteredReal. Range: rolling 90 days from load date. (Tier 2 - Dim_Customer.FirstDepositDate or Dim_Customer.RegisteredReal)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Region COMMENT 'Marketing region name from `DWH_dbo.Dim_Country.MarketingRegionManualName` - manually curated marketing-team region. Not a standard geographic boundary. Top values: UK, Spain, French, Italian, CEE. (Tier 2 - Dim_Country.MarketingRegionManualName)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Country COMMENT 'Full country name in English from `DWH_dbo.Dim_Country.Name` based on customer''s registered CountryID. (Tier 1 - Dictionary.Country via Dim_Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN KPI COMMENT 'Event type discriminator: ''FTDs'' (first-time deposit event) or ''Registration'' (real account registration event). Hardcoded in the SP''s UNION ALL branches. (Tier 2 - SP_LiveAcquisitionDashboard_Daily hardcoded literal)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN FTDA COMMENT 'First deposit amount in USD. Populated only for KPI=''FTDs'' rows from `Dim_Customer.FirstDepositAmount`. NULL for KPI=''Registration'' rows. (Tier 2 - Dim_Customer.FirstDepositAmount via CustomerFinanceDB.Customer.FirstTimeDeposits)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN SerialID COMMENT 'Affiliate ID - acquisition affiliate/partner identifier. From `Dim_Customer.AffiliateID` (= Customer.CustomerStatic.SerialID). FK to `DWH_dbo.Dim_Affiliate`. (Tier 2 - Dim_Customer.AffiliateID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN SubSerialID COMMENT 'Sub-affiliate campaign tracking string from `Dim_Customer.SubSerialID`. Allows affiliates to track sub-campaigns or sub-partners within their attribution. (Tier 2 - Dim_Customer.SubSerialID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN DownloadID COMMENT 'App download/install attribution ID from `Dim_Customer.DownloadID`. Used for mobile app acquisition tracking. (Tier 2 - Dim_Customer.DownloadID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN FunnelName COMMENT 'Name of the acquisition funnel the customer entered, from `DWH_dbo.Dim_Funnel.Name` on `Dim_Customer.FunnelID`. NULL if no funnel. (Tier 2 - Dim_Funnel.Name via Dim_Customer.FunnelID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN FunnelFromName COMMENT 'Name of the source funnel (referral funnel), from `DWH_dbo.Dim_Funnel.Name` on `Dim_Customer.FunnelFromID`. LEFT JOIN - NULL when no source funnel. (Tier 2 - Dim_Funnel.Name via Dim_Customer.FunnelFromID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN State COMMENT 'State/province name from `DWH_dbo.Dim_State_and_Province.Name` on `Dim_Customer.RegionID`. Derived from customer''s IP at registration. LEFT JOIN - NULL when no IP region match. (Tier 2 - Dim_State_and_Province.Name via Dim_Customer.RegionID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN UpdateDate COMMENT 'Batch timestamp set to GETDATE() at INSERT time. Reflects when the SP last ran. (Tier 3 - GETDATE())';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN AffiliatesGroupsName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Contact SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN KPI SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN SerialID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN SubSerialID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN DownloadID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN FunnelName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN FunnelFromName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN State SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_liveacquisitiondashboard_daily ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:58:58 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 36/36 succeeded
-- ====================
