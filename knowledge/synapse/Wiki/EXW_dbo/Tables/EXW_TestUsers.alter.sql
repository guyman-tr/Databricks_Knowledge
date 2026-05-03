-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_TestUsers
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- This table is a curated allowlist of test and internal users operating in the eToro Wallet (EXW) environment. It is maintained automatically by SP_EXW_TestUsers, which queries DWH_dbo.Dim_Customer and filters to accounts that match known test-user patterns (username substrings like `redeemprod`, `betatester`, `walletprod`, `internalprod`, `nowalletprod`), specific named individuals, or Beta tester accounts (email LIKE %test@test.com% with PlayerLevelID=4). The table holds 958 rows as of the last refresh (March 2026), spanning users inserted from 2020 onwards. Its primary consumer is SP_DimUser, which LEFT JOINs on GCID to mark users as test accounts within EXW_DimUser. This ensures that analytics built on EXW_DimUser can easily exclude test traffic from production metrics. The SP uses an UPSERT pattern: it inserts new test users discovered in Dim_Customer, updates existing rows when User

