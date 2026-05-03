-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskClassificationRegulation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassificationRegulation.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_riskclassificationregulation
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_riskclassificationregulation (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationregulation SET TBLPROPERTIES (
    'comment' = 'Configuration table mapping regulation entities to risk score thresholds with classification labels - currently empty in production, with structure for per-regulation risk bucketing. Source: etoro.Dictionary.RiskClassificationRegulation on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassificationRegulation.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationregulation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskClassificationRegulation',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationregulation ALTER COLUMN RegulationID COMMENT 'Part of composite PK. References Dictionary.Regulation (implicit). Identifies the regulatory authority. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationRegulation)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationregulation ALTER COLUMN RiskScore COMMENT 'Part of composite PK. The numeric risk score threshold. Combined with RegulationID to form unique classification boundaries. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationRegulation)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationregulation ALTER COLUMN Name COMMENT 'Risk classification label for this regulation+score combination (e.g., "Low", "Medium", "High"). (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationRegulation)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
