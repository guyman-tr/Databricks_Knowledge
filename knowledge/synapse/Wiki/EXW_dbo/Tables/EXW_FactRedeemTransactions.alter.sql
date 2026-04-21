-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FactRedeemTransactions
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_FactRedeemTransactions is the definitive fact table for crypto redemptions in eToro Wallet. A redemption is the process where a customer converts a trading position (CFD or real) into actual cryptocurrency deposited into their wallet. Each row records one redemption''s blockchain execution: the position redeemed, the crypto amount sent, fees charged, and the confirmation that the crypto arrived in the customer''s wallet. With 1.13 million rows spanning 2018-10-09 to 2026-04-19, the table covers 149,817 distinct users across 57 cryptocurrency types. XRP is the most redeemed asset (41%), followed by BTC (23%) and ETH (12.6%). The ETL SP runs daily for `@d`, processing new redemptions where `BeginDate = @d`. A re-run mechanism catches positions where `FinalRedeemStatus = ''Completed''` but `ReceivedTransactionID` is NULL (received transaction not yet confirmed at time of initial insert)

