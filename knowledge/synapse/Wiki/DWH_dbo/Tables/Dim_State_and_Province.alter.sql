-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_State_and_Province
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_State_and_Province` maps IP-based geographic region identifiers to human-readable sub-country labels (states, provinces, territories). When customers register or transact, their IP address is resolved to a country and sub-country region. This dimension bridges the numeric `RegionByIP_ID` (from `Dictionary.RegionByIP`) with the full geographic name from `Dictionary.RegionName`. The table contains 181 rows - a subset of the full `Dictionary.RegionByIP` (4,206 entries). The reduction occurs because the ETL uses an INNER JOIN between `RegionByIP` (indexed by RegionByIP_ID, CountryID, and a short code in Name) and `RegionName` (which stores full ShortName and Name per country). Only regions with a matching `RegionName.ShortName = RegionByIP.Name` for the same country appear in DWH. Source pipeline: SP_Dictionaries_DL_To_Synapse performs TRUNCATE + INSERT with: ```sql SELECT rei.RegionByIP_ID, ren.CountryID, ren.ShortName, ren.Name, GETDATE() FROM etoro_Dictionary_RegionByIP AS rei JOIN etoro_Dictio...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED (implied - see DDL)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN RegionByIP_ID COMMENT 'Primary join key. Auto-incrementing surrogate PK from `Dictionary.RegionByIP` (IDENTITY NOT FOR REPLICATION). Stored in `Customer.CustomerStatic.RegionByIP_ID` and used to identify the sub-country region detected from a customer''s IP address at registration. (Tier 1 - upstream wiki, Dictionary.RegionByIP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN CountryID COMMENT 'Country this region belongs to. FK to `DWH_dbo.Dim_Country.CountryID`. Sourced from `Dictionary.RegionName.CountryID` (the RegionName side of the join). Used for country-level geographic aggregation. (Tier 1 - upstream wiki, Dictionary.RegionByIP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN ShortName COMMENT 'Short alphanumeric region code used by IP geolocation providers. Examples: "CA", "NY", "64". This is the code that matched `Dictionary.RegionByIP.Name` in the ETL join condition. Used for cross-referencing with geolocation provider outputs. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN Name COMMENT 'Full human-readable geographic name of the region - state, province, or territory. Sourced from `Dictionary.RegionName.Name`. Examples: "California", "New York", "Ontario". Used in reporting to display readable geographic labels. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp - use for ETL freshness monitoring only. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN RegionByIP_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN ShortName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
