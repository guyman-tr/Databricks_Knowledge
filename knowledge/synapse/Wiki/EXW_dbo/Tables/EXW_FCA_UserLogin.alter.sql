-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FCA_UserLogin
-- UC Target: _Not_Migrated
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_FCA_UserLogin is the wallet-scoped login event table. It contains one row per login event (ActionTypeID=14 in Fact_CustomerAction) for users who are active wallet holders (present in EXW_Wallet.CustomerWalletsView). The table provides the same login data as the full DWH Fact_CustomerAction for login events, but restricted to the ~700K EXW wallet user population. Each row records when a wallet user logged in, their IP address, session identifier, proxy/anonymization status, and the platform they logged in from. This is the primary data source for FCA (Financial Conduct Authority) regulatory reporting on wallet user login patterns and geographic access. Despite the "FCA" in the table name, the table is not restricted to FCA-regulated users — it contains all wallet users'' login events. The FCA naming reflects the original reporting scope when the table was created.

