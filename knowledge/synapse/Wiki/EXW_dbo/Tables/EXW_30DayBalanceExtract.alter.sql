-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_30DayBalanceExtract
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_30DayBalanceExtract is a rolling 30-day window of wallet balances sourced from EXW_FinanceReportsBalancesNew, enriched with geographic and compliance attributes from EXW_DimUser. Each SP run completely replaces the table (TRUNCATE + INSERT) with the last 31 days of balance data. **Key enrichments over EXW_FinanceReportsBalancesNew**: - **Region**: geographic region (not in EXW_FinanceReportsBalancesNew) - **State / StateCode**: US state name and short code (not in EXW_FinanceReportsBalancesNew) - **ComplianceClosureEvent**: compliance closure flag from EXW_DimUser (not in EXW_FinanceReportsBalancesNew) - **RealUser**: derived from IsTestAccount and IsValidCustomer - ''TestUser'', ''eTorian'', or ''RealUser'' **CryptoId/CryptoName** in this table refer to the **blockchain-level** crypto (EXW_Wallet.CryptoTypes.BlockchainCryptoId), not the ERC-level. The original ERC-level values are p

