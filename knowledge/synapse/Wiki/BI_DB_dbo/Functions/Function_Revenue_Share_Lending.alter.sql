-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Share_Lending
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Surfaces share-lending compensation actions (`ActionTypeID` 36, `CompensationReasonID` 119) with customer snapshot attributes, splitting the booked `Amount` into eToro share, user share, inferred broker share, and gross using the BNY-style split formula (`round(0.425,1,1)`).

