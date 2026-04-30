-- =============================================================================
-- Databricks ALTER Script: bronze WalletConversionDB.C2F.Conversions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletconversiondb_c2f_conversions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletconversiondb_c2f_conversions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions SET TBLPROPERTIES (
    'comment' = 'Central record of every crypto-to-fiat conversion request, storing the customer, source crypto, target fiat, amount, fee, and correlation identity that links to the saga orchestration. Source: WalletConversionDB.C2F.Conversions on the WalletConversionDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.Conversions.md).'
);

ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletConversionDB',
    'source_schema' = 'C2F',
    'source_table' = 'Conversions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN Gcid COMMENT 'Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum). (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN TargetPlatformId COMMENT 'Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount (77%), 2=EtoroPlatform (6%), 3=EtoroPosition (17%). See Fiat Conversion Target. Determines the downstream routing of fiat proceeds. (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN CryptoId COMMENT 'Crypto asset identifier (external reference). Identifies which cryptocurrency is being sold. Values observed: 4, 64, 107 (likely mapped to assets like BTC, ETH, etc. in an external system). (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN FiatId COMMENT 'Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR). (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN CryptoAmount COMMENT 'Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN ConversionFeePercentage COMMENT 'Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN CorrelationId COMMENT 'Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id. (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversions ALTER COLUMN Occurred COMMENT 'UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter. (Tier 1 - upstream wiki, WalletConversionDB.C2F.Conversions)';

