-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CountryIP
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip SET TBLPROPERTIES (
    'comment' = '`Dim_CountryIP` is a 6.8-million-row IP geolocation range table. Each row maps a contiguous range of IPv4 addresses (stored as bigint integers) to a DWH CountryID and optionally a sub-national RegionID. When a customer connects to eToro, their IP address is converted to an integer and matched against this table via a range lookup (`WHERE @IPInteger BETWEEN IPFrom AND IPTo`) to determine their geographic location. This geolocation data drives: auto-detection of registration country (pre-filling the registration form), fraud detection (validating IP location matches expected patterns), and risk scoring context. In production, this is served by `Internal.GetCountryIDByIP` / `Internal.GetCountryNameByIP` / `Internal.GetRegionIDByIP` functions. The ETL is a full TRUNCATE+INSERT daily reload from `DWH_staging.etoro_Dictionary_CountryIP`. All 4 source columns are passthroughs; only UpdateDate is ETL-computed. Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryIP.md`. Synapse: REPLICATE, CLUS...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (IPFrom ASC, IPTo ASC, CountryID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN CountryID COMMENT 'FK to DWH_dbo.Dim_Country. Identifies which country owns this IP range. Part of the clustered index. (Tier 1 - Dictionary.CountryIP upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN IPFrom COMMENT 'Start of the IP address range as an integer (IPv4: octet1*16777216 + octet2*65536 + octet3*256 + octet4). Part of the clustered index. Used with IPTo for BETWEEN lookups. (Tier 1 - Dictionary.CountryIP upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN IPTo COMMENT 'End of the IP address range as an integer. When IPFrom = IPTo the range covers exactly one IP address. Part of the clustered index. (Tier 1 - Dictionary.CountryIP upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN RegionID COMMENT 'Sub-national region ID within the country. Provides geographic granularity below country level (e.g., state, province). NULL when regional data is not available for this IP range. References an internal region lookup (not directly a DWH dimension). (Tier 2 - SP passthrough; CODE-BACKED in upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily full reload via SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN IPFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN IPTo SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN RegionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:16:42 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 12/12 succeeded
-- ====================
