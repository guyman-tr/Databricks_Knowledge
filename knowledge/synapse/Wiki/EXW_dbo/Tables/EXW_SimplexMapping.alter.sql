-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_SimplexMapping
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_SimplexMapping is a staging/reporting table for Simplex-facilitated crypto purchase transactions initiated through the eToro Wallet platform. Simplex was a third-party payment processor that enabled users to buy cryptocurrency using credit/debit cards. Each row represents one payment attempt (whether completed, cancelled, or declined), including the transaction amounts in both fiat and crypto, the funnel stage where the transaction terminated, and enriched card metadata (bank name, BIN country, card type). The table contains 103,356 rows spanning 2019-07-08 to 2022-09-19. Of these: 76% were cancelled, 22% approved, 2% declined, and a small number refunded. BTC dominates (72% of crypto purchases), followed by ETH (14%), LTC (5%), XLM (4%), XRP (3%), and BCH (2%). Fiat currencies are EUR and GBP only. The single `partner` value is "eToro Wallet" (84% populated, 16% empty records from e

