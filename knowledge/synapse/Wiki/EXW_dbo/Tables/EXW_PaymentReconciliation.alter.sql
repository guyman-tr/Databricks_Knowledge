-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_PaymentReconciliation
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_PaymentReconciliation is the definitive cross-source reconciliation record for Simplex fiat-to-crypto payments on the eToro Wallet platform. Unlike EXW_FactPayments (which stores one row per payment × status event — 553K rows), this table stores **one row per payment at its final status**, making it the go-to table for payment-level analysis and financial reconciliation. The table spans three data sources: 1. **WalletDB** (always present) — 16 T1 columns from Wallet.Payments, PaymentTransactions, and PaymentStatuses; same columns as EXW_FactPayments 2. **EXW_SimplexMapping** (LEFT JOIN via UTI/CorrelationID) — 5 Simplex-sourced columns; populated for 38,044 of 99,243 payments (38%) — those that reached the Simplex API layer 3. **EXW_ECPBank** (LEFT JOIN via UTI) — 9 ECP Bank settlement columns; populated for 20,944 payments (21%) — those that were settled by the ECP Bank acquirer The

