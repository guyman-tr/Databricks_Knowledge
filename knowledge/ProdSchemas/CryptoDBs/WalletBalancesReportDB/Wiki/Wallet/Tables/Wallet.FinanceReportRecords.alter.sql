-- =============================================================================
-- Databricks ALTER Script: bronze WalletBalancesReportDB.Wallet.FinanceReportRecords
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords (business_group=wallet) ----
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords SET TBLPROPERTIES (
    'comment' = 'Primary table storing individual wallet-crypto reconciliation results for the current reconciliation system, linking each balance comparison outcome to its parent run. Source: WalletBalancesReportDB.Wallet.FinanceReportRecords on the WalletBalancesReportDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md).'
);

ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletBalancesReportDB',
    'source_schema' = 'Wallet',
    'source_table' = 'FinanceReportRecords',
    'business_group' = 'wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. Part of unique index IX_FinanceReportRecords__ReportId_WalletId_CryptoId for efficient lookups. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN ReportId COMMENT 'FK to Wallet.FinanceReportRuns.Id identifying which reconciliation run produced this record. Constraint: FK__FinanceReportRecords__ReportId. Indexed in composite with LevelId and with WalletId+CryptoId. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN WalletId COMMENT 'Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). Used in CROSS APPLY joins by CreateNewReportRun and GetFinanceSnapshot to correlate with external table data. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN Gcid COMMENT 'Global Customer ID -- identifies the wallet owner. Carried from the external table for denormalized customer-level querying without joining back to WalletDB. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN CryptoId COMMENT 'Cryptocurrency asset identifier. Completes the composite business key. Same CryptoId may appear multiple times per run if a customer has multiple wallets for the same crypto. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN Address COMMENT 'Blockchain address associated with this wallet-crypto pair. Passed through from the external table for traceability during discrepancy investigation. NULL for wallets without dedicated on-chain addresses. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN BitgoWalletId COMMENT 'BitGo custody platform''s wallet identifier. Enables cross-referencing with BitGo''s API for discrepancy investigation. Aliased as ProviderWalletId in GetFinanceReportRunDiscrepancies output. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN BloxAccountId COMMENT 'Blox portfolio tracker''s account identifier. Always NULL in production data -- the current reconciliation system (CreateNewReportRun) does not populate this field, suggesting Blox account mapping was deprecated or moved to the application layer. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN TotalReceive COMMENT 'Total amount received into this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalRecive (note: mapped from the misspelled column). Represents the cumulative incoming blockchain transactions. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN TotalSend COMMENT 'Total amount sent from this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalSend. Represents the cumulative outgoing blockchain transactions. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN BloxBalance COMMENT 'Blockchain-reported net balance (TotalReceive - TotalSend). Despite the name suggesting "Blox balance," this is actually the blockchain/computed balance from the external table''s TotalBalance column. The naming reflects the legacy system where Blox was the primary comparison source. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN ComputedAmount COMMENT 'Internally computed expected balance from eToro''s ledger system. Sourced from vu_GetWalletBalanceReport.TotalAmount. The reconciliation threshold check compares this against BloxBalance: ABS(ComputedAmount - BloxBalance) > @Threshold. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN FindDiscrepancy COMMENT 'Whether the final reconciliation result found a balance mismatch: 0 = no discrepancy (or not yet verified), 1 = confirmed discrepancy. Initially set to 0 by CreateNewReportRun; updated to 1 by UpdateReportRecords when verification confirms a mismatch. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN BitgoValue COMMENT 'Balance amount reported by BitGo custody provider during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual BitGo API response. NULL/0 until the verification phase processes this record. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN BloxValue COMMENT 'Balance amount reported by Blox portfolio tracker during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual Blox API response. NULL/0 until verification. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN ErrorMsg COMMENT 'Error message from the reconciliation verification phase. Contains API error details from BitGo or Blox when their endpoints fail. NULL when verification completes successfully. Set by UpdateReportRecords via the BalanceType TVP. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN LevelId COMMENT 'FK to Dictionary.FinanceReportLevel classifying the reconciliation outcome. Initially set to 100 (InitialDiscrepancy) if balance exceeds threshold, NULL otherwise. Refined by UpdateReportRecords: 1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, 5-11=API errors, 12=InternalError. See Finance Report Level. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN Created COMMENT 'UTC timestamp when this record was inserted by CreateNewReportRun. Default constraint DF_FinanceReportRecords_Created. Indexed in ix_FinanceReportRecords__WalletId_CryptoId_Created (DESC) for efficient "latest record per wallet" lookups used by CreateNewReportRun''s incremental processing. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN LastChecked COMMENT 'UTC timestamp of the most recent verification check for this record. NULL until the record is processed by UpdateReportRecords, which sets it to GETUTCDATE(). Used by CreateNewReportRun''s incremental logic: DATEDIFF(DAY, ISNULL(LastChecked, ''2000-01-01''), GETUTCDATE()) >= @RetryDays to determine if the record should be rechecked. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords ALTER COLUMN Retries COMMENT 'Number of times this wallet-crypto pair has been re-verified. Set by UpdateReportRecords via the BalanceType TVP. NULL on initial creation; 0+ after verification. Used to track persistent discrepancies that don''t resolve after multiple attempts. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRecords)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:39:29 UTC
-- Bronze deploy: WalletBalancesReportDB batch 1
-- ====================
