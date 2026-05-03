-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PhoneVerificationRiskLevel
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerificationRiskLevel.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_phoneverificationrisklevel
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_phoneverificationrisklevel (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationrisklevel SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 8 risk levels from phone verification providers - ranging from None (0) through Low/Medium/High to a catch-all Other (MaxInt) - used in KYC risk scoring. Source: etoro.Dictionary.PhoneVerificationRiskLevel on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerificationRiskLevel.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationrisklevel SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PhoneVerificationRiskLevel',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationrisklevel ALTER COLUMN RiskLevelID COMMENT 'Primary key identifying the risk level. 0=None, 1=Low, 2=MediumLow, 3=Medium, 4=MediumHigh, 5=High, 6=Neutral, 2147483647=Other. Stored in Customer.PhoneVerificationDetails. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerificationRiskLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationrisklevel ALTER COLUMN RiskLevel COMMENT 'Human-readable risk level label. Used in risk scoring displays, compliance reports, and verification dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerificationRiskLevel)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
