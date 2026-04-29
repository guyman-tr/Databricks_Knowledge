-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Channel
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel SET TBLPROPERTIES (
    'comment' = 'Dim_Channel is the marketing acquisition channel dimension for eToro''s DWH. It classifies every affiliate sub-channel into a standardized channel hierarchy with an Organic vs. Paid indicator. Each row represents a unique sub-channel (e.g., "Google Brand", "FB", "Taboola") mapped to a parent channel (e.g., "SEM", "Direct", "Affiliate"). The Organic/Paid flag enables marketing analysts to split spend and attribution without re-deriving the classification. The data originates from the AffWizz affiliate management system (fiktivo database). The production source tables are `fiktivo_dbo.tblaff_Affiliates` joined with `fiktivo_dbo.tblaff_MarketingExpense` and `fiktivo_dbo.tblaff_AffiliatesGroups`. There is no upstream production wiki - AffWizz is an external affiliate platform with no semantic documentation in the DB_Schema repository. All column descriptions are derived from ETL SP code analysis (Tier 2). The table is loaded daily via a two-step ETL chain: `SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse` (bui...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX (SubChannelID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN SubChannelID COMMENT 'Primary key. DWH-derived sub-channel identifier assigned via a CASE expression in SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse. Maps affiliate contact strings to ~30 standardized sub-channel categories (e.g., 4=Google Brand, 5=Google Search, 32=FB, 33=Taboola). NOT a production FK - computed entirely in DWH ETL. (Tier 2 - SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN Channel COMMENT 'Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: ''Introducing Agents'' -> ''Affiliate'', AffiliateID IN (56662,56663) -> ''Direct''. Common values: Direct, SEM, SEO, Affiliate, Mobile Acquisition, Friend Referral, Media Programmatic, TV, Social Organic. (Tier 2 - SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN SubChannel COMMENT 'Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: ''Google Brand'', ''Google Search'', ''FB'', ''Taboola'', ''Twitter'', ''Outbrain'', ''Bing Search'', ''Direct'', ''SEO'', ''Affiliate'', ''IBs''. Derived via parallel CASE expression alongside SubChannelID. (Tier 2 - SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN `Organic/Paid` COMMENT 'Binary marketing spend classification. ''Organic'' for channels Friend Referral, Direct, SEO, and Google Brand. ''Paid'' for all others. Computed in SP_Dim_Channel (second ETL step). Note: column name contains a slash - requires square brackets in queries. (Tier 2 - SP_Dim_Channel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN InsertDate COMMENT 'ETL metadata: timestamp when this row was first inserted by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. (Tier 2 - SP_Dim_Channel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. Same as InsertDate since table is TRUNCATE+INSERT. (Tier 2 - SP_Dim_Channel)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN SubChannelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN `Organic/Paid` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:27:10 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 14/14 succeeded
-- ====================
