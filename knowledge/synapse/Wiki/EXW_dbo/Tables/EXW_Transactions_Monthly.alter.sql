-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_Transactions_Monthly
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_Transactions_Monthly was the historical monthly aggregation of wallet transaction activity per GCID×CryptoId×WalletId, providing end-of-month summaries of sent amounts, received amounts, and fees for each wallet. With 50.1M rows across 489,135 unique users and 69 months (Apr 2018 – Dec 2023), it served as a pre-aggregated source for monthly financial reporting. The table is frozen. SP_EXW_Transactions_Monthly(@d date) exists in the SSDT repository but its operational logic is entirely wrapped in a comment block — the SP is a NO-OP. The last data write was 2024-01-01 (covering the December 2023 EOM date). No equivalent replacement has been identified in the current EXW_dbo schema. **For current monthly analysis**, analysts should aggregate directly from EXW_FactTransactions using the External_WalletDB_Wallet_TransactionsView as the source, or use EXW_30DayBalanceExtract for rolling re

