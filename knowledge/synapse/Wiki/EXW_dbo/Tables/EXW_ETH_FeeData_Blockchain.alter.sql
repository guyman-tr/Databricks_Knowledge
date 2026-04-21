-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_ETH_FeeData_Blockchain
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_ETH_FeeData_Blockchain is the raw Ethereum blockchain fee ledger for eToro''s ETH hot wallet. It tracks every on-chain ETH transaction in which the eToro multi-sig wallet (`from = 0x8c4b7870fc7dff2cb1e854858533ceddaf3eebf4`) participated — including wallet creations, user send-outs, multi-sig token transfers, and forwarder flushes. The data is manually exported from Etherscan and loaded into Synapse via a Google Sheet maintained by the analytics team (Fivetran-synced). The table has 402,288 rows covering 2022-01-01 to 2024-09-09. Key characteristics: - **All fee and value columns are nvarchar** — Etherscan exports numeric data as strings, which persists through the Fivetran → Google Sheet pipeline. SP_EXW_EthFeeSent_Blockchain applies a 2-step `CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY)` to convert fees for use. - The `method` field (added 2022-03-22) is NULL for 191,869 rows (47%) — 

