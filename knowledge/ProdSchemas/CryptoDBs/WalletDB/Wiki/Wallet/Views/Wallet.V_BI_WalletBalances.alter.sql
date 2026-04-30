-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.V_BI_WalletBalances
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.V_BI_WalletBalances.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances SET TBLPROPERTIES (
    'comment' = 'BI-facing view over Wallet.WalletBalances that returns balance snapshots within a rolling 20-day window, providing the business intelligence team with recent balance history without exposing the full multi-million-row base table. Source: WalletDB.Wallet.V_BI_WalletBalances on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 120-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.V_BI_WalletBalances.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'V_BI_WalletBalances',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '120'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key from the base WalletBalances table. Not used as FK - the business key is (WalletId, CryptoId, DateTo). From Wallet.WalletBalances.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN WalletId COMMENT 'The wallet this balance belongs to. Implicit reference to Wallet.WalletPool.WalletId. From Wallet.WalletBalances.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN CryptoId COMMENT 'The cryptocurrency this balance measures. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId and DateTo for unique identification. From Wallet.WalletBalances.CryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN DateFrom COMMENT 'Start of this balance snapshot''s validity window. Set to the time the balance was confirmed by the blockchain provider. Filtered by DateFrom < GETDATE() in the view. From Wallet.WalletBalances.DateFrom. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN DateTo COMMENT 'End of this balance snapshot''s validity window. 3000-01-01 = current/open balance. Updated to the next snapshot''s DateFrom when a new balance is recorded. Filtered by DateTo >= 20 days ago in the view. From Wallet.WalletBalances.DateTo. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN Balance COMMENT 'The confirmed crypto balance in native units (e.g., BTC, ETH). NULL is possible but rare - indicates balance could not be determined. Uses high-precision decimal for sub-unit accuracy across all crypto types. From Wallet.WalletBalances.Balance. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_v_bi_walletbalances ALTER COLUMN Occurred COMMENT 'Timestamp when this balance record was created/updated in the database. May differ from DateFrom if there was processing delay between provider confirmation and DB write. From Wallet.WalletBalances.Occurred. (Tier 1 - upstream wiki, WalletDB.Wallet.V_BI_WalletBalances)';

