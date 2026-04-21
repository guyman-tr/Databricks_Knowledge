-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_ReimbursementFollowUp
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_ReimbursementFollowUp is the primary operational tracking table for the eToro Wallet reimbursement program. It stores one row per GCID × CryptoId combination for every user who appears in EXW_CompensationClosingCountries with a non-zero compensation balance. Each row captures a complete snapshot of the compensation event alongside the user''s current state, enabling finance and compliance teams to: - Track whether compensated users have since changed country or regulation - Monitor residual wallet balances after the compensation date - Reconcile platform-side credits (Fact_CustomerAction) against wallet-side reimbursement records - Identify users where the wallet balance differs from what was compensated - Track actual crypto extractions (withdrawals) post-compensation The table is rebuilt on every on-demand SP run by TRUNCATE + INSERT, meaning it reflects the state as of the most re

