-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_RedeemReconciliation
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_RedeemReconciliation is the primary reconciliation table for crypto redemption events. A redemption is the reverse of a deposit: a customer converts a trading position back into cryptocurrency, which is then sent to their external wallet address. This table reconciles two independent systems that must agree for a successful redemption: - **eToro platform side** (`etoro - *` columns): The billing and trading system records — what the platform requested, approved, and expected - **Wallet/blockchain side** (`Wallet - *` columns): The actual blockchain execution — what was sent to the blockchain and what the destination wallet received The `EntryAppears` column classifies each row as `BothSidesEntry` (both systems have matching records), `OnlyEtoroSideEntry` (eToro has a record but no blockchain send exists — typically early-stage or non-blockchain redeems), or `NoUserReceiveEntry` (bloc

