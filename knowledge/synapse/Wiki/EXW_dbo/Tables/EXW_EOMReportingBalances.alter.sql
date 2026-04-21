-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_EOMReportingBalances
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_EOMReportingBalances is the historical monthly regulatory balance reporting table for eToro Wallet. It captures a complete snapshot of every customer''s crypto holdings at the end of each month, supporting balance reporting requirements across all applicable jurisdictions. **Business context**: eToro Wallet is subject to regulatory reporting obligations across multiple jurisdictions — CySEC (EU/Cyprus, 546K rows in Sep-2023), FCA (UK, 310K), BVI (105K), ASIC & GAML (81K), FinCEN/FINRA (US, 76K), and others. For each jurisdiction, regulators may require monthly position reports showing each customer''s crypto holdings with opening/closing balances, activity, and USD valuations. **What each row represents**: One customer''s holding of one crypto asset at one month-end date. The same customer appears multiple times — once per crypto asset they hold (131 distinct cryptos across 467,616 d

