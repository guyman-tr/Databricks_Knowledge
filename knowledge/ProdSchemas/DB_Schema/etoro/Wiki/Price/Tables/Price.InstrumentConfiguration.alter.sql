-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.InstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.InstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_price_instrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_price_instrumentconfiguration (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-instrument spread and skew control thresholds for the pricing engine - defines when bid/ask spreads trigger alerts (SpreadAlertThresholdPercentage), when they cause a trading lock (SpreadLockThresholdPercentage), the maximum allowed skew magnitude (SkewLimitThreshold), and eToro''s maximum spread enforcement cap (EtoroMaxSpreadPercentage). Source: etoro.Price.InstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.InstrumentConfiguration.md).'
);

ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'InstrumentConfiguration',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. CLUSTERED PK. FK to Trade.Instrument. One row per instrument. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN SpreadAlertThresholdPercentage COMMENT 'Alert threshold: when the bid/ask spread as a percentage of mid price exceeds this value, the pricing engine generates an alert. Does not halt trading. Expressed as a percentage (e.g., 0.0719 = 0.0719%). decimal(10,6) provides sub-pip precision for tight FX spreads. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN SpreadLockThresholdPercentage COMMENT 'Lock threshold: when spread% exceeds this value, new position openings are rejected for this instrument until the spread normalizes. NULL = no lock threshold (alert-only mode). Typically 2-6x the alert threshold. decimal(12,5) has slightly different precision from the alert threshold - supports wider spread values for volatile instruments. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN SkewLimitThreshold COMMENT 'Maximum skew magnitude cap in price units. DEFAULT=0 means no cap. When > 0: the skew algorithm''s output (from Price.BuyRatioThresholds) is capped at this value before being applied. Prevents extreme client-side imbalances from causing disproportionate price distortions. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN EtoroMaxSpreadPercentage COMMENT 'eToro''s maximum spread policy cap as a percentage. DEFAULT=0 means no cap enforced. When > 0: if the external feed spread exceeds this value, the pricing engine adjusts bid/ask to enforce the cap. Represents eToro''s commercial commitment to maximum spread on this instrument. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed: SQL Server login of last row modifier. Auto-set by SQL Server. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed: application identity from context_info(). Populated when calling service sets context_info before DML. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal row validity start. Auto-managed by system versioning. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
ALTER TABLE main.dealing.bronze_etoro_price_instrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal row validity end. Historical versions in History.InstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Price.InstrumentConfiguration)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
