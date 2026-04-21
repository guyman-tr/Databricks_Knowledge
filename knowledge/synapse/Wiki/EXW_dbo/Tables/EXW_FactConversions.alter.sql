-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FactConversions
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_FactConversions records every crypto-to-crypto swap executed in the eToro Wallet platform from October 2018 through June 2023. Each row represents a single conversion where a wallet user exchanged one cryptocurrency for another within their own wallet — for example, selling 0.01 BTC to receive 3,022 XLM. The table denormalizes data from five sources into a flat analytical record per conversion: the core swap intent (WalletDB.Wallet.Conversions), the per-leg transaction details (Wallet.ConversionTransactions), the final settlement status (Wallet.ConversionStatuses), crypto names (CryptoTypes), and the user''s GCID (CustomerWalletsView). The 50,298 conversions involve 19,722 distinct GCIDs. Cryptos used as "FROM" side are dominated by ETH (34%), BTC (15%), and XRP (15%). Target cryptos ("TO" side) are led by BTC (36%), ETH (17%), and XRP (11%). Tokenized fiat assets (USDEX=102, EURX=10

