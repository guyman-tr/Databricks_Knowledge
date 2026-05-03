-- =============================================================================
-- Databricks ALTER Script: bronze WalletBalancesReportDB.Wallet.FinanceReportsBalances
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances SET TBLPROPERTIES (
    'comment' = 'Partitioned table storing wallet-crypto balance reconciliation results for the legacy reconciliation system, with date-based partitioning on the Occurred column for historical data management. Source: WalletBalancesReportDB.Wallet.FinanceReportsBalances on the WalletBalancesReportDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md).'
);

ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletBalancesReportDB',
    'source_schema' = 'Wallet',
    'source_table' = 'FinanceReportsBalances',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key. Part of the composite PK (ReportId, Id, Occurred) to support the partitioning scheme. Sequence reaches ~1.8 billion, reflecting the massive volume of reconciliation data over 5+ years. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN ReportId COMMENT 'Implicit FK to Wallet.FinanceReports.Id identifying the parent run. No explicit FK constraint exists (partitioning prevents FK on non-partition-aligned columns). Indexed in composite with LevelId and with WalletId+CryptoId. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN WalletId COMMENT 'Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN Gcid COMMENT 'Global Customer ID -- identifies the wallet owner. Denormalized from the external table for efficient customer-level querying. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN CryptoId COMMENT 'Cryptocurrency asset identifier. Completes the composite business key. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN Address COMMENT 'Blockchain address for this wallet-crypto pair. Passed through from the external table for traceability. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN BitgoWalletId COMMENT 'BitGo custody platform''s wallet identifier for cross-referencing during discrepancy investigation. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN BloxAccountId COMMENT 'Blox portfolio tracker''s account identifier. Appears unused in production (always NULL in sampled data). (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN TotalReceive COMMENT 'Total received amount for this wallet-crypto pair from blockchain data. Sourced from vu_GetWalletBalanceReport.TotalRecive. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN TotalSend COMMENT 'Total sent amount for this wallet-crypto pair from blockchain data. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN BloxBalance COMMENT 'Blockchain-reported net balance. Despite the name, this is the blockchain balance (TotalReceive - TotalSend), not the Blox provider balance. Legacy naming. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN ComputedAmount COMMENT 'eToro ledger''s computed expected balance. Compared against BloxBalance: ABS(ComputedAmount - BloxBalance) > @Threshold for discrepancy detection. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN FindDiscrepancy COMMENT 'Whether reconciliation found a balance mismatch: 0=no discrepancy (or not yet verified), 1=confirmed discrepancy. Initially 0; updated by UpdateReportRecord. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN BitgoValue COMMENT 'BitGo custody provider''s actual balance from the verification phase. Initially 0; updated by UpdateReportRecord via BalanceType TVP. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN BloxValue COMMENT 'Blox portfolio tracker''s actual balance from the verification phase. Initially 0; updated by UpdateReportRecord via BalanceType TVP. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN ErrorMsg COMMENT 'Error message from reconciliation verification. Contains API error details. NULL when successful. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN LevelId COMMENT 'Classification of the reconciliation outcome. Implicit reference to Dictionary.FinanceReportLevel (no explicit FK due to partitioning). See Finance Report Level. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN Occurred COMMENT 'UTC timestamp when this record was created. Partition column for DatesToFilegroup. Default constraint DF_FinanceReportsBalances_Occurred. Equivalent to FinanceReportRecords.Created. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances ALTER COLUMN Retries COMMENT 'Number of verification re-attempts. Set via the BalanceType TVP. NULL on initial creation. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportsBalances)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:39:29 UTC
-- Bronze deploy: WalletBalancesReportDB batch 1
-- ====================
