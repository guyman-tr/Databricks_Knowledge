-- =============================================================================
-- Databricks ALTER Script: bronze WalletConversionDB.C2F.EstimatedFiatTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions SET TBLPROPERTIES (
    'comment' = 'Captures the estimated fiat amounts and exchange rates at the time of conversion creation, serving as the pre-execution price quote before actual rates are locked. Source: WalletConversionDB.C2F.EstimatedFiatTransactions on the WalletConversionDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.EstimatedFiatTransactions.md).'
);

ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletConversionDB',
    'source_schema' = 'C2F',
    'source_table' = 'EstimatedFiatTransactions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN ConversionId COMMENT 'FK to C2F.Conversions.Id. 1:1 relationship - every conversion gets exactly one estimated fiat record. Created atomically by InsertConversion. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN FiatAmount COMMENT 'Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments). (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN UsdAmount COMMENT 'Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN CryptoToUsdRate COMMENT 'Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN FiatToUsdRate COMMENT 'Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN CryptoToFiatRate COMMENT 'Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_estimatedfiattransactions ALTER COLUMN Occurred COMMENT 'UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction. (Tier 1 - upstream wiki, WalletConversionDB.C2F.EstimatedFiatTransactions)';

