-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_TransactionCategory
-- UC Target: `_Not_Migrated` (static reference — no Generic Pipeline export)
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- `eMoney_Dictionary_TransactionCategory` is a 5-row static lookup table that classifies fiat platform transactions into mutually exclusive high-level categories. Each row maps an integer category identifier to a human-readable category name. The values enumerate the four distinct transaction flow types used in the eToro Money fiat platform — card payments, banking (IBAN/bank transfer), transfers between accounts, and balance adjustments — plus an Unknown sentinel. The table was loaded on 2023-06-12 as a direct mirror of `FiatDwhDB.Dictionary.TransactionCategories` and has never been updated (all 5 rows share the same UpdateDate). It is effectively a compile-time constant — the category codes are embedded in the production fiat platform schema and are unlikely to change. The table is NOT directly joined by any current ETL stored procedure in eMoney_dbo (SP_eMoney_DimFact_Transaction instea

