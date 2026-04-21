-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_AMLProviderID
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- This table is a daily delta log of AML (Anti-Money Laundering) compliance provider submissions for eToro Wallet users. Each row records one GCID (Wallet user) that was submitted to an AML provider (identified by AMLProviderID) on a specific date (DateID), along with the provider''s own identifier for that user (ProviderUserID — a base64-encoded string). The table is populated by SP_EXW_AMLProviderID, which runs daily and processes events from the previous day: it deletes any existing rows for that DateID and re-inserts from EXW_Wallet.AmlProviderUsers filtered to that date''s Occurred range. RealCID is enriched by joining to EXW_DimUser. Three distinct AML providers are active: ID 1 (166,322 rows), ID 3 (27,381 rows), and ID 4 (12,704 rows). The ProviderUserIDNormalized column strips base64 padding (''='') for systems that expect unpadded identifiers — observed in live data to consistent

