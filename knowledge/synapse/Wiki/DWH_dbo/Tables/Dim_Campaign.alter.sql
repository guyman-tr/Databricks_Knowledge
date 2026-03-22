-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Campaign
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign SET TBLPROPERTIES (
    'comment' = 'Dim_Campaign was designed to be the DWH version of etoro.BackOffice.Campaign -- a marketing bonus campaign registry defining time-bounded promotional campaigns with user caps and bonus pools. Each campaign has a unique Code (the public-facing identifier customers enter at registration), linked BonusTypes, start/end dates, and a MaxBonusAmount cap. **DEAD TABLE STATUS**: The INSERT statement in SP_Dictionaries_DL_To_Synapse is entirely commented out (lines 1093-1118). The SP daily runs `TRUNCATE TABLE Dim_Campaign` followed by an active INSERT of only the ID=0 placeholder row. No actual campaign data is loaded. The table always contains exactly 1 row. The production BackOffice.Campaign has 11,080 campaigns (no new campaigns since May 2017 -- the system appears frozen or superseded by an external campaign management system). None of these are accessible in DWH. Two columns have Dynamic Data Masking applied in the DWH DDL: - `ParticipatedUsers`: `MASKED WITH (FUNCTION = ''default()'')` - returns 0 for non-privi...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN CampaignID COMMENT 'Primary key. Auto-incrementing campaign identifier in production. PK NOT ENFORCED in DWH. Currently only ID=0 (N/A placeholder) exists. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN CampaignGroupID COMMENT 'Campaign group for organization/reporting. FK to BackOffice.CampaignGroup in production. NULL for 30.5% of production campaigns (ungrouped). (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN Code COMMENT 'Unique public-facing campaign code (e.g., "20coupon", "freecopyref"). The identifier customers enter at registration. UNIQUE in production. Currently only ''N/A'' (ID=0 placeholder). (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN MaxNumberOfUsers COMMENT 'Maximum number of customers who can use this campaign. Range in production: 0 to 100,000,000. 0 in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN StartDate COMMENT 'Campaign activation datetime (UTC). ''1900-01-01'' in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN EndDate COMMENT 'Campaign expiry datetime (UTC). Must be after StartDate. IsActive is NOT auto-set to 0 when EndDate passes in production. ''1900-01-01'' in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN MaxBonusAmount COMMENT 'Maximum total bonus pool in dollars. Range in production: $0 to $15,000,000. 0 in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN IsActive COMMENT 'Whether campaign is active. 1=active, 0=inactive. False in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN ParticipatedUsers COMMENT 'Count of customers who used this campaign. MASKED WITH default() - non-privileged users see 0. 0 in placeholder row. (Tier 1 - upstream wiki, BackOffice.Campaign)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN InsertDate COMMENT 'ETL load date. For ID=0 placeholder: set to @ddate (CAST(GETDATE() AS DATE) = midnight). Would be GETDATE() for live rows if INSERT were active. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN UpdateDate COMMENT 'ETL load date. For ID=0 placeholder: set to @ddate (CAST(GETDATE() AS DATE) = midnight). Would be GETDATE() for live rows if INSERT were active. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN CampaignGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN Code SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN MaxNumberOfUsers SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN StartDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN EndDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN MaxBonusAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN ParticipatedUsers SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
