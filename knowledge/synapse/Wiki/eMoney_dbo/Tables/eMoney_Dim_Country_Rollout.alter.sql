-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dim_Country_Rollout
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout SET TBLPROPERTIES (
    'comment' = '`eMoney_Dim_Country_Rollout` is the authoritative reference table for the eToro Money (eMoney) geographic rollout: it lists every country that has gone live on the platform and the date it did so. As of 2026-04-12 there are **34 rows** covering rollouts from 2020-11-01 (United Kingdom, the first market) through 2025-10-15 (Australia, the most recent addition). The table is replicated across all Synapse distributions and refreshed daily. Downstream SPs - including the Acquisition Funnel, Card Monthly Snapshot, and AM Target reports - JOIN to this table to determine which customers are in active eToro Money markets. Only countries whose rollout date has already passed appear in the table; future rollout dates coded in the SP are suppressed until that date arrives. Key business facts: - 34 active countries across 9 regions and 7 sales desks - UK launched first (2020-11-01); Australia joined latest (2025-10-15) - Countries are filtered by `IsCountryOpen = CASE WHEN RolloutDate <= GETDATE()` - future rollouts a...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `CountryID` COMMENT 'eToro internal country identifier. Passthrough from DWH_dbo.Dim_Country.CountryID. Filtered by SP to 34 eMoney-eligible countries. FK usage: JOIN to DWH_dbo.Dim_Customer.CountryID. (Tier 4 - DWH_dbo.Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `CountryName` COMMENT 'Country display name. Sourced from DWH_dbo.Dim_Country.Name (renamed CountryName by SP). Examples: United Kingdom, Cyprus, Ireland, Romania. (Tier 4 - DWH_dbo.Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `RolloutDate` COMMENT 'Official launch date when eToro Money became available in this country. Hardcoded in SP_eMoney_Dim_Country_Rollout as a CASE expression per CountryID (34 entries). UK first at 2020-11-01, Australia most recent at 2025-10-15. Only dates <= today are present. (Tier 2 - SP_eMoney_Dim_Country_Rollout)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `RolloutDateID` COMMENT 'Integer YYYYMMDD encoding of RolloutDate. Computed as CAST(CONVERT(VARCHAR(8), RolloutDate, 112) AS INT). Used for joining to DWH_dbo.Dim_Date. Example: 2020-11-01 -> 20201101. (Tier 2 - SP_eMoney_Dim_Country_Rollout)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `Region` COMMENT 'Broad geographic grouping. 9 values: UK, French, Spanish, Italian, Eastern Europe, North Europe, German, ROE, Australia. Passthrough from DWH_dbo.Dim_Country.Region. (Tier 4 - DWH_dbo.Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `Desk` COMMENT 'Sales desk responsible for the country. 7 values: UK, French, Spanish, Italian, Other EU, German, Australia. Eastern Europe, North Europe, and ROE regions all map to "Other EU" desk. Passthrough from DWH_dbo.Dim_Country.Desk. (Tier 4 - DWH_dbo.Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of the most recent SP execution. Set to GETDATE() at insert time; all 34 rows share the same value per refresh. Last observed: 2026-04-12 06:24:35. (Tier 2 - SP_eMoney_Dim_Country_Rollout)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `CountryName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `RolloutDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `RolloutDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `Region` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `Desk` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:20:49 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 10
-- Statements: 16/16 succeeded
-- ====================
