-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletRegulation
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- This table tracks the regulatory entity that each Wallet user operates under, as determined by their accepted Terms & Conditions (T&C) versions. Different regulatory frameworks govern eToro Wallet operations in different jurisdictions, and users transition between frameworks when they accept updated T&C for a different entity. For each user (GCID) and regulation type (TypeID), the table stores at most two rows: - **IsCurrent=1**: The user''s most recently accepted regulation — FromDate = when they last accepted this type''s T&C; ToDate = ''2999-01-01'' (open-ended) - **IsCurrent=0**: The user''s second-most-recent regulation — ToDate = current.FromDate - 1 day The five regulatory types are: 1=eToroX (main Wallet entity), 2=US, 3=Germany, 4=eToro DA, 5=eToro SEY. eToroX is the dominant regulation with 419,719 current rows. The SP performs a full DELETE of the entire table before INSERT on

