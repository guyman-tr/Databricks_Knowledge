-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.PriceDetectionDifferenceLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.PriceDetectionDifferenceLog.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_pricedetectiondifferencelog
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_pricedetectiondifferencelog (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog SET TBLPROPERTIES (
    'comment' = 'High-frequency log of price anomaly detection events, recording each instance where the active price feed diverges from secondary feeds beyond a configured threshold - capturing instrument, provider, price, and severity. Source: etoro.History.PriceDetectionDifferenceLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.PriceDetectionDifferenceLog.md).'
);

ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'PriceDetectionDifferenceLog',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog ALTER COLUMN NotificationLogID COMMENT 'Auto-incrementing PK (NOT FOR REPLICATION). This IDENTITY value is the shared key between this table and History.PriceDetectionNotificationLog - the same ID is inserted into both tables for each price anomaly event. Provides the 1:1 link. (Tier 1 - upstream wiki, etoro.History.PriceDetectionDifferenceLog)';
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog ALTER COLUMN NotificationSeverityTypeID COMMENT 'Severity of the price discrepancy. FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low. Distribution in live data: 44% Critical, 31% High, 25% Medium, <1% Low. Note: the alert SUBJECT in NotificationLog describes the direction (Low/High price) - severity here indicates the magnitude of discrepancy. (Tier 1 - upstream wiki, etoro.History.PriceDetectionDifferenceLog)';
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog ALTER COLUMN InstrumentID COMMENT 'Financial instrument for which the price anomaly was detected. The active feed''s price for this instrument diverged from secondary feeds. Implicit FK to instrument lookup. (Tier 1 - upstream wiki, etoro.History.PriceDetectionDifferenceLog)';
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog ALTER COLUMN ActiveProviderID COMMENT 'ID of the active price feed provider whose price is the outlier. This is the provider currently supplying execution prices for the instrument. Implicit FK to provider lookup. The notification body identifies the provider with descriptive name (e.g., "ProviderARS#21: ZBFX Price1(69)"). (Tier 1 - upstream wiki, etoro.History.PriceDetectionDifferenceLog)';
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog ALTER COLUMN ActiveProviderPrice COMMENT 'The price reported by the active provider at the time the anomaly was detected. This is the price that differs from secondary feeds. Stored as float (not dtPrice) - this is a raw feed price used for detection comparison, not for execution. (Tier 1 - upstream wiki, etoro.History.PriceDetectionDifferenceLog)';
ALTER TABLE main.general.bronze_etoro_history_pricedetectiondifferencelog ALTER COLUMN Occurred COMMENT 'Local server timestamp when the anomaly was logged. DEFAULT getdate() (not UTC). Corresponds to the "Time of check" reported in the notification body. (Tier 1 - upstream wiki, etoro.History.PriceDetectionDifferenceLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
