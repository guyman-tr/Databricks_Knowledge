-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_UserCalculatedBalance
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_UserCalculatedBalance was the historical daily balance ledger for every wallet user - computing each GCID''s crypto balance on each date as the sum of all received amounts minus all sent amounts from account inception to that date. With 1.27 billion rows, it was the largest EXW_dbo balance table by row count, providing a full daily time series of wallet balances from December 2019 through December 2023. The table is frozen. SP_EXW_UserCalculatedBalance(@d date) exists in the SSDT repository but its operational logic is entirely wrapped in a comment block - the SP is a NO-OP. The last data write was 2024-01-01 (covering the 2023-12-31 balance date). **Balance computation method** (archived, from SP comments): Balance = ReceivedAmount - SentAmount - XRP_reserve, where XRP_reserve = 0.0225 for CryptoId=4 (XRP) and 0 for all other cryptos. This is a cumulative lifetime calculation - not 

