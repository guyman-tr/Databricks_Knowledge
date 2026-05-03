-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.ProviderUnitConversionRatio
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_providerunitconversionratio
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_providerunitconversionratio (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_providerunitconversionratio SET TBLPROPERTIES (
    'comment' = 'Per-provider, per-instrument unit and lot size conversion table translating eToro''s internal unit denomination to a liquidity provider''s native order quantity system. The central reference for order size translation in the hedge engine. Source: etoro.Hedge.ProviderUnitConversionRatio on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_providerunitconversionratio SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'ProviderUnitConversionRatio',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_providerunitconversionratio ALTER COLUMN LiquidityProviderID COMMENT 'FK to Trade.LiquidityProviderType(LiquidityProviderTypeID). Named "LiquidityProviderID" but references the provider type table. Part of composite PK. 10 distinct providers configured. (Tier 1 - upstream wiki, etoro.Hedge.ProviderUnitConversionRatio)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_providerunitconversionratio ALTER COLUMN InstrumentID COMMENT 'The instrument this ratio applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint in DDL). 5,215 distinct instruments. (Tier 1 - upstream wiki, etoro.Hedge.ProviderUnitConversionRatio)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_providerunitconversionratio ALTER COLUMN UnitConversionRatio COMMENT 'Multiplier converting eToro internal units to provider-native order quantity. providerQty = eToroUnits * UnitConversionRatio. Range 0.001-10,000 in current data. ISNULL defaults to 1.0 in GetProviderUnitConversion. (Tier 1 - upstream wiki, etoro.Hedge.ProviderUnitConversionRatio)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_providerunitconversionratio ALTER COLUMN LotSize COMMENT 'Standard lot size for this provider/instrument, used for lot-boundary rounding. DEFAULT 1 = no lot rounding. Range 0.00001-3,000. ISNULL defaults to 1000 (Forex) or 1 (other) in GetProviderUnitConversion. Not tracked by ASM audit triggers. (Tier 1 - upstream wiki, etoro.Hedge.ProviderUnitConversionRatio)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
