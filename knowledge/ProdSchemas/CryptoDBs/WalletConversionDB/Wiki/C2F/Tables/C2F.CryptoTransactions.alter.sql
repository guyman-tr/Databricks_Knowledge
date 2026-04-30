-- =============================================================================
-- Databricks ALTER Script: bronze WalletConversionDB.C2F.CryptoTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions SET TBLPROPERTIES (
    'comment' = 'Records the blockchain-side transaction for each crypto-to-fiat conversion, capturing the on-chain transaction hash, destination address, amount, and network fee as proof of the crypto sell operation. Source: WalletConversionDB.C2F.CryptoTransactions on the WalletConversionDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md).'
);

ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletConversionDB',
    'source_schema' = 'C2F',
    'source_table' = 'CryptoTransactions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN ConversionId COMMENT 'FK to C2F.Conversions.Id. Links the blockchain transaction to its parent conversion. One crypto transaction per conversion (when present). (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN BlockchainTransactionId COMMENT 'On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution. (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN ToAddress COMMENT 'Destination blockchain address where crypto was sent. May include chain-specific qualifiers (Ripple destination tags as "?dt=..."). Repeated addresses across transactions suggest omnibus wallet patterns. (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN Amount COMMENT 'Quantity of cryptocurrency transferred on-chain. Matches or closely tracks C2F.Conversions.CryptoAmount for the same conversion. (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN BlockchainFee COMMENT 'Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount. (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions ALTER COLUMN Occurred COMMENT 'UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets. (Tier 1 - upstream wiki, WalletConversionDB.C2F.CryptoTransactions)';

